class_name CombatScene
extends Control

## Top-level controller for a single combat encounter.
## Owns the turn loop: player turn → enemy turn → victory/defeat.
## Reads run state from GameManager; writes back player HP, gold, enemies defeated.


# Constants
const FLOATING_NUMBER = preload("res://scenes/ui/floating_number.tscn")
const CARD_BURST = preload("res://scenes/ui/card_burst.tscn")
const NULL_POINTER_FALLBACK := preload("res://data/enemies/null_pointer.tres")
const MAX_ENERGY := 3
const DRAW_COUNT := 5
const GOLD_PER_FIGHT := 25
const _POPUP_POOL_SIZE := 8
const _BURST_POOL_SIZE := 6


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
var _player_statuses: Array[StatusEffect] = []
var _popup_pool: Array[FloatingNumber] = []
var _burst_pool: Array[CardBurst] = []


# @onready variables
@onready var _enemy: Enemy = $MainLayout/EnemyArea
@onready var _stack_zone: StackZone = $MainLayout/MiddleRow/StackZone
@onready var _hand_node: Hand = $MainLayout/Hand
@onready var _hp_label: Label = $MainLayout/MiddleRow/PlayerPanel/HPLabel
@onready var _player_hp_bar: ProgressBar = $MainLayout/MiddleRow/PlayerPanel/HPBar
@onready var _block_label: Label = $MainLayout/MiddleRow/PlayerPanel/BlockLabel
@onready var _energy_label: Label = $MainLayout/MiddleRow/PlayerPanel/EnergyLabel
@onready var _player_status_label: Label = $MainLayout/MiddleRow/PlayerPanel/PlayerStatusLabel
@onready var _draw_pile_label: Label = $MainLayout/MiddleRow/PilesPanel/DrawPileLabel
@onready var _discard_pile_label: Label = $MainLayout/MiddleRow/PilesPanel/DiscardPileLabel
@onready var _end_turn_button: Button = $MainLayout/EndTurnButton
@onready var _victory_overlay: Control = $VictoryOverlay
@onready var _victory_gold_label: Label = $VictoryOverlay/VictoryGold
@onready var _vic_continue_button: Button = $VictoryOverlay/VicContinueButton
@onready var _defeat_overlay: Control = $DefeatOverlay
@onready var _defeat_seed_label: Label = $DefeatOverlay/SeedLabel
@onready var _def_continue_button: Button = $DefeatOverlay/DefContinueButton
@onready var _flee_button: Button = $FleeButton


# Built-in virtuals
func _ready() -> void:
	_hp = GameManager.player_hp
	_player_hp_bar.max_value = GameManager.player_max_hp
	_resolver = StackResolver.new()

	var enemy_data: EnemyData = GameManager.current_enemy_data
	if enemy_data == null:
		enemy_data = NULL_POINTER_FALLBACK
	_enemy.setup(enemy_data)

	if GameManager.deck.is_empty():
		# Fallback: start a fresh run if somehow we got here without one
		GameManager.start_new_run()
	_draw_pile = GameManager.deck.duplicate()
	RNG.shuffle(_draw_pile)

	_victory_overlay.visible = false
	_defeat_overlay.visible = false
	_stack_zone.execute_requested.connect(_on_execute_requested)
	_stack_zone.clear_requested.connect(_on_clear_requested)
	_hand_node.card_play_requested.connect(_on_card_play_requested)
	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	_enemy.enemy_died.connect(_on_enemy_died)
	_vic_continue_button.pressed.connect(_on_vic_continue_pressed)
	_def_continue_button.pressed.connect(_on_def_continue_pressed)
	_flee_button.pressed.connect(_on_flee_pressed)
	_init_pools()
	AudioManager.play_bgm()
	start_player_turn()


# Public methods
func start_player_turn() -> void:
	_phase = Phase.PLAYER_TURN
	_energy = MAX_ENERGY
	_block = 0
	_draw_cards(DRAW_COUNT)
	_update_hud()


# Private methods
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
		_hand_node.add_card(data, true)


