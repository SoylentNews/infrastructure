import re
import json
import os
from entities import Player
import random

def roll_once(sides):
    random_number = random.randint(1, sides)
    return random_number

DATABASE_FILE = "players.json"

def clean_nick(nick):
    return re.sub(r'^[\@\+\~\&\%]', '', nick)

def load_players():
    if os.path.exists(DATABASE_FILE):
        with open(DATABASE_FILE, "r") as f:
            data = json.load(f)
            return {name: Player.from_dict(player_data) for name, player_data in data.items()}
    return {}

def save_players(players):
    with open(DATABASE_FILE, "w") as f:
        json.dump({name: player.to_dict() for name, player in players.items()}, f)