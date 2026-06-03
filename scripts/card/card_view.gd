class_name CardView
extends Control

const HOLO_SHADER := preload("res://assets/shaders/holo_foil.gdshader")
const ART_FONT    := preload("res://assets/fonts/JetBrainsMono.ttf")

# Card frame textures
const FRAME_RED    := preload("res://assets/card_frames/card_frame_blank_red.png")
const FRAME_BLUE   := preload("res://assets/card_frames/card_frame_blank_blue.png")
const FRAME_GREEN  := preload("res://assets/card_frames/card_frame_blank_green.png")
const FRAME_YELLOW := preload("res://assets/card_frames/card_frame_blank_yellow.png")
const FRAME_PURPLE := preload("res://assets/card_frames/card_frame_blank_purple.png")

# Art icons — board-game-icons (white line-art on transparent background)
const ICON_PUSH    := preload("res://assets/card_icons/cards_stack_high.png")
const ICON_POP     := preload("res://assets/card_icons/card_remove.png")
const ICON_DUP     := preload("res://assets/card_icons/cards_stack.png")
const ICON_SWAP    := preload("res://assets/card_icons/hexagon_switch.png")
const ICON_ROT     := preload("res://assets/card_icons/arrow_rotate.png")
const ICON_ADD     := preload("res://assets/card_icons/card_add.png")
const ICON_NEG     := preload("res://assets/card_icons/card_subtract.png")
const ICON_LOOP    := preload("res://assets/card_icons/arrow_clockwise.png")
const ICON_IFPOS   := preload("res://assets/card_icons/hexagon_question.png")
const ICON_BREAK   := preload("res://assets/card_icons/cards_stack_cross.png")
const ICON_STRIKE  := preload("res://assets/card_icons/sword.png")
const ICON_DEFEND  := preload("res://assets/card_icons/shield.png")
const ICON_DRAW    := preload("res://assets/card_icons/hand_card.png")
const ICON_COMPILE := preload("res://assets/card_icons/cards_fan.png")
const ICON_DEBUG   := preload("res://assets/card_icons/hexagon_question.png")

signal card_clicked(card_data: CardData)

enum State { IDLE, HOVERED, DRAGGING, STACKED }

var current_state: State = State.IDLE

const HOVER_LIFT       := Vector2(0.0, -28.0)
const DEAL_DURATION    := 0.25
const DEAL_START_SCALE := Vector2(0.8, 0.8)
const LAND_START_SCALE := Vector2(0.85, 0.85)

const TYPE_TITLE_COLORS := {
	CardData.CardType.VALUE:     Color(0.40, 0.85, 1.00),
	CardData.CardType.OPERATION: Color(0.40, 1.00, 0.60),
	CardData.CardType.FLOW:      Color(1.00, 0.90, 0.25),
	CardData.CardType.EFFECT:    Color(1.00, 0.50, 0.30),
}

# Icon per card id — null means use text fallback in ArtLabel
const CARD_ICONS: Dictionary = {
	&"push_1":       ICON_PUSH,
	&"push_3":       ICON_PUSH,
	&"push_5":       ICON_PUSH,
	&"push_10":      ICON_PUSH,
	&"push_rand":    ICON_PUSH,
	&"pop":          ICON_POP,
	&"dup":          ICON_DUP,
	&"swap":         ICON_SWAP,
	&"rot":          ICON_ROT,
	&"add":          ICON_ADD,
	&"neg":          ICON_NEG,
	&"loop_2":       ICON_LOOP,
	&"loop_3":       ICON_LOOP,
	&"if_positive":  ICON_IFPOS,
	&"break":        ICON_BREAK,
	&"strike":       ICON_STRIKE,
	&"heavy_strike": ICON_STRIKE,
	&"defend":       ICON_DEFEND,
	&"draw_2":       ICON_DRAW,
	&"compile":      ICON_COMPILE,
	&"debug":        ICON_DEBUG,
}

# Text-only fallback for cards without a distinct icon (mul has no clean icon match)
const CARD_SYMBOL_TEXT: Dictionary = {
	&"mul": "A×B",
}

const RED_FRAME_CARDS := [&"strike", &"heavy_strike"]

var _card_data: CardData
var _original_position: Vector2
var _original_z_index: int
var _tween: Tween
var _position_ready: bool = false

@onready var _background:        TextureRect = $Background
@onready var _holo_overlay:      ColorRect   = $HoloOverlay
@onready var _title_label:       Label       = $TitleLabel
@onready var _cost_label:        Label       = $CostLabel
@onready var _art_icon:          TextureRect = $ArtIcon
@onready var _art_label:         Label       = $ArtLabel
@onready var _description_label: Label       = $DescriptionLabel


