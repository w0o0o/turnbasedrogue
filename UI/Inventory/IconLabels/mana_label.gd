@tool
extends Node2D
@export var show: bool = false: set = _set_show
@export var mana_count: int = 0: set = _set_mana_count
@export var use_current_mana = false
var sprite_width = 2.0
var sprite_height = 4.0
@export var delay = 0.01
@export var gap = 1.0
@export var cols = 6
@export var reversed = false


func _ready():
	if show:
		show_mana()
	else:
		hide_mana()

func _set_mana_count(v):
	mana_count = v
	var current_mana = State.mana
	if has_node("Sprite2D"):
		for child in get_children():
			if child != get_node("Sprite2D") and child is Sprite2D:
				child.queue_free()
		var sprite = get_node("Sprite2D")

		var tex = sprite.texture
		sprite_width = tex.get_width()
		sprite_height = tex.get_height()
		print("Width %s, Height %s" % [sprite_width, sprite_height])

		var mana_sprites = [sprite]
		for i in mana_count - 1:
			var new_sprite = sprite.duplicate()
			mana_sprites.append(new_sprite)
			add_child(new_sprite)
			if use_current_mana and i + 1 > current_mana:
				new_sprite.modulate = Color(1, 1, 1, 0.5)
			new_sprite.hide()
		# center the sprites
		var num_rows = ceil(float(mana_count) / float(cols))
		print("count: %s - %s Num rows: %s" % [mana_count, cols, num_rows])
		var y_mult = -1 if reversed else 1
		if num_rows > 1:
			var left = -((sprite_width + gap) * (cols - 1)) / 2
			var y = 0
			for i in range(mana_sprites.size()):
				# every cols sprites move down
				y = floor(i / cols)
				mana_sprites[i].position.x = left + (i % cols) * (sprite_width + gap)
				mana_sprites[i].position.y = y * (sprite_height + gap) * y_mult
		else:
			var left = -((sprite_width + gap) * (mana_count - 1)) / 2
			for i in range(mana_sprites.size()):
				mana_sprites[i].position.x = left + i * (sprite_width + gap)
				mana_sprites[i].position.y = 0

func _set_show(v):
	show = v
	if show:
		show_mana()
	else:
		hide_mana()

func show_mana():
	if is_node_ready() and get_tree() != null:
		var i = 0
		for child in get_children():
			i += 1
			if child is Sprite2D:
				var tween = get_tree().create_tween()
				child.show()
				tween.tween_property(child, "scale", Vector2(1, 1), 0.2).set_delay(i * delay)

func hide_mana():
	var i = 0
	for child in get_children():
		i += 1
		if child is Sprite2D:
			var tween = get_tree().create_tween()
			tween.tween_property(child, "scale", Vector2(0, 0), 0.2).set_delay(i * delay)
	
	await get_tree().create_timer(delay * i).timeout
	for child in get_children():
		if child is Sprite2D:
			child.hide()

func update_count():
	show_mana()
