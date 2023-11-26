class_name State
extends Node
## Abstract state class with behavior that affects a target node.


## The current active substate.
var live_substate: State = null

## The target of this state machine's behavior.
var actor: CharacterBody2D = null

## The AVManager of this state machine.
var av: AVManager = null

## The root of the state machine.
var manager: StateManager = null

## Cache of StateLinks to other states in the machine.
var _link_cache: Dictionary = {}

## True when on the first cycle of the physics loop.
var _first_cycle: bool = true

## The name of the AV effect that this state should trigger.
@export var effect := &""
## How many units the effect needs to be offset.
@export var effect_offset := Vector2i()


func _to_string():
	return str(name)


## Get a link to the given state.
func get_link(key: StringName) -> StateLink:
	if _link_cache.has(key):
		return _link_cache[key]

	return _cache_link(key)


## Cache a link to a state.
func _cache_link(key: StringName) -> StateLink:
	var target = manager.find_child(key)
	if target == null:
		push_error("State %s does not exist!" % key)
		return null

	var link = StateLink.new(self, target)
	_link_cache[key] = link
	return link


## Called on all cycles of the physics process loop.
func _cycle_tick() -> void:
	pass


## Called on the first cycle of the physics process loop.
func _pre_tick() -> void:
	pass


## Called on subsequent cycles of the physics process loop.
func _post_tick() -> void:
	pass


## Calls the fixed tick functions
func tick_hook() -> void:
	if _first_cycle:
		_pre_tick()
		_first_cycle = false
	else:
		_post_tick()

	_cycle_tick()


## Called when the state becomes active.
func _on_enter(_handover: Variant) -> void:
	pass


## Called when the state is deactivated.
func _on_exit() -> void:
	pass


## Return the name of a state for the parent to switch to, or `null` for no change.
## This is called by the parent state during probe_switch() at the start of the physics tick.
## This function should be used to define the transition rules for the state.
func _tell_switch() -> Variant:
	return &""


## Return the name of a passthrough state.
## When this state is switched to, immediately switch to that state.
## This means that other states don't have to guess the behavior of this state when switching to a child of it.
func _tell_defer() -> StringName:
	return &""


## Probe the active substate for a state to switch to.
## This is based on its transition rules defined in tell_switch().
## If a state is found, switch to that state.
func probe_switch(defer: bool = false) -> void:
	var link_name
	var handover = null

	if defer:
		link_name = _tell_defer()
	else:
		var data

		data = _tell_switch()
		if data is Array:
			link_name = data[0]
			handover = data[1]
		else:
			link_name = data

	# Only switch if we need to
	if link_name != &"":
		var link = get_link(link_name)
		_switch_leaf(link, handover)


## Reroute the active path to select a given state as the active leaf.
func _switch_leaf(link: StateLink, handover = null) -> void:
	var path = link.get_path()
	var peak = link.get_peak_index()
	var length = link.get_length()
	var last = length - 1
	var argument = null

	var current_state: State = self
	for i in length:
		var next_state: State = path[i]

		if i <= peak:
			ditch_state()
		else:
			if i == last:
				argument = handover
			current_state.switch_substate(next_state, argument)

		assert(current_state != next_state)
		current_state = next_state

	current_state.probe_switch(true)


## Ditch this state and all its descendents,
## making this branch of the state tree inactive.
func ditch_state():
	_on_exit()

	# Ditch live descendents
	if live_substate == null: return
	live_substate.ditch_state()
	live_substate = null


## Activate the given state, ditching the current state.
func switch_substate(new_state: State, handover: Variant):
	if new_state == live_substate: return
	if new_state == null: return

	if live_substate != null:
		live_substate.ditch_state()

	live_substate = new_state
	new_state.trigger_enter(handover)


## Trigger entrance events for a new state.
func trigger_enter(handover: Variant):
	_first_cycle = true
	_on_enter(handover)

	if av != null and effect != &"":
		av.trigger_effect(effect, effect_offset)


## Call a function on the live substate, but only if there is one.
func call_live(function_name: StringName, arguments := []):
	if live_substate != null:
		live_substate.call_func(function_name, arguments)


## Call a function on this state and all its live descendents.
func recurse_live(function_name: StringName, arguments := []):
	call_func(function_name, arguments)
	call_live(&"recurse_live", [function_name, arguments])


## Call a function on this state and its entire descendant family.
func recurse_descendents(function_name: StringName, arguments := []):
	call_func(function_name, arguments)

	for child in get_children():
		child.recurse_descendents(function_name, arguments)


## Call a callable from a function name and given arguments.
func call_func(function_name: StringName, arguments := []):
	var callable := Callable(self, function_name)

	callable.callv(arguments)


