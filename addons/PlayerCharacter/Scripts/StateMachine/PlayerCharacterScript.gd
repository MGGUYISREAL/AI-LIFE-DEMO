extends CharacterBody3D

class_name PlayerCharacter 

@export_group("Movement variables")
var moveSpeed : float
var moveAccel : float
var moveDeccel : float
var desiredMoveSpeed : float 
@export var desiredMoveSpeedCurve : Curve
@export var maxSpeed : float
@export var inAirMoveSpeedCurve : Curve
var inputDirection : Vector2 
var moveDirection : Vector3 
@export var hitGroundCooldown : float #amount of time the character keep his accumulated speed before losing it (while being on ground)
var hitGroundCooldownRef : float 
@export var bunnyHopDmsIncre : float #bunny hopping desired move speed incrementer
@export var autoBunnyHop : bool = false
var lastFramePosition : Vector3 
var lastFrameVelocity : Vector3
var wasOnFloor : bool
var walkOrRun : String = "WalkState" #keep in memory if play char was walking or running before being in the air
#for crouch visible changes
@export var baseHitboxHeight : float
@export var baseModelHeight : float
@export var heightChangeSpeed : float

@export_group("Crouch variables")
@export var crouchSpeed : float
@export var crouchAccel : float
@export var crouchDeccel : float
@export var continiousCrouch : bool = false #if true, doesn't need to keep crouch button on to crouch
@export var crouchHitboxHeight : float
@export var crouchModelHeight : float

@export_group("Walk variables")
@export var walkSpeed : float
@export var walkAccel : float
@export var walkDeccel : float

@export_group("Run variables")
@export var runSpeed : float
@export var runAccel : float 
@export var runDeccel : float 
@export var continiousRun : bool = false #if true, doesn't need to keep run button on to run

@export_group("Jump variables")
@export var jumpHeight : float
@export var jumpTimeToPeak : float
@export var jumpTimeToFall : float
@onready var jumpVelocity : float = (2.0 * jumpHeight) / jumpTimeToPeak
@export var jumpCooldown : float
var jumpCooldownRef : float 
@export var nbJumpsInAirAllowed : int 
var nbJumpsInAirAllowedRef : int 
var jumpBuffOn : bool = false
var bufferedJump : bool = false
@export var coyoteJumpCooldown : float
var coyoteJumpCooldownRef : float
var coyoteJumpOn : bool = false
@export_range(0.1, 1.0, 0.05) var inAirInputMultiplier: float = 1.0

@export_group("Gravity variables")
@onready var jumpGravity : float = (-2.0 * jumpHeight) / (jumpTimeToPeak * jumpTimeToPeak)
@onready var fallGravity : float = (-2.0 * jumpHeight) / (jumpTimeToFall * jumpTimeToFall)

@export_group("Health variables")
@export var maxHealth : float = 100.0
var health : float

@export var fallDamageThreshold : float = 10.0
@export var fallDamageMultiplier : float = 1.0

@export var fallDamageMinHeight : float = 2.0
var fallStartY : float = 0.0

@export_group("Keybind variables")
@export var moveForwardAction : String = ""
@export var moveBackwardAction : String = ""
@export var moveLeftAction : String = ""
@export var moveRightAction : String = ""
@export var runAction : String = ""
@export var crouchAction : String = ""
@export var jumpAction : String = ""

#references variables
@onready var camHolder : Node3D = $CameraHolder
@onready var model : MeshInstance3D = $Model
@onready var hitbox : CollisionShape3D = $Hitbox
@onready var stateMachine : Node = %StateMachine
@onready var hud : CanvasLayer = $HUD
@onready var ceilingCheck : RayCast3D = $Raycasts/CeilingCheck
@onready var floorCheck : RayCast3D = $Raycasts/FloorCheck

func _ready():
	#set move variables, and value references
	moveSpeed = walkSpeed
	moveAccel = walkAccel
	moveDeccel = walkDeccel
	
	hitGroundCooldownRef = hitGroundCooldown
	jumpCooldownRef = jumpCooldown
	nbJumpsInAirAllowedRef = nbJumpsInAirAllowed
	coyoteJumpCooldownRef = coyoteJumpCooldown

	# Initialize health
	health = maxHealth
	wasOnFloor = is_on_floor()
	
func _process(_delta: float):
	displayProperties()
	
func _physics_process(_delta : float):
	modifyPhysicsProperties()
	
	move_and_slide()

	var onFloor : bool = is_on_floor()
	# detect the start of fall
	if wasOnFloor and not onFloor:
		fallStartY = position.y
	# detect landing
	if onFloor and not wasOnFloor:
		var fallDistance : float = fallStartY - position.y
		if fallDistance > fallDamageMinHeight:
			var fallSpeed : float = -lastFrameVelocity.y
			if fallSpeed > fallDamageThreshold:
				applyFallDamage((fallSpeed - fallDamageThreshold) * fallDamageMultiplier)
	wasOnFloor = onFloor

func displayProperties():
	#display properties on the hud
	if hud != null:
		hud.displayCurrentState(stateMachine.currStateName)
		hud.displayCurrentDirection(moveDirection)
		hud.displayDesiredMoveSpeed(desiredMoveSpeed)
		hud.displayVelocity(velocity.length())
		hud.displayNbJumpsInAirAllowed(nbJumpsInAirAllowed)
		
func modifyPhysicsProperties():
	lastFramePosition = position #get play char position every frame
	lastFrameVelocity = velocity #get play char velocity every frame
	
func gravityApply(delta : float):
	#if play char goes up, apply jump gravity
	#otherwise, apply fall gravity
	if !is_on_floor():
		if velocity.y >= 0.0: velocity.y += jumpGravity * delta
		elif velocity.y < 0.0: velocity.y += fallGravity * delta

# Health and death logic
func hitscanHit(damageVal : float, _hitscanDir : Vector3, _hitscanPos : Vector3) -> void:
	health -= damageVal
	print("Player hit! Health remaining: ", health)
	if health <= 0.0:
		get_tree().quit()

func projectileHit(damageVal : float, _hitscanDir : Vector3) -> void:
	health -= damageVal
	print("Player projectile hit! Health remaining: ", health)
	if health <= 0.0:
		get_tree().quit()

func applyFallDamage(damageVal : float) -> void:
	health -= damageVal
	print("Player took fall damage: ", damageVal, " (Health remaining: ", health, ")")
	if health <= 0.0:
		get_tree().quit()
		
		
		
		
		
		
		
		
		
		
	
