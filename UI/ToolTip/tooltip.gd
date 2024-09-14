extends Node2D

var shown = false
func hide_tooltip():
	if not shown:
		return
	shown = false
	$AnimationPlayer.play_backwards("show")
	pass

func show_tooltip():
	if shown:
		return
	shown = true
	$AnimationPlayer.play("show")
	pass

func set_tooltip(text: String):
	%Label.text = text
	pass