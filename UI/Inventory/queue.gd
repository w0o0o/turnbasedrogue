extends HBoxContainer

@export var attack_scene: PackedScene = null

func _ready() -> void:
	Messenger.attack_added_to_queue.connect(_on_attack_added_to_queue)
	Messenger.attacks_executed.connect(_on_attacks_executed)
	Messenger.death.connect(_on_death)
	Messenger.next_level.connect(_on_next_level)
	Messenger.no_attacks.connect(_on_no_attacks)

func has_focussed_attack() -> bool:
	for child in get_children():
		if child.has_focus():
			return true
	return false

func focus_queue() -> void:
	if has_focussed_attack():
		print("Already has focus")
		return
	for child in get_children():
		if child.visible:
			child.grab_focus()
			print("Focussing on: ", child)
			return

func find_child_index(child: Node) -> int:
	for i in range(get_child_count()):
		if get_child(i) == child:
			return i
	return -1

func move_attack(attack: AttackButton, direction: int) -> void:
	var index = find_child_index(attack)
	var new_index = index + direction
	if new_index < 0 or new_index >= get_child_count():
		print("Invalid move")
		return
	remove_child(attack)
	# remove all children and re-add them in the correct order
	var children = []
	for i in range(get_child_count()):
		if i == index:
			continue
		children.append(get_child(i))
		remove_child(get_child(i))
	print("Moving attack from ", index, " to ", new_index, " With: ", get_child_count(), " children")
	if new_index == children.size() + 1:
		children.append(attack)
	else:
		children.insert(new_index, attack)
	for child in children:
		add_child(child)
	attack.grab_focus()
	

func _on_death():
	for child in get_children():
		child.queue_free()
	hide()

func _on_next_level():
	for child in get_children():
		child.queue_free()


func _on_attack_added_to_queue(attack: Attack):
	show()
	var attack_instance = attack_scene.instantiate()
	attack_instance.attack_data = attack
	attack_instance.queued = true
	add_child(attack_instance)
	pass

func _on_attacks_executed(_attacks):
	hide()
	for child in get_children():
		child.queue_free()
	pass


func _on_focus_entered() -> void:
	print("QUEUE FOCUS ENTERED")
	pass # Replace with function body.

func _on_no_attacks():
	print("No attacks")
	focus_queue()
	pass