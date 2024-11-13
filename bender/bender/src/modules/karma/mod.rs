mod karma_database;
pub mod karma_karma;
pub mod karma_whodown;
pub mod karma_whoup;
pub mod karma_whydown;
pub mod karma_whyup;

use crate::config::Config;
use crate::modules::karma::karma_database::KarmaDatabase;
use irc::client::Sender;
use irc::proto::{Command, Message};
use regex::Regex;

pub struct KarmaHandler {
    ignore: Vec<String>,
    db: KarmaDatabase,
}

impl KarmaHandler {
    pub fn new(conf: &Config) -> KarmaHandler {
        KarmaHandler {
            db: KarmaDatabase::new(&conf.db_path),
            ignore: vec!["aristarchus".to_string()],
        }
    }

    fn prekarma(&self, message: &Message) -> bool {
        if let Command::PRIVMSG(ref _target, ref msg) = message.command {
            let re_karma =
                Regex::new(r"^(?P<item>\([^\)]+\)|\[[^\]]+\]|\w+)(?P<mod>\+\+|--)( |$)").unwrap();

            if let Some(userhost) = message.source_nickname() {
                if self.ignore.contains(&userhost.to_string()) {
                    return false;
                }
            }

            if let Some(captures) = re_karma.captures(msg) {
                if let Some(item) = captures.name("item") {
                    if let Some(nick) = message.source_nickname() {
                        if item.as_str() == nick {
                            return false;
                        } else {
                            return true;
                        }
                    }
                }
            }
        }
        false
    }
    pub async fn handle_command(
        &mut self,
        sender: &Sender,
        message: &Message,
        command_str: &String,
    ) {
        if let Command::PRIVMSG(ref _target, ref _msg) = message.command {
            let parts: Vec<&str> = command_str.split_whitespace().collect();
            if parts.is_empty() {
                return;
            }

            let command = parts[0].to_lowercase();
            let args = &parts[1..];

            match command.as_str() {
                "karma" => karma_karma::handle(sender, message, &mut self.db, args).await,
                "karma-whyup" => karma_whyup::handle(sender, message, &mut self.db, args).await,
                "karma-whydown" => karma_whydown::handle(sender, message, &mut self.db, args).await,
                "karma-whoup" => karma_whoup::handle(sender, message, &mut self.db, args).await,
                "karma-whodown" => karma_whodown::handle(sender, message, &mut self.db, args).await,
                _ => {
                    sender
                        .send_privmsg(message.response_target().unwrap_or(""), "Unknown command")
                        .unwrap();
                }
            }
        }
    }

    pub async fn handle_message(&mut self, sender: &Sender, message: &Message) {
        if !self.prekarma(&message) {
            return;
        }

        if let Command::PRIVMSG(ref target, ref msg) = message.command {
            self.handle_privmsg(sender, target, msg, message)
                .await
                .unwrap();
        }
    }
    async fn handle_privmsg(
        &mut self,
        sender: &Sender,
        target: &str,
        msg: &str,
        message: &Message,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let re_karma =
            Regex::new(r"^(?P<item>\([^\)]+\)|\[[^\]]+\]|\w+)(?P<mod>\+\+|--)( |$)").unwrap();

        let channel = if target.starts_with("#") {
            target.to_lowercase()
        } else {
            "".to_string()
        };

        let reason = msg.split('#').nth(1).map(|s| s.trim().to_string());
        let source = message.source_nickname().unwrap_or("");
        let reply = message.response_target().unwrap_or(source);

        // create a list of output strings to send to the channel
        let mut output = Vec::<String>::new();

        for cap in re_karma.captures_iter(msg) {
            let item = cap.name("item").unwrap().as_str().to_lowercase();
            let modifier = cap.name("mod").unwrap().as_str();

            let karma_item = self.db.load_item(channel.as_str(), &item);
            if modifier == "++" {
                karma_item.count += 1;
                if !karma_item.whoup.contains_key(source) {
                    karma_item.whoup.insert(source.to_string(), 0);
                }
                *karma_item.whoup.get_mut(source).unwrap() += 1;
                if let Some(ref reason) = reason {
                    if !karma_item.whyup.contains(reason) {
                        karma_item.whyup.push(reason.clone());
                    }
                }
            } else {
                karma_item.count -= 1;
                if !karma_item.whodown.contains_key(source) {
                    karma_item.whodown.insert(source.to_string(), 0);
                }
                *karma_item.whodown.get_mut(source).unwrap() -= 1;
                if let Some(ref reason) = reason {
                    if !karma_item.whydown.contains(reason) {
                        karma_item.whydown.push(reason.clone());
                    }
                }
            }
            output.push(format!("{}: {}", item, karma_item.count));

            self.db.sync_item(channel.as_str(), &item);
        }

        sender.send_privmsg(reply, output.join(", ")).unwrap();

        Ok(())
    }
}
