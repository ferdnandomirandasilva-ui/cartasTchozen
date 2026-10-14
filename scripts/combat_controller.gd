extends Node

const BATTLE = preload("res://scripts/battle_state.gd")
const COMBAT_ARCS = preload("res://scripts/combat_arcs.gd")
const DAMAGE_CHOICE = preload("res://scripts/damage_choice.gd")
var arcs: Control
var state = BATTLE.new()
var game: Control
var selected := -1
var finished := false
var busy := false
var attack_button: Button
var cancel_button: Button
var message: Label

func setup(main: Control) -> void:
	game = main
	arcs = COMBAT_ARCS.new()
	game.add_child(arcs)
	arcs.setup(game)
	attack_button = _button("Atacar", 0.29)
	attack_button.pressed.connect(begin_player_attacks)
	cancel_button = _button("Cancelar ataques", 0.36)
	cancel_button.pressed.connect(cancel_player_attacks)
	message = Label.new()
	game.interface_layer.add_child(message)
	message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	message.anchor_left = 0.19
	message.anchor_right = 0.81
	message.anchor_top = 0.497
	message.anchor_bottom = 0.533
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 14)
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	refresh()

func _button(title: String, top: float) -> Button:
	var button := Button.new()
	game.interface_layer.add_child(button)
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.anchor_left = 0.84
	button.anchor_right = 0.98
	button.anchor_top = top
	button.anchor_bottom = top + 0.055
	button.text = title
	return button

func can_play_cards() -> bool:
	return not finished and not busy and state.phase == "main"

func register_card(data: CardData, owner: int, view: Node3D) -> void:
	view.unit_id = state.play_card(data, owner)
	refresh()

func start_turn(owner: int) -> void:
	state.start_turn(owner)
	selected = -1
	refresh()

func awaiting_player_defense() -> bool:
	return state.phase == "defense" and state.active_owner == 1 and not busy and not finished

func begin_player_attacks() -> void:
	if game.drawing or not PlayerState.can_player_act or finished or busy:
		return
	if state.begin_attacks():
		selected = -1
		message.text = "Marque as cartas que vão atacar e confirme. Clique novamente para desmarcar."
		refresh()

func cancel_player_attacks() -> void:
	if state.active_owner != 0 or busy:
		return
	state.cancel_attacks()
	selected = -1
	message.text = "Seleção de ataques cancelada."
	refresh()

func click_at(screen: Vector2) -> bool:
	if finished or busy or game.drawing:
		return false
	var view = game.board.pick_card(screen)
	if view == null or not state.units.has(view.unit_id):
		return false
	var id: int = view.unit_id
	var unit: Dictionary = state.units[id]
	if state.phase == "attack" and state.active_owner == 0:
		if unit.owner == 0:
			if not state.can_attack(id):
				message.text = "Esta carta está virada ou precisa aguardar seu próximo turno."
			else:
				var marked := false
				for order in state.attacks:
					marked = marked or order.attacker == id
				if marked:
					state.remove_attack(id)
					message.text = "Atacante desmarcada. Marque outras cartas ou confirme."
				else:
					state.declare_attack(id)
					message.text = "Atacante marcada. Marque outras cartas ou confirme."
		refresh()
		return true
	if awaiting_player_defense():
		if unit.owner == 0:
			if unit.used:
				message.text = "Cartas viradas não podem bloquear."
			if state.can_defend(id):
				if selected == id:
					state.remove_blocker(id)
					selected = -1
				else:
					selected = id
					message.text = "Clique na atacante que esta carta vai bloquear."
		elif state.assign_blocker(id, selected):
			selected = -1
			message.text = "Defesa marcada. Escolha outra defensora ou confirme."
		refresh()
		return true
	return false

func confirm_player_attacks() -> void:
	if state.active_owner != 0 or state.phase != "attack" or busy or game.drawing:
		return
	state.confirm_attacks()
	busy = true
	game._set_drawing(true)
	message.text = "O adversário está escolhendo as defesas…"
	refresh()
	await get_tree().create_timer(0.6).timeout
	_choose_enemy_defenses()
	refresh()
	await get_tree().create_timer(0.5).timeout
	await resolve_combat()

func begin_enemy_combat() -> bool:
	state.begin_attacks()
	for unit in state.units.values():
		if not state.can_attack(unit.id):
			continue
		state.declare_attack(unit.id)
	state.confirm_attacks()
	if state.attacks.is_empty():
		state.resolve()
		refresh()
		return false
	selected = -1
	game._set_drawing(false)
	message.text = "Escolha uma defensora e a atacante a bloquear; depois confirme as defesas."
	refresh()
	return true

func _choose_enemy_defenses() -> void:
	var orders: Array[Dictionary] = state.attacks.duplicate()
	orders.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return state.units[a.attacker].data.attack > state.units[b.attacker].data.attack)
	for order in orders:
		var attack: int = state.units[order.attacker].data.attack
		var chosen := -1
		var best := -100000
		for candidate in state.units.values():
			if not state.can_defend(candidate.id) or state.assigned_defenders().has(candidate.id):
				continue
			var value: int = candidate.data.attack + candidate.data.health
			var survives: bool = candidate.data.health - candidate.damage > attack
			var score := (10000 if survives else 0) - value
			if score > best:
				best = score
				chosen = candidate.id
		if chosen != -1:
			state.assign_blocker(order.attacker, chosen)
	# Add a group block when the available defenders can defeat the attacker.
	for order in orders:
		var group: Array = state.blockers.get(order.attacker, [])
		if group.is_empty():
			continue
		var power := 0
		for id in group:
			power += maxi(0, state.units[id].data.attack)
		var needed: int = state.units[order.attacker].data.health - state.units[order.attacker].damage
		var available: Array = []
		var extra := 0
		for candidate in state.units.values():
			if state.can_defend(candidate.id) and not state.assigned_defenders().has(candidate.id) and candidate.data.attack > 0:
				available.append(candidate)
				extra += candidate.data.attack
		if power < needed and power + extra >= needed:
			available.sort_custom(func(a, b): return a.data.attack > b.data.attack)
			for candidate in available:
				state.assign_blocker(order.attacker, candidate.id)
				power += candidate.data.attack
				if power >= needed:
					break

