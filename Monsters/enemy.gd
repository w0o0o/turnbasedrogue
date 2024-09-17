extends Entity
class_name Enemy


		# turn = {
		# 	"type": "ATTACK"
		# }
var spawned = true
var aggro_icon: Sprite2D = null
var attack_icon: Sprite2D = null
var prediction_priority = 0
var health_bar = null

@onready var hb_scene = preload("res://UI/Inventory/IconLabels/Health.tscn")

func create_icon(src: String):
	var icon = Sprite2D.new()
	icon.texture = load(src)
	icon.scale = Vector2(0.5, 0.5)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.position = Vector2(0, -30)
	icon.hide()
	return icon

func setup_health():
	health_bar = hb_scene.instantiate()
	var pos = Vector2(0, -30)
	if has_node("health_pos"):
		pos = get_node("health_pos").position
	health_bar.position = pos
	add_child(health_bar)
	health_bar.mana_count = health
	health_bar.show_mana()

func _on_health_change(_v: int):
	if health_bar != null:
		health_bar.mana_count = health
		health_bar.update_count()


@export var attacks: Array[Attack] = []

func _ready():
	super._ready()
	aggro_icon = create_icon("res://UI/aggrro.aseprite")
	attack_icon = create_icon("res://Game/MapGen/Sprites/item_9.png")
	add_child(aggro_icon)
	add_child(attack_icon)
	setup_health()


func predict_turn(game: GameManager) -> int:
	if not spawned:
		return -1
	var player_cell = game.player.cell
	var my_cell = cell
	var direction = player_cell - my_cell
	direction = sign(direction)
	# var distance = abs(my_cell - player_cell)

	if direction != facing: # player is not in line of sight
		turn = {
			"type": "TURNAROUND",
		}
		return -1

	if entity_state == EntityState.QUEUED_ATTACK:
		if can_hit_entity(game.player, attacks[0]):
			turn = {
				"type": "AGGRO"
			}
			entity_state = EntityState.AGGRO
			if name == "Skeleton":
				print("Skeleton will: %s" % turn)
			return 10
		else:
			turn = {
				"type": "MOVE",
				"args": [direction]
			}
			if name == "Skeleton":
				print("Skeleton will: %s" % turn)
			# 1 in 3 chance to aggro if can hit player
			if can_hit_entity(game.player, attacks[0]) and randi() % 3 == 0:
				turn = {
					"type": "AGGRO"
				}
				entity_state = EntityState.AGGRO
				if name == "Skeleton":
					print("Skeleton will: %s" % turn)
			return -1
	elif entity_state == EntityState.AGGRO:
		turn = {
			"type": "ATTACK"
		}
		if name == "Skeleton":
			print("Skeleton will: %s" % turn)
		entity_state = EntityState.ATTACKING
	elif entity_state == EntityState.IDLE:
		turn = {
			"type": "QUEUE_ATTACK"
		}
		if name == "Skeleton":
			print("Skeleton will: %s" % turn)
		return 10
	elif entity_state == EntityState.RETREATING:
		turn = {
			"type": "MOVE",
			"args": [-direction] # move away from player
		}
		return -1
	return -1


func run_turn(game: GameManager):
	if not spawned:
		spawned = true
		return
	if name == "Skeleton":
		print("Skeleton turn: %s" % turn)
	aggro_icon.visible = false
	if turn["type"] == "MOVE":
		if entity_state == EntityState.RETREATING:
			entity_state = EntityState.IDLE
		var direction = turn["args"][0]
		var can = game.can_move(self, direction)
		if can:
			game.move(self, direction)
			await get_tree().create_timer(0.5).timeout
	elif turn["type"] == "TURNAROUND":
		game.turn_around(self)
		await get_tree().create_timer(0.1).timeout
	elif turn["type"] == "QUEUE_ATTACK":
		add_to_attack_queue(attacks[0])
		entity_state = EntityState.QUEUED_ATTACK
	elif turn["type"] == "ATTACK":
		for attack in attack_queue:
			await execute_attack(attack)
		attack_queue.clear()
		await get_tree().create_timer(0.1).timeout
		entity_state = EntityState.RETREATING
	turn = default_turn
	_manage_animation_state()
	return
func _on_state_change(_v: EntityState):
	_manage_animation_state()
	pass
func _manage_animation_state():
	if attack_queue.size() > 0:
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
