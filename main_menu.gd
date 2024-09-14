extends Control


func _on_play_pressed() -> void:
	SceneLoader.load_scene(self, "res://Main.tscn")
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
