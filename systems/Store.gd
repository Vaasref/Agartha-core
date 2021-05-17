extends Node

var stack_size_max:int

var state_stack:Array
var current_state_id:int
var current_state:StoreState

func init(default_state=null):
	stack_size_max = Agartha.Settings.get("agartha/timeline/maximum_rollback_steps")
	if default_state:
		current_state = default_state.duplicate()
	else:
		current_state = StoreState.new()
	current_state_id = 0
	state_stack = [current_state]


func prepare_storing():
	if not state_stack or not state_stack[0]:
		push_warning("Store not initialized.")
		init()
		return

	prune_front_stack()
	state_stack[0] = current_state
	state_stack.insert(1, current_state.duplicate())
	prune_back_stack()


func restore_state(id:int):
	if id < 0 and id >= state_stack.size():
		push_warning("Invalid store state ID : %s" % id)
		return
	current_state = state_stack[id].duplicate()#Restore as stored
	current_state_id = id


func get_current_state():
	if current_state:
		return current_state


func prune_front_stack():
	state_stack = state_stack.slice(current_state_id, stack_size_max - 1)
	current_state_id = 0


func prune_back_stack():
	state_stack = state_stack.slice(0, stack_size_max - 1)





############## Saving and Loading

func get_store_save(save_name:String="", save_image:Image=null):
	var save = StoreSave.new()

	save.name = save_name
	save.init_date()

	save.state_stack = self.state_stack
	save.current_state = self.current_state
	save.current_state_id = self.current_state_id

	save.init_compatibility_features()

	if not save_image:
		save_image = get_tree().get_root().get_texture().get_data()
		save_image.flip_y()
	save.encoded_image = save.encode_image(save_image)

	return save


func restore_state_from_save(save):
	self.current_state_id = save.current_state_id
	self.current_state = save.current_state.duplicate()
	self.state_stack = []
	for s in save.state_stack: # TODO a deep duplicate might work here need to check that.
		self.state_stack.append(s.duplicate())
