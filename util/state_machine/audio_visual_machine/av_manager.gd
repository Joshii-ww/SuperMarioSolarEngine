class_name AVManager
extends Node
## An interface that manages audiovisual effects.

## If an effect does not exist, try to set this sprite's animation to the name of the effect.
@export var fallback_sprite: AnimatedSprite2D = null

## Cache of effects that can be triggered.
var _effect_cache: Dictionary = {}

var current_effect: AVEffect = null


func trigger_effect(effect: String, offset:= Vector2i(0, 0)) -> void:
	deactivate_effect()

	if _effect_cache.has(effect):
		var effect_node: AVEffect = _effect_cache[effect]

		current_effect = effect_node

		effect_node.trigger()
		return

	var node: AVEffect = get_node_or_null(effect)

	if node == null:
		if fallback_sprite == null:
			push_warning("No effect with this name, and no fallback sprite.")
			return
		if !fallback_sprite.sprite_frames.has_animation(effect):
			push_warning("No effect or sprite animation with this name.")
			return
		
		fallback_sprite.offset = offset
		fallback_sprite.play(effect)
		return

	node.trigger()
	_effect_cache[effect] = node
	current_effect = node


func deactivate_effect():
	if current_effect != null and current_effect.deactivate_on_switch:
		current_effect.deactivate()
