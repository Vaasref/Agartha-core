tool
extends Node


var settings_list:Dictionary

func _ready():
	if Engine.editor_hint:
		init_properties()

func init():
	if not Engine.editor_hint:
		if Agartha.Persistent.has_value("_settings"):
			settings_list = Agartha.Persistent.get_value("_settings").duplicate(true)
		else:
			settings_list = {}


##Specialized getters

func get_user_path(property:String, filename:String="", tres_to_res:bool=true):
	var path_format:String
	if OS.has_feature("editor"):
		path_format = "res://%s"
	else:
		path_format = "user://%s"
	var path:String = get(property)
	path = path.trim_suffix("/") + "/"
	path = path.trim_prefix("user://").trim_prefix("res://")
	if filename:
		path = path + filename
		if tres_to_res and path.ends_with(".tres"):
			path = path.trim_suffix(".tres") + ".res"
	path = path_format % path
	return path


func get_parameter_list(property:String, value:Dictionary={}, other_default:Dictionary={}, concat_defaults:bool=true):
	if not concat_defaults:
		if value:
			return value.duplicate()
		elif other_default:
			return other_default.duplicate()
		else:
			return get(property).duplicate()
	else:
		var concat = {}
		for k in value.keys():
			concat[k] = value[k]

		if other_default:
			for k in other_default.keys():
				if not k in concat:
					concat[k] = other_default[k]

		if property:
			if property in settings_list:
				for k in settings_list[property].keys():
					if not k in concat:
						concat[k] = settings_list[property][k]
			if ProjectSettings.has_setting(property):
				var project_settings_default = ProjectSettings.get_setting(property)
				for k in project_settings_default.keys():
					if not k in concat:
						concat[k] = project_settings_default[k]

		return concat



## General purpose set/get

func get(property:String, default_value=null, default_override_settings:bool=true):
	if property in settings_list:
		return settings_list[property]

	elif default_override_settings and not default_value == null:
		return default_value

	elif ProjectSettings.has_setting(property):
		return ProjectSettings.get_setting(property)
	elif property in properties_infos:
		if properties_infos[property].has("hard_default"):
			return properties_infos[property].hard_default
		return properties_infos[property].default

	elif not default_override_settings and not default_value == null:
		return default_value
	return null


func set(property:String, value, save=true):
	if Engine.editor_hint:
		if ProjectSettings.has_setting(property) or ProjectSettings.property_get_revert(property):
			ProjectSettings.set_setting(property, value)
	else:
		settings_list[property] = value
		if save:
			update_persistent()


func reset(property:String, reset_project_settings:bool=false):
	if Engine.editor_hint:
		if reset_project_settings:
			if ProjectSettings.property_can_revert(property):
				ProjectSettings.set_setting(property, ProjectSettings.property_get_revert(property))
			else:
				ProjectSettings.set_setting(property, null)
	else:
		if property in settings_list:
			settings_list.erase(property)
			update_persistent()


func update_persistent():
	if not Engine.editor_hint and Agartha.Persistent:
		Agartha.Persistent.set_value("_settings", settings_list.duplicate(true))











## Following functions are not to be used after export

func init_properties():
	var property_info
	init_compatibility_code()
	print("Initializing Agartha settings.")
	_init_properties(properties_infos)
	ProjectSettings.set_order(properties_infos.keys()[0], 1)

func _init_properties(properties_infos:Dictionary):
	for k in properties_infos.keys():
		properties_infos[k].name = k
		_init_property(properties_infos[k])

func _init_property(property_info:Dictionary):
	if property_info.has("hard_default"):
		ProjectSettings.set_setting(property_info.name, property_info.hard_default)
	elif not ProjectSettings.has_setting(property_info.name):
		ProjectSettings.set_setting(property_info.name, property_info.default)
	ProjectSettings.add_property_info(property_info)
	ProjectSettings.set_initial_value(property_info.name, property_info.default)

func init_compatibility_code():
	print("Randomizing compatibility_code default")
	randomize()
	properties_infos["agartha/saves/compatibility/compatibility_code"]["default"] = str(randi()).md5_text().substr(0, 5)
	if not ProjectSettings.has_setting("agartha/saves/compatibility/compatibility_code"):
		ProjectSettings.set_setting("agartha/saves/compatibility/compatibility_code", str(randi()).md5_text().substr(0, 5))

const properties_infos:Dictionary = {
	"agartha/application/game_version": {
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_PLACEHOLDER_TEXT ,
		"hint_string": "Version number",
		"default": "0.0.0"
	},
	"agartha/application/agartha_version": {
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_NONE ,
		"default": "0.0.0",
		"hard_default": "0.0.0"
	},
	"agartha/timeline/maximum_rollback_steps": {
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "-1, 50, or_greater",
		"default": 10
	},
	"agartha/dialogues/skip_delay": {
		"type": TYPE_REAL,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.05, 0.2, or_greater",
		"default": 0.1
	},
	"agartha/dialogues/maximum_history_entry": {
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "-1, 100, or_greater",
		"default": 20
	},
	"agartha/dialogues/actions_default_parameters/show": {
		"type": TYPE_DICTIONARY,
		"hint": PROPERTY_HINT_NONE,
		"default": {}
	},
	"agartha/dialogues/actions_default_parameters/hide": {
		"type": TYPE_DICTIONARY,
		"hint": PROPERTY_HINT_NONE,
		"default": {}
	},
	"agartha/dialogues/actions_default_parameters/play": {
		"type": TYPE_DICTIONARY,
		"hint": PROPERTY_HINT_NONE,
		"default": {}
	},
	"agartha/dialogues/actions_default_parameters/say": {
		"type": TYPE_DICTIONARY,
		"hint": PROPERTY_HINT_NONE,
		"default": {}
	},
	"agartha/dialogues/actions_default_parameters/ask": {
		"type": TYPE_DICTIONARY,
		"hint": PROPERTY_HINT_NONE,
		"default": {}
	},
	"agartha/dialogues/actions_default_parameters/menu": {
		"type": TYPE_DICTIONARY,
		"hint": PROPERTY_HINT_NONE,
		"default": {}
	},
	"agartha/saves/quick_save_slots": {
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1, 20, or_greater",
		"default": 6
	},
	"agartha/saves/auto_save_slots": {
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1, 20, or_greater",
		"default": 10
	},
	"agartha/saves/compatibility/compatibility_code": {
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_NONE,
		"default": ""
	},
	"agartha/saves/compatibility/load_on_different_game_version": {
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"default": true
	},
	"agartha/saves/compatibility/force_load_on_different_storesave_version": {
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"default": false
	},
	"agartha/saves/compress_savefiles": {
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"default": true
	},
	"agartha/saves/compress_permanent_data_file": {
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"default": true
	},
	"agartha/paths/scenes/scene_aliases": {
		"type": TYPE_DICTIONARY,
		"hint": PROPERTY_HINT_NONE,
		"default": {},
	},
	"agartha/paths/saves/saves_folder": {
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR,
		"default": "res://saves/"
	},
	"agartha/paths/saves/permanent_data_folder": {
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR,
		"default": "res://saves/"
	},
	"agartha/paths/shard_libraries_folder": {
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR,
		"default": "res://shard_libraries/"
	},
	"agartha/paths/codices_folder": {
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR,
		"default": "res://codices/"
	},
	"agartha/export/strip_shard_libraries": {
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"default": true,
	},
	"autoload/Agartha": {
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_NONE,
		"default": "res://addons/Agartha/Agartha.tscn",
		"hard_default": "*res://addons/Agartha/Agartha.tscn",
	}
	}
