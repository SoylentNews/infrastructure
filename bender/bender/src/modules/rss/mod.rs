mod rss_database;

use crate::config::Config;
use irc::client::Sender;
use irc::proto::Message;
use rss::Channel;
use rss_database::RssDatabase;
use serde::Deserialize;
use std::fs;
use std::sync::{Arc, Mutex};
use std::time::Duration;
use tokio::time;

#[derive(Clone, Deserialize)]
pub struct RssFeed {
    pub name: String,
    pub url: String,
    pub channels: Vec<String>,
    pub trigger: String,
    pub output: String,
    pub update_interval: u64,
    pub announce_output: usize,
}

#[derive(Clone, Deserialize)]
struct FeedsDocument {
    feeds: Vec<RssFeed>,
}

pub struct RssHandler {
    db: Arc<Mutex<RssDatabase>>,
    feeds: Vec<RssFeed>,
}

impl RssHandler {
    pub fn new(config: &Config) -> Self {
        let feeds = config
            .rss_feeds_path
            .as_ref()
            .and_then(|path| fs::read_to_string(path).ok())
            .and_then(|contents| toml::from_str::<FeedsDocument>(&contents).ok())
            .map_or_else(Vec::new, |doc| doc.feeds);

        if feeds.is_empty() {
            println!("Warning: No RSS feeds were loaded. Check the 'rss_feeds_path' in your config.toml and the contents of the feeds file.");
        }

        RssHandler {
            db: Arc::new(Mutex::new(RssDatabase::new(&config.db_path))),
            feeds,
        }
    }

    pub fn get_rss_channels(&self) -> std::collections::HashSet<String> {
        let mut channels = std::collections::HashSet::new();
        for feed in &self.feeds {
            for channel in &feed.channels {
                channels.insert(channel.clone());
            }
        }
        channels
    }

    pub async fn start_polling(&self, sender: Sender) {
        if self.feeds.is_empty() {
            println!("No RSS feeds configured. RSS polling will not start.");
            return;
        }

        println!("Starting RSS polling for {} feeds.", self.feeds.len());

        for feed in self.feeds.clone() {
            let sender_clone = sender.clone();
            let db_clone = Arc::clone(&self.db);
            let update_interval = feed.update_interval;

            tokio::spawn(async move {
                let mut interval = time::interval(Duration::from_secs(update_interval * 60));
                loop {
                    interval.tick().await;
                    println!("Fetching RSS feed: {}", &feed.name);
                    if let Err(e) =
                        Self::fetch_and_process_feed(&sender_clone, db_clone.clone(), &feed).await
                    {
                        eprintln!("Error processing feed {}: {}", &feed.name, e);
                    }
                }
            });
        }
    }

    async fn fetch_and_process_feed(
        sender: &Sender,
        db: Arc<Mutex<RssDatabase>>,
        feed: &RssFeed,
    ) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        let content = reqwest::get(&feed.url).await?.bytes().await?;
        let channel = Channel::read_from(&content[..])?;
        let mut new_items_found = 0;

        let mut seen_items = db.lock().unwrap().get_seen_items(&feed.name);
        let mut items_to_send = Vec::new();

        for item in channel.items().iter().rev() {
            let item_id = item.guid().map_or_else(
                || item.link().unwrap_or_default().to_string(),
                |g| g.value().to_string(),
            );

            if !seen_items.contains(&item_id) {
                items_to_send.push(item.clone());
                seen_items.insert(item_id.clone());
            }
        }
        
        items_to_send.reverse(); // To announce oldest first
        
        for item in items_to_send.iter().take(feed.announce_output) {
            let item_id = item.guid().map_or_else(
                || item.link().unwrap_or_default().to_string(),
                |g| g.value().to_string(),
            );
            
            let title = item.title().unwrap_or("No Title");
            let link = item.link().unwrap_or("No Link");

            let output = feed
                .output
                .replace("{name}", &feed.name)
                .replace("{title}", title)
                .replace("{link}", link);

            for channel_name in &feed.channels {
                sender.send_privmsg(channel_name, &output)?;
            }
            new_items_found += 1;
            db.lock().unwrap().add_seen_item(&feed.name, item_id);
        }

        if new_items_found > 0 {
            println!("Announced {} new items for feed '{}'", new_items_found, feed.name);
        }

        Ok(())
    }

    pub async fn handle_command(
        &self,
        sender: &Sender,
        message: &Message,
        command_str: &str,
    ) {
        let parts: Vec<&str> = command_str.split_whitespace().collect();
        if parts.is_empty() {
            return;
        }

        let command = parts[0].to_lowercase();
        let args = &parts[1..];
        let target = message.response_target().unwrap_or_default();

        if command != "rss" {
            return;
        }
        
        if self.feeds.is_empty() {
            sender
                .send_privmsg(target, "RSS module is not configured or no feeds were loaded.")
                .unwrap();
            return;
        }

        if args.is_empty() || args[0] == "list" {
            let feed_triggers: Vec<String> = self.feeds.iter().map(|f| f.trigger.clone()).collect();
            let response = format!("Available RSS feeds: {}", feed_triggers.join(", "));
            sender.send_privmsg(target, &response).unwrap();
            return;
        }

        let feed_trigger = args.join(" ");
        if let Some(feed) = self.feeds.iter().find(|f| f.trigger == feed_trigger) {
            match Self::fetch_latest_for_feed(feed).await {
                Ok(items) => {
                    if items.is_empty() {
                        sender
                            .send_privmsg(
                                target,
                                format!("No items found for feed '{}'.", feed.name),
                            )
                            .unwrap();
                    } else {
                        for item in items.iter().take(feed.announce_output) {
                             let title = item.title().unwrap_or("No Title");
                             let link = item.link().unwrap_or("No Link");

                             let output = feed
                                 .output
                                 .replace("{name}", &feed.name)
                                 .replace("{title}", title)
                                 .replace("{link}", link);
                            sender.send_privmsg(target, &output).unwrap();
                        }
                    }
                }
                Err(e) => {
                    let response = format!("Error fetching feed '{}': {}", feed.name, e);
                    sender.send_privmsg(target, &response).unwrap();
                }
            }
        } else {
            let response = format!("Feed trigger '{}' not found. Use '!rss list' to see available feeds.", feed_trigger);
            sender.send_privmsg(target, &response).unwrap();
        }
    }
    
    async fn fetch_latest_for_feed(
        feed: &RssFeed,
    ) -> Result<Vec<rss::Item>, Box<dyn std::error::Error + Send + Sync>> {
        let content = reqwest::get(&feed.url).await?.bytes().await?;
        let channel = Channel::read_from(&content[..])?;
        Ok(channel.into_items())
    }
}