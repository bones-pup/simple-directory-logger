extends Control

@onready var watcher: DirectoryWatcher = $DirectoryWatcher

var ITEM = preload("uid://7lwino4j4r6u")
@onready var main_container: VBoxContainer = $VBoxContainer/MarginContainer2/ScrollContainer/main_container

var scan_dir = ""
var exclude_extensions:Array[String] = ["import", "tmp", "uid","godot","cfg"]
var exclude_folder:Array[String] = ["res://addons", "res://cache"]

func _ready() -> void:
	watcher.add_scan_directory("C:/Users/Rova/Documents/test")
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
		
	
	
	pass # Replace with function body.


func _on_directory_watcher_files_deleted(files: PackedStringArray) -> void:
	var t = Time.get_datetime_string_from_system()
	for file in files:  # ← loop semua file
		var i = ITEM.instantiate()
		main_container.add_child(i)
		i.date.text = t
		i.jenis.text = "deleted"
		i.nama.text = file.get_file()  # nama file saja biar tidak terlalu panjang
		i.path_label.text = file # full path buat tombol go
		i.jenis.add_theme_color_override("font_color",Color.RED)
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
	pass # Replace with function body.
