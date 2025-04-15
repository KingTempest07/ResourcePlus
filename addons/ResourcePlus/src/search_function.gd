@tool
extends LineEdit


const ResourceDock = preload("res://addons/ResourcePlus/src/resource_dock.gd")
const ResourceTree = preload("res://addons/ResourcePlus/src/resource_tree.gd")


@export 
var tree: ResourceTree


func _ready() -> void:
	# prevent errors when opening the dock's scene in the editor
	if ResourceDock.instance != null:
		right_icon = ResourceDock.get_icon("Search")
	text_changed.connect(_on_text_changed)


func _on_text_changed(_new_text: String) -> void:
	if text.length() == 0:
		tree.get_root().visible = true
		var current_item : TreeItem
		current_item = tree.get_root().get_next_in_tree()
		
		while current_item != null:
			current_item.visible = true
			current_item = current_item.get_next_in_tree()
		return

	var current_item : TreeItem
	current_item = tree.get_root().get_next_in_tree()
	
	while current_item != null:
		var current_text = current_item.get_text(0)
		if current_text.containsn(text):
			current_item.visible = true
		else:
			current_item.visible = false
		current_item = current_item.get_next_in_tree()
	current_item = tree.get_root().get_next_in_tree()
	
	while current_item != null:
		if current_item.visible:
			var children = current_item.get_children()
			for i in children:
				i.visible = true
			
			var parent = current_item.get_parent()
			while parent != tree and parent != null:
				parent.visible = true
				parent = parent.get_parent()
				
		current_item = current_item.get_next_in_tree()
