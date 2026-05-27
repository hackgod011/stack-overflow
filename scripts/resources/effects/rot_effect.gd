class_name RotEffect
extends CardEffect
## Rotates the top three values on the runtime stack. ( a b c -- b c a )
## The third-from-top value rises to the top.


func apply(context: Dictionary) -> void:
	if context.runtime_stack.size() < 3:
		return
	var a: int = context.runtime_stack[-3]
	var b: int = context.runtime_stack[-2]
	var c: int = context.runtime_stack[-1]
	context.runtime_stack[-3] = b
	context.runtime_stack[-2] = c
	context.runtime_stack[-1] = a
