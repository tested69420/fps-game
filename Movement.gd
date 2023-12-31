extends CharacterBody3D


const WALK_SPEED = 4.0
const SPRINT_SPEED = 7.0
const JUMP_VELOCITY = 6
const SENSITIVITY = 0.008

var speed = WALK_SPEED

#head bobbing shit
const FREQ = 2
const AMP = 0.1
var btick = 0 
var xrot = 0
var MouseX = 0

#fov shit
const BASE_FOV = 80.0
const FOV_CHANGE = 1.5


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $head
@onready var camera = $head/camera
	
var locked = true

func _ready(): 
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(event):
	
	if Input.is_action_just_released("pause"):
		locked = !locked
		if locked:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if locked == false:
					locked = true
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90),deg_to_rad(90))
		xrot = camera.rotation.x
		MouseX = -event.relative.x

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (head.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x,direction.x * speed,delta * 10)
			velocity.z = lerp(velocity.z,direction.z * speed,delta * 10)
	else:
		velocity.x = lerp(velocity.x,direction.x * speed,delta * 2)
		velocity.z = lerp(velocity.z,direction.z * speed,delta * 2)
		
	#sine wave update
	btick += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(btick)
	
	var velocity_clamped = clamp(velocity.length(),0.5,SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov,target_fov, delta * 8.0)
		
	
	
	move_and_slide()
	
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * FREQ) * AMP
	pos.x = cos(time * FREQ / 2) * AMP
	return pos
