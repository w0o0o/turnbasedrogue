extends Control

@export var animated_text: String = "YOU ARE DEAD"

func _ready() -> void:
	$Buttons.hide()
	Messenger.death.connect(_on_death)


func _on_death():
	await get_tree().create_timer(0.3).timeout
	show_death_screen()
			

# Called when the node enters the scene tree for the first time.
func show_death_screen() -> void:
	show()
	$AudioStreamPlayer.play()
	var str = ""
	for i in range(animated_text.length()):
		str += animated_text[i]
		$Label.text = str
		await get_tree().create_timer(0.1).timeout
	$Buttons.show()


func _on_restart_pressed() -> void:
	State.restart()
	pass # Replace with function body.



func _on_quit_pressed() -> void:
	State.quit()
	pass # Replace with function body.
