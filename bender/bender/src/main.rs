mod modules;
mod config;

use futures::StreamExt;
use irc::client::prelude::*;
use modules::{karma::KarmaHandler, rss::RssHandler};
use std::collections::HashSet;
use std::sync::Arc;
use tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = Arc::new(crate::config::Config::load("config.toml").expect("Failed to load configuration."));
    let irc_config = ::irc::client::prelude::Config {
        nickname: Some(config.nickname.clone()),
        server: Some(config.server.clone()),
        channels: config.channels.clone(),
        port: Some(config.port),
        username: Some("bot".to_string()),
        ..Default::default()
    };

    let mut client = ::irc::client::Client::from_config(irc_config).await?;
    client.identify()?;
    let mut stream = client.stream()?;
    let sender = client.sender();
    let mut karma = KarmaHandler::new(&config);

    // Initialize RSS handler but don't start polling yet
    let rss_handler = Arc::new(RssHandler::new(&config));
    
    // Channel tracking for synchronization - only wait for channels that need RSS feeds
    let rss_channels: HashSet<String> = rss_handler.get_rss_channels();
    let mut joined_rss_channels: HashSet<String> = HashSet::new();
    let mut rss_polling_started = false;

    loop {
        let message = stream.select_next_some().await?;

        match message.command {
            Command::PRIVMSG(ref _target, ref msg) => {
                let bot_name = config.nickname.clone();

                if let Some(command_str) = extract_command(&bot_name, msg) {
                    // Pass command to handlers
                    karma.handle_command(&sender, &message, &command_str).await;
                    rss_handler.handle_command(&sender, &message, &command_str).await;
                } else {
                    // Pass message to handlers
                    karma.handle_message(&sender, &message).await;
                }
            }
            Command::JOIN(ref channel, _, _) => {
                // Check if this JOIN is for our bot
                if let Some(ref prefix) = message.prefix {
                    let prefix_str = prefix.to_string();
                    if let Some(nick) = prefix_str.split('!').next() {
                        if nick == config.nickname {
                            // Our bot joined a channel
                            println!("Bot joined channel: {}", channel);
                            
                            // Track RSS channels specifically
                            if rss_channels.contains(channel) {
                                joined_rss_channels.insert(channel.clone());
                                println!("RSS channel joined: {}", channel);
                            }
                            
                            // Check if all RSS channels have been joined
                            if !rss_polling_started && !rss_channels.is_empty() && joined_rss_channels == rss_channels {
                                println!("All RSS channels joined, starting RSS polling...");
                                
                                // Start RSS polling now that all RSS channels are joined
                                let rss_polling_handler = Arc::clone(&rss_handler);
                                let rss_sender = sender.clone();
                                tokio::spawn(async move {
                                    rss_polling_handler.start_polling(rss_sender).await;
                                });
                                
                                rss_polling_started = true;
                            } else if rss_channels.is_empty() && !rss_polling_started {
                                println!("No RSS channels configured, starting RSS polling immediately...");
                                
                                // Start RSS polling immediately if no RSS channels are configured
                                let rss_polling_handler = Arc::clone(&rss_handler);
                                let rss_sender = sender.clone();
                                tokio::spawn(async move {
                                    rss_polling_handler.start_polling(rss_sender).await;
                                });
                                
                                rss_polling_started = true;
                            }
                        }
                    }
                }
            }
            _ => {
                // Handle other IRC commands if needed in the future
            }
        }
    }
}

fn extract_command(bot_name: &str, msg_orig: &str) -> Option<String> {
    let prefix = "!";
    let binding = msg_orig.to_lowercase();
    let msg = binding.as_str();
    if msg.starts_with(prefix) {
        Some(msg_orig[prefix.len()..].to_string())
    } else if msg.starts_with(&format!("{}: ", bot_name)) {
        Some(msg_orig[(bot_name.len() + 2)..].to_string())
    } else if msg.starts_with(&format!("{}, ", bot_name)) {
        Some(msg_orig[(bot_name.len() + 2)..].to_string())
    } else {
        None
    }
}