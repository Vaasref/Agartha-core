tool
extends Tree

var plugin:EditorPlugin

var bundles:Array


func init(_plugin):
	self.plugin = _plugin
	self.plugin.connect("shard_library_set", self, '_on_library_set')
	self.plugin.connect("shard_library_changed", self, '_on_library_changed')

func _on_library_set(new_library, old_library):
	update_tree()

func _on_library_changed():
	update_tree()


# Update tree logic

func update_tree():
	var tree = plugin.shard_library.get_tree()
	
	self.clear()
	var root = self.create_item()
	self.set_column_expand(0, true)
	self.set_column_expand(1, false)
	self.set_column_min_width(1, 25)
	self.set_hide_root(true)
	
	for b in tree.keys():
		place_item_in_tree(root, tree[b], b)

func place_item_in_tree(parent, branch, id):
	var tree_item = self.create_item(parent)
	var id_split = id.split("_")
	tree_item.set_text(0, id_split[id_split.size()-1])
	tree_item.set_meta("shard_id", id)
	if id in plugin.shard_library.shards:
		tree_item.set_icon(0, plugin.base_control.get_icon("Script", "EditorIcons"))
	else:
		tree_item.set_custom_color(0, Color.silver)
	tree_item.add_button(1, plugin.base_control.get_icon("Remove", "EditorIcons"), -1, true, "Delete shard and children.")
	for b in branch.keys():
		place_item_in_tree(tree_item, branch[b], b)


# Delete buttons

func disable_delete_buttons():
	var branch = self.get_root().get_children()
	while branch:
		branch.call_recursive('set_button_disabled', 1, 0, true)
		branch.call_recursive('set_meta', "exact_select", false)
		branch = branch.get_next()

func enable_delete_buttons(from:TreeItem):
	from.call_recursive('set_button_disabled', 1, 0, false)

func _on_nothing_selected():
	disable_delete_buttons()

func _on_item_selected():
	print("Openning Shard id: %s" % self.get_selected().get_meta("shard_id"))
	disable_delete_buttons()
	enable_delete_buttons(self.get_selected())
	plugin.open_shard(self.get_selected().get_meta("shard_id"))

func _on_item_rmb_selected(_position):
	disable_delete_buttons()
	self.get_selected().set_meta("exact_select", true)
	self.get_selected().set_button_disabled(1, 0, false)

func _on_item_button_pressed(item, column, id):
	if column == 1 and id == 0:
		var shard_id = item.get_meta("shard_id")
		var exact = item.has_meta("exact_select") and item.get_meta("exact_select")
		plugin.shard_library.remove_shard(shard_id, exact)
