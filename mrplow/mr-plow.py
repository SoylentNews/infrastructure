import random
import irc.bot
import irc.strings
import json
import os
import time
from threading import Timer
from message_templates import message_templates

DATABASE_FILE = "players.json"

class Player:
    def __init__(self, name, level=1, hp=100, weapon='fists', armor='clothes', alive=True):
        self.name = name
        self.level = level
        self.hp = hp
        self.weapon = weapon
        self.armor = armor
        self.alive = alive

    @property
    def max_hp(self):
        return 100 + (self.level - 1) * 10

    def status(self):
        return f"{self.name} level: {self.level}, hp: {self.hp}/{self.max_hp}, weapon: '{self.weapon}', armor: '{self.armor}'"

    def to_dict(self):
        return {
            "name": self.name,
            "level": self.level,
            "hp": self.hp,
            "weapon": self.weapon,
            "armor": self.armor,
            "alive": self.alive
        }

    @staticmethod
    def from_dict(data):
        return Player(
            name=data["name"],
            level=data["level"],
            hp=data["hp"],
            weapon=data["weapon"],
            armor=data["armor"],
            alive=data["alive"]
        )

class NPC:
    def __init__(self, name):
        self.name = name
        self.hp = 50
        self.weapon = 'claws'
        self.alive = True
        
