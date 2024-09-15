extends Enemy
class_name Bat


func _ready() -> void:
	super._ready()
	also_turn.append(%Health)
	$AnimatedSprite2D.play("idle")

func _on_death():
	z_index = -1
	$AnimatedSprite2D.play("death")
	await get_tree().create_timer(2.0).timeout
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0, 1.5)
	tween.parallel()
	tween.tween_property(self, "position:y", position.y + 50, 6.0)


# func _on_move(direction: int):
# 	if entity_state == EntityState.IDLE:
# 		$AnimatedSprite2D.play("walk")


func _on_move_finished():
	if entity_state == EntityState.IDLE:
		$AnimatedSprite2D.play("idle")

func _on_damage(_damage_amount: int):
	await wait_for_animation($AnimatedSprite2D, "hit")
	$AnimatedSprite2D.play("idle")


func _on_attack(_attack):
	var rand = (randi() % 2) + 1
	var duration = get_animation_duration($AnimatedSprite2D, "attack_1")
	await wait_for_animation($AnimatedSprite2D, "attack_%s" % rand, 0.35) # 35% of the animation duration
	return duration * 0.65 # 65% of the animation duration
