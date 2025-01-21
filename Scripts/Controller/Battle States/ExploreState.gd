extends BattleState

@export var commandSelectionState: State

func Enter():
	super()
	RefreshPrimaryStatPanel(_owner.board.pos)
	#RefreshSecondaryStatPanel(_owner.board.pos)

func Exit():
	super()
	await statPanelController.HidePrimary()
	#await statPanelController.HideSecondary()

func OnMove(e:Vector2i):
	var rotatedPoint = _owner.cameraController.AdjustedMovement(e)
	SelectTile(rotatedPoint + _owner.board.pos)
	RefreshPrimaryStatPanel(_owner.board.pos)
	#RefreshSecondaryStatPanel(_owner.board.pos)

func OnFire(e:int):
	print("Fire: " + str(e))
	if e == 0:
		_owner.stateMachine.ChangeState(commandSelectionState)

func Zoom(scroll: int):
	_owner.cameraController.Zoom(scroll)

func Orbit(direction: Vector2):
	_owner.cameraController.Orbit(direction)
