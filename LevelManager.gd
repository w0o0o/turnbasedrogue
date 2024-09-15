extends Node2D

const level_scene: PackedScene = preload("res://Game/Levels/level.tscn")
const level2_scene: PackedScene = preload("res://Game/Levels/level2.tscn")
const upgrade_scene: PackedScene = preload("res://Game/Levels/Blacksmith/blacksmith.tscn")
const shop_scene: PackedScene = preload("res://Game/Levels/Shop/shop.tscn")

var current_level = null
var next_level = null

var special_levels = []
var level_width = 256
var gap = 48
var levels_moved = 0
var camera_speed = 3.0
@onready var camera = $Camera2D

var rooms = {
	Room.Type.BATTLE: [level_scene],
	Room.Type.HEALTH: [upgrade_scene],
	Room.Type.SHOP: [shop_scene],
	Room.Type.WEAPON: [upgrade_scene],
	Room.Type.BOSS: [level2_scene]
}

func start_game():
	Messenger.disable_inventory.emit(true)
	camera.position_smoothing_enabled = false
	camera.global_position = -Vector2(level_width + gap, 0)
	$Map.global_position = -Vector2(level_width + gap, 0)
	$Map.show()
	$CanvasLayer.hide()

func move_camera_away():
	Messenger.disable_inventory.emit(true)
	$Map.global_position = Vector2(level_width + gap, 0) 
	$Map.show()
	camera.follow = false
	camera.position_smoothing_enabled = true
	camera.global_position = Vector2(level_width + gap, 0)
	await get_tree().create_timer(2.0).timeout

	camera.position_smoothing_enabled = false
	camera.global_position = -Vector2(level_width + gap, 0)
	$Map.global_position = -Vector2(level_width + gap, 0) 
	$CanvasLayer.hide()
	$Map.unlock_next_rooms()
	$Map.disabled = false
	current_level.hide()

func load_level(room: Room):
	var options = rooms[room.type]
	var scene = options[randi() % options.size()]
	if scene == null:
		print("No scene found for room type: %s" % room.type)
		scene = options[0]
	if scene == null:
		print("SOMETHING WENT HORRIBLY WRONG")
		scene = level_scene
	print("Loading level: %s" % room)
	next_level = scene.instantiate()
	next_level.global_position = Vector2.ZERO
	$Below.add_child(next_level)
	var boss_battle = room.type == Room.Type.BOSS
	print("Loading level: %s Boss battle: %s" % [room, boss_battle])
	next_level.start(levels_moved, boss_battle)
	await get_tree().create_timer(0.5).timeout
	
	camera.position_smoothing_enabled = true
	camera.global_position = Vector2.ZERO
	await get_tree().create_timer(1.0).timeout

	if is_instance_valid(current_level):
		current_level.queue_free()
	current_level = next_level
	next_level = null
	camera.follow = true
	
	levels_moved += 1
	$Map.hide()
	$CanvasLayer.show()

func _ready():
	State.main = self
	special_levels = [upgrade_scene, shop_scene]
	start_game()
	Messenger.next_level.connect(move_camera_away)
	Messenger.move_to_level.connect(load_level)


func generate_map():
	pass
