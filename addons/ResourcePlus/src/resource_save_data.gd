# Copyright (c) 2024 Make It With Wyatt. Licensed under the MIT License. 
# (See LICENSE file for details.)

extends Resource


@export var folder_colors: Dictionary[Script, Color]
@export var folder_collapse_states: Dictionary[Script, bool]

@export var instance_indices: Dictionary[Resource, int]