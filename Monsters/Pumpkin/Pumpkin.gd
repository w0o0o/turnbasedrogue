extends Enemy
class_name Pumpkin


func _ready() -> void:
	super._ready()
	also_turn.append(%Health)
	$AnimatedSprite2D.play("Idle")

func _on_death():
	z_index = -1
	$AnimatedSprite2D.play("Death")
	await get_tree().create_timer(2.0).timeout
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0, 1.5)
	tween.parallel()
	tween.tween_property(self, "position:y", position.y + 50, 6.0)


func _on_move(_direction: int):
	if entity_state == EntityState.IDLE:
		$AnimatedSprite2D.play("Walk")


func _on_move_finished():
	if entity_state == EntityState.IDLE:
		$AnimatedSprite2D.play("Idle")

func _on_damage(_damage_amount: int):
	await wait_for_animation($AnimatedSprite2D, "Hurt")
	$AnimatedSprite2D.play("Idle")

func _on_attack(attack: Attack):
	var attacks = ["Spell 1", "Spell 2"]
	var attack_name = attacks.pick_random()
	var duration = get_animation_duration($AnimatedSprite2D, attack_name)
	await wait_for_animation($AnimatedSprite2D, attack_name, 0.35) # 35% of the animation duration
	return duration * 0.65 # 65% of the animation duration


func _on_animated_sprite_2d_animation_finished() -> void:
	pass # Replace with function body.


func _on_animated_sprite_2d_animation_changed() -> void:
	pass # Replace with function body.
