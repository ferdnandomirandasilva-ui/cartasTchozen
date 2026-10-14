extends Control
const CARD_SCENE = preload("res://scenes/card.tscn")
const DECK_STATE = preload("res://scripts/deck_state.gd")
const CARD_ZOOM = preload("res://scripts/card_zoom.gd")
const SPELL_PREVIEW = preload("res://scripts/spell_preview.gd")
const PORTRAIT_STATUS = preload("res://scripts/portrait_counters.gd")
const BOARD_3D = preload("res://scripts/board_3d.gd")
const OPPONENT_POLICY = preload("res://scripts/opponent_policy.gd")
const COMBAT_CONTROLLER = preload("res://scripts/combat_controller.gd")
var combat: Node
var board: Node3D
var player_hud: Control
var opponent_hud: Control
var card_zoom: Control
var spell_preview: Control
var player = DECK_STATE.new()
var enemy = DECK_STATE.new()
var hand_cards: Array[Card] = []
var enemy_cards: Array[Card] = []
var drawing := false
var hovered_card: Card
var field_cards: Array[CardData] = []
var enemy_field_cards: Array[CardData] = []
var hand: Control
var enemy_hand: Control
var drag_layer: Control
var turn_label: Label
var end_turn_button: Button
var table_layer: Control
var portrait_layer: Control
var hands_layer: Control
var interface_layer: Control

func _ready() -> void:
	_build_table()
	combat = COMBAT_CONTROLLER.new()
	add_child(combat)
	combat.setup(self)
	PlayerState.mana_changed.connect(_update_mana_display)
	PlayerState.life_changed.connect(_update_life_display)
	PlayerState.opponent_resources_changed.connect(_update_opponent_display)
	PlayerState.turn_changed.connect(_update_turn_display)
	player.setup(CardDatabase.all_cards, 0)
	enemy.setup(CardDatabase.all_cards, 0)
	resized.connect(_arrange_cards)
	_update_mana_display(PlayerState.current_mana, PlayerState.max_mana)
	_update_life_display(PlayerState.current_life, PlayerState.max_life)
	_update_turn_display(PlayerState.current_turn)
	_update_piles()
	call_deferred("_deal_starting_hands")

