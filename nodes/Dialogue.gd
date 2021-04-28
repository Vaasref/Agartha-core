extends Node
class_name Dialogue

export var default_fragment:String = ""
export var auto_start:bool = false

var thread:Thread setget ,_get_thread
var stage_path:String


func _enter_tree():
	stage_path = str(self.get_path()).trim_prefix(str(Agartha.stage.get_path()))
	Agartha.Director.declare_dialogue(stage_path, self)

func _exit_tree():
	Agartha.Director.remove_dialogue(stage_path)
	pass

func _get_thread():
	return Agartha.Director.get_thread()

########

func step():
	if is_running():
		if self.thread.get_meta("execution_mode") == Director.ExecMode.Forwarding:
			if self.thread.get_meta("execution_stack")[0].step_counter >= self.thread.get_meta("execution_stack")[0].target_step:
				self.thread.set_meta("execution_mode", Director.ExecMode.Normal)
				var _o = self.thread.get_meta("execution_stack")[0].erase('target_step')
		if self.thread.get_meta("execution_mode") == Director.ExecMode.Normal:
			Agartha.Director._store(Agartha.store)
			_wait_semaphore()
		self.thread.get_meta("execution_stack")[0]['step_counter'] += 1

func _wait_semaphore():#This function allow to pre-post the semaphore
	if not self.thread.has_meta("semaphore"):
		self.thread.set_meta("semaphore", Semaphore.new())
	self.thread.get_meta("semaphore").wait()
	self.thread.set_meta("semaphore", null)



func _is_preactive():
	if self.thread.get_meta("execution_mode") == Director.ExecMode.Normal:
		return true
	elif self.thread.get_meta("execution_mode") == Director.ExecMode.Forwarding:
		if self.thread.get_meta("execution_stack")[0].step_counter >= self.thread.get_meta("execution_stack")[0].target_step:
			return true
	return false




###########

func ia():#Shorhand
	return is_active()
func is_active():
	return self.thread.get_meta("execution_mode") == Director.ExecMode.Normal

func is_running():
	return self.thread.get_meta("execution_mode") == Director.ExecMode.Normal or self.thread.get_meta("execution_mode") == Director.ExecMode.Forwarding

func is_exitting():
	return self.thread.get_meta("execution_mode") == Director.ExecMode.Exitting


### User-side execution actions

func call_fragment(fragment_name:String):
	if is_active():
		if self.has_method(fragment_name):
			Agartha.History.log_fragment(self.name, fragment_name)
			var entry = {'fragment_name':fragment_name, 'step_counter':0}
			if self.thread.get_meta("execution_stack"):
				self.thread.get_meta("execution_stack")[0].step_counter += 1
			self.thread.get_meta("execution_stack").push_front(entry)
			self.call(fragment_name, thread)
			self.thread.get_meta("execution_stack").pop_front()
			if self.thread.get_meta("execution_stack"):
				self.thread.get_meta("execution_stack")[0].step_counter -= 1
		else:
			push_error("Invalid fragement name '%s' in dialogue '%s'" % [fragment_name, self.name])
	else:
		step()


func jump(dialogue_name:String, fragment_name:String="", scene_id:String=""):
	if is_running():
		if scene_id:
			var _o = Agartha.call_deferred('change_scene', scene_id, dialogue_name, fragment_name)
		else:
			var _o = Agartha.call_deferred('start_dialogue', dialogue_name, fragment_name)


func cond(condition):#Shorhand
	return condition(condition)
func condition(condition):
	match self.thread.get_meta("execution_mode"):
		Director.ExecMode.Normal:
			if not self.thread.get_meta("execution_stack")[0].has('condition_stack'):
				self.thread.get_meta("execution_stack")[0].condition_stack = []
			if condition:
				condition = true
			else:
				condition = false
			self.thread.get_meta("execution_stack")[0].condition_stack.push_front(condition)
		Director.ExecMode.Forwarding:
			if self.thread.get_meta("execution_stack")[0].has('condition_stack'):
				condition = self.thread.get_meta("execution_stack")[0].condition_stack.pop_back()
			else:
				push_error("Condition stack misalignment.")
	return condition

func shard(shard_id:String, exact_id:bool=true, shard_library:Resource=null):
	if is_running():
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
			if is_running():
				if l:
					match l[0]:
						Agartha.ShardParser.LineType.SAY:
							say(l[1], l[2])
							step()
						Agartha.ShardParser.LineType.SHOW:
							show(l[1])
						Agartha.ShardParser.LineType.HIDE:
							hide(l[1])
						Agartha.ShardParser.LineType.PLAY:
							print("play %s" % l[1])
						Agartha.ShardParser.LineType.HALT:
							halt(l[1])
			else:
				break


################# Dialogue actions


func show(tag:String, parameters:Dictionary={}):
	if _is_preactive():
		Agartha.Show_Hide.call_deferred("action_show", tag, parameters)


func hide(tag:String, parameters:Dictionary={}):
	if _is_preactive():
		Agartha.Show_Hide.call_deferred("action_hide", tag, parameters)


func halt(priority:int):
	if _is_preactive():
		Agartha.Timeline.call_deferred("skip_stop", priority)


func say(character, text:String, parameters:Dictionary={}):
	if _is_preactive():
		Agartha.Say.call_deferred("action",character, text, parameters)


func ask(default_answer:String="", parameters:Dictionary={}):
	if _is_preactive():
		var return_pointer = [null] # Using a array here with a null entry as a makeshift pointer
		_ask_callback(return_pointer)
		Agartha.Ask.call_deferred("action", default_answer, parameters)
		step()
		return return_pointer[0]
	step()
func _ask_callback(return_pointer:Array):
	return_pointer[0] = yield(Agartha, "ask_return")


func menu(entries:Array, parameters:Dictionary={}):
	if _is_preactive():
		var return_pointer = [null] # Using a array here with a null entry as a makeshift pointer
		_menu_callback(return_pointer)
		Agartha.Menu.call_deferred("action", entries, parameters)
		step()
		return return_pointer[0]
	step()
func _menu_callback(return_pointer:Array):
	return_pointer[0] = yield(Agartha, "menu_return")
