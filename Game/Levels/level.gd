extends Node2D

@export var cell_scene: PackedScene = null


func start(level, boss_battle = false) -> void:
	State.level = self
	State.cell_scene = cell_scene
	State.cells = $Cells
	State.setup(level, boss_battle)
	Messenger.death.connect(on_death)
	Messenger.reset.connect(on_reset)
	Messenger.drop_item.connect(_on_item_drop)

func _on_item_drop(item: Item):
	add_child(item)

func on_death():
	for child in get_children():
		if child is not Player:
			child.modulate = Color(0, 0, 0, 0)

func on_reset():
	for child in get_children():
		if child is not Player:
			child.modulate = Color(1, 1, 1, 1)
