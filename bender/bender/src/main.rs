mod modules;
mod config;

use futures::StreamExt;
use irc::client::prelude::*;
use modules::karma::KarmaHandler;
use tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = crate::config::Config::load("config.toml").expect("Failed to load configuration.");
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
    loop {
        let message = stream.select_next_some().await?;

        if let Command::PRIVMSG(ref _target, ref msg) = message.command {
            let bot_name = config.nickname.clone();

            if let Some(command_str) = extract_command(&bot_name, msg) {
                karma.handle_command(&sender, &message, &command_str).await;
            } else {
                karma.handle_message(&sender, &message).await;
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
