extends Node


var player = null
var level = null
var cell_scene = null
var cells = null
var gm: GameManager = null
var selected_cat = 0
var health = 9
var killed_enemies = 0
var mana = 5: set = _on_mana_change
var main = null

func _on_mana_change(v: int):
	mana = v
	Messenger.mana_changed.emit(v)

var cat = preload("res://Kitty/Kitty.tscn")

func _ready() -> void:
	mana = 5
	killed_enemies = 0
	health = 9
	cells = null
	if gm == null:
		gm = GameManager.new()
	if player == null:
		player = cat.instantiate()
	Messenger.end_of_turn.connect(_on_end_of_turn)

func _on_end_of_turn():
	mana += 1

func setup(difficulty = 0, boss_battle = false):
	mana = max(5, mana)
	player.health = health
	player.selected_cat = selected_cat
	gm.boss_battle = boss_battle
	gm.difficulty = difficulty
	gm.setup(player, level, cell_scene, cells)


func restart():
	_ready()
	SceneLoader.load_scene(main, "res://Main.tscn")
func quit():
	SceneLoader.load_scene(main, "res://MainMenu.tscn")

func free_previous_level(level):
	var found_player = null;
	for child in level.get_children():
		if child is Player:
			found_player = child
			break
	if found_player != null:
		# remove player from level tree but keep it alive
		level.remove_child(found_player)
	level.queue_free()
