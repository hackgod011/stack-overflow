extends Node
## Tracks the cards discovered in the CURRENT run (starters + anything obtained
## via rewards/shops this run). Reset to starters on each new run; persisted to
## user://collection.json so it survives a mid-run reload/resume.
## Local-first: this is the single source of truth for the card library and is
## structured so a cloud backend (e.g. Supabase) could sync `discovered` later.

const _FILE := "user://collection.json"

## Card ids (as String) the player has discovered → true.
var discovered: Dictionary = {}


func _ready() -> void:
	_load()
	_seed_starters()


## Starter-deck cards are owned from the very first run, so always discovered.
func _seed_starters() -> void:
	for card: CardData in [GameManager.STRIKE_DATA, GameManager.DEFEND_DATA, GameManager.PUSH_5_DATA]:
		if card != null:
			discovered[String(card.id)] = true
	_save()


## Clear the collection back to just the starter cards. Called when a new run
## begins so the library reflects only what's unlocked in the current run.
func reset_to_starters() -> void:
	discovered.clear()
	_seed_starters()


func is_discovered(id: StringName) -> bool:
	return discovered.get(String(id), false)


## Mark a card discovered. Saves only when it is newly discovered.
func discover_card(card: CardData) -> void:
	if card == null:
		return
	var key := String(card.id)
	if discovered.get(key, false):
		return
	discovered[key] = true
	_save()


## All cards the player has discovered, in canonical ALL_CARDS order.
func get_discovered_cards() -> Array[CardData]:
	var result: Array[CardData] = []
	for card: CardData in GameManager.ALL_CARDS:
		if is_discovered(card.id):
			result.append(card)
	return result


func discovered_count() -> int:
	return get_discovered_cards().size()


func total_count() -> int:
	return GameManager.ALL_CARDS.size()


func _save() -> void:
	var file := FileAccess.open(_FILE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(discovered, "\t"))
	file.close()


func _load() -> void:
	if not FileAccess.file_exists(_FILE):
		return
	var file := FileAccess.open(_FILE, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		discovered = parsed
