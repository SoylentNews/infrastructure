use irc::client::Sender;
use irc::proto::Message;
use super::karma_database::KarmaDatabase;

pub async fn handle(sender: &Sender, message: &Message, db: & mut KarmaDatabase, args: &[&str]) {
    let channel = message.response_target().unwrap_or("").to_lowercase();
    let item_name = args.join(" ").to_lowercase();
    let karma_item = db.load_item(&channel, &item_name);

    let response = if !karma_item.whyup.is_empty() {
        format!("reasons for karma up are: {:?}", karma_item.whyup)
    } else {
        format!("no reasons for karma up of {} known yet", item_name)
    };

    sender.send_privmsg(message.response_target().unwrap_or_default(), &response).unwrap();
}