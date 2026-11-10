extends SceneTree

const Progress = preload("res://GameProgress.gd")

func _initialize() -> void:
	call_deferred("_check")

func _settle() -> void:
	for frame in range(8):
		await process_frame

func _screen(menu: Control, level: int, missing: String, locked: int = 0) -> void:
	await _settle()
	var card := menu.find_child("LevelCard%d" % level, true, false) as Button
	assert(card != null and not card.disabled)
	var rect := card.get_global_rect()
	assert(absf(rect.get_center().x - menu.size.x / 2) < 3.0, "Selected level is off center")
	assert(menu.login_brand.get_global_rect().position.y >= 0)
	if not missing.is_empty(): assert(menu.find_child(missing, true, false) != null)
	if locked > 0:
		var neighbor := menu.find_child("LevelCard%d" % locked, true, false) as Button
		assert(neighbor != null and neighbor.size.x < card.size.x and neighbor.has_node("LockBadge"))
	assert(menu.find_child("PreviousLevel", true, false).disabled == (level == 1))
	assert(menu.find_child("NextLevel", true, false).disabled == (level == 3))
	assert(menu.help_button.visible and menu.lobby_badge.visible)
	print("Level ", level, " centered at ", rect.get_center(), " and navigation/lock checks passed")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		assert(image.save_png(OS.get_cmdline_user_args()[0] + "/Level-%d.png" % level) == OK)

func _check() -> void:
	root.size = Vector2i(1280, 720)
	set_meta("kitchen_language", 2)
	var scene := load("res://GameMenu.tscn") as PackedScene
	Progress.begin_guest()
	var menu := scene.instantiate()
	root.add_child(menu)
	await _screen(menu, 1, "NoPreviousLevel", 2)
	Progress.unlock_level(2)
	menu.find_child("NextLevel", true, false).pressed.emit()
	await _screen(menu, 2, "", 3)
	Progress.unlock_level(3)
	root.remove_child(menu)
	menu.queue_free()
	menu = scene.instantiate()
	root.add_child(menu)
	assert(menu.selected_stage == 3, "Returning player did not open on Level 3")
	await _screen(menu, 3, "NoNextLevel")
	quit()
