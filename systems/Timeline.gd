extends Node

var pending_step = false
var restoring = false

func step():
	self.pending_step = true

func _process(_delta):
	if pending_step and not restoring:
		next_step()

func next_step():
	if any_blocker():
		call_for_blocked_step()
	else:
		Agartha.Store.prepare_storing()
		call_for_storing()
		call_for_step()


func roll(amount:int):
	restoring = true
	end_skipping()
	unblock_all()
	amount += Agartha.Store.current_state_id
	if amount >= 0 and amount < Agartha.Store.state_stack.size():
		Agartha.Store.restore_state(amount)
		var scene = Agartha.store.get("_scene")
		if not scene:
			scene = ""
		Agartha.StageManager.change_scene(scene, "", "", true)
		call_for_restoring()
	restoring = false


func load_save(save):
	restoring = true
	end_skipping()
	unblock_all()
	Agartha.Store.restore_state_from_save(save)
	var scene = Agartha.store.get("_scene")
	if not scene:
		scene = ""
	Agartha.StageManager.change_scene(scene, "", "", true)
	call_for_restoring()


func call_for_step():
	get_tree().get_root().propagate_call("_step")
	pending_step = false

func call_for_blocked_step():
	get_tree().get_root().propagate_call("_blocked_step")
	pending_step = false

func call_for_storing():
	get_tree().get_root().propagate_call("_store", [Agartha.Store.get_current_state()])

func call_for_restoring():
	get_tree().get_root().propagate_call("_restore", [Agartha.Store.get_current_state()])
	restoring = false
	pending_step = false


###### Skipping system

enum SkipPriority {
	SEEN, # Only skip seen text
	UNSEEN, # Skip un-important unseen text
	INPUT, # Skip even after requiring input (ask and menu), but only un-important
	IMPORTANT, # Skip important seen text, this level is given as an example
	KEY # Skip key text, this level is given as an example
}

var skip_priority:int = 0

signal skip_change(active, _priority)


func start_skipping(priority:int):
	self.emit_signal('skip_change', true, priority)
	skip_priority = priority
	$SkipDelay.wait_time = Agartha.Settings.get("agartha/dialogues/skip_delay")
	$SkipDelay.start()


func end_skipping():
	$SkipDelay.stop()
	self.emit_signal('skip_change', false, 0)


func skip_stop(stop_priority:int):
	if skip_priority < stop_priority:
		 end_skipping()


func _skip():
	step()


###### Blocker system

const blockers:Dictionary = {}

func block(id, set:bool=false, amount:int=1):
	if amount < 1:
		push_warning("Cannot block '%s' a null or negative amount of time." % id)
		return 
	if set or not id in blockers:
		blockers[id] = amount
	else:
		blockers[id] += amount

func unblock(id, full:bool=false, amount:int=1):
	if amount < 1:
		push_warning("Cannot unblock '%s' a null or negative amount of time." % id)
		return
	if id in blockers:
		if full or blockers[id] <= amount:
			blockers.erase(id)
		else:
			blockers[id] -= amount

func get_blocker(id):
	if id in blockers:
		return blockers[id]
	return 0

func unblock_all():
	blockers.clear()

func any_blocker():
	return not blockers.empty()
