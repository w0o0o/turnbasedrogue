extends Enemy
class_name Skeleton

@onready var skelly_death = preload("res://sfx/skelly_death.mp3")


func _ready() -> void:
	super._ready()
	also_turn.append(%Health)
	$AnimatedSprite2D.play("idle")

func _on_death():
	z_index = -1
	$AnimatedSprite2D.play("death")
	await get_tree().create_timer(0.26).timeout
	play_sound(skelly_death)
	await get_tree().create_timer(1.0).timeout
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0, 1.5)
	tween.parallel()
	tween.tween_property(self, "position:y", position.y + 50, 6.0)


func _on_move(_direction: int):
	if entity_state == EntityState.IDLE:
		$AnimatedSprite2D.play("walk")


func _on_move_finished():
	if entity_state == EntityState.IDLE:
		$AnimatedSprite2D.play("idle")

func _on_damage(_damage_amount: int):
	$AnimatedSprite2D/Blood.show()
	$AnimatedSprite2D/Blood.play("default")
	await wait_for_animation($AnimatedSprite2D, "hit")
	$AnimatedSprite2D.play("idle")


func _on_attack(_attack):
	var duration = get_animation_duration($AnimatedSprite2D, "attack")
	await wait_for_animation($AnimatedSprite2D, "attack", 0.35) # 35% of the animation duration
	return duration * 0.65 # 65% of the animation duration


func _on_blood_animation_finished() -> void:
	$AnimatedSprite2D/Blood.hide()
	pass # Replace with function body.
