extends CharacterBody3D
class_name WashPlayer

@export var walk_speed: float = 5.0
@export var mouse_sensitivity: float = 0.0022
@export var gravity: float = 18.0

var touch_move: Vector2 = Vector2.ZERO
var look_delta: Vector2 = Vector2.ZERO
var touch_look_enabled := false
var spray_enabled := false
var camera: Camera3D
var pitch := 0.0

func _ready() -> void:
    name = "Player"
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.34
    capsule.height = 1.7
    collision.shape = capsule
    collision.position.y = 0.85
    add_child(collision)

    camera = Camera3D.new()
    camera.name = "Camera3D"
    camera.position = Vector3(0, 1.55, 0)
    camera.current = true
    add_child(camera)

    if not OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        pitch = clamp(pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-78), deg_to_rad(78))
        camera.rotation.x = pitch
    elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        else:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func add_look_delta(delta: Vector2) -> void:
    rotate_y(-delta.x * mouse_sensitivity)
    pitch = clamp(pitch - delta.y * mouse_sensitivity, deg_to_rad(-78), deg_to_rad(78))
    camera.rotation.x = pitch

func set_touch_move(value: Vector2) -> void:
    touch_move = value.limit_length(1.0)

func _physics_process(delta: float) -> void:
    var input_dir := Vector2.ZERO
    input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    input_dir.y = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
    input_dir += touch_move
    input_dir = input_dir.limit_length(1.0)

    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    if direction.length() > 0.01:
        velocity.x = direction.x * walk_speed
        velocity.z = direction.z * walk_speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, walk_speed * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, walk_speed * 5.0 * delta)

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0
    move_and_slide()
