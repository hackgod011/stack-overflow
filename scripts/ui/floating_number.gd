class_name FloatingNumber
extends Label

## Floating popup label that drifts upward and fades out.
## Call init_popup() after adding to scene tree to animate.


func init_popup(value_text: String, start_pos: Vector2, color: Color) -> void:
	text = value_text
	position = start_pos
	modulate = color
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", start_pos.y - 60.0, 0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.finished.connect(queue_free)
