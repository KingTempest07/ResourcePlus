# Copyright (c) 2024 Make It With Wyatt. Licensed under the MIT License. 
# (See LICENSE file for details.)

@tool
extends HBoxContainer


const Classes = preload("res://addons/ResourcePlus/src/classes.gd")


enum MenuItems
{
	NAVIGATE = 0,
	CREATE = 1,
	COLOR = 2,
	OPEN_SCRIPT = 3,
	CREATE_TYPE = 5
}


## Assigned by the plugin
static var instance: Classes.ResourceDock


## Assigned by the plugin
var base_control: Control

static func get_icon(
	name: StringName, theme_type: StringName = "EditorIcons"
) -> Texture2D:
	return instance.base_control.get_theme_icon(name, theme_type)


## Assigned by the plugin
var editor_file_system: EditorFileSystem
## Assigned by the plugin
var dock_file_system: FileSystemDock


@export 
var tree: Classes.ResourceTree


#region Initialization/Exit
func _ready():
	_connect_signals()

	load_save_file()
	
	update_collapsed()

	# prevent errors when opening the dock's scene in the editor
	if instance != null:
		_set_icons()


func _connect_signals():
	if editor_file_system != null:
		editor_file_system.filesystem_changed.connect(refresh_if_visible)

	visibility_changed.connect(refresh_if_visible)

	new_resource_type_button.pressed.connect(_on_create_new_resource_type_pressed)

	base_menu.id_pressed.connect(_on_popup_menu_id_pressed)
	instance_menu.id_pressed.connect(_on_popup_menu_id_pressed)
	blank_menu.id_pressed.connect(_on_popup_menu_id_pressed)

	file_dialog.file_selected.connect(_on_file_dialog_file_selected)

	color_panel.visibility_changed.connect(_on_color_panel_visibility_changed)
	color_picker.color_changed.connect(_on_color_picker_color_changed)
	color_select_button.pressed.connect(_on_color_select_pressed)

	collapse_button.pressed.connect(_on_collapse_pressed)


func _set_icons():
	base_menu.set_item_icon(
		base_menu.get_item_index(MenuItems.NAVIGATE), 
		get_icon("Folder")
	)
	base_menu.set_item_icon(
		base_menu.get_item_index(MenuItems.OPEN_SCRIPT), 
		get_icon("Script")
	)
	base_menu.set_item_icon(
		base_menu.get_item_index(MenuItems.CREATE), 
		get_icon("Add")
	)
	base_menu.set_item_icon(
		base_menu.get_item_index(MenuItems.COLOR), 
		get_icon("ColorPicker")
	)

	instance_menu.set_item_icon(
		instance_menu.get_item_index(MenuItems.NAVIGATE), 
		get_icon("Folder")
	)

	blank_menu.set_item_icon(
		blank_menu.get_item_index(MenuItems.CREATE_TYPE), 
		get_icon("ScriptCreate")
	)

	new_resource_type_button.icon = get_icon("ScriptCreate")
	

func _exit_tree() -> void:
	save_to_file()
#endregion


#region Save Data
const SAVE_DATA_LOCATION:= "res://addons/ResourcePlus/src/data.tres"
var save_data: Classes.SaveData

func save_file_exists() -> bool:
	return FileAccess.file_exists(SAVE_DATA_LOCATION)

func save_to_file() -> void:
	var error:= ResourceSaver.save(save_data, SAVE_DATA_LOCATION)
	if error != OK:
		push_error("Errored when saving ResourcePlus's data to file: ", error)

## If the save data file does not exist, this will create and save a new one
func load_save_file() -> void:
	if save_file_exists():
		save_data = load(SAVE_DATA_LOCATION)
		return
	
	save_data = Classes.SaveData.new()
	save_to_file()
#endregion


#region Popup Menus
@export
var base_menu: PopupMenu
@export
var instance_menu: PopupMenu
@export
var blank_menu: PopupMenu

