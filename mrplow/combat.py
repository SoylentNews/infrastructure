import random
from constants import message_templates, locations, effectiveness_pools
from utils import roll_once

def determine_hit_degree(damage):
    if damage <= 3:
        return "light"
    elif damage <= 7:
        return "moderate"
    else: # damage < 12:
        return "heavy"
    

def roll_dmg():
    roll = roll_once(8)
    total = 0
    total += roll
    while roll == 8:
        roll = roll_once(8)
        total += roll
    return total




def combat(connection, channel, player, opponent):
    if not player.alive:
        connection.privmsg(channel, f"{player.name}, how can you participate when you're not active? Try again tomorrow.")
        return
    if not opponent.alive:
        connection.privmsg(channel, f"{opponent.name} is currently inactive. Try engaging with someone who's active.")
        return

    while player.alive and opponent.alive:
        player_initiative = roll_once(20)
        opponent_initiative = roll_once(20)

        while player_initiative == opponent_initiative:
            player_initiative = roll_once(20)
            opponent_initiative = roll_once(20)

        if player_initiative > opponent_initiative:
            attacker, defender = player, opponent
        else:
            attacker, defender = opponent, player

        if roll_once(20) == 2:
            surprise_attack = True
        else:
            surprise_attack = False

        if surprise_attack:
            perform_attack(connection, channel, attacker, defender)
            if not defender.alive:
                break

        while attacker.alive and defender.alive:
            perform_attack(connection, channel, attacker, defender)
            if not defender.alive:
                break
            attacker, defender = defender, attacker

def perform_attack(connection, channel, attacker, defender):
    attack_roll = roll_once(20)
    if attack_roll == 20:
        damage = roll_dmg() * 2
        hit_degree = "critical"
        hit_effectiveness = random.choice(effectiveness_pools[hit_degree])
    elif attack_roll > 10:
        damage = roll_dmg()
        hit_degree = determine_hit_degree(damage)
        hit_effectiveness = random.choice(effectiveness_pools[hit_degree])
    elif attack_roll == 1:
        hit_degree = "fail"
        hit_effectiveness = "missed"
        damage = 0
    else:
        hit_degree = "defense"
        damage = 0
        hit_effectiveness = "blocked"

    hit_location = random.choice(locations)
    message_template = random.choice(message_templates[hit_degree])
    message = message_template.format(
                attacker=attacker.name,
                defender=defender.name,
                location=hit_location,
                effectiveness=hit_effectiveness,
                damage=damage,
                weapon=attacker.weapon,
                armor=defender.armor    );

    connection.privmsg(channel, message)

    if attack_roll > 10 and attack_roll <= 20: # not a fail, over AC check
        defender.hp -= damage
        if defender.hp <= 0:
            defender.alive = False
            connection.privmsg(channel, f"{defender.name} has been defeated by {attacker.name}.")
            attacker.level += 1
            attacker.hp += 1
            if defender.level >= 1 and (defender.level > 15 or roll_once(2) == 1):
                defender.level -= 1



   # self.save_players()
   # self.update_leaderboard(connection)