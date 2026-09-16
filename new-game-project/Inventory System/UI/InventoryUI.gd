extends Control

const CELL_SIZE := 68

@onready var item_layer: Control = $Panel/InventoryArea/ItemLayer

var handgun_data: ItemData = preload("res://Inventory System/Items/handgun.tres")
var shotgun_data: ItemData = preload("res://Inventory System/Items/shotgun.tres")
var ammo_data: ItemData = preload("res://Inventory System/Items/ammo.tres")
var medkit_data: ItemData = preload("res://Inventory System/Items/medkit.tres")
var item_scene: PackedScene = preload("res://Inventory System/UI/InventoryItem.tscn")


func _ready():
	create_handgun(0,0)
	create_handgun(0,5)
	create_shotgun(2,2)
	create_ammo(4,0,5)
	create_ammo(5,0,25)
	create_medkit(7,7,2)
	create_medkit(7,6,1)
	
func create_handgun(x: int, y: int):
	var handgun := item_scene.instantiate() as InventoryItem

	handgun.item_data = handgun_data

	item_layer.add_child(handgun)

	# Put handgun at grid position (0, 0)
	handgun.position = Vector2(
		x * CELL_SIZE,
		y * CELL_SIZE
	)

func create_shotgun(x: int, y: int):
	var shotgun := item_scene.instantiate() as InventoryItem

	shotgun.item_data = shotgun_data

	item_layer.add_child(shotgun)
	# Put handgun at grid position (0, 0)
	shotgun.position = Vector2(
		x * CELL_SIZE,
		y * CELL_SIZE
	)
	
func create_ammo(x: int, y: int, quantity: int):
	var ammo :=  item_scene.instantiate() as InventoryItem

	ammo.item_data = ammo_data
	
	item_layer.add_child(ammo)
	ammo.quantity = quantity
	# Put handgun at grid position (0, 0)
	ammo.position = Vector2(
		x * CELL_SIZE,
		y * CELL_SIZE
	)


func create_medkit(x: int, y: int, quantity: int):
	var medkit :=  item_scene.instantiate() as InventoryItem

	medkit.item_data = medkit_data
	
	item_layer.add_child(medkit)
	medkit.quantity = quantity
	# Put handgun at grid position (0, 0)
	medkit.position = Vector2(
		x * CELL_SIZE,
		y * CELL_SIZE
	)