func _update_hud() -> void:
	_hp_label.text = "HP: %d/%d" % [_hp, GameManager.player_max_hp]
	TweenPresets.standard_tween(self).tween_property(_player_hp_bar, "value", float(_hp), TweenPresets.SLOW_DURATION)
	_block_label.text = "Block: %d" % _block
	_energy_label.text = "Energy: %d/%d" % [_energy, MAX_ENERGY]
	_draw_pile_label.text = "Draw: %d" % _draw_pile.size()
	_discard_pile_label.text = "Discard: %d" % _discard_pile.size()
	_update_player_status_display()


func _update_player_status_display() -> void:
	if _player_statuses.is_empty():
		_player_status_label.text = ""
		return
	var parts: Array[String] = []
	for s in _player_statuses:
		parts.append("%s(%d)" % [s.get_status_name(), s.stacks])
	_player_status_label.text = " ".join(parts)


func _animate_block_pop() -> void:
	_block_label.scale = Vector2(1.3, 1.3)
	TweenPresets.standard_tween(_block_label).tween_property(_block_label, "scale", Vector2(1.0, 1.0), TweenPresets.SNAP_DURATION)


func _init_pools() -> void:
	for _i in _POPUP_POOL_SIZE:
		var p: FloatingNumber = FLOATING_NUMBER.instantiate()
		add_child(p)
		p.visible = false
		p.popup_finished.connect(_on_popup_finished)
		_popup_pool.append(p)
	for _i in _BURST_POOL_SIZE:
		var b: CardBurst = CARD_BURST.instantiate()
		add_child(b)
		b.visible = false
		b.burst_finished.connect(_on_burst_finished)
		_burst_pool.append(b)


func _on_popup_finished(popup: FloatingNumber) -> void:
	_popup_pool.append(popup)


func _on_burst_finished(burst: CardBurst) -> void:
	_burst_pool.append(burst)


func _spawn_number(value_text: String, global_pos: Vector2, color: Color) -> void:
	var popup: FloatingNumber
	if not _popup_pool.is_empty():
		popup = _popup_pool.pop_back()
	else:
		popup = FLOATING_NUMBER.instantiate()
		add_child(popup)
		popup.popup_finished.connect(_on_popup_finished)
	popup.show_popup(value_text, global_pos, color)


func _shake_screen(intensity: float, duration: float) -> void:
	var shake_rng := RandomNumberGenerator.new()
	shake_rng.randomize()
	var start_pos := Vector2.ZERO
	var elapsed := 0.0
	while elapsed < duration:
		var shake := Vector2(
			shake_rng.randf_range(-intensity, intensity),
			shake_rng.randf_range(-intensity, intensity)
		)
		position = start_pos + shake
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	position = start_pos


func _get_burst_color(card_type: CardData.CardType) -> Color:
	match card_type:
		CardData.CardType.OPERATION:
			return Color(0.3, 0.6, 1.0)
		CardData.CardType.VALUE:
			return Color(0.4, 1.0, 0.4)
		CardData.CardType.EFFECT:
			return Color(1.0, 0.4, 0.3)
		CardData.CardType.FLOW:
			return Color(1.0, 0.9, 0.3)
		_:
			return Color.WHITE


