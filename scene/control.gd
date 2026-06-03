extends Control

@onready var watcher: DirectoryWatcher = $DirectoryWatcher
@onready var file_dialog: FileDialog = $FileDialog
var current_use_filedialog = ""

var ITEM = preload("uid://7lwino4j4r6u")
@onready var main_container_scroll_container: ScrollContainer = $VBoxContainer/Panel/MarginContainer2/ScrollContainer
@onready var main_container: VBoxContainer = %main_container

var scan_dir = ""
@onready var scan_path_line_edit: LineEdit = $VBoxContainer/MarginContainer3/HBoxContainer/VBoxContainer/sc_dir/scan_path_LineEdit
@onready var recursive: CheckBox = $VBoxContainer/MarginContainer3/HBoxContainer/VBoxContainer/recursive
@onready var scaning_log: LineEdit = $VBoxContainer/scanlog_HBoxContainer/scaning_log
@onready var scanlog_h_box_container: HBoxContainer = $VBoxContainer/scanlog_HBoxContainer


var ITEM_SETTING = preload("uid://ch3jkxera3e1f")
@onready var setup_list: VBoxContainer = $VBoxContainer/MarginContainer3/HBoxContainer/setup_list
@onready var setup_list_label: Label = $VBoxContainer/MarginContainer3/HBoxContainer/setup_list/setup_list_label
@onready var setup_list_line_edit: LineEdit = $VBoxContainer/MarginContainer3/HBoxContainer/setup_list/setup_list_LineEdit
@onready var setup_list_v_box_container: VBoxContainer = $VBoxContainer/MarginContainer3/HBoxContainer/setup_list/ScrollContainer/setup_list_VBoxContainer
@onready var setup_list_selectfolder_button: Button = $VBoxContainer/MarginContainer3/HBoxContainer/setup_list/setup_list_selectfolder_Button

@onready var dc_webhook_line_edit: LineEdit = $VBoxContainer/MarginContainer3/HBoxContainer/VBoxContainer/dc_webhook/dc_webhook_LineEdit
@onready var dc_mention_option_button: OptionButton = $VBoxContainer/MarginContainer3/HBoxContainer/VBoxContainer/dc_mention/dc_mention_OptionButton
@onready var dc_mention_id_line_edit: LineEdit = $VBoxContainer/MarginContainer3/HBoxContainer/VBoxContainer/dc_mention_id/dc_mention_id_LineEdit

@onready var start_button: Button = $VBoxContainer/Panel2/MarginContainer/HBoxContainer/start
@onready var stop_button: Button = $VBoxContainer/Panel2/MarginContainer/HBoxContainer/stop

@onready var item_timeout_line_edit: LineEdit = $VBoxContainer/MarginContainer3/HBoxContainer/VBoxContainer2/item_lifetime_container/item_timeout_LineEdit


var exclude_extensions: Array[String] = ["import", "tmp", "uid", "godot", "cfg"]
var exclude_folder: Array[String] = []

var dc_webhook_url: String
var _is_running := false

var _editing_item: HBoxContainer = null
var _editing_mode := ""

const CONFIG_PATH = "user://sdl_user.cfg"
const app_data_path = "user://"

@onready var autostart_check_box: CheckBox = $VBoxContainer/MarginContainer3/HBoxContainer/VBoxContainer2/autostart_CheckBox
@onready var dc_push_created_check_box: CheckBox = $VBoxContainer/MarginContainer3/HBoxContainer/VBoxContainer2/dc_push_created_CheckBox
@onready var dc_push_deleted_check_box: CheckBox = $VBoxContainer/MarginContainer3/HBoxContainer/VBoxContainer2/dc_push_deleted_CheckBox
@onready var dc_push_modified_check_box: CheckBox = $VBoxContainer/MarginContainer3/HBoxContainer/VBoxContainer2/dc_push_modified_CheckBox


var is_autostart:bool
var is_discord_created_push:bool
var is_discord_deleted_push:bool
var is_discord_modified_push:bool

