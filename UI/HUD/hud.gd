extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Messenger.mana_changed.connect(on_mana_changed)

func on_mana_changed(mana: int):
	%Label.text = str(mana)
