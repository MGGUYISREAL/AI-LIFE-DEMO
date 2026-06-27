extends AIState

class_name AIMoveState

var stateName : String = "AIMove"

var target_reached : bool = true
var player_detected : bool = false
var cR : EnemyTest

var remaining_patrol_time : float = 0.0

var target : Vector3 = Vector3.ZERO
@onready var raycast : RayCast3D = $"../../RayCast3D"

@export var patrol_radius : float = 12.0
@export var min_patrol_time : float = 2.0
@export var max_patrol_time : float = 8.0

func patrol() -> void:
	if not cR:
		return
	randomize()
	var random_direction : Vector3 = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	if random_direction == Vector3.ZERO:
		random_direction = Vector3.FORWARD
	random_direction = random_direction.normalized()
	var destination : Vector3 = cR.global_position + random_direction * patrol_radius
	destination.y = cR.global_position.y
	target = destination
	cR.navAgent.set_target_position(target)
	remaining_patrol_time = randf_range(min_patrol_time, max_patrol_time)

func enter(char_Ref : CharacterBody3D) -> void:
	cR = char_Ref
	target_reached = false
	patrol()

func update(delta : float) -> void:
	pass

func physics_update(delta: float) -> void:
	if not cR:
		return
	if cR.navAgent.is_navigation_finished():
		target_reached = true
		_stop_movement()
	else:
		var next_position : Vector3 = cR.navAgent.get_next_path_position()
		var direction : Vector3 = next_position - cR.global_position
		if direction.length_squared() < 0.0001:
			return
		direction = direction.normalized()
		_apply_velocity(direction * cR.speed)
		_face_direction(direction)
	playerDetection()
	transition()

func _apply_velocity(desired_velocity : Vector3) -> void:
	if cR.navAgent.avoidance_enabled:
		cR.navAgent.velocity = desired_velocity
	else:
		cR.velocity = desired_velocity

func _stop_movement() -> void:
	if cR.navAgent.avoidance_enabled:
		cR.navAgent.velocity = Vector3.ZERO
	cR.velocity = Vector3.ZERO

func _face_direction(direction : Vector3) -> void:
	var look_direction : Vector3 = direction.normalized()
	var target_rotation : float = atan2(look_direction.x, look_direction.z)
	cR.rotation.y = lerp_angle(cR.rotation.y, target_rotation, 0.05)

func playerDetection() -> void:
	if raycast.is_colliding():
		if raycast.get_collider().is_in_group("Player"):
			player_detected = true


func transition() -> void:
	if target_reached:
		transitioned.emit(self, "IdleState")
	elif player_detected:
		transitioned.emit(self, "ChaseState")