var item_life:int


func _ready() -> void:
	load_config()
	
	if is_autostart:
		_start_watcher()
	else :
		watcher.set_process(false)
		_is_running = false
	_update_button_states()
	_update_mention_id_visibility()
	dc_mention_option_button.item_selected.connect(_on_mention_option_changed)


# ─────────────────────────────────────────────
#  SAVE & LOAD CONFIG
# ─────────────────────────────────────────────

func save_config() -> void:
	var config := ConfigFile.new()
	# Load dulu supaya tidak menghapus key lain
	config.load(CONFIG_PATH)

	config.set_value("webhooks", "webhook_url", dc_webhook_line_edit.text.strip_edges())
	config.set_value("webhooks", "mention_type", dc_mention_option_button.selected)
	config.set_value("webhooks", "mention_id", dc_mention_id_line_edit.text.strip_edges())

	config.set_value("settings", "scan_dir", scan_path_line_edit.text.strip_edges())
	config.set_value("settings", "recursive", watcher.recursive)
	config.set_value("settings", "is_autostart", is_autostart)
	config.set_value("settings", "is_discord_created_push", is_discord_created_push)
	config.set_value("settings", "is_discord_deleted_push", is_discord_deleted_push)
	config.set_value("settings", "is_discord_modified_push", is_discord_modified_push)
	config.set_value("settings", "item_life", item_life)

	config.set_value("excludes", "folders", exclude_folder)
	config.set_value("excludes", "extensions", exclude_extensions)
	

	var err := config.save(CONFIG_PATH)
	if err == OK:
		_log_status("Config saved.")
	else:
		push_error("Gagal menyimpan config: %s" % error_string(err))


func load_config() -> void:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)

	if err != OK:
		push_warning("Config tidak ditemukan, pakai nilai default.")
		return

	# Discord
	dc_webhook_url = config.get_value("webhooks", "webhook_url", "")
	dc_webhook_line_edit.text = dc_webhook_url
	dc_mention_option_button.select(config.get_value("webhooks", "mention_type", 0))
	dc_mention_id_line_edit.text = config.get_value("webhooks", "mention_id", "")

	# Scan dir
	scan_dir = config.get_value("settings", "scan_dir", "")
	if not scan_dir.is_empty():
		scan_path_line_edit.text = scan_dir

	var is_recursive = config.get_value("settings", "recursive", true)
	recursive.button_pressed = is_recursive
	watcher.recursive = is_recursive  # ← tambahkan ini
	
	is_autostart = config.get_value("settings", "is_autostart", false)
	autostart_check_box.button_pressed = is_autostart
	
	is_discord_created_push = config.get_value("settings", "is_discord_created_push", true)
	dc_push_created_check_box.button_pressed = is_discord_created_push
	
	is_discord_deleted_push = config.get_value("settings", "is_discord_deleted_push", true)
	dc_push_deleted_check_box.button_pressed = is_discord_deleted_push
	
	is_discord_modified_push = config.get_value("settings", "is_discord_modified_push", true)
	dc_push_modified_check_box.button_pressed = is_discord_modified_push
	
	watcher.push_created  = is_discord_created_push
	watcher.push_deleted  = is_discord_deleted_push
	watcher.push_modified = is_discord_modified_push
	
	item_life = config.get_value("settings", "item_life", 300.0)
	item_timeout_line_edit.text = str(item_life)

	# Excludes — fallback ke default hardcode kalau belum pernah disimpan
	exclude_folder.assign(config.get_value("excludes", "folders", exclude_folder))
	exclude_extensions.assign(config.get_value("excludes", "extensions", exclude_extensions))

	print("Config berhasil dimuat.")


# ─────────────────────────────────────────────
#  WATCHER CONTROL
# ─────────────────────────────────────────────

