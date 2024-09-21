extends Entity
class_name Enemy


enum EnemyTraits {
	NORETREAT, # enemy will not retreat 
	INSTANTATTACK, # enemy will aggro if it can hit the player when it queues an attack
	AGGRESSIVE, # instead of retreating, the enemy will move towards the player
	DOUBLEMOVE, # enemy will move twice as fast (2 cells per turn if possible else 1 cell)
}
var spawned = true
var aggro_icon: Sprite2D = null
var attack_icon = null
var prediction_priority = 0
var health_bar = null
@export var attacks: Array[Attack] = []
@export var traits:Array[EnemyTraits] = [] 

@onready var hb_scene = preload("res://Game/Health/Healthbar.tscn")
@onready var att_icon_scene = preload("res://Attacks/attack_icon/AttackIcon.tscn")

func create_icon(src: String):
	var icon = Sprite2D.new()
	icon.texture = load(src)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.position = Vector2(0, -30)
	icon.hide()
	return icon

func setup_health():
	health_bar = hb_scene.instantiate()
	var pos = Vector2(0, -30)
	if has_node("health_pos"):
		pos = get_node("health_pos").position
	pos = Vector2(0, 1)
	health_bar.position = pos
	health_bar.z_index = 100000000
	add_child(health_bar)
	health_bar.max_amount = health
	health_bar.amount = health
	health_bar.show()

func _on_health_change(_v: int):
	if health_bar != null:
		if health <= 0:
			attack_icon.hide()
			aggro_icon.hide()
			health_bar.amount = 0
			health_bar.hide()
		else:
			health_bar.amount = health



func _ready():
	super._ready()
	aggro_icon = create_icon("res://UI/aggrro.aseprite")
	attack_icon = att_icon_scene.instantiate()
	attack_icon.hide()
	add_child(aggro_icon)
	add_child(attack_icon)
	setup_health()
	Messenger.death.connect(health_bar.hide)

var chosen_attack = null

func enemy_can_hit_player(game: GameManager):
	var can_hit_player = false
	attacks.shuffle() # randomize the order of attacks we check to make it less predictable
	if chosen_attack != null:
		if can_hit_entity(game.player, chosen_attack):
			can_hit_player = true
			return can_hit_player
	for attack in attacks:
		if can_hit_entity(game.player, attack):
			can_hit_player = true
			chosen_attack = attack
			break

func predict_turn(game: GameManager) -> int:
	if not spawned:
		return -1

	var player_cell = game.player.cell
	var direction_to_player = sign(player_cell - cell)
	var has_line_of_sight = game.has_line_of_sight(self, game.player)
	var can_hit_player = enemy_can_hit_player(game)
	var has_attack_queued = attack_queue.size() > 0

	if entity_state == EntityState.AGGRO:
		# we must attack
		print("Enemy is aggro, will try to attack")
		turn = {
			"type": "ATTACK"
		}
		return 10

	if entity_state == EntityState.RETREATING:
		var retreat_direction = direction_to_player if traits.has(EnemyTraits.AGGRESSIVE) else -direction_to_player
		print("Enemy is retreating, will move %s" % retreat_direction)
		turn = {
			"type": "MOVE",
			"args": [retreat_direction] # move away from player
		}
		return -1

	if can_hit_player:
		if has_attack_queued:
			print("Enemy already has an attack queued, and we can hit the player, therefore we will aggro")
			turn = {
				"type": "AGGRO"
			}
			return 10
		else:
			print("Enemy can hit player, but no attack queued, therefore we will queue an attack")
			turn = {
				"type": "QUEUE_ATTACK"
			}
			return 10
	else:
		if direction_to_player != facing: # enemy is not facing the player
			print("Enemy is not facing the player, will turn around")
			turn = {
				"type": "TURNAROUND",
			}
			return -1
		if has_line_of_sight:
			print("Enemy has line of sight to player, will move towards player")
			# we only move towards the player if we have line of sight to them
			var move_direction = direction_to_player
			if traits.has(EnemyTraits.DOUBLEMOVE):
				# double move
				var can = game.can_move(self, move_direction * 2)
				if can:
					move_direction *= 2
					print("Enemy has double move, will move twice as fast")
			turn = {
				"type": "MOVE",
				"args": [move_direction]
			}
			return -1
		else:
			print("Enemy has no line of sight to player, will move randomly")
		
	# enemy cant do anything, skip turn
	print("Enemy can't do anything, skipping turn")
	turn = default_turn
	return -1


func run_turn(game: GameManager):
	if not spawned:
		spawned = true
		return
	print("Enemy turn: %s" % turn)
	if turn["type"] == "MOVE":
		var direction = turn["args"][0]
		var can = game.can_move(self, direction)
		if can:
			game.move(self, direction)
		var can_hit_player = enemy_can_hit_player(game)
		if can_hit_player and attack_queue.size() > 0:
			entity_state = EntityState.AGGRO
		else:
			entity_state = EntityState.IDLE
		# this will reset the state to idle so anythign else can happen
	elif turn["type"] == "TURNAROUND":
		game.turn_around(self)
		var can_hit_player = enemy_can_hit_player(game)
		if can_hit_player and attack_queue.size() > 0:
			entity_state = EntityState.AGGRO
		else:
			entity_state = EntityState.IDLE
		# this will reset the state to idle so anythign else can happen
	elif turn["type"] == "QUEUE_ATTACK":
		add_to_attack_queue(chosen_attack)
		entity_state = EntityState.QUEUED_ATTACK
		# this will trigger aggro if the player is in range
	elif turn["type"] == "AGGRO":
		var can_hit_player = enemy_can_hit_player(game)
		if can_hit_player:
			entity_state = EntityState.AGGRO
		else:
			entity_state = EntityState.IDLE
		# this will trigger the attack on the next turn
	elif turn["type"] == "ATTACK":
		for attack in attack_queue:
			await execute_attack(attack)
		attack_queue.clear()
		chosen_attack = null
		entity_state = EntityState.RETREATING
	turn = default_turn
	return
func _on_state_change(_v: EntityState):
	_manage_animation_state()
	pass

func _manage_animation_state():
	print("Enemy state: %s" % EntityState.keys()[entity_state])
	if attack_queue.size() > 0:
		attack_icon.frame = attack_queue[0].icon_frame
		attack_icon.visible = true
	else:
		attack_icon.visible = false
	if entity_state == EntityState.AGGRO:
		$AnimatedSprite2D.play("pre_attack")
		aggro_icon.visible = true
	else:
		aggro_icon.visible = false
		$AnimatedSprite2D.play("idle")

	pass
