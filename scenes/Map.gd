extends TileMap

var map = FastNoiseLite.new()
var width = 70
var height = 50
var level = 1
@onready var player = get_parent().get_child(1)

# Called when the node enters the scene tree for the first time.
func _ready():
	map.seed = randi()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	generate_chunk(player.position)
	
func generate_chunk(position):
	var tile_pos = local_to_map(position)
	for x in range(width):
		for y in range(height):
			var floor_map = map.get_noise_2d(tile_pos.x - width/2 + x, tile_pos.y - height/2 + y)*10
			#set_cell(0,Vector2i(tile_pos.x - width/2 + x, tile_pos.y - height/2 + y),rng.randi_range(first_floor_tile_id,last_floor_tile_id),Vector2i(0,0))
			set_cell(0,Vector2i(tile_pos.x - width/2 + x, tile_pos.y - height/2 + y),level,Vector2i(round((floor_map+10)/1.3),0))
