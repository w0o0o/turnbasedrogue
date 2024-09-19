@tool
extends Resource
class_name ItemData

var callback: Callable = func() -> void:
    pass

@export var name: String = ""
@export var description: String = ""
@export var icon_frame: int = 0 : set = _set_frame
@export var tint: Color = Color(1, 1, 1, 1) : set = _set_tint
@export var type: String = "ITEM"

func call_callback():
    if callback is Callable:
        callback.call()

func _set_frame(v: int):
    icon_frame = v
    call_callback()

func _set_tint(v: Color):
    tint = v
    call_callback()