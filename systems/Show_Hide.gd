extends Node


func action_show(tag:String, parameters:Dictionary={}):
	var split_tag = tag.split(" ")
	var character_show_parameters = _get_character_parameters(split_tag[0])
	
	parameters = Agartha.Settings.get_parameter_list("agartha/dialogues/actions_default_parameters/show", parameters, character_show_parameters)
	
	show(tag, parameters)
	Agartha.emit_signal("show", tag, parameters)

func action_hide(tag:String, parameters:Dictionary={}):
	var split_tag = tag.split(" ")
	var character_show_parameters = _get_character_parameters(split_tag[0])
	
	parameters = Agartha.Settings.get_parameter_list("agartha/dialogues/actions_default_parameters/hide", parameters, character_show_parameters)
	
	hide(tag, parameters)
	Agartha.emit_signal("hide", tag, parameters)

func _get_character_parameters(first_tag_element:String):
	var output = {}
	if Agartha.store.has(first_tag_element):
		var character = Agartha.store.get(first_tag_element)
		if character is Resource:
			output = character.character_say_parameters
	return output


## Shown tag management


func _store(state):
	var sh_states:Dictionary = {}
	for n in get_tree().get_nodes_in_group("tagged"):
		var entry:Dictionary = {}
		var visible = null
		if n is CanvasItem:
			entry['visible'] = n.visible
		if n.has_meta("_show_tag"):
			entry['_show_tag'] = n.get_meta("_show_tag")
			entry['_show_parameters'] = n.get_meta("_show_parameters")
		elif n.has_meta("_hide_tag"):
			entry['_hide_tag'] = n.get_meta("_hide_tag")
			entry['_hide_parameters'] = n.get_meta("_hide_parameters")
		sh_states[_get_truncated_path(n)] = entry
		
	state.set("_tagged_sh_states", sh_states)

func _get_truncated_path(node:Node):
	return "." + str(node.get_path()).trim_prefix(str(Agartha.stage.get_path()))


func _restore(state):
	var sh_states:Dictionary = state.get("_tagged_sh_states")
	for path in sh_states.keys():
		var n = Agartha.stage.get_node(path)
		if n:
			if '_show_tag' in sh_states[path]:
				if 'visible' in sh_states[path] and sh_states[path]['visible']:
					show_node(n, sh_states[path]['_show_tag'], sh_states[path]['_show_parameters'])
				else:
					n.set_meta("_show_tag", sh_states[path]['_show_tag'])
					n.set_meta("_show_parameters", sh_states[path]['_show_parameters'])
			elif '_hide_tag' in sh_states[path]:
				if 'visible' in sh_states[path] and not sh_states[path]['visible']:
					hide_node(n, sh_states[path]['_hide_tag'], sh_states[path]['_hide_parameters'])
				else:
					n.set_meta("_hide_tag", sh_states[path]['_hide_tag'])
					n.set_meta("_hide_parameters", sh_states[path]['_hide_parameters'])
			elif n is CanvasItem and 'visible' in sh_states[path]:
				n.visible = sh_states[path]['visible']


func show(tag:String, parameters:Dictionary):
	tag = "# " + tag.trim_prefix("# ")
	var radical = tag.split(" ", false, 2)[1]
	var to_show = Agartha.Tag.get_array(tag) # Might be better as a dictionary for a big number of entries.
	
	for n in Agartha.Tag.get_array(radical):
		if n in to_show:
			show_node(n, tag, parameters)
		else:
			hide_node(n, tag, parameters)


func hide(tag:String, parameters:Dictionary):
	tag = "# " + tag.trim_prefix("# ")
	var to_hide = Agartha.Tag.get_array(tag)
	for n in to_hide:
		hide_node(n, tag, parameters)



func show_node(node:Node, tag:String, parameters:Dictionary):
	if node:
		if node.has_method("show") or node.has_method("_show"):
			node.set_meta("_show_tag", tag)
			node.set_meta("_show_parameters", parameters)
			if node.has_meta("_hide_tag"):
				node.set_meta("_hide_tag", null)
				node.set_meta("_hide_parameters", null)
			
		if node.has_method("_show"):
			node.call("_show", tag, parameters)
		elif node.has_method("show"):
			node.call("show")


func hide_node(node:Node, tag:String, parameters:Dictionary):
	if node:
		if node.has_method("hide") or node.has_method("_hide"):
			node.set_meta("_hide_tag", tag)
			node.set_meta("_hide_parameters", parameters)
			if node.has_meta("_show_tag"):
				node.set_meta("_show_tag", null)
				node.set_meta("_show_parameters", null)
			
		if node.has_method("_hide"):
			node.call("_hide", tag, parameters)
		elif node.has_method("hide"):
			node.call("hide")







