extends Control

@onready var watcher: DirectoryWatcher = $DirectoryWatcher
@onready var file_dialog: FileDialog = $FileDialog
var current_use_filedialog = ""

var ITEM = preload("uid://7lwino4j4r6u")
@onready var main_container_scroll_container: ScrollContainer = $VBoxContainer/Panel/MarginContainer2/ScrollContainer

@onready var main_container: VBoxContainer = %main_container

var scan_dir = ""
@onready var scan_path_line_edit: LineEdit = $VBoxContainer/MarginContainer3/HBoxContainer/VBoxContainer/sc_dir/scan_path_LineEdit

var ITEM_SETTING = preload("uid://ch3jkxera3e1f")
@onready var setup_list: VBoxContainer = $VBoxContainer/MarginContainer3/HBoxContainer/setup_list
@onready var setup_list_label: Label = $VBoxContainer/MarginContainer3/HBoxContainer/setup_list/setup_list_label
@onready var setup_list_line_edit: LineEdit = $VBoxContainer/MarginContainer3/HBoxContainer/setup_list/setup_list_LineEdit
@onready var setup_list_v_box_container: VBoxContainer = $VBoxContainer/MarginContainer3/HBoxContainer/setup_list/ScrollContainer/setup_list_VBoxContainer
@onready var setup_list_selectfolder_button: Button = $VBoxContainer/MarginContainer3/HBoxContainer/setup_list/setup_list_selectfolder_Button


var exclude_extensions:Array[String] = ["import", "tmp", "uid","godot","cfg"]
var exclude_folder:Array[String] = ["res://addons", "res://cache"]

var dc_webhook_url:String

func _ready() -> void:
	load_secret_config()
	watcher.discord_webhook_url = dc_webhook_url
	watcher.add_scan_directory(scan_dir)
	watcher.add_excludes(exclude_folder)
	watcher.add_exclude_extensions(exclude_extensions)
	pass
	

func _on_directory_watcher_files_created(files: PackedStringArray) -> void:
	var t = Time.get_datetime_string_from_system()
	for file in files:  # ← loop semua file
		var i = ITEM.instantiate()
		main_container.add_child(i)
		i.date.text = t
		i.jenis.text = "created"
		i.nama.text = file.get_file()  # nama file saja biar tidak terlalu panjang
		i.path_label.text = file # full path buat tombol go
		i.jenis.add_theme_color_override("font_color",Color.GREEN)
		await get_tree().process_frame
		var scrollbar = main_container_scroll_container.get_v_scroll_bar()
		main_container_scroll_container.scroll_vertical = scrollbar.max_value

		
	
	
	pass # Replace with function body.


func _on_directory_watcher_files_deleted(files: PackedStringArray) -> void:
	var t = Time.get_datetime_string_from_system()
	for file in files:  # ← loop semua file
		var i = ITEM.instantiate()
		main_container.add_child(i)
		i.go_btn.hide()
		i.date.text = t
		i.jenis.text = "deleted"
		i.nama.text = file.get_file()  # nama file saja biar tidak terlalu panjang
		i.path_label.text = file # full path buat tombol go
		i.jenis.add_theme_color_override("font_color",Color.RED)
		await get_tree().process_frame
		var scrollbar = main_container_scroll_container.get_v_scroll_bar()
		main_container_scroll_container.scroll_vertical = scrollbar.max_value
	pass # Replace with function body.


func _on_directory_watcher_files_modified(files: PackedStringArray) -> void:
	var t = Time.get_datetime_string_from_system()
	for file in files:  # ← loop semua file
		var i = ITEM.instantiate()
		main_container.add_child(i)
		i.date.text = t
		i.jenis.text = "deleted"
		i.nama.text = file.get_file()  # nama file saja biar tidak terlalu panjang
		i.path_label.text = file # full path buat tombol go
		i.jenis.add_theme_color_override("font_color",Color.ORANGE)
		await get_tree().process_frame
		var scrollbar = main_container_scroll_container.get_v_scroll_bar()
		main_container_scroll_container.scroll_vertical = scrollbar.max_value
	pass # Replace with function body.


func load_secret_config() -> void:
	var config := ConfigFile.new()
	
	# Muat file dari folder root proyek
	var error := config.load("res://config/discord.cfg")
	
	
	if error == OK:
		# Ambil nilai berdasarkan [section] dan "key"
		dc_webhook_url = config.get_value("webhooks", "webhook_url", "")
		print("Konfigurasi rahasia berhasil dimuat!")
	else:
		# Berikan peringatan jika file lupa dibuat oleh tim/anda di PC lain
		push_error("Gagal memuat discord.cfg! Pastikan file sudah dibuat.")


func _on_start_pressed() -> void:
	pass # Replace with function body.


func _on_stop_pressed() -> void:
	pass # Replace with function body.


func _on_restart_pressed() -> void:
	pass # Replace with function body.


func _on_help_pressed() -> void:
	pass # Replace with function body.


func _on_scan_button_pressed() -> void:
	current_use_filedialog = "scan_folder"
	# Configure the dialog via code (alternative to using the Inspector)
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	
	file_dialog.popup_centered()



func _on_file_dialog_dir_selected(dir: String) -> void:
	match current_use_filedialog:
		"scan_folder":
			scan_path_line_edit.text = dir
			pass
		"exclude_folder":
			setup_list_line_edit.text = dir
			pass


func _on_recursive_toggled(toggled_on: bool) -> void:
	print(toggled_on)
	pass # Replace with function body.


func _on_e_fol_button_pressed() -> void:
	
	for i in setup_list_v_box_container.get_children():
		i.queue_free()
	
	setup_list_label.text = "exclude folder list"
	setup_list.show()
	setup_list_selectfolder_button.show()
	
	for i in exclude_folder:
		var x = ITEM_SETTING.instantiate()
		setup_list_v_box_container.add_child(x)
		x.name_item.text = i

func _on_e_ex_button_pressed() -> void:
	
	for i in setup_list_v_box_container.get_children():
		i.queue_free()
	
	setup_list_label.text = "exclude extension list"
	setup_list.show()
	setup_list_selectfolder_button.hide()
	
	for i in exclude_extensions:
		var x = ITEM_SETTING.instantiate()
		setup_list_v_box_container.add_child(x)
		x.name_item.text = i
	


func _on_setup_list_add_pressed() -> void:
	match setup_list_label.text:
		"exclude folder list":
			exclude_folder.append(setup_list_line_edit.text)
			var x = ITEM_SETTING.instantiate()
			setup_list_v_box_container.add_child(x)
			x.name_item.text = setup_list_line_edit.text
			setup_list_line_edit.text = ""
			
		"exclude extension list":
			exclude_extensions.append(setup_list_line_edit.text)
			var x = ITEM_SETTING.instantiate()
			setup_list_v_box_container.add_child(x)
			x.name_item.text = setup_list_line_edit.text
			setup_list_line_edit.text = ""
			
	pass # Replace with function body.


func _on_setup_list_save_pressed() -> void:
	setup_list.hide()
	pass # Replace with function body.


func _on_setup_list_selectfolder_button_pressed() -> void:
	current_use_filedialog = "exclude_folder"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	
	file_dialog.popup_centered()
	pass # Replace with function body.
