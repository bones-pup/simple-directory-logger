extends HBoxContainer
@onready var date: Label = $date
@onready var jenis: Label = $jenis
@onready var nama: Label = $nama
@onready var path_label: Label = $path


func _on_go_pressed() -> void:
	go(path_label.text)
	pass # Replace with function body.


func go(target_path:String):
	
	OS.shell_show_in_file_manager(target_path)
