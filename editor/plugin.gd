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
	re.compile("((res:\\/\\/.*\\.([a-z]+))(?:::[0-9]+)?)(?::([_a-zA-Z][_a-zA-Z0-9]+))?(?::([0-9]+))?")
	var result = re.search(shortcut)
	if result:
		var scene_path = result.get_string(2) if result.get_string(3) == "tscn" or result.get_string(3) == "scn" else ""
		var is_sub_resource:bool = result.get_string(3) == "tscn" and result.get_string(2) != result.get_string(1)
		var is_scene:bool = scene_path and not is_sub_resource
		var is_script:bool = result.get_string(3) == "gd"
		
		var resource_path = result.get_string(1) if is_sub_resource or is_script else ""

		var specified_line = int(result.get_string(5))
		var specified_function = result.get_string(4)
		var specifies_goto:bool = (specified_line or specified_function) and resource_path
		
		
		print(shortcut)
		for i in result.get_group_count():
			print("%d - '%s'" % [i, result.get_string(i)])
		
		if scene_path:
			get_editor_interface().open_scene_from_path(scene_path)
			if scene_path != get_tree().edited_scene_root.filename:
				yield(self, 'scene_changed')
		
		if resource_path:
			get_editor_interface().call_deferred('inspect_object', load(resource_path))
		
		if not is_sub_resource:
			get_editor_interface().call_deferred('select_file', resource_path)
		
		if specifies_goto:
			var line = specified_line
			if specified_function:
				line = get_function_line(resource_path, specified_function, line)
			get_editor_interface().get_script_editor().call_deferred('goto_line', line - 1)

func get_function_line(file_path:String, function_name:String, line_offset:int=0):
	var script:Script = load(file_path)
	var re = RegEx.new()
	re.compile("\\n(\\s*func\\s+%s\\()" % function_name)
	var result = re.search(script.source_code)
	var line = line_offset
	if result:
		line += script.source_code.count("\n", 0, result.get_end(1)) + 1
		print("Line %d    start at %d" % [line, result.get_start(1)])
	return line

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
	return "ShardLib"

func get_plugin_icon():
	return AgarthaIcon
