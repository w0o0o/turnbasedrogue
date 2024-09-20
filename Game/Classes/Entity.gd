extends Node2D
class_name Entity

@onready var foot_step_sound: AudioStream = preload("res://sfx/8bit/scratch_sound.wav")
@onready var punch_1: AudioStream = preload("res://sfx/8bit/punch.wav")
@onready var punch_2: AudioStream = preload("res://sfx/punch2.mp3")
@onready var scratch: AudioStream = preload("res://sfx/8bit/scratch_sound.wav")
var punch_sound: AudioStreamRandomizer = null
var sound_player: AudioStreamPlayer2D = null
var also_turn: Array = []

var gm: GameManager = null:
	set(g):
		gm = g
		Messenger.end_of_turn.connect(_on_end_of_turn)
var cell: int = -1:
	set(v):
		handle_change_cell(cell, v)
		cell = v
var facing: int = 1:
	set(v):
		handle_change_direction(facing, v)
		facing = v
var health: int = 4: set = health_change
func health_change(v: int):
	health = v
	_on_health_change(v)

func _on_health_change(_v: int):
	pass

var default_turn = {
	"type": "SKIP",
	"args": []
}
var turn = default_turn
var special_ability_cool_down_max: int = 0
var special_ability_cool_down: int = 0

enum EntityState {
	IDLE,
	MOVING,
	QUEUED_ATTACK,
	AGGRO,
	ATTACKING,
	RETREATING
}
var entity_state: EntityState = EntityState.IDLE: set = state_change
func state_change(v: EntityState):
	entity_state = v
	_on_state_change(v)

func _on_state_change(_v):
	pass


func _ready() -> void:
	sound_player = AudioStreamPlayer2D.new()
	add_child(sound_player)
	punch_sound = AudioStreamRandomizer.new()
	punch_sound.add_stream(0, punch_1)
	hide()

func play_sound(sound: AudioStream):
	sound_player.stream = sound
	sound_player.play()
	

var attack_queue: Array[Attack] = []

func handle_move_into_enemy(cells: Array[Entity], _direction: int, _enemy: Entity) -> Array[Entity]:
	# default implementation for entities is to return the cells array unchanged
	return cells

func predict_turn(_game: GameManager) -> int:
	return 10

func run_turn(_game: GameManager):
	pass

func _on_death():
	pass

func damage(damage_amount: int) -> bool:
	sound_player.stream = punch_sound
	sound_player.play()
	health -= damage_amount
	DamageNumbers.display_number(damage_amount, position, false)
	if health <= 0:
		_on_death()
		return true
	else:
		_on_damage(damage_amount)
	return false

func handle_change_cell(before: int, after: int):
	if after == -1:
		# entity is removed from the game
		return

	var cell_scene = gm.cell_insts[after]
	var cell_scene_b4 = gm.cell_insts[before]
	if cell_scene_b4 != null:
		cell_scene_b4.stepped_on(false)
	if cell_scene != null:
		cell_scene.stepped_on(true)
	if before == -1:
		play_sound(scratch)
		scale = Vector2(0, 0)
		var pos = gm.cell_to_position(after)
		position = pos
		show()
		var tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "scale", Vector2(1, 1), 0.2)
	elif before != after:
		var new_pos = gm.cell_to_position(after)
		var tween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "position", new_pos, 0.2)
		var direction = after - before
		direction = direction / abs(direction)
		_on_move(direction)
		await get_tree().create_timer(0.2).timeout
		_on_move_finished()

func _on_move(_direction: int):
	pass

func _on_move_finished():
	pass

func _on_damage(_damage: int):
	pass
		

func handle_change_direction(_before: int, after: int):
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale:x", after, 0.2)
	for item in also_turn:
		tween.parallel()
		tween.tween_property(item, "scale:x", after, 0.2)
	await get_tree().create_timer(0.2).timeout


func add_to_attack_queue(attack):
	attack_queue.append(attack)
	entity_state = EntityState.QUEUED_ATTACK

