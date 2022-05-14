tool
extends EditorPlugin

const AgarthaIcon = preload("res://addons/Agartha/editor/icon.svg")

const CodexEditor = preload("res://addons/Agartha/editor/CodexEditor/CodexEditor.tscn")


var codex_editor_instance
var base_control:Control

var codex:Codex setget set_codex

signal codex_set(new_library, old_library)
signal codex_changed()
signal codex_open_entry(entry_id)

func set_codex(new_codex:Codex):
	var old_codex = codex
	if old_codex and old_codex.is_connected("changed", self, 'save_codex'):
		old_codex.disconnect("changed", self, 'save_codex')
	new_codex.connect("changed", self, 'save_codex')
	codex = new_codex
	self.emit_signal('codex_set', new_codex, old_codex)

func save_codex(path:String=""):
	if codex:
		if not path:
			path = codex.resource_path
		if path:
			var error = ResourceSaver.save(path, codex)
			if error:
				push_error("Error when saving codex.")
	self.emit_signal('codex_changed')

### Administrative

func show():
	get_editor_interface().set_main_screen_editor(get_plugin_name())

func _enter_tree():
	base_control = get_editor_interface().get_base_control()
	
	codex_editor_instance = CodexEditor.instance()
	get_editor_interface().get_editor_viewport().add_child(codex_editor_instance)
	codex_editor_instance.init(self)
	
	make_visible(false)

func _exit_tree():
	if codex_editor_instance:
		codex_editor_instance.queue_free()

func has_main_screen():
	return true

func handles(object):
	if object is Codex:
		return true
	return false

func edit(object):
	if object is Codex:
		self.codex = object

func make_visible(visible):
	if codex_editor_instance:
		codex_editor_instance.visible = visible

func get_plugin_name():
	return "Codex"

func get_plugin_icon():
	return AgarthaIcon
