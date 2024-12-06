extends Node
class_name BattleController

@export var board: BoardCreator
@export var inputController: InputController
@export var cameraController: CameraController
@export var stateMachine: StateMachine
@export var startState: State

#var heroPrefab = preload("res://Prefabs/Hero.tscn")#replaced by @export/PackedScene
@export var heroPrefab: PackedScene

var currentUnit:Unit

var currentTile:Tile: 
	get: return board.GetTile(board.pos)

func _ready():
	stateMachine.ChangeState(startState)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
