extends Node

var save_folder_path:String
var save_extension:String

var stack_size_max:int = 5

var state_stack:Array = []
var current_state_id:int = 0
var current_state:Array = []

func init(default_state=null):
	stack_size_max = Agartha.Settings.get("agartha/timeline/maximum_rollback_steps")
	var compress_saves = Agartha.Settings.get("agartha/saves/compress_savefiles")
	if compress_saves:
		save_extension = ".res"
	else:
		save_extension = ".tres"
	save_folder_path = Agartha.Settings.get_user_path("agartha/paths/saves/saves_folder")
	if default_state:
		current_state = [default_state.duplicate(), null]
	else:
		current_state = [StoreState.new(), null]
	state_stack.push_front(current_state)
	finish_step()# Using this function here for its semantic


func store_current_state():
	if not state_stack or not state_stack[0][0]:
		push_warning("Store not initialized.")
		init()
		return

	prune_front_stack()
	state_stack[0] = current_state
	var passed_state = [state_stack[0][0].duplicate(), state_stack[0][1].duplicate()]
	state_stack.insert(1, passed_state)
	prune_back_stack()


func finish_step():
	current_state[1] = current_state[0].duplicate()#Old origin replaced by previous working state


func restore_state(id:int, post_step:bool=false):
	if id < 0 and id >= state_stack.size():
		push_warning("Invalid store state ID : %s" % id)
		return
	if post_step:
		current_state = [state_stack[id][1].duplicate(), state_stack[id][1].duplicate()]#Restore from the origin
	else:
		current_state = [state_stack[id][0].duplicate(), state_stack[id][1].duplicate()]#Restore as stored
	current_state_id = id


func get_current_state():
	if current_state[0]:
		return current_state[0]

func get_current_state_origin():
	if current_state[1]:
		return current_state[1]


func prune_front_stack():
	state_stack = state_stack.slice(current_state_id, stack_size_max - 1)
	current_state_id = 0


func prune_back_stack():
	state_stack = state_stack.slice(0, stack_size_max - 1)





############## Saving and Loading

func save_store(save_filename:String, save_name:String="", save_image:Image=null):
	var save = StoreSave.new()

	save.name = save_name
	save.init_date()

	save.state_stack = self.state_stack
	save.current_state = self.current_state

	save.init_compatibility_features()

	if not save_image:
		save_image = get_tree().get_root().get_texture().get_data()
		save_image.flip_y()
	save.encoded_image = save.encode_image(save_image)

	var path = (save_folder_path + save_filename).get_basename() + save_extension
	
	var flags = 0
	if Agartha.Settings.get("agartha/saves/compress_savefiles"):
			flags += ResourceSaver.FLAG_COMPRESS
	
	if ResourceSaver.save(path, save, flags) != OK:
		push_error("Error when saving '%s'" % save_filename)


func load_store(save):
	if save is String:
		var path:String
		if save.is_rel_path():
			path = save_folder_path + save
		elif save.is_abs_path():
			path = save
		elif save.is_valid_filename():
			path = save
		if path:
			path = path.get_basename() + save_extension
			save = load(path) as StoreSave

	var ok = check_save_compatibility(save)

	if not ok:
		print("Save loading aborted.")
		return

	self.state_stack = []
	for s in save.state_stack:
		self.state_stack.append([s[0].duplicate(), s[1].duplicate()])

enum COMPATIBILITY_ERROR{
	NO_ERROR,
	NOT_SAVE,
	GAME_VERSION,
	DIFF_SCRIPT_COMP_CODE,
	DIFF_COMP_CODE
}

func check_save_compatibility(save, push_errors:bool=true):
	var error = COMPATIBILITY_ERROR.NO_ERROR
	
	if save and save is StoreSave:
		if save.game_version != Agartha.Settings.get("agartha/application/game_version") and not Agartha.Settings.get("agartha/saves/compatibility/load_on_different_game_version"):
			push_error("Save is not compatible : different game version")
			error = COMPATIBILITY_ERROR.GAME_VERSION
		if save.save_script_compatibility_code != save.get_script_compatibility_code() and not Agartha.Settings.get("agartha/saves/compatibility/force_load_on_different_storesave_version"):
			push_error("Save is not compatible : different script compatibility code")
			error = COMPATIBILITY_ERROR.DIFF_SCRIPT_COMP_CODE
		if save.save_compatibility_code != Agartha.Settings.get("agartha/saves/compatibility/compatibility_code"):
			push_error("Save is not compatible : different compatibility code")
			error = COMPATIBILITY_ERROR.DIFF_COMP_CODE
	else:
		push_error("File given is not a save file.")
		error = COMPATIBILITY_ERROR.NOT_SAVE
	
	return error
