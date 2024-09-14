extends Node
class_name GameManager

var difficulty = 0

var skelly = preload("res://Monsters/Skeleton.tscn")
var ramses = preload("res://Monsters/Ramsey/Ramsey.tscn")
var reaper = preload("res://Monsters/BossReaper/Reaper.tscn")
var enemy_opts = [skelly, ramses]
var bosses = [reaper]
var enemy_options = [skelly, ramses]
var cells: Array[Entity] = []
var numCells = 5
var boss_battle: bool = false
var player: Player = null
var enemies: Array[Entity] = []

var turns = 0:
	set(v):
		turns = v
		handle_moves_updated(turns)

var level: Node2D = null

var cell_size: int = 16
var gap = 4

var dead = false

var cell_insts = []

var running_turns = false: set = emit_running_turns
func emit_running_turns(v: bool):
	running_turns = v
	Messenger.running_turns.emit(v)

var cell_parent: Node2D = null

var cell_parent_origin = null

var entities: Node2D = null

var killed_enemies = 0
var killed_enemies_this_move = 0
var hit_enemies_this_move = 0

var max_enemies = 3
var enemies_target = 2 # number of enemies to kill to win

var test_attack = null
var attack_library = {}
var picked_attacks = []
var discard_pile = []

func on_attack_upgraded(attack: Attack):
	print("Upgrading attack: " + attack.name)
	for a in attack_library.keys():
		if a == attack.name:
			print("Found attack: " + attack.name)
			attack_library[a] = attack
			break
	pass

func load_all_attacks(dir):
	if attack_library.size() > 0:
		return
	for file_name in DirAccess.get_files_at(dir):
		if file_name.ends_with(".tres.remap") or file_name.ends_with(".tres"):
			var file_base_name = file_name.replace(".remap", "")
			file_base_name = file_base_name.replace(".tres", "")
			print("Loading attack: " + file_base_name)
			var attack = ResourceLoader.load(dir + "/" + file_base_name + ".tres")
			if attack is Attack:
				attack_library[attack.name] = attack
	
	print("Loaded attacks: " + str(attack_library.keys()))

func add_to_discard_pile(attack: Attack):
	discard_pile.append(attack)
	pass

func reset_discard_pile():
	var library = attack_library.keys()
	picked_attacks.clear()
	discard_pile.clear()
	return library

func choose_random_attacks(amount: int) -> Array:
	var attacks = []
	var library = attack_library.keys()
	if test_attack != null:
		for i in amount:
			attacks.append(attack_library[test_attack].duplicate())
		return attacks

	# remove already picked attacks
	for attack in picked_attacks:
		library.erase(attack.name)
	#	remove cards in discard pile
	for attack in discard_pile:
		library.erase(attack.name)
	if library.size() < amount:
		library = reset_discard_pile()


	for i in range(amount):
		var attack = library.pick_random()
		library.erase(attack)
		var this_attack = attack_library[attack].duplicate()
		attacks.append(this_attack)
		picked_attacks.append(this_attack)
	return attacks
			

func cell_to_position(cell: int) -> Vector2:
	return Vector2(cell * (cell_size + gap), 0) + cell_parent.position + level.global_position

func timeout(time: float):
	await level.get_tree().create_timer(time).timeout

func place_cells(cell_scene, cp) -> void:
	cell_parent = cp
	for i in cell_insts:
		if is_instance_valid(i):
			i.queue_free()
	cell_insts.clear()
	for i in range(numCells):
		var cell = cell_scene.instantiate()
		cell.position = Vector2(i * (cell_size + gap), 0)
		cell_parent.add_child(cell)
		cell_insts.append(cell)
	cell_parent.position.x = -((float(cell_size + gap) * (numCells - 1)) / 2.0)


func cleanup():
	turns = 0
	cells.clear()
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	killed_enemies = 0

func _init() -> void:
	load_all_attacks("res://Attacks/")
	Messenger.death.connect(on_death)

func randomize_level():
	if boss_battle:
		enemy_options = [bosses.pick_random()]
		enemies_target = 1
		max_enemies = 1
		numCells = 9
	else:
		enemies_target = randi_range(2, 4 + difficulty)
		numCells = randi_range(5, 5 + difficulty)
		print("Num cells: " + str(numCells))
		max_enemies = min(numCells - 2, randi_range(2, 4 + difficulty))


func setup(p, l, cell_scene, cell_parent):
	cleanup()
	print("Setting up game manager")
	randomize_level()
	level = l
	player = p
	player.hide()
	entities = Node2D.new()
	entities.hide()
	level.add_child(entities)
	place_cells(cell_scene, cell_parent)
	for i in range(numCells):
		cells.append(null)
	
	player.cell = -1
	player.gm = self
	player.top_level = true

func play():
	var middle_cell = numCells / 2
	middle_cell = int(middle_cell)
	cells[middle_cell] = player

	level.add_child(player)
	player.cell = middle_cell
	player.facing = 1
	player.start()

	spawn_enemy()
	
	entities.show()
	dead = false
	
	Messenger.disable_inventory.emit(false)
	Messenger.level_started.emit()


