extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const CAR_SCRIPT = preload("res://scripts/car.gd")
const SAVE_PATH := "user://carwash_save.cfg"

var player: WashPlayer
var current_car: WashCar
var money := 250
var cleaner_level := 1
var wash_speed := 0.10
var spray_on := false
var foam_mode := false
var job_number := 1
var job_reward := 100
var game_paused := false
var spray_timer := 0.0
var water_stream: MeshInstance3D
var hud: CanvasLayer
var money_label: Label
var job_label: Label
var progress_bar: ProgressBar
var status_label: Label
var shop_panel: PanelContainer
var pause_panel: PanelContainer
var look_touch_id := -1
var look_last := Vector2.ZERO
var joystick_touch_id := -1
var joystick_origin := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var joy_visual: Control

func _ready() -> void:
    _load_game()
    _build_world()
    _spawn_player()
    _spawn_car()
    _build_hud()
    _refresh_hud()
    if OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_world() -> void:
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.sky.sky_material = ProceduralSkyMaterial.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.65, 0.72, 0.82)
    env.ambient_light_energy = 0.65
    env_node.environment = env
    add_child(env_node)

    _make_box("Floor", Vector3(18, 0.3, 24), Vector3(0, -0.15, 0), Color(0.23, 0.27, 0.29))
    _make_box("BackWall", Vector3(18, 5, 0.3), Vector3(0, 2.5, -10), Color(0.72, 0.75, 0.76))
    _make_box("LeftWall", Vector3(0.3, 5, 20), Vector3(-9, 2.5, 0), Color(0.58, 0.64, 0.67))
    _make_box("RightWall", Vector3(0.3, 5, 20), Vector3(9, 2.5, 0), Color(0.58, 0.64, 0.67))
    _make_box("FrontHeader", Vector3(18, 0.5, 0.35), Vector3(0, 4.7, 9.7), Color(0.1, 0.32, 0.42))
    _make_box("WashBayMark", Vector3(5.5, 0.025, 8), Vector3(0, 0.015, -0.2), Color(0.28, 0.34, 0.35))
    _make_box("Roof", Vector3(18, 0.25, 20), Vector3(0, 5.1, 0), Color(0.18, 0.22, 0.25))

    for x in [-6.0, -2.5, 2.5, 6.0]:
        _make_box("SupportPillar", Vector3(0.28, 4.8, 0.28), Vector3(x, 2.4, 7.5), Color(0.13, 0.28, 0.34))
    for z in [-6.5, 0.0, 6.0]:
        var light := OmniLight3D.new()
        light.position = Vector3(0, 4.5, z)
        light.light_color = Color(0.78, 0.9, 1.0)
        light.light_energy = 1.3
        light.omni_range = 10
        add_child(light)

    # A simple wash arch made from free procedural geometry.
    _make_box("ArchLeft", Vector3(0.25, 3.0, 0.25), Vector3(-2.7, 1.5, -0.3), Color(0.1, 0.52, 0.66))
    _make_box("ArchRight", Vector3(0.25, 3.0, 0.25), Vector3(2.7, 1.5, -0.3), Color(0.1, 0.52, 0.66))
    _make_box("ArchTop", Vector3(5.6, 0.25, 0.25), Vector3(0, 3.0, -0.3), Color(0.1, 0.52, 0.66))

    var sign := Label3D.new()
    sign.text = "MOONWASH  •  SELF SERVICE"
    sign.font_size = 48
    sign.position = Vector3(0, 4.25, 9.45)
    sign.pixel_size = 0.01
    sign.modulate = Color(0.45, 0.95, 1.0)
    add_child(sign)

func _make_box(label: String, size: Vector3, pos: Vector3, color: Color) -> void:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.78
    mesh_instance.material_override = mat
    mesh_instance.position = pos
    add_child(mesh_instance)
    if label in ["Floor", "BackWall", "LeftWall", "RightWall", "Roof", "SupportPillar", "FrontHeader", "ArchLeft", "ArchRight", "ArchTop"]:
        var static_body := StaticBody3D.new()
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        static_body.position = pos
        static_body.add_child(collision)
        add_child(static_body)

