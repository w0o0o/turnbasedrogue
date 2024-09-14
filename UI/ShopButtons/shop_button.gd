extends TextureButton

class_name ShopButton
var attack_data: Attack:
	set(d):
		attack_data = d
		setup_ui()

var mana_cost: int = 0:
	set(v):
		mana_cost = v
		if v > 0:
			modulate = Color(1, 1, 1, 0.5)
		else:
			modulate = Color(1, 1, 1, 1)

func _ready() -> void:
	Messenger.end_of_turn.connect(_on_end_of_turn)

func _on_end_of_turn():
	if mana_cost > 0:
		mana_cost -= 1
	pass

func setup_ui():
	if attack_data == null:
		return
	$Power.text = str(attack_data.damage)
	

func buy():
	Messenger.attack_added_to_library.emit(attack_data)
	pass
func open(a):
	scale = Vector2(0, 0)
	show()
	attack_data = a
	var tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.2)
func close():
	var tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(0, 0), 0.2)

	