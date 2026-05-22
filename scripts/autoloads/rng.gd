extends Node


var _rng := RandomNumberGenerator.new()
var _seed: int = 0


func seed_run(s: int) -> void:
	_seed = s
	_rng.seed = s


func get_seed() -> int:
	return _seed


func randi_range(a: int, b: int) -> int:
	return _rng.randi_range(a, b)


func randf() -> float:
	return _rng.randf()


func randf_range(a: float, b: float) -> float:
	return _rng.randf_range(a, b)


func pick(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[_rng.randi_range(0, array.size() - 1)]


func shuffle(array: Array) -> void:
	var i: int = array.size() - 1
	while i > 0:
		var j: int = _rng.randi_range(0, i)
		var tmp: Variant = array[i]
		array[i] = array[j]
		array[j] = tmp
		i -= 1
