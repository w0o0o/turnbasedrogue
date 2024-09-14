extends Node

signal death()
signal attack_added_to_queue(attack)
signal attack_selected(attack)
signal attack_added_to_library(attack: Attack)
signal attacks_executed(attacks)
signal health_updated(health)
signal running_turns()
signal end_of_turn()
signal reset()
signal next_level()
signal move_to_level(room: Room)
signal level_started()
signal disable_inventory(disable)
signal blacksmith_opened(open, anvil)
signal blacksmith_item_selected(attack)
signal skip_turn()
signal mana_changed(mana)
signal no_attacks()

signal shake_camera(strength: float, duration: float)

signal attack_upgraded(attack: Attack)