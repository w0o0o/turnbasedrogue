extends CanvasLayer

var follow_offset_x = 10
var global_position = Vector2.ZERO
var current_offset_x = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    if is_instance_valid(State.player):
        var distance_from_camera = State.player.global_position.x - global_position.x
        current_offset_x = lerpf(current_offset_x, (State.player.global_position.x - follow_offset_x + 10) / 5, delta * 10)
        offset = Vector2(current_offset_x, 0)
