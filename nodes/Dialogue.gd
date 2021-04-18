extends Node
class_name Dialogue

export var default_fragment:String = ""
export var auto_start:bool = false

var thread:Thread
var stage_path:String

func _preprocess():
	Agartha.Director.preprocess_dialogue(self)

######## To check the implementations of the methods look at ProcessedDialogue.gd

func step():
	pass

func _wait_semaphore():
	pass

func _is_preactive() -> bool:
	return false



###########

func ia() -> bool:#Shorhand
	return false
func is_active() -> bool:
	return false

func is_running() -> bool:
	return false

func is_exitting() -> bool:
	return false


### User-side execution actions

func call_fragment(fragment_name:String):
	pass

func jump(dialogue_name:String, fragment_name:String="", scene_id:String=""):
	pass


func cond(condition) -> bool:#Shorhand
	return false
func condition(condition) -> bool:
	return false

func shard(shard_id:String, exact_id:bool=true, shard_library:Resource=null):
	pass


################# Dialogue actions

func show(tag:String, parameters:Dictionary={}):
	pass

func hide(tag:String, parameters:Dictionary={}):
	pass

func halt(priority:int):
	pass

func say(character, text:String, parameters:Dictionary={}):
	pass

func ask(default_answer:String="", parameters:Dictionary={}):
	pass

func menu(entries:Array, parameters:Dictionary={}):
	pass
