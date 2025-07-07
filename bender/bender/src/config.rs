use serde::Deserialize;
use std::fs;
use std::collections::HashMap;

#[derive(Clone, Deserialize)]
pub struct Config {
    pub server: String,
    pub port: u16,
    pub nickname: String,
    pub realname: String,
    pub channels: Vec<String>,
    pub db_path: String,
    pub rss_feeds_path: Option<String>,
    pub nickserv_password: Option<String>,
    pub log_path: Option<String>,
    pub log_channels: Option<Vec<String>>,
    pub channel_timezones: Option<HashMap<String, String>>,
}

impl Config {
    pub fn load(filename: &str) -> Result<Config, Box<dyn std::error::Error>> {
        let contents = fs::read_to_string(filename)?;
        let config: Config = toml::from_str(&contents)?;
        Ok(config)
    }
}