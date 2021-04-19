extends Node
class_name ProcessedDialogue

export var default_fragment:String = ""
export var auto_start:bool = false

var stage_path


func _enter_tree():
	stage_path = str(self.get_path()).trim_prefix(str(Agartha.stage.get_path()))
	Agartha.Director.declare_dialogue(stage_path, self)

func _exit_tree():
	Agartha.Director.remove_dialogue(stage_path)
	pass

########

func step(thread:Thread):
	if is_running(thread):
		if thread.get_meta("execution_mode") == Director.ExecMode.Forwarding:
			if thread.get_meta("execution_stack")[0].step_counter >= thread.get_meta("execution_stack")[0].target_step:
				thread.set_meta("execution_mode", Director.ExecMode.Normal)
				var _o = thread.get_meta("execution_stack")[0].erase('target_step')
		if thread.get_meta("execution_mode") == Director.ExecMode.Normal:
			#_store(Agartha.Store.get_current_state())
			_wait_semaphore(thread)
		thread.get_meta("execution_stack")[0]['step_counter'] += 1

func _wait_semaphore(thread:Thread):#This function allow to pre-post the semaphore
	if not thread.has_meta("semaphore"):
		thread.set_meta("semaphore", Semaphore.new())
	thread.get_meta("semaphore").wait()
	thread.set_meta("semaphore", null)



func _is_preactive(thread:Thread):
	if thread.get_meta("execution_mode") == Director.ExecMode.Normal:
		return true
	elif thread.get_meta("execution_mode") == Director.ExecMode.Forwarding:
		if thread.get_meta("execution_stack")[0].step_counter >= thread.get_meta("execution_stack")[0].target_step:
			return true
	return false




###########

func ia(thread:Thread):#Shorhand
	return is_active(thread)
func is_active(thread:Thread):
	return thread.get_meta("execution_mode") == Director.ExecMode.Normal

func is_running(thread:Thread):
	return thread.get_meta("execution_mode") == Director.ExecMode.Normal or thread.get_meta("execution_mode") == Director.ExecMode.Forwarding

func is_exitting(thread:Thread):
	return thread.get_meta("execution_mode") == Director.ExecMode.Exitting


### User-side execution actions

func call_fragment(thread:Thread, fragment_name:String):
	if is_active(thread):
		if self.has_method(fragment_name):
			Agartha.History.log_fragment(self.name, fragment_name)
			var entry = {'fragment_name':fragment_name, 'step_counter':0}
			if thread.get_meta("execution_stack"):
				thread.get_meta("execution_stack")[0].step_counter += 1
			thread.get_meta("execution_stack").push_front(entry)
			self.call(fragment_name, thread)
			thread.get_meta("execution_stack").pop_front()
			if thread.get_meta("execution_stack"):
				thread.get_meta("execution_stack")[0].step_counter -= 1
		else:
			push_error("Invalid fragement name '%s' in dialogue '%s'" % [fragment_name, self.name])
	else:
		step(thread)


func jump(thread:Thread, dialogue_name:String, fragment_name:String="", scene_id:String=""):
	if is_running(thread):
		if scene_id:
			var _o = Agartha.call_deferred('change_scene', scene_id, dialogue_name, fragment_name)
		else:
			var _o = Agartha.call_deferred('start_dialogue', dialogue_name, fragment_name)


func cond(thread:Thread, condition):#Shorhand
	return condition(thread, condition)
func condition(thread:Thread, condition):
	match thread.get_meta("execution_mode"):
		Director.ExecMode.Normal:
			if not thread.get_meta("execution_stack")[0].has('condition_stack'):
				thread.get_meta("execution_stack")[0].condition_stack = []
			if condition:
				condition = true
			else:
				condition = false
			thread.get_meta("execution_stack")[0].condition_stack.push_front(condition)
		Director.ExecMode.Forwarding:
			if thread.get_meta("execution_stack")[0].has('condition_stack'):
				condition = thread.get_meta("execution_stack")[0].condition_stack.pop_back()
			else:
				push_error("Condition stack misalignment.")
	return condition

func shard(thread:Thread, shard_id:String, exact_id:bool=true, shard_library:Resource=null):
	if is_running(thread):
		var shard = []
		if shard_library:
			if exact_id:
				if shard_id in shard_library.shards:
					shard = shard_library.shards[shard_id]
			else:
				shard = shard_library.get_shards(shard_id)
		else:
			shard = Agartha.ShardLibrarian.get_shard(shard_id, exact_id)
		if shard:
			if exact_id:
				Agartha.History.log_shard(shard_id)
			else:
				Agartha.History.log_shard(Agartha.ShardLibrarian.get_sub_shard_ids(shard_id))
		for l in shard:
			if is_running(thread):
				if l:
					match l[0]:
						Agartha.ShardParser.LineType.SAY:
							say(thread, l[1], l[2])
							step(thread)
						Agartha.ShardParser.LineType.SHOW:
							show(thread, l[1])
						Agartha.ShardParser.LineType.HIDE:
							hide(thread, l[1])
						Agartha.ShardParser.LineType.PLAY:
							print("play %s" % l[1])
						Agartha.ShardParser.LineType.HALT:
							halt(thread, l[1])
			else:
				break


################# Dialogue actions


func show(thread:Thread, tag:String, parameters:Dictionary={}):
	if _is_preactive(thread):
		Agartha.Show_Hide.call_deferred("action_show", tag, parameters)


func hide(thread:Thread, tag:String, parameters:Dictionary={}):
	if _is_preactive(thread):
		Agartha.Show_Hide.call_deferred("action_hide", tag, parameters)


func halt(thread:Thread, priority:int):
	if _is_preactive(thread):
		Agartha.Timeline.call_deferred("skip_stop", priority)


func say(thread:Thread, character, text:String, parameters:Dictionary={}):
	if _is_preactive(thread):
		Agartha.Say.call_deferred("action",character, text, parameters)


func ask(thread:Thread, default_answer:String="", parameters:Dictionary={}):
	if _is_preactive(thread):
		var return_pointer = [null] # Using a array here with a null entry as a makeshift pointer
		_ask_callback(return_pointer)
		Agartha.Ask.call_deferred("action", default_answer, parameters)
		step(thread)
		return return_pointer[0]
	step(thread)
func _ask_callback(return_pointer:Array):
	return_pointer[0] = yield(Agartha, "ask_return")


func menu(thread:Thread, entries:Array, parameters:Dictionary={}):
	if _is_preactive(thread):
		var return_pointer = [null] # Using a array here with a null entry as a makeshift pointer
		_menu_callback(return_pointer)
		Agartha.Menu.call_deferred("action", entries, parameters)
		step(thread)
		return return_pointer[0]
	step(thread)
func _menu_callback(return_pointer:Array):
	return_pointer[0] = yield(Agartha, "menu_return")
