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

	# Convert mouse position to grid position.
	var grid_position := Vector2i(
		floor(at_position.x / CELL_SIZE),
		floor(at_position.y / CELL_SIZE)
	)

	# Check if the entire item fits.
	return item_fits(
		grid_position,
		item.item_data.grid_size
	)


func _drop_data(at_position: Vector2, data):
	if not data is Dictionary:
		return

	if not data.has("item"):
		return

	var item: InventoryItem = data["item"]

	if item == null:
		return

	# Convert mouse position to grid coordinates.
	var grid_position := Vector2i(
		floor(at_position.x / CELL_PITCH),
		floor(at_position.y / CELL_PITCH)
	)

	# Check if the item fits.
	if not item_fits(
		grid_position,
		item.item_data.grid_size
	):
		# Invalid position.
		item.position = item.original_position
		return

	# Snap item to the grid.
	item.position = Vector2(
		grid_position.x * CELL_PITCH,
		grid_position.y * CELL_PITCH
	)


func item_fits(
	grid_position: Vector2i,
	item_size: Vector2i
) -> bool:

	# Left boundary.
	if grid_position.x < 0:
		return false

	# Top boundary.
	if grid_position.y < 0:
		return false

	# Right boundary.
	if grid_position.x + item_size.x > INVENTORY_WIDTH:
		return false

	# Bottom boundary.
	if grid_position.y + item_size.y > INVENTORY_HEIGHT:
		return false

	return true
