extends Node
class_name BattleController

@export var board: BoardCreator
@export var inputController: InputController
@export var cameraController: CameraController
@export var stateMachine: StateMachine
@export var startState: State

func _ready():
	stateMachine.ChangeState(startState)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
