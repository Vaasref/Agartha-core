tool
extends EditorPlugin

const AgarthaIcon = preload("res://addons/Agartha/editor/icon.svg")

const ShardLibraryEditor = preload("res://addons/Agartha/editor/ShardLibraryEditor/ShardLibraryEditor.tscn")
const ShardLibraryDock = preload("res://addons/Agartha/editor/ShardLibraryDock/ShardLibraryDock.tscn")


var shard_library_editor_instance
var shard_library_dock_instance

var base_control:Control

var shard_library:ShardLibrary setget set_shard_library
signal shard_library_set(new_library, old_library)
signal shard_library_changed()
signal shard_library_open_shard(shard_id)

func set_shard_library(new_library:ShardLibrary):
	var old_library = shard_library
	if old_library and old_library.is_connected("changed", self, 'save_shard_library'):
		old_library.disconnect("changed", self, 'save_shard_library')	
	new_library.connect("changed", self, 'save_shard_library')
	shard_library = new_library
	self.emit_signal('shard_library_set', new_library, old_library)

func save_shard_library(path:String=""):
	if shard_library:
		if not path:
			path = shard_library.resource_path
		if path:
			var error = ResourceSaver.save(path, shard_library)
			if error:
				push_error("Error when saving shard library.")
	self.emit_signal('shard_library_changed')

### Actions

func use_shortcut(shortcut:String):
	var re = RegEx.new()
	re.compile("((res:\\/\\/.*\\.([a-z]+))(::[0-9]+)?)(?::([0-9]+))?")
	var result = re.search(shortcut)
	if result:
		var need_scene:bool = result.get_string(3) == "tscn" or result.get_string(3) == "scn"
		var is_scene_object:bool = need_scene and result.get_string(4)
		var is_scene:bool = need_scene and not is_scene_object
		
		if need_scene:
			get_editor_interface().open_scene_from_path(result.get_string(2))
			if result.get_string(2) != get_tree().edited_scene_root.filename:
				yield(self, 'scene_changed')
		
		if not is_scene:
			get_editor_interface().call_deferred('inspect_object', load(result.get_string(1)))
		
		if not is_scene_object:
			get_editor_interface().call_deferred('select_file', result.get_string(1))
		
		if result.get_string(5) and (result.get_string(3) != "gd" or is_scene_object):
			get_editor_interface().get_script_editor().call_deferred('goto_line', int(result.get_string(5))-1)

func open_shard(shard_id:String):
	self.show()
	self.emit_signal('shard_library_open_shard', shard_id)


### Administrative

func show():
	get_editor_interface().set_main_screen_editor(get_plugin_name())

func _enter_tree():
	base_control = get_editor_interface().get_base_control()
	
	shard_library_editor_instance = ShardLibraryEditor.instance()
	get_editor_interface().get_editor_viewport().add_child(shard_library_editor_instance)
	shard_library_editor_instance.init(self)
	
	shard_library_dock_instance = ShardLibraryDock.instance()
	add_control_to_dock(DOCK_SLOT_LEFT_UL, shard_library_dock_instance)
	shard_library_dock_instance.init(self)
	
	make_visible(false)

func _exit_tree():
	if shard_library_editor_instance:
		shard_library_editor_instance.queue_free()
	if shard_library_dock_instance:
		shard_library_dock_instance.queue_free()

func has_main_screen():
	return true

func handles(object):
	if object is ShardLibrary:
		return true
	return false

func edit(object):
	if object is ShardLibrary:
		self.shard_library = object

func make_visible(visible):
	if shard_library_editor_instance:
		shard_library_editor_instance.visible = visible

func get_plugin_name():
	return "Agartha"

func get_plugin_icon():
	return AgarthaIcon
