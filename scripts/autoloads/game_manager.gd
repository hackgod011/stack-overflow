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
const SETTINGS_SCENE := "res://scenes/ui/settings_screen.tscn"
const HISTORY_SCENE := "res://scenes/ui/run_history_screen.tscn"
const CARD_LIBRARY_SCENE := "res://scenes/ui/card_library_screen.tscn"

# In-progress run save (local-first; survives reload via browser storage)
const _RUN_SAVE := "user://current_run.json"

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
var total_damage_dealt: int = 0
var run_start_time: float = 0.0
var deck: Array[CardData] = []
var current_enemy_data: EnemyData = null
var is_run_active: bool = false
## Guards against double-logging a run to history (game-over vs. abandon).
var run_recorded: bool = false

signal run_started


func _ready() -> void:
	_setup_cursor()


func _setup_cursor() -> void:
	# Terminal-green crosshair with a centered hotspot. Four arms with a small
	# gap around the middle plus a center dot, all wrapped in a dim halo so it
	# stays visible on both light and dark backgrounds.
	const SIZE := 32
	const CENTER := 16        # hotspot
	const ARM_OUTER := 14     # arms reach this far from center
	const GAP := 4            # clear space around the exact center
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cur := Color(0.12, 0.95, 0.42, 1.0)
	var dim := Color(0.02, 0.22, 0.10, 0.85)

	# Halo helper: lay a dim pixel only where nothing brighter sits yet.
	var halo := func(px: int, py: int) -> void:
		if px < 0 or py < 0 or px >= SIZE or py >= SIZE:
			return
		if img.get_pixel(px, py).a < 0.1:
			img.set_pixel(px, py, dim)

	# Solid pixel + surrounding halo.
	var plot := func(px: int, py: int) -> void:
		for oy in range(-1, 2):
			for ox in range(-1, 2):
				halo.call(px + ox, py + oy)

	# Draw the four arms (2px thick) with a center gap.
	for t in range(0, 2):
		var off := CENTER - 1 + t
		for r in range(GAP, ARM_OUTER + 1):
			plot.call(CENTER - r, off)   # left
			plot.call(CENTER + r, off)   # right
			plot.call(off, CENTER - r)   # up
			plot.call(off, CENTER + r)   # down
	# Center aiming dot.
	for dy in range(-1, 1):
		for dx in range(-1, 1):
			plot.call(CENTER + dx, CENTER + dy)

	# Paint the bright cores over the halo.
	for t in range(0, 2):
		var off := CENTER - 1 + t
		for r in range(GAP, ARM_OUTER + 1):
			img.set_pixel(CENTER - r, off, cur)
			img.set_pixel(CENTER + r, off, cur)
			img.set_pixel(off, CENTER - r, cur)
			img.set_pixel(off, CENTER + r, cur)
	for dy in range(-1, 1):
		for dx in range(-1, 1):
			img.set_pixel(CENTER + dx, CENTER + dy, cur)

	var tex := ImageTexture.create_from_image(img)
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, Vector2(CENTER, CENTER))


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
	total_damage_dealt = 0
	run_start_time = Time.get_ticks_msec() / 1000.0
	current_enemy_data = null
	is_run_active = true
	run_recorded = false
	deck = _build_starter_deck()
	# Assign art textures to all cards in the pool (once per run start)
	CardArtLoader.apply_art(ALL_CARDS)
	clear_saved_run()
	# A fresh run resets the card collection to the starter cards.
	CollectionManager.reset_to_starters()
	run_started.emit()


## Log the current run to history exactly once (win, loss, or abandon).
func record_current_run(won: bool) -> void:
	if run_recorded or not is_run_active:
		return
	run_recorded = true
	is_run_active = false
	var duration := Time.get_ticks_msec() / 1000.0 - run_start_time
	HistoryManager.record_run(
		floors_cleared, enemies_defeated, total_damage_dealt,
		current_seed, duration, won,
	)
	clear_saved_run()


## --- In-progress run persistence (resume across sessions) ---

func has_saved_run() -> bool:
	return FileAccess.file_exists(_RUN_SAVE)


## Live summary of the in-progress run (for the "ACTIVE" row in run history).
## Reads in-memory state if a run is loaded, else peeks the saved file.
## Returns {} when there is no run in progress.
func get_active_run_summary() -> Dictionary:
	if is_run_active:
		return {
			"floor": floors_cleared,
			"enemies": enemies_defeated,
			"damage": total_damage_dealt,
			"duration": int(Time.get_ticks_msec() / 1000.0 - run_start_time),
		}
	if FileAccess.file_exists(_RUN_SAVE):
		var f := FileAccess.open(_RUN_SAVE, FileAccess.READ)
		if f != null:
			var p = JSON.parse_string(f.get_as_text())
			f.close()
			if p is Dictionary:
				return {
					"floor": int(p.get("floors_cleared", 0)),
					"enemies": int(p.get("enemies_defeated", 0)),
					"damage": int(p.get("total_damage_dealt", 0)),
					"duration": int(p.get("elapsed", 0.0)),
				}
	return {}


func get_card_by_id(id: StringName) -> CardData:
	for card: CardData in ALL_CARDS:
		if card.id == id:
			return card
	return null


## Checkpoint the current run to disk (called from the map between floors).
func save_run() -> void:
	if not is_run_active:
		return
	var deck_ids: Array = []
	for card: CardData in deck:
		deck_ids.append(String(card.id))
	var data := {
		"seed": current_seed,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"gold": gold,
		"current_floor": current_floor,
		"floors_cleared": floors_cleared,
		"enemies_defeated": enemies_defeated,
		"total_damage_dealt": total_damage_dealt,
		"elapsed": Time.get_ticks_msec() / 1000.0 - run_start_time,
		"deck": deck_ids,
	}
	var file := FileAccess.open(_RUN_SAVE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


## Restore a saved run into memory. Returns true on success.
func load_saved_run() -> bool:
	if not FileAccess.file_exists(_RUN_SAVE):
		return false
	var file := FileAccess.open(_RUN_SAVE, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return false
	current_seed = int(parsed.get("seed", 0))
	RNG.seed_run(current_seed)
	player_max_hp = int(parsed.get("player_max_hp", 80))
	player_hp = int(parsed.get("player_hp", player_max_hp))
	gold = int(parsed.get("gold", 0))
	current_floor = int(parsed.get("current_floor", 0))
	floors_cleared = int(parsed.get("floors_cleared", 0))
	enemies_defeated = int(parsed.get("enemies_defeated", 0))
	total_damage_dealt = int(parsed.get("total_damage_dealt", 0))
	run_start_time = Time.get_ticks_msec() / 1000.0 - float(parsed.get("elapsed", 0.0))
	var restored: Array[CardData] = []
	for id in parsed.get("deck", []):
		var card := get_card_by_id(StringName(id))
		if card != null:
			restored.append(card)
	deck = restored
	CardArtLoader.apply_art(ALL_CARDS)
	is_run_active = true
	run_recorded = false
	return true


func clear_saved_run() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists("current_run.json"):
		dir.remove("current_run.json")


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
