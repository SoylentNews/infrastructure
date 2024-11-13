use irc::client::Sender;
use irc::proto::Message;
use super::karma_database::KarmaDatabase;

pub async fn handle(sender: &Sender, message: &Message, db: &mut KarmaDatabase, args: &[&str]) {
    let channel = message.response_target().unwrap_or("").to_lowercase();
    let item_name = args.join(" ").to_lowercase();
    let karma_item = db.load_item(&channel, &item_name);

    let res: Vec<String> = karma_item.whoup.iter()
        .map(|(user, count)| format!("{}: {}", user, count))
        .collect();

    let response = if !res.is_empty() {
        format!("uppers of {} are: {}", item_name, res.join(", "))
    } else {
        format!("nobody upped {} yet", item_name)
    };

    sender.send_privmsg(message.response_target().unwrap_or_default(), &response).unwrap();
}