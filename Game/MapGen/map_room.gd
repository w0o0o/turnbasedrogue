@tool
extends Area2D
class_name MapRoom

signal selected(room: Room)

const ICONS := {
	Room.Type.NOT_ASSIGNED: [0, Vector2.ONE],
	Room.Type.BATTLE: [4, Vector2.ONE],
	Room.Type.WEAPON: [2, Vector2.ONE],
	Room.Type.HEALTH: [6, Vector2.ONE],
	Room.Type.SHOP: [5, Vector2.ONE],
	Room.Type.BOSS: [4, Vector2(1.25, 1.25)]
}

@onready var sprite_2d: Sprite2D = $Visuals/Sprite2D
@onready var line_2d: Line2D = $Visuals/Line2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var focused: bool = false: set = set_focused
var available: bool = false: set = set_available
var room: Room: set = set_room


func set_focused(new_value: bool) -> void:
	focused = new_value
	if focused:
		$Visuals/Sprite2D2.modulate = Color.WHITE
		animation_player.play("highlight")
	else:
		animation_player.play("available")

func set_available(new_value: bool) -> void:
	available = new_value
	if available:
		animation_player.play("available")
		$Visuals/Sprite2D2.modulate = Color.WHITE
	elif not room.selected:
		animation_player.play("RESET")
	
func set_room(new_value: Room) -> void:
	if Engine.is_editor_hint():
		return
	room = new_value
	position = room.position
	sprite_2d.frame = ICONS[room.type][0]
	sprite_2d.scale = ICONS[room.type][1]

func show_selected() -> void:
	line_2d.modulate = Color.WHITE

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if available:
				room.selected = true
				animation_player.play("select")

func _on_map_room_selected() -> void:
	selected.emit(room)


func manual_select() -> void:
	room.selected = true
	animation_player.play("select")
