class_name CombatScene
extends Control

## Top-level controller for a single combat encounter.
## Owns the turn loop: player turn → enemy turn → victory/defeat.


# Constants
const STRIKE = preload("res://data/cards/strike.tres")
const DEFEND = preload("res://data/cards/defend.tres")
const PUSH_5 = preload("res://data/cards/push_5.tres")
const NULL_POINTER = preload("res://data/enemies/null_pointer.tres")
const MAX_ENERGY := 3
const DRAW_COUNT := 5


# Enum
enum Phase { PLAYER_TURN, ENEMY_TURN, VICTORY, DEFEAT }


# Private variables
var _phase: Phase = Phase.PLAYER_TURN
var _draw_pile: Array[CardData] = []
var _hand_cards: Array[CardData] = []
var _discard_pile: Array[CardData] = []
var _energy: int = 0
var _block: int = 0
var _hp: int = 80
var _resolver: StackResolver


# @onready variables
@onready var _enemy: Enemy = $MainLayout/EnemyArea
@onready var _stack_zone: StackZone = $MainLayout/MiddleRow/StackZone
@onready var _hand_node: Hand = $MainLayout/Hand
@onready var _hp_label: Label = $MainLayout/MiddleRow/PlayerPanel/HPLabel
@onready var _block_label: Label = $MainLayout/MiddleRow/PlayerPanel/BlockLabel
@onready var _energy_label: Label = $MainLayout/MiddleRow/PlayerPanel/EnergyLabel
@onready var _draw_pile_label: Label = $MainLayout/MiddleRow/PilesPanel/DrawPileLabel
@onready var _discard_pile_label: Label = $MainLayout/MiddleRow/PilesPanel/DiscardPileLabel
@onready var _end_turn_button: Button = $MainLayout/EndTurnButton
@onready var _victory_overlay: Control = $VictoryOverlay
@onready var _defeat_overlay: Control = $DefeatOverlay
@onready var _defeat_seed_label: Label = $DefeatOverlay/SeedLabel


# Built-in virtuals
func _ready() -> void:
	GameManager.start_new_run()
	_resolver = StackResolver.new()
	_draw_pile = _build_starter_deck()
	RNG.shuffle(_draw_pile)
	_victory_overlay.visible = false
	_defeat_overlay.visible = false
	_stack_zone.execute_requested.connect(_on_execute_requested)
	_hand_node.card_play_requested.connect(_on_card_play_requested)
	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	_enemy.enemy_died.connect(_on_enemy_died)
	start_player_turn()


# Public methods
func start_player_turn() -> void:
	_phase = Phase.PLAYER_TURN
	_energy = MAX_ENERGY
	_block = 0
	_draw_cards(DRAW_COUNT)
	_update_hud()


# Private methods
func _build_starter_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	for _i in 5:
		deck.append(STRIKE)
	for _i in 3:
		deck.append(DEFEND)
	for _i in 2:
		deck.append(PUSH_5)
	return deck


func _draw_cards(count: int) -> void:
	var remaining := count
	while remaining > 0:
		if _draw_pile.is_empty():
			if _discard_pile.is_empty():
				break
			_draw_pile = _discard_pile.duplicate()
			_discard_pile.clear()
			RNG.shuffle(_draw_pile)
		_hand_cards.append(_draw_pile.pop_back())
		remaining -= 1
	_hand_node.clear()
	for data in _hand_cards:
		_hand_node.add_card(data)


func _update_hud() -> void:
	_hp_label.text = "HP: %d/80" % _hp
	_block_label.text = "Block: %d" % _block
	_energy_label.text = "Energy: %d/%d" % [_energy, MAX_ENERGY]
	_draw_pile_label.text = "Draw: %d" % _draw_pile.size()
	_discard_pile_label.text = "Discard: %d" % _discard_pile.size()


# Signal handlers
func _on_card_play_requested(card_data: CardData) -> void:
	if _phase != Phase.PLAYER_TURN:
		return
	if _energy < card_data.cost:
		return
	_energy -= card_data.cost
	_hand_cards.erase(card_data)
	_stack_zone.push_card(card_data)
	_hand_node.clear()
	for data in _hand_cards:
		_hand_node.add_card(data)
	_update_hud()


func _on_execute_requested(stack: Array[CardData]) -> void:
	if _phase != Phase.PLAYER_TURN:
		return
	var context: Dictionary = {
		"runtime_stack": [],
		"damage_accumulator": 0,
		"block_gain": 0,
		"draw_pile": _draw_pile,
		"hand": _hand_cards,
	}
	context = _resolver.resolve(stack, context)
	_enemy.take_damage(context.damage_accumulator)
	_block += context.block_gain
	for card in stack:
		_discard_pile.append(card)
	_update_hud()


func _on_end_turn_pressed() -> void:
	if _phase != Phase.PLAYER_TURN:
		return
	_phase = Phase.ENEMY_TURN
	for card in _hand_cards:
		_discard_pile.append(card)
	_hand_cards.clear()
	_hand_node.clear()
	var attack: int = _enemy.get_next_attack()
	var damage: int = max(0, attack - _block)
	_hp = max(0, _hp - damage)
	_enemy.advance_pattern()
	_update_hud()
	if _hp <= 0:
		_phase = Phase.DEFEAT
		_defeat_overlay.visible = true
		_defeat_seed_label.text = "Seed: %d" % GameManager.current_seed
		return
	start_player_turn()


func _on_enemy_died() -> void:
	_phase = Phase.VICTORY
	_victory_overlay.visible = true
