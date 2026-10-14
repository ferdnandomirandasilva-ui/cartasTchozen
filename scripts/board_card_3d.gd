extends Node3D

const WIDTH := 1.25
const HEIGHT := 1.741
const COMBAT_GLOW = preload("res://scripts/card_combat_glow.gdshader")
var glow: MeshInstance3D
var glow_material: ShaderMaterial
var data: CardData
var opponent := false
var movement: Tween
var unit_id := -1
var face_material: StandardMaterial3D
var status_label: Label3D
var tapped := false
var turning: Tween

func setup(card_data: CardData, texture: Texture2D, other_side: bool = false) -> void:
	data = card_data
	opponent = other_side
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(WIDTH, 0.035, HEIGHT)
	body.mesh = box
	var edge := StandardMaterial3D.new()
	edge.albedo_color = Color(0.19, 0.16, 0.12)
	edge.roughness = 0.8
	body.material_override = edge
	add_child(body)
	var face := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(WIDTH, HEIGHT)
	face.mesh = quad
	face.rotation.x = -PI / 2.0
	face.position.y = 0.022
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.2
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	face.material_override = material
	face_material = material
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(face)
	glow = MeshInstance3D.new()
	var glow_quad := QuadMesh.new()
	glow_quad.size = Vector2(WIDTH + 0.22, HEIGHT + 0.22)
	glow.mesh = glow_quad
	glow.rotation.x = -PI / 2.0
	glow.position.y = 0.028
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glow_material = ShaderMaterial.new()
	glow_material.shader = COMBAT_GLOW
	glow.material_override = glow_material
	add_child(glow)
	glow.hide()
	rotation.y = PI if opponent else 0.0
	status_label = Label3D.new()
	status_label.position = Vector3(0, 0.10, HEIGHT / 2.0 + 0.12)
	status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	status_label.font_size = 26
	status_label.pixel_size = 0.005
	status_label.outline_size = 6
	add_child(status_label)

func set_combat_mark(color: Color, status: String = "") -> void:
	status_label.text = status
	status_label.modulate = color if color.a > 0.0 else Color.WHITE
	glow.visible = color.a > 0.0
	if glow.visible:
		glow_material.set_shader_parameter("mark_color", color)

func set_tapped(value: bool) -> void:
	if tapped == value:
		return
	tapped = value
	if turning != null:
		turning.kill()
	turning = create_tween()
	turning.tween_property(self, "rotation:y", (PI if opponent else 0.0) + (PI / 2.0 if tapped else 0.0), 0.2)

func show_back(texture: Texture2D) -> void:
	face_material.albedo_texture = texture
	set_combat_mark(Color.TRANSPARENT)

func move_to(target: Vector3, target_scale: float = 1.0, duration: float = 0.25) -> void:
	if movement != null:
		movement.kill()
	movement = create_tween().set_parallel(true)
	movement.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	movement.tween_property(self, "position", target, duration)
	movement.tween_property(self, "scale", Vector3.ONE * target_scale, duration)

func contains_point(world: Vector3) -> bool:
	var point := to_local(world)
	return absf(point.x) <= WIDTH / 2.0 and absf(point.z) <= HEIGHT / 2.0
