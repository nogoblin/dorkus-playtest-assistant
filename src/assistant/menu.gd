extends PopupMenu


signal menu_initialized(popup)

# TODO id vs index is annoying to manage
# these are IDs
enum {
	START_STOP_RECORDING = 0,
	SAVE_REPLAY = 1,
	TAKE_SCREENSHOT = 8,
	OPEN_RECORDING_FOLDER = 2,
	OPTIONS = 4,
}

const OPTIONS_WINDOW : PackedScene = preload("res://src/windows/options_window.tscn")
const OBS_COMMANDS = {
	START_STOP_RECORDING: "ToggleRecord",
	SAVE_REPLAY: "SaveReplayBuffer",
	TAKE_SCREENSHOT: [
		"SaveSourceScreenshot",
		{
			"sourceName": "Game Capture",
			"imageFormat": "png",
			"imageFilePath": "D:/Screenshots/test/test.png"
		}
	],
	OPEN_RECORDING_FOLDER: [
		"GetProfileParameter",
		{
			"parameterCategory": "AdvOut",
			"parameterName": "RecFilePath"
		}
	],
}


func _ready():
	OBSHelper.record_state_changed.connect(
		func(is_recording : bool):
			set_item_text(
				get_item_index(START_STOP_RECORDING),
				"%s Recording" % ("Stop" if is_recording else "Start")
			)
	)

	if not Config.get_value("Assistant", "OptionsAccess"):
		var options_index = get_item_index(OPTIONS)
		remove_item(options_index)
		remove_item(options_index - 1)
		reset_size()

	# change anim on show/hide popup
	about_to_popup.connect(
		func():
			set_item_disabled(SAVE_REPLAY, not Config.get_value("OBS", "ReplayBuffer"))
			StateMachine.state_updated.emit(StateMachine.MENU_OPENED)
	)
	popup_hide.connect(
		func():
			StateMachine.state_updated.emit(StateMachine.IDLE)
	)


func _on_id_pressed(id:int):
	if id in OBS_COMMANDS.keys():
		var command = OBS_COMMANDS[id]
		var params = null

		if command is Array:
			params = command[1]
			command = command[0]

		StateMachine.state_updated.emit(StateMachine.LOADING)
		OBSHelper.send_command(command, params if params != null else {})
		return
	
	if id == OPTIONS:
		get_tree().get_root().add_child(OPTIONS_WINDOW.instantiate())
		StateMachine.state_updated.emit(StateMachine.WAITING)

	
	# TODO look into dynamic resolution setting - must happen with record/replay buffer off
	# OBSHelper.send_command(
	# 	"SetVideoSettings",
	# 	{
	# 		"baseWidth": DisplayServer.screen_get_size().x,
	# 		"baseHeight": DisplayServer.screen_get_size().y
	# 	}
	# )
