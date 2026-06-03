class_name FloatingNumber
extends Label

## Floating popup label that drifts upward and fades out.
## Signals 'popup_finished' when animation ends so the pool can reclaim it.

signal popup_finished(popup: FloatingNumber)


func show_popup(value_text: String, start_pos: Vector2, color: Color) -> void:
	text = value_text
	position = start_pos
	modulate = color
	visible = true
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", start_pos.y - 60.0, 0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.finished.connect(_on_tween_done, CONNECT_ONE_SHOT)


func _on_tween_done() -> void:
	visible = false
	popup_finished.emit(self)