func _ready() -> void:
	_original_z_index = z_index
	if not DisplayServer.is_touchscreen_available():
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		pressed = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if pressed and (current_state == State.IDLE or current_state == State.HOVERED):
		AudioManager.play_card_play()
		card_clicked.emit(_card_data)


func set_card_data(data: CardData) -> void:
	_card_data = data

	# ── Frame ──────────────────────────────────────────────────────────
	var title_color := Color.WHITE
	if data.rarity == CardData.Rarity.RARE:
		# Background: crisp FRAME_PURPLE (no shader) — boundaries stay visible
		_background.texture = FRAME_PURPLE
		_background.material = null
		# HoloOverlay: transparent shimmer shader floats on top of the frame
		var mat := ShaderMaterial.new()
		mat.shader = HOLO_SHADER
		_holo_overlay.material = mat
		_holo_overlay.visible = true
		title_color = Color(1.0, 0.85, 0.25)
	else:
		_background.material = null
		_holo_overlay.visible = false
		_holo_overlay.material = null
		match data.card_type:
			CardData.CardType.VALUE:
				_background.texture = FRAME_BLUE
			CardData.CardType.OPERATION:
				_background.texture = FRAME_GREEN
			CardData.CardType.FLOW:
				_background.texture = FRAME_YELLOW
			CardData.CardType.EFFECT:
				_background.texture = FRAME_RED if data.id in RED_FRAME_CARDS else FRAME_PURPLE
		title_color = TYPE_TITLE_COLORS.get(data.card_type, Color.WHITE)

	# ── Title ──────────────────────────────────────────────────────────
	_title_label.text = data.title
	_title_label.add_theme_font_override("font", ART_FONT)
	_title_label.add_theme_font_size_override("font_size", 8)
	_title_label.add_theme_color_override("font_color", title_color)

	# ── Cost ───────────────────────────────────────────────────────────
	_cost_label.text = str(data.cost)
	_cost_label.add_theme_font_override("font", ART_FONT)
	_cost_label.add_theme_font_size_override("font_size", 9)
	_cost_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.20))

	# ── Art icon or text fallback ──────────────────────────────────────
	var icon_tex: Texture2D = CARD_ICONS.get(data.id, null)
	if icon_tex:
		_art_icon.texture = icon_tex
		_art_icon.modulate = Color(1.0, 1.0, 1.0, 0.90)
		_art_icon.visible = true
		_art_label.visible = false
	else:
		_art_icon.visible = false
		_art_label.text = CARD_SYMBOL_TEXT.get(data.id, "")
		_art_label.add_theme_font_override("font", ART_FONT)
		_art_label.add_theme_font_size_override("font_size", 22)
		_art_label.add_theme_color_override("font_color", Color(0.25, 1.00, 0.55, 0.95))
		_art_label.visible = true

	# ── Description ────────────────────────────────────────────────────
	_description_label.text = data.description
	_description_label.add_theme_font_override("font", ART_FONT)
	_description_label.add_theme_font_size_override("font_size", 10)
	_description_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))


func animate_deal() -> void:
	if _tween:
		_tween.kill()
	scale = DEAL_START_SCALE
	_tween = TweenPresets.standard_tween(self)
	_tween.tween_property(self, "scale", Vector2(1.0, 1.0), DEAL_DURATION)


func animate_land() -> void:
	if _tween:
		_tween.kill()
	scale = LAND_START_SCALE
	_tween = TweenPresets.standard_tween(self)
	_tween.tween_property(self, "scale", Vector2(1.0, 1.0), TweenPresets.STANDARD_DURATION)


func disable() -> void:
	if mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.disconnect(_on_mouse_entered)
	if mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.disconnect(_on_mouse_exited)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_state = State.IDLE


func _animate_hover() -> void:
	if _tween:
		_tween.kill()
	_tween = TweenPresets.standard_tween(self)
	z_index = _original_z_index + 1
	_tween.tween_property(self, "position", _original_position + HOVER_LIFT, TweenPresets.STANDARD_DURATION)
	_tween.parallel().tween_property(self, "scale", Vector2(1.08, 1.08), TweenPresets.STANDARD_DURATION)


func _animate_idle() -> void:
	if _tween:
		_tween.kill()
	_tween = TweenPresets.standard_tween(self)
	z_index = _original_z_index
	_tween.tween_property(self, "position", _original_position, TweenPresets.STANDARD_DURATION)
	_tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), TweenPresets.STANDARD_DURATION)


func _on_mouse_entered() -> void:
	if not _position_ready:
		_original_position = position
		_position_ready = true
	current_state = State.HOVERED
	_animate_hover()


func _on_mouse_exited() -> void:
	current_state = State.IDLE
	_animate_idle()
