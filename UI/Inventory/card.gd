extends Node2D
class_name Card
signal pressed(card: Card)
signal dragged(card: Card, direction: int)

var deck: bool = false: set = set_deck
var skip: bool = false: set = set_skip
var attack_data: Attack = null: set = set_attack_data
var focus = false: set = set_focus
var still_animating = false
var reanimate: bool = false
var hovered = false
var tool_tipped = false
var was_focussed = false
var cooldown = 0: set = _set_cooldown
var prevent_hover = false
var shown = false
var selected = false: set = set_selected
var width = 100
func _ready() -> void:
	Messenger.attack_upgraded.connect(on_attack_upgraded)
	Messenger.running_turns.connect(on_running_turns)
	Messenger.end_of_turn.connect(_on_end_of_turn)
	Messenger.prevent_hover.connect(on_running_turns)
	Messenger.attacks_executed.connect(_on_attacks_executed)
	Messenger.next_level.connect(_on_end_of_level)
	Messenger.hide_tool_tips.connect(_on_hide_tooltip)
	on_running_turns(State.gm.running_turns)
	$AnimationPlayer.play("show")
	width = $Cardbase.texture.get_width()
var covered = false

func _on_end_of_level():
	cooldown = 0

func _on_end_of_turn():
	if cooldown > 0:
		cooldown -= 1

func _set_cooldown(v):
	var went_down = cooldown > 0 and v == 0
	cooldown = v
	if v > 0:
		if shown:
			$AnimationPlayer.play_backwards("show")
			shown = false
	else:
		if not shown:
			$AnimationPlayer.play("show")
			shown = true

func _on_hide_tooltip():
	print("Hiding tooltip")
	if tool_tipped:
		$Cardbase/Tooltip.hide_tooltip()
		tool_tipped = false

func _on_attacks_executed(asdf):
	if selected:
		selected = false
		focus = false

func on_running_turns(running: bool):
	if running:
		prevent_hover = true
	else:
		prevent_hover = false

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

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("show_tool_tip") and focus:
		if not tool_tipped:
			print("Showing tooltip")
			Messenger.hide_tool_tips.emit()
			$Cardbase/Tooltip.show_tooltip()
			await get_tree().create_timer(0.3).timeout
			tool_tipped = true
		else:
			print("Hiding tooltip")
			$Cardbase/Tooltip.hide_tooltip()
			await get_tree().create_timer(0.3).timeout
			tool_tipped = false
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released() and mouse_down and signalled:
			handle_drop()
var original_position = Vector2()
var signalled = false
func _process(delta: float) -> void:
	if mouse_down and not skip and not deck:
		z_index = 100
		var mouse = get_global_mouse_position()
		var distance = mouse.distance_to(original_position)
		if distance > 10:
			var clampedx = clamp(mouse.x, width * -2, width * 2)
			global_position = Vector2(clampedx, global_position.y)
		else:
			global_position = original_position
		if not signalled:
			if global_position.distance_to(original_position) > 1:
				print("SIGNALLING")
				Messenger.prevent_hover.emit(true)
				signalled = true

var mouse_down = false
var mouse_direction = 0

func handle_drop():
	Messenger.prevent_hover.emit(false)
	signalled = false
	mouse_down = false
	if global_position.distance_to(original_position) > 10:
		var direction = 0
		if global_position.x > original_position.x:
			direction = 1
		else:
			direction = -1

		# how many?
		var distance = global_position.distance_to(original_position)
		if distance > width * 1.5:
			direction *= 2
		
		print("Dragged")
		emit_signal("dragged", self, direction)
		mouse_down = false
		z_index = 0
		return true
	return false

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if prevent_hover and not mouse_down and not skip and not deck:
				return
			original_position = global_position
			mouse_down = true
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			var dropped = handle_drop()
			if not dropped:
				emit_signal("pressed", self)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if not tool_tipped:
				Messenger.hide_tool_tips.emit()
				$Cardbase/Tooltip.show_tooltip()
				tool_tipped = true
			else:
				$Cardbase/Tooltip.hide_tooltip()
				tool_tipped = false
	if event is InputEventScreenDrag:
		print("Dragged")

func set_focus(v):
	if v:
		modulate = Color(1, 1, 1, 1)
	else:
		modulate = Color(1, 1, 1, 0.8)
	if selected:
		return
	var was = focus
	var changed = focus != v
	focus = v
	if not changed or not shown:
		return
	if prevent_hover:
		return
	if focus:
		modulate = Color(1, 1, 1, 1)
		$AnimationPlayer.play("focus_hover")
	else:
		modulate = Color(1, 1, 1, 0.8)
		$AnimationPlayer.play_backwards("focus_hover")
		$Cardbase/Tooltip.hide_tooltip()


func _on_area_2d_mouse_exited() -> void:
	if mouse_down:
		return
	if selected:
		return
	hovered = false
	get_parent().focus_card_hover(self)
	if tool_tipped:
		$Cardbase/Tooltip.hide_tooltip()
		tool_tipped = false
	pass # Replace with function body.


func _on_area_2d_mouse_entered() -> void:
	if prevent_hover:
		print("Prevent hover")
		return
	if not hovered:
		hovered = true
		get_parent().focus_card_hover(self)
	pass # Replace with function body.

func manual_tool_tip_show() -> void:
	$Cardbase/Tooltip.show_tooltip()
	tool_tipped = true


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "show":
		shown = true
	pass # Replace with function body.


func set_selected(v):
	if v and cooldown > 0:
		return
	selected = v
	if selected:
		$Cardbase/Label.hide()
		set_focus(true)
	else:
		$Cardbase/Label.show()
		prevent_hover = false
		hovered = false
		focus = true
		focus = false
		$Cardbase/Tooltip.hide_tooltip()
		modulate = Color(1, 1, 1, 0.8)
		$AnimationPlayer.play_backwards("focus_hover")
		$Cardbase/Tooltip.hide_tooltip()
