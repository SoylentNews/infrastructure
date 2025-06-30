mod modules;
mod config;

use futures::StreamExt;
use irc::client::prelude::*;
use modules::{karma::KarmaHandler, rss::RssHandler};
use std::collections::HashSet;
use std::sync::{Arc, Mutex};
use tokio::time::{interval, Duration};
use tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = Arc::new(crate::config::Config::load("config.toml").expect("Failed to load configuration."));
    let irc_config = ::irc::client::prelude::Config {
        nickname: Some(config.nickname.clone()),
        server: Some(config.server.clone()),
        channels: config.channels.clone(), // Initial join attempts
        port: Some(config.port),
        username: Some("bot".to_string()),
        ..Default::default()
    };

    let mut client = ::irc::client::Client::from_config(irc_config).await?;
    client.identify()?;
    let mut stream = client.stream()?;
    let sender = client.sender();

    // --- Start of retry logic ---
    // Channels the bot should be in
    let desired_channels = Arc::new(Mutex::new(config.channels.iter().cloned().collect::<HashSet<String>>()));
    // Channels the bot has successfully joined
    let joined_channels = Arc::new(Mutex::new(HashSet::<String>::new()));

    // Spawn a task to periodically try to join channels
    let sender_clone = sender.clone();
    let desired_channels_clone = Arc::clone(&desired_channels);
    let joined_channels_clone = Arc::clone(&joined_channels);
    tokio::spawn(async move {
        let mut interval = interval(Duration::from_secs(60)); // Check every 60 seconds
        loop {
            interval.tick().await;
            let desired = desired_channels_clone.lock().unwrap().clone();
            let joined = joined_channels_clone.lock().unwrap().clone();
            
            for channel in desired.difference(&joined) {
                println!("Attempting to re-join channel: {}", channel);
                if let Err(e) = sender_clone.send_join(channel) {
                    eprintln!("Failed to send JOIN command for {}: {}", channel, e);
                }
            }
        }
    });
    // --- End of retry logic ---

    let mut karma = KarmaHandler::new(&config);

    let rss_handler = Arc::new(RssHandler::new(&config));
    
    let rss_channels: HashSet<String> = rss_handler.get_rss_channels();
    let mut joined_rss_channels: HashSet<String> = HashSet::new();
    let mut rss_polling_started = false;

    loop {
        let message = stream.select_next_some().await?;

        match message.command {
            Command::PRIVMSG(ref _target, ref msg) => {
                let bot_name = config.nickname.clone();

                if let Some(command_str) = extract_command(&bot_name, msg) {
                    karma.handle_command(&sender, &message, &command_str).await;
                    rss_handler.handle_command(&sender, &message, &command_str).await;
                } else {
                    karma.handle_message(&sender, &message).await;
                }
            }
            Command::JOIN(ref channel, _, _) => {
                if let Some(nick) = message.source_nickname() {
                    if nick == config.nickname {
                            println!("Bot joined channel: {}", channel);

                            // Update the master list of joined channels
                            joined_channels.lock().unwrap().insert(channel.clone());

                            // Track RSS channels specifically for sync
                            if rss_channels.contains(channel) {
                                joined_rss_channels.insert(channel.clone());
                                println!("RSS channel joined: {}", channel);
                            }
                            
                            if !rss_polling_started && !rss_channels.is_empty() && joined_rss_channels == rss_channels {
                                println!("All RSS channels joined, starting RSS polling...");
                                let rss_polling_handler = Arc::clone(&rss_handler);
                                let rss_sender = sender.clone();
                                tokio::spawn(async move {
                                    rss_polling_handler.start_polling(rss_sender).await;
                                });
                                rss_polling_started = true;
                            } else if rss_channels.is_empty() && !rss_polling_started {
                                println!("No RSS channels configured, RSS polling will not start.");
                                rss_polling_started = true; // Prevents this from running again
                            }
                        }
                    }
                    }
                }
            }
            // --- New handlers for PART and KICK ---
            Command::PART(ref channel, _) => {
                if let Some(nick) = message.source_nickname() {
                    if nick == config.nickname {
                        println!("Bot parted channel: {}. Will try to rejoin.", channel);
                        joined_channels.lock().unwrap().remove(channel);
                        joined_rss_channels.remove(channel);
                    }
                }
            }
            Command::KICK(ref channel, ref kicked_user, _) => {
                if *kicked_user == config.nickname {
                    println!("Bot was kicked from channel: {}. Will try to rejoin.", channel);
                    joined_channels.lock().unwrap().remove(channel);
                    joined_rss_channels.remove(channel);
                }
            }
            // --- End of new handlers ---
            _ => {}
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