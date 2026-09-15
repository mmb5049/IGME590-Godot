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

	# Only default to item_data if it hasn't been rotated yet
	apply_rotation(rotation_state)
		
	setup_item()


func setup_item():
	var texture_rect := $TextureRect

	if item_data.icon:
		texture_rect.texture = item_data.icon

	texture_rect.size = Vector2(
		item_data.grid_size.x * CELL_SIZE,
		item_data.grid_size.y * CELL_SIZE
	)

	texture_rect.pivot_offset = texture_rect.size / 2.0
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	update_visual()


func apply_rotation(new_rotation: int):
	rotation_state = new_rotation % 4

	if rotation_state % 2 == 0:
		current_grid_size = item_data.grid_size
	else:
		current_grid_size = Vector2i(
			item_data.grid_size.y,
			item_data.grid_size.x
		)
	
	update_visual()
	print_debug(current_grid_size)
	
	
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

	# Create preview.
	drag_preview = duplicate()

	# Explicitly copy the current state of the real item.
	drag_preview.rotation_state = rotation_state
	drag_preview.current_grid_size = current_grid_size
	print_debug(current_grid_size)
	
	# Make sure the preview's visual matches that state.
	drag_preview.update_visual()

	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.modulate.a = 0.7

	set_drag_preview(drag_preview)
	visible = false
	return drag_data


func update_visual():
	size = Vector2(
		current_grid_size.x * CELL_SIZE,
		current_grid_size.y * CELL_SIZE
	)

	var texture_rect := $TextureRect

	texture_rect.rotation_degrees = rotation_state * 90

	texture_rect.position = (
		size / 2.0
		- texture_rect.size / 2.0
	)
