class_name ItemData
extends Resource

@export var item_name: String
@export var icon: Texture2D

@export var grid_size: Vector2i = Vector2i(1, 1)

@export var stackable: bool = false
@export var max_stack: int = 1