func _area(title: String, rect: Rect2) -> Control:
	var panel := Panel.new()
	table_layer.add_child(panel)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.anchor_left = rect.position.x
	panel.anchor_top = rect.position.y
	panel.anchor_right = rect.end.x
	panel.anchor_bottom = rect.end.y
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	panel.add_child(label)
	label.text = title
	label.position = Vector2(8, 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel

func _pile(rect: Rect2) -> Label:
	var area := _area("", rect)
	var label := Label.new()
	area.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _depth_layer(layer_name: String, depth: int) -> Control:
	var layer := Control.new()
	layer.name = layer_name
	add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = depth
	return layer

func _build_player_status() -> void:
	player_hud = _build_portrait_hud("StatusJogador", false)
	opponent_hud = _build_portrait_hud("StatusOponente", true)
	player_hud.set_life(PlayerState.current_life, PlayerState.max_life, false)
	player_hud.set_mana(PlayerState.current_mana, PlayerState.max_mana, false)
	opponent_hud.set_life(PlayerState.opponent_life, PlayerState.opponent_max_life, false)
	opponent_hud.set_mana(PlayerState.opponent_mana, PlayerState.opponent_max_mana, false)

func _build_portrait_hud(panel_name: String, opposite: bool) -> Control:
	var hud = PORTRAIT_STATUS.new()
	hud.name = panel_name
	portrait_layer.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	hud.anchor_top = 0.35 if opposite else 0.65
	hud.anchor_bottom = hud.anchor_top
	hud.offset_left = 12
	hud.offset_right = 194
	hud.offset_top = -70
	hud.offset_bottom = 70
	var portrait: Texture2D = null
	if opposite:
		portrait = load("res://assets/portraits/opponent_avatar.png")
	else:
		portrait = load("res://assets/portraits/player_avatar.png")
	hud.setup(portrait, opposite)
	return hud
func _build_table() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	board = BOARD_3D.new()
	board.name = "Mesa3D"
	add_child(board)
	table_layer = _depth_layer("Mesa", 0)
	portrait_layer = _depth_layer("RetratoERecursos", 50)
	hands_layer = _depth_layer("Maos", 100)
	interface_layer = _depth_layer("Interface", 250)
	enemy_hand = _area("", Rect2(0.18, 0.02, 0.64, 0.14))
	hand = _area("", Rect2(0.18, 0.76, 0.64, 0.23))
	hand.reparent(hands_layer)
	enemy_hand.reparent(hands_layer)
	hand.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	enemy_hand.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_build_player_status()
	turn_label = _pile(Rect2(0.005, 0.48, 0.145, 0.04))
	end_turn_button = Button.new()
	turn_label.get_parent().reparent(interface_layer)
	interface_layer.add_child(end_turn_button)
	end_turn_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_turn_button.anchor_left = 0.84
	end_turn_button.anchor_top = 0.20
	end_turn_button.anchor_right = 0.98
	end_turn_button.anchor_bottom = 0.28
	end_turn_button.text = "Finalizar turno"
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	drag_layer = Control.new()
	drag_layer.name = "CartasEmMovimento"
	drag_layer.z_index = 300
	add_child(drag_layer)
	drag_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drag_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_zoom = CARD_ZOOM.new()
	card_zoom.z_index = 1000
	add_child(card_zoom)
	board.inspect_requested.connect(card_zoom.open_data)
	spell_preview = SPELL_PREVIEW.new()
	spell_preview.z_index = 500
	add_child(spell_preview)

func _add_card_to_hand(data: CardData) -> Card:
	var card: Card = CARD_SCENE.instantiate()
	hand.add_child(card)
	card.setup(data)
	card.drag_started.connect(_on_card_drag_started)
	card.drag_ended.connect(_on_card_drag_ended)
	card.inspect_requested.connect(card_zoom.open_card)
	hand_cards.append(card)
	return card

func _arrange_hand(cards: Array[Card], area: Control, opponent: bool = false) -> void:
	var count := cards.size()
	if count == 0:
		return
	# Preserve the original arc and 0.2-second animation, fitted to this area.
	var spread := minf(42.0, 7.0 * (count - 1))
	# Fit against a full hand so drawing cards never changes their size.
	var half_angle := deg_to_rad(42.0 / 2.0)
	var reference_height := 468.0 * cos(half_angle) + 336.0 * sin(half_angle) + 1500.0 * (1.0 - cos(half_angle))
	var reference_width := 3000.0 * sin(half_angle) + 336.0 * cos(half_angle) + 468.0 * sin(half_angle)
	var base_factor := maxf(0.05, minf(0.56, minf((hand.size.y - 40.0) / reference_height * 1.12, (hand.size.x - 24.0) / reference_width)))
	# Foreground cards are larger while the fan keeps its horizontal footprint.
	var factor := maxf(base_factor * 2.1, board.deck_screen_width() * 1.2 / 336.0)
	var radius := 1500.0 * base_factor
	# Place the fan at the screen edge, with its lower portion out of view.
	var center_y := hand.size.y - 468.0 * factor * 0.2 - 28.0
	# Keep the former visible height while larger cards extend beyond the edge.
	center_y += 468.0 * (factor - base_factor * 1.45) * 0.7
	if opponent:
		center_y = size.y - (hand.position.y + center_y) - area.position.y
	for i in range(count):
		var card := cards[i]
		if card.dragging:
			continue
		if card.placement_tween != null:
			card.placement_tween.kill()
		card.pivot_offset = card.size / 2.0
		var t := 0.0 if count == 1 else float(i) / float(count - 1) - 0.5
		var angle := t * spread
		var radians := deg_to_rad(angle)
		var direction := -1.0 if opponent else 1.0
		var center := Vector2(area.size.x / 2.0 + sin(radians) * radius * direction, center_y + (1.0 - cos(radians)) * radius * direction)
		card.hand_position = center - card.size / 2.0
		card.hand_rotation = angle + 180.0 if opponent else angle
		card.hand_scale = Vector2.ONE * factor
		card.hand_order = count - 1 - i if opponent else i
		card.hover_direction = 1.0 if opponent else -1.0
		card.animate_hand_pose(0.2)
	_restore_hand_order()

func _restore_hand_order() -> void:
	# Stable left-to-right array order: the rightmost card is drawn on top.
	for card in hand_cards:
		if card.get_parent() == hand:
			hand.move_child(card, hand.get_child_count() - 1)
	for i in range(enemy_cards.size() - 1, -1, -1):
		enemy_hand.move_child(enemy_cards[i], enemy_hand.get_child_count() - 1)
	if is_instance_valid(hovered_card):
		var area: Control = hovered_card.get_parent()
		if area == hand or area == enemy_hand:
			area.move_child(hovered_card, area.get_child_count() - 1)

func _process(_delta: float) -> void:
	var selected: Card = null
	var blocked: bool = drawing or card_zoom.visible or not combat.can_play_cards()
	var dragged: Card = null
	for card in hand_cards:
		if card.dragging:
			blocked = true
			dragged = card
	var valid_drop: bool = dragged != null and PlayerState.can_player_act and combat.can_play_cards() and board.can_drop(get_global_mouse_position())
	if dragged != null:
		valid_drop = valid_drop and PlayerState.current_mana >= dragged.data.cost
	board.set_drop_hint(dragged != null, valid_drop)
	if not blocked:
		# Hit-test the original fan, so raising one card does not reshuffle selection.
		var candidates: Array[Card] = hand_cards.duplicate()
		candidates.reverse()
		for card in candidates:
			var area: Control = card.get_parent()
			if not card.visible or area != hand:
				continue
			var pointer := area.get_local_mouse_position()
			var pose := Transform2D(deg_to_rad(card.hand_rotation), card.hand_scale, 0.0, card.hand_position + card.pivot_offset)
			if Rect2(-card.pivot_offset, card.size).has_point(pose.affine_inverse() * pointer):
				selected = card
				break
		if selected == null and is_instance_valid(hovered_card):
			if Rect2(Vector2.ZERO, hovered_card.size).has_point(hovered_card.get_local_mouse_position()):
				selected = hovered_card
	if selected == hovered_card:
		return
	if is_instance_valid(hovered_card):
		hovered_card.hand_hovered = false
		if (hovered_card.get_parent() == hand or hovered_card.get_parent() == enemy_hand) and not hovered_card.dragging:
			hovered_card.animate_hand_pose()
		else:
			hovered_card.z_index = 200 if hovered_card.dragging else 0
	hovered_card = selected
	if is_instance_valid(hovered_card):
		hovered_card.hand_hovered = true
		hovered_card.animate_hand_pose()
	_restore_hand_order()

func set_opponent_selected_card(index: int) -> void:
	# Reserved for actions from the opponent; never driven by the local mouse.
	for i in range(enemy_cards.size()):
		var card := enemy_cards[i]
		card.hand_hovered = i == index
		card.animate_hand_pose()
	_restore_hand_order()

func _arrange_cards() -> void:
	_arrange_hand(hand_cards, hand)
	_arrange_hand(enemy_cards, enemy_hand, true)

func _set_drawing(value: bool) -> void:
	drawing = value
	for card in hand_cards:
		card.can_drag = not value
	_update_turn_display(PlayerState.current_turn)
	if combat != null:
		combat.refresh()

func _deal_starting_hands() -> void:
	_set_drawing(true)
	for i in range(DECK_STATE.HAND_LIMIT):
		await _draw_animated(player, false, 1)
		await _draw_animated(enemy, true, 1)
	_set_drawing(false)

func _draw_animated(state: RefCounted, opponent: bool, amount: int) -> void:
	for i in range(amount):
		var drawn: Array[CardData] = state.draw(1)
		if drawn.is_empty():
			break
		var destination: Card
		if opponent:
			destination = CARD_SCENE.instantiate()
			enemy_hand.add_child(destination)
			destination.set_face_down(true)
			destination.can_drag = false
			destination.inspect_requested.connect(card_zoom.open_card)
			enemy_cards.append(destination)
		else:
			destination = _add_card_to_hand(drawn[0])
			destination.can_drag = false
		destination.hide()
		_update_piles()
		_arrange_cards()
		# Let the fan make room before the travelling card reaches its slot.
		await get_tree().create_timer(0.21).timeout
		var flight: Card = CARD_SCENE.instantiate()
		drag_layer.add_child(flight)
		flight.z_index = 200
		flight.can_drag = false
		flight.set_face_down(true)
		if not opponent:
			flight.setup(drawn[0])
		flight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flight.pivot_offset = flight.size / 2.0
		var inverse := drag_layer.get_global_transform().affine_inverse()
		var source_center: Vector2 = inverse * board.deck_screen_position(opponent)
		var target_center := inverse * (destination.get_global_transform() * (destination.size / 2.0))
		flight.position = source_center - flight.size / 2.0
		flight.scale = destination.scale
		flight.rotation_degrees = 180.0 if opponent else 0.0
		var travel := create_tween().set_parallel(true)
		travel.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		travel.tween_property(flight, "position", target_center - flight.size / 2.0, 0.45)
		travel.tween_property(flight, "rotation_degrees", destination.rotation_degrees, 0.45)
		await travel.finished
		if not opponent:
			var flip := create_tween()
			flip.tween_property(flight, "scale:x", 0.0, 0.09)
			flip.tween_callback(flight.set_face_down.bind(false))
			flip.tween_property(flight, "scale:x", destination.scale.x, 0.09)
			await flip.finished
		flight.free()
		destination.show()
		_arrange_cards()

func _on_card_drag_started(card: Card) -> void:
	var global_pos := card.global_position
	card.reparent(drag_layer)
	card.z_index = 200
	card.global_position = global_pos

func _on_card_drag_ended(card: Card, drop_position: Vector2) -> void:
	var cost := maxi(0, card.data.cost) if card.data else 0
	if PlayerState.can_player_act and not drawing and combat.can_play_cards() and board.can_drop(drop_position) and PlayerState.current_mana >= cost:
		var data: CardData = card.data
		PlayerState.current_mana -= cost
		player.hand.erase(data)
		hand_cards.erase(card)
		card.hide()
		card.queue_free()
		if data.is_spell():
			_set_drawing(true)
			_arrange_cards()
			await combat.use_spell(data, 0)
			_set_drawing(false)
		else:
			field_cards.append(data)
			var view = board.add_card(data, drop_position)
			combat.register_card(data, 0, view)
	else:
		card.reparent(hand)
	_arrange_cards()
	_update_piles()

func _update_piles() -> void:
	board.update_pile_counts(player.deck.size(), player.graveyard.size(), enemy.deck.size(), enemy.graveyard.size())

func _unhandled_input(event: InputEvent) -> void:
	if drawing or card_zoom.visible:
		return
	for card in hand_cards:
		if card.dragging:
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if board.inspect_at(event.position):
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if combat.click_at(event.position):
			get_viewport().set_input_as_handled()

func _update_mana_display(current: int, maximum: int) -> void:
	player_hud.set_mana(current, maximum)

func _update_life_display(current: int, maximum: int) -> void:
	player_hud.set_life(current, maximum)

func _update_opponent_display() -> void:
	opponent_hud.set_life(PlayerState.opponent_life, PlayerState.opponent_max_life)
	opponent_hud.set_mana(PlayerState.opponent_mana, PlayerState.opponent_max_mana)

func _update_turn_display(owner: PlayerState.TurnOwner) -> void:
	var active := owner == PlayerState.TurnOwner.PLAYER
	turn_label.text = "Seu turno" if active else "Turno do oponente"
	end_turn_button.disabled = not active or drawing
	if combat != null:
		combat.refresh()

func _on_end_turn_pressed() -> void:
	if combat.finished or combat.busy or drawing:
		return
	if combat.awaiting_player_defense():
		if combat.selected != -1:
			combat.message.text = "Associe a defensora à atacante ou clique nela para cancelar a seleção."
			return
		await combat.resolve_combat()
		if not combat.finished:
			await start_player_turn()
		return
	if combat.state.phase == "attack" and PlayerState.can_player_act:
		await combat.confirm_player_attacks()
		return
	if not PlayerState.can_player_act or drawing:
		return
	PlayerState.set_turn(PlayerState.TurnOwner.ENEMY)
	combat.start_turn(1)
	PlayerState.start_mana_turn(PlayerState.TurnOwner.ENEMY)
	_set_drawing(true)
	await _draw_animated(enemy, true, 2)
	await _play_opponent_turn()
	if not combat.begin_enemy_combat():
		await start_player_turn()

func _play_opponent_turn() -> void:
	await get_tree().create_timer(0.6).timeout
	while PlayerState.current_turn == PlayerState.TurnOwner.ENEMY:
		var index: int = OPPONENT_POLICY.choose_card(enemy.hand, PlayerState.opponent_mana)
		if index < 0:
			break
		set_opponent_selected_card(index)
		await get_tree().create_timer(0.4).timeout
		await _play_opponent_card(index)
		await get_tree().create_timer(0.35).timeout
	set_opponent_selected_card(-1)

func _play_opponent_card(index: int) -> void:
	if PlayerState.current_turn != PlayerState.TurnOwner.ENEMY or index < 0 or index >= enemy.hand.size() or index >= enemy_cards.size():
		return
	var data: CardData = enemy.hand[index]
	var cost := maxi(0, data.cost)
	if cost > PlayerState.opponent_mana:
		return
	var card := enemy_cards[index]
	if card.placement_tween != null:
		card.placement_tween.kill()
	card.hand_hovered = false
	enemy.hand.remove_at(index)
	enemy_cards.remove_at(index)
	PlayerState.opponent_mana -= cost
	if data.is_spell():
		card.hide()
		card.queue_free()
		_arrange_cards()
		await combat.use_spell(data, 1)
		return
	card.reparent(drag_layer)
	card.z_index = 200
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrange_cards()
	var inverse := drag_layer.get_global_transform().affine_inverse()
	var target: Vector2 = board.camera.unproject_position(Vector3(0, 0.06, -1.72))
	var local_target: Vector2 = inverse * target
	var travel := create_tween().set_parallel(true)
	travel.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	travel.tween_property(card, "position", local_target - card.size / 2.0, 0.55)
	travel.tween_property(card, "rotation_degrees", 180.0, 0.55)
	await travel.finished
	# Keep the travelling card anonymous; reveal data only on the public field.
	card.hide()
	card.queue_free()
	enemy_field_cards.append(data)
	var view = board.add_card(data, target, true)
	combat.register_card(data, 1, view)
	_update_piles()

func start_player_turn() -> void:
	if combat.finished:
		return
	PlayerState.complete_round()
	combat.start_turn(0)
	PlayerState.start_mana_turn(PlayerState.TurnOwner.PLAYER)
	PlayerState.set_turn(PlayerState.TurnOwner.PLAYER)
	_set_drawing(true)
	await _draw_animated(player, false, 2)
	_set_drawing(false)
	_update_piles()
	_arrange_cards()