func _spawn_player() -> void:
    player = PLAYER_SCRIPT.new()
    player.position = Vector3(0, 0.1, 5.0)
    add_child(player)

func _spawn_car() -> void:
    if is_instance_valid(current_car):
        current_car.queue_free()
    current_car = CAR_SCRIPT.new()
    var colors: Array[Color] = [
        Color(0.12, 0.38, 0.82), Color(0.72, 0.12, 0.1),
        Color(0.12, 0.58, 0.32), Color(0.78, 0.65, 0.12),
        Color(0.62, 0.64, 0.68)
    ]
    var color := colors[(job_number - 1) % colors.size()]
    job_reward = 80 + ((job_number - 1) % 4) * 35
    current_car.setup(color, job_reward, "Customer Car #%d" % job_number, 18)
    current_car.position = Vector3(0, 0.0, -0.3)
    current_car.rotation.y = PI
    current_car.cleaned.connect(_on_car_cleaned)
    add_child(current_car)
    _refresh_hud()

func _build_hud() -> void:
    hud = CanvasLayer.new()
    hud.name = "HUD"
    add_child(hud)

    var top := PanelContainer.new()
    top.position = Vector2(16, 14)
    top.custom_minimum_size = Vector2(330, 105)
    hud.add_child(top)
    var top_box := VBoxContainer.new()
    top.add_child(top_box)
    money_label = Label.new()
    money_label.add_theme_font_size_override("font_size", 24)
    top_box.add_child(money_label)
    job_label = Label.new()
    job_label.add_theme_font_size_override("font_size", 18)
    top_box.add_child(job_label)
    progress_bar = ProgressBar.new()
    progress_bar.custom_minimum_size = Vector2(290, 22)
    progress_bar.max_value = 100
    top_box.add_child(progress_bar)
    status_label = Label.new()
    status_label.text = "WASD bewegen • Maus umsehen • E interagieren"
    status_label.position = Vector2(16, 130)
    status_label.add_theme_font_size_override("font_size", 16)
    hud.add_child(status_label)

    _make_button("SHOP / UPGRADES", Vector2(-190, -28), Vector2(170, 54), _open_shop, true)
    _make_button("PAUSE", Vector2(-95, 42), Vector2(150, 48), _toggle_pause, true)
    _make_button("SCHAUM", Vector2(-285, -105), Vector2(120, 56), _toggle_foam, true)
    _make_button("SPRÜHEN", Vector2(-145, -105), Vector2(120, 56), _toggle_spray, true)
    _make_button("INTERAGIEREN", Vector2(-145, -175), Vector2(160, 52), _interact, true)

    # Mobile joystick background; desktop users can continue using WASD.
    joy_visual = Control.new()
    joy_visual.position = Vector2(25, -195)
    joy_visual.size = Vector2(170, 170)
    joy_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(joy_visual)
    var ring := ColorRect.new()
    ring.position = Vector2(10, 10)
    ring.size = Vector2(150, 150)
    ring.color = Color(0.1, 0.2, 0.25, 0.38)
    ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joy_visual.add_child(ring)
    var center := ColorRect.new()
    center.name = "Knob"
    center.position = Vector2(55, 55)
    center.size = Vector2(60, 60)
    center.color = Color(0.35, 0.8, 0.9, 0.65)
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joy_visual.add_child(center)

    _create_shop_panel()
    _create_pause_panel()

func _make_button(text_value: String, offset: Vector2, size_value: Vector2, callback: Callable, right_side: bool) -> void:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = size_value
    button.size = size_value
    if right_side:
        button.anchor_left = 1.0
        button.anchor_right = 1.0
        button.anchor_top = 1.0
        button.anchor_bottom = 1.0
        button.position = offset
    else:
        button.position = offset
    button.add_theme_font_size_override("font_size", 16)
    button.pressed.connect(callback)
    hud.add_child(button)

