extends State

class_name AIMoveState

var stateName : String = "AIMove"

var cR : CharacterBody3D

func enter(char_Ref : CharacterBody3D):
	print("move")
	cR = char_Ref
	
func physics_update(delta: float):
	move(delta)

func move(delta: float):
	var current_position = cR.global_transform.origin
	var next_position = cR.navigationAgent.get_next_path_position()
	var direction = (next_position - current_position).normalized()
	cR.velocity = direction * cR.speed

	# Check if reached destination
	if cR.navigationAgent.is_navigation_finished():
		transitioned.emit(self, "aiidlestate")



