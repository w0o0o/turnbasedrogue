extends TextureButton

class_name AttackButton
var queued: bool = false
var attack_data: Attack:
	set(d):
		attack_data = d
		update()
var focussed = false
var mana_cost: int = 0:
	set(v):
		mana_cost = v
		var gb = 0 if focussed else 1
		if v > 0:
			modulate = Color(1, gb, gb, 0.5)
		else:
			modulate = Color(1, gb, gb, 1)
func _ready() -> void:
	Messenger.end_of_turn.connect(_on_end_of_turn)

func _on_end_of_turn():
	if mana_cost > 0:
		mana_cost -= 1
	pass

func update():
	if attack_data == null:
		return
	$Power.text = str(attack_data.damage)
	
func _input(event: InputEvent) -> void:
	if not queued:
		return
	if not focussed:
		return
	if Input.is_action_just_pressed("move_queued_left"):
		get_parent().move_attack(self, -1)
	if Input.is_action_just_pressed("move_queued_right"):
		get_parent().move_attack(self, 1)

func _on_focus_exited() -> void:
	focussed = false
	print("Focus exited")
	var v = 1 if mana_cost == 0 else 0.5
	modulate = Color(1, 1, 1, v)
	pass # Replace with function body.

func _on_focus_entered() -> void:
	focussed = true
	print("Focus entered")
	var v = 1 if mana_cost == 0 else 0.5
	modulate = Color(1, 0, 0, v)
	pass # Replace with function body.
