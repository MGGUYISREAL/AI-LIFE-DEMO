extends AIState

class_name AIDeathState

var stateName : String = "AIDeath"

var cR : EnemyTest
var death_animation_finished : bool = false


func enter(char_Ref : CharacterBody3D) -> void:
	print("Entering death state")
	cR = char_Ref
	death_animation_finished = false
	
	if not cR:
		return
	
	# Disable the enemy's state machine so other states can't interrupt death
	cR.stateMachine.set_process(false)
	cR.stateMachine.set_physics_process(false)
	
	# Disable collision so the enemy can't be hit again
	cR.set_collision_layer_value(1, false)
	cR.set_collision_mask_value(1, false)
	
	# Stop any current movement
	cR.velocity = Vector3.ZERO
	
	# Play the death (fall) animation and connect the finished signal
	if cR.animManager and cR.animManager.has_animation("fall"):
		cR.animManager.animation_finished.connect(_on_death_animation_finished)
		cR.animManager.play("fall")
	else:
		# No animation available, die immediately
		_die()


func exit() -> void:
	if cR and cR.animManager:
		if cR.animManager.animation_finished.is_connected(_on_death_animation_finished):
			cR.animManager.animation_finished.disconnect(_on_death_animation_finished)


func update(_delta : float) -> void:
	# Wait for the death animation to finish before dying
	if death_animation_finished:
		_die()


func physics_update(_delta : float) -> void:
	# Keep enemy rooted during death
	if cR:
		cR.velocity = Vector3.ZERO


func _on_death_animation_finished(anim_name : String) -> void:
	if anim_name == "fall":
		death_animation_finished = true


func _die() -> void:
	if not cR:
		return
	
	print("Enemy died")
	# Remove the enemy from the scene
	cR.queue_free()
