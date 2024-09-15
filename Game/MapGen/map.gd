extends Node2D
class_name Map

const MAP_ROOM = preload("res://Game/MapGen/map_room.tscn")
const MAP_LINE = preload("res://Game/MapGen/map_line.tscn")

@onready var map_generator: MapGenerator = $MapGenerator
@onready var lines: Node2D = %Lines
@onready var rooms: Node2D = %Rooms
@onready var visuals: Node2D = $Visuals
@onready var camera_2d: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D

var map_data: Array = []
var floors_climbed: int = 0
var last_room: Room = null
var disabled: bool = false

func _ready() -> void:
	sprite.play("Idle")
	sprite.position.y = map_generator.Y_DIST
	generate_new_map()
	unlock_floor(0)
	center_next_rooms()
	disabled = false
	
func generate_new_map() -> void:
	floors_climbed = 0
	map_data = map_generator.generate_map()
	create_map()

func unlock_floor(which_floor: int = floors_climbed) -> void:
	var focus: MapRoom = null
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == which_floor:
			if focus == null:
				focus = map_room
			map_room.available = true
	if focus != null:
		focus.focused = true
func get_floor_rooms(floor: int) -> Array:
	var floor_rooms: Array = []
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == floor:
			floor_rooms.append(map_room)
	return floor_rooms

func unlock_next_rooms() -> void:
	var focus: MapRoom = null
	for map_room: MapRoom in rooms.get_children():
		if last_room.next_rooms.has(map_room.room):
			if focus == null:
				focus = map_room
			map_room.available = true
	if focus != null:
		focus.focused = true

func _input(event: InputEvent) -> void:
	if disabled:
		return
	if event.is_action_pressed("ui_left"):
		focus_room(-1)
	elif event.is_action_pressed("ui_right"):
		focus_room(1)
	elif event.is_action_pressed("ui_accept"):
		for map_room: MapRoom in rooms.get_children():
			if map_room.focused:
				map_room.focused = false
				map_room.manual_select()

func focus_room(direction: int) -> void:
	var roooooms := get_floor_rooms(floors_climbed)
	var current_floor_rooms: Array = []
	for map_room: MapRoom in roooooms:
		if map_room.available:
			current_floor_rooms.append(map_room)
	var focused_room: MapRoom = null
	for map_room: MapRoom in current_floor_rooms:
		if map_room.focused:
			focused_room = map_room
			break
	if focused_room == null:
		return
	var index := current_floor_rooms.find(focused_room)
	index += direction
	if index < 0 or index >= current_floor_rooms.size():
		# wrap around
		index = index % current_floor_rooms.size()
		if index < 0:
			index = current_floor_rooms.size() + index
	if focused_room == current_floor_rooms[index]:
		return
	focused_room.focused = false
	current_floor_rooms[index].focused = true


func show_map() -> void:
	show()
	camera_2d.enabled = true

func create_map() -> void:
	for current_floor: Array in map_data:
		for room: Room in current_floor:
			if room.next_rooms.size() > 0:
				_spawn_room(room)
	
	var middle := floori(MapGenerator.MAP_WIDTH * 0.5)
	_spawn_room(map_data[MapGenerator.FLOORS - 1][middle] as Room)
	# var map_width_pixels:= MapGenerator.X_DIST * (MapGenerator.MAP_WIDTH - 1)
	# visuals.position.x = (get_viewport_rect().size.x - map_width_pixels) * 0.5
	# visuals.position.y = get_viewport_rect().size.y * 0.5


func _spawn_room(room: Room) -> void:
	var new_map_room := MAP_ROOM.instantiate() as MapRoom
	rooms.add_child(new_map_room)
	new_map_room.room = room
	new_map_room.selected.connect(_on_map_room_selected)
	_connect_lines(room)

	if room.selected and room.row < floors_climbed:
		new_map_room.show_selected()


func _connect_lines(room: Room) -> void:
	if room.next_rooms.is_empty():
		return
	for next: Room in room.next_rooms:
		var new_line := MAP_LINE.instantiate() as Line2D
		new_line.add_point(room.position)
		new_line.add_point(next.position)
		lines.add_child(new_line)


func center_next_rooms() -> void:
	var rms := get_floor_rooms(floors_climbed)
	var lowest := 0
	var highest := 0
	for room: MapRoom in rms:
		if room.room.position.x < lowest:
			lowest = room.room.position.x
		if room.room.position.x > highest:
			highest = room.room.position.x
	var middle_pos := MapGenerator.X_DIST * (MapGenerator.MAP_WIDTH - 1) * -0.5
	var ypos = 0.0
	if last_room != null:
		ypos = last_room.position.y - MapGenerator.Y_DIST
	var tween = get_tree().create_tween()
	tween.tween_property($Visuals, "position", Vector2(middle_pos, -ypos), 0.3)

func _on_map_room_selected(room: Room) -> void:
	disabled = true
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == room.row:
			map_room.available = false
	last_room = room
	floors_climbed += 1
	sprite.play("Run")
	sprite.flip_h = room.position.x < last_room.position.x
	var new_cat_pos = last_room.position + Vector2(-5, -MapGenerator.Y_DIST * 0.5 + 10)
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "position", new_cat_pos, 0.3)
	await get_tree().create_timer(0.3).timeout
	sprite.play("Idle")
	center_next_rooms()
	Messenger.move_to_level.emit(room)