func _on_popup_menu_id_pressed(id: int):
	if id == MenuItems.CREATE_TYPE:
		_open_script_create_dialog()

	var item = tree.get_selected()
	if not item:
		return

	var metadata = item.get_metadata(0)

	match id:
		MenuItems.NAVIGATE:
			var path: String = (
				metadata.class_data.script_file.resource_path
				if metadata is Classes.ClassItemData else
				metadata.resource.resource_path
			)
			dock_file_system.navigate_to_path(path)
		MenuItems.CREATE:
			file_dialog.title = "Create new %s" % metadata.class_data.global_name
			file_dialog.show()
		MenuItems.COLOR:
			color_panel.show()
		MenuItems.OPEN_SCRIPT:
			EditorInterface.edit_resource(metadata.class_data.script_file)
#endregion


#region File Dialog
@export
var file_dialog: FileDialog
func _on_file_dialog_file_selected(path: String):
	var selected_item = tree.get_selected()
	if not selected_item:
		return

	var class_data: Classes.ClassData = selected_item.get_metadata(0).class_data
	var ResourceType = load(class_data.script_file.resource_path)
	var resource = ResourceType.new()

	var error:= ResourceSaver.save(resource, path)
	if error != OK:
		push_error("Error when creating resource: ", error)
		return
#endregion


#region Colors
@export
var color_panel: PopupPanel
func _on_color_panel_visibility_changed() -> void:
	var folder_script: Script = \
			tree.get_selected().get_metadata(0).class_data.script_file
	
	if save_data.folder_colors.has(folder_script):
		var color:= save_data.folder_colors[folder_script]
		if color_panel.visible:
			color_picker.color = color
	else:
		save_data.folder_colors[folder_script] = Color.BLACK

@export
var color_picker: ColorPicker

var SELECTED_COLOR: Color
func _on_color_picker_color_changed(color: Color) -> void:
	SELECTED_COLOR = color

@export
var color_select_button: Button
func _on_color_select_pressed() -> void:
	color_panel.hide()

	var folder_data = tree.get_selected().get_metadata(0)
	var folder_script: Script = folder_data.class_data.script_file

	save_data.folder_colors[folder_script] = SELECTED_COLOR
	save_to_file()
	process_colors(folder_data)


func process_colors(folder_data: Classes.ClassItemData) -> void:
	if save_data == null:
		return

	var folder_script: Script = folder_data.class_data.script_file

	if not save_data.folder_colors.has(folder_script):
		return
	
	folder_data.tree_item.set_custom_bg_color(
		0,
		save_data.folder_colors[folder_script] - Color(0,0,0,0.9)
	)
	
	for child_item in folder_data.tree_item.get_children():
		if child_item.get_custom_bg_color(0) != Color(0,0,0,1):
			continue
		
		child_item.set_custom_bg_color(
			0,
			save_data.folder_colors[folder_script] - Color(0,0,0,0.9)
		)
	for child_item in folder_data.tree_item.get_children():
		if child_item.get_custom_bg_color(0) != Color(0,0,0,1):
			continue
		
		child_item.set_custom_bg_color(
			0,
			save_data.folder_colors[folder_script] - Color(0,0,0,0.9)
		)
#endregion


#region Script Creation
@export
var new_resource_type_button: Button
func _on_create_new_resource_type_pressed() -> void:
	_open_script_create_dialog()

func _open_script_create_dialog() -> void:
	var dialog:= ScriptCreateDialog.new()
	add_child(dialog)
	dialog.config("Resource", "res://new_resource_type.gd")
	dialog.popup_centered()
	dialog.script_created.connect(_on_script_created)

## Change to script editor after new resource type is created.
func _on_script_created(script) -> void:
	EditorInterface.edit_resource(script)
	refresh()
#endregion


