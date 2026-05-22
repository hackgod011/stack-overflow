class_name CardData
extends Resource


enum CardType { OPERATION, VALUE, FLOW, EFFECT }
enum Rarity { COMMON, UNCOMMON, RARE }


@export var id: StringName
@export var title: String
@export_multiline var description: String
@export var cost: int = 1
@export var card_type: CardType
@export var rarity: Rarity
@export var art: Texture2D = null
@export var effects: Array[CardEffect]
