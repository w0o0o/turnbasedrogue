extends Node2D

var moving = false
var closed = true

func play() -> void:
	moving = true
	await $ShopCat.move($CatEnter.global_position)
	moving = false
	closed = false
	Messenger.blacksmith_opened.emit(true, $Anvil)
	Messenger.level_started.emit()

func _input(event: InputEvent) -> void:
	if moving or closed:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		close_shop()
		
func close_shop():
	closed = true
	await $ShopCat.move($CatExit.global_position)
	Messenger.next_level.emit()

func _on_blacksmith_item_selected(attack_data:Attack) -> void:
	if closed:
		return
	closed = true
	await $ShopCat.hammer()
	attack_data.upgrade()
	await get_tree().create_timer(0.5).timeout
	close_shop()

func start(level, boss_battle = false):
	Messenger.blacksmith_item_selected.connect(_on_blacksmith_item_selected)
	Messenger.skip_turn.connect(close_shop)
	pass

var dup = null
