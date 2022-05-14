tool
extends Resource
class_name ShardLibrary


export var shards:Dictionary = {}


func get_shards(shard_id:String=""):
	var output = []
	var ids = get_children_ids(shard_id)
	
	for id in ids:
		output += shards[id]
	
	return output


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
	for k in shards.keys():
		if k.begins_with(branch_id):
			if trimmed:
				output.append(k.trim_prefix(branch_id))
			else:
				output.append(k)
	return output


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


func save_script(script):
	if not script is Array:
		return
	var shard_ids = []
	for i in script.size():
		if script[i] and script[i][0] == LineType.SHARD_ID:
			shard_ids.append(i)
	for i in shard_ids.size():
		if i + 1 == shard_ids.size():
			save_shard(script, shard_ids[i], script.size())
		else:
			save_shard(script, shard_ids[i], shard_ids[i+1])
	self.emit_signal("changed")


func save_shard(script, start, end):
	if not script is Array or end >= script.size() and start > end:
		return
	var shard_id = script[start][1]
	var shard_script = []
	for i in range(start, end):
		shard_script.append(script[i].duplicate(true))
	self.shards[shard_id] = shard_script


func remove_shard(shard_id, exact:bool=false):
	if exact:
		self.shards.erase(shard_id)
	else:
		for s in self.shards.keys():
			if s.begins_with(shard_id):
				self.shards.erase(s)
	self.emit_signal("changed")

func set_path(value:String):
	resource_path = value
	self.emit_signal("changed")
