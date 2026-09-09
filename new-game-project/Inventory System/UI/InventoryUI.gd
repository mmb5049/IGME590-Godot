extends Control

const CELL_SIZE := 64

@onready var item_layer: Control = $Panel/InventoryArea/ItemLayer

var handgun_data: ItemData = preload("res://Inventory System/Items/handgun.tres")
var item_scene: PackedScene = preload("res://Inventory System/UI/InventoryItem.tscn")


func _ready():
	create_handgun()


func create_handgun():
	var handgun := item_scene.instantiate() as InventoryItem

	handgun.item_data = handgun_data

	item_layer.add_child(handgun)

	# Put handgun at grid position (0, 0)
	handgun.position = Vector2(
		0 * CELL_SIZE,
		0 * CELL_SIZE
	)
