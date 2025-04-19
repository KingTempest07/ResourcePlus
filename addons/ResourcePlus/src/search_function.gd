# Copyright (c) 2024 Make It With Wyatt. Licensed under the MIT License. 
# (See LICENSE file for details.)

@tool
extends LineEdit


const Classes = preload("res://addons/ResourcePlus/src/classes.gd")


@export 
var tree: Classes.ResourceTree


func _ready() -> void:
	# prevent errors when opening the dock's scene in the editor
	if Classes.ResourceDock.instance != null:
		right_icon = Classes.ResourceDock.get_icon("Search")
	text_changed.connect(_on_text_changed)


func _on_text_changed(_new_text: String) -> void:
	var current_item: TreeItem = tree.get_root().get_next_in_tree()
	
	if text.length() == 0:
		tree.get_root().visible = true
		while current_item != null:
			current_item.visible = true
			current_item = current_item.get_next_in_tree()
		return
	
	while current_item != null:
		var current_item_text:= current_item.get_text(0)
		if current_item_text.containsn(text):
			current_item.visible = true
		else:
			current_item.visible = false
		current_item = current_item.get_next_in_tree()
	
	current_item = tree.get_root().get_next_in_tree()
	while current_item != null:
		if current_item.visible:
			var children:= current_item.get_children()
			for i in children:
				i.visible = true
			
			var parent:= current_item.get_parent()
			while parent != tree and parent != null:
				parent.visible = true
				parent = parent.get_parent()
				
		current_item = current_item.get_next_in_tree()
