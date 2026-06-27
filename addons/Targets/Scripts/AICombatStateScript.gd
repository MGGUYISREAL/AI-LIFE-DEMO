extends AIState

class_name AICombatState

var stateName : String = "AICombat"

var cR : EnemyTest
var player_detected : bool = false

@onready var raycast : RayCast3D = $"../../RayCast3D"
@onready var player : PlayerCharacter = get_tree().get_first_node_in_group("Player")

@export var attack_cooldown : float = 2.0
@export var attack_damage : float = 15.0
@export var combat_range : float = 12.0
@export var chase_range : float = 20.0
@export var retreat_distance : float = 5.0

var can_attack : bool = true
var attack_cooldown_timer : float = 0.0

var is_retreating : bool = false
var retreat_target : Vector3 = Vector3.ZERO

var cover_spots : Array = []
var current_cover_spot : Marker3D = null

func enter(char_Ref : CharacterBody3D) -> void:
	print("Entering combat")
	cR = char_Ref
	can_attack = true
	attack_cooldown_timer = 0.0
	is_retreating = false
	retreat_target = Vector3.ZERO
	current_cover_spot = null
	cover_spots = _get_cover_spots()

func exit() -> void:
	player_detected = false

func update(delta : float) -> void:
	if not can_attack:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0.0:
			can_attack = true

func physics_update(delta : float) -> void:
	if not cR or not player:
		return
	
	var to_player : Vector3 = player.global_position - cR.global_position
	var distance_to_player : float = to_player.length()
	
	# Retreat to cover if the player gets too close
	if not is_retreating and distance_to_player < retreat_distance:
		_start_retreat()
	
	if is_retreating:
		_retreat_update()
	else:
		# Stop movement while engaged in combat at range
		_stop_movement()
		# Always face the player during combat
		_face_direction(to_player)
		# Attack the player on cooldown if within combat range
		if can_attack and distance_to_player <= combat_range:
			_attack_player()
	
	playerDetection()
	transition()

func _get_cover_spots() -> Array:
	var spots : Array = []
	var cover_parent : Node = get_tree().get_first_node_in_group("AICover_Spots")
	if not cover_parent:
		return spots
	for child in cover_parent.get_children():
		if child is Marker3D:
			spots.append(child)
	return spots

func _find_nearest_cover_spot(exclude_spot : Marker3D = null) -> Marker3D:
	if cover_spots.is_empty() or not cR:
		return null
	var nearest : Marker3D = null
	var nearest_dist : float = INF
	var enemy_pos : Vector3 = cR.global_position
	for spot in cover_spots:
		var spot_node : Marker3D = spot
		# Skip the excluded spot (the one we're already at)
		if exclude_spot and spot_node == exclude_spot:
			continue
		var dist : float = enemy_pos.distance_squared_to(spot_node.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = spot_node
	return nearest

func _attack_player() -> void:
	if not player or not cR:
		return
	
	can_attack = false
	attack_cooldown_timer = attack_cooldown
	
	# Calculate direction from enemy to player for the hit
	var attack_dir : Vector3 = (player.global_position - cR.global_position).normalized()
	var attack_pos : Vector3 = cR.global_position
	
	# Deal damage to the player using the hitscan damage method
	if player.has_method("hitscanHit"):
		player.hitscanHit(attack_damage, attack_dir, attack_pos)
		print("Enemy attacked player for ", attack_damage, " damage")
	
	# Play attack animation if available
	if cR.animManager and cR.animManager.has_animation("attack"):
		cR.animManager.play("attack")

func _start_retreat() -> void:
	if is_retreating:
		return
	
	# Find nearest cover spot that isn't the one we're already at
	var target_spot : Marker3D = _find_nearest_cover_spot(current_cover_spot)
	if not target_spot:
		# No other cover spot available — try the current one as a fallback
		target_spot = current_cover_spot
		if not target_spot:
			return
	
	is_retreating = true
	can_attack = false
	attack_cooldown_timer = attack_cooldown
	current_cover_spot = null
	
	retreat_target = target_spot.global_position
	retreat_target.y = cR.global_position.y
	
	# Navigate to the cover spot
	cR.navAgent.avoidance_enabled = true
	cR.navAgent.target_desired_distance = 1.5
	cR.navAgent.set_target_position(retreat_target)
	
	print("Retreating to cover spot: ", target_spot.name)

func _retreat_update() -> void:
	if not cR or not player:
		return
	
	var to_player : Vector3 = player.global_position - cR.global_position
	var distance_to_player : float = to_player.length()
	
	# Check if we've arrived at the cover spot
	if cR.navAgent.is_navigation_finished():
		_stop_movement()
		is_retreating = false
		can_attack = true
		current_cover_spot = _find_nearest_cover_spot()
		cR.navAgent.target_desired_distance = 2.0
		print("Reached cover at: ", current_cover_spot.name if current_cover_spot else "unknown")
		return
	
	# If the player backed off to a safe distance while we were retreating, stop and fight
	if distance_to_player >= combat_range:
		_stop_movement()
		is_retreating = false
		can_attack = true
		cR.navAgent.target_desired_distance = 2.0
		return
	
	# Keep moving toward the retreat target
	var next_position : Vector3 = cR.navAgent.get_next_path_position()
	_move_towards(next_position, cR.chase_speed)
	
	# Face the player while moving to cover
	_face_direction(to_player)

func _move_towards(target_position : Vector3, speed : float) -> void:
	var direction : Vector3 = target_position - cR.global_position
	if direction.length_squared() < 0.0001:
		return
	direction = direction.normalized()
	var desired_velocity : Vector3 = direction * speed
	_apply_velocity(desired_velocity)

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
	if raycast and raycast.is_colliding():
		if raycast.get_collider().is_in_group("Player"):
			player_detected = true

func transition() -> void:
	if not cR or not player:
		return
	
	var to_player : Vector3 = player.global_position - cR.global_position
	var distance_to_player : float = to_player.length()
	
	# If player moved too far away, chase them again
	if distance_to_player > chase_range:
		transitioned.emit(self, "ChaseState")
		return
	
	# Only give up combat and return to idle if the player is out of detection range
	# AND not visible. Being behind cover blocks the raycast, but the player is still nearby.
	if not player_detected and distance_to_player > combat_range:
		transitioned.emit(self, "IdleState")
