extends Node

var persistent_state:StoreState

var path:String


func init():
	var compress = Agartha.Settings.get("agartha/saves/compress_permanent_data_file")
	path = Agartha.Settings.get_user_path("agartha/paths/saves/permanent_data_folder", "persistent.tres", compress)
	var dir = Directory.new()
	if not dir.dir_exists(path.get_base_dir()):
		dir.make_dir_recursive(path.get_base_dir())
	persistent_state = StoreState.new()
	load_persistent()


func save_persistent():
	var error = ResourceSaver.save(path, persistent_state)
	if error != OK:
		push_error("Error when saving persistent date")


func load_persistent():
	if ResourceLoader.exists(path):
		persistent_state = ResourceLoader.load(path) as StoreState


func set_value(name, value):
	persistent_state.set(name, value)
	save_persistent()


func get_value(name, default=null):
	var output = persistent_state.get(name)
	if output and output is Object and output.has_method('duplicate'):
		output = output.duplicate(true)
	if output == null and default != null:
		output = default
	return output


func has_value(name):
	return persistent_state.has(name)