func _create_shop_panel() -> void:
    shop_panel = PanelContainer.new()
    shop_panel.visible = false
    shop_panel.anchor_left = 0.5
    shop_panel.anchor_right = 0.5
    shop_panel.anchor_top = 0.5
    shop_panel.anchor_bottom = 0.5
    shop_panel.position = Vector2(-190, -150)
    shop_panel.custom_minimum_size = Vector2(380, 300)
    hud.add_child(shop_panel)
    var box := VBoxContainer.new()
    shop_panel.add_child(box)
    var title := Label.new()
    title.text = "WASCHSHOP"
    title.add_theme_font_size_override("font_size", 24)
    box.add_child(title)
    var info := Label.new()
    info.text = "Stufe 1: 100% Basisleistung\nStufe 2: schneller reinigen (300 $)\nStufe 3: Profi-Düse (650 $)"
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(info)
    var upgrade := Button.new()
    upgrade.text = "Reiniger verbessern"
    upgrade.pressed.connect(_buy_upgrade)
    box.add_child(upgrade)
    var close := Button.new()
    close.text = "Schließen"
    close.pressed.connect(func(): shop_panel.visible = false)
    box.add_child(close)

func _create_pause_panel() -> void:
    pause_panel = PanelContainer.new()
    pause_panel.visible = false
    pause_panel.anchor_left = 0.5
    pause_panel.anchor_right = 0.5
    pause_panel.anchor_top = 0.5
    pause_panel.anchor_bottom = 0.5
    pause_panel.position = Vector2(-150, -100)
    pause_panel.custom_minimum_size = Vector2(300, 200)
    hud.add_child(pause_panel)
    var box := VBoxContainer.new()
    pause_panel.add_child(box)
    var title := Label.new()
    title.text = "PAUSE"
    title.add_theme_font_size_override("font_size", 24)
    box.add_child(title)
    var resume := Button.new()
    resume.text = "Weiter spielen"
    resume.pressed.connect(_toggle_pause)
    box.add_child(resume)
    var save := Button.new()
    save.text = "Speichern"
    save.pressed.connect(func(): _save_game(); status_label.text = "Spielstand gespeichert.")
    box.add_child(save)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            var screen_size := get_viewport().get_visible_rect().size
            if event.position.x < screen_size.x * 0.42 and event.position.y > screen_size.y * 0.45:
                joystick_touch_id = event.index
                joystick_origin = event.position
                _update_joystick(event.position)
            elif event.position.x < screen_size.x * 0.78 and event.position.y < screen_size.y - 220:
                look_touch_id = event.index
                look_last = event.position
        else:
            if event.index == joystick_touch_id:
                joystick_touch_id = -1
                joystick_vector = Vector2.ZERO
                player.set_touch_move(Vector2.ZERO)
                _move_joystick_knob(Vector2.ZERO)
            if event.index == look_touch_id:
                look_touch_id = -1
    elif event is InputEventScreenDrag:
        if event.index == joystick_touch_id:
            _update_joystick(event.position)
        elif event.index == look_touch_id:
            player.add_look_delta(event.relative * 0.65)
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        # A mouse click can spray when the spray mode is enabled.
        pass

func _update_joystick(pos: Vector2) -> void:
    var delta := (pos - joystick_origin) / 65.0
    joystick_vector = Vector2(delta.x, delta.y).limit_length(1.0)
    player.set_touch_move(joystick_vector)
    _move_joystick_knob(joystick_vector)

func _move_joystick_knob(value: Vector2) -> void:
    if is_instance_valid(joy_visual):
        var knob := joy_visual.get_node_or_null("Knob") as Control
        if knob:
            knob.position = Vector2(55, 55) + value * 38.0

func _process(delta: float) -> void:
    if game_paused:
        return
    if spray_on or Input.is_action_pressed("spray"):
        spray_timer += delta
        if spray_timer >= 0.12:
            spray_timer = 0.0
            _spray_at_target()
    else:
        spray_timer = 0.0

