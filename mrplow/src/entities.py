class Player:
    def __init__(self, name, level=1, hp=11, weapon='fists', armor='clothes', kills=0, deaths=0):
        self.name = name
        self.level = level
        self.weapon = weapon
        self.armor = armor
        self.hp = hp
        self.kills = kills
        self.deaths = deaths

    @property
    def max_hp(self):
        return self.level + 10

    @property
    def alive(self):
        return self.hp > 0

    def status(self):
        return f"{self.name} level: {self.level}, hp: {self.hp}/{self.max_hp}, weapon: '{self.weapon}', armor: '{self.armor}', kills: {self.kills}, deaths: {self.deaths}"

    def to_dict(self):
        return {
            "name": self.name,
            "level": self.level,
            "hp": self.hp,
            "weapon": self.weapon,
            "armor": self.armor,
            "kills": self.kills,
            "deaths": self.deaths
        }

    @staticmethod
    def from_dict(data):
        return Player(
            name=data["name"],
            level=data["level"],
            hp=data["hp"],
            weapon=data["weapon"],
            armor=data["armor"],
            kills=data.get("kills", 0),
            deaths=data.get("deaths", 0)
        )

class NPC:
    def __init__(self, name):
        self.name = name
        self.hp = 50
        self.weapon = 'claws'
        self.alive = True