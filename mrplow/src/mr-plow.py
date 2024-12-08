import random
import irc.bot
import irc.strings
import time
import os
import json
from threading import Timer
from entities import Player, NPC
from combat import combat
from utils import clean_nick, load_players, save_players
from constants import message_templates, locations, effectiveness_pools

SCHEDULE_FILE = "schedule.json"

class IRCBot(irc.bot.SingleServerIRCBot):
    def __init__(self, channel, nickname, server, port=6667):
        irc.bot.SingleServerIRCBot.__init__(self, [(server, port)], nickname, nickname)
        self.channel = channel
        self.players = load_players()
        self.npcs = {}
        self.leaderboard = []
        self.next_reset = None
        self.next_announcement = None
        self.load_schedule()

    def load_schedule(self):
        if os.path.exists(SCHEDULE_FILE):
            with open(SCHEDULE_FILE, 'r') as f:
                schedule = json.load(f)
                self.next_reset = schedule.get("next_reset")
                self.next_announcement = schedule.get("next_announcement")
                now = time.time()
                if self.next_reset and self.next_reset > now:
                    Timer(self.next_reset - now, self.handle_scheduled_reset).start()
                else:
                    Timer(30, self.handle_scheduled_reset).start()
                if self.next_announcement and self.next_announcement > now:
                    Timer(self.next_announcement - now, self.handle_scheduled_leaderboard).start()
                else:
                    Timer(30, self.handle_scheduled_leaderboard).start()
        else:
            Timer(30, self.handle_scheduled_reset).start()
            Timer(30, self.handle_scheduled_leaderboard).start()

    

    def handle_scheduled_leaderboard(self):
        self.announce_leaderboard()
        self.next_announcement = time.time() + 3600
        self.save_schedule()
        Timer(3600, self.handle_scheduled_leaderboard).start()

    def save_schedule(self):
        schedule = {}
        if self.next_reset:
            schedule["next_reset"] = self.next_reset
        if self.next_announcement:
            schedule["next_announcement"] = self.next_announcement
        with open(SCHEDULE_FILE, 'w') as f:
            json.dump(schedule, f)
        print(f"Saved schedule: {schedule}")

    def on_welcome(self, connection, event):
        connection.join(self.channel)
        self.delayed_privmsg(connection, self.channel, "MrPlow has joined the channel!", 0)
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
            self.delayed_privmsg(connection, self.channel, f"Welcome {clean}! You have been added to the game.", 0)

    def on_pubmsg(self, connection, event):
        message = event.arguments[0]
        nick = event.source.nick
        vhost = event.source.host
        delay = 0

        if message.startswith("#fitectl status"):
            self.handle_status(connection, nick, delay)
        elif message.startswith("#fite "):
            target = message.split(" ")[1]
            self.handle_fite(connection, nick, target, delay)
        elif message.startswith("#fitectl weapon "):
            weapon = message.split(" ", 2)[2]
            self.handle_weapon(connection, nick, weapon, delay)
        elif message.startswith("#fitectl armor "):
            armor = message.split(" ", 2)[2]
            self.handle_armor(connection, nick, armor, delay)
        elif message.startswith("#fitectl schedule"):
            self.handle_schedule(connection, nick, delay)
        elif message.startswith("#fitectl leaderboard") or message.startswith("#fitectl score"):
            self.handle_show_leaderboard(connection, delay)
        elif vhost.startswith("Soylent/Staff/") and message == "#suckit":
            self.handle_reset_now(connection, delay)

    def handle_status(self, connection, nick, delay):
        if nick not in self.players:
            self.players[nick] = Player(nick)
            save_players(self.players)
        player = self.players[nick]
        self.delayed_privmsg(connection, self.channel, f"{nick}: {player.status()}", delay)

    def handle_fite(self, connection, nick, target, delay):
        if nick not in self.players:
            self.players[nick] = Player(nick)
            save_players(self.players)
        player = self.players[nick]

        if target.startswith("NPC_"):
            if target not in self.npcs:
                self.npcs[target] = NPC(target)
            npc = self.npcs[target]
            delay = combat(connection, self.channel, player, npc, self.delayed_privmsg, delay)
        else:
            if target not in self.players:
                self.delayed_privmsg(connection, self.channel, f"{nick}: {target} is not a valid target.", delay)
                return
            opponent = self.players[target]
            delay = combat(connection, self.channel, player, opponent, self.delayed_privmsg, delay)
            save_players(self.players)
            self.update_leaderboard(connection, delay)
    def handle_show_leaderboard(self, connection, delay):
        self.announce_leaderboard()

    def handle_weapon(self, connection, nick, weapon, delay):
        if nick not in self.players:
            self.players[nick] = Player(nick)
            save_players(self.players)
        player = self.players[nick]
        player.weapon = weapon
        save_players(self.players)
        self.delayed_privmsg(connection, self.channel, f"{nick}: weapon set to {weapon}.", delay)

    def handle_armor(self, connection, nick, armor, delay):
        if nick not in self.players:
            self.players[nick] = Player(nick)
            save_players(self.players)
        player = self.players[nick]
        player.armor = armor
        save_players(self.players)
        self.delayed_privmsg(connection, self.channel, f"{nick}: armor set to {armor}.", delay)

    def announce_leaderboard(self):
        sorted_players = sorted(self.players.values(), key=lambda p: p.level, reverse=True)
        leaderboard = []
        for i, player in enumerate(sorted_players[:10]):
            status = "\x033Alive\x03" if player.alive else "\x034Dead\x03"
            modified_name = f"{player.name[:1]}\u200B{player.name[1:]}"
            leaderboard.append(f"{i+1}. {modified_name} (Level {player.level}) - {status} - K:{player.kills} D:{player.deaths}")
        
        delay = 0
        self.delayed_privmsg(self.connection, self.channel, "Mr. Plow's Leaderboard:", delay)
        delay += 1
        for entry in leaderboard:
            self.delayed_privmsg(self.connection, self.channel, entry, delay)
            delay += 1
    def update_leaderboard(self, connection, delay):
        sorted_players = sorted(self.players.values(), key=lambda p: p.level, reverse=True)
        new_leaderboard = [player.name for player in sorted_players[:10]]
        if new_leaderboard != self.leaderboard:
            for i, player_name in enumerate(new_leaderboard):
                if player_name not in self.leaderboard:
                    self.delayed_privmsg(connection, self.channel, f"Mr. Plow says: Congratulations {player_name}! You've moved up to position {i+1} on the leaderboard!", delay)
                    delay += 1
            self.leaderboard = new_leaderboard

    def delayed_privmsg(self, connection, channel, message, delay):
        Timer(delay, connection.privmsg, args=[channel, message]).start()

    def handle_schedule(self, connection, nick, delay):
        now = time.time()
        reset_time = self.next_reset - now if self.next_reset else None
        announcement_time = self.next_announcement - now if self.next_announcement else None

        reset_str = self.format_time_difference(reset_time) if reset_time else "not scheduled"
        announcement_str = self.format_time_difference(announcement_time) if announcement_time else "not scheduled"

        self.delayed_privmsg(connection, self.channel, f"{nick}: Next reset in {reset_str}, next announcement in {announcement_str}.", delay)
    def handle_scheduled_reset(self):
        self.next_reset = time.time() + (2 * 60 * 60)
        Timer(2 * 60 * 60, self.handle_scheduled_reset).start()
        self.reset_all()
        self.save_schedule()
    def handle_reset_now(self, connection, delay):
        self.reset_all()
        self.delayed_privmsg(connection, self.channel, "Reset triggered by Soylent/Staff member.", delay)
    def reset_all(self):
        for player in self.players.values():
            player.hp = player.max_hp
        for npc in self.npcs.values():
            npc.hp = 50
        random_player = random.choice(list(self.players.values()))
        random_player.hp = random_player.level + 100
        save_players(self.players)
        self.delayed_privmsg(self.connection, self.channel, "The good fairy has come along and revived everyone.", 0)
        self.delayed_privmsg(self.connection, self.channel, f"{random_player.name} has been blessed with extra health!", 1)

    def format_time_difference(self, seconds):
        if seconds is None:
            return "unknown"
        minutes, seconds = divmod(seconds, 60)
        hours, minutes = divmod(minutes, 60)
        return f"{int(hours)} hours and {int(minutes)} minutes"

if __name__ == "__main__":
    bot = IRCBot("#fite", "MrPlow", "irc.soylentnews.org")
    bot.start()
