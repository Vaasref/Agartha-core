extends Node

var seen_lines:Dictionary = {}

var dialogue_log:Array = []

var log_max_length = -1


func init():
	if Agartha.Persistent.has_value("_history_seen_lines"):
		seen_lines = Agartha.Persistent.get_value("_history_seen_lines")
	if Agartha.store.has("_history_dialogue_log"):
		dialogue_log = Agartha.store.get("_history_dialogue_log")
	log_max_length = Agartha.Settings.get("agartha/dialogues/maximum_history_entry")


func _restore(state):
	if state.has("_history_dialogue_log"):
		dialogue_log = state.get("_history_dialogue_log").duplicate(true)

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



