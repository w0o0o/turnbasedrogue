extends Node2D

@export var card_base: PackedScene = null
var disabled = false
var blacksmithing = false
var cards_held = []
var cards_queued = []
var card_width = 18
var gap = 2
var max_hand_size = 5 # 2 of which are the deck and skip
var used_hover = false
var blacksmith_anvil = null
var last_hovered = 0
var shuffle_deck_cost = 3
var focused_card = null
var allowed_input

func _ready() -> void:
	Messenger.level_started.connect(started)
	Messenger.attacks_executed.connect(_on_attacks_executed)
	Messenger.attack_added_to_library.connect(_on_attack_added_to_library)

	Messenger.force_tutorial_input.connect(_on_force_tutorial_input)
	Messenger.blacksmith_opened.connect(_on_blacksmith_opened)

	Messenger.death.connect(hide)

	started()

func _on_force_tutorial_input(input_name):
	if input_name == "":
		allowed_input = null
	else:
		allowed_input = input_name

func add_card(attack: Attack):
	var card = card_base.instantiate()
	card.attack_data = attack
	add_child(card)
	card.pressed.connect(_on_attack_pressed)
	cards_held.append(card)
	order_cards()

func _on_attacks_executed(_a):
	order_cards()

func started():
	if cards_held.size() >= 3:
		return
	var new_attacks = State.gm.choose_random_attacks(3)
	for new_attack in new_attacks:
		add_card(new_attack)

var debounce = false
func _on_attack_pressed(card: Card) -> void:
	if not card:
		return
	if disabled:
		return
	if allowed_input != null and allowed_input != "use_card":
		return
	if blacksmithing and not card.deck and not card.skip:
		debounce = true
		await move_card_to_blacksmith(card)
		blacksmithing = false
		return
	if card.cooldown > 0:
		return
	if !card.selected:
		var count = 0
		var selected_cards = []
		for c in cards_held:
			if c.selected:
				count += 1
				if count > 3:
					return
	card.selected = !card.selected
	cards_held.erase(card)
	# move the card in the array. we want its pos to be after the last selected card
	var new_cards = []
	var copy = cards_held.duplicate()
	for c in cards_held:
		if c.selected:
			new_cards.append(c)
			copy.erase(c)
	print("New cards holds: %s" % new_cards.size())
	print("Copy holds: %s" % copy.size())
	new_cards.append(card)
	new_cards.append_array(copy)
	cards_held = new_cards
	order_cards()
	queue_manager()

func queue_manager():
	var count = 0
	var selected_cards:Array[Attack] = []
	for card in cards_held:
		if card.selected:
			count += 1
			if count > 3:
				card.selected = false
				count -= 1
			else:
				selected_cards.append(card.attack_data)
	Messenger.reorder_queue.emit(selected_cards)
	
func order_cards():
	if cards_held.size() == 0:
		return
	var y = 0
	var left = -((card_width + gap) / 2) * (cards_held.size() - 1)
	var i = 0
	for card in cards_held:
		i += 1
		var tweener = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		var offset = -10 if card.selected else 10
		var pos = Vector2(left, y + offset)
		tweener.tween_property(card, "position", pos, 0.2).set_delay(i * 0.05)
		left += card_width + gap
	var tweener_left = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	var tweener_right = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	var new_pos_L = Vector2(-((card_width + gap) / 2) * (cards_held.size() - 1) - (card_width + gap), 5)
	var new_pos_R = Vector2(left, 5) - Vector2(1, 0)
	tweener_left.tween_property($LeftPrompt, "position", new_pos_L, 0.2)
	tweener_right.tween_property($RightPrompt, "position", new_pos_R, 0.2)

func _on_blacksmith_opened(open, anvil):
	blacksmithing = open
	blacksmith_anvil = anvil
	if open:
		show()

func _on_attack_added_to_library(attack: Attack):
	add_card(attack)
	pass

func move_card_to_blacksmith(card: Card):
	var index = cards_held.find(card)
	cards_held.erase(card)
	var old_pos = card.global_position
	var new_pos = blacksmith_anvil.global_position - Vector2(0, 5)
	var tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card, "global_position", new_pos, 0.2)
	order_cards()
	await get_tree().create_timer(0.6).timeout
	Messenger.blacksmith_item_selected.emit(card.attack_data)
	await get_tree().create_timer(0.6).timeout
	tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card, "global_position", old_pos, 0.2)
	await get_tree().create_timer(0.2).timeout
	cards_held.insert(index, card)
	order_cards()

func _input(event: InputEvent) -> void:
	if debounce:
		debounce = false
		return
	if Input.is_action_just_pressed("ui_left"):
		debounce = true
		_ui_move(-1)
	elif Input.is_action_just_pressed("ui_right"):
		debounce = true
		_ui_move(1)
	elif Input.is_action_just_pressed("ui_select"):
		debounce = true
		_ui_select()


func _ui_move(x):
	var current_index = 0
	if focused_card:
		focused_card.focused = false
		current_index = cards_held.find(focused_card)
	
	var new_index = current_index + x
	if new_index < 0:
		new_index = 0
	if new_index >= cards_held.size():
		new_index = cards_held.size() - 1
	focused_card = cards_held[new_index]
	focused_card.focused = true
	pass

func _ui_select():
	if focused_card:
		_on_attack_pressed(focused_card)
	pass