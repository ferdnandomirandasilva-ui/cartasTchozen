extends Control

const CARD_SCENE = preload("res://scenes/card.tscn")
const DISPLAY_SECONDS := 3.0
var preview: Card
var zoom: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_fit_preview)
	hide()

func present(data: CardData, traditional_zoom: Control, source: Vector2, board: Node3D, opposite: bool) -> void:
	zoom = traditional_zoom
	preview = CARD_SCENE.instantiate()
	add_child(preview)
	preview.setup(data)
	preview.can_drag = false
	preview.pivot_offset = preview.size / 2.0
	preview.set_details_visible(true)
	preview.inspect_requested.connect(zoom.open_card)
	show()
	_fit_preview()
	var destination := preview.position
	preview.position = get_global_transform().affine_inverse() * source - preview.size / 2.0
	preview.rotation_degrees = -360.0
	preview.modulate.a = 0.0
	var entrance := create_tween().set_parallel(true)
	entrance.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrance.tween_property(preview, "position", destination, 0.55)
	entrance.tween_property(preview, "rotation_degrees", 0.0, 0.55)
	entrance.tween_property(preview, "modulate:a", 1.0, 0.2)
	await entrance.finished
	_fit_preview()
	var elapsed := 0.0
	while elapsed < DISPLAY_SECONDS:
		await get_tree().process_frame
		if not zoom.visible:
			elapsed += get_process_delta_time()
	# Stop accepting inspection once the spell leaves its display.
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.set_details_visible(false)
	var start := preview.position + preview.size / 2.0
	var start_scale := preview.scale
	var flight := create_tween()
	flight.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	flight.tween_method(func(t: float):
		var inverse := get_global_transform().affine_inverse()
		var target: Vector2 = inverse * board.graveyard_screen_position(opposite)
		var center := start.lerp(target, t) + Vector2(0, -sin(t * PI) * size.y * 0.08)
		preview.position = center - preview.size / 2.0
		var pile_size: Vector2 = board.graveyard_screen_size(opposite)
		preview.scale = start_scale.lerp(pile_size / preview.size, t)
		preview.rotation_degrees = 180.0 * t if opposite else 0.0
		var flip := clampf((t - 0.55) / 0.3, 0.0, 1.0)
		preview.scale.x *= absf(cos(flip * PI))
		if flip >= 0.5 and not preview.face_down:
			preview.set_face_down(true)
			preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	, 0.0, 1.0, 0.65)
	await flight.finished
	preview.free()
	preview = null
	hide()

func _fit_preview() -> void:
	if not is_instance_valid(preview):
		return
	var factor := minf(0.75, minf(size.x * 0.19 / 336.0, size.y * 0.46 / 468.0))
	preview.scale = Vector2.ONE * factor
	preview.position = Vector2(size.x * 0.76, size.y * 0.56) - preview.size / 2.0
