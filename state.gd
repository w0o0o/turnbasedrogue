extends Node


var player = null
var level = null: set = _set_level
var cell_scene = null
var cells = null
var gm: GameManager = null
var selected_cat = 1
var default_health = 9
var health = 9
var killed_enemies = 0
var mana = 5: set = _on_mana_change
var main = null

var play_tutorial = false

func _on_mana_change(v: int):
	mana = v
	Messenger.mana_changed.emit(v)

func _set_level(v):
	level = v
	if level != null:
		speech_bubble = speech_bubble_scene.instantiate()
		level.add_child(speech_bubble)

var speech_bubble_scene = preload("res://UI/SpeechBubble/SpeechBubble.tscn")
var cat = preload("res://Kitty/Kitty.tscn")
var tutorial: Tutorial = null

var speech_bubble: SpeechBubble

func _ready() -> void:
	gm = GameManager.new()
	mana = 5
	killed_enemies = 0
	health = default_health
	cells = null

func setup(difficulty = 0, boss_battle = false):
	mana = max(5, mana)
	if player != null:
		if is_instance_valid(player):
			player.queue_free()
		player = null
	player = cat.instantiate()
	player.health = health
	player.selected_cat = selected_cat
	gm.boss_battle = boss_battle
	gm.difficulty = difficulty
	gm.setup(player, level, cell_scene, cells)
	if play_tutorial:
		tutorial = Tutorial.new()

func player_ready():
	if play_tutorial:
		tutorial.start_tutorial()
	pass


func restart():
	_ready()
	SceneLoader.load_scene(main, "res://Main.tscn")
func quit():
	SceneLoader.load_scene(main, "res://MainMenu.tscn")
