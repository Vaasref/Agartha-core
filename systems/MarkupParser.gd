extends Node

onready var expr = Expression.new()

func parse_text(text:String, store=null):
	var output = text
	if not store:
		store = Agartha.store
	
	output = hidden_escape(output)
	output = replace_store_variables(output, store)
	output = replace_line_feed(output)
	
	return output


func replace_store_variables(text:String, store):
	if store:
		var output = text
		var re = RegEx.new()
		re.compile("{(([a-zA-Z]|[a-zA-Z_][a-zA-Z_0-9]+)(\\.\\g<2>)*)}")
		var results = re.search_all(text)
		var offset = 0
		for m in results:
			var name = m.get_string(1)
			var value = m.get_string(0)
			if store.has(name):
				value = store.get(name)
			elif "." in name:
				var error = expr.parse(name)
				if error == OK:
					var result = expr.execute([], store, true)
					if not expr.has_execute_failed():
						value = result

			output = "%s%s%s" % [output.substr(0, offset + m.get_start(0)), value, output.substr(offset + m.get_end(0), -1)]
			offset = output.length() - text.length()
		return output
	else:
		return text


func replace_line_feed(text:String):
	var output = text
	var re = RegEx.new()
	re.compile("(?<!\\\\)\\\\n")
	var results = re.search_all(text)
	var offset = 0
	for m in results:
		output = "%s\n%s" % [output.substr(0, offset + m.get_start(0)), output.substr(offset + m.get_end(0), -1)]
		offset = output.length() - text.length()
	
	return output


func hidden_escape(text:String):
	var output = text
	var re = RegEx.new()
	re.compile("(?<!\\\\)\\\\([^n\\\\])")
	var results = re.search_all(text)
	var offset = 0
	for m in results:
		output = "%s\u200B%s\u200B%s" % [output.substr(0, offset + m.get_start(0)), m.get_string(1), output.substr(offset + m.get_end(0), -1)]
		offset = output.length() - text.length()
	
	return output
