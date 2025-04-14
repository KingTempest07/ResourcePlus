@tool
extends HBoxContainer


const ResourceDock = preload("res://addons/ResourcePlus/src/resource_dock.gd")
const ResourceTree = preload("res://addons/ResourcePlus/src/resource_tree.gd")


enum MenuItems
{
	NAVIGATE = 0,
	CREATE = 1,
	COLOR = 2,
	OPEN_SCRIPT = 3,
	CREATE_TYPE = 5
}


## assigned by the plugin
static var instance: ResourceDock


## assigned by the plugin
var base_control: Control
static func get_icon(name: StringName, theme_type: StringName = "EditorIcons") -> Texture2D:
	return instance.base_control.get_theme_icon(name, theme_type)


## assigned by the plugin
var editor_file_system: EditorFileSystem
## assigned by the plugin
var dock_file_system: FileSystemDock


#region Resource Tree
@export 
var tree: ResourceTree
var _tree_items:= {}

#region Tree GUI Input
func _on_tree_gui_input(event: InputEvent):
	if event is not InputEventMouseButton: 
		return

	if event.button_index == MOUSE_BUTTON_RIGHT:
		_on_mouse_right()
	elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_on_mouse_left_released(event)
	
func _on_mouse_right():
	var mouse_pos = get_global_mouse_position()

	var item = tree.get_item_at_position(mouse_pos - tree.get_global_position())
	if item == null:
		blank_menu.popup(Rect2i(mouse_pos.x,mouse_pos.y,0,0))
		return
	
	if "class" in _tree_items[item]:
		base_menu.set_item_text(
			base_menu.get_item_index(MenuItems.CREATE), 
			"Create new "+_tree_items[item]["class"]
		)
		base_menu.popup(Rect2i(mouse_pos.x, mouse_pos.y, 0, 0))
	else:
		instance_menu.popup(Rect2i(mouse_pos.x, mouse_pos.y, 0, 0))

func _on_mouse_left_released(event: InputEventMouseButton):
	var mouse_pos = get_global_mouse_position()

	var item = tree.get_item_at_position(mouse_pos - tree.get_global_position())
	if item == null:
		return
	if item.get_metadata(0) == "Folder":
		return
		
	# edit if selected again; this is consistent with the rest of the editor
	var was_selected = tree.get_selected() == item
	if not was_selected:
		tree.set_selected(item, 0)

	item.set_editable(0, was_selected)
	tree_item_to_be_edited = item if was_selected else null
	EditorInterface.edit_resource(load(_tree_items[item]["path"]))
#endregion

var tree_item_to_be_edited: TreeItem
func _on_item_edited() -> void:
	if tree_item_to_be_edited == null:
		return

	var new_name = tree_item_to_be_edited.get_text(0)
	new_name = new_name.replace(" ","_")
	
	var path: String = tree_item_to_be_edited.get_metadata(0)

	var splits = path.split("/")
	var prev_name = splits[splits.size() - 1].get_basename()

	# NOTE: this may cause problems if a folder has the same name as the resource
	var new_path = path.replace(prev_name, new_name)
	
	var err = DirAccess.rename_absolute(path, new_path)
	if err != OK:
		print("Error renaming resource: "+err)

	EditorInterface.get_resource_filesystem().scan()
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

	match id:
		MenuItems.NAVIGATE:
			dock_file_system.navigate_to_path(_tree_items[item]["path"])
		MenuItems.CREATE:
			file_dialog.title = "Create new "+_tree_items[item]["class"]
			file_dialog.show()
		MenuItems.COLOR:
			color_panel.show()
		MenuItems.OPEN_SCRIPT:
			EditorInterface.edit_resource(load(_tree_items[item]["path"]))
#endregion


#region File Dialog
@export
var file_dialog: FileDialog
func _on_file_dialog_file_selected(path: String):
	var item = tree.get_selected()
	if not item:
		return
	var klass = _tree_items[item]
	var resource_type = load(klass["path"])
	var resource = resource_type.new()
	ResourceSaver.save(resource, path)
#endregion


#region Colors
@export
var color_panel: PopupPanel
func _on_color_panel_visibility_changed() -> void:
	var folder = tree.get_selected()
	var folder_path = _tree_items[folder]["path"]
	var script = load(folder_path)
	
	if save_data.RESOURCE_SAVED_DATA.has(folder_path):
		var color = save_data.RESOURCE_SAVED_DATA[folder_path]
		if color_panel.visible:
			color_picker.color = color
	else:
		save_data.RESOURCE_SAVED_DATA[folder_path] = Color.BLACK

@export
var color_picker: ColorPicker

var SELECTED_COLOR: Color
func _on_color_picker_color_changed(color: Color) -> void:
	SELECTED_COLOR = color

@export
var color_select_button: Button
func _on_color_select_pressed() -> void:
	color_panel.hide()

	var folder = tree.get_selected()
	var folder_path = _tree_items[folder]["path"]

	save_data.RESOURCE_SAVED_DATA[folder_path] = SELECTED_COLOR
	ResourceSaver.save(save_data, SAVE_DATA_LOCATION)
	process_colors(folder)


func process_colors(folder) -> void:
	if save_data == null:
		return

	var folder_path = _tree_items[folder]["path"]
	if not save_data.RESOURCE_SAVED_DATA.has(folder_path):
		return
	
	folder.set_custom_bg_color(
		0,
		save_data.RESOURCE_SAVED_DATA[folder_path] - Color(0,0,0,0.9)
	)
	
	for child_item in folder.get_children():
		if child_item.get_custom_bg_color(0) != Color(0,0,0,1):
			continue
		
		child_item.set_custom_bg_color(
			0,
			save_data.RESOURCE_SAVED_DATA[folder_path] - Color(0,0,0,0.9)
		)
	for child_item in folder.get_children():
		if child_item.get_custom_bg_color(0) != Color(0,0,0,1):
			continue
		
		child_item.set_custom_bg_color(
			0,
			save_data.RESOURCE_SAVED_DATA[folder_path] - Color(0,0,0,0.9)
		)
