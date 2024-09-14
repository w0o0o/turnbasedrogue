extends Node2D
class_name Card
signal pressed(card: Card)

var deck: bool = false: set = set_deck
var skip: bool = false: set = set_skip
var attack_data: Attack = null: set = set_attack_data
var focus = false: set = set_focus
var still_animating = false
var reanimate: bool = false
var hovered = false
var tool_tipped = false
var was_focussed = false
var prevent_hover = false
var shown = false

func _ready() -> void:
	Messenger.attack_upgraded.connect(on_attack_upgraded)
	Messenger.running_turns.connect(on_running_turns)
	on_running_turns(State.gm.running_turns)
	Messenger.mana_changed.connect(on_mana_changed)
	$AnimationPlayer.play("show")


func on_mana_changed(mana: int):
	if attack_data:
		if attack_data.mana_cost > mana:
			$Cardbase.modulate = Color(1, 1, 1, 0.2)
		else:
			$Cardbase.modulate = Color.WHITE

func on_running_turns(running: bool):
	print("Running turns: ", running)
	if running:
		prevent_hover = true
		if focus:
			$AnimationPlayer.play_backwards("focus_hover")
			%ManaLabel.hide_mana()
			focus = false
			was_focussed = true
	else:
		prevent_hover = false
		if was_focussed:
			$AnimationPlayer.play("focus_hover")
			%ManaLabel.show_mana()
			focus = true
			was_focussed = false

func on_attack_upgraded(attack: Attack):
	if attack_data and attack_data.name == attack.name:
		attack_data = attack

func set_attack_data(v):
	attack_data = v
	if attack_data:
		$Cardbase.modulate = Color.WHITE
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
		%ManaLabel.mana_count = attack_data.mana_cost
func set_deck(v):
	deck = v
	if deck:
		$Cardbase.modulate = Color.PALE_VIOLET_RED
		$Cardbase/Label.text = "Draw"
		$Cardbase/Tooltip.set_tooltip("Draw a new card")
		%ManaLabel.mana_count = 0
		%ManaLabel.hide()

func set_skip(v):
	skip = v
	if skip:
		$Cardbase.modulate = Color.CADET_BLUE
		$Cardbase/Label.text = "Skip"
		$Cardbase/Tooltip.set_tooltip("Skip this turn")
		%ManaLabel.mana_count = 0
		%ManaLabel.hide()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("show_tool_tip") and focus:
		if not tool_tipped:
			$Cardbase/Tooltip.show_tooltip()
			await get_tree().create_timer(0.3).timeout
			tool_tipped = true
		else:
			$Cardbase/Tooltip.hide_tooltip()
			await get_tree().create_timer(0.3).timeout
			tool_tipped = false

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseMotion:
		if not focus:
			hovered = true
			get_parent().focus_card_hover(self)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("pressed", self)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if not tool_tipped:
				$Cardbase/Tooltip.show_tooltip()
				tool_tipped = true
			else:
				$Cardbase/Tooltip.hide_tooltip()
				tool_tipped = false

func set_focus(v):
	var was = focus
	var changed = focus != v
	focus = v
	if not changed or not shown:
		return
	if prevent_hover:
		return
	if focus:
		$AnimationPlayer.play("focus_hover")
		%ManaLabel.show_mana()
	else:
		$AnimationPlayer.play_backwards("focus_hover")
		%ManaLabel.hide_mana()
		$Cardbase/Tooltip.hide_tooltip()


func _on_area_2d_mouse_exited() -> void:
	hovered = false
	get_parent().focus_card_hover(self)
	if tool_tipped:
		$Cardbase/Tooltip.hide_tooltip()
		tool_tipped = false
	pass # Replace with function body.


func _on_area_2d_mouse_entered() -> void:
	# await get_tree().create_timer(5.0).timeout
	# if hovered:
	# 	$Cardbase/Tooltip.show_tooltip()
	# 	tool_tipped = true
	pass # Replace with function body.

func manual_tool_tip_show() -> void:
	$Cardbase/Tooltip.show_tooltip()
	tool_tipped = true


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "show":
		shown = true
	pass # Replace with function body.
