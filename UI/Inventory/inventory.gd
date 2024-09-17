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

func _ready() -> void:
	Messenger.attack_added_to_library.connect(_on_attack_added_to_library)
	Messenger.death.connect(_on_death)
	Messenger.disable_inventory.connect(_on_disable_inventory)
	Messenger.blacksmith_opened.connect(_on_blacksmith_opened)
	Messenger.running_turns.connect(_on_running_turns)
	Messenger.end_of_turn.connect(_on_end_of_turn)
	Messenger.level_started.connect(started)
	Messenger.attacks_executed.connect(_on_attacks_executed)
	var test: Attack = Attack.new()
	test.name = "Test"
	test.damage = 1
	place_deck()
	place_skip()
	Messenger.force_tutorial_input.connect(_on_force_tutorial_input)
	# await get_t ree().create_timer(0.1).timeout
	# started()

func _on_attacks_executed(a):
	print("Attacks executed")
	for card in cards_held:
		if card.selected:
			card.cooldown = card.attack_data.cooldown
			card.selected = false
	order_cards()


func started():
	if cards_held.size() >= 5:
		return
	var new_attacks = State.gm.choose_random_attacks(3)
	for new_attack in new_attacks:
		add_card(new_attack)
var allowed_input
func _on_force_tutorial_input(input_name):
	if input_name == "":
		allowed_input = null
	else:
		allowed_input = input_name


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
	card.dragged.connect(_on_attack_dragged)
	card.position = deck.position
	cards_held.insert(1, card)
	cards_held = cards_held
	order_cards()

func _on_attack_dragged(card: Card, direction: int):
	if dragging:
		return
	dragging = true
	if allowed_input != null and allowed_input != "move_card":
		dragging = false
		return
	print("SIGNAL RECEIVED - MOVE CARD DIRECTION %s" % str(direction))
	print("SIGNAL RECEIVED - MOVE CARD ", card.name)
	move_card_in_hand(direction, card)
	await get_tree().create_timer(0.1).timeout
	dragging = false

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
		return
		if allowed_input != null and allowed_input != "draw_card":
			return


		if State.mana < shuffle_deck_cost:
			return
		State.mana -= shuffle_deck_cost
		var cards_to_keep = []
		for c in cards_held:
			if c.deck or c.skip:
				cards_to_keep.append(c)
			else:
				State.gm.add_to_discard_pile(c.attack_data)
				c.queue_free()
		cards_held.clear()
		cards_held = cards_to_keep
		
		
		var new_attacks = State.gm.choose_random_attacks(max_hand_size - 2)
		for new_attack in new_attacks:
			add_card(new_attack)

		
		order_cards()

		return
	if card.skip:
		if allowed_input != null and allowed_input != "skip_turn":
			return
		Messenger.skip_turn.emit()
		return
	
	if allowed_input != null and allowed_input != "use_card":
		return

	if card.selected:
		var cards_selected = 0
		for c in cards_held:
			if c.selected:
				cards_selected += 1
				
		card.selected = false
		cards_held.erase(card)
		cards_held.insert(cards_selected + 1, card)
	else:
		# move this card to the back of the queue
		var cards_selected = 0
		for c in cards_held:
			if c.selected:
				cards_selected += 1
				
		card.selected = true
		cards_held.erase(card)
		cards_held.insert(cards_selected + 1, card)

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
		if is_instance_valid(focused_card):
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
	handle_queue()
	var new_array = [deck]
	var y = deck.position.y
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
		var offset = -20 if card.selected else 0
		var pos = Vector2(left, y + offset)
		tweener.tween_property(card, "position", pos, 0.2).set_delay(i * 0.05)
		left += card_width + gap

	var tweener_left = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	var tweener_right = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
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
	if not v and not used_hover:
		focused_card = cards_held[last_hovered]
		focused_card.focus = true


func _on_end_of_turn():
	_on_disable_inventory(false)
	if cards_held.size() < max_hand_size:
		var new_attack = State.gm.choose_random_attacks(1)[0]
		add_card(new_attack)

func _on_disable_inventory(f):
	disabled = f


func _on_death():
	for child in get_children():
		child.queue_free()
	hide()

var dragging = false
var dragged = false	

func handle_queue():
	var queue = []
	cards_held = cards_held.filter(func (c): return c != null)
	for c in cards_held:
		if c.selected:
			queue.append(c.attack_data)
	Messenger.reorder_queue.emit(queue)

func move_card_in_hand(direction: int, card = null):
	if card == null:
		card = focused_card
	if dragging:
		var index = cards_held.find(card)
		var new_index = index + direction
		new_index = clamp(new_index, 0, cards_held.size() - 1)
		cards_held.erase(card)
		cards_held.insert(new_index, card)
		order_cards()

func _input(event: InputEvent) -> void:
	if disabled:
		return
	if Input.is_action_just_pressed("inventory_left"):
		if not dragging:
			focus_card_direction(-1)
		else:
			dragged = true
			move_card_in_hand(-1)
	elif Input.is_action_just_pressed("inventory_right"):
		if not dragging:
			focus_card_direction(1)
		else:
			dragged = true
			move_card_in_hand(1)
	elif Input.is_action_just_pressed("ui_accept"):
		dragging = true
	elif Input.is_action_pressed("ui_accept"):
		print("Accept held")
	elif Input.is_action_just_released("ui_accept"):
		print("Accept released: ", dragging)
		if not dragged:
			if is_instance_valid(focused_card):
				_on_attack_pressed(focused_card)
		dragging = false
		dragged = false

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