func _apply_settings_to_watcher() -> void:
	for dir in watcher._directory_cache.duplicate():
		watcher.remove_scan_directory(dir)

	var target_dir = scan_path_line_edit.text.strip_edges()
	print("target_dir = '", target_dir, "'")
	print("scan_dir = '", scan_dir, "'")
	if target_dir.is_empty():
		target_dir = scan_dir
	else:
		scan_dir = target_dir

	if not target_dir.is_empty():
		watcher.add_scan_directory(target_dir)

	watcher.add_excludes(exclude_folder)
	watcher.add_exclude_extensions(exclude_extensions)

	watcher.discord_webhook_url = dc_webhook_line_edit.text.strip_edges()
	watcher.mention_type = dc_mention_option_button.selected as DirectoryWatcher.MentionType
	watcher.mention_id = dc_mention_id_line_edit.text.strip_edges()


func _start_watcher() -> void:
	if _is_running:
		return
	_apply_settings_to_watcher()
	watcher.set_process(true)
	_is_running = true
	_update_button_states()
	_log_status("Watcher started — scanning: %s" % scan_dir)
	scanlog_h_box_container.show()


func _stop_watcher() -> void:
	if not _is_running:
		return
	watcher.set_process(false)
	_is_running = false
	_update_button_states()
	_log_status("Watcher stopped.")


func _restart_watcher() -> void:
	_stop_watcher()
	watcher._directory_list.clear()
	watcher._directory_cache.clear()
	watcher._current_directory_index = 0
	watcher._current_directory_name = ""
	watcher._current_delay = watcher.scan_delay
	watcher._remaining_steps = watcher.scan_step
	await get_tree().process_frame
	_start_watcher()
	_log_status("Watcher restarted.")


func _update_button_states() -> void:
	if not is_node_ready():
		return
	start_button.disabled = _is_running
	stop_button.disabled = not _is_running


func _log_status(msg: String) -> void:
	var t = Time.get_datetime_string_from_system()
	var i = ITEM.instantiate()
	main_container.add_child(i)
	i.date.text = t
	i.jenis.text = "info"
	i.nama.text = msg
	i.path_label.text = ""
	i.go_btn.hide()
	i.jenis.add_theme_color_override("font_color", Color.GRAY)
	i.finish_init_data = true
	i.lifetime_timeout.start(item_life)
	await get_tree().process_frame
	var scrollbar = main_container_scroll_container.get_v_scroll_bar()
	main_container_scroll_container.scroll_vertical = scrollbar.max_value


# ─────────────────────────────────────────────
#  WATCHER SIGNALS
# ─────────────────────────────────────────────

func _on_directory_watcher_files_created(files: PackedStringArray) -> void:
	var t = Time.get_datetime_string_from_system()
	for file in files:
		var i = ITEM.instantiate()
		main_container.add_child(i)
		i.date.text = t
		i.jenis.text = "created"
		i.nama.text = file.get_file()
		i.path_label.text = file
		i.jenis.add_theme_color_override("font_color", Color.GREEN)
		i.finish_init_data = true
		i.lifetime_timeout.start(item_life)
	await get_tree().process_frame
	var scrollbar = main_container_scroll_container.get_v_scroll_bar()
	main_container_scroll_container.scroll_vertical = scrollbar.max_value


func _on_directory_watcher_files_deleted(files: PackedStringArray) -> void:
	var t = Time.get_datetime_string_from_system()
	for file in files:
		var i = ITEM.instantiate()
		main_container.add_child(i)
		i.go_btn.hide()
		i.date.text = t
		i.jenis.text = "deleted"
		i.nama.text = file.get_file()
		i.path_label.text = file
		i.jenis.add_theme_color_override("font_color", Color.RED)
		i.finish_init_data = true
		i.lifetime_timeout.start(item_life)
	await get_tree().process_frame
	var scrollbar = main_container_scroll_container.get_v_scroll_bar()
	main_container_scroll_container.scroll_vertical = scrollbar.max_value