#region Collapse
var all_collapsed := false
@export
var collapse_button: Button
func _on_collapse_pressed() -> void:
	all_collapsed = !all_collapsed

	if all_collapsed:
		collapse_button.text = ">"
	else:
		collapse_button.text = "v"

	save_data.folder_collapse_states.clear()
	for data in tree.item_data:
		if not data is Classes.ClassItemData:
			continue
		# if data == null:
		# 	continue
		# TODO: find out if this is necessary

		data.tree_item.collapsed = all_collapsed

		var script: Script = data.class_data.script_file
		save_data.folder_collapse_states[script] = all_collapsed

	# TODO: remove maybe probably
	#for folder_script in save_data.folder_collapse_states:
	#	save_data.folder_collapse_states[folder_script] = all_collapsed

func update_collapsed():
	for data in tree.item_data:
		if not data is Classes.ClassItemData:
			continue
		#if data == null:
		#	continue
		# TODO

		#var text: String = data.get_text(0)
		var script: Script = data.class_data.script_file
		if not save_data.folder_collapse_states.has(script):
			continue
		
		data.tree_item.collapsed = save_data.folder_collapse_states[script]

func store_collapsed_state():
	save_data.folder_collapse_states.clear()
	for data in tree.item_data:
		if not data is Classes.ClassItemData:
			continue
		#if data == null:
		#	continue
		#TODO
		var script: Script = data.class_data.script_file
		save_data.folder_collapse_states[script] = data.tree_item.collapsed
#endregion


#region Refresh
func refresh_if_visible():
	if not visible:
		return
	refresh()

func refresh():
	if base_control == null:
		return
	
	if tree == null:
		return
	
	store_collapsed_state()
	tree.reset()
	_populate()

	if save_data != null:
		update_collapsed()

	for data in tree.item_data:
		if not data is Classes.ClassItemData:
			continue
		#if data == null:
		#	continue
		# TODO
		process_colors(data)
#endregion


#region Populate
## Populates the tree with tree items for each Resource class and its instances
func _populate():
	var class_items:= _create_items_by_class()

	var resource_files:= find_resources_recursive(
		editor_file_system.get_filesystem()
	)
	for resource: Dictionary in resource_files:
		if resource.base not in class_items:
			continue
		
		var base_item:= class_items[resource.base]

		var item: TreeItem = tree.create_item(base_item)
		var name: String = \
				resource.path.split("/")[-1].get_basename().capitalize()
		
		var base_item_data: Classes.ClassItemData = base_item.get_metadata(0)
		var base_icon: Texture2D = base_item_data.class_data.icon
		
		var item_icon: Texture2D = (
			base_icon 
			if base_icon != get_icon("Folder") else 
			get_icon("ResourcePreloader")
		)
		item.set_icon(0, item_icon)

		item.set_text(0, name)

		var resource_item_data: Classes.ResourceItemData = \
				Classes.ResourceItemData.new(
					item, 
					load(resource.path), 
					base_item_data.class_data
				)
		item.set_metadata(0, resource_item_data)
		tree.item_data.append(resource_item_data)

	var sorted_instances: Array[Resource] = save_data.instance_indices.keys()
	sorted_instances.sort_custom(
		func(a, b): 
			return save_data.instance_indices[a] < save_data.instance_indices[b]
	)

	for resource: Resource in sorted_instances:
		var data_index: int = tree.item_data.find_custom(
			func(data): 
				if not data is Classes.ResourceItemData:
					return false
				return data.resource == resource
		)
		var resource_item_data: Classes.ResourceItemData = \
				tree.item_data[data_index]

		var parent_item:= resource_item_data.tree_item.get_parent()
		var final_child:= parent_item.get_child(-1)
		resource_item_data.tree_item.move_after(final_child)

	for data in tree.item_data:
		if not data is Classes.ResourceItemData:
			continue
		if data.resource in sorted_instances:
			continue

		var parent_item:= data.tree_item.get_parent()
		var final_child:= parent_item.get_child(-1)
		data.tree_item.move_after(final_child)


