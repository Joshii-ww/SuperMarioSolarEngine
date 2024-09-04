class_name PlayerStateManager
extends StateManager
## Root node of a player state machine.
## Adds player specialised variables and functions.

@export var input: InputManager
@export var movement: PMovement


func _custom_passdowns() -> Dictionary:
	return {
		&"input": input,
		&"movement": movement,
	}
