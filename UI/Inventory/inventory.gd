extends Node2D

@export var card_base: PackedScene = null
var disabled = false
var blacksmithing = false

var cards_held = []: set = set_cards_held
var card_width = 18
var gap = 2
var max_hand_size = 5 # 2 of which are the deck and skip
var used_hover = false

var blacksmith_anvil = null
var last_hovered = 0

func _ready() -> void:
	Messenger.attack_added_to_library.connect(_on_attack_added_to_library)
	Messenger.death.connect(_on_death)
	Messenger.disable_inventory.connect(_on_disable_inventory)
	Messenger.blacksmith_opened.connect(_on_blacksmith_opened)
	Messenger.running_turns.connect(_on_running_turns)
	Messenger.end_of_turn.connect(_on_end_of_turn)
	var test: Attack = Attack.new()
	test.name = "Test"
	test.damage = 1
	place_deck()
	place_skip()
	pass

func set_cards_held(new_value):
	cards_held = new_value
	print("Cards held: ", cards_held.size())
	if cards_held.size() >= max_hand_size:
		deck.modulate = Color(1, 1, 1, 0.5)
	else:
		deck.modulate = Color(1, 1, 1, 1)

var deck = null
var skip = null

var debounce = false
var focused_card: Card = null

func place_deck():
	deck = card_base.instantiate()
	deck.pressed.connect(_on_attack_pressed)
	deck.deck = true
	add_child(deck)
	cards_held.append(deck)
	cards_held = cards_held

func place_skip():
	skip = card_base.instantiate()
	skip.pressed.connect(_on_attack_pressed)
	skip.skip = true
	add_child(skip)
	cards_held.append(skip)
	cards_held = cards_held
	order_cards()

func add_card(attack: Attack):
	var card = card_base.instantiate()
	card.attack_data = attack
	add_child(card)
	card.pressed.connect(_on_attack_pressed)
	card.position = deck.position
	cards_held.insert(1, card)
	cards_held = cards_held
	order_cards()


func _on_attack_pressed(card: Card) -> void:
	if not card:
		return
	if blacksmithing and not card.deck and not card.skip:
		await move_card_to_blacksmith(card)
		blacksmithing = false
		return
	if disabled:
		return
	if card.deck:
		if State.mana < 1:
			return
		State.mana -= 1
		if cards_held.size() >= max_hand_size:
			return
		var new_attack = State.gm.choose_random_attacks(1)[0]
		add_card(new_attack)
		return
	if card.skip:
		Messenger.skip_turn.emit()
		return
	
	print("Attack pressed")
	var index = cards_held.find(card)
	if card.attack_data.mana_cost > State.mana:
		print("Not enough mana")
		return
	State.mana -= card.attack_data.mana_cost
	var new_index_for_focus = index - 1
	if new_index_for_focus < 0:
		new_index_for_focus = 0
	focus_card(new_index_for_focus)
	cards_held.erase(card)
	cards_held = cards_held
	card.queue_free()
	Messenger.attack_selected.emit(card.attack_data)
	order_cards()
	

func focus_card_hover(card: Card):
	used_hover = true
	if card.hovered:
		var index = cards_held.find(card)
		focus_card(index)
	elif card == focused_card:
		focused_card.focus = false
		focused_card = null
func focus_card_direction(direction: int):
	if debounce:
		return
	debounce = true
	if used_hover:
		used_hover = false
		focus_card(0 if direction == -1 else cards_held.size() - 1)
	else:
		var index = cards_held.find(focused_card)
		var has_tool_tip = false
		if focused_card:
			has_tool_tip = focused_card.tool_tipped
		focus_card(index + direction)
		if has_tool_tip:
			focused_card.manual_tool_tip_show()
	await get_tree().create_timer(0.05).timeout
	debounce = false

func focus_card(index: int):
	if index < 0 or index >= cards_held.size():
		# wrap around
		if index < 0:
			index = cards_held.size() - 1
		else:
			index = 0
	if focused_card != null:
		focused_card.focus = false
	focused_card = cards_held[index]
	focused_card.focus = true
	last_hovered = index

func order_cards():
	var new_array = [deck]
	cards_held.erase(deck)
	cards_held.erase(skip)
	new_array.append_array(cards_held)
	new_array.append(skip)
	cards_held = new_array
	var left = -((card_width + gap) / 2) * (cards_held.size() - 1)
	var i = 0
	for card in cards_held:
		i += 1
		var tweener = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		tweener.tween_property(card, "position:x", left, 0.2).set_delay(i * 0.05)
		left += card_width + gap

	var tweener_left = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	var tweener_right = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	# $LeftPrompt.position.x = cards_held[0].position.x - ((card_width + gap) * 1.5)
	# $LeftPrompt.position.y = cards_held[0].position.y
	# $RightPrompt.position.x = cards_held[cards_held.size() - 1].position.x + ((card_width + gap) * 1.5)
	# $RightPrompt.position.y = cards_held[cards_held.size() - 1].position.y

	var new_pos_L = Vector2(-((card_width + gap) / 2) * (cards_held.size() - 1) - (card_width + gap), cards_held[0].position.y + 5)
	var new_pos_R = Vector2(left, cards_held[cards_held.size() - 1].position.y + 5)
	tweener_left.tween_property($LeftPrompt, "position", new_pos_L, 0.2)
	tweener_right.tween_property($RightPrompt, "position", new_pos_R, 0.2)


func _on_blacksmith_opened(open, anvil):
	blacksmithing = open
	blacksmith_anvil = anvil
	if open:
		show()

func _on_running_turns(v):
	_on_disable_inventory(v)
	print("Running turns: ", v)
	# if not v and not used_hover:
	# 	focused_card = cards_held[last_hovered]
	# 	focused_card.focus = true


func _on_end_of_turn():
	_on_disable_inventory(false)
	# if cards_held.size() < max_hand_size:
	# 	var new_attack = State.gm.choose_random_attacks(1)[0]
	# 	add_card(new_attack)

func _on_disable_inventory(f):
	disabled = f


func _on_death():
	for child in get_children():
		child.queue_free()
	hide()
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("inventory_left"):
		focus_card_direction(-1)
	elif Input.is_action_just_pressed("inventory_right"):
		focus_card_direction(1)
	elif Input.is_action_just_pressed("ui_accept"):
		print("Accept")
		_on_attack_pressed(focused_card)

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
