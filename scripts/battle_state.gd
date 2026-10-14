extends RefCounted
var units: Dictionary = {}
var next_id := 1
var turns: Array[int] = [1, 0]
var active_owner := 0
var phase := "main"
var combat_done := false
var attacks: Array[Dictionary] = []
var blockers: Dictionary = {}
var damage_assignments: Dictionary = {}

func play_card(data: CardData, owner: int) -> int:
	if data.is_spell():
		return -1
	var id := next_id
	next_id += 1
	units[id] = {"id": id, "data": data, "owner": owner, "entered": turns[owner], "used": false, "damage": 0}
	return id

func end_turn() -> void:
	for unit in units.values():
		unit.damage = 0

func start_turn(owner: int) -> void:
	end_turn()
	active_owner = owner
	turns[owner] += 1
	phase = "main"
	combat_done = false
	attacks.clear()
	blockers.clear()
	damage_assignments.clear()
	for unit in units.values():
		if unit.owner == owner:
			unit.used = false

func can_attack(id: int) -> bool:
	if not units.has(id):
		return false
	var unit: Dictionary = units[id]
	return unit.owner == active_owner and not unit.used and unit.entered < turns[unit.owner]

func begin_attacks() -> bool:
	if phase != "main" or combat_done:
		return false
	phase = "attack"
	attacks.clear()
	blockers.clear()
	damage_assignments.clear()
	return true

func cancel_attacks() -> void:
	if phase == "attack":
		attacks.clear()
		phase = "main"

func declare_attack(attacker: int) -> bool:
	if phase != "attack" or not can_attack(attacker):
		return false
	remove_attack(attacker)
	attacks.append({"attacker": attacker, "target": -1})
	return true

func remove_attack(attacker: int) -> void:
	if phase != "attack":
		return
	for i in range(attacks.size() - 1, -1, -1):
		if attacks[i].attacker == attacker:
			attacks.remove_at(i)

func confirm_attacks() -> bool:
	if phase != "attack":
		return false
	for order in attacks:
		units[order.attacker].used = true
	phase = "defense"
	return true

func can_defend(id: int) -> bool:
	return phase == "defense" and units.has(id) and units[id].owner != active_owner and not units[id].used

func assigned_defenders() -> Array:
	var assigned: Array = []
	for group in blockers.values():
		assigned.append_array(group)
	return assigned

func assign_blocker(attacker: int, defender: int) -> bool:
	if not can_defend(defender):
		return false
	var declared := false
	for order in attacks:
		declared = declared or order.attacker == attacker
	if not declared:
		return false
	remove_blocker(defender)
	if not blockers.has(attacker):
		blockers[attacker] = []
	blockers[attacker].append(defender)
	return true

func remove_blocker(defender: int) -> void:
	if phase != "defense":
		return
	for key in blockers.keys():
		blockers[key].erase(defender)
		if blockers[key].is_empty():
			blockers.erase(key)
	damage_assignments.clear()

func default_assignment(attacker: int) -> Dictionary:
	var assignment: Dictionary = {}
	var remaining: int = maxi(0, units[attacker].data.attack)
	var group: Array = blockers.get(attacker, [])
	for id in group:
		var lethal: int = maxi(0, units[id].data.health - units[id].damage)
		var amount := mini(remaining, lethal)
		assignment[id] = amount
		remaining -= amount
	if not group.is_empty():
		assignment[group[-1]] += remaining
	return assignment

func set_damage_assignment(attacker: int, assignment: Dictionary) -> bool:
	if phase != "defense" or not units.has(attacker):
		return false
	var group: Array = blockers.get(attacker, [])
	var total := 0
	if assignment.size() != group.size():
		return false
	for id in group:
		if not assignment.has(id) or int(assignment[id]) < 0:
			return false
		total += int(assignment[id])
	if total != maxi(0, units[attacker].data.attack):
		return false
	damage_assignments[attacker] = assignment.duplicate()
	return true

func resolve() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if phase != "defense":
		return results
	# All damage is marked before casualties are removed.
	for order in attacks:
		if not units.has(order.attacker):
			continue
		var attacker: Dictionary = units[order.attacker]
		var group: Array = blockers.get(order.attacker, [])
		var result := {"attacker": order.attacker, "target": -1 if group.is_empty() else group[0], "owner": active_owner, "damage": 0, "defeated": false, "defeated_ids": []}
		if group.is_empty():
			result.damage = maxi(0, attacker.data.attack)
		else:
			var assignment: Dictionary = damage_assignments.get(order.attacker, default_assignment(order.attacker))
			for id in group:
				units[id].damage += int(assignment.get(id, 0))
				attacker.damage += maxi(0, units[id].data.attack)
		results.append(result)
	var defeated: Array = []
	for id in units:
		if units[id].damage >= units[id].data.health:
			defeated.append(id)
	for result in results:
		var group: Array = blockers.get(result.attacker, []).duplicate()
		group.append(result.attacker)
		for id in group:
			if defeated.has(id):
				result.defeated_ids.append(id)
		result.defeated = not result.defeated_ids.is_empty()
	for id in defeated:
		units.erase(id)
	combat_done = true
	phase = "main"
	return results
