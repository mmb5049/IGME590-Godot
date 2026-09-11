extends Control

const CELL_SIZE := 64
const GRID_GAP := 4

var CELL_PITCH := CELL_SIZE + GRID_GAP

const INVENTORY_WIDTH := 10
const INVENTORY_HEIGHT := 8

@onready var item_layer: Control = $ItemLayer


func _can_drop_data(at_position: Vector2, data) -> bool:
	if not data is Dictionary:
		return false

	if not data.has("item"):
		return false

	var item: InventoryItem = data["item"]

	if item == null:
		return false

	if item.item_data == null:
		return false

	var grid_position := Vector2i(
		floor(at_position.x / CELL_PITCH),
		floor(at_position.y / CELL_PITCH)
	)

	return item_fits(
		grid_position,
		item.item_data.grid_size,
		item
	)
	



func _drop_data(at_position: Vector2, data):
	if not data is Dictionary:
		return

	if not data.has("item"):
		return

	var item: InventoryItem = data["item"]

	if item == null:
		return

	var grid_position := Vector2i(
		floor(at_position.x / CELL_PITCH),
		floor(at_position.y / CELL_PITCH)
	)

	if not item_fits(grid_position, item.item_data.grid_size, item):
		_revert_item_placement(item, data)
		return
	
	# Snap exactly to the grid layout and make it visible again
	item.position = Vector2(
		grid_position.x * CELL_PITCH,
		grid_position.y * CELL_PITCH
	)
	item.visible = true # <--- MAKE VISIBLE AGAIN


func item_fits(
	grid_position: Vector2i,
	item_size: Vector2i,
	excluded_item: InventoryItem = null
) -> bool:

	# Check boundaries.
	if grid_position.x < 0:
		return false

	if grid_position.y < 0:
		return false

	if grid_position.x + item_size.x > INVENTORY_WIDTH:
		return false

	if grid_position.y + item_size.y > INVENTORY_HEIGHT:
		return false

	# Check for collisions with other items.
	for other_item in item_layer.get_children():

		if not other_item is InventoryItem:
			continue
			
		if not other_item.visible:
			continue
		
		if other_item == excluded_item or other_item.get_instance_id() == excluded_item.get_instance_id():
			continue

		var other_grid_position := Vector2i(
			round(other_item.position.x / CELL_PITCH),
			round(other_item.position.y / CELL_PITCH)
		)

		var other_size: Vector2i = other_item.item_data.grid_size

		# Check rectangle overlap.
		if rectangles_overlap(
			grid_position,
			item_size,
			other_grid_position,
			other_size
		):
			return false

	return true
	
	
func rectangles_overlap(
	pos_a: Vector2i,
	size_a: Vector2i,
	pos_b: Vector2i,
	size_b: Vector2i
) -> bool:

	return (
		pos_a.x < pos_b.x + size_b.x
		and
		pos_a.x + size_a.x > pos_b.x
		and
		pos_a.y < pos_b.y + size_b.y
		and
		pos_a.y + size_a.y > pos_b.y
	)
func _revert_item_placement(item: InventoryItem, data: Dictionary):
	var original_parent = data.get("original_parent", item_layer)
	if item.get_parent() != original_parent:
		if item.get_parent():
			item.get_parent().remove_child(item)
		original_parent.add_child(item)
	item.position = data.get("original_position", Vector2.ZERO)
	item.visible = true # <--- MAKE VISIBLE AGAIN