## Creates new tree items for each Resource class in the format 
## { class: tree_item }
func _create_items_by_class() -> Dictionary[String, TreeItem]:
	var class_map:= _get_class_map()

	var base_class_queue: Array[Classes.ClassData] = [null]

	var class_items: Dictionary[String, TreeItem] = {}
	while len(base_class_queue):
		var base_class:= base_class_queue.pop_front()

		var map_index:= class_map.find_custom(
			func(node): return node.class_data == base_class
		)
		if map_index == -1:
			continue

		var map_node: Classes.ClassMapNode = class_map[map_index]

		for subclass in map_node.subclasses:
			var item:= tree.add_base_resource(subclass)
			class_items[subclass.global_name] = item
			base_class_queue.append(subclass)

	return class_items


## Gets all global Resource classes by their base class
func _get_class_map() -> Array[Classes.ClassMapNode]:
	## Formats to { name: global_class_info_dict }
	var classes: Dictionary[String, Dictionary] = {}
	for class_info: Dictionary in ProjectSettings.get_global_class_list():
		classes[class_info.class] = class_info
	
	var resource_class_data: Dictionary[String, Classes.ClassData] = {}
	for name: String in classes:
		var current_class:= classes[name]
		var initial_class:= current_class
		
		# makes sure the class inherits (at some point) from Resource
		while true:
			if current_class.base == "Resource":
				var initial_class_data: Classes.ClassData = \
						Classes.ClassData.new(
							initial_class.class, 
							load(initial_class.path),
							(
								null if initial_class.icon == "" else 
								load(initial_class.icon)
							), 
							null
						)
				resource_class_data[name] = initial_class_data 
				# TODO stop replacing every time
				break
			
			if current_class.base not in classes:
				break
			
			current_class = classes[current_class.base]
	
	for name: String in resource_class_data:
		if classes[name].base == "Resource":
			continue
		resource_class_data[name].base_class = \
				resource_class_data[classes[name].base]

	var class_map: Array[Classes.ClassMapNode] = []
	for name: String in resource_class_data:
		var class_data:= resource_class_data[name]

		var base_node_index: int
		if class_data.base_class == null:
			base_node_index = class_map.find_custom(
				func(node): 
					return classes[name].base == "Resource"
			)
		else:
			base_node_index = class_map.find_custom(
				func(node): 
					if node.class_data == null:
						return classes[name].base == "Resource"
					var node_name: String = node.class_data.global_name
					return node_name == class_data.base_class.global_name
			)

		var base_node: Classes.ClassMapNode
		match base_node_index:
			-1:
				base_node = Classes.ClassMapNode.new(class_data.base_class)
				class_map.append(base_node)
			_:
				base_node = class_map[base_node_index]
		base_node.subclasses.append(class_data)

	return class_map


var resource_regex:= RegEx.new()
## Finds all Resource files in the filesystem and returns them in an array of 
## the format { path: path, base: base_class }
func find_resources_recursive(
	directory: EditorFileSystemDirectory
) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	
	for file_index: int in range(directory.get_file_count()):
		var file_type: StringName = directory.get_file_type(file_index)
		if file_type != &"Resource":
			continue

		var directory_path: String = directory.get_file_path(file_index)

		var file_access:= FileAccess.open(directory_path, FileAccess.READ)
		var content: String = file_access.get_as_text()
		file_access.close()

		resource_regex.compile("script_class=\"(\\w+)\"")
		var resource_match: RegExMatch = resource_regex.search(content)
		if not resource_match:
			continue
		
		results.append({
			"path": directory_path,
			"base": resource_match.get_string(1)
		})
	
	for subdirectory_index: int in range(directory.get_subdir_count()):
		results += find_resources_recursive(
			directory.get_subdir(subdirectory_index)
		)
	
	return results
#endregion
