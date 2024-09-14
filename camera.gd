extends Camera2D
var noise: NoiseTexture2D
func _ready() -> void:
    Messenger.shake_camera.connect(shake_camera)
    noise = NoiseTexture2D.new()
    noise.noise = FastNoiseLite.new()
    noise.noise.frequency = 0.1

var follow = false
var shake = false
var time = 0.0
var duration = 0.0
var strength = 0.0

var follow_offset_x = 2
var current_offset_x = 0


func shake_camera(s: float, d: float) -> void:
    noise.noise.frequency = 2.5
    time = 0.0
    duration = d
    strength = s
    shake = true

func _process(delta: float) -> void:
    if shake:
        if duration > 0.0:
            var x = noise.noise.get_noise_2d(duration, 0) * 0.5
            var y = noise.noise.get_noise_2d(0, duration)
            print(x, " : ", y)
            duration -= delta
            offset = (Vector2(x, y) * strength) + Vector2(current_offset_x, 0)
        else:
            offset = Vector2(current_offset_x, 0)
            shake = false
    
    if follow and not shake and is_instance_valid(State.player):
        follow_offset_x = 10
        var distance_from_camera = State.player.global_position.x - global_position.x
        current_offset_x = lerpf(current_offset_x, (State.player.global_position.x - follow_offset_x + 10) / 5, delta * 10)
        offset = Vector2(current_offset_x, 0)
