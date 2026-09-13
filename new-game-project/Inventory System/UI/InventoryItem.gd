class_name InventoryItem
extends Control

@export var item_data: ItemData

const CELL_SIZE := 68

var inventory_ui: Control
var original_position: Vector2
var rotation_state := 0
var current_grid_size: Vector2i
var drag_preview: Control

func _ready():
	if item_data == null:
		return
	current_grid_size = item_data.grid_size
	setup_item()


func setup_item():
	size = Vector2(
		current_grid_size.x * CELL_SIZE,
		current_grid_size.y * CELL_SIZE
	)

	var texture_rect := $TextureRect

	if item_data.icon:
		texture_rect.texture = item_data.icon

	texture_rect.size = size
	texture_rect.position = Vector2.ZERO

	# Rotate around its center.
	texture_rect.pivot_offset = texture_rect.size / 2.0

	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
func rotate_item():
	rotation_state = (rotation_state + 1) % 4

	# Swap the logical grid dimensions.
	current_grid_size = Vector2i(
		current_grid_size.y,
		current_grid_size.x
	)

	# Update the item's Control size.
	size = Vector2(
		current_grid_size.x * CELL_SIZE,
		current_grid_size.y * CELL_SIZE
	)

	var texture_rect := $TextureRect

	# Original visual dimensions before rotation.
	var original_size = texture_rect.size

	# Rotate around the center instead of the top-left.
	texture_rect.pivot_offset = original_size / 2.0

	texture_rect.rotation_degrees = rotation_state * 90

	# Keep the center of the visual aligned with the center
	# of the item's new grid footprint.
	texture_rect.position = (size / 2.0) - (original_size / 2.0)
	if drag_preview != null:
		var preview_texture := drag_preview.get_node("TextureRect")

		preview_texture.pivot_offset = original_size / 2.0
		preview_texture.rotation_degrees = rotation_state * 90

		drag_preview.size = size
		preview_texture.position = (size / 2.0) - (original_size / 2.0)

func _get_drag_data(at_position: Vector2):
	if item_data == null:
		return null

	original_position = position
	
	var inventory := get_parent().get_parent()

	if inventory.has_method("set_dragged_item"):
		inventory.set_dragged_item(self)

	var drag_data := {
		"item": self,
		"item_data": item_data,
		"original_position": position,
		"original_parent": get_parent(),
		"offset": at_position
	}

	# Create the visual drag preview.
	drag_preview = duplicate()
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.modulate.a = 0.7

	set_drag_preview(drag_preview)

	visible = false

	return drag_data
	
func _notification(what):
	# DRAG_END is called automatically by Godot when the drag completes or cancels
	if what == NOTIFICATION_DRAG_END:
		if not is_drag_successful():
			# If the drag failed/canceled outside the inventory, unhide it
			visible = true 
