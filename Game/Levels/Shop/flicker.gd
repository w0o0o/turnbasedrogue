@tool
extends PointLight2D

@export var noise: NoiseTexture2D = null
var time_passed:float = 0.0
@export var min_energy:float = 1.0
@export var max_energy:float = 1.0
func _process(delta:float)->void:
    if noise == null:
        return
    time_passed += delta
    if time_passed > 100:
        time_passed = 0
    var sampled_noise = noise.noise.get_noise_2d(time_passed, 0)
    sampled_noise = abs(sampled_noise)
    sampled_noise = lerp(min_energy, max_energy, sampled_noise)
    energy = sampled_noise