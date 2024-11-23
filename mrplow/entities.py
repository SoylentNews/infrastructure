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
        return self.level + 10

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