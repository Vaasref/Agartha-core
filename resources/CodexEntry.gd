tool
extends Resource
class_name CodexEntry


export var id:String
export var substitution_format:String
export var keywords:Dictionary
export var digest:String
export var description:String


func get_formated_substitution(matched_string:String, keyword:Array):
	return substitution_format.format({"matched": matched_string, "keyword":keyword, "id":id, "digest":digest})

func set_keywords(subs:String):
	subs = subs.to_lower()
	var re = RegEx.new()
	re.compile("(?:[\\p{L}\\p{N}]+[^;\\p{L}\\p{N}]*)+")
	var results = re.search_all(subs)
	re.compile("[\\p{L}\\p{N}]+")
	
	var new_set = {}
	
	for r in results:
		var keys = re.search_all(r.get_string(0))
		var step = new_set
		for i in keys.size():
			var key = keys[i].get_string(0)
			if not key in step:
				step[key] = {}
			step = step[key]
			if i + 1 == keys.size():
				step[""] = id
	keywords = new_set

func compose_keywords_string():
	return _compose_keywords_string(keywords)

func _compose_keywords_string(step:Dictionary, input:String = ""):
	var output = ""
	for k in step.keys():
		if output:
			output += "; "
		if k:
			output += _compose_keywords_string(step[k], input + k + " ")
		else:
			output += input
	return output
