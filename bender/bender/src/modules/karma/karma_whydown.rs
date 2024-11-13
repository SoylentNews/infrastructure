use irc::client::Sender;
use irc::proto::Message;
use super::karma_database::KarmaDatabase;

pub async fn handle(sender: &Sender, message: &Message, db: &mut KarmaDatabase, args: &[&str]) {
    let channel = message.response_target().unwrap_or("").to_lowercase();
    let item_name = args.join(" ").to_lowercase();
    let karma_item = db.load_item(&channel, &item_name);

    let response = if !karma_item.whydown.is_empty() {
        format!("reasons for karma down are: {:?}", karma_item.whydown)
    } else {
        format!("no reasons for karma down of {} known yet", item_name)
    };

    sender.send_privmsg(message.response_target().unwrap_or_default(), &response).unwrap();
}