func resolve_combat() -> void:
	if state.phase != "defense" or finished:
		return
	busy = true
	selected = -1
	game._set_drawing(true)
	if state.active_owner == 0:
		var choice = DAMAGE_CHOICE.new()
		game.add_child(choice)
		await choice.choose(state)
		choice.queue_free()
	var snapshot: Dictionary = state.units.duplicate()
	var results: Array[Dictionary] = state.resolve()
	var defeated: Dictionary = {}
	refresh()
	for result in results:
		var attacker = game.board.card_for_unit(result.attacker)
		var target = game.board.card_for_unit(result.target)
		var at: Vector3 = Vector3(-6.8, 0.15, -1.5 if result.owner == 0 else 1.5)
		if target != null:
			at = target.position
		if attacker != null:
			await game.board.animate_attack(attacker, at)
		if result.damage > 0:
			if result.owner == 0:
				PlayerState.opponent_life -= result.damage
			else:
				PlayerState.current_life -= result.damage
			message.text = "Ataque direto: %d de dano ao jogador." % result.damage
		elif result.defeated:
			message.text = "Dano simultâneo: criaturas com dano igual ou maior que a resistência vão ao cemitério."
		else:
			message.text = "Dano marcado nas criaturas até o fim do turno."
		for id in result.defeated_ids:
			defeated[id] = snapshot[id]
	for id in defeated:
		var unit: Dictionary = defeated[id]
		var view = game.board.card_for_unit(id)
		if view != null:
			arcs.remove_card(view)
			await game.board.send_to_graveyard(view, unit.owner == 1)
		var deck = game.enemy if unit.owner == 1 else game.player
		var field = game.enemy_field_cards if unit.owner == 1 else game.field_cards
		field.erase(unit.data)
		deck.graveyard.append(unit.data)
		game._update_piles()
	state.attacks.clear()
	state.blockers.clear()
	busy = false
	if PlayerState.current_life <= 0 or PlayerState.opponent_life <= 0:
		finished = true
		message.text = "Você venceu!" if PlayerState.opponent_life <= 0 else "Você perdeu."
	game._set_drawing(false)
	refresh()

func use_spell(data: CardData, owner: int) -> void:
	message.text = "%s: efeito ainda não implementado; será enviado ao cemitério." % data.card_name
	var hand: Control = game.enemy_hand if owner == 1 else game.hand
	await game.spell_preview.present(data, game.card_zoom, hand.get_global_rect().get_center(), game.board, owner == 1)
	var deck = game.enemy if owner == 1 else game.player
	deck.graveyard.append(data)
	game._update_piles()
	message.text = "%s no cemitério · efeito ainda não implementado." % data.card_name

func refresh() -> void:
	if not is_instance_valid(game):
		return
	arcs.set_orders(state.attacks, state.blockers, state.active_owner)
	var local_turn := PlayerState.can_player_act
	attack_button.visible = local_turn and state.phase == "main" and not state.combat_done and not finished
	var ready := false
	for id in state.units:
		ready = ready or state.can_attack(id)
	attack_button.disabled = game.drawing or busy or not ready
	cancel_button.visible = local_turn and state.phase == "attack" and not finished
	cancel_button.disabled = busy
	game.end_turn_button.text = "Confirmar defesas" if awaiting_player_defense() else ("Confirmar ataques" if state.phase == "attack" and local_turn else "Finalizar turno")
	game.end_turn_button.disabled = finished or busy or game.drawing or (not local_turn and not awaiting_player_defense())
	for card in game.hand_cards:
		card.can_drag = local_turn and not game.drawing and can_play_cards()
	for view in game.board.cards:
		if not state.units.has(view.unit_id):
			continue
		var unit: Dictionary = state.units[view.unit_id]
		var color := Color.TRANSPARENT
		var label := ""
		view.set_tapped(unit.used)
		if unit.used:
			label = "Virada"
		elif unit.entered >= state.turns[unit.owner]:
			label = "Aguarda turno"
		for i in range(state.attacks.size()):
			var order: Dictionary = state.attacks[i]
			if order.attacker == unit.id:
				color = Color(1.0, 0.16, 0.20, 0.65)
				label = "Ataque %d" % (i + 1)
			if state.blockers.get(order.attacker, []).has(unit.id):
				color = Color(0.08, 0.48, 0.98, 0.65)
				label = "Defesa %d" % (i + 1)
		if selected == unit.id:
			if color.a == 0.0:
				color = Color(0.08, 0.48, 0.98, 0.65) if state.phase == "defense" else Color(1.0, 0.16, 0.20, 0.65)
			label = "Selecionada" if label.is_empty() else "Selecionada · " + label
		if unit.damage > 0:
			label += " · %d/%d dano" % [unit.damage, unit.data.health]
		view.set_combat_mark(color, label)
