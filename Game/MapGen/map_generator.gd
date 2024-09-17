extends Node
class_name MapGenerator

const X_DIST: int = 50
const Y_DIST: int = 50
const PLACEMENT_RANDOMNESS: int = 5
const PLACEMENT_RANDOMNESS_X: int = 15
const FLOORS: int = 9
const MAP_WIDTH: int = 6
const PATHS: int = 6
const BATTLE_ROOM_WEIGHT: float = 10.0
const SHOP_ROOM_WEIGHT: float = 2.5
const HEALTH_ROOM_WEIGHT: float = 4.0
const MIN_STARTING_POINTS: int = 2

var rules = [
	{
		"floor": 0,
		"type": Room.Type.BATTLE # first floor is always battle
	},
	{
		"floor": 1,
		"type": Room.Type.WEAPON # second floor is always weapon
	},
	{
		"floor": floor(FLOORS * 0.5),
		"type": Room.Type.SHOP # middle floor is always shop
	},
	{
		"floor": FLOORS - 2,
		"type": Room.Type.HEALTH # second to last floor is always health
	},
	{
		"floor": FLOORS - 1,
		"type": Room.Type.BOSS # last floor is always boss
	}
]

var random_room_type_weights = {
	Room.Type.BATTLE: 0.0,
	Room.Type.SHOP: 0.0,
	Room.Type.HEALTH: 0.0
}
var random_room_type_total_weight: float = 0.0
var map_data: Array

func generate_map() -> Array:
	map_data = _generate_initial_grid()
	var starting_points := _get_random_starting_points()
	# var starting_points := [0,3]
	for j in starting_points:
		var current_j: int = j
		for i in FLOORS - 1:
			current_j = _setup_connection(i, current_j)

	_setup_boss_room()
	_setup_random_room_weights()
	_setup_room_types()
	return map_data

func _generate_initial_grid() -> Array:
	var result = []
	for i in FLOORS:
		var adjacent_rooms: Array[Room] = []
		for j in MAP_WIDTH:
			var current_room: Room = Room.new()
			var offset: Vector2 = Vector2(randf() * PLACEMENT_RANDOMNESS_X, randf() * PLACEMENT_RANDOMNESS)
			current_room.position = Vector2(j * X_DIST, i * -Y_DIST) + offset
			current_room.row = i
			current_room.column = j
			current_room.next_rooms = []
			# if last floor (boss room) give extra space
			# if i == FLOORS - 1:
			# 	current_room.position.y = (i + 1) * -Y_DIST
			adjacent_rooms.append(current_room)
		result.append(adjacent_rooms)
	return result

func _get_random_starting_points() -> Array[int]:
	var y_coordinates: Array[int] = []
	var unique_points: int = 0
	
	while unique_points < MIN_STARTING_POINTS:
		unique_points = 0
		y_coordinates.clear()
		for i in PATHS:
			var starting_point := randi_range(0, MAP_WIDTH - 1)
			if not y_coordinates.has(starting_point):
				unique_points += 1
			y_coordinates.append(starting_point)
	return y_coordinates

func _setup_connection(i: int, j: int) -> int:
	var next_room: Room
	var current_room := map_data[i][j] as Room
	while not next_room or _would_cross_existing_path(i, j, next_room):
		var random_j := clampi(randi_range(j - 1, j + 1), 0, MAP_WIDTH - 1)
		next_room = map_data[i + 1][random_j]
	current_room.next_rooms.append(next_room)
	return next_room.column

func _would_cross_existing_path(i: int, j: int, room: Room) -> bool:
	var left_neighbour: Room
	var right_neighbour: Room

	# if j is 0 there is no left neighbour
	if j > 0:
		left_neighbour = map_data[i][j - 1]

	# if j is MAP_WIDTH-1 there is no right neighbour
	if j < MAP_WIDTH - 1:
		right_neighbour = map_data[i][j + 1]

	if right_neighbour and room.column > j:
		for next_room: Room in right_neighbour.next_rooms:
			if next_room.column < room.column:
				return true
	
	if left_neighbour and room.column < j:
		for next_room: Room in left_neighbour.next_rooms:
			if next_room.column > room.column:
				return true

	return false

func _setup_boss_room() -> void:
	var middle := floori(MAP_WIDTH * 0.5)
	var boss_room := map_data[FLOORS - 1][middle] as Room
	
	for j in MAP_WIDTH:
		var current_room = map_data[FLOORS - 2][j] as Room # rooms below boss room
		if current_room.next_rooms:
			current_room.next_rooms = [] as Array[Room]
			current_room.next_rooms.append(boss_room)

	boss_room.type = Room.Type.BOSS

func _setup_random_room_weights() -> void:
	random_room_type_weights[Room.Type.BATTLE] = BATTLE_ROOM_WEIGHT
	random_room_type_weights[Room.Type.HEALTH] = BATTLE_ROOM_WEIGHT + HEALTH_ROOM_WEIGHT
	random_room_type_weights[Room.Type.SHOP] = BATTLE_ROOM_WEIGHT + HEALTH_ROOM_WEIGHT + SHOP_ROOM_WEIGHT
	random_room_type_total_weight = random_room_type_weights[Room.Type.SHOP]

func _setup_room_types() -> void:
	for rule in rules:
		for room: Room in map_data[rule["floor"]]:
			if room.next_rooms.size() > 0:
				room.type = rule["type"]

	#  random room types for the rest
	for current_floor in map_data:
		for room: Room in current_floor:
			for next_room: Room in room.next_rooms:
				if next_room.type == Room.Type.NOT_ASSIGNED:
					_set_room_randomly(next_room)

func _set_room_randomly(room: Room) -> void:
	var health_below_4 := true
	var consecutive_health := true
	var consecutive_shop := true
	var health_on_last_floor := true

	var type_candidate: Room.Type
	while health_below_4 or consecutive_health or consecutive_shop or health_on_last_floor:
		type_candidate = _get_random_room_type_by_weight()
		
		var is_health := type_candidate == Room.Type.HEALTH
		var has_health_parent := _room_has_parent_of_type(room, Room.Type.HEALTH)
		var is_shop := type_candidate == Room.Type.SHOP
		var has_shop_parent := _room_has_parent_of_type(room, Room.Type.SHOP)

		health_below_4 = is_health and room.row < 3
		consecutive_health = is_health and has_health_parent
		consecutive_shop = is_shop and has_shop_parent
		health_on_last_floor = is_health and room.row == FLOORS - 3

	room.type = type_candidate
		
func _room_has_parent_of_type(room: Room, type: Room.Type) -> bool:
	var parents: Array[Room] = []
	# left parent
	if room.column > 0 and room.row > 0:
		var parent_candidate := map_data[room.row - 1][room.column - 1] as Room
		if parent_candidate.next_rooms.has(room):
			parents.append(parent_candidate)
			
	# middle parent
	if room.row > 0:
		var parent_candidate := map_data[room.row - 1][room.column] as Room
		if parent_candidate.next_rooms.has(room):
			parents.append(parent_candidate)

	# right parent
	if room.column < MAP_WIDTH - 1 and room.row > 0:
		var parent_candidate := map_data[room.row - 1][room.column + 1] as Room
		if parent_candidate.next_rooms.has(room):
			parents.append(parent_candidate)

	for parent in parents:
		if parent.type == type:
			return true

	return false
	
func _get_random_room_type_by_weight() -> Room.Type:
	var roll: float = randf_range(0.0, random_room_type_total_weight)
	for type: Room.Type in random_room_type_weights:
		if random_room_type_weights[type] > roll:
			return type
	return Room.Type.BATTLE