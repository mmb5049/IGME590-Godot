extends GridContainer

const WIDTH := 10
const HEIGHT := 8

@export var slot_scene: PackedScene


func _ready():
	create_grid()


func create_grid():
	for child in get_children():
		child.queue_free()

	for i in range(WIDTH * HEIGHT):
		var slot = slot_scene.instantiate()
		add_child(slot)
