@tool
extends Entity
class_name Player

func set_cat_frames(frames: SpriteFrames):
	if has_node("AnimatedSprite2D"):
		get_node("AnimatedSprite2D").sprite_frames = frames
		get_node("AnimatedSprite2D").play("Idle")

@export var cat_frames: SpriteFrames:
	set(v):
		set_cat_frames(v)
		cat_frames = v

@export var selected_cat: int = 0:
	set(v):
		selected_cat = v
		if cat_options.size() == 0:
			return
		v = v % cat_options.size()
		if v < 0:
			v = cat_options.size() - 1
		cat_frames = cat_options[v]

@export var cat_options: Array[SpriteFrames]


func handle_move_into_enemy(cells: Array[Entity], direction: int, enemy: Entity) -> Array[Entity]:
	# default implementation is to trade places with the enemy if the player is looking at the enemy

	if special_ability_cool_down > 0:
		return cells

	if direction != facing:
		return cells; # return the cells array unchanged
	
	var new_cells = cells.duplicate()
	var enemy_cell = enemy.cell
	var player_cell = cell
	new_cells[enemy_cell] = self
	new_cells[player_cell] = enemy
	return new_cells


func run_turn(game: GameManager):
	if turn["type"] == "MOVE":
		var direction = turn["args"][0]
		var can = game.can_move(self, direction)
		if can:
			game.move(self, direction)
	elif turn["type"] == "TURNAROUND":
		game.turn_around(self)
	elif turn["type"] == "ATTACK":
		for attack in attack_queue:
			Messenger.attack_executed.emit(attack)
			await execute_attack(attack)
		Messenger.attacks_executed.emit(attack_queue)
		attack_queue.clear()
	turn = default_turn
	return

func _on_damage(_damage_amount: int):
	Messenger.health_updated.emit(health)
	$AnimatedSprite2D.play("Take_Damage")

func _ready() -> void:
	super._ready()
	set_cat_frames(cat_frames)
	Messenger.health_updated.emit(health)
	Messenger.attack_selected.connect(_on_attack_selected)
	Messenger.reorder_queue.connect(_on_queue_reordered)
	await get_tree().create_timer(0.1).timeout
	Messenger.health_updated.emit(health)
	Messenger.skip_turn.connect(_on_skip_turn)
	Messenger.force_tutorial_input.connect(_on_force_tutorial_input)
	State.player_ready()

var allowed_input
func _on_force_tutorial_input(input_name):
	print("Forcing input ", input_name)
	if input_name == "":
		allowed_input = null
	else:
		allowed_input = input_name

var attack_library: Array[Attack] = []

func _on_death():
	$AnimatedSprite2D.play("Take_Damage")
	await get_tree().create_timer(0.2).timeout
	$AnimatedSprite2D.play("Death")
	Messenger.death.emit()
	
func _on_move(_direction: int):
	$AnimatedSprite2D.play("Run")


func _on_move_finished():
	$AnimatedSprite2D.play("Idle")


func _input(_event: InputEvent) -> void:
	if gm == null:
		return
	if gm.running_turns:
		return
	if Input.is_action_just_pressed('move_left'):
		print("Move left pressed _____________ %s" % allowed_input)
		if allowed_input != null and allowed_input != "move_left":
			return
		print("Move left")
		var can = gm.can_move(self, -1)
		if can:
			turn = {
				"type": "MOVE",
				"args": [-1]
			}
			gm.run_next_turn()
	elif Input.is_action_just_pressed('move_right'):
		if allowed_input != null and allowed_input != "move_right":
			return
		var can = gm.can_move(self, 1)
		if can:
			turn = {
				"type": "MOVE",
				"args": [1]
			}
			gm.run_next_turn()
	elif Input.is_action_just_pressed('turn_around'):
		if allowed_input != null and allowed_input != "turn_around":
			return
		turn = {
			"type": "TURNAROUND",
		}
		gm.run_next_turn()
	elif Input.is_action_just_pressed('attack'):
		if attack_queue.size() == 0:
			return
		turn = {
			"type": "ATTACK"
		}
		gm.run_next_turn()
	pass

func _on_animation_finished():
	if health <= 0:
		return
	$AnimatedSprite2D.play("Idle")
	

func _on_attack(attack):
	print("Attack received ", attack)
	gm.add_to_discard_pile(attack)
	var anim_name = attack["animation"]
	await wait_for_animation($AnimatedSprite2D, anim_name)
	return 1.0

func _on_attack_selected(attack):
	if gm.running_turns:
		return
	attack_queue.append(attack)
	entity_state = EntityState.QUEUED_ATTACK

func _on_queue_reordered(queue):
	attack_queue = queue


func _on_skip_turn():
	if allowed_input != null and allowed_input != "skip":
		return
	turn = {
		"type": "SKIP"
	}
	gm.run_next_turn()
	pass
