extends AIState

class_name AIChaseStateOld

var stateName : String = "AICombat"

var cR : EnemyTest
var player_detected : bool = false

@onready var raycast: RayCast3D = $"../../RayCast3D"
@onready var player: PlayerCharacter = get_tree().get_first_node_in_group("Player")


@export var cooldown_duration: float = 3.0
@export var stop_distance: float = 5.0

var cooldown_time_remaining: float = 0.0
var attack_cooldown: bool = false


func chase() -> void:
	if not player:
		return
	cR.navAgent.target_desired_distance = stop_distance
	cR.navAgent.set_target_position(player.global_position)

func enter(char_Ref : CharacterBody3D) -> void:
	cR = char_Ref
	chase()

func update(delta : float) -> void:
	pass

func physics_update(delta: float) -> void:
	if not cR or not player:
		return
	playerDetection()
	if cR.navAgent.is_navigation_finished():
		_stop_movement()
		transition()
		return
	cR.navAgent.set_target_position(player.global_position)
	var next_position: Vector3 = cR.navAgent.get_next_path_position()
	_move_towards(next_position, cR.chase_speed)
	transition()

func _move_towards(target_position: Vector3, speed: float) -> void:
	var direction: Vector3 = target_position - cR.global_position
	if direction.length_squared() < 0.0001:
		return
	direction = direction.normalized()
	var desired_velocity: Vector3 = direction * speed
	_apply_velocity(desired_velocity)
	_face_direction(direction)

func _apply_velocity(desired_velocity: Vector3) -> void:
	if cR.navAgent.avoidance_enabled:
		cR.navAgent.velocity = desired_velocity
	else:
		cR.velocity = desired_velocity

func _stop_movement() -> void:
	if cR.navAgent.avoidance_enabled:
		cR.navAgent.velocity = Vector3.ZERO
	cR.velocity = Vector3.ZERO

func _face_direction(direction: Vector3) -> void:
	var look_direction: Vector3 = direction.normalized()
	var target_rotation: float = atan2(look_direction.x, look_direction.z)
	cR.rotation.y = lerp_angle(cR.rotation.y, target_rotation, 0.05)

func playerDetection() -> void:
	if raycast.is_colliding():
		if raycast.get_collider().is_in_group("Player"):
			player_detected = true
			print("Player detected")

func transition() -> void:
	pass
	
