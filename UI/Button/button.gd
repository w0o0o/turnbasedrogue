extends Button

@export var auto_focus: bool = false

func _ready() -> void:
	$FlairLeft.hide()
	$FlairRight.hide()

func hover()->void:
	$FlairLeft.show()
	$FlairRight.show()

func unhover()->void:
	$FlairLeft.hide()
	$FlairRight.hide()

func _on_mouse_exited() -> void:
	unhover()


func _on_mouse_entered() -> void:
	hover()


func _on_focus_exited() -> void:
	unhover()


func _on_focus_entered() -> void:
	hover()


func _on_visibility_changed() -> void:
	if visible and auto_focus:
		grab_focus()
		hover()