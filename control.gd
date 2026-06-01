extends Control


var watcher = DirectoryWatcher.new()

func _ready() -> void:
	watcher.add_scan_directory("res://")
	add_child(watcher)
	
	watcher.files_created.connect(on_files_created)
	watcher.files_modified.connect(on_files_modified)
	watcher.files_deleted.connect(on_files_deleted)
	
	
func on_files_created(file):
	OS.shell_show_in_file_manager(file[0])
	print("file di buat : "+file[0])
	
func on_files_modified(file):
	OS.shell_show_in_file_manager(file[0])
	print("file di rubah : "+file[0])
	
func on_files_deleted(file):
	OS.shell_show_in_file_manager(file[0])
	print("file di hapus : "+file[0])
