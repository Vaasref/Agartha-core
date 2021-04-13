extends Node


var compress_saves:bool
var save_extension:String
var save_folder_path:String

func init():
	compress_saves = Agartha.Settings.get("agartha/saves/compress_savefiles")
	if compress_saves:
		save_extension = ".res"
	else:
		save_extension = ".tres"
	save_folder_path = Agartha.Settings.get_user_path("agartha/paths/saves/saves_folder")


func get_save_array(pattern:String, to:int=1, from:int=0): #pattern must be a String to format
	var output = []
	if to < from:
		to = from + 1
	var file:File = File.new()
	for i in range(from, to):
		var path = get_save_path(pattern % i)
		output.append(null)
		if file.file_exists(path):
			var save = ResourceLoader.load(path, "Resource", true).duplicate()
			if check_save_compatibility(save, false) != COMPATIBILITY_ERROR.NOT_SAVE:
				output[i] = save
	return output


func get_save_path(save_filename:String):
	save_filename = save_filename.get_basename().get_file() #Strips extension and folders
	return save_folder_path.plus_file(save_filename + save_extension)


func save(save_filename:String, save_name:String="", save_image:Image=null, set_latest:bool=true):
	var save = Agartha.Store.get_store_save(save_name, save_image)
	
	var path = get_save_path(save_filename) 
	
	var flags = ResourceSaver.FLAG_CHANGE_PATH
	if compress_saves:
			flags += ResourceSaver.FLAG_COMPRESS
	
	if ResourceSaver.save(path, save, flags) != OK:
		push_error("Error when saving '%s'" % save_filename)
	else:
		if set_latest:
			Agartha.Persistent.set("_latest_save", save_filename)
		Agartha.emit_signal("saved")


func load(save):
	if save is String:
		save = ResourceLoader.load(get_save_path(save), "Resource", true) as StoreSave

	if check_save_compatibility(save) == COMPATIBILITY_ERROR.NO_ERROR:
		Agartha.Timeline.load_save(save)
	else:
		print("Save loading aborted.")


func rename(save, new_name):
	if save is String:
		save = ResourceLoader.load(get_save_path(save), "Resource", true) as StoreSave
	
	if check_save_compatibility(save, false) == COMPATIBILITY_ERROR.NO_ERROR:
		save.name = new_name
		var flag = 0
		if compress_saves:
			flag = ResourceSaver.FLAG_COMPRESS
		if ResourceSaver.save(save.resource_path, save, flag) != OK:
			push_error("Error when renaming '%s'" % save.resource_path)
		else:
			Agartha.emit_signal("saved")


func quick_save():
	var max_slot = Agartha.Settings.get("agartha/saves/quick_save_slots")
	var file = File.new()
	
	var empty_slots = []
	var slot_dates = []
	
	var pattern = "quick_%d"
	for i in max_slot:
		var path = get_save_path(pattern % i)
		slot_dates.append(9223372036854775807)
		if file.file_exists(path):
			slot_dates[i] = file.get_modified_time(path)
		else:
			empty_slots.append(pattern % i)
	
	if empty_slots:
		save(empty_slots[0])
	else:
		var oldest_slot = 0
		for i in slot_dates.size():
			if slot_dates[oldest_slot] > slot_dates[i]:
				oldest_slot = i
		print("Oldest is %s" % (pattern % oldest_slot))
		save(pattern % oldest_slot)


func quick_load():
	var max_slot = Agartha.Settings.get("agartha/saves/quick_save_slots")
	var file = File.new()

	var slot_dates = {}
	
	var pattern = "quick_%d"
	for i in max_slot:
		var path = get_save_path(pattern % i)
		if file.file_exists(path):
			slot_dates[pattern % i] = file.get_modified_time(path)
	
	if slot_dates:
		var latest_slot = pattern % 0
		for k in slot_dates.keys():
			if slot_dates[latest_slot] < slot_dates[k]:
				latest_slot = k
		print("Quickloading %s" % latest_slot)
		self.load(latest_slot)


func auto_save():
	var max_slot = Agartha.Settings.get("agartha/saves/auto_save_slots")
	var dir = Directory.new()
	
	var empty_slots = []
	var slot_dates = []
	
	var pattern = "auto_%d"
	for i in range(1, max_slot):
		var path = get_save_path(pattern % (max_slot - i))
		if dir.file_exists(path):
			dir.copy(path, get_save_path(pattern % (max_slot - i + 1)))
	save(get_save_path("auto_0"), "", null, false)


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
			if push_errors:
				push_error("Save is not compatible : different game version")
			error = COMPATIBILITY_ERROR.GAME_VERSION
		if save.save_script_compatibility_code != save.get_script_compatibility_code() and not Agartha.Settings.get("agartha/saves/compatibility/force_load_on_different_storesave_version"):
			if push_errors:
				push_error("Save is not compatible : different script compatibility code")
			error = COMPATIBILITY_ERROR.DIFF_SCRIPT_COMP_CODE
		if save.save_compatibility_code != Agartha.Settings.get("agartha/saves/compatibility/compatibility_code"):
			if push_errors:
				push_error("Save is not compatible : different compatibility code")
			error = COMPATIBILITY_ERROR.DIFF_COMP_CODE
	else:
		if push_errors:
				push_error("File given is not a save file.")
		error = COMPATIBILITY_ERROR.NOT_SAVE
	
	return error
