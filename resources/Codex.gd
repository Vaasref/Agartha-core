tool
extends Resource
class_name Codex


export var entries:Dictionary = {}

var keywords_super_set:Dictionary = {} setget ,get_keywords_super_set


func save_entry(entry:CodexEntry):
	if entry and entry.id:
		var id = entry.id
		entries[id] = entry
		self.emit_signal("changed")
	update_super_set(entry)


func get_tree():
	return get_branch("")


func get_branch(branch_id):
	var output = []
	var ids = get_children_ids(branch_id)
	var branches = {}
	for id in ids:
		if id == branch_id:
			continue
		var child_branch_id = id.trim_prefix(branch_id).split("_", false)[0]
		if branch_id:
			child_branch_id = "%s_%s" % [branch_id, child_branch_id]
		branches[child_branch_id] = true
	for b in branches.keys():
		branches[b] = get_branch(b)
	return branches


func get_children_ids(branch_id, trimmed:bool = false):
	var output = []
	for k in entries.keys():
		if k.begins_with(branch_id):
			if trimmed:
				output.append(k.trim_prefix(branch_id))
			else:
				output.append(k)
	return output

static func parse_text(text:String):
	var input:String = text.to_lower()
	var re = RegEx.new()
	re.compile("[\\p{L}\\p{N}]+")
	var results = re.search_all(input)
	
	var parsed_text = []
	for r in results:
		parsed_text.append([r.get_start(0), r.get_string(0), r.get_end(0)])
	return parsed_text

static func match_keywords(super_set:Dictionary, parsed_text:Array):
	var w = 0
	var matched_keywords = []
	while w < parsed_text.size():
		if parsed_text[w][1] in super_set: #If first word match try to match as much as possible
			var keyword = [parsed_text[w]]
			var step = super_set[parsed_text[w][1]]
			var i = w + 1
			while i < parsed_text.size() and parsed_text[i][1] in step:
				keyword.append(parsed_text[i])
				step = step[parsed_text[i][1]]
				i += 1
			if "" in step: #If the text end is reached or the current word doesn't match
				matched_keywords.append([keyword, step[""]])
			w = i #Offset the current word counter to continue from the current word on
		else:
			w += 1
	return matched_keywords

func apply_to(text:String):
	var parsed_text = parse_text(text)
	var matched_keywords = match_keywords(self.keywords_super_set, parsed_text)
	
	var output:String = ""
	var last_end:int = 0
	for keyword in matched_keywords:
		var words = keyword[0]
		var entry:CodexEntry = entries[keyword[1]]
		var start = words[0][0]
		var end = words[-1][2]
		var matched_text = text.substr(start, end - start)
		output += text.substr(last_end, start - last_end) + entry.get_formated_substitution(matched_text, words)
		last_end = end
	output += text.substr(last_end)
	
	return output

func get_keywords_super_set():
	if not keywords_super_set:
		build_keywords_super_set()
	return keywords_super_set

func update_super_set(entry:CodexEntry):
	if not keywords_super_set:
		build_keywords_super_set()
	else:
		_build_keywords_super_set(keywords_super_set, entry.keywords)

func build_keywords_super_set():
	var new_super_set = {}
	for e in entries.values():
		_build_keywords_super_set(new_super_set, e.keywords)
	keywords_super_set = new_super_set

static func _build_keywords_super_set(super_set:Dictionary, step:Dictionary, path:String = ""):
	for k in step.keys():
		if k:
			_build_keywords_super_set(super_set, step[k], path + " " + k)
		else:
			_set_in_nested_dictionary(super_set, path.split(" ", false), step[k])# step[k] should be ""

static func _set_in_nested_dictionary(nested_dict:Dictionary, path:Array, value:String):
	var step = nested_dict
	for p in path:
		if not p in step:
			step[p] = {}
		step = step[p]
	step[""] = value

static func _get_in_nested_dictionary(nested_dict:Dictionary, path:Array):
	var step = nested_dict
	for p in path:
		if not p in step:
			return null
		step = step[p]
	if "" in step:
		return step[""]
	return null


func get_keyword_dictionary():
	return _get_keyword_dictionary() #Hiding the recursive function to get cleaner code completion

func _get_keyword_dictionary(step:Dictionary = self.keywords_super_set, path:String = "", output:Dictionary = {}):
	if "" in step:
		output[path] = step[""]
	if path:
		path = path + " "
	for k in step.keys():
		if step[k] is Dictionary:
			_get_keyword_dictionary(step[k], path + k, output)
	return output
