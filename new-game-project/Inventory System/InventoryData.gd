# InventoryData.gd
class_name InventoryData
extends Resource

const WIDTH := 6
const HEIGHT := 5

var grid: Array = []


func _init():
	grid.resize(WIDTH * HEIGHT)

	for i in range(grid.size()):
		grid[i] = null


func get_cell(position: Vector2i):
	return grid[position.y * WIDTH + position.x]


func can_place_item(item: ItemData, position: Vector2i) -> bool:
	for y in range(item.grid_size.y):
		for x in range(item.grid_size.x):

			var cell := position + Vector2i(x, y)

			# Check if outside the inventory
			if cell.x < 0 or cell.x >= WIDTH:
				return false

			if cell.y < 0 or cell.y >= HEIGHT:
				return false

			# Check if another item is already there
			if get_cell(cell) != null:
				return false

	return true
