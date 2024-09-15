extends Node
class_name Tutorial

func start_tutorial():

    var player_pos = State.player.global_position
    print("Tutorial: Starting tutorial")

    Messenger.force_tutorial_input.emit("move_left")
    Messenger.speech_bubble.emit("Move the left joystick to the left to move left.", player_pos, -1, "move_left")
    await Messenger.speech_bubble_hidden
    print("Tutorial: Move left done")

    Messenger.force_tutorial_input.emit("move_right")
    Messenger.speech_bubble.emit("Great! Move the left joystick to the right to move right.", player_pos, -1, "move_right")
    await Messenger.speech_bubble_hidden
    print("Tutorial: Move right done")

    Messenger.force_tutorial_input.emit("turn_around")
    Messenger.speech_bubble.emit("Now press the Y (TOP BUTTON) to turn around.", player_pos, -1, "turn_around")
    await Messenger.speech_bubble_hidden
    print("Tutorial: Turn around done")
    
    Messenger.force_tutorial_input.emit("ui_accept")
    Messenger.speech_bubble.emit("You can select a card below using the left and right bumpers. Then press A to use the card", player_pos, -1, "ui_accept")
    await Messenger.speech_bubble_hidden
    print("Tutorial: Use card done")

    Messenger.force_tutorial_input.emit("")
    Messenger.speech_bubble.emit("Great! You're ready to play!", player_pos, -1, "")



    Messenger.force_tutorial_input.emit("")
