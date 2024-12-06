@tool
class_name BoardCreator
extends Node

@export var width: int = 10
@export var depth: int = 10
@export var height: int = 8
@export var pos: Vector2i
var _oldPos: Vector2i
var tiles = {}

var tileViewPrefab = preload("res://Prefabs/Tile.tscn")
var tileSelectionIndicatorPrefab = preload("res://Prefabs/Tile Selection Indicator.tscn")
var marker
var _random = RandomNumberGenerator.new()
var savePath = "res://Data/Levels/"
@export var fileName = "defaultMap.txt"

var selectedTileColor:Color = Color(0, 1, 1, 1)
var defaultTileColor:Color = Color(1, 1, 1, 1)

func Clear():
	for key in tiles:
		tiles[key].free()
	tiles.clear()
	
func Grow():
	_GrowSingle(pos)

func Shrink():
	_ShrinkSingle(pos)
	
func _GrowSingle(p: Vector2i):
	var t: Tile = _GetOrCreate(p)
	if t.height < height:
		t.Grow()
		_UpdateMarker()

func _ShrinkSingle(p: Vector2i):
	if not tiles.has(p):
		return
	
	var t: Tile = tiles[p]
	t.Shrink()
	_UpdateMarker()
	
	if t.height <= 0:
		tiles.erase(p)
		t.free()
		
func _GetOrCreate(p: Vector2i):
	if tiles.has(p):
		return tiles[p]
	
	var t: Tile = _Create()
	t.Load(p, 0)
	tiles[p] = t
	
	return t

func _Create():
	var instance = tileViewPrefab.instantiate()
	add_child(instance)
	return instance

func GrowArea():
	var r: Rect2i = _RandomRect()
	_GrowRect(r)

func ShrinkArea():
	var r: Rect2i = _RandomRect()
	_ShrinkRect(r)
	
func Save():
	var saveFile = savePath + fileName
	SaveMap(saveFile)
	
func Load():
	var saveFile = savePath + fileName
	LoadMap(saveFile)

func SaveJSON():
	#var saveFile = savePath + fileName
	#var save_game = FileAccess.open(saveFile, FileAccess.WRITE)
	var saveFile = "res://Data/Levels/savegame.json"
	SaveMapJSON(saveFile)
	
func LoadJSON():
	#var saveFile = savePath + fileName
	#var save_game = FileAccess.open(saveFile, FileAccess.WRITE)
	var saveFile = "res://Data/Levels/savegame.json"
	LoadMapJSON(saveFile)
	
func SaveMap(saveFile):
	var save_game = FileAccess.open(saveFile, FileAccess.WRITE)
	var version = 1
	var size = tiles.size()
	
	save_game.store_8(version)
	save_game.store_16(size)

	for key in tiles:
		save_game.store_8(key.x)
		save_game.store_8(key.y)
		save_game.store_8(tiles[key].height)
		
	save_game.close()

func LoadMap(saveFile):
	Clear()	

	if not FileAccess.file_exists(saveFile):
		return # Error! We don't have a save to load.
		
	var save_game = FileAccess.open(saveFile, FileAccess.READ)
	var version = save_game.get_8()
	var size = save_game.get_16()
	
	for i in range(size):
		var save_x = save_game.get_8()
		var save_z = save_game.get_8()
		var save_height = save_game.get_8()
		
		var t: Tile = _Create()
		t.Load(Vector2i(save_x, save_z) , save_height)
		tiles[Vector2i(t.pos.x,t.pos.y)] = t	
	
	save_game.close()
	_UpdateMarker()

func SaveMapJSON(saveFile):
	var main_dict = {
		"version": "1.0.0",
		"tiles": []
	}
		
	for key in tiles:
		var save_dict = {
			"pos_x" : tiles[key].pos.x,
			"pos_z" : tiles[key].pos.y,
			"height" : tiles[key].height
			}
		main_dict["tiles"].append(save_dict)

	var save_game = FileAccess.open(saveFile, FileAccess.WRITE)
	
	var json_string = JSON.stringify(main_dict, "\t", false)
	save_game.store_line(json_string)

func LoadMapJSON(saveFile):
	Clear()

	if not FileAccess.file_exists(saveFile):
		return # Error! We don't have a save to load.
		
	var save_game = FileAccess.open(saveFile, FileAccess.READ)	

	var json_text = save_game.get_as_text()	
	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		print("Error %s reading json file." % parse_result)
		return
		
	var data = {}
	data = json.get_data()

	for mtile in data["tiles"]:
		var t: Tile = _Create()
		t.Load(Vector2(mtile["pos_x"], mtile["pos_z"]) , mtile["height"])
		tiles[Vector2i(t.pos.x,t.pos.y)] = t
	
	save_game.close()
	_UpdateMarker()

func _ready(): 
	marker = tileSelectionIndicatorPrefab.instantiate()
	add_child(marker)
	
	pos = Vector2i(0,0)
	_oldPos = pos
	
	_random.randomize()

func _process(delta):
	if pos != _oldPos:
		_oldPos = pos
		_UpdateMarker()
		
func _UpdateMarker():
	if tiles.has(pos):
		var t: Tile = tiles[pos]
		marker.position = t.center()
	else:
		marker.position = Vector3(pos.x, 0, pos.y)

func _RandomRect():
	var x = _random.randi_range(0, width - 1)
	var y = _random.randi_range(0, depth - 1)
	var w = _random.randi_range(1, width - x)
	var h = _random.randi_range(1, depth - y)
	return Rect2i ( x, y, w, h )

func _GrowRect(rect: Rect2i):
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			var p = Vector2i(x,y)
			_GrowSingle(p)

func _ShrinkRect(rect: Rect2i):
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			var p = Vector2i(x,y)
			_ShrinkSingle(p)

func ClearSearch():
	for key in tiles:
		tiles[key].prev = null
		tiles[key].distance = 2147483647 #max signed 32bit number
		
func GetTile(p: Vector2i):
	return tiles[p] if tiles.has(p) else null
	
func Search(start: Tile, addTile: Callable):
	var retValue = []
	retValue.append(start)	
	ClearSearch()
	var checkNext = []
	start.distance = 0
	checkNext.push_back(start)
	
	var _dirs = [Vector2i(0,1), Vector2i(0,-1), Vector2i(1,0), Vector2i(-1,0)]
	
	while checkNext.size() > 0:
		var t:Tile = checkNext.pop_front()
		_dirs.shuffle() #Optional. May impact performance
		for i in _dirs.size():
			var next:Tile = GetTile(t.pos + _dirs[i])
			if next == null || next.distance <= t.distance + 1:
					continue
			if addTile.call(t, next):
				next.distance = t.distance + 1
				next.prev = t
				checkNext.push_back(next)
				retValue.append(next)
	return retValue

func SelectTiles(tileList:Array):	
	for i in tileList.size():
		tileList[i].get_node("MeshInstance3D").material_override.albedo_color = selectedTileColor

func DeSelectTiles(tileList:Array):
	for i in tileList.size():
		tileList[i].get_node("MeshInstance3D").material_override.albedo_color = defaultTileColor
		
func RangeSearch(start: Tile, addTile: Callable, range: int):
	var retValue = []
	ClearSearch()
	start.distance = 0
	
	for y in range(-range, range+1):
		for x in range(-range + abs(y), range - abs(y) +1):
			var next:Tile = GetTile(start.pos + Vector2i(x,y))
			if next == null:
				continue
				
			if next == start:
				retValue.append(start)
			elif addTile.call(start, next):
				next.distance = (abs(x) + abs(y))
				next.prev = start
				retValue.append(next)
	
	return retValue
