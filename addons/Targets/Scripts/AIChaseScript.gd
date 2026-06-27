extends AIState

class_name AIChaseState

var stateName : String = "AIChase"

var cR : EnemyTest
var player_detected : bool = false

@onready var raycast : RayCast3D = $"../../RayCast3D"
@onready var player : PlayerCharacter = get_tree().get_first_node_in_group("Player")

@export var cooldown_duration : float = 3.0
@export var stop_distance : float = 10.0
@export var flee_distance : float = 5.0
@export var max_chase_range : float = 20.0

var chase_start_position : Vector3 = Vector3.ZERO
var target_reached : bool = true
var target_ran : bool = false

func chase() -> void:
	if not player:
		return
	cR.navAgent.avoidance_enabled = true
	cR.navAgent.target_desired_distance = stop_distance
	cR.navAgent.set_target_position(player.global_position)

func enter(char_Ref : CharacterBody3D) -> void:
	cR = char_Ref
	chase_start_position = cR.global_position
	chase()
	
	target_reached = false
	target_ran = false

func update(delta : float) -> void:
	pass

func physics_update(delta : float) -> void:
	if not cR or not player:
		return
	
	# If the AI has moved too far from where the chase started, give up
	if cR.global_position.distance_to(chase_start_position) > max_chase_range:
		cR.navAgent.avoidance_enabled = false
		_stop_movement()
		target_ran = true
		transition()
		return
	
	var to_player : Vector3 = player.global_position - cR.global_position
	if to_player.length() < flee_distance:
		var flee_direction : Vector3 = -to_player.normalized()
		# Disable avoidance so manual fleeing isn't overridden by the agent
		cR.navAgent.avoidance_enabled = false
		cR.velocity.x = flee_direction.x * cR.chase_speed
		cR.velocity.z = flee_direction.z * cR.chase_speed
		_face_direction(to_player)
		playerDetection()
		transition()
		return
	cR.navAgent.avoidance_enabled = true
	cR.navAgent.set_target_position(player.global_position)
	if cR.navAgent.is_navigation_finished():
		target_reached = true
		_stop_movement()
	else:
		var next_position : Vector3 = cR.navAgent.get_next_path_position()
		_move_towards(next_position, cR.chase_speed)
	playerDetection()
	transition()

func _move_towards(target_position : Vector3, speed : float) -> void:
	var direction : Vector3 = target_position - cR.global_position
	if direction.length_squared() < 0.0001:
		return
	direction = direction.normalized()
	var desired_velocity : Vector3 = direction * speed
	_apply_velocity(desired_velocity)
	_face_direction(direction)

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
		transitioned.emit(self, "CombatState")
	if target_ran:
		transitioned.emit(self, "MoveState")
