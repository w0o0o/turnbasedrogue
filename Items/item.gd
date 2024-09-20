@tool
extends Node2D
class_name Item

@export var item_data: ItemData = null: set = _set_item_data
func _set_item_data(v):
	item_data = v
	item_data.callback = Callable(self, "_update")
	_update()

func _update():
	if is_node_ready() == false:
		return
	$ItemIcon.frame = item_data.icon_frame
	$ItemIcon.modulate = item_data.tint

var timer = 0
func _process(delta: float) -> void:
	# float $ItemIcon up and down using sine
	$ItemIcon.position.y = sin(timer) - 10
	$ItemIcon/PointLight2D.energy = (1 + sin(timer)) + 2
	timer += delta
	if timer > 2 * PI:
		timer = 0

func execute(entity: Entity):
	Messenger.pickup_show.emit(entity.cell, item_data)
