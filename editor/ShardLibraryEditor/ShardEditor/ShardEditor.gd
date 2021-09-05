tool
extends TextEdit

var plugin:EditorPlugin
var ShardParser = preload("res://addons/Agartha/systems/ShardParser.gd")
var parser = ShardParser.new()

signal script_error(error)
signal update_shortcuts(shortcuts)
signal update_cursor(cursor_line, cursor_column)


func init(_plugin):
	self.plugin = _plugin
	self.plugin.connect("shard_library_set", self, '_on_library_set')
	self.plugin.connect("shard_library_changed", self, '_on_library_changed')
	self.plugin.connect('shard_library_open_shard', self, '_on_open_shard')
	update_colors()

func _on_library_set(new_library, old_library):
	self.text = ""


func _on_library_changed():
	pass


func update_colors():
	self.clear_colors()
	self.add_color_region("@", "@", Color.goldenrod)
	self.add_color_region(":", ":", Color.mediumorchid)
	self.add_color_region("\"", "\"", Color.yellowgreen)
	self.add_color_region("#", "", Color.indianred)
	self.add_keyword_color("show", Color.lightskyblue)
	self.add_keyword_color("hide", Color.lightskyblue)
	self.add_keyword_color("play", Color.palegreen)
	self.add_keyword_color("halt", Color.plum)


func _on_visibility_changed():
	var script = parser.parse_shard(self.text)
	update_text(script)


func _on_text_changed():
	var script = parser.parse_shard(self.text)
	update_text(script)


func update_text(script):
	var error = false
	self.emit_signal("script_error", "")#Reset the error display
	update_colors()
	var shard_started = false
	var shard_id_list = []
	var shortcuts = {}
	var line = 1
	for l in script:
		if l:
			if not shard_started and l[0] != ShardParser.LineType.SHARD_ID:
				error = "Shard Script Error: shards must start with a Shard_ID. Line %d" % line
				self.emit_signal("script_error", error)
			match l[0]:
				ShardParser.LineType.ERROR:
					self.add_color_region(self.get_line(line-1), "", Color.crimson, true)
					if l.size() == 1:
						error = "Shard Script Error: syntax error line %d." % line
					else:
						error = "Shard Script Error: invalid '%s' syntax line %d." % [ShardParser.LineType_names[l[1]] ,line]
					self.emit_signal("script_error", error)
				ShardParser.LineType.SAY:
					if l[1]:
						self.add_keyword_color(l[1], Color.palevioletred)
				ShardParser.LineType.SHOW:
					for w in l[1].split(" "):
						if not w.is_valid_integer() and  not self.has_keyword_color(w):
							self.add_keyword_color(w, Color.paleturquoise)
				ShardParser.LineType.HIDE:
					for w in l[1].split(" "):
						if not w.is_valid_integer() and  not self.has_keyword_color(w):
							self.add_keyword_color(w, Color.paleturquoise)
				ShardParser.LineType.PLAY:
					for w in l[1].split(" "):
						if not w.is_valid_integer() and  not self.has_keyword_color(w):
							self.add_keyword_color(w, Color.paleturquoise)
				ShardParser.LineType.SHARD_ID:
					shard_started = true
					if l[1] in shard_id_list:
						error = "Shard Script Error: shard_id '%s' used twice." % [l[1]]
						self.emit_signal("script_error", error)
					else:
						shard_id_list.append(l[1])
				ShardParser.LineType.SHORTCUT:
					shortcuts[l[1]] = true
		line += 1
	self.emit_signal("update_shortcuts", shortcuts.keys())
	return error


func _on_open_shard(shard_id):
	if plugin.shard_library:
		var shard = plugin.shard_library.get_shards(shard_id)
		if shard:
			if shard is String:
				self.text = shard
			else:
				self.text = parser.compose_shard(shard)
				update_text(shard)
		else:
			self.text = ":%s:\n" % shard_id


func _on_save_button_pressed():
	var script = parser.parse_shard(self.text)
	var error = update_text(script)
	if error:
		push_error(error)
	else:
		if plugin.shard_library:
			plugin.shard_library.save_script(script)
		else:
			var new_library = ShardLibrary.new()
			new_library.save_script(script)
			plugin.shard_library = new_library


func can_drop_data(position, data):
	if data is Dictionary and data.type == "files":
		return true
	return false


func drop_data(position, data):
	var line = self.cursor_get_line()
	
	self.cursor_set_line(self.cursor_get_line() + 1)
	self.cursor_set_column(0)

	for file in data.files:
		line += 1
		self.insert_text_at_cursor("\t@%s@\n" % file)
	
	self.cursor_set_line(self.cursor_get_line() - 1)
	self.cursor_set_column(1000)#If you have a file path longer than that you probably need a(an other) psychiatrist
	self.grab_focus()


func _on_cursor_changed():
	self.emit_signal('update_cursor', self.cursor_get_line(), self.cursor_get_column())


func _on_insert_shard_script(script_text):
	self.text = script_text
	var script = parser.parse_shard(self.text)
	update_text(script)
