extends State

class_name AIIdleState

var stateName : String = "AIIdle"

var cR : CharacterBody3D
var wander_time : float = 0.0

@export var target: Vector3

func wander():
	#generate a random point around the character within a certain radius
	var random_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	target = random_direction
	wander_time = randf_range(2.0, 5.0) #wander for a random time between 2 and 5 seconds

	print("wandered to : ", target)

func enter(char_Ref : CharacterBody3D):
	print("idle")
	cR = char_Ref

func update(delta : float):
	if wander_time <= 0.0:
		wander()
	else:
		wander_time -= delta

func physics_update(delta: float):
	if cR:
		#move towards the target
		cR.velocity = lerp(cR.velocity, target * cR.speed, 0.1)
		#rotate towards the target
		cR.rotation.y = lerp(cR.rotation.y, atan2(target.x, target.z), 0.05)

func transition():
	#Combat transition
	pass