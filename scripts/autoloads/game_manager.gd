extends Node

## Run-wide state: HP, deck, floor, gold, enemy selection.
## All scenes read/write here; never hardcode state in individual scenes.

# Scene paths
const COMBAT_SCENE := "res://scenes/combat/combat_scene.tscn"
const MAP_SCENE := "res://scenes/map/run_map.tscn"
const REWARD_SCENE := "res://scenes/ui/reward_screen.tscn"
const SHOP_SCENE := "res://scenes/ui/shop_screen.tscn"
const GAME_OVER_SCENE := "res://scenes/ui/game_over_screen.tscn"
const MAIN_MENU_SCENE := "res://scenes/core/main_menu.tscn"

# Starter deck cards
const STRIKE_DATA := preload("res://data/cards/strike.tres")
const DEFEND_DATA := preload("res://data/cards/defend.tres")
const PUSH_5_DATA := preload("res://data/cards/push_5.tres")

# Full card pool (all 22 cards)
const ALL_CARDS: Array = [
	preload("res://data/cards/push_1.tres"),
	preload("res://data/cards/push_3.tres"),
	preload("res://data/cards/push_5.tres"),
	preload("res://data/cards/push_10.tres"),
	preload("res://data/cards/push_rand.tres"),
	preload("res://data/cards/dup.tres"),
	preload("res://data/cards/pop.tres"),
	preload("res://data/cards/swap.tres"),
	preload("res://data/cards/rot.tres"),
	preload("res://data/cards/add.tres"),
	preload("res://data/cards/mul.tres"),
	preload("res://data/cards/neg.tres"),
	preload("res://data/cards/loop_2.tres"),
	preload("res://data/cards/loop_3.tres"),
	preload("res://data/cards/if_positive.tres"),
	preload("res://data/cards/break.tres"),
	preload("res://data/cards/strike.tres"),
	preload("res://data/cards/heavy_strike.tres"),
	preload("res://data/cards/defend.tres"),
	preload("res://data/cards/draw_2.tres"),
	preload("res://data/cards/compile.tres"),
	preload("res://data/cards/debug.tres"),
]

# Enemy pools
const REGULAR_ENEMIES: Array = [
	preload("res://data/enemies/null_pointer.tres"),
	preload("res://data/enemies/infinite_loop.tres"),
	preload("res://data/enemies/segfault.tres"),
	preload("res://data/enemies/race_condition.tres"),
	preload("res://data/enemies/memory_leak.tres"),
	preload("res://data/enemies/off_by_one.tres"),
]
const ELITE_ENEMIES: Array = [
	preload("res://data/enemies/kernel_panic.tres"),
	preload("res://data/enemies/stack_overflow_enemy.tres"),
]
const BOSS: EnemyData = preload("res://data/enemies/the_compiler.tres")

# Run state
var current_seed: int = 0
var player_max_hp: int = 80
var player_hp: int = 80
var player_block: int = 0
var gold: int = 0
var current_floor: int = 0
var floors_cleared: int = 0
var enemies_defeated: int = 0
var deck: Array[CardData] = []
var current_enemy_data: EnemyData = null
var is_run_active: bool = false

signal run_started


func start_new_run(run_seed: int = -1) -> void:
	if run_seed == -1:
		run_seed = Time.get_ticks_msec()
	current_seed = run_seed
	RNG.seed_run(run_seed)
	player_hp = player_max_hp
	player_block = 0
	gold = 100
	current_floor = 0
	floors_cleared = 0
	enemies_defeated = 0
	current_enemy_data = null
	is_run_active = true
	deck = _build_starter_deck()
	run_started.emit()


func get_enemy_for_floor(floor: int) -> EnemyData:
	match _get_floor_type(floor):
		FloorType.BOSS:
			return BOSS
		FloorType.ELITE:
			var rng := RandomNumberGenerator.new()
			rng.seed = current_seed + floor * 7919
			return ELITE_ENEMIES[rng.randi() % ELITE_ENEMIES.size()]
		_:
			var rng := RandomNumberGenerator.new()
			rng.seed = current_seed + floor * 1031
			return REGULAR_ENEMIES[rng.randi() % REGULAR_ENEMIES.size()]


enum FloorType { FIGHT, ELITE, SHOP, BOSS }


func get_floor_type(floor: int) -> FloorType:
	return _get_floor_type(floor)


func get_cards_by_rarity(rarity: CardData.Rarity) -> Array[CardData]:
	var result: Array[CardData] = []
	for card: CardData in ALL_CARDS:
		if card.rarity == rarity:
			result.append(card)
	return result


func pick_reward_cards(count: int) -> Array[CardData]:
	var pool: Array = []
	for card: CardData in ALL_CARDS:
		# Exclude cards already in deck to prefer variety
		if not deck.has(card):
			pool.append(card)
	if pool.is_empty():
		pool = ALL_CARDS.duplicate()

	var chosen: Array[CardData] = []
	var attempts := 0
	while chosen.size() < count and attempts < 100:
		attempts += 1
		var roll: float = RNG.randf()
		var rarity: CardData.Rarity
		if roll < 0.1:
			rarity = CardData.Rarity.RARE
		elif roll < 0.4:
			rarity = CardData.Rarity.UNCOMMON
		else:
			rarity = CardData.Rarity.COMMON

		var candidates: Array = pool.filter(func(c: CardData) -> bool: return c.rarity == rarity)
		if candidates.is_empty():
			continue
		var pick: CardData = candidates[RNG.randi_range(0, candidates.size() - 1)]
		if not chosen.has(pick):
			chosen.append(pick)

	return chosen


func pick_shop_cards(count: int) -> Array[CardData]:
	var pool: Array = ALL_CARDS.duplicate()
	RNG.shuffle(pool)
	var result: Array[CardData] = []
	for c in pool:
		if result.size() >= count:
			break
		result.append(c)
	return result


func _build_starter_deck() -> Array[CardData]:
	var d: Array[CardData] = []
	for _i in 5:
		d.append(STRIKE_DATA)
	for _i in 3:
		d.append(DEFEND_DATA)
	for _i in 2:
		d.append(PUSH_5_DATA)
	return d


func _get_floor_type(floor: int) -> FloorType:
	if floor == 15:
		return FloorType.BOSS
	if floor in [9, 12]:
		return FloorType.ELITE
	if floor in [6, 11]:
		return FloorType.SHOP
	return FloorType.FIGHT