func run_next_turn():
	if dead or running_turns:
		return
	running_turns = true

	var turns_prioritised = [] # array where index is the priority of the turn and the value is an enemy
	for enemy in enemies:
		if enemy.health <= 0:
			continue
		var prediction = enemy.predict_turn(self)
		enemy.prediction_priority = prediction
		# prediction is a number representing the priority of the move (lower is first, higher is last)
		for i in range(turns_prioritised.size()):
			if prediction < i:
				turns_prioritised.insert(i, enemy)
				break
		if not turns_prioritised.has(enemy):
			turns_prioritised.append(enemy)

	await player.run_turn(self)
	for enemy in turns_prioritised:
		if enemy.health <= 0:
			continue
		if enemy.prediction_priority == -1:
			await enemy.run_turn(self)
	for enemy in turns_prioritised:
		if enemy.health <= 0:
			continue
		if enemy.prediction_priority == -1:
			continue
		await enemy.run_turn(self)

	for enemy in enemies:
		if enemy.health <= 0:
			continue
		enemy.predict_turn(self)
	
	killed_enemies += killed_enemies_this_move
	killed_enemies_this_move = 0
	Messenger.end_of_turn.emit()
	var win = win_check()
	running_turns = false
	turns += 1
	if not win:
		if enemies.size() == 0:
			spawn_enemy()
		print_cells()
func can_move(entity: Entity, direction: int):
	var new_cell = entity.cell + direction
	if new_cell < 0 or new_cell >= numCells:
		return false
	if cells[new_cell] != null:
		return entity.handle_move_into_enemy(cells, direction, cells[new_cell]) != cells
	return true

func turn_around(entity: Entity):
	if dead:
		return
	entity.play_sound(entity.foot_step_sound)
	entity.facing *= -1

func move(entity: Entity, direction: int):
	if dead:
		return false
	var new_cell = entity.cell + direction
	if new_cell < 0 or new_cell >= numCells:
		return false

	if cells[new_cell] != null:
		var result = entity.handle_move_into_enemy(cells, direction, cells[new_cell])
		if result == cells:
			# no change
			return false
		cells = result
		entity.special_ability_cool_down = 2
		for i in range(numCells):
			if cells[i] == null:
				continue
			cells[i].cell = i # update the cell index of each entity (entities will perform the animation themselves on this value change)
		return true

	# player turns to an empty cell (no enemy)
	cells[entity.cell] = null
	cells[new_cell] = entity
	entity.cell = new_cell
	entity.play_sound(entity.foot_step_sound)
	return true

func damage_entity(entity: Entity, damage: int):
	if entity is not Player:
		hit_enemies_this_move += 1
	var dead = entity.damage(damage)
	if dead:
		if entity is not Player:
			killed_enemies_this_move += 1
			_on_enemy_death(entity)
		cells[entity.cell] = null
		entity.cell = -1
		return true
	return false

func _on_enemy_death(enemy: Entity):
	print("Enemy died")
	enemies.erase(enemy)
	enemies_updated(enemy)

	pass

func print_cells():
	return
	# print("\n\n\n\n\n\n\n\n\n\n\n\n")
	var cell_str = ""
	var stat_str = ""
	var direction_str = ""
	for i in range(numCells):
		if cells[i] == null:
			cell_str += "_"
			stat_str += " "
			direction_str += " "
		else:
			if cells[i] == player:
				cell_str += "P"
			else:
				cell_str += "E"
			stat_str += str(cells[i].health)
			var dir_arrow = ">" if cells[i].facing == 1 else "<"
			direction_str += dir_arrow
	print(cell_str)
	print(stat_str)
	print(direction_str)


func place_enemy(enemy: Entity):
	var empty_cells = []
	for i in range(numCells):
		if cells[i] == null:
			empty_cells.append(i)
	if empty_cells.size() == 0:
		return false
	var cell = empty_cells[randi() % empty_cells.size()]
	var rand_direction = [-1, 1].pick_random()
	cells[cell] = enemy
	enemy.top_level = true
	enemy.hide()
	entities.add_child(enemy)
	enemy.cell = cell
	cell_insts[cell].spawn_enemy()
	enemies.append(enemy)
	enemy.facing = rand_direction
	return true

func on_death():
	dead = true

func enemies_updated(e):
	print("Enemies updated")
	pass


func spawn_enemy():
	var enem = enemy_options.pick_random()
	var enemy = enem.instantiate()
	enemy.gm = self
	if boss_battle:
		enemy.health = 10 + difficulty
	else:
		enemy.health = enemy.health + randi_range(0, 2 + difficulty)
	place_enemy(enemy)
	pass


func handle_moves_updated(moves):
	if moves == 0:
		return
	if enemies.size() >= max_enemies:
		return
	if enemies.size() + killed_enemies >= enemies_target:
		return
	if moves % 5 == 0:
		spawn_enemy()

func win_check():
	if killed_enemies >= enemies_target:
		print("You win!")
		dead = true
		State.health = player.health
		print("Killed enemies: " + str(killed_enemies), " Health: " + str(player.health))
		State.killed_enemies += killed_enemies
		Messenger.next_level.emit()
		Messenger.disable_inventory.emit(true)
		return true
	return false