func _spray_at_target() -> void:
    if not is_instance_valid(current_car) or current_car.is_clean:
        return
    var from := player.camera.global_position
    var to := from + (-player.camera.global_transform.basis.z * 7.0)
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [player.get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return
    var collider: Object = hit.get("collider")
    var car: WashCar = null
    if collider is StaticBody3D and collider.has_meta("wash_car"):
        car = collider.get_meta("wash_car") as WashCar
    elif collider.get_parent() is WashCar:
        car = collider.get_parent() as WashCar
    if car == current_car:
        var amount := wash_speed * (1.45 if foam_mode else 1.0)
        car.clean(amount)
        _refresh_hud()

func _toggle_spray() -> void:
    spray_on = not spray_on
    status_label.text = "Hochdruckreiniger: " + ("AN" if spray_on else "AUS") + " • auf das Auto zielen"

func _toggle_foam() -> void:
    foam_mode = not foam_mode
    status_label.text = "Schaum-Modus: " + ("AN" if foam_mode else "AUS")

func _interact() -> void:
    if not is_instance_valid(current_car):
        _spawn_car()
        return
    var distance := player.global_position.distance_to(current_car.global_position)
    if current_car.is_clean:
        status_label.text = "Auto fertig! Nächster Auftrag kommt gleich."
    elif distance > 8.0:
        status_label.text = "Geh näher an das Auto heran."
    else:
        spray_on = not spray_on
        status_label.text = "Reiniger " + ("aktiviert" if spray_on else "deaktiviert") + ". Ziele auf die Karosserie."

func _on_car_cleaned(car: WashCar) -> void:
    money += car.reward
    status_label.text = "Sauber! +$%d verdient. Nächster Kunde..." % car.reward
    _save_game()
    _refresh_hud()
    await get_tree().create_timer(2.0).timeout
    if is_instance_valid(car):
        car.queue_free()
    job_number += 1
    _spawn_car()

func _buy_upgrade() -> void:
    var cost := 300 if cleaner_level == 1 else 650
    if cleaner_level >= 3:
        status_label.text = "Du besitzt bereits die Profi-Düse."
    elif money < cost:
        status_label.text = "Nicht genug Geld! Benötigt: $%d" % cost
    else:
        money -= cost
        cleaner_level += 1
        wash_speed = 0.10 + (cleaner_level - 1) * 0.055
        status_label.text = "Upgrade gekauft! Reinigungsleistung verbessert."
        _save_game()
        _refresh_hud()

func _open_shop() -> void:
    shop_panel.visible = not shop_panel.visible
    if shop_panel.visible:
        pause_panel.visible = false

func _toggle_pause() -> void:
    game_paused = not game_paused
    pause_panel.visible = game_paused
    if game_paused:
        shop_panel.visible = false
    get_tree().paused = game_paused
    # Keep UI buttons active while paused.
    process_mode = Node.PROCESS_MODE_ALWAYS
    hud.process_mode = Node.PROCESS_MODE_ALWAYS

func _refresh_hud() -> void:
    if is_instance_valid(money_label):
        money_label.text = "Geld: $%d" % money
    if is_instance_valid(job_label):
        job_label.text = "Auftrag #%d  •  $%d" % [job_number, job_reward]
    if is_instance_valid(progress_bar):
        progress_bar.value = current_car.get_progress() * 100.0 if is_instance_valid(current_car) else 0.0

func _save_game() -> void:
    var config := ConfigFile.new()
    config.set_value("progress", "money", money)
    config.set_value("progress", "cleaner_level", cleaner_level)
    config.set_value("progress", "job_number", job_number)
    config.save(SAVE_PATH)

func _load_game() -> void:
    var config := ConfigFile.new()
    if config.load(SAVE_PATH) == OK:
        money = int(config.get_value("progress", "money", 250))
        cleaner_level = int(config.get_value("progress", "cleaner_level", 1))
        job_number = int(config.get_value("progress", "job_number", 1))
        wash_speed = 0.10 + (cleaner_level - 1) * 0.055
