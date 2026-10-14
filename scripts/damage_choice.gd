extends Control

signal confirmed

func choose(state: RefCounted) -> void:
	var orders: Array = []
	for order in state.attacks:
		if state.blockers.get(order.attacker, []).size() > 1:
			orders.append(order)
	if orders.is_empty():
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 700
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.6)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -260
	panel.offset_right = 260
	panel.offset_top = -260
	panel.offset_bottom = 260
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = "Distribuir dano entre bloqueadores"
	column.add_child(title)
	var scroll := ScrollContainer.new()
	column.add_child(scroll)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rows := VBoxContainer.new()
	scroll.add_child(rows)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inputs: Dictionary = {}
	for order in orders:
		var attacker: int = order.attacker
		var heading := Label.new()
		heading.text = "%s · distribua %d de dano" % [state.units[attacker].data.card_name, maxi(0, state.units[attacker].data.attack)]
		rows.add_child(heading)
		inputs[attacker] = {}
		var defaults: Dictionary = state.default_assignment(attacker)
		for id in state.blockers[attacker]:
			var row := HBoxContainer.new()
			rows.add_child(row)
			var label := Label.new()
			label.text = "%s (#%d) · resistência %d" % [state.units[id].data.card_name, id, state.units[id].data.health]
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
			var amount := SpinBox.new()
			row.add_child(amount)
			amount.min_value = 0
			amount.max_value = maxi(0, state.units[attacker].data.attack)
			amount.step = 1
			amount.value = defaults[id]
			inputs[attacker][id] = amount
	var error := Label.new()
	error.text = "A soma precisa ser igual ao poder de cada atacante."
	error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(error)
	var button := Button.new()
	button.text = "Confirmar dano"
	column.add_child(button)
	button.pressed.connect(func():
		var assignments: Dictionary = {}
		for attacker in inputs:
			var assignment: Dictionary = {}
			var total := 0
			for id in inputs[attacker]:
				assignment[id] = int(inputs[attacker][id].value)
				total += assignment[id]
			if total != maxi(0, state.units[attacker].data.attack):
				error.text = "Corrija a soma do dano de " + state.units[attacker].data.card_name
				return
			assignments[attacker] = assignment
		for attacker in assignments:
			state.set_damage_assignment(attacker, assignments[attacker])
		confirmed.emit()
	)
	await confirmed
	hide()
