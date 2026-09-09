class_name InventoryData
extends Resource

const WIDTH := 10
const HEIGHT := 8

var grid: Array = []


func _init():
	grid.resize(WIDTH * HEIGHT)

	for i in range(grid.size()):
		grid[i] = null


func get_cell(position: Vector2i):
	if not is_inside_grid(position):
		return null

	return grid[
		position.y * WIDTH + position.x
	]


func is_inside_grid(position: Vector2i) -> bool:
	return (
		position.x >= 0
		and position.x < WIDTH
		and position.y >= 0
		and position.y < HEIGHT
	)


func can_place_item(
	item: InventoryItem,
	position: Vector2i
) -> bool:

	if item == null:
		return false

	if item.item_data == null:
		return false

	var item_size: Vector2i = item.item_data.grid_size

	for y in range(item_size.y):
		for x in range(item_size.x):

			var cell := position + Vector2i(x, y)

			# Outside inventory
			if not is_inside_grid(cell):
				return false

			var occupying_item = get_cell(cell)

			# Empty cell → okay
			if occupying_item == null:
				continue

			# The item is occupying its OWN old cells.
			# That's okay while moving.
			if occupying_item == item:
				continue

			# Some OTHER item is here.
			return false

	return true


func place_item(
	item: InventoryItem,
	position: Vector2i
) -> bool:

	if not can_place_item(item, position):
		return false

	# First remove the item from its old cells.
	remove_item(item)

	# Put the item into its new cells.
	var item_size: Vector2i = item.item_data.grid_size

	for y in range(item_size.y):
		for x in range(item_size.x):

			var cell := position + Vector2i(x, y)

			grid[
				cell.y * WIDTH + cell.x
			] = item

	return true


func remove_item(item: InventoryItem):

	for i in range(grid.size()):

		if grid[i] == item:
			grid[i] = null
