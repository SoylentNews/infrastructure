import random
import irc.bot
import irc.strings
import time
from threading import Timer
from entities import Player, NPC
from combat import combat
from utils import clean_nick, load_players, save_players
from constants import message_templates, locations, effectiveness_pools

class IRCBot(irc.bot.SingleServerIRCBot):
    def __init__(self, channel, nickname, server, port=6667):
        irc.bot.SingleServerIRCBot.__init__(self, [(server, port)], nickname, nickname)
        self.channel = channel
        self.players = load_players()
        self.npcs = {}
        self.leaderboard = []
        self.schedule_reset()
        self.schedule_leaderboard_announcement()

    def on_welcome(self, connection, event):
        connection.join(self.channel)
        connection.privmsg("ChanServ", f"OP {self.channel}")
        connection.privmsg(self.channel, "MrPlow has joined the channel!")
        connection.names(self.channel)

    def on_namreply(self, connection, event):
        for nick in event.arguments[2].split():
            clean = clean_nick(nick)
            if clean not in self.players:
                self.players[clean] = Player(clean)
                save_players(self.players)

    def on_join(self, connection, event):
        nick = event.source.nick
        clean = clean_nick(nick)
        if clean not in self.players:
            self.players[clean] = Player(clean)
            save_players(self.players)
            connection.privmsg(self.channel, f"Welcome {clean}! You have been added to the game.")

    def on_pubmsg(self, connection, event):
        message = event.arguments[0]
        nick = event.source.nick
        vhost = event.source.host

        if message.startswith("#fitectl status"):
            self.handle_status(connection, nick)
        elif message.startswith("#fite "):
            target = message.split(" ")[1]
            self.handle_fite(connection, nick, target)
        elif message.startswith("#fitectl weapon "):
            weapon = message.split(" ", 2)[2]
            self.handle_weapon(connection, nick, weapon)
        elif message.startswith("#fitectl armor "):
            armor = message.split(" ", 2)[2]
            self.handle_armor(connection, nick, armor)
        elif message == "#fite The good fairy has come along and revived everyone":
            self.handle_revive_all(connection)
        elif vhost.startswith("Soylent/Staff/") and message == "#suckit":
            self.handle_reset_now(connection)

    def handle_status(self, connection, nick):
        if nick not in self.players:
            self.players[nick] = Player(nick)
            save_players(self.players)
        player = self.players[nick]
        connection.privmsg(self.channel, f"{nick}: {player.status()}")

    def handle_fite(self, connection, nick, target):
        if nick not in self.players:
            self.players[nick] = Player(nick)
            save_players(self.players)
        player = self.players[nick]

        if target.startswith("NPC_"):
            if target not in self.npcs:
                self.npcs[target] = NPC(target)
            npc = self.npcs[target]
            combat(connection, player, npc)
        else:
            if target not in self.players:
                connection.privmsg(self.channel, f"{nick}: {target} is not a valid target.")
                return
            opponent = self.players[target]
            combat(connection, self.channel, player, opponent)
            save_players(self.players)
            self.update_leaderboard(connection)


    def handle_weapon(self, connection, nick, weapon):
        if nick not in self.players:
            self.players[nick] = Player(nick)
            save_players(self.players)
        player = self.players[nick]
        player.weapon = weapon
        save_players(self.players)
        connection.privmsg(self.channel, f"{nick}: weapon set to {weapon}.")

    def handle_armor(self, connection, nick, armor):
        if nick not in self.players:
            self.players[nick] = Player(nick)
            save_players(self.players)
        player = self.players[nick]
        player.armor = armor
        save_players(self.players)
        connection.privmsg(self.channel, f"{nick}: armor set to {armor}.")

    def handle_revive_all(self, connection):
        for player in self.players.values():
            player.hp = player.max_hp
            player.alive = True
        for npc in self.npcs.values():
            npc.hp = 50
            npc.alive = True
        random_player = random.choice(list(self.players.values()))
        random_player.hp = random_player.level + 100

        save_players(self.players)
        connection.privmsg(self.channel, "The good fairy has come along and revived everyone.")
        connection.privmsg(self.channel, f"{random_player.name} has been blessed with extra health!")

    def handle_reset_now(self, connection):
        self.handle_revive_all(connection)
        connection.privmsg(self.channel, "Reset triggered by Soylent/Staff member.")

    def schedule_reset(self):
        now = time.time()
        next_reset = now + (24 * 60 * 60) - (now % (24 * 60 * 60))
        Timer(next_reset - now, self.reset_players).start()

    def reset_players(self):
        for player in self.players.values():
            player.hp = player.max_hp
            player.alive = True
        save_players(self.players)
        self.connection.privmsg(self.channel, "Mr. Plow has reset everyone's HP! Time to get back to fighting!")
        self.schedule_reset()

    def schedule_leaderboard_announcement(self):
        Timer(3600, self.announce_leaderboard).start()  # Announce every hour

    def announce_leaderboard(self):
        sorted_players = sorted(self.players.values(), key=lambda p: p.level, reverse=True)
        leaderboard = "\n".join([f"{i+1}. {player.name} (Level {player.level})" for i, player in enumerate(sorted_players[:10])])
        self.connection.privmsg(self.channel, f"Mr. Plow's Leaderboard:\n{leaderboard}")
        self.schedule_leaderboard_announcement()

    def update_leaderboard(self, connection):
        sorted_players = sorted(self.players.values(), key=lambda p: p.level, reverse=True)
        new_leaderboard = [player.name for player in sorted_players[:10]]
        if new_leaderboard != self.leaderboard:
            for i, player_name in enumerate(new_leaderboard):
                if player_name not in self.leaderboard:
                    connection.privmsg(self.channel, f"Mr. Plow says: Congratulations {player_name}! You've moved up to position {i+1} on the leaderboard!")
            self.leaderboard = new_leaderboard

if __name__ == "__main__":
    bot = IRCBot("#fite", "MrPlow", "irc.soylentnews.org")
    bot.start()