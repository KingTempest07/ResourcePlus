# Copyright (c) 2024 Make It With Wyatt. Licensed under the MIT License. 
# (See LICENSE file for details.)

@tool
extends EditorPlugin


const ResourceDock = preload("res://addons/ResourcePlus/src/resource_dock.gd")
const resource_dock_scene = preload("./src/ResourceDock.tscn")

var resource_dock: ResourceDock


func _enter_tree():
	resource_dock = resource_dock_scene.instantiate()
	resource_dock.dock_file_system = get_editor_interface().get_file_system_dock()
	resource_dock.editor_file_system = get_editor_interface().get_resource_filesystem()
	resource_dock.base_control = get_editor_interface().get_base_control()
	ResourceDock.instance = resource_dock
	add_control_to_dock(DOCK_SLOT_LEFT_UR, resource_dock)


func _exit_tree():
	remove_control_from_docks(resource_dock)
