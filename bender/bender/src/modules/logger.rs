use crate::config::Config;
use chrono::{DateTime, Utc};
use chrono_tz::Tz;
use htmlescape::encode_minimal;
use irc::proto::{Command, Message};
use lazy_static::lazy_static;
use regex::Regex;
use std::collections::HashMap;
use std::fs;
use std::io::{BufRead, BufReader};
use std::path::{Path, PathBuf};

lazy_static! {
    static ref URL_REGEX: Regex = Regex::new(r#"(?i)\b((?:[a-z][\w-]+:(?:/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))"#).unwrap();
}

pub struct Logger {
    log_path: PathBuf,
    timezones: HashMap<String, Tz>,
    channels: Vec<String>,
}

impl Logger {
    pub fn new(config: &Config) -> Option<Self> {
        config.log_path.as_ref().map(|path| {
            let timezones = config
                .channel_timezones
                .as_ref()
                .map(|tz_map| {
                    tz_map
                        .iter()
                        .filter_map(|(channel, tz_str)| {
                            tz_str.parse::<Tz>().ok().map(|tz| (channel.to_lowercase(), tz))
                        })
                        .collect()
                })
                .unwrap_or_default();
            Logger {
                log_path: PathBuf::from(path),
                timezones,
                channels: config.log_channels.as_ref()
                    .unwrap_or(&config.channels)
                    .clone(),
            }
        })
    }

    pub async fn log_message(&self, message: &Message) {
        let (channels, line) = match self.format_message(message) {
            Some((channels, line)) => (channels, line),
            None => return,
        };

        if line.is_empty() {
            return;
        }

        for channel_name in channels {
            self.write_to_log(&channel_name, &line);
        }
    }

    fn should_log_channel(&self, channel: &str) -> bool {
        self.channels.iter().any(|c| c.to_lowercase() == channel.to_lowercase())
    }

    fn filter_channels(&self, channels: Vec<String>) -> Vec<String> {
        channels.into_iter()
            .filter(|channel| self.should_log_channel(channel))
            .collect()
    }

    fn format_message(&self, message: &Message) -> Option<(Vec<String>, String)> {
        // Clean logging - debug output removed after successful implementation
        
        let nick = message.source_nickname().unwrap_or("").to_string();
        let color = Self::get_nick_color(&nick);
        
        // Fix user_host() - implement proper user@host format like the original Python code
        let host_string = message.prefix.as_ref().map(|p| {
            match p {
                irc::proto::Prefix::Nickname(_nick, user, host) => {
                    // user and host are already &String, so create user@host format
                    format!("{}@{}", user, host)
                }
                irc::proto::Prefix::ServerName(server) => server.clone(),
            }
        });
        let host = host_string.as_deref().unwrap_or("");

        match &message.command {
            // Handle CTCP ACTION commands manually from PRIVMSG
            Command::PRIVMSG(target, msg) if msg.starts_with("\x01ACTION ") && msg.ends_with("\x01") => {
                // This is a CTCP ACTION message
                let action_text = &msg[8..msg.len()-1]; // Remove \x01ACTION and trailing \x01
                let line = format!(
                    r#"<span class="person" style="color:{}">* {} {}</span>"#,
                    color,
                    encode_minimal(&nick),
                    self.specials(action_text)
                );
                let filtered_channels = self.filter_channels(vec![target.clone()]);
                if filtered_channels.is_empty() { None } else { Some((filtered_channels, line)) }
            }
            Command::PRIVMSG(target, msg) => {
                let formatted_msg = self.specials(msg);
                let line = format!(
                    r#"<span class="person" style="color:{}">&lt;{}&gt;</span> {}"#,
                    color,
                    encode_minimal(&nick),
                    formatted_msg
                );
                let filtered_channels = self.filter_channels(vec![target.clone()]);
                if filtered_channels.is_empty() { None } else { Some((filtered_channels, line)) }
            }
            Command::NOTICE(target, msg) => {
                let formatted_msg = self.specials(msg);
                let line = format!(
                    r#"<span class="notice">-{}:{}-</span> {}"#,
                    encode_minimal(&nick),
                    encode_minimal(target),
                    formatted_msg
                );
                let filtered_channels = self.filter_channels(vec![target.clone()]);
                if filtered_channels.is_empty() { None } else { Some((filtered_channels, line)) }
            }
            Command::JOIN(channel, _, _) => {
                let line = format!(
                    r#"-!- <span class="join">{}</span> [{}] has joined {}"#,
                    encode_minimal(&nick),
                    encode_minimal(host),
                    encode_minimal(channel)
                );
                let filtered_channels = self.filter_channels(vec![channel.clone()]);
                if filtered_channels.is_empty() { None } else { Some((filtered_channels, line)) }
            }
            Command::PART(channel, reason) => {
                let reason_str = reason.as_deref().unwrap_or("");
                let line = format!(
                    r#"-!- <span class="part">{}</span> [{}] has parted {} [{}]"#,
                    encode_minimal(&nick),
                    encode_minimal(host),
                    encode_minimal(channel),
                    encode_minimal(reason_str)
                );
                let filtered_channels = self.filter_channels(vec![channel.clone()]);
                if filtered_channels.is_empty() { None } else { Some((filtered_channels, line)) }
            }
            Command::QUIT(reason) => {
                let reason_str = reason.as_deref().unwrap_or("");
                let line = format!(
                    r#"-!- <span class="quit">{}</span> has quit [{}]"#,
                    encode_minimal(&nick),
                    encode_minimal(reason_str)
                );
                let filtered_channels = self.filter_channels(self.channels.clone());
                if filtered_channels.is_empty() { None } else { Some((filtered_channels, line)) }
            }
            Command::KICK(channel, kicked, reason) => {
                let reason_str = reason.as_deref().unwrap_or("");
                let line = format!(
                    r#"-!- <span class="kick">{}</span> was kicked from {} by {} [{}]"#,
                    encode_minimal(kicked),
                    encode_minimal(channel),
                    encode_minimal(&nick),
                    encode_minimal(reason_str)
                );
                let filtered_channels = self.filter_channels(vec![channel.clone()]);
                if filtered_channels.is_empty() { None } else { Some((filtered_channels, line)) }
            }
            Command::NICK(new_nick) => {
                let line = format!(
                    r#"<span class="nick">{}</span> is now known as <span class="nick">{}</span>"#,
                    encode_minimal(&nick),
                    encode_minimal(new_nick)
                );
                let filtered_channels = self.filter_channels(self.channels.clone());
                if filtered_channels.is_empty() { None } else { Some((filtered_channels, line)) }
            }
            Command::TOPIC(channel, topic) => {
                let topic_text = topic.as_deref().unwrap_or("");
                let line = format!(
                    r#"<span class="topic">{}</span> changed topic of <span class="topic">{}</span> to: {}"#,
                    encode_minimal(&nick),
                    encode_minimal(channel),
                    self.specials(topic_text)
                );
                let filtered_channels = self.filter_channels(vec![channel.clone()]);
                if filtered_channels.is_empty() { None } else { Some((filtered_channels, line)) }
            }
            // MODE command support - handles channel mode changes like the Python bot
            Command::ChannelMODE(channel, modes) => {
                // Format mode changes according to Python bot logic
                let mut mode_str = String::new();
                let mut current_op = None;
                let mut params = Vec::new();
                
                for mode in modes {
                    match mode {
                        irc::proto::Mode::Plus(mode_type, param) => {
                            if current_op != Some('+') {
                                mode_str.push('+');
                                current_op = Some('+');
                            }
                            mode_str.push(mode_char_from_type(mode_type));
                            if let Some(p) = param {
                                params.push(p.clone());
                            }
                        },
                        irc::proto::Mode::Minus(mode_type, param) => {
                            if current_op != Some('-') {
                                mode_str.push('-');
                                current_op = Some('-');
                            }
                            mode_str.push(mode_char_from_type(mode_type));
                            if let Some(p) = param {
                                params.push(p.clone());
                            }
                        },
                        irc::proto::Mode::NoPrefix(mode_type) => {
                            // Handle modes without explicit +/- prefix
                            mode_str.push(mode_char_from_type(mode_type));
                        }
                    }
                }
                
                // Combine mode string with parameters
                let full_mode = if params.is_empty() {
                    mode_str
                } else {
                    format!("{} {}", mode_str, params.join(" "))
                };
                
                let line = format!(
                    r#"-!- <span class="mode">{}</span> sets mode {}"#,
                    encode_minimal(&nick),
                    encode_minimal(&full_mode)
                );
                let filtered_channels = self.filter_channels(vec![channel.clone()]);
                if filtered_channels.is_empty() { None } else { Some((filtered_channels, line)) }
            },
            Command::UserMODE(_user, modes) => {
                // Format user mode changes
                let mut mode_str = String::new();
                let mut current_op = None;
                
                for mode in modes {
                    match mode {
                        irc::proto::Mode::Plus(mode_type, _) => {
                            if current_op != Some('+') {
                                mode_str.push('+');
                                current_op = Some('+');
                            }
                            mode_str.push(mode_char_from_user_type(mode_type));
                        },
                        irc::proto::Mode::Minus(mode_type, _) => {
                            if current_op != Some('-') {
                                mode_str.push('-');
                                current_op = Some('-');
                            }
                            mode_str.push(mode_char_from_user_type(mode_type));
                        },
                        irc::proto::Mode::NoPrefix(mode_type) => {
                            // Handle modes without explicit +/- prefix for user modes
                            mode_str.push(mode_char_from_user_type(mode_type));
                        }
                    }
                }
                
                let line = format!(
                    r#"-!- <span class="mode">{}</span> sets user mode {}"#,
                    encode_minimal(&nick),
                    encode_minimal(&mode_str)
                );
                
                // User mode changes might not have a specific channel context
                // Log to all channels the user is in (similar to QUIT/NICK)
                let filtered_channels = self.filter_channels(self.channels.clone());
                if filtered_channels.is_empty() { None } else { Some((filtered_channels, line)) }
            },
            _ => None,
        }
    }

    fn specials(&self, message: &str) -> String {
        let escaped = encode_minimal(message);
        URL_REGEX.replace_all(&escaped, r#"<a href="$0" target="_blank">$0</a>"#).to_string()
    }

    fn get_nick_color(nick: &str) -> String {
        let digest = md5::compute(nick.as_bytes());
        format!("#{:02x}{:02x}{:02x}", digest[0], digest[1], digest[2])
    }

    fn get_html_header(&self, title: &str) -> String {
        format!(
            r#"<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>{}</title>
    <style type="text/css">
        body {{
            background-color: #F8F8FF;
            font-family: Fixed, monospace;
            font-size: 13px;
            word-wrap: break-word;
        }}
        h1 {{
            font-family: sans-serif;
            font-size: 24px;
            text-align: center;
        }}
        a, .time {{
            color: #525552;
            text-decoration: none;
        }}
        a:hover, .time:hover {{ text-decoration: underline; }}
        .person {{ color: #DD1144; }}
        .join, .part, .quit, .kick, .mode, .topic, .nick {{ color: #42558C; }}
        .notice {{ color: #AE768C; }}
    </style>
  </head>
  <body>
  <h1>{}</h1>
  <a href="..">&laquo; return</a><br />
  </body>
</html>
"#,
            title, title
        )
    }

    fn write_to_log(&self, channel: &str, line: &str) {
        let channel_name = channel.to_lowercase();
        let tz = self.timezones.get(&channel_name).cloned().unwrap_or(Tz::UTC);
        let now: DateTime<Tz> = Utc::now().with_timezone(&tz);
        let date_str = now.format("%Y-%m-%d").to_string();
        let time_str = now.format("%H:%M:%S").to_string();

        let channel_path = self.log_path.join(channel_name.trim_start_matches('#'));
        if let Err(e) = fs::create_dir_all(&channel_path) {
            eprintln!("[Log] Failed to create directory {}: {}", channel_path.display(), e);
            return;
        }

        let channel_index_path = channel_path.join("index.html");
        if !channel_index_path.exists() {
            let title = format!("{} | Logs", channel);
            let header = self.get_html_header(&title);
            if let Err(e) = fs::write(&channel_index_path, header) {
                eprintln!("[Log] Failed to write channel index {}: {}", channel_index_path.display(), e);
            }
            self.add_to_main_index(channel);
        }

        let log_file_path = channel_path.join(format!("{}.html", date_str));
        if !log_file_path.exists() {
            let title = format!("{} | Logs for {}", channel, date_str);
            let header = self.get_html_header(&title);
            if let Err(e) = fs::write(&log_file_path, header) {
                eprintln!("[Log] Failed to write daily log {}: {}", log_file_path.display(), e);
            }
            let entry = format!(r#"<a href="{}.html">{}</a>"#, date_str, date_str);
            self.append_line_to_file(&channel_index_path, &entry);
        }

        let formatted_line = format!(
            "<a href=\"#{}\" name=\"{}\" class=\"time\">[{}]</a> {}",
            time_str, time_str, time_str, line
        );
        self.append_line_to_file(&log_file_path, &formatted_line);
    }

    fn add_to_main_index(&self, channel: &str) {
        let main_index_path = self.log_path.join("index.html");
        if !self.log_path.exists() {
            fs::create_dir_all(&self.log_path).expect("Failed to create base log directory");
        }
        if !main_index_path.exists() {
             let header = self.get_html_header("Chat Logs");
             if let Err(e) = fs::write(&main_index_path, header) {
                 eprintln!("[Log] Failed to write main index {}: {}", main_index_path.display(), e);
             }
        }
        
        let entry = format!(r#"<a href="./{}/index.html">{}</a>"#, channel.trim_start_matches('#'), channel);
        self.append_line_to_file(&main_index_path, &entry);
    }
    
    fn append_line_to_file(&self, path: &Path, line: &str) {
        let file = match fs::File::open(path) {
            Ok(f) => f,
            Err(e) => {
                eprintln!("[Log] Failed to open {} for read: {}", path.display(), e);
                return;
            }
        };

        let reader = BufReader::new(file);
        let mut lines: Vec<String> = reader.lines().collect::<Result<_, _>>().unwrap_or_default();
        
        let closing_tags = if lines.len() >= 2 {
            lines.split_off(lines.len() - 2)
        } else {
            // Fallback if the file is malformed or empty
            vec!["</body>".to_string(), "</html>".to_string()]
        };

        lines.push(line.to_string());
        lines.push("<br />".to_string());
        lines.extend(closing_tags);

        if let Err(e) = fs::write(path, lines.join("\n")) {
            eprintln!("[Log] Failed to write to {}: {}", path.display(), e);
        }
    }
}

// Helper functions for MODE command handling
fn mode_char_from_type(mode_type: &irc::proto::ChannelMode) -> char {
    use irc::proto::ChannelMode::*;
    match mode_type {
        Oper => 'o',
        Voice => 'v',
        Ban => 'b',
        Exception => 'e',
        InviteException => 'I',
        Limit => 'l',
        InviteOnly => 'i',
        Key => 'k',
        Moderated => 'm',
        NoExternalMessages => 'n',
        ProtectedTopic => 't',
        Secret => 's',
        RegisteredOnly => 'R',
        Founder => 'q',
        _ => '?', // Fallback for any other modes
    }
}

fn mode_char_from_user_type(mode_type: &irc::proto::UserMode) -> char {
    use irc::proto::UserMode::*;
    match mode_type {
        Away => 'a',
        Invisible => 'i',
        Wallops => 'w',
        Restricted => 'r',
        ServerNotices => 's',
        Oper => 'o',
        LocalOper => 'O',
        MaskedHost => 'x',
        _ => '?', // Fallback for any other user modes
    }
}