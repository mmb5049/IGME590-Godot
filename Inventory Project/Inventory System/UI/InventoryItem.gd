class_name InventoryItem
extends Control

@export var item_data: ItemData

const CELL_SIZE := 68

var inventory_ui: Control
var original_position: Vector2
var rotation_state := 0
var current_grid_size: Vector2i
var drag_preview: Control
var quantity: int = 1:

	set(value):
		quantity = value
		update_count_label()

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
	update_count_label()

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

	# 1. Create the empty parent container
	var preview_container := Control.new()
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 2. Duplicate the item as the visual child
	drag_preview = duplicate()

	# Explicitly copy the current state of the real item.
	drag_preview.rotation_state = rotation_state
	drag_preview.current_grid_size = current_grid_size
	drag_preview.quantity = quantity
	
	# 3. Apply the negative offset to the CHILD node, NOT the container
	drag_preview.position = -at_position
	
	# Make sure the preview's visual matches that state.
	drag_preview.update_visual()
	drag_preview.update_count_label()
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.modulate.a = 0.7

	# 4. Nest the child into the container and set the container as the preview
	preview_container.add_child(drag_preview)
	set_drag_preview(preview_container)
	
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
	


func update_count_label():
	var label := get_node_or_null("CountLabel")
	print(label)
	if label == null:
		return
	if item_data != null and item_data.stackable and quantity > 1:
		label.text = str(quantity)
		label.visible = true
	else:
		label.visible = false
		
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var inventory := get_parent().get_parent()

			if inventory.has_method("show_item_context_menu"):
				inventory.show_item_context_menu(self)

			accept_event()
			
			
func rotate_offset_90_degrees(
	old_offset: Vector2,
	old_size: Vector2i
) -> Vector2:

	var old_width := old_size.x * CELL_SIZE
	var old_height := old_size.y * CELL_SIZE

	return Vector2(
		old_height - old_offset.y,
		old_offset.x
	)
