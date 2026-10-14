extends Node3D

signal inspect_requested(data: CardData)
const CARD_3D = preload("res://scripts/board_card_3d.gd")
const FACE_CACHE = preload("res://scripts/card_face_cache.gd")
const SURFACE_SHADER = preload("res://scripts/table_surface.gdshader")
const CARD_BACK = preload("res://assets/hud/card_back_3d.svg")
const FRONT_FIELD := Rect2(-5.9, 0.08, 12.8, 1.77)
const NEAR_FIELD := Rect2(-5.9, 1.85, 8.85, 2.35)
var camera: Camera3D
var face_cache: Node
var cards: Array[Node3D] = []
var piles: Dictionary = {}
var pile_labels: Dictionary = {}
var deck_visuals: Dictionary = {}
var grave_visuals: Dictionary = {}
var hint_material: StandardMaterial3D
var drop_hint: MeshInstance3D
var near_drop_hint: MeshInstance3D
var drop_enabled := false

func _ready() -> void:
	_build_environment()
	_build_table()
	face_cache = FACE_CACHE.new()
	add_child(face_cache)
	get_viewport().size_changed.connect(_fit_camera)
	_fit_camera()

func _material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.75
	return material

func _box(part_name: String, dimensions: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = part_name
	var shape := BoxMesh.new()
	shape.size = dimensions
	mesh.mesh = shape
	mesh.position = at
	mesh.material_override = material
	add_child(mesh)
	return mesh

func _plane(part_name: String, dimensions: Vector2, at: Vector3, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = part_name
	var plane := PlaneMesh.new()
	plane.size = dimensions
	mesh.mesh = plane
	mesh.position = at
	mesh.material_override = material
	add_child(mesh)
	return mesh

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.035, 0.05, 0.065)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.80, 0.90)
	environment.ambient_light_energy = 0.65
	world.environment = environment
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-58, -28, 0)
	light.light_color = Color(1.0, 0.90, 0.76)
	light.light_energy = 1.25
	light.shadow_enabled = true
	add_child(light)
	camera = Camera3D.new()
	camera.name = "CameraFixa"
	camera.current = true
	camera.fov = 38.0
	camera.near = 0.1
	camera.far = 80.0
	add_child(camera)

func _fit_camera() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var distance_factor := maxf(1.0, 1.55 / aspect)
	camera.position = Vector3(0, 13.0, 4.6) * distance_factor
	camera.look_at(Vector3(0, 0, -0.15), Vector3.UP)