func _animate_card_launch(view: Control, card: CardData) -> void:
	var start_gpos := view.global_position
	var card_scale := _stack_zone.CARD_SCALE
	var enemy_center := _enemy.get_global_rect().get_center()

	# Phase 1: Card rises and glows (0.22s)
	var t1 := view.create_tween().set_parallel(true)
	t1.tween_property(view, "scale", card_scale * 1.4, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t1.tween_property(view, "global_position", start_gpos + Vector2(0.0, -62.0), 0.22)
	t1.tween_property(view, "modulate", Color(1.6, 1.5, 0.5, 1.0), 0.22)
	await t1.finished

	# Flash white, spawn burst at card location
	view.modulate = Color(2.5, 2.5, 2.5, 1.0)
	_spawn_burst(view.get_global_rect().get_center(), card.card_type)

	# Phase 2: Fly toward enemy, shrink, fade (0.30s)
	var t2 := view.create_tween().set_parallel(true)
	t2.tween_property(view, "global_position", enemy_center, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t2.tween_property(view, "scale", card_scale * 0.1, 0.30).set_ease(Tween.EASE_IN)
	t2.tween_property(view, "modulate", Color(2.0, 2.0, 2.0, 0.0), 0.30)
	await t2.finished

	# Impact burst at enemy
	_spawn_burst(enemy_center, card.card_type)


func _spawn_burst(global_pos: Vector2, card_type: CardData.CardType) -> void:
	var burst: CardBurst
	if not _burst_pool.is_empty():
		burst = _burst_pool.pop_back()
	else:
		burst = CARD_BURST.instantiate()
		add_child(burst)
		burst.burst_finished.connect(_on_burst_finished)
	burst.position = global_pos
	burst.emit_burst(_get_burst_color(card_type))


func _add_player_status(new_status: StatusEffect) -> void:
	for existing in _player_statuses:
		if existing.get_script() == new_status.get_script():
			existing.stacks += new_status.stacks
			return
	_player_statuses.append(new_status)


func _apply_enemy_statuses_to_player() -> void:
	if _enemy.data.inflicts_vulnerable > 0:
		var v := VulnerableStatus.new()
		v.stacks = _enemy.data.inflicts_vulnerable
		_add_player_status(v)
	if _enemy.data.inflicts_weak > 0:
		var w := WeakStatus.new()
		w.stacks = _enemy.data.inflicts_weak
		_add_player_status(w)


func _get_player_outgoing_multiplier() -> float:
	var multiplier := 1.0
	for status in _player_statuses:
		multiplier *= status.get_damage_dealt_multiplier()
	return multiplier


func _get_player_incoming_multiplier() -> float:
	var multiplier := 1.0
	for status in _player_statuses:
		multiplier *= status.get_damage_taken_multiplier()
	return multiplier


func _tick_player_statuses() -> void:
	for status in _player_statuses:
		status.tick()
	var kept: Array[StatusEffect] = []
	for s in _player_statuses:
		if not s.is_expired():
			kept.append(s)
	_player_statuses = kept


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


func _on_clear_requested(cards: Array[CardData]) -> void:
	if _phase != Phase.PLAYER_TURN:
		return
	for card in cards:
		_hand_cards.append(card)
		_energy = min(_energy + card.cost, MAX_ENERGY)
	_hand_node.clear()
	for data in _hand_cards:
		_hand_node.add_card(data)
	_update_hud()


func _on_execute_requested(stack: Array[CardData]) -> void:
	if _phase != Phase.PLAYER_TURN:
		return
	# Lock input during choreography (ENEMY_TURN blocks all player actions)
	_phase = Phase.ENEMY_TURN
	AudioManager.play_execute_stack()

	# ---- Visual choreography: each card rises then flies toward enemy ----
	var views := _stack_zone.get_views_in_execution_order()
	for i in range(views.size()):
		await _animate_card_launch(views[i], stack[i])
		await get_tree().create_timer(0.08).timeout

	await get_tree().create_timer(0.12).timeout
	_stack_zone.pop_all()

	# ---- Logic resolution ----
	var context: Dictionary = {
		"runtime_stack": [],
		"damage_accumulator": 0,
		"block_gain": 0,
		"heal_amount": 0,
		"draw_pile": _draw_pile,
		"hand": _hand_cards,
	}
	context = _resolver.resolve(stack, context)

	for card in stack:
		_discard_pile.append(card)

	# Apply Vulnerable status from any apply_vulnerable_effect cards
	var vul_stacks: int = context.get("vulnerable_stacks", 0)
	if vul_stacks > 0:
		var v := VulnerableStatus.new()
		v.stacks = vul_stacks
		_enemy.add_status(v)

	# Calculate final damage with status multipliers
	var effective_damage: int = int(context.damage_accumulator
			* _enemy.get_incoming_damage_multiplier()
			* _get_player_outgoing_multiplier())
	_enemy.take_damage(effective_damage)
	if effective_damage > 0:
		AudioManager.play_enemy_hurt()
		_spawn_number("-%d" % effective_damage, _enemy.get_global_rect().get_center(), Color.RED)
		var is_boss_hit := GameManager.current_enemy_data == GameManager.BOSS
		_shake_screen(12.0 if is_boss_hit else 4.0, 0.18)

	_block += context.block_gain
	if context.block_gain > 0:
		AudioManager.play_block_gain()
		_animate_block_pop()
		_spawn_number("+%d" % context.block_gain, _hp_label.get_global_rect().get_center(), Color.CYAN)

	# Handle healing (capped at max HP)
	if context.heal_amount > 0:
		_hp = min(_hp + context.heal_amount, GameManager.player_max_hp)
		_spawn_number("+%d" % context.heal_amount, _hp_label.get_global_rect().get_center(), Color.GREEN)

	# Restore player turn (victory overlay fires separately via enemy_died signal)
	if _phase != Phase.VICTORY:
		_phase = Phase.PLAYER_TURN

	# Refresh hand display — needed when draw effects added cards to _hand_cards
	_hand_node.clear()
	for data in _hand_cards:
		_hand_node.add_card(data)
	_update_hud()


func _on_end_turn_pressed() -> void:
	if _phase != Phase.PLAYER_TURN:
		return
	AudioManager.play_button_click()
	_phase = Phase.ENEMY_TURN
	for card in _hand_cards:
		_discard_pile.append(card)
	_hand_cards.clear()
	await _hand_node.discard_all_animated()

	# Enemy heals before attacking
	if _enemy.data.heal_per_turn > 0:
		_enemy.heal(_enemy.data.heal_per_turn)
		_spawn_number("+%d" % _enemy.data.heal_per_turn, _enemy.get_global_rect().get_center(), Color.GREEN)

	var raw_attack: int = _enemy.get_next_attack()
	var attack: int = int(raw_attack * _enemy.get_outgoing_damage_multiplier() * _get_player_incoming_multiplier())
	var damage: int = max(0, attack - _block)
	_hp = max(0, _hp - damage)
	_enemy.advance_pattern()
	if damage > 0:
		AudioManager.play_player_hurt()
		_spawn_number("-%d" % damage, _hp_label.get_global_rect().get_center(), Color.RED)
		_shake_screen(6.0, 0.22)

	# Apply statuses from enemy attacks
	_apply_enemy_statuses_to_player()
	_update_hud()

	if _hp <= 0:
		_phase = Phase.DEFEAT
		GameManager.player_hp = 0
		AudioManager.play_defeat()
		_shake_screen(20.0, 0.4)
		_defeat_overlay.visible = true
		_defeat_seed_label.text = "Seed: %d" % GameManager.current_seed
		return

	# Tick all statuses at end of the full round
	_enemy.tick_statuses()
	_tick_player_statuses()
	start_player_turn()


func _on_enemy_died() -> void:
	_phase = Phase.VICTORY
	GameManager.player_hp = _hp
	GameManager.gold += GOLD_PER_FIGHT
	GameManager.enemies_defeated += 1
	GameManager.floors_cleared += 1
	AudioManager.play_victory()
	_victory_overlay.visible = true
	var is_boss := GameManager.current_enemy_data != null and GameManager.current_enemy_data == GameManager.BOSS
	var gold_label_text := "+%d Gold" % GOLD_PER_FIGHT
	if is_boss:
		gold_label_text = "You beat the Compiler!"
	_victory_gold_label.text = gold_label_text


func _on_vic_continue_pressed() -> void:
	var is_boss := GameManager.current_enemy_data != null and GameManager.current_enemy_data == GameManager.BOSS
	if is_boss:
		GameManager.current_floor = 15
		get_tree().change_scene_to_file(GameManager.GAME_OVER_SCENE)
	else:
		GameManager.current_floor += 1
		get_tree().change_scene_to_file(GameManager.REWARD_SCENE)


func _on_def_continue_pressed() -> void:
	GameManager.player_hp = 0
	get_tree().change_scene_to_file(GameManager.GAME_OVER_SCENE)


func _on_flee_pressed() -> void:
	if _phase != Phase.PLAYER_TURN:
		return
	AudioManager.play_button_click()
	GameManager.player_hp = _hp
	get_tree().change_scene_to_file(GameManager.MAP_SCENE)
