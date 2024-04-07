extends TileMap

var moisture = FastNoiseLite.new()
var temperature = FastNoiseLite.new()
var altitude = FastNoiseLite.new()
var width = 70
var height = 50
var first_floor_tile_id = 342
var last_floor_tile_id = 511
@onready var player = get_parent().get_child(1)

# Called when the node enters the scene tree for the first time.
func _ready():
	moisture.seed = randi()
	temperature.seed = randi()
	altitude.seed = randi() # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	generate_chunk(player.position)
	
func generate_chunk(position):
	var tile_pos = local_to_map(position)
	for x in range(width):
		for y in range(height):
			var moist = moisture.get_noise_2d(tile_pos.x - width/2 + x, tile_pos.y - height/2 + y)
			var temp = temperature.get_noise_2d(tile_pos.x - width/2 + x, tile_pos.y - height/2 + y)
			var alt = altitude.get_noise_2d(tile_pos.x- width/2 + x, tile_pos.y - height/2 + y)
			#set_cell(0,Vector2i(tile_pos.x - width/2 + x, tile_pos.y - height/2 + y),randi_range(first_floor_tile_id,last_floor_tile_id),Vector2i(0,0))
			set_cell(0,Vector2i(tile_pos.x - width/2 + x, tile_pos.y - height/2 + y),first_floor_tile_id,Vector2i(0,0))
