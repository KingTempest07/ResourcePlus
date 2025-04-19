# Copyright (c) 2024 Make It With Wyatt. Licensed under the MIT License. 
# (See LICENSE file for details.)

@tool
extends Tree


const Classes = preload("res://addons/ResourcePlus/src/classes.gd")


var item_data: Array[Classes.TreeItemData] = []

func get_item_data(item: TreeItem) -> Classes.TreeItemData:
	var index = item_data.find_custom(
		func(data): return data.tree_item == item
	)
	return item_data[index]

func get_base_item_data(class_data: Classes.ClassData) -> Classes.ClassItemData:
	var index = item_data.find_custom(
		func(data):
			return (
				false if not data is Classes.ClassItemData else
				data.class_data.global_name == class_data.base_class.global_name
			)
	)
	return item_data[index] if index != -1 else null


func _ready():
	item_edited.connect(_on_item_edited)
	gui_input.connect(_on_gui_input)

	hide_root = true
	create_item()


func reset():
	item_data.clear()
	clear()
	create_item()


## Creates a tree item for the Resource type (folder)
func add_base_resource(resource_class_info: Classes.ClassData) -> TreeItem:
	var parent_item: TreeItem = (
		get_root()
		if resource_class_info.base_class == null or resource_class_info.base_class.global_name == "Resource" else 
		get_base_item_data(resource_class_info).tree_item
	)
	
	var tree_item:= create_item(parent_item)
	tree_item.set_text(0, resource_class_info.global_name)
	var data = Classes.ClassItemData.new(tree_item, resource_class_info)
	tree_item.set_metadata(0, data)

	if not resource_class_info.icon:
		resource_class_info.icon = Classes.ResourceDock.get_icon("Folder")
	
	tree_item.set_icon(0, resource_class_info.icon)
	item_data.append(data)
	return tree_item


#region Drag Data
func _get_drag_data(at_position):
	var tree_item:= get_item_at_position(at_position)
	if tree_item == null:
		return null

	var metadata = tree_item.get_metadata(0)
	if metadata is Classes.ClassItemData:
		return null
	
	var resource_item_data: Classes.ResourceItemData = metadata
	
	var preview_rect:= TextureRect.new()
	preview_rect.texture = (
		Classes.ResourceDock.get_icon("ResourcePreloader") 
		if resource_item_data.class_data.icon == null else 
		resource_item_data.class_data.icon
	)
	set_drag_preview(preview_rect)
	
	var resource: Resource = load(resource_item_data.resource.resource_path)
	
	# Must be formatted to have type as "resource" and resource as the resource, 
	# otherwise this will not be recognized as Resource data by the editor.
	# Other data can be added or removed as needed.
	# TODO: see if this can be made with its own type rather than a dictionary
	return { 
		"type": "resource", 
		"resource": resource, 
		"dock_tree_item": tree_item
	}


func _can_drop_data(at_position, data):
	if data.type != "resource":
		return false
	if not data.dock_tree_item:
		return false

	drop_mode_flags = DROP_MODE_INBETWEEN

	var drop_section: int = get_drop_section_at_position(at_position)
	
	# if no item is there
	if drop_section == -100:
		return false

	var hovered_tree_item:= get_item_at_position(at_position)
	var hovered_item_data: Classes.TreeItemData = \
			hovered_tree_item.get_metadata(0)
	if hovered_tree_item.get_metadata(0) is Classes.ClassItemData:
		return false

	var data_item_data: Classes.ResourceItemData = \
			data.dock_tree_item.get_metadata(0)

	var data_class_name: String = data_item_data.class_data.global_name
	var hovered_class_name: String = hovered_item_data.class_data.global_name

	return data_class_name == hovered_class_name

func _drop_data(at_position, data):
	var drop_section: int = get_drop_section_at_position(at_position)
	var hovered_item:= get_item_at_position(at_position)

	if drop_section == -1:
		data.dock_tree_item.move_before(hovered_item)
	elif drop_section == 1:
		data.dock_tree_item.move_after(hovered_item)
	else:
		push_error("Invalid drop section: %s" % str(drop_section))

	var save_data:= Classes.ResourceDock.instance.save_data
	save_data.instance_indices.clear()
	for resource_item_data in item_data:
		if not resource_item_data is Classes.ResourceItemData:
			continue
		save_data.instance_indices[resource_item_data.resource] = \
				resource_item_data.tree_item.get_index()
		
#endregion


#region GUI Input
func _on_gui_input(event: InputEvent):
	if not event is InputEventMouseButton: 
		return

	if event.button_index == MOUSE_BUTTON_RIGHT:
		_on_mouse_right()
	elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_on_mouse_left_released(event)
	
func _on_mouse_right():
	var mouse_pos:= get_global_mouse_position()

	var dock_instance:= Classes.ResourceDock.instance

	var hovered_item:= get_item_at_position(mouse_pos - get_global_position())
	if hovered_item == null:
		dock_instance.blank_menu.popup(
			Rect2i(mouse_pos.x, mouse_pos.y, 0, 0)
		)
		return
	
	var metadata = hovered_item.get_metadata(0)

	if metadata is Classes.ClassItemData:
		dock_instance.base_menu.set_item_text(
			dock_instance.base_menu.get_item_index(
				Classes.ResourceDock.MenuItems.CREATE
			), 
			"Create new %s" % metadata.class_data.global_name
		)
		dock_instance.base_menu.popup(
			Rect2i(mouse_pos.x, mouse_pos.y, 0, 0)
		)
	elif metadata is Classes.ResourceItemData:
		dock_instance.instance_menu.popup(
			Rect2i(mouse_pos.x, mouse_pos.y, 0, 0)
		)
	else:
		push_error("Invalid item type. Metadata: %s" % str(metadata))

func _on_mouse_left_released(event: InputEventMouseButton):
	var mouse_pos:= get_global_mouse_position()

	var hovered_item:= get_item_at_position(mouse_pos - get_global_position())
	if hovered_item == null:
		return
	
	var metadata = hovered_item.get_metadata(0)
	if metadata is Classes.ClassItemData:
		return
		
	# edit if selected again; this is consistent with the rest of the editor
	var was_selected:= get_selected() == hovered_item
	if not was_selected:
		set_selected(hovered_item, 0)

	hovered_item.set_editable(0, was_selected)
	tree_item_to_be_edited = hovered_item if was_selected else null

	var resource_item_data: Classes.ResourceItemData = metadata
	EditorInterface.edit_resource(resource_item_data.resource)


## The item currently being edited. This will always be a Resource item.
var tree_item_to_be_edited: TreeItem
func _on_item_edited() -> void:
	if tree_item_to_be_edited == null:
		return

	var new_basename:= tree_item_to_be_edited.get_text(0)
	new_basename = new_basename.replace(" ","_")
	
	var metadata = tree_item_to_be_edited.get_metadata(0)
	var resource_item_data: Classes.ResourceItemData = metadata

	var old_path: String = resource_item_data.resource.resource_path

	var old_file_name:= old_path.get_slice('/', -1)
	var old_basename:= old_file_name.get_basename()

	var old_folder_path:= old_path.trim_suffix(old_file_name)

	var new_file_name:= old_file_name.replace(old_basename, new_basename)

	var new_path:= old_folder_path + new_file_name
	
	var err = DirAccess.rename_absolute(old_path, new_path)
	if err != OK:
		print("Error renaming resource: "+err)

	Classes.ResourceDock.instance.editor_file_system.scan()
#endregion
