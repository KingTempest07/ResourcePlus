Copyright (c) 2024 Make It With Wyatt. Licensed under the MIT License. 
(See LICENSE file for details.)

# ResourcePlus

A quality-of-life editor plugin for Resource management in Godot!

### Features:

Adds a new "Resources" tab with a tree view, where you can manage all of your 
resources in one place
- Creates folders to represent Resource-based types
  - Subclasses are given nested folders under their parent type
  - Folders can be (un)collapsed
	- (Un)Collapse all with one click
- Groups each Resource instance into their respective folder
- Has search functionality to filter each Resource by their name
- Supports drag-and-drop of resource data
  - Allows you to drag a resource from the dock to an inspector property
  - Allows for custom ordering of Resource instances in the tree
- Click the script button to quickly create a new Resource type
  - Alternatively, right click an empty space to bring up the option
- Right click a folder to bring up options
  - Show in FileSystem
  - Open Script
  - Create Item
	- Opens a dialog to create a new instance of the Resource type
  - Set Color
	- Opens a dialog to assign a color to the folder and its contents
- Right click a Resource instance to quickly show it in the Godot FileSystem

![resource_preview](https://github.com/makeitwithwyatt/ResourcePlus/assets/13342266/04890472-dc22-4dd8-b021-f5f0c831a1ef)
