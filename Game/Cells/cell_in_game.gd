extends Node2D

var num_frames:int = 0;
var offset_per_frame:float = 0.0;
var cell_num = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	num_frames = $Pickup.material.particles_anim_v_frames * $Pickup.material.particles_anim_h_frames
	offset_per_frame = 1.0 / num_frames
	Messenger.pickup_show.connect(_on_pickup_show)
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

func _on_pickup_show(cell_num:int, item:ItemData) -> void:
	if cell_num != self.cell_num:
		return
	var process: ParticleProcessMaterial = $Pickup.process_material
	process.anim_offset_max = offset_per_frame * item.icon_frame
	process.anim_offset_min = process.anim_offset_max
	$Pickup.modulate = item.tint
	$Pickup.emitting = true