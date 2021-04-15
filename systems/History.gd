extends Node

#Persistent
var seen_lines:Dictionary

#Store
var dialogue_log:Array
var seen_shards:Dictionary
var seen_fragments:Dictionary

var log_max_length


func init():
	seen_lines = {}
	dialogue_log = []
	seen_shards = {}
	seen_fragments = {}
	log_max_length = -1
	
	if Agartha.Persistent.has_value("_history_seen_lines"):
		seen_lines = Agartha.Persistent.get_value("_history_seen_lines")
		
	_restore(Agartha.store)# A bit dirty but not really.
	
	log_max_length = Agartha.Settings.get("agartha/dialogues/maximum_history_entry")


# Store part

func _restore(state):
	if state.has("_history_dialogue_log"):
		dialogue_log = state.get("_history_dialogue_log").duplicate(true)
	if state.has("_history_seen_shards"):
		seen_shards = state.get("_history_seen_shards").duplicate()
	if state.has("_history_seen_fragments"):
		seen_fragments = state.get("_history_seen_fragments").duplicate()


func log_say(character, text, parameters):
	var character_tag = ""
	if character is Character:
		character_tag = character.tag
	dialogue_log.push_front([character_tag, text, parameters])
	while dialogue_log.size() > log_max_length:
		dialogue_log.pop_back()
	Agartha.store.set("_history_dialogue_log", dialogue_log.duplicate(true))


func clear_dialogue_log():
	while dialogue_log.size() > 0:
		dialogue_log.pop_back()
	Agartha.store.set("_history_dialogue_log", dialogue_log.duplicate(true))


func log_fragment(dialogue_name:String, fragment_name:String):
	if fragment_name in seen_fragments:
		seen_fragments[fragment_name] += 1
	else:
		seen_fragments[fragment_name] = 1
	var specific = "%s.%s" % [dialogue_name, fragment_name]
	if specific in seen_fragments:
		seen_fragments[specific] += 1
	else:
		seen_fragments[specific] = 1


func log_shard(shard_id):
	if shard_id is String:
		if shard_id in seen_shards:
			seen_shards[shard_id] += 1
		else:
			seen_shards[shard_id] = 1
	elif shard_id is Array:
		for sh_id in shard_id:
			log_shard(sh_id)


# Persistent part

func log_text_line(character, text_line:String):
	var entry = ""
	if character is Character:
		var character_tag = character.tag
		entry = character.tag + "-"
	entry += text_line.sha256_text()
	if not seen_lines.has(entry):
		seen_lines[entry] = true
		Agartha.Timeline.skip_stop(Agartha.Timeline.SkipPriority.UNSEEN)
	update_persistent()


func clear_persistent_history():
	seen_lines = {}
	update_persistent()


func update_persistent():
	Agartha.Persistent.set_value("_history_seen_lines", seen_lines.duplicate(true))



