tool
extends FileDialog

var ShardParser = preload("res://addons/Agartha/systems/ShardParser.gd")
var parser = ShardParser.new()

signal insert_shard_script(script)

var plugin:EditorPlugin



func init(_plugin):
	self.plugin = _plugin
	self.plugin.connect("shard_library_set", self, '_on_library_set')


func _on_library_set(new_library, _old_library):
	if new_library and not new_library.resource_path:
		open_save_as_dialog()


func insert_scripts(script_paths):
	var output = ""
	var f = File.new()
	for file in script_paths:
		if output:
			output += '\n'
		f.open(file, File.READ)
		output += f.get_as_text()
		if not output.ends_with('\n'):
			output += '\n'
		f.close()
	self.emit_signal('insert_shard_script', output)

func import_library(script_path, library_path):
	var f = File.new()
	
	f.open(script_path, File.READ)
	var file_text = f.get_as_text()
	if not file_text.ends_with('\n'):
		file_text += '\n'
	f.close()
	
	var new_library = ShardLibrary.new()
	var new_library_script = parser.parse_shard(file_text)
	new_library.save_script(new_library_script)
	
	var error = ResourceSaver.save(library_path, new_library)
	if error:
		push_error("Error when saving imported shard library.")

func export_library(script_path):
	if plugin.shard_library:
		var f = File.new()
		
		var script = plugin.shard_library.get_shards()
		var script_text = parser.compose_shard(script)
		if not script_text.ends_with('\n'):
			script_text += '\n'
		
		f.open(script_path, File.WRITE)
		f.store_string(script_text)
		f.close()


### On selected

func _ready():
	self.connect('file_selected', self, '_on_file_selected')
	self.connect('files_selected', self, '_on_files_selected')

var temp_import_input_path

func _on_file_selected(path):
	match current_mode:
		Mode.IMPORT_INPUT:
			temp_import_input_path = path
			self.call_deferred('_open_import_output_output')
		Mode.IMPORT_OUTPUT:
			import_library(temp_import_input_path, path)
		Mode.EXPORT:
			export_library(path)
		Mode.SAVE_LIBRARY_AS:
			plugin.shard_library.resource_path = path

func _on_files_selected(paths):
	if current_mode == Mode.INSERT:
		insert_scripts(paths)

### Modes

enum Mode{
	SAVE_LIBRARY_AS,
	INSERT,
	IMPORT_INPUT,
	IMPORT_OUTPUT,
	EXPORT
}
var current_mode:int

const shard_filter:Array = ["*.shrd ; Shard script"]
const library_filter:Array = ["*.tres ; Godot resource"]

func open_insert_dialog():
	self.mode = FileDialog.MODE_OPEN_FILES
	self.filters = shard_filter
	current_mode = Mode.INSERT
	self.window_title = "Select shard script file(s) to insert."
	self.popup_centered()

func open_import_input_dialog():
	self.mode = FileDialog.MODE_OPEN_FILE
	self.filters = shard_filter
	current_mode = Mode.IMPORT_INPUT
	self.window_title = "Select script file to import."
	self.popup_centered()

func _open_import_output_output():#This dialog is only used after the input
	self.mode = FileDialog.MODE_SAVE_FILE
	self.filters = library_filter
	current_mode = Mode.IMPORT_OUTPUT
	self.window_title = "Save imported library as ..."
	self.popup_centered()

func open_export_dialog():
	if plugin.shard_library:
		self.mode = FileDialog.MODE_SAVE_FILE
		self.filters = shard_filter
		current_mode = Mode.EXPORT
		self.window_title = "Export library to ..."
		self.popup_centered()

func open_save_as_dialog():
	self.mode = FileDialog.MODE_SAVE_FILE
	self.filters = library_filter
	current_mode = Mode.SAVE_LIBRARY_AS
	self.window_title = "Save library as ..."
	self.popup_centered()
