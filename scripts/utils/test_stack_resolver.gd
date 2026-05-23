extends SceneTree

const StackResolverClass = preload("res://scripts/systems/stack_resolver.gd")
const CardDataClass = preload("res://scripts/resources/card_data.gd")
const PushValueEffectClass = preload("res://scripts/resources/effects/push_value_effect.gd")
const DupEffectClass = preload("res://scripts/resources/effects/dup_effect.gd")
const DealDamageEffectClass = preload("res://scripts/resources/effects/deal_damage_effect.gd")

func _init() -> void:
	# Build PUSH 5 card
	var push_effect := PushValueEffectClass.new()
	push_effect.value = 5
	var push_card := CardDataClass.new()
	push_card.effects = [push_effect]

	# Build DUP card
	var dup_effect := DupEffectClass.new()
	var dup_card := CardDataClass.new()
	dup_card.effects = [dup_effect]

	# Build STRIKE card (amount = 6)
	var damage_effect := DealDamageEffectClass.new()
	damage_effect.amount = 6
	var strike_card := CardDataClass.new()
	strike_card.effects = [damage_effect]

	# stack[0] = top = first to execute
	var stack: Array[CardData] = [push_card, dup_card, strike_card]

	var context: Dictionary = {
		"runtime_stack": [],
		"damage_accumulator": 0,
		"block_gain": 0,
		"draw_pile": [],
		"hand": [],
	}

	var resolver := StackResolverClass.new()
	context = resolver.resolve(stack, context)

	if context.damage_accumulator == 16:
		print("PASS: damage_accumulator == 16")
	else:
		print("FAIL: damage_accumulator == %d (expected 16)" % context.damage_accumulator)

	quit()
