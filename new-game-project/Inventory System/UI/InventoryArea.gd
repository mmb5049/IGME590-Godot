extends Control

const CELL_SIZE := 64
const GRID_GAP := 4

var CELL_PITCH := CELL_SIZE + GRID_GAP

const INVENTORY_WIDTH := 10
const INVENTORY_HEIGHT := 8
var currently_dragged_item: InventoryItem = null
const HIGHLIGHT_COLOR_VALID := Color(0.2, 1.0, 0.3, 0.35)
const HIGHLIGHT_COLOR_INVALID := Color(1.0, 0.2, 0.2, 0.35)
var current_highlight_grid_position := Vector2i.ZERO
var highlight_cells: Array[ColorRect] = []

var drop_successful := false

@onready var highlight_layer: Control = $HighlightLayer
@onready var item_layer: Control = $ItemLayer

func _ready():
	create_highlight_cells()

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

	if item.drag_preview == null:
		return false

	var grid_position := Vector2i(
		floor(at_position.x / CELL_PITCH),
		floor(at_position.y / CELL_PITCH)
	)
	#print_debug("Preview rotation: ", item.drag_preview.current_grid_size)
	current_highlight_grid_position = grid_position

	var item_size: Vector2i = item.drag_preview.current_grid_size
	var stack_target := get_item_at_cell(grid_position, item)
	if can_stack_onto(stack_target, item):
		var target_cell := Vector2i(
			round(stack_target.position.x / CELL_PITCH),
			round(stack_target.position.y / CELL_PITCH)
		)
		update_item_highlight(target_cell, stack_target.current_grid_size, true)
		return true
		
	var valid := item_fits(
		grid_position,
		item_size,
		item
)
	update_item_highlight(
		grid_position,
		item_size,
		valid
)
	return valid



func _drop_data(at_position: Vector2, data):
	
	if not data is Dictionary:
		return

	if not data.has("item"):
		return

	var item: InventoryItem = data["item"]

	if item == null:
		return

	var preview := item.drag_preview
	if preview == null:
		return

	var grid_position := Vector2i(
		floor(at_position.x / CELL_PITCH),
		floor(at_position.y / CELL_PITCH)
	)
	
	var stack_target := get_item_at_cell(grid_position, item)
	if can_stack_onto(stack_target, item):
		var space: int = stack_target.item_data.max_stack - stack_target.quantity
		var moved: int = min(space, item.quantity)

		stack_target.quantity += moved
		item.quantity -= moved

		currently_dragged_item = null
		clear_item_highlight()
		drop_successful = true

		if item.quantity <= 0:
			item.queue_free()
		else:
			# Partial merge: the remainder snaps back where it came from.
			item.position = item.original_position
			item.visible = true
			item.drag_preview = null
		return

	# Validate using the preview's current rotation.
	if not item_fits(
		grid_position,
		preview.current_grid_size,
		item
	):
		return

	# Apply the preview's rotation to the REAL item.
	item.apply_rotation(preview.rotation_state)

	# Apply the final position.
	item.position = Vector2(
		grid_position.x * CELL_PITCH,
		grid_position.y * CELL_PITCH
	)
	


	item.visible = true

	item.drag_preview = null
	currently_dragged_item = null
	clear_item_highlight()
	
	# The drop was successful.
	drop_successful = true

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

	# Check collisions with other items.
	for other_item in item_layer.get_children():

		if not other_item is InventoryItem:
			continue

		if not other_item.visible:
			continue

		if other_item == excluded_item:
			continue

		var other_grid_position := Vector2i(
			round(other_item.position.x / CELL_PITCH),
			round(other_item.position.y / CELL_PITCH)
		)

		var other_size: Vector2i = other_item.current_grid_size

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

	# Make the real item visible again.
	item.visible = true

	# Clear drag state.
	item.drag_preview = null
	currently_dragged_item = null
	
func _input(event):
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_R:
				if currently_dragged_item != null:
					rotate_drag_preview()
		
func set_dragged_item(item: InventoryItem):
	currently_dragged_item = item
	drop_successful = false
	
	
func rotate_drag_preview():
	var item := currently_dragged_item

	if item == null:
		return

	var preview := item.drag_preview

	if preview == null:
		return

	# Rotate the PREVIEW only.
	var new_rotation: int = (preview.rotation_state + 1) % 4

	preview.apply_rotation(new_rotation)
	
	# Immediately update the highlight.
	var valid := item_fits(
		current_highlight_grid_position,
		preview.current_grid_size,
		item
	)

	update_item_highlight(
		current_highlight_grid_position,
		preview.current_grid_size,
		valid
	)
	
func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		clear_item_highlight()

		if currently_dragged_item != null and not drop_successful:
			var item := currently_dragged_item

			item.position = item.original_position
			item.visible = true
			item.drag_preview = null

			currently_dragged_item = null
			
func create_highlight_cells():
	for cell in highlight_cells:
		cell.queue_free()

	highlight_cells.clear()

	for y in range(INVENTORY_HEIGHT):
		for x in range(INVENTORY_WIDTH):
			var cell := ColorRect.new()

			cell.size = Vector2(
				CELL_SIZE,
				CELL_SIZE
			)

			cell.position = Vector2(
				x * CELL_PITCH,
				y * CELL_PITCH
			)

			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.visible = false

			highlight_layer.add_child(cell)
			highlight_cells.append(cell)
			
			
func update_item_highlight(
	grid_position: Vector2i,
	item_size: Vector2i,
	valid: bool
):
	# Hide everything first.
	for cell in highlight_cells:
		cell.visible = false

	for y in range(item_size.y):
		for x in range(item_size.x):

			var cell_position := Vector2i(
				grid_position.x + x,
				grid_position.y + y
			)

			if cell_position.x < 0:
				continue

			if cell_position.y < 0:
				continue

			if cell_position.x >= INVENTORY_WIDTH:
				continue

			if cell_position.y >= INVENTORY_HEIGHT:
				continue

			var index := (
				cell_position.y * INVENTORY_WIDTH
				+ cell_position.x
			)

			var cell := highlight_cells[index]

			cell.color = (
				HIGHLIGHT_COLOR_VALID
				if valid
				else HIGHLIGHT_COLOR_INVALID
			)

			cell.visible = true
			
			
func clear_item_highlight():
	for cell in highlight_cells:
		cell.visible = false
		
		
func get_item_at_cell(cell: Vector2i, exclude: InventoryItem = null) -> InventoryItem:
	for other in item_layer.get_children():
		if not other is InventoryItem:
			continue
		if other == exclude or not other.visible:
			continue
		var other_pos := Vector2i(
			round(other.position.x / CELL_PITCH),
			round(other.position.y / CELL_PITCH)
		)
		if rectangles_overlap(cell, Vector2i.ONE, other_pos, other.current_grid_size):
			return other
	return null


func can_stack_onto(target: InventoryItem, item: InventoryItem) -> bool:
	if target == null or item == null or target == item:
		return false
	if item.item_data == null or target.item_data == null:
		return false
	if not item.item_data.stackable:
		return false
	if target.item_data != item.item_data:
		return false
	return target.quantity < target.item_data.max_stack
