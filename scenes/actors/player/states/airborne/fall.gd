class_name Fall
extends PlayerState
## Falling.


func _on_enter(_handover):
	movement.activate_freefall_timer()


func _subsequent_ticks():
	movement.apply_gravity()


func _physics_tick():
	movement.move_x("air", true)


func _trans_rules():
	if movement.can_spin() and input.buffered_input(&"spin"):
		return &"Spin"

	if not movement.dived and input.buffered_input(&"dive") and movement.can_air_action():
		if Input.is_action_pressed(&"down"):
			return [&"FaceplantDive", actor.vel.x]
		else:
			return [&"Dive", false]

	if Input.is_action_just_pressed(&"down") and movement.can_air_action():
		return &"GroundPound"

	if movement.can_init_wallslide():
		return &"Wallslide"

	if movement.finished_freefall_timer():
		return &"Freefall"

	return &""
