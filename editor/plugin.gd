tool
extends EditorPlugin

const AgarthaIcon = preload("res://addons/Agartha/editor/icon.svg")

const ShardLibraryEditor = preload("res://addons/Agartha/editor/ShardLibraryEditor/ShardLibraryEditor.tscn")

var shard_library_editor_instance


func _enter_tree():
	shard_library_editor_instance = ShardLibraryEditor.instance()
	shard_library_editor_instance.base_control = get_editor_interface().get_base_control()
	shard_library_editor_instance.connect("use_shortcut", self, "_on_use_shortcut")
	get_editor_interface().get_editor_viewport().add_child(shard_library_editor_instance)
	
	make_visible(false)

func _on_use_shortcut(shortcut:String):
	var re = RegEx.new()
	re.compile("((res:\\/\\/.*\\.([a-z]+))(::[0-9]+)?)(?::([0-9]+))?")
	var result = re.search(shortcut)
	if result:
		var need_scene:bool = result.get_string(3) == "tscn" or result.get_string(3) == "scn"
		var is_scene_object:bool = need_scene and result.get_string(4)
		var is_scene:bool = need_scene and not is_scene_object
		
		if need_scene:
			get_editor_interface().open_scene_from_path(result.get_string(2))
			yield(self, 'scene_changed')
		
		if not is_scene:
			get_editor_interface().call_deferred('inspect_object', load(result.get_string(1)))
		
		if not is_scene_object:
			get_editor_interface().call_deferred('select_file', result.get_string(1))
		
		if result.get_string(5) and (result.get_string(3) != "gd" or is_scene_object):
			get_editor_interface().get_script_editor().call_deferred('goto_line', int(result.get_string(5))-1)


func _exit_tree():
	if shard_library_editor_instance:
		shard_library_editor_instance.queue_free()


func has_main_screen():
	return true

func handles(object):
	if object is ShardLibrary:
		return true
	return false
	
func edit(object):
	if object is ShardLibrary:
		shard_library_editor_instance.open_library(object)

var hidden_list:Array

func make_visible(visible):
	if shard_library_editor_instance:
		#if visible:
			#hidden_list = []
			#for c in get_editor_interface().get_editor_viewport().get_children():
			#	if c.get('visible') is bool and c.visible:
					#hidden_list.append(c)
			#		c.visible = false
		#else:
			#for c in hidden_list:
			#	c.visible = true
			#hidden_list = []
		shard_library_editor_instance.visible = visible


func get_plugin_name():
	return "Agartha"


func get_plugin_icon():
	return AgarthaIcon
