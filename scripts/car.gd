extends Node3D
class_name WashCar

signal cleaned(car: WashCar)

var paint_color: Color = Color(0.15, 0.42, 0.85)
var reward: int = 100
var dirt_level: float = 1.0
var dirt_spots: Array[MeshInstance3D] = []
var car_label := "Compact"
var is_clean := false
var body: StaticBody3D

func setup(color: Color, cash_reward: int, label: String, dirt_amount: int = 18) -> void:
    paint_color = color
    reward = cash_reward
    car_label = label
    _build_car(dirt_amount)

func _build_car(dirt_amount: int) -> void:
    var paint := StandardMaterial3D.new()
    paint.albedo_color = paint_color
    paint.metallic = 0.25
    paint.roughness = 0.32

    var glass := StandardMaterial3D.new()
    glass.albedo_color = Color(0.08, 0.16, 0.20)
    glass.metallic = 0.15
    glass.roughness = 0.18

    var rubber := StandardMaterial3D.new()
    rubber.albedo_color = Color(0.025, 0.03, 0.035)
    rubber.roughness = 0.9

    _box("LowerBody", Vector3(2.0, 0.62, 4.1), Vector3(0, 0.72, 0), paint)
    _box("Cabin", Vector3(1.48, 0.65, 1.85), Vector3(0, 1.32, -0.25), paint)
    _box("FrontWindow", Vector3(1.32, 0.42, 0.06), Vector3(0, 1.43, 0.72), glass)
    _box("RearWindow", Vector3(1.28, 0.4, 0.06), Vector3(0, 1.43, -1.18), glass)

    for x in [-1.02, 1.02]:
        for z in [-1.35, 1.35]:
            var wheel := MeshInstance3D.new()
            wheel.name = "Wheel"
            var mesh := CylinderMesh.new()
            mesh.top_radius = 0.34
            mesh.bottom_radius = 0.34
            mesh.height = 0.2
            wheel.mesh = mesh
            wheel.material_override = rubber
            wheel.position = Vector3(x, 0.38, z)
            wheel.rotation.z = PI / 2
            add_child(wheel)

    body = StaticBody3D.new()
    body.name = "CarCollider"
    var shape_node := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2.05, 1.5, 4.15)
    shape_node.shape = shape
    shape_node.position = Vector3(0, 0.85, 0)
    body.add_child(shape_node)
    body.set_meta("wash_car", self)
    add_child(body)

    var dirt_mat := StandardMaterial3D.new()
    dirt_mat.albedo_color = Color(0.20, 0.13, 0.075)
    dirt_mat.roughness = 1.0
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    for i in range(dirt_amount):
        var spot := MeshInstance3D.new()
        var sphere := SphereMesh.new()
        var radius := rng.randf_range(0.07, 0.15)
        sphere.radius = radius
        sphere.height = radius * 2.0
        spot.mesh = sphere
        spot.material_override = dirt_mat
        var side := -1.0 if i % 2 == 0 else 1.0
        var z := rng.randf_range(-1.8, 1.8)
        var y := rng.randf_range(0.48, 1.05)
        spot.position = Vector3(side * 1.01, y, z)
        spot.scale = Vector3(0.35, 1.0, 1.25)
        add_child(spot)
        dirt_spots.append(spot)

func _box(node_name: String, size: Vector3, pos: Vector3, mat: Material) -> void:
    var instance := MeshInstance3D.new()
    instance.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = size
    instance.mesh = mesh
    instance.material_override = mat
    instance.position = pos
    add_child(instance)

func clean(amount: float) -> bool:
    if is_clean:
        return true
    var remove_count := maxi(1, int(ceil(amount * dirt_spots.size())))
    for i in range(remove_count):
        if dirt_spots.is_empty():
            break
        var spot: MeshInstance3D = dirt_spots.pop_back()
        spot.queue_free()
    dirt_level = float(dirt_spots.size()) / 18.0
    if dirt_spots.is_empty():
        is_clean = true
        cleaned.emit(self)
    return is_clean

func get_progress() -> float:
    if dirt_spots.is_empty():
        return 1.0
    return clamp(1.0 - float(dirt_spots.size()) / 18.0, 0.0, 1.0)
