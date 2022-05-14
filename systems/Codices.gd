extends Node

var codices:Array = []
var global_keyword_set:Dictionary = {} setget ,get_global_keyword_set

func init():
	var path = Agartha.Settings.get("agartha/paths/codices_folder")
	codices = get_codices(path)
	if not codices:
		push_warning("No codex got loaded, check the folder path.")

func get_codices(path):
	var output = []
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name == "." or file_name == "..":
				file_name = dir.get_next()
				continue
			file_name = path + file_name
			if dir.current_is_dir():
				output.append_array(get_codices(file_name))
			elif ResourceLoader.exists(file_name):
				var res = ResourceLoader.load(file_name) as Codex
				if res:
					output.append(res)
			file_name = dir.get_next()
	else:
		push_error("Selected directory for codices doesn't exists.")
	return output

func get_global_keyword_set():
	if not global_keyword_set:
		build_global_keyword_set()
	return global_keyword_set

func build_global_keyword_set():
	var new_global_set = {}
	for c in codices:
		Codex._build_keywords_super_set(new_global_set, c.get_keywords_super_set())
	global_keyword_set = new_global_set

func apply_to(text:String):
	var parsed_text = Codex.parse_text(text)
	var matched_keywords = Codex.match_keywords(self.global_keyword_set, parsed_text)
	
	var output:String = ""
	var last_end:int = 0
	for keyword in matched_keywords:
		var words = keyword[0]
		var entry:CodexEntry = get_codex_entry(keyword[1])
		var start = words[0][0]
		var end = words[-1][2]
		var matched_text = text.substr(start, end - start)
		output += text.substr(last_end, start - last_end) + entry.get_formated_substitution(matched_text, words)
		last_end = end
	output += text.substr(last_end)
	return output

func get_codex_entry(id:String):
	for c in codices:
		if id in c.entries:
			return c.entries[id]
	return null
