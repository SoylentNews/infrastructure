import random
import threading
from constants import message_templates, locations, effectiveness_pools
from utils import roll_once

def noping(name):
    return f"{name[:1]}\u200B{name[1:]}"

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

def combat(connection, channel, player, opponent, delay_function, delay):
    if not player.alive:
        delay_function(connection, channel, f"{noping(player.name)}, how can you participate when you're not active? Try again tomorrow.", delay)
        return delay
    if not opponent.alive:
        delay_function(connection, channel, f"{noping(opponent.name)} is currently inactive. Try engaging with someone who's active.", delay)
        return delay

    while player.alive and opponent.alive:
        player_initiative = roll_once(20)
        opponent_initiative = roll_once(20)
        surprise_attack = False

        while player_initiative == opponent_initiative:
            player_initiative = roll_once(20)
            opponent_initiative = roll_once(20)

        if player_initiative > opponent_initiative:
            attacker, defender = player, opponent
            if roll_once(20) == 2:
                surprise_attack = True
                delay_function(connection, channel, f"{noping(defender.name)} has been caught by surprise by {noping(attacker.name)}!", delay)
                delay += 1
            else:
                surprise_attack = False
        else:
            attacker, defender = opponent, player

        if surprise_attack:
            delay = perform_attack(connection, channel, attacker, defender, delay, delay_function)
            if not defender.alive:
                break

        while attacker.alive and defender.alive:
            delay = perform_attack(connection, channel, attacker, defender, delay, delay_function)
            if not defender.alive:
                break
            attacker, defender = defender, attacker

    return delay

def perform_attack(connection, channel, attacker, defender, delay, delay_function):
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
                attacker=f"{noping(attacker.name)} ({attacker.hp}/{attacker.max_hp})",
                defender=f"{noping(defender.name)} ({defender.hp}/{defender.max_hp})",
                location=hit_location,
                effectiveness=hit_effectiveness,
                damage=f"\x02\x0304{damage}\x0F",
                weapon=attacker.weapon,
                armor=defender.armor)

    delay_function(connection, channel, message, delay)
    delay += 1

    if attack_roll > 10 and attack_roll <= 20: # not a fail, over AC check
        defender.hp -= damage
        if defender.hp <= 0:
            delay_function(connection, channel, f"{noping(defender.name)} has been defeated by {noping(attacker.name)}.", delay)
            delay += 1
            attacker.level += 1
            attacker.hp += 1
            attacker.kills += 1
            defender.deaths += 1
            if defender.level >= 1 and (defender.level > 15 or roll_once(2) == 1):
                defender.level -= 1

    return delay