func can_hit_entity(entity: Entity, attack: Attack) -> bool:
	if attack == null or entity == null:
		return false
	var will_hit = false
	if attack.damage_cells.size() > 0:
		var damage_cells = attack.damage_cells
		for dc in damage_cells:
			var target_cell = cell + (dc * facing)
			if target_cell < 0 or target_cell >= gm.numCells:
				continue
			if target_cell == entity.cell:
				will_hit = true
				break
	var direction = attack.direction * facing
	if direction == 0:
		direction = facing # if the attack has no direction, it is the same as the facing direction (prevent infinite loop)
	if attack.projectile:
		var test_cell = cell + direction
		while test_cell < gm.numCells and test_cell >= 0:
			if test_cell == entity.cell:
				will_hit = true
				break
			test_cell += direction
	if attack.reverse:
		var test_cell = gm.numCells - 1 if direction > 0 else 0
		while test_cell != cell:
			if test_cell == entity.cell:
				will_hit = true
				break
			test_cell -= direction

	if attack.ramming:
		var test_cell = cell + direction
		while test_cell < gm.numCells and test_cell >= 0:
			if test_cell == entity.cell:
				will_hit = true
				break
			test_cell += direction
		var cell_for_self = (direction * (abs(cell - test_cell) - 1))
		var resulting_cell = cell + cell_for_self
		test_cell = resulting_cell + direction
		while test_cell < gm.numCells and test_cell >= 0:
			if test_cell == entity.cell:
				will_hit = true
				break
			test_cell += direction
	return will_hit

func execute_attack(attack: Attack):
	if attack == null:
		return
	var after_attack_delay = await _on_attack(attack)
	var damage_amount = attack.damage
	if attack.damage_cells.size() > 0:
		var damage_cells = attack.damage_cells # will be -1 -2, 1, 2 (relative to the attacker) but it is an array
		for dc in damage_cells:
			var target_cell = cell + (dc * facing) # facing is 1 or -1 and matters for the direction of the attack
			if target_cell < 0 or target_cell >= gm.numCells:
				continue
			var target = gm.cells[target_cell]
			if target != null:
				gm.damage_entity(target, damage_amount)
	var direction = attack.direction * facing
	if direction == 0:
		direction = facing # if the attack has no direction, it is the same as the facing direction (prevent infinite loop)
	if attack.projectile:
		# get all cells in the direction of the attack
		var test_cell = cell + direction
		var piercing = attack.piercing
		while test_cell < gm.numCells and test_cell >= 0:
			var target = gm.cells[test_cell]
			if target != null:
				gm.damage_entity(target, damage_amount)
				piercing -= 1
				if piercing <= 0:
					break # no piercing left
			test_cell += direction
			await get_tree().create_timer(0.05).timeout
	if attack.reverse:
		# start from 0 if the direction is negative and numCells - 1 if the direction is positive
		var test_cell = gm.numCells - 1 if direction > 0 else 0
		var piercing = attack.piercing
		while test_cell != cell:
			var target = gm.cells[test_cell]
			if target != null:
				gm.damage_entity(target, damage_amount)
				piercing -= 1
				if piercing <= 0:
					break # no piercing left
			test_cell -= direction
			await get_tree().create_timer(0.05).timeout
	if attack.ramming:
		var test_cell = cell + direction
		while test_cell < gm.numCells and test_cell >= 0:
			var target = gm.cells[test_cell]
			if target != null:
				break
			test_cell += direction
		var cell_for_self = (direction * (abs(cell - test_cell) - 1))

		var resulting_cell = cell + cell_for_self
		test_cell = resulting_cell + direction
		var piercing = attack.piercing
		var enemies_hit = []
		while test_cell < gm.numCells and test_cell >= 0:
			var target = gm.cells[test_cell]
			if target != null:
				enemies_hit.append(target)
				piercing -= 1
				if piercing <= 0:
					break # no piercing left
			test_cell += direction
		gm.move(self, cell_for_self)
		await get_tree().create_timer(0.2).timeout
		for enemy in enemies_hit:
			gm.damage_entity(enemy, damage_amount)
	await get_tree().create_timer(after_attack_delay).timeout

func _on_attack(_attack) -> float:
	await get_tree().create_timer(0.0).timeout
	return 0.0

func _on_end_of_turn():
	if special_ability_cool_down > 0:
		special_ability_cool_down -= 1


func wait_for_animation(sprite: AnimatedSprite2D, animation: String, factor: float = 0.5):
	var duration = get_animation_duration(sprite, animation)
	sprite.play(animation)
	await get_tree().create_timer(float(duration) * factor).timeout
	return

func get_animation_duration(sprite: AnimatedSprite2D, animation: String):
	var frame_count = sprite.sprite_frames.get_frame_count(animation) + 1
	var fps = sprite.sprite_frames.get_animation_speed(animation)
	var duration = float(frame_count) / float(fps)
	return duration

func pick_up_item(item: Item):
	item.queue_free()
	await item.execute(self)
	