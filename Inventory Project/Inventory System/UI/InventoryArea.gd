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

var item_context_menu: PopupMenu
var context_menu_item: InventoryItem = null

const MENU_SPLIT := 0
const MENU_CONSUME := 1

var drop_successful := false

@onready var highlight_layer: Control = $HighlightLayer
@onready var item_layer: Control = $ItemLayer
@onready var message_label: Label = $MessageLabel

var handgun_data: ItemData = preload("res://Inventory System/Items/handgun.tres")
var shotgun_data: ItemData = preload("res://Inventory System/Items/shotgun.tres")
var ammo_data: ItemData = preload("res://Inventory System/Items/ammo.tres")
var medkit_data: ItemData = preload("res://Inventory System/Items/medkit.tres")

var item_scene: PackedScene = preload(
	"res://Inventory System/UI/InventoryItem.tscn"
)

var active_drag_data: Dictionary = {}

func _ready():
	create_highlight_cells()
	highlight_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	create_item_context_menu()

func _can_drop_data(at_position: Vector2, data) -> bool:
	if not data is Dictionary or not data.has("item"):
		print("FALSE")
		return false
		
	

	var item: InventoryItem = data["item"]
	if item == null or item.item_data == null or item.drag_preview == null:
		print("FALSE")
		return false

	
	active_drag_data = data 
	# Get the click offset from the drag data dictionary
	var click_offset: Vector2 = data.get("offset", Vector2.ZERO)
	
	# Calculate grid position based on the top-left corner of the item box instead of the mouse tip
	var item_top_left := at_position - click_offset + Vector2(34,32)
	var grid_position := Vector2i(
		floor(item_top_left.x / CELL_PITCH),
		floor(item_top_left.y / CELL_PITCH)
	)
	current_highlight_grid_position = grid_position
	# 1. Check if we are hovering over a valid stack target
	var stack_target := get_item_at_cell(grid_position, item)
	print(stack_target)
	if can_stack_onto(stack_target, item):
		var target_cell := Vector2i(
			round(stack_target.position.x / CELL_PITCH),
			round(stack_target.position.y / CELL_PITCH)
		)
		update_item_highlight(target_cell, stack_target.current_grid_size, true)
		return true

	# 2. Otherwise, check standard placement fit
	var item_size: Vector2i = item.drag_preview.current_grid_size
	var valid := item_fits(grid_position, item_size, item)
	
	update_item_highlight(grid_position, item_size, valid)
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
		
	print("MOUSE POSITION: ", at_position)


	# Get the click offset from the drag data dictionary
	var click_offset: Vector2 = data.get("offset", Vector2.ZERO)

	# Calculate final grid position based on the top-left corner of the item box
	var item_top_left := at_position - click_offset + Vector2(34,32)
	var grid_position := Vector2i(
		floor(item_top_left.x / CELL_PITCH),
		floor(item_top_left.y / CELL_PITCH)
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
			elif event.keycode == KEY_H:
				spawn_item(handgun_data, 1)

			elif event.keycode == KEY_S:
				spawn_item(shotgun_data, 1)

			elif event.keycode == KEY_A:
				spawn_item(ammo_data, 10)

			elif event.keycode == KEY_M:
				spawn_item(medkit_data, 1)
		
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

	# Save the dimensions BEFORE rotation.
	var old_size: Vector2i = preview.current_grid_size

	# Save the mouse's position inside the item BEFORE rotation.
	var old_offset: Vector2 = active_drag_data.get("offset", Vector2.ZERO)

	# Rotate the preview.
	var new_rotation: int = (preview.rotation_state + 1) % 4
	preview.apply_rotation(new_rotation)

	# Calculate where that SAME mouse point should be
	# inside the newly rotated item.
	var new_offset : Vector2 = preview.rotate_offset_90_degrees(
		old_offset,
		old_size
	)

	# Save the new offset.
	active_drag_data["offset"] = new_offset

	# Keep the same point of the gun underneath the mouse.
	preview.position = -new_offset


	# UPDATE HIGHLIGHT IMMEDIATELY
	
	var mouse_position := get_global_mouse_position()

	# Convert mouse position to inventory coordinates
	var at_position := mouse_position - global_position

	# Use the same calculation you use while dragging
	var item_top_left := at_position - new_offset + Vector2(34, 32)

	var new_grid_position := Vector2i(
		floor(item_top_left.x / CELL_PITCH),
		floor(item_top_left.y / CELL_PITCH)
	)

	current_highlight_grid_position = new_grid_position

	# Check using the NEW rotated size
	var valid := item_fits(
		new_grid_position,
		preview.current_grid_size,
		item
	)

	update_item_highlight(
		new_grid_position,
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
		if not other is InventoryItem or not other.visible or other == exclude:
			continue

		# Use floor to ensure consistent integer grid mapping with cell coordinates
		var other_pos := Vector2i(
			floor(other.position.x / CELL_PITCH),
			floor(other.position.y / CELL_PITCH)
		)
		var other_size: Vector2i = other.current_grid_size

		# Check if the target cell falls anywhere within the item's grid bounds
		if cell.x >= other_pos.x and cell.x < (other_pos.x + other_size.x) \
		and cell.y >= other_pos.y and cell.y < (other_pos.y + other_size.y):
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
	
func create_item_context_menu():
	item_context_menu = PopupMenu.new()

	item_context_menu.add_item("Split", MENU_SPLIT)
	item_context_menu.add_item("Consume", MENU_CONSUME)

	item_context_menu.id_pressed.connect(_on_context_menu_pressed)

	add_child(item_context_menu)

	item_context_menu.hide()


func _on_context_menu_pressed(id: int):
	if context_menu_item == null:
		return

	var item := context_menu_item
	context_menu_item = null

	match id:
		MENU_SPLIT:
			split_item(item)

		MENU_CONSUME:
			consume_item(item)
			
			
func show_item_context_menu(item: InventoryItem):
	if item == null or item.item_data == null:
		return

	context_menu_item = item

	item_context_menu.clear()

	# Split
	if item.item_data.stackable and item.quantity > 1:
		item_context_menu.add_item("Split", MENU_SPLIT)

	# Consume
	if item.item_data.consumable:
		item_context_menu.add_item("Consume", MENU_CONSUME)

	# Don't show an empty menu.
	if item_context_menu.item_count == 0:
		context_menu_item = null
		return

	var mouse_position := get_global_mouse_position()

	item_context_menu.position = Vector2i(mouse_position)
	item_context_menu.popup()
	
	
func split_item(item: InventoryItem):
	if item == null:
		return

	if item.item_data == null:
		return

	if not item.item_data.stackable:
		return

	if item.quantity <= 1:
		return

	var split_quantity := item.quantity / 2
	var remaining_quantity := item.quantity - split_quantity

	# Find an empty space in the inventory.
	var empty_position := find_empty_position(item.current_grid_size)

	if empty_position == Vector2i(-1, -1):
		print("No room to split stack.")
		return

	# Keep the original item with the remaining quantity.
	item.quantity = remaining_quantity

	# Create the new half.
	var new_item := item.duplicate()

	new_item.quantity = split_quantity
	new_item.rotation_state = item.rotation_state
	new_item.current_grid_size = item.current_grid_size
	new_item.position = Vector2(
		empty_position.x * CELL_PITCH,
		empty_position.y * CELL_PITCH
	)

	new_item.visible = true
	new_item.drag_preview = null

	item_layer.add_child(new_item)

	new_item.setup_item()
	new_item.apply_rotation(item.rotation_state)

	print(
		"Split ",
		item.item_data.item_name,
		": ",
		remaining_quantity,
		" + ",
		split_quantity
	)
	
func find_empty_position(item_size: Vector2i) -> Vector2i:
	for y in range(INVENTORY_HEIGHT):
		for x in range(INVENTORY_WIDTH):

			var position := Vector2i(x, y)

			if item_fits(position, item_size):
				return position

	return Vector2i(-1, -1)
	
func consume_item(item: InventoryItem):
	if item == null:
		return

	if item.item_data == null:
		return

	if not item.item_data.consumable:
		return


	item.quantity -= 1

	if item.quantity <= 0:
		item.queue_free()

	print("Consumed: ", item.item_data.item_name)


func spawn_item(item_data: ItemData, quantity: int = 1):
	if item_data == null:
		return

	# Find an empty position for a new item.
	var empty_position := find_empty_position(item_data.grid_size)

	if empty_position == Vector2i(-1, -1):
		show_inventory_message(
			"No room for %s!" % item_data.item_name
		)
		return

	# Create the item.
	var new_item := item_scene.instantiate() as InventoryItem

	new_item.item_data = item_data
	new_item.quantity = quantity

	item_layer.add_child(new_item)

	# Position it on the grid.
	new_item.position = Vector2(
		empty_position.x * CELL_PITCH,
		empty_position.y * CELL_PITCH
	)

	# Make sure the quantity display updates.
	new_item.update_count_label()

	show_inventory_message("Spawned %s" % item_data.item_name)
	



func show_inventory_message(message: String):
	message_label.text = message
	message_label.visible = true

	await get_tree().create_timer(2.0).timeout

	# Don't erase a newer message.
	if message_label.text == message:
		message_label.visible = false
