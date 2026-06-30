class_name EnemyData
extends Resource

@export var name: String
@export var max_hp: int = 30
@export var attack_pattern: Array[int] = []

## --- Visual sprite (data-driven so themed art swaps in with no code change) ---
## Sprite sheet for this enemy. A grid of `sheet_hframes` x `sheet_vframes` cells.
@export var sprite_sheet: Texture2D
## Grid dimensions of the sheet.
@export var sheet_hframes: int = 4
@export var sheet_vframes: int = 7
## Frame indices (row * sheet_hframes + col) that make up the looping idle animation.
@export var idle_frames: PackedInt32Array = PackedInt32Array([0, 1])
## Seconds per idle frame.
@export var idle_frame_time: float = 0.45
## Render scale applied to the sprite (bosses use > 1.0 to read larger).
@export var sprite_scale: float = 2.0
## Per-phase tint applied to the sprite (escalation). Empty = no tint.
@export var phase_tints: PackedColorArray = PackedColorArray()

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
