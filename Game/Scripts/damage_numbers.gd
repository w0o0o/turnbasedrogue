extends Node

@onready var font = preload("res://Fonts/TinyPixie2.ttf")
# Called when the node enters the scene tree for the first time.
func display_number(value: int, position: Vector2, critical: bool = false) -> void:
	Messenger.shake_camera.emit(value * 3, 0.3)
	var number = Label.new()
	number.global_position = position
	number.z_index = 5
	number.label_settings = LabelSettings.new()
	var color = "#FFF";
	var size = 10
	var display_string = str(value)
	if critical:
		size = 10
		color = "#B22"
	if value == 0:
		color = "#FFF"
		display_string = "DODGE"
	number.text = display_string
	number.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	number.label_settings.font_color = color
	number.label_settings.outline_color = "#000"
	number.label_settings.outline_size = 2
	number.label_settings.font_size = size
	number.label_settings.font = font
	call_deferred("add_child", number)
	await number.resized
	number.pivot_offset = Vector2(number.size / 2)
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	var anim_time = 0.5
	var rand_offest = randf_range(-25, 25)
	tween.tween_property(number, "position:y", number.position.y - 50, anim_time).set_ease(Tween.EASE_OUT)
	tween.tween_property(number, "position:x", number.position.x + rand_offest, anim_time).set_ease(Tween.EASE_OUT)
	tween.tween_property(number, "position:y", number.position.y, anim_time).set_ease(Tween.EASE_IN).set_delay(anim_time + 0.1)
	tween.tween_property(number, "scale", Vector2.ZERO, anim_time).set_ease(Tween.EASE_IN).set_delay(anim_time * 2 + 0.2)

	await tween.finished
	number.queue_free()

	pass