#endregion


#region Script Creation
@export
var new_resource_type_button: Button
func _on_create_new_resource_type_pressed() -> void:
	_open_script_create_dialog()

func _open_script_create_dialog() -> void:
	var dialog = ScriptCreateDialog.new()
	add_child(dialog)
	dialog.config("Resource", "res://new_resource_type.gd")
	dialog.popup_centered()
	dialog.script_created.connect(_on_script_created)

## Change to script editor after new resource type is created.
func _on_script_created(newscript) -> void:
	EditorInterface.edit_resource(load(newscript.resource_path))
	refresh()
#endregion


#region Collapse
var all_collapsed := false
@export
var collapse_button: Button
func _on_collapse_pressed() -> void:
	all_collapsed = !all_collapsed

	if all_collapsed:
		collapse_button.text = "^"
	else:
		collapse_button.text = "v"

	for i in _tree_items:
		if i == null:
			continue
		i.collapsed = all_collapsed

	for i in save_data.RESOURCE_COLLAPSED_VALUE:
		save_data.RESOURCE_COLLAPSED_VALUE[i] = all_collapsed

func collapse_check():
	for i in _tree_items:
		if i == null:
			continue

		var text = i.get_text(0)
		if not save_data.RESOURCE_COLLAPSED_VALUE.has(text):
			continue
		
		i.collapsed = save_data.RESOURCE_COLLAPSED_VALUE[text]
#endregion


var resource_regex = RegEx.new()


const SAVE_DATA_LOCATION:= "res://addons/ResourcePlus/src/data.tres"
var save_data: Resource_Saved_Data


#region Initialization
func _ready():
	_connect_signals()

	save_data = load(SAVE_DATA_LOCATION)
	if save_data == null:
		save_data = Resource_Saved_Data.new()
		ResourceSaver.save(save_data, SAVE_DATA_LOCATION)
	
	collapse_check()

	_set_icons()


func _connect_signals():
	if editor_file_system != null:
		editor_file_system.filesystem_changed.connect(refresh_if_visible)

	visibility_changed.connect(refresh_if_visible)

	tree.item_edited.connect(_on_item_edited)
	tree.gui_input.connect(_on_tree_gui_input)

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
#endregion


func _exit_tree() -> void:
	ResourceSaver.save(save_data, SAVE_DATA_LOCATION)


func find_resources_recursive(dir: EditorFileSystemDirectory) -> Array:
	var results: Array = []
	for i: int in range(dir.get_file_count()):
		var file_type = dir.get_file_type(i)
		if file_type != "Resource":
			continue

		var path = dir.get_file_path(i)

		var file_access = FileAccess.open(path, FileAccess.READ)
		var content = file_access.get_as_text()
		file_access.close()

		resource_regex.compile("script_class=\"(\\w+)\"")
		var resource_result = resource_regex.search(content)
		if not resource_result:
			continue
		
		results.append({
			"path": path,
			"base": resource_result.get_string(1)
		})
	
	for i: int in range(dir.get_subdir_count()):
		results += find_resources_recursive(dir.get_subdir(i))
	
	return results


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
	
	## store collapsed identity
	for i in _tree_items:
		if i != null:
			save_data.RESOURCE_COLLAPSED_VALUE[i.get_text(0)] = i.collapsed
	
	_tree_items.clear()
	tree.reset()

	## formats to {name: info}
	var classes:= {}
	for klass in ProjectSettings.get_global_class_list():
		classes[klass["class"]] = klass
	
	var class_map = {}
	for name in classes:
		var klass = classes[name]
		var start = klass
		
		while true:
			## if the current class's base class is Resource, add it to the map
			## and advance
			if classes[klass["class"]]["base"] == "Resource":
				if start["base"] not in class_map:
					class_map[start["base"]] = []
				class_map[start["base"]].append(start)
				break
			
			if klass["base"] not in classes:
				break
			
			klass = classes[klass["base"]]

	var queue = ["Resource"]
	var class_items = {}
	while len(queue):
		var base = queue.pop_front()
		if base not in class_map:
			continue

		for klass in class_map[base]:
			var item = tree.add_base_resource(klass)
			_tree_items[item] = klass
			class_items[klass["class"]] = item
			queue.append(klass["class"])

	var resource_files = find_resources_recursive(
		editor_file_system.get_filesystem()
	)
	for resource in resource_files:
		if resource["base"] not in class_items:
			continue
			
		if resource["base"] == "Resource_Saved_Data":
			continue
			
		var item : TreeItem = tree.create_item(class_items[resource["base"]])
		var name = resource["path"].split("/")[-1].split(".")[0].capitalize()
		
		var icon = class_items[resource["base"]].get_meta("ICON")
		var folder_icon = get_icon("Folder")

		if icon == folder_icon:
			var base_icon = get_icon("ResourcePreloader")
			icon = base_icon

		item.set_icon(0, icon)
		item.set_text(0, name)
		item.set_metadata(0, resource["path"])
		_tree_items[item] = resource

	if save_data != null:
		collapse_check()

	for i in _tree_items:
		if i == null:
			continue
		if i.get_metadata(0) != "Folder":
			continue
		process_colors(i)
#endregion
