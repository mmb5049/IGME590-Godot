class_name ItemData
extends Resource

enum ConsumeEffect 
{ 
	NONE, 
	HEAL, 
	RESTORE_MANA, 
	RESTORE_STAMINA, 
	REMOVE_HUNGER, 
}

@export var item_name: String
@export var icon: Texture2D

@export var grid_size: Vector2i = Vector2i(1, 1)

@export var stackable: bool = false
@export var max_stack: int = 1
@export var consumable: bool = false
@export var consume_effect: ConsumeEffect = ConsumeEffect.NONE
