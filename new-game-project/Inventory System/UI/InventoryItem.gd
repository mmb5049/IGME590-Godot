class_name InventoryItem
extends Control

@export var item_data: ItemData

const CELL_SIZE := 68

var inventory_ui: Control
var original_position: Vector2


func _ready():
	if item_data == null:
		return

	setup_item()


func setup_item():
	# Set the size based on the item's grid footprint.
	size = Vector2(
		item_data.grid_size.x * CELL_SIZE,
		item_data.grid_size.y * CELL_SIZE
	)

	var texture_rect := $TextureRect

	if item_data.icon:
		texture_rect.texture = item_data.icon

	texture_rect.position = Vector2.ZERO
	texture_rect.size = size

	# The TextureRect should not intercept mouse input.
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _get_drag_data(at_position: Vector2):
	if item_data == null:
		return null

	original_position = position

	var drag_data := {
		"item": self,
		"item_data": item_data,
		"original_position": position,
		"original_parent": get_parent(),
		"offset": at_position # Fixes snapping behavior based on click point
	}

	# Create the visual drag preview.
	var preview := duplicate()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.modulate.a = 0.7
	set_drag_preview(preview)
	
	# Hide this item temporarily so it doesn't visually clutter the grid
	visible = false 

	return drag_data
	
func _notification(what):
	# DRAG_END is called automatically by Godot when the drag completes or cancels
	if what == NOTIFICATION_DRAG_END:
		if not is_drag_successful():
			# If the drag failed/canceled outside the inventory, unhide it
			visible = true 
