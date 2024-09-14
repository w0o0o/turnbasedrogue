extends CanvasLayer

signal safe_to_load

func _ready() -> void:
	SceneLoader.loading_finished.connect(fade_out_loading_screen)


func fade_out_loading_screen(status: SceneLoader.ThreadStatus) -> void:
	queue_free()
