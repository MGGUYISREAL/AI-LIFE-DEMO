extends AIState

class_name AIIdleState

var stateName : String = "AIIdle"

var cR : EnemyTest
var player_detected : bool = false

@onready var raycast: RayCast3D = $"../../RayCast3D"
@export var target: Vector3

var cooldown_duration: float = randf_range(2.0, 5.0)
var cooldown_time_remaining: float = 0.0
var in_cooldown: bool = false

func enter(char_Ref : CharacterBody3D) -> void:
	print("Entering idle")
	cooldown_time_remaining += cooldown_duration
	in_cooldown = true
	
	cR = char_Ref
	if raycast and cR:
		raycast.add_exception(cR)

func update(delta : float) -> void:
	#for move cooldown
	if in_cooldown:
		cooldown_time_remaining -= delta
		if cooldown_time_remaining <= 0.0:
			in_cooldown = false

func physics_update(delta: float) -> void:
	if cR:
		cR.velocity = Vector3.ZERO
	
	playerDetection()
	transition()

func playerDetection() -> void:
	if raycast.is_colliding():
		if raycast.get_collider().is_in_group("Player"):
			player_detected = true
			print("Player detected")

func transition() -> void:
	if player_detected:
		transitioned.emit(self, "ChaseState")
	if in_cooldown == false:
		transitioned.emit(self, "MoveState")
