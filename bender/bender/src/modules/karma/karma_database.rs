use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::Path;

#[derive(Serialize, Deserialize, Default)]
pub struct KarmaItem {
    pub name: String,
    pub count: i32,
    pub whoup: HashMap<String, i32>,
    pub whodown: HashMap<String, i32>,
    pub whyup: Vec<String>,
    pub whydown: Vec<String>,
}

pub struct KarmaDatabase {
    items: HashMap<String, KarmaItem>,
    data_dir: String,
}

impl KarmaDatabase {
    pub fn new(data_dir: &str) -> Self {
        Self {
            items: HashMap::new(),
            data_dir: data_dir.to_string(),
        }
    }

    pub fn load_item(&mut self, channel: &str, key: &str) -> &mut KarmaItem {
        let lookup = format!("{}-{}", channel, key);
        let filename = format!("{}-{}", channel.replace("#", "-"), key);

        if !self.items.contains_key(&lookup) {
            let path = Path::new(&self.data_dir).join(&filename);
            let item = if path.exists() {
                let data = fs::read_to_string(&path).expect("Unable to read file");
                serde_json::from_str(&data).expect("Unable to parse JSON")
            } else {
                KarmaItem {
                    name: lookup.clone(),
                    ..Default::default()
                }
            };
            self.items.insert(lookup.clone(), item);
        }
        self.items.get_mut(&lookup).unwrap()
    }

    pub fn save_item(&self, channel: &str, key: &str) {
        let lookup = format!("{}-{}", channel, key);
        let filename = format!("{}-{}", channel.replace("#", "-"), key);

        if let Some(item) = self.items.get(&lookup) {
            let path = Path::new(&self.data_dir).join(&filename);
            let data = serde_json::to_string(item).expect("Unable to serialize JSON");
            fs::write(path, data).expect("Unable to write file");
        }
    }

    pub fn sync_item(&mut self, channel: &str, key: &str) {
        self.save_item(channel, key);
    }
}