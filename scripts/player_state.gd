extends Node

const LIFE_LIMIT := 20
const MANA_LIMIT := 9
const STARTING_MANA := 3
var round_number := 1

enum TurnOwner {
	PLAYER,
	ENEMY
}

signal mana_changed(current: int, max_mana: int)
signal life_changed(current: int, maximum: int)
signal opponent_resources_changed()
var opponent_max_life: int = LIFE_LIMIT:
	set(value):
		opponent_max_life = clampi(value, 0, LIFE_LIMIT)
		opponent_life = mini(opponent_life, opponent_max_life)
		opponent_resources_changed.emit()
var opponent_life: int = LIFE_LIMIT:
	set(value):
		opponent_life = clampi(value, 0, opponent_max_life)
		opponent_resources_changed.emit()
var opponent_max_mana: int = STARTING_MANA:
	set(value):
		opponent_max_mana = clampi(value, 0, MANA_LIMIT)
		opponent_mana = mini(opponent_mana, opponent_max_mana)
		opponent_resources_changed.emit()
var opponent_mana: int = STARTING_MANA:
	set(value):
		opponent_mana = clampi(value, 0, opponent_max_mana)
		opponent_resources_changed.emit()

var max_life: int = LIFE_LIMIT:
	set(value):
		max_life = clampi(value, 0, LIFE_LIMIT)
		current_life = mini(current_life, max_life)
		life_changed.emit(current_life, max_life)
var current_life: int = LIFE_LIMIT:
	set(value):
		current_life = clampi(value, 0, max_life)
		life_changed.emit(current_life, max_life)
signal turn_changed(owner: TurnOwner)

@export var max_mana: int = STARTING_MANA:
	set(value):
		max_mana = clampi(value, 0, MANA_LIMIT)
		current_mana = min(current_mana, max_mana)
		mana_changed.emit(current_mana, max_mana)

var current_mana: int = STARTING_MANA:
	set(value):
		current_mana = clamp(value, 0, max_mana)
		mana_changed.emit(current_mana, max_mana)

var current_turn: TurnOwner = TurnOwner.PLAYER:
	set(value):
		current_turn = value
		turn_changed.emit(current_turn)

var can_player_act: bool:
	get:
		return current_turn == TurnOwner.PLAYER

func _ready() -> void:
	current_mana = max_mana

func reset_mana() -> void:
	current_mana = max_mana

func start_mana_turn(owner: TurnOwner) -> void:
	if owner == TurnOwner.PLAYER:
		reset_mana()
	else:
		opponent_mana = opponent_max_mana

func complete_round() -> void:
	round_number += 1
	max_mana += 1
	opponent_max_mana += 1
	reset_mana()
	opponent_mana = opponent_max_mana

func set_turn(new_turn: TurnOwner) -> void:
	current_turn = new_turn
