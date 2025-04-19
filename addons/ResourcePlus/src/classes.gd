# Copyright (c) 2024 Make It With Wyatt. Licensed under the MIT License. 
# (See LICENSE file for details.)

## This file is intended to be a quick terminal to the plugin's internal classes
## 
## Inner classes in this file have a "__" prefix so that they can be renamed and 
## replaced by a const value that can actually be documented (workaround, really)


## The main class of the plugin; acts as the "Resources" dock
const ResourceDock = preload("res://addons/ResourcePlus/src/resource_dock.gd")
## Manages and creates the Tree and many of its TreeItems
const ResourceTree = preload("res://addons/ResourcePlus/src/resource_tree.gd")
## Allows for filtering of the tree's items by resource name
const SearchFunction = preload("res://addons/ResourcePlus/src/search_function.gd")

## Stores the state of the tree and its items (saved to file)
const SaveData = preload("res://addons/ResourcePlus/src/resource_save_data.gd")

## Holds relevant data about a global class
const ClassData = __ClassData

## Used internally to map classes to their subclasses
const ClassMapNode = __ClassMapNode

## Used to store the data of an item in the resource tree
## (intended as a base class)
const TreeItemData = __TreeItemData
## Stores the data of a tree item that represents a resource instance
const ResourceItemData = __ResourceItemData
## Stores the data of a tree item that represents a global, Resource-based class
const ClassItemData = __ClassItemData


class __ClassData:
	func _init(
		name: String, script: Script, script_icon: Texture2D, base: ClassData
	):
		global_name = name
		script_file = script
		icon = script_icon
		base_class = base

	## The registered global class name
	var global_name: String

	var script_file: Script
	## The icon of the class
	var icon: Texture2D

	var base_class: ClassData


class __ClassMapNode:
	func _init(data: ClassData):
		class_data = data

	var class_data: ClassData
	var subclasses: Array[ClassData] = []


class __TreeItemData:
	## The tree item instance of the represented object
	var tree_item: TreeItem

class __ResourceItemData:
	extends TreeItemData

	func _init(item: TreeItem, res: Resource, data: ClassData):
		tree_item = item
		resource = res
		class_data = data

	## The resource instance represented by the item
	var resource: Resource

	## The resource's class data
	var class_data: ClassData

class __ClassItemData:
	extends TreeItemData

	func _init(item: TreeItem, data: ClassData):
		tree_item = item
		class_data = data

	## The data of the represented class
	var class_data: ClassData