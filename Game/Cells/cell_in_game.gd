extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func stepped_on(on:bool) -> void:
	if on:
		$Light.show()
	else:
		$Light.hide()

func spawn_enemy() -> void:
	$AnimatedSprite2D.show()
	$AnimatedSprite2D.play("default")


func _on_animated_sprite_2d_animation_finished() -> void:
	$AnimatedSprite2D.hide()
	pass # Replace with function body.
