extends Control

const DEFENSE_COLOR := Color(0.16, 0.55, 1.0, 0.55)
var game: Control
var connections: Array[Dictionary] = []

func setup(main: Control) -> void:
	game = main
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 150

func set_orders(attacks: Array[Dictionary], blockers: Dictionary, _owner: int) -> void:
	connections.clear()
	for i in range(attacks.size()):
		var order: Dictionary = attacks[i]
		var attacker = game.board.card_for_unit(order.attacker)
		if blockers.has(order.attacker):
			for j in range(blockers[order.attacker].size()):
				var defender = game.board.card_for_unit(blockers[order.attacker][j])
				connections.append({"from": defender, "to": attacker, "color": DEFENSE_COLOR, "bend": -1.15 - i * 0.12 - j * 0.2})
	queue_redraw()

func _process(_delta: float) -> void:
	if not connections.is_empty():
		queue_redraw()

func remove_card(card: Node3D) -> void:
	for i in range(connections.size() - 1, -1, -1):
		if connections[i].from == card or connections[i].to == card:
			connections.remove_at(i)
	queue_redraw()

func _screen_point(node: Node) -> Variant:
	if not is_instance_valid(node) or node.is_queued_for_deletion():
		return null
	if node is Node3D:
		if not node.visible or game.board.camera.is_position_behind(node.global_position):
			return null
		return game.board.camera.unproject_position(node.global_position)
	if node is Control and node.visible:
		# Aim at the portrait itself, rather than its adjacent counters.
		return node.get_global_transform() * Vector2(55, 70)
	return null

func _draw() -> void:
	if not is_instance_valid(game):
		return
	var inverse := get_global_transform().affine_inverse()
	for link in connections:
		if not is_instance_valid(link.from) or not is_instance_valid(link.to):
			continue
		var from = _screen_point(link.from)
		var to = _screen_point(link.to)
		if from == null or to == null:
			continue
		var start: Vector2 = inverse * from
		var finish: Vector2 = inverse * to
		var delta := finish - start
		if delta.length() < 48.0:
			continue
		var perpendicular := delta.normalized().orthogonal()
		var control := (start + finish) * 0.5 + perpendicular * clampf(delta.length() * 0.25, 38.0, 130.0) * float(link.bend)
		start += (control - start).normalized() * 28.0
		finish -= (finish - control).normalized() * 32.0
		var points := PackedVector2Array()
		for step in range(49):
			var t := float(step) / 48.0
			points.append(start.lerp(control, t).lerp(control.lerp(finish, t), t))
		draw_polyline(points, Color(0.015, 0.02, 0.03, 0.2), 7.0, true)
		draw_polyline(points, link.color, 3.5, true)
		var direction := (points[-1] - points[-3]).normalized()
		var side := direction.orthogonal()
		var arrow := PackedVector2Array([finish, finish - direction * 16.0 + side * 7.0, finish - direction * 16.0 - side * 7.0])
		draw_colored_polygon(arrow, link.color)
