extends Node2D

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
var speed = 50.0

func _ready() -> void:
	selected_cat = State.selected_cat

func move(position: Vector2):
	$AnimatedSprite2D.play("Idle")
	var tween = get_tree().create_tween()
	var new_pos = position
	new_pos.y = global_position.y
	print("Moving asdfto ", new_pos)
	
	if new_pos.x < global_position.x:
		handle_change_direction(-1)
	else:
		handle_change_direction(1)
	var distance = new_pos.distance_to(global_position)
	print("Distance: ", distance)

	tween.tween_property(self, "global_position", new_pos, distance / speed)
	$AnimatedSprite2D.play("Run")
	await get_tree().create_timer(distance / speed).timeout
	print("Done moving")
	$AnimatedSprite2D.play("Idle")
	return true


func handle_change_direction(direction: int):
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale:x", direction, 0.2)
	await get_tree().create_timer(0.2).timeout
	return true

func hammer():
	var anim_name = "Hammer"
	var frame_count = $AnimatedSprite2D.sprite_frames.get_frame_count(anim_name)
	var fps = $AnimatedSprite2D.sprite_frames.get_animation_speed(anim_name)
	var duration = float(frame_count) / float(fps)
	$AnimatedSprite2D.play(anim_name)
	await get_tree().create_timer(duration).timeout
	$AnimatedSprite2D.play("Idle")
