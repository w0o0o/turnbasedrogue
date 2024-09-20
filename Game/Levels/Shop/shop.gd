extends Node2D

var selected_box = 0
var moving = false
var closed = true

func select_box(box):
	var boxcount = $Items.get_child_count()
	if box < 0:
		box = 0
	elif box >= boxcount:
		box = boxcount - 1

	selected_box = box
	moving = true
	await $ShopCat.move($Items.get_child(selected_box).position + Vector2(-31, 0))
	moving = false
func _input(event: InputEvent) -> void:
	if moving or closed:
		return
	if Input.is_action_just_pressed('ui_accept'):
		close_shop()
		$Items.get_child(selected_box).buy()
	if Input.is_action_just_pressed('move_left'):
		select_box(selected_box - 1)
	elif Input.is_action_just_pressed('move_right'):
		select_box(selected_box + 1)
	
func close_shop():
	for item in $Items.get_children():
		item.close()
	closed = true
	await $ShopCat.move($CatExit.position)
	Messenger.next_level.emit()

func start(level, boss_battle = false):
	var attacks = State.gm.choose_random_attacks(3)
	for i in range($Items.get_child_count()):
		await get_tree().create_timer(0.1).timeout
		var item = $Items.get_child(i)
		item.open(attacks[i])
	
	await select_box(selected_box)
	closed = false
	Messenger.level_started.emit()
	pass


func _on_shop_button_pressed() -> void:
	close_shop()
	$Items.get_child(0).buy()
	pass # Replace with function body.


func _on_shop_button_2_pressed() -> void:
	close_shop()
	$Items.get_child(1).buy()
	pass # Replace with function body.


func _on_shop_button_3_pressed() -> void:
	close_shop()
	$Items.get_child(2).buy()
	pass # Replace with function body.
