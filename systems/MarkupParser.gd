extends Node



func parse_text(text:String, store=null):
	var output = text
	if not store:
		store = Agartha.store
	
	output = hidden_escape(output)
	output = output.format(store.properties, "{_}")
	output = replace_line_feed(output)
	
	return output


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
