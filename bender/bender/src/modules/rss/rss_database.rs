use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::PathBuf;

pub struct RssDatabase {
    data_dir: PathBuf,
    seen_items_cache: HashMap<String, HashSet<String>>,
}

impl RssDatabase {
    pub fn new(data_dir: &str) -> Self {
        let path = PathBuf::from(data_dir);
        if !path.exists() {
            fs::create_dir_all(&path).expect("Failed to create database directory for RSS.");
        }
        Self {
            data_dir: path,
            seen_items_cache: HashMap::new(),
        }
    }

    fn get_feed_db_path(&self, feed_name: &str) -> PathBuf {
        self.data_dir.join(format!("rss_seen_{}.json", feed_name))
    }

    pub fn get_seen_items(&mut self, feed_name: &str) -> HashSet<String> {
        if let Some(items) = self.seen_items_cache.get(feed_name) {
            return items.clone();
        }

        let path = self.get_feed_db_path(feed_name);
        let items = if path.exists() {
            let data = fs::read_to_string(&path).unwrap_or_default();
            serde_json::from_str(&data).unwrap_or_else(|_| HashSet::new())
        } else {
            HashSet::new()
        };

        self.seen_items_cache
            .insert(feed_name.to_string(), items.clone());
        items
    }

    pub fn add_seen_item(&mut self, feed_name: &str, item_id: String) {
        let items = self
            .seen_items_cache
            .entry(feed_name.to_string())
            .or_insert_with(HashSet::new);
        items.insert(item_id);
        self.save_seen_items(feed_name);
    }

    fn save_seen_items(&self, feed_name: &str) {
        if let Some(items) = self.seen_items_cache.get(feed_name) {
            let path = self.get_feed_db_path(feed_name);
            let data = serde_json::to_string_pretty(items).expect("Failed to serialize seen items.");
            fs::write(path, data).expect("Failed to write RSS seen items database.");
        }
    }
}