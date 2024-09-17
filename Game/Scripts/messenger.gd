extends Node

signal death()
signal attack_added_to_queue(attack)
signal attack_selected(attack)
signal attack_added_to_library(attack: Attack)
signal attacks_executed(attacks)
signal health_updated(health)
signal running_turns(v)
signal end_of_turn()
signal reset()
signal next_level()
signal move_to_level(room: Room)
signal level_started()
signal disable_inventory(disable)
signal blacksmith_opened(open, anvil)
signal hide_tool_tips()
signal blacksmith_item_selected(attack)
signal skip_turn()
signal prevent_hover(running: bool)
signal mana_changed(mana)
signal no_attacks()
signal force_tutorial_input(input_name: String)
signal speech_bubble(text: String, pos: Vector2, duration: float, input_action: String)
signal speech_bubble_hidden()
signal shake_camera(strength: float, duration: float)
signal attack_upgraded(attack: Attack)
signal reorder_queue(queue: Array)