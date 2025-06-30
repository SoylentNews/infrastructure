use serde::Deserialize;
use std::fs;

#[derive(Clone, Deserialize)]
pub struct Config {
    pub server: String,
    pub port: u16,
    pub nickname: String,
    pub realname: String,
    pub channels: Vec<String>,
    pub db_path: String,
    pub rss_feeds_path: Option<String>,
}

impl Config {
    pub fn load(filename: &str) -> Result<Config, Box<dyn std::error::Error>> {
        let contents = fs::read_to_string(filename)?;
        let config: Config = toml::from_str(&contents)?;
        Ok(config)
    }
}