extends Node


var preloaded_scenes:Dictionary = {}

var previous_scene:Node
var current_scene:Node
var current_scene_path:String

func change_scene(scene_id, auto_start_dialogue:bool=true, reload_scene:bool=false):
	if current_scene_path == scene_id:
		return false
	var new_scene = get_scene(scene_id)
	
	if new_scene is String:
		return false
	if not reload_scene and new_scene and new_scene.resource_path == current_scene_path:
		return false
	
	if Agartha.stage:
		if new_scene:
			_set_scene(new_scene.instance(), new_scene.resource_path)
			if auto_start_dialogue:
				Agartha.start_dialogue("","")
		else:
			_set_scene(null, "")
		return true
	return false

func _set_scene(scene:Node, scene_path):
	clear_stage()
	previous_scene = current_scene
	current_scene_path = scene_path
	current_scene = scene
	Agartha.store.set("_scene", scene_path)
	if scene:
		Agartha.stage.add_child(scene)
		Agartha.emit_signal('scene_changed', current_scene.name)
	else:
		Agartha.emit_signal('scene_changed', "")

func clear_stage():
	if Agartha.stage:
		for c in Agartha.stage.get_children():
			Agartha.stage.remove_child(c)

func get_scene(scene_id):
	if scene_id == null:
		return null
	elif scene_id in preloaded_scenes:
		return preloaded_scenes[scene_id]
	elif scene_id.is_abs_path():
		if scene_id.get_extension() == "tscn":
			load_scene(scene_id, scene_id, true)
			return preloaded_scenes[scene_id]
		else:
			push_error("Trying to change scene using an incorrect path. [%s]" % scene_id)
			return "error"
	else:
		push_error("Trying to change scene using and invalid alias. [%s]" % scene_id)
		return "error"


func init():
	var aliases = Agartha.Settings.get("agartha/paths/scenes/scene_aliases")
	var scenes:Dictionary = {}
	
	if aliases:
		for k in aliases.keys():
			if aliases[k] is PackedScene:
				scenes[k] = aliases[k]
			elif aliases[k] is String:
				if aliases[k].is_abs_path() and aliases[k].get_extension() == "tscn":
					scenes[k] = aliases[k]
	lazy_preload_scenes(scenes)


func lazy_preload_scenes(scenes):
	for k in scenes.keys():
		if scenes[k] is PackedScene:
			preloaded_scenes[k] = scenes[k]
			preloaded_scenes[scenes[k].resource_path] = preloaded_scenes[k]
		elif scenes[k] is String:
			self.call_deferred("load_scene", k, scenes[k])


func load_scene(alias:String, path:String, signal_loading:bool=false):
	if alias in preloaded_scenes:
		if not path in preloaded_scenes:
			push_error("Trying to use the alias '%s' for multiple scenes. [%s, %s]" % [alias, path,  preloaded_scenes[alias].resource_path])
	else:
		if path in preloaded_scenes:
			preloaded_scenes[alias] = preloaded_scenes[path]
		else:
			if signal_loading:
				Agartha.emit_signal("loading", NAN)
			var scene = ResourceLoader.load(path, "PackedScene")
			if scene:
				preloaded_scenes[alias] = scene
				preloaded_scenes[preloaded_scenes[alias].resource_path] = preloaded_scenes[alias]
				if signal_loading:
					Agartha.emit_signal("loading", 1)

