@tool
extends Tree


const ResourceDock = preload("res://addons/ResourcePlus/src/resource_dock.gd")


var tree_nodes: Dictionary = {}


func reset():
	clear()
	create_item()


func add_base_resource(resource):
	var parent = get_root()
	if resource["base"] != "Resource":
		parent = tree_nodes[resource["base"]]
	
	if resource["class"] == "Resource_Saved_Data":
		return
	
	var item = create_item(parent)
	item.set_text(0, resource["class"])
	item.set_metadata(0, "Folder")
	
	var icon = ResourceDock.get_icon("Folder")

	if resource["icon"].length() != 0:
		icon = load(resource["icon"])
	
	item.set_meta("ICON", icon)
	
	item.set_icon(0, ResourceDock.get_icon("Folder"))
	tree_nodes[resource["class"]] = item
	return item


func _ready():
	hide_root = true
	create_item()


func _get_drag_data(at_position):
	var item = get_item_at_position(at_position)
	if item == null:
		return null
	if item.get_metadata(0) == "Folder":
		return null
	
	var resource: Resource = load(item.get_metadata(0))

	var icon: Texture2D
	var classes:= ProjectSettings.get_global_class_list()
	for klass: Dictionary in classes:
		if klass.class == (resource.get_script() as Script).get_global_name():
			if klass.icon.length() == 0:
				icon = ResourceDock.get_icon("ResourcePreloader")
			else:
				icon = load(klass.icon)
			break
	
	var rect = TextureRect.new()
	rect.texture = icon
	set_drag_preview(rect)

	return {"type": "resource", "resource": resource}
