extends Node
class_name Director

func init():
	if current_dialogue_thread:
		pass
	pass


const dialogue_list:Dictionary = {}

func declare_dialogue(dialogue_path:String, dialogue:Node):
	print("Declaring %s    %s" % [dialogue, dialogue_path])
	dialogue_list[dialogue_path] = dialogue

func remove_dialogue(dialogue_path:String):
	print("Removing %s" % [dialogue_path])
	dialogue_list.erase(dialogue_path)

func clear_dialogue_list():
	while not dialogue_list.empty():
		var k = dialogue_list.keys()[0]
		dialogue_list[k].queue_free()
		dialogue_list.erase(k)

func get_dialogue_path(dialogue_name:String, push_errors:bool=true, push_warnings:bool=false):
	var dialogue_path = ""
	if dialogue_name in dialogue_list:
		dialogue_path = dialogue_name
	elif dialogue_name:
		for k in dialogue_list.keys():
			if k.ends_with(dialogue_name):
				dialogue_path = k
				break
		if not dialogue_path and push_errors:
			push_error("Director: No dialogue named '%s' found." % dialogue_name)
	else:
		for k in dialogue_list.keys():
			if dialogue_list[k].auto_start:
				dialogue_path = k
				break
		if not dialogue_path and push_warnings:
			push_warning("Director: No auto-start Dialogue found.")
	
	return dialogue_path


func preprocess_dialogues(scene:Node):
	scene.propagate_call('_preprocess')

func preprocess_dialogue(dialogue):
	print("Preprocessing '%s'" % dialogue.name)
	var script:String = dialogue.get_script().source_code
	var output
	#print(script)
	var re = RegEx.new()
	var error:String = ""
	re.compile("extends Dialogue")## Make that more sturdy
	script = re.sub(script, "extends ProcessedDialogue")
	#print(script)
	re.compile("\\#\\@fragment[\\n\\r]+func ([a-z_A-Z]+)\\(()\\)")
	var res = re.search_all(script)
	output = script
	for r in res:
		var offset = output.length() - script.length()
		output = output.insert(offset + r.get_start(2), "thread:Thread")
	script = output

	for m in preprocessed_methods:
		re.compile("(?<![^ \\t])(self\\.)?%s\\((\\))?" % m)
		output = script
		for r in re.search_all(script):
			var offset = output.length() - script.length()
			if r.get_string(2):
				output = output.insert(offset + r.get_start(2), "thread")
			else:
				output = output.insert(offset + r.get_end(0), "thread, ")
		script = output 
	
	var default_fragment:String = dialogue.default_fragment
	var auto_start:bool = dialogue.auto_start
	
	var new_script = dialogue.get_script().duplicate(true)
	new_script.source_code = script
	new_script.reload()
	new_script.take_over_path(dialogue.get_script().resource_path)
	dialogue.set_script(new_script)
	
	
	dialogue.default_fragment = default_fragment
	dialogue.auto_start = auto_start
	print( dialogue.get_script().source_code)
	
	pass


const preprocessed_methods:Array = [
	"step",
	"_wait_semaphore",
	"_is_preactive",
	"ia",
	"is_active",
	"is_running",
	"is_exitting",
	"call_fragment",
	"jump",
	"cond",
	"condition",
	"shard",
	"show",
	"hide",
	"halt",
	"say",
	"ask",
	"menu",
]


## Store related

func _store(state):
	if current_dialogue_thread:
		state.set('_dialogue_execution_stack', current_dialogue_thread.get_meta("execution_stack").duplicate(true))
		state.set('_dialogue_name', current_dialogue_thread.get_meta("dialogue_name"))
	pass

func _restore(state):
	if state.has('_dialogue_name') and state.has('_dialogue_execution_stack'):
		restore_dialogue(state.get('_dialogue_name'), state.get('_dialogue_execution_stack'))

### Thread handling

enum ExecMode {
	Normal,
	Forwarding,
	Exitting
}
var current_dialogue_thread:Thread


func start_dialogue(dialogue_name:String, fragment_name:String):
	print("Starting dialogue '%s'  '%s'" % [dialogue_name, fragment_name])
	
	dialogue_name = get_dialogue_path(dialogue_name)
	if not dialogue_name:
		return
	var dialogue = dialogue_list[dialogue_name]
	
	var fragment:String = fragment_name
	if not fragment_name:
		if dialogue.default_fragment:
			fragment = dialogue.default_fragment
		else:
			push_error("Director: No default fragment set for Dialogue '%s'." % dialogue_name)
			return
	
	if not dialogue.has_method(fragment):
		push_error("Director: No fragment named '%s' in Dialogue '%s'." % [fragment_name, dialogue_name])
		return
	
	var execution_stack = [{'fragment_name': fragment}]
	Agartha.store.set('_dialogue_execution_stack', execution_stack)
	Agartha.store.set('_dialogue_name', dialogue_name)
	
	exit_dialogue()
	var thread = Thread.new()
	current_dialogue_thread = thread ## Maybe a mutex here
	thread.start(self, '_execution_loop', [thread, dialogue, dialogue_name, execution_stack])


func restore_dialogue(dialogue_name:String, execution_stack:Array):
	dialogue_name = get_dialogue_path(dialogue_name)
	if not dialogue_name:
		return
	var dialogue = dialogue_list[dialogue_name]

	exit_dialogue()
	var thread = Thread.new()
	current_dialogue_thread = thread ## Maybe a mutex here
	thread.start(self, '_execution_loop', [thread, dialogue, dialogue_name, execution_stack.duplicate(true)])


func _execution_loop(args):
	var thread = args[0]
	var dialogue = args[1]
	var execution_stack = args[3]
	thread.set_meta("execution_stack", execution_stack)
	thread.set_meta("execution_mode", ExecMode.Normal)
	thread.set_meta("dialogue_name", args[2])
	thread.set_meta("dialogue", dialogue)
	
	while execution_stack and thread.get_meta("execution_mode") != ExecMode.Exitting:
		if execution_stack[0].has('step_counter'):
			if dialogue.has_method(execution_stack[0]['fragment_name']):
				thread.set_meta("execution_mode", ExecMode.Forwarding)
				
				execution_stack[0]['target_step'] = execution_stack[0]['step_counter']
				execution_stack[0]['step_counter'] = 0
				
				dialogue.call(execution_stack[0]['fragment_name'], thread)
				execution_stack.pop_front()
			else:
				push_error("Invalid fragment name '%s' in Dialogue '%s'" % [execution_stack[0]['fragment_name'], args[2]])
				pass
		else:
			var fragment_name = execution_stack.pop_front()['fragment_name']
			dialogue.call_fragment(thread, fragment_name)
	self.call_deferred('_end_dialogue_thread', thread)

func _end_dialogue_thread(thread):
	if thread and thread.is_active():
		thread.wait_to_finish()
		if thread == current_dialogue_thread:
			current_dialogue_thread = null
			Agartha.store.set('_dialogue_execution_stack', null)
			Agartha.store.set('_dialogue_name', null)


func _step():
	if current_dialogue_thread and current_dialogue_thread.has_meta("semaphore"):
		current_dialogue_thread.get_meta("semaphore").post()


func exit_dialogue():
	if current_dialogue_thread:
		current_dialogue_thread.set_meta("execution_mode", ExecMode.Exitting)
		if current_dialogue_thread.has_meta("semaphore"):
			current_dialogue_thread.get_meta("semaphore").post()
