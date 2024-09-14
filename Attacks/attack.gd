extends Resource
class_name Attack


@export var name: String = ""
@export var icon: Texture2D = null
@export var icon_frame: int = 0
@export var description: String = ""
@export var animation: String = ""
@export var damage_cells: Array[int] = []
@export var damage: int = 0
@export var mana_cost: int = 1
@export var projectile: bool = false
@export var piercing: int = 0
@export var reverse: bool = false # attack hits the last enemy first (in the direction of the attack)
@export var direction: int = 0
@export var ramming: bool = false # attack moves towards the next enemy in the direction of the attack

func upgrade():
    damage += 1
    Messenger.attack_upgraded.emit(self)
    State.gm.on_attack_upgraded(self)