extends Node2D
class_name Card

signal pressed(card: Card)

var selected = false
var focused = false: set = _set_focused
var hovered = false
var tool_tip_shown = false

var deck: bool = false: set = set_deck
var skip: bool = false: set = set_skip
var attack_data: Attack = null: set = set_attack_data

var cooldown = 0: set = _set_cooldown

var width = 100

func _ready() -> void:
	Messenger.attack_executed.connect(_on_attack_executed)
	Messenger.attack_upgraded.connect(on_attack_upgraded)
	Messenger.level_started.connect(_on_level_started)
	Messenger.end_of_turn.connect(_on_end_of_turn)
	$AnimationPlayer.play("show_card")

func _on_attack_executed(attack: Attack):
	if attack == attack_data:
		selected = false
		cooldown = attack.cooldown

func _on_level_started():
	selected = false
	cooldown = 0

func _on_end_of_turn():
	if cooldown > 0:
		cooldown -= 1

func _set_cooldown(v):
	var changed = true if (cooldown != 0 and v == 0) or (cooldown == 0 and v != 0) else false
	cooldown = v
	if cooldown < 0:
		cooldown = 0
	if cooldown > 0 and changed:
		$AnimationPlayer.play_backwards("show_card")
	elif cooldown == 0 and changed:
		$AnimationPlayer.play("show_card")
		
func on_attack_upgraded(attack: Attack):
	if attack_data and attack_data.name == attack.name:
		attack_data = attack

func set_attack_data(v):
	attack_data = v
	if attack_data:
		$Cardbase/Label.text = str(attack_data.damage)
		var desc = "%s%s\n%s Damage" % [
			attack_data.name,
			attack_data.description,
			str(attack_data.damage)
		]
		desc += "\nMana cost: %s" % str(attack_data.mana_cost)
		if attack_data.projectile:
			desc += "\nProjectile"
		if attack_data.piercing > 1:
			desc += "\nPiercing: %s" % str(attack_data.piercing)
		if attack_data.reverse:
			desc += "\nHits the furthest enemy first"
		if attack_data.ramming:
			desc += "\nMoves towards the enemy in front"
		if attack_data.damage_cells.size() > 1:
			var infront = false
			var infront_count = 0
			var behind = false
			var behind_count = 0
			for dc in attack_data.damage_cells:
				if dc > 0:
					infront = true
					infront_count += 1
				if dc < 0:
					behind = true
					behind_count += 1
			var suffix = "s" if infront_count > 1 else ""
			var suffix2 = "s" if behind_count > 1 else ""
			if infront and behind:
				desc += "\nHits %s cell%s in front and %s cell%s behind" % [str(infront_count), suffix, str(behind_count), suffix2]
			elif infront:
				desc += "\nHits %s cell%s in front" % [str(infront_count), suffix]
			elif behind:
				desc += "\nHits %s cell%s behind" % [str(behind_count), suffix]
		$Cardbase/Tooltip.set_tooltip(desc)
		if attack_data.icon != null:
			$Cardbase/WeaponIcon.texture = attack_data.icon
		else:
			$Cardbase/WeaponIcon.frame = attack_data.icon_frame

func set_deck(v):
	deck = v
	if deck:
		$Cardbase.modulate = Color.PALE_VIOLET_RED
		$Cardbase/Label.text = "!"
		$Cardbase/Tooltip.set_tooltip("Discard current hand and draw 3 new cards.\nCosts 3 mana")

func set_skip(v):
	skip = v
	if skip:
		$Cardbase.modulate = Color.CADET_BLUE
		$Cardbase/Label.text = "Skip"
		$Cardbase/Tooltip.set_tooltip("Skip this turn")

func _on_area_2d_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Pressed")
			if cooldown == 0:
				emit_signal("pressed", self)


func _set_focused(v):
	var changed = focused != v
	focused = v
	if focused:
		$Cardbase.scale = Vector2(1.1, 1.1)
		$Cardbase.modulate = Color(1, 1, 1, 1)
	else:
		$Cardbase.scale = Vector2(1, 1)
		$Cardbase.modulate = Color(1, 1, 1, 0.5)
	if changed:
		_set_focused_ui(focused)

func _set_focused_ui(focused):
	pass
