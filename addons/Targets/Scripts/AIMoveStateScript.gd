extends AIState

class_name AIMoveState

var stateName : String = "AIMove"

var target_reached = true
var cR : EnemyTest
var patrol_time : float = 0.0
var remaining_patrol_time : float = 0.0

@onready var target: Vector3

func patrol():
	#generate a random point around the character within a certain radius
	var random_direction: Vector3 = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	target = random_direction
	remaining_patrol_time += randf_range(2.0, 8.0) #wander for a random time between 2 and 5 seconds

	print("patrolling to : ", target)
	return

func enter(char_Ref : CharacterBody3D):
	print("Patrolling")
	cR = char_Ref
	
	target_reached = false
	patrol()

func update(delta : float) -> void:
	#if wander time ended
	if remaining_patrol_time <= 0.0:
		target_reached = true
	else:
		remaining_patrol_time -= delta

func physics_update(delta: float):
	# Check to stop move whentarget is reached
	if cR:
		#move towards the target
		cR.velocity = lerp(cR.velocity, target * cR.speed, 0.1)
		#rotate towards the target
		cR.rotation.y = lerp_angle(cR.rotation.y, atan2(target.x, target.z), 0.05)
		
	transition()

func transition() -> void:
	if target_reached:
		transitioned.emit(self, "IdleState")