class IRCBot(irc.bot.SingleServerIRCBot):
    def __init__(self, channel, nickname, server, port=6667):
        irc.bot.SingleServerIRCBot.__init__(self, [(server, port)], nickname, nickname)
        self.channel = channel
        self.players = self.load_players()
        self.npcs = {}
        self.leaderboard = []
        self.schedule_reset()
        self.schedule_leaderboard_announcement()

    def clean_nick(self, nick):
        return re.sub(r'^[\@\+\~\&\%]', '', nick)

    def on_welcome(self, connection, event):
        connection.join(self.channel)
        connection.privmsg("ChanServ", f"OP {self.channel}")
        connection.privmsg(self.channel, "MrPlow has joined the channel!")
        connection.names(self.channel)

    def on_namreply(self, connection, event):
        for nick in event.arguments[2].split():
            clean_nick = self.clean_nick(nick)
            if clean_nick not in self.players:
                self.players[clean_nick] = Player(clean_nick)
                self.save_players()

    def on_join(self, connection, event):
        nick = event.source.nick
        clean_nick = self.clean_nick(nick)
        if clean_nick not in self.players:
            self.players[clean_nick] = Player(clean_nick)
            self.save_players()
            connection.privmsg(self.channel, f"Welcome {clean_nick}! You have been added to the game.")


    def on_pubmsg(self, connection, event):
        message = event.arguments[0]
        nick = event.source.nick

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

    def handle_status(self, connection, nick):
        if nick not in self.players:
            self.players[nick] = Player(nick)
            self.save_players()
        player = self.players[nick]
        connection.privmsg(self.channel, f"{nick}: {player.status()}")

    def handle_fite(self, connection, nick, target):
        if nick not in self.players:
            self.players[nick] = Player(nick)
            self.save_players()
        player = self.players[nick]

        if target.startswith("NPC_"):
            if target not in self.npcs:
                self.npcs[target] = NPC(target)
            npc = self.npcs[target]
            self.combat(connection, player, npc)
        else:
            if target not in self.players:
                connection.privmsg(self.channel, f"{nick}: {target} is not a valid target.")
                return
            opponent = self.players[target]
            self.combat(connection, player, opponent)

    def handle_weapon(self, connection, nick, weapon):
        if nick not in self.players:
            self.players[nick] = Player(nick)
            self.save_players()
        player = self.players[nick]
        player.weapon = weapon
        self.save_players()
        connection.privmsg(self.channel, f"{nick}: weapon set to {weapon}.")

    def handle_armor(self, connection, nick, armor):
        if nick not in self.players:
            self.players[nick] = Player(nick)
            self.save_players()
        player = self.players[nick]
        player.armor = armor
        self.save_players()
        connection.privmsg(self.channel, f"{nick}: armor set to {armor}.")

    def handle_revive_all(self, connection):
        for player in self.players.values():
            player.hp = player.max_hp
            player.alive = True
        for npc in self.npcs.values():
            npc.hp = 50
            npc.alive = True
        self.save_players()
        connection.privmsg(self.channel, "The good fairy has come along and revived everyone.")

    def combat(self, connection, player, opponent):
        if not player.alive:
            connection.privmsg(self.channel, f"{player.name} is dead and cannot fight.")
            return
        if not opponent.alive:
            connection.privmsg(self.channel, f"{opponent.name} is already dead.")
            return

        degrees_of_hits = ["light", "moderate", "heavy", "critical", "defense"]
        locations = ["head", "arm", "leg", "torso"]
        effectiveness = ["barely", "solidly", "devastatingly"]

        while player.alive and opponent.alive:
            player_attack = random.randint(1, 20)
            opponent_attack = random.randint(1, 20)

            if player_attack > opponent_attack:
                damage = random.randint(5, 15)
                hit_degree = determine_hit_degree(damage)
                if random.random() < 0.1:  # 10% chance for defense
                    hit_degree = "defense"
                hit_location = random.choice(locations)
                hit_effectiveness = random.choice(effectiveness)
                if hit_degree == "defense":
                    damage = int(damage * 0.5)  # Reduce damage by 50%
                    message_template = random.choice(message_templates["defense"])
                else:
                    opponent.hp -= damage
                    message_template = random.choice(message_templates[hit_degree])
                message = message_template.format(
                    attacker=player.name,
                    defender=opponent.name,
                    location=hit_location,
                    effectiveness=hit_effectiveness,
                    damage=damage,
                    weapon=player.weapon,
                    armor=opponent.armor
                )
                connection.privmsg(self.channel, message)
            else:
                damage = random.randint(5, 15)
                hit_degree = determine_hit_degree(damage)
                if random.random() < 0.1:  # 10% chance for defense
                    hit_degree = "defense"
                hit_location = random.choice(locations)
                hit_effectiveness = random.choice(effectiveness)
                if hit_degree == "defense":
                    damage = int(damage * 0.5)  # Reduce damage by 50%
                    message_template = random.choice(message_templates["defense"])
                else:
                    player.hp -= damage
                    message_template = random.choice(message_templates[hit_degree])
                message = message_template.format(
                    attacker=opponent.name,
                    defender=player.name,
                    location=hit_location,
                    effectiveness=hit_effectiveness,
                    damage=damage,
                    weapon=opponent.weapon,
                    armor=player.armor
                )
                connection.privmsg(self.channel, message)

            if player.hp <= 0:
                player.alive = False
                connection.privmsg(self.channel, f"{player.name} has been defeated by {opponent.name}.")
            if opponent.hp <= 0:
                opponent.alive = False
                connection.privmsg(self.channel, f"{opponent.name} has been defeated by {player.name}.")

        self.save_players()
        self.update_leaderboard(connection)

    def load_players(self):
        if os.path.exists(DATABASE_FILE):
            with open(DATABASE_FILE, "r") as f:
                data = json.load(f)
                return {name: Player.from_dict(player_data) for name, player_data in data.items()}
        return {}

    def save_players(self):
        with open(DATABASE_FILE, "w") as f:
            json.dump({name: player.to_dict() for name, player in self.players.items()}, f)

    def schedule_reset(self):
        now = time.time()
        next_reset = now + (24 * 60 * 60) - (now % (24 * 60 * 60))
        Timer(next_reset - now, self.reset_players).start()

    def reset_players(self):
        for player in self.players.values():
            player.hp = player.max_hp
            player.alive = True
        self.save_players()
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

def determine_hit_degree(damage):
    if damage <= 5:
        return "light"
    elif damage <= 10:
        return "moderate"
    elif damage <= 15:
        return "heavy"
    else:
        return "critical"

if __name__ == "__main__":
    bot = IRCBot("#fite", "MrPlow", "irc.soylentnews.org")
    bot.start()