extends Control

const CELL_SIZE := 68

@onready var item_layer: Control = $Panel/InventoryArea/ItemLayer

var handgun_data: ItemData = preload("res://Inventory System/Items/handgun.tres")
var shotgun_data: ItemData = preload("res://Inventory System/Items/shotgun.tres")
var item_scene: PackedScene = preload("res://Inventory System/UI/InventoryItem.tscn")


func _ready():
	create_handgun()
	create_shotgun()

func create_handgun():
	var handgun := item_scene.instantiate() as InventoryItem

	handgun.item_data = handgun_data

	item_layer.add_child(handgun)

	# Put handgun at grid position (0, 0)
	handgun.position = Vector2(
		0 * CELL_SIZE,
		0 * CELL_SIZE
	)

func create_shotgun():
	var shotgun := item_scene.instantiate() as InventoryItem

	shotgun.item_data = shotgun_data

	item_layer.add_child(shotgun)

	# Put handgun at grid position (0, 0)
	shotgun.position = Vector2(
		2 * CELL_SIZE,
		2 * CELL_SIZE
	)
