tool
extends Node


enum LineType {
	ERROR,
	SHARD_ID,#aka label
	SHORTCUT,
	COMMENT,
	SAY,
	SHOW,
	HIDE,
	PLAY,
	HALT
}
const LineType_names:Array = ["Error", "Shard_ID", "Shortcut", "Comment", "Say", "Show", "Hide", "Play", "Halt"]


func parse_shard(shard_script):
	var lines = shard_script.split("\n", true)
	var script = []
	
	for i in lines.size():
		script.append(parse_line(lines[i]))
	
	var last_shard_id = ""
	for l in script:
		if l and l[0] == LineType.SHARD_ID:
			if l[1] == "$":
				if last_shard_id:
					l[1] = generate_sequential_id(last_shard_id)
			else:
				last_shard_id = l[1]
	
	return script

func generate_sequential_id(previous_id:String):
	var re = RegEx.new()
	re.compile("^(.*)((?<![0-9])[0-9]+)$")
	var result = re.search(previous_id)
	if result:
		var output = result.get_string(1) + String(int(result.get_string(2)) + 1)
		return output
	return "%s_0" % previous_id

func parse_line(line:String):
	var output = []
	var re = RegEx.new()
	var result
	var comment = ""
	
	re.compile("([^#\\s]?)([ \\t]*(?<!\\\\)#[^\\n]*)")
	result = re.search(line)
	if result:
		if result.get_string(1):
			line = line.substr(0, result.get_start(2))
			comment = result.get_string(2).strip_edges()
		else:
			output = [LineType.COMMENT, result.get_string(2).strip_edges()]
	
	var trimmed_line = line.strip_edges()
	
	if output:#Check if the line is a comment line 
		pass
	elif trimmed_line.begins_with("@"):
		re.compile("@([^@\\s]+)@")
		result = re.search(trimmed_line)
		if result:
			output = [LineType.SHORTCUT, result.get_string(1), comment]
		else:
			output = [LineType.ERROR, LineType.SHORTCUT]#Returns and error with shortcut flavor
	elif trimmed_line.ends_with(":"):
		re.compile("^:([\\w]+|\\$):[\\s]*")
		result = re.search(line)
		if result:
			output = [LineType.SHARD_ID, result.get_string(1), comment]
		else:
			output = [LineType.ERROR, LineType.SHARD_ID]#Returns and error with shard_id flavor
	elif trimmed_line.begins_with("show "):
		re.compile("show((?: +[\\w]+)+)$")
		result = re.search(trimmed_line)
		if result:
			output = [LineType.SHOW, result.get_string(1).strip_edges(), comment]
		else:
			output = [LineType.ERROR, LineType.SHOW]#Returns and error with show flavor	
	elif trimmed_line.begins_with("hide "):
		re.compile("hide((?: +[\\w]+)+)$")
		result = re.search(trimmed_line)
		if result:
			output = [LineType.HIDE, result.get_string(1).strip_edges(), comment]
		else:
			output = [LineType.ERROR, LineType.HIDE]#Returns and error with hide flavor
	elif trimmed_line.begins_with("play "):
		re.compile("play((?: +[\\w]+)+)$")
		result = re.search(trimmed_line)
		if result:
			output = [LineType.PLAY, result.get_string(1).strip_edges(), comment]
		else:
			output = [LineType.ERROR, LineType.PLAY]#Returns and error with play flavor
	elif trimmed_line.begins_with("halt "):
		re.compile("halt[\\s]+([0-9]+)$")
		result = re.search(trimmed_line)
		if result:
			output = [LineType.HALT, int(result.get_string(1)), comment]
		else:
			output = [LineType.ERROR, LineType.HALT]#Returns and error with halt flavor
	elif "\"" in trimmed_line:
		re.compile("^(?:([a-zA-Z_][\\w]*)((?: [a-zA-Z_][\\w]*)*)|)[\\s]*\"(.*)\"$")
		result = re.search(trimmed_line)
		if result:
			output = [LineType.SAY, result.get_string(1), result.get_string(3), result.get_string(2).split(' ', false), comment]
		else:
			output = [LineType.ERROR, LineType.SAY]#Returns and error with say flavor
	elif trimmed_line:
		output = [LineType.ERROR]#Return a general error	
	
	return output




func compose_shard(script):
	var output = ""
	for i in script.size():
		var l = script[i]
		if l:
			print("Line: %s" % [l])
			var comment = ""
			match l[0]:
				LineType.SHARD_ID, LineType.SHORTCUT, LineType.SHOW, LineType.HIDE, LineType.PLAY, LineType.HALT:
					if l.size() == 3 and l[2]:
						comment = "  %s" % l[2]
				LineType.SAY:
					if l.size() == 5 and l[4]:
						comment = "  %s" % l[4]
					elif l.size() == 4:#TODO remove temporary compatibility code
						comment = "  %s" % l[3]
			
			match l[0]:
				LineType.SHARD_ID:
					output += ":%s:%s" % [l[1], comment]
				LineType.SHORTCUT:
					output += "\t@%s@%s" % [l[1], comment]
				LineType.COMMENT:
					output += "\t%s" % l[1]
				LineType.SAY:
					var sayer = ""
					if l[1]:
						sayer = "%s " % l[1]
					var flags = ""
					if  l.size() == 5 and l[3]:#TODO remove temporary compatibility code "l.size() == 5 and "
						for f in l[3]:
							flags += "%s " % f
					output += "\t%s%s\"%s\"%s" % [sayer, flags, l[2], comment]
				LineType.SHOW:
					output += "\tshow %s%s" % [l[1], comment]
				LineType.HIDE:
					output += "\thide %s%s" % [l[1], comment]
				LineType.PLAY:
					output += "\tplay %s%s" % [l[1], comment]
				LineType.HALT:
					output += "\thalt %d%s" % [l[1], comment]
		if i + 1 < script.size():
			output += "\n"
	return output