func _build_table() -> void:
	var wood := ShaderMaterial.new()
	wood.shader = SURFACE_SHADER
	var rim := _material(Color(0.105, 0.065, 0.045))
	var brass := _material(Color(0.45, 0.33, 0.16), 0.55)
	_box("Estrutura", Vector3(15.0, 0.42, 9.6), Vector3(0, -0.24, 0), rim)
	_plane("Superficie", Vector2(14.6, 9.2), Vector3(0, -0.015, 0), wood)
	for x in [-7.25, 7.25]:
		_box("BordaLateral", Vector3(0.22, 0.14, 9.4), Vector3(x, 0.02, 0), brass)
	for z in [-4.6, 4.6]:
		_box("BordaFrontal", Vector3(14.5, 0.14, 0.22), Vector3(0, 0.02, z), brass)
	_plane("CampoJogador", Vector2(12.8, 4.2), Vector3(0.5, 0.006, 2.15), _material(Color(0.075, 0.12, 0.125)))
	_plane("CampoAdversario", Vector2(12.8, 4.2), Vector3(-0.5, 0.006, -2.15), _material(Color(0.115, 0.095, 0.12)))
	_box("Divisoria", Vector3(12.8, 0.012, 0.035), Vector3(0, 0.015, 0), brass)
	_build_pile("player_deck", Vector3(4.0, 0.04, 3.0), true, false)
	_build_pile("player_graveyard", Vector3(5.8, 0.04, 3.0), false, false)
	_build_pile("enemy_deck", Vector3(-4.0, 0.04, -3.0), true, true)
	_build_pile("enemy_graveyard", Vector3(-5.8, 0.04, -3.0), false, true)
	hint_material = _material(Color(0.18, 0.68, 0.40, 0.18))
	hint_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hint_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_hint = _plane("DestinoDaCarta", FRONT_FIELD.size, Vector3(FRONT_FIELD.get_center().x, 0.025, FRONT_FIELD.get_center().y), hint_material)
	near_drop_hint = _plane("DestinoProximoDaMao", NEAR_FIELD.size, Vector3(NEAR_FIELD.get_center().x, 0.025, NEAR_FIELD.get_center().y), hint_material)
	near_drop_hint.visible = false
	near_drop_hint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	drop_hint.visible = false
	drop_hint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _build_pile(key: String, at: Vector3, deck: bool, opposite: bool) -> void:
	piles[key] = at
	var brass := _material(Color(0.40, 0.31, 0.18), 0.4)
	_box(key + "Base", Vector3(1.55, 0.025, 2.10), Vector3(at.x, 0.015, at.z), brass)
	_box(key + "Fundo", Vector3(1.46, 0.025, 2.01), Vector3(at.x, 0.032, at.z), _material(Color(0.055, 0.065, 0.08)))
	if deck:
		var body := _box(key + "Pilha", Vector3(1.28, 0.20, 1.78), at + Vector3(0, 0.10, 0), _material(Color(0.50, 0.46, 0.38)))
		var material := StandardMaterial3D.new()
		material.albedo_texture = CARD_BACK
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var top := _plane(key + "Verso", Vector2(1.28, 1.78), body.position + Vector3(0, 0.105, 0), material)
		top.rotation.y = PI if opposite else 0.0
		deck_visuals[key] = [body, top]
	else:
		var material := StandardMaterial3D.new()
		material.albedo_texture = CARD_BACK
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var back := _plane(key + "Verso", Vector2(1.28, 1.78), at + Vector3(0, 0.015, 0), material)
		back.rotation.y = PI if opposite else 0.0
		grave_visuals[key] = back
		back.hide()
	var label := Label3D.new()
	label.name = key + "Contador"
	label.position = at + Vector3(0, 0.30, -0.85 if opposite else 0.85)
	if key == "enemy_graveyard":
		label.position.x += 0.25
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 36
	label.pixel_size = 0.007
	label.outline_size = 8
	label.modulate = Color(0.92, 0.86, 0.72)
	label.no_depth_test = false
	add_child(label)
	pile_labels[key] = label

func update_pile_counts(player_deck: int, player_graveyard: int, enemy_deck: int, enemy_graveyard: int) -> void:
	pile_labels.player_deck.text = "DECK · %d" % player_deck
	pile_labels.player_graveyard.text = "CEMITÉRIO · %d" % player_graveyard
	pile_labels.enemy_deck.text = "DECK · %d" % enemy_deck
	pile_labels.enemy_graveyard.text = "CEMITÉRIO · %d" % enemy_graveyard
	for mesh in deck_visuals.player_deck:
		mesh.visible = player_deck > 0
	for mesh in deck_visuals.enemy_deck:
		mesh.visible = enemy_deck > 0
	grave_visuals.player_graveyard.visible = player_graveyard > 0
	grave_visuals.enemy_graveyard.visible = enemy_graveyard > 0

func deck_screen_position(opponent: bool = false) -> Vector2:
	var at: Vector3 = piles.enemy_deck if opponent else piles.player_deck
	return camera.unproject_position(at + Vector3(0, 0.24, 0))

func deck_screen_width() -> float:
	var left := INF
	var right := -INF
	var at: Vector3 = piles.player_deck
	for x in [-0.64, 0.64]:
		for z in [-0.89, 0.89]:
			var point: Vector2 = camera.unproject_position(at + Vector3(x, 0.24, z))
			left = minf(left, point.x)
			right = maxf(right, point.x)
	return right - left

func ray_to_table(screen: Vector2, height: float = 0.06) -> Variant:
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	return Plane(Vector3.UP, height).intersects_ray(origin, direction)

func can_drop(screen: Vector2) -> bool:
	var point = ray_to_table(screen)
	if point == null:
		return false
	var at := Vector2(point.x, point.z)
	return FRONT_FIELD.has_point(at) or NEAR_FIELD.has_point(at)