func _on_directory_watcher_files_modified(files: PackedStringArray) -> void:
	var t = Time.get_datetime_string_from_system()
	for file in files:
		var i = ITEM.instantiate()
		main_container.add_child(i)
		i.date.text = t
		i.jenis.text = "modified"
		i.nama.text = file.get_file()
		i.path_label.text = file
		i.jenis.add_theme_color_override("font_color", Color.ORANGE)
		i.finish_init_data = true
		i.lifetime_timeout.start(item_life)
	await get_tree().process_frame
	var scrollbar = main_container_scroll_container.get_v_scroll_bar()
	main_container_scroll_container.scroll_vertical = scrollbar.max_value


# ─────────────────────────────────────────────
#  BUTTON HANDLERS: START / STOP / RESTART
# ─────────────────────────────────────────────

func _on_start_pressed() -> void:
	_start_watcher()


func _on_stop_pressed() -> void:
	_stop_watcher()


func _on_restart_pressed() -> void:
	_restart_watcher()


# ─────────────────────────────────────────────
#  SCAN DIRECTORY
# ─────────────────────────────────────────────

func _on_scan_button_pressed() -> void:
	current_use_filedialog = "scan_folder"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.popup_centered()


func _on_file_dialog_dir_selected(dir: String) -> void:
	match current_use_filedialog:
		"scan_folder":
			scan_path_line_edit.text = dir
			scan_dir = dir
		"exclude_folder":
			setup_list_line_edit.text = dir



# ─────────────────────────────────────────────
#  SETUP LIST: EXCLUDE FOLDER & EXTENSION
# ─────────────────────────────────────────────

func _on_e_fol_button_pressed() -> void:
	_clear_setup_list()
	setup_list_label.text = "exclude folder list"
	setup_list.show()
	setup_list_selectfolder_button.show()
	_editing_mode = "exclude_folder"
	for path in exclude_folder:
		_add_item_setting(path)


func _on_e_ex_button_pressed() -> void:
	_clear_setup_list()
	setup_list_label.text = "exclude extension list"
	setup_list.show()
	setup_list_selectfolder_button.hide()
	_editing_mode = "exclude_extension"
	for ext in exclude_extensions:
		_add_item_setting(ext)


func _clear_setup_list() -> void:
	for i in setup_list_v_box_container.get_children():
		i.queue_free()


func _add_item_setting(value: String) -> HBoxContainer:
	var x = ITEM_SETTING.instantiate()
	setup_list_v_box_container.add_child(x)
	x.name_item.text = value
	x.delete_requested.connect(_on_item_setting_delete)
	x.edit_requested.connect(_on_item_setting_edit)
	return x


func _on_setup_list_add_pressed() -> void:
	# Kalau sedang mode edit item, jalankan update
	if _editing_item != null:
		_on_setup_list_add_pressed_with_edit()
		return

	var val = setup_list_line_edit.text.strip_edges()
	if val.is_empty():
		return

	match _editing_mode:
		"exclude_folder":
			if not val in exclude_folder:
				exclude_folder.append(val)
				_add_item_setting(val)
		"exclude_extension":
			val = val.lstrip(".")
			if not val in exclude_extensions:
				exclude_extensions.append(val)
				_add_item_setting(val)

	setup_list_line_edit.text = ""


func _on_setup_list_save_pressed() -> void:
	setup_list.hide()
	_editing_item = null
	save_config()  # ← simpan saat user klik Save di panel list


func _on_setup_list_selectfolder_button_pressed() -> void:
	current_use_filedialog = "exclude_folder"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.popup_centered()


# ─────────────────────────────────────────────
#  ITEM SETTING: DELETE & EDIT
# ─────────────────────────────────────────────

func _on_item_setting_delete(item: HBoxContainer) -> void:
	var val = item.name_item.text
	match _editing_mode:
		"exclude_folder":
			exclude_folder.erase(val)
		"exclude_extension":
			exclude_extensions.erase(val)
	item.queue_free()


func _on_item_setting_edit(item: HBoxContainer, old_value: String) -> void:
	setup_list_line_edit.text = old_value
	_editing_item = item


