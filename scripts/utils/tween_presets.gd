class_name TweenPresets
extends RefCounted

## Static helper providing pre-configured Tween factories and shared duration constants.

const STANDARD_DURATION: float = 0.18
const SNAP_DURATION: float = 0.08
const SLOW_DURATION: float = 0.4

static func standard_tween(node: Node) -> Tween:
	return node.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