func set_drop_hint(enabled: bool, valid: bool = false) -> void:
	drop_enabled = enabled
	drop_hint.visible = enabled
	near_drop_hint.visible = enabled
	hint_material.albedo_color = Color(0.14, 0.75, 0.38, 0.22) if valid else Color(0.8, 0.12, 0.13, 0.16)

func add_card(data: CardData, from_screen: Vector2, opposite: bool = false) -> Node3D:
	var card = CARD_3D.new()
	add_child(card)
	card.setup(data, face_cache.get_face(data), opposite)
	var start = ray_to_table(from_screen, 1.0)
	card.position = start if start != null else Vector3(0, 1.0, 1.8)
	cards.append(card)
	_arrange_cards()
	return card

func _arrange_cards() -> void:
	for opposite in [false, true]:
		var group: Array[Node3D] = []
		for card in cards:
			if card.opponent == opposite:
				group.append(card)
		var rows := 1 if group.size() <= 8 else 2
		var columns := maxi(1, ceili(float(group.size()) / rows))
		for i in range(group.size()):
			var row := i / columns
			var column := i % columns
			var row_count := mini(columns, group.size() - row * columns)
			var area: Rect2 = NEAR_FIELD if row == 1 else FRONT_FIELD
			var row_step := minf(1.40, (area.size.x - 0.2) / row_count)
			var row_scale := minf(1.0, row_step / 1.30)
			var x := area.get_center().x + (column - (row_count - 1) / 2.0) * row_step
			if opposite:
				x = -x
			var z := 2.85 if row == 1 else 0.95
			group[i].move_to(Vector3(x, 0.065 + i * 0.0003, -z if opposite else z), row_scale)

func inspect_at(screen: Vector2) -> bool:
	var card = pick_card(screen)
	if card != null:
		inspect_requested.emit(card.data)
		return true
	return false

func pick_card(screen: Vector2) -> Node3D:
	for i in range(cards.size() - 1, -1, -1):
		var card = cards[i]
		var point = ray_to_table(screen, card.to_global(Vector3(0, 0.022, 0)).y)
		if point != null and card.contains_point(point):
			return card
	return null

func card_for_unit(id: int) -> Node3D:
	for card in cards:
		if card.unit_id == id:
			return card
	return null

func animate_attack(attacker: Node3D, target: Vector3) -> void:
	if attacker.movement != null:
		attacker.movement.kill()
	var home := attacker.position
	var destination := home.lerp(target, 0.65) + Vector3(0, 0.22, 0)
	var motion := create_tween()
	motion.tween_property(attacker, "position", destination, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	motion.tween_property(attacker, "position", home, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await motion.finished

func graveyard_screen_position(opposite: bool) -> Vector2:
	var at: Vector3 = piles.enemy_graveyard if opposite else piles.player_graveyard
	return camera.unproject_position(at + Vector3(0, 0.10, 0))

func graveyard_screen_size(opposite: bool) -> Vector2:
	var at: Vector3 = piles.enemy_graveyard if opposite else piles.player_graveyard
	var bounds := Rect2(camera.unproject_position(at), Vector2.ZERO)
	for x in [-0.64, 0.64]:
		for z in [-0.89, 0.89]:
			bounds = bounds.expand(camera.unproject_position(at + Vector3(x, 0.10, z)))
	return bounds.size

func send_to_graveyard(card: Node3D, opposite: bool) -> void:
	cards.erase(card)
	card.set_combat_mark(Color.TRANSPARENT)
	if card.movement != null:
		card.movement.kill()
	if card.turning != null:
		card.turning.kill()
	var destination: Vector3 = piles.enemy_graveyard if opposite else piles.player_graveyard
	var start: Vector3 = card.position
	var start_scale: Vector3 = card.scale
	var start_rotation: float = card.rotation.y
	var flight := create_tween()
	flight.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	flight.tween_method(func(t: float):
		card.position = start.lerp(destination + Vector3(0, 0.10, 0), t) + Vector3(0, sin(t * PI) * 0.7, 0)
		card.scale = start_scale.lerp(Vector3.ONE, t)
		card.rotation.y = lerpf(start_rotation, PI if opposite else 0.0, t)
	, 0.0, 1.0, 0.65)
	await flight.finished
	card.show_back(CARD_BACK)
	await get_tree().create_timer(0.10).timeout
	card.hide()
	card.queue_free()
	_arrange_cards()
