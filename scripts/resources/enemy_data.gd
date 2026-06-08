class_name EnemyData
extends Resource

@export var name: String
@export var max_hp: int = 30
@export var attack_pattern: Array[int] = []

## Turns of Vulnerable inflicted on the player each time this enemy attacks.
@export var inflicts_vulnerable: int = 0
## Turns of Weak inflicted on the player each time this enemy attacks.
@export var inflicts_weak: int = 0
## Damage below this threshold is ignored (0 = disabled). Used for armored enemies.
@export var min_damage_threshold: int = 0
## HP this enemy regenerates at the start of each of its turns.
@export var heal_per_turn: int = 0

## Multi-phase support (0.0 = disabled). At or below this fraction of max_hp, phase 2 activates.
@export var phase2_hp_fraction: float = 0.0
@export var phase2_attack_pattern: Array[int] = []
@export var phase2_inflicts_vulnerable: int = 0
@export var phase2_inflicts_weak: int = 0
@export var phase2_heal_per_turn: int = 0
@export var phase2_min_damage_threshold: int = 0

## At or below this fraction of max_hp, phase 3 activates (requires phase2_hp_fraction > 0).
@export var phase3_hp_fraction: float = 0.0
@export var phase3_attack_pattern: Array[int] = []
@export var phase3_inflicts_vulnerable: int = 0
@export var phase3_inflicts_weak: int = 0
@export var phase3_heal_per_turn: int = 0
@export var phase3_min_damage_threshold: int = 0
