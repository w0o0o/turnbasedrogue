extends Resource
class_name Room
enum Type { 
    NOT_ASSIGNED, BATTLE, WEAPON, HEALTH, SHOP, BOSS
}
@export var type: Type = Type.NOT_ASSIGNED
@export var row: int = 0
@export var column: int = 0
@export var position: Vector2 = Vector2.ZERO
@export var next_rooms: Array[Room] = []
@export var selected: bool = false

func _to_string() -> String:
    return "%s (%s)" % [column, Type.keys()[type][0]]