func _on_setup_list_add_pressed_with_edit() -> void:
	var new_val = setup_list_line_edit.text.strip_edges()
	if new_val.is_empty():
		return
	var old_val = _editing_item.name_item.text
	match _editing_mode:
		"exclude_folder":
			var idx = exclude_folder.find(old_val)
			if idx != -1:
				exclude_folder[idx] = new_val
			_editing_item.name_item.text = new_val
		"exclude_extension":
			new_val = new_val.lstrip(".")
			var idx = exclude_extensions.find(old_val)
			if idx != -1:
				exclude_extensions[idx] = new_val
			_editing_item.name_item.text = new_val
	_editing_item = null
	setup_list_line_edit.text = ""


# ─────────────────────────────────────────────
#  DISCORD SETTINGS
# ─────────────────────────────────────────────

func _on_dc_webhook_button_pressed() -> void:
	watcher.discord_webhook_url = dc_webhook_line_edit.text.strip_edges()
	dc_webhook_url = dc_webhook_line_edit.text.strip_edges()
	save_config()
	_log_status("Discord webhook URL updated & saved.")


func _on_mention_option_changed(index: int) -> void:
	watcher.mention_type = index as DirectoryWatcher.MentionType
	_update_mention_id_visibility()


func _update_mention_id_visibility() -> void:
	var selected = dc_mention_option_button.selected
	var needs_id = selected == DirectoryWatcher.MentionType.ROLE or selected == DirectoryWatcher.MentionType.USER
	dc_mention_id_line_edit.get_parent().visible = needs_id


func _on_dc_mention_button_pressed() -> void:
	watcher.mention_type = dc_mention_option_button.selected as DirectoryWatcher.MentionType
	save_config()
	_log_status("Mention type saved.")


func _on_dc_mention_id_button_pressed() -> void:
	watcher.mention_id = dc_mention_id_line_edit.text.strip_edges()
	save_config()
	_log_status("Mention ID saved.")


# ─────────────────────────────────────────────
#  HELP
# ─────────────────────────────────────────────

func _on_help_pressed() -> void:
	OS.shell_open("https://github.com/bones-pup/simple-directory-logger")


# ─────────────────────────────────────────────
#  SCAN DIR APPLY (opsional, kalau ada tombol apply terpisah di UI)
# ─────────────────────────────────────────────



func _on_set_scan_button_pressed() -> void:
	scan_dir = scan_path_line_edit.text.strip_edges()
	save_config()
	_log_status("Scan directory saved: %s" % scan_dir)
	pass # Replace with function body.


func _on_recursive_pressed() -> void:
	watcher.recursive = recursive.button_pressed
	save_config()
	pass # Replace with function body.


func _on_directory_watcher_scan_completed() -> void:
	_log_status("scanning: done")
	scanlog_h_box_container.hide()
	pass # Replace with function body.


func _on_directory_watcher_scan_log(log_scan: String) -> void:
	scaning_log.text = log_scan
	pass # Replace with function body.


func _on_autostart_check_box_pressed() -> void:
	is_autostart = autostart_check_box.button_pressed
	save_config()
	pass # Replace with function body.


func _on_dc_push_created_check_box_pressed() -> void:
	is_discord_created_push = dc_push_created_check_box.button_pressed
	save_config()
	pass # Replace with function body.


func _on_dc_push_deleted_check_box_pressed() -> void:
	is_discord_deleted_push = dc_push_deleted_check_box.button_pressed
	save_config()
	pass # Replace with function body.


func _on_dc_push_modified_check_box_pressed() -> void:
	is_discord_modified_push = dc_push_modified_check_box.button_pressed
	save_config()
	pass # Replace with function body.


func _on_item_timeout_button_pressed() -> void:
	item_life = int(item_timeout_line_edit.text)
	save_config()
	pass # Replace with function body.


func _on_user_data_folder_button_pressed() -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(app_data_path))
	pass # Replace with function body.
