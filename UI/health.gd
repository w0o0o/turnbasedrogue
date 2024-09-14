@tool
extends Control

@export var health_texture: Texture2D = null

@export var health = 2:
    set(v):
        update_health(v)
        health = v

@export var per_row = 5:
    set(v):
        per_row = v
        update_health(health)

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    Messenger.health_updated.connect(update_health)

func update_health(amount):
    for child in get_children():
        child.queue_free()
    var rows = ceil(float(amount) / float(per_row))
    var vbox = VBoxContainer.new()
    var remaining = amount
    var row_boxes = []
    for j in range(rows):
        var box = HBoxContainer.new()
        for i in range(per_row):
            if remaining == 0:
                break
            remaining -= 1
            var health = TextureRect.new()
            health.texture = health_texture
            health.size = Vector2(5, 5)
            health.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            box.add_child(health)
        row_boxes.append(box)
        box.alignment = BoxContainer.ALIGNMENT_END

    
    # row_boxes.reverse()
    for box in row_boxes:
        vbox.add_child(box)
    

    add_child(vbox)