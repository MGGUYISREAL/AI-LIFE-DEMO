extends CharacterBody3D

class_name EnemyTest

@export var speed : float = 1.0
@export var chase_speed : float = 5.0
@export var health : float = 100.0
@export var wait_time : float = 0.0

var healthRef : float
var isDisabled : bool = false

@onready var animManager : AnimationPlayer = $AnimationPlayer
@onready var navAgent : NavigationAgent3D = $NavigationAgent3D
@onready var stateMachine : Node = $StateMachine
@onready var Raycast : RayCast3D = $RayCast3D
@onready var Shapecast: ShapeCast3D = $ShapeCast3D


func _ready():
	healthRef = health
	animManager.play("idle")
	navAgent.velocity_computed.connect(Callable(self, "_on_nav_agent_velocity_computed"))

func _physics_process(delta: float):
	velocity += get_gravity() * delta

	move_and_slide()

func _on_nav_agent_velocity_computed(safe_velocity: Vector3) -> void:
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	
func hitscanHit(damageVal : float, _hitscanDir : Vector3, _hitscanPos : Vector3):
	health -= damageVal
	
	print("Hitscan hit, target health : ", health)
	
	if health <= 0.0 and !isDisabled:
		isDisabled = true
		animManager.play("fall")
		
func projectileHit(damageVal : float, _hitscanDir : Vector3):
	health -= damageVal
	
	print("Projectile hit, target health : ", health)
	
	if health <= 0.0 and !isDisabled:
		isDisabled = true
		animManager.play("fall")
