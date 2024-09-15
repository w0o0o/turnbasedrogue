extends Node2D
class_name SpeechBubble

var wait_for_input = false
var input_to_wait_for = ""
func _ready() -> void:
    print("Speech bubble ready")
    Messenger.speech_bubble.connect(_on_speech_bubble)

func _on_speech_bubble(text: String, pos: Vector2, duration: float, input_action: String) -> void:
    print("Showing speech bubble: %s" % text)
    if input_action == null:
        input_to_wait_for = "ui_accept"
    else:
        input_to_wait_for = input_action
    $PanelContainer/Label.text = text
    global_position = pos
    show_speech_bubble(duration)

func _input(event: InputEvent) -> void:
    if wait_for_input and Input.is_action_just_pressed(input_to_wait_for):
        hide_speech_bubble()

func hide_speech_bubble():
    wait_for_input = false
    print("Hiding speech bubble")
    $AnimationPlayer.play_backwards("show")
    $PanelContainer/Label.text = ""
    Messenger.speech_bubble_hidden.emit()

    pass

func show_speech_bubble(duration: float = -1) -> void:
    $AnimationPlayer.play("show")
    if duration > 0 or duration == null:
        await get_tree().create_timer(duration - 0.2).timeout
        hide_speech_bubble()
    else:
        wait_for_input = true