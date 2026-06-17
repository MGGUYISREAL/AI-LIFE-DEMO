extends AIState

class_name AIChaseState

var stateName : String = "AICombat"

var cR : EnemyTest
var player_detected : bool = false

@onready var raycast: RayCast3D = $"../../RayCast3D"
@export var enemy_target: Vector3
@onready var player: PlayerCharacter = get_tree().get_first_node_in_group("Player")


@export var cooldown_duration: float = 3.0
@export var stop_distance: float = 5.0

var cooldown_time_remaining: float = 0.0
var attack_cooldown: bool = false


func chase():
	#Chasing the AI's target
	cR.navigationAgent.target_desired_distance = stop_distance
	cR.navigationAgent.set_target_position(player.global_position)
	
	print("chasing: ", enemy_target)

func enter(char_Ref : CharacterBody3D):
	print("Entering chase")
	cR = char_Ref
	
	chase()

func update(delta : float) -> void:
	pass

func physics_update(delta: float) -> void:
	if cR:
		var to_player: Vector3 = player.global_position - cR.global_position
		var away_player: Vector3 = player.global_position + cR.global_position
		var distance: float = to_player.length()
		if distance > stop_distance:
			var direction: Vector3 = to_player.normalized()
			var target_velocity: Vector3 = direction * cR.chase_speed
			cR.velocity = cR.velocity.lerp(target_velocity, 0.1)
			cR.rotation.y = lerp_angle(cR.rotation.y, atan2(direction.x, direction.z), 0.05)
		elif distance < stop_distance - 2:
			var direction: Vector3 = away_player.normalized()
			var target_velocity: Vector3 = direction * cR.chase_speed
			cR.velocity = cR.velocity.lerp(target_velocity, 0.1)
			cR.rotation.y = lerp_angle(cR.rotation.y, atan2(direction.x, direction.z), 0.05)
		else:
			var direction: Vector3 = to_player.normalized()
			cR.velocity = cR.velocity.lerp(Vector3.ZERO, 0.1)
			cR.rotation.y = lerp_angle(cR.rotation.y, atan2(direction.x, direction.z), 0.05)
		cR.move_and_slide()

	transition()

func playerDetection() -> void:
	if raycast.is_colliding():
		if raycast.get_collider().is_in_group("Player"):
			player_detected = true
			print("Player detected")

func transition() -> void:
	pass
