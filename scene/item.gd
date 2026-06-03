extends HBoxContainer
@onready var date: Label = $date
@onready var jenis: Label = $jenis
@onready var nama: Label = $nama
@onready var path_label: Label = $path
@onready var go_btn: Button = $go
@onready var lifetime_timeout: Timer = $Lifetime_timeout
@onready var lifetime: Label = $lifetime

var finish_init_data:bool = false
var flash_color: Color = Color(1.0, 0.85, 0.0, 0.5)
var alpha_fade:float = 1.0

const LOG_PATH = "user://sdl_item.log"
const MAX_LOG_SIZE = 5 * 1024 * 1024  # 5MB per file
const MAX_LOG_BACKUPS = 5  # watcher.log.1 sampai watcher.log.5

func _on_go_pressed() -> void:
	go(path_label.text)
	pass # Replace with function body.


func _ready() -> void:
	#modulate.a = 0
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	#tw.tween_property(self,"modulate:a",1.0,0.5)
	tw.tween_property(self,"scale",Vector2(1.1,1.0),0.2)
	tw.tween_property(self,"scale",Vector2(1.0,1.0),0.2)
	
	
		# Memastikan background menggambar ulang setiap kali ukuran HBox berubah
	item_rect_changed.connect(queue_redraw)
	
	# Membuat animasi fadeout menggunakan Tween langsung dari _ready
	var tween = create_tween()
	# Menganimasikan properti 'a' (alpha/transparansi) pada flash_color menjadi 0 (hilang) selama 1.0 detik
	tween.tween_property(self, "alpha_fade", 0.0, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Menghubungkan proses animasi ke fungsi menggambar ulang
	tween.tween_callback(queue_redraw) # Memastikan redraw terakhir bersih
	

func go(target_path:String):
	if FileAccess.file_exists(target_path):
		OS.shell_show_in_file_manager(target_path)
	else:
		OS.alert("path file telah dipindah / dihapus")

func _format_time(seconds: float) -> String:
	var s := int(seconds)
	var h := s / 3600
	var m := (s % 3600) / 60
	var sec := s % 60
	
	if h > 0:
		return "%02d:%02d:%02d" % [h, m, sec]
	elif m > 0:
		return "%02d:%02d" % [m, sec]
	else:
		return "%ds" % sec


func _process(_delta: float) -> void:
	lifetime.text = _format_time(lifetime_timeout.time_left)
	if finish_init_data:
		_append_to_log(jenis.text,nama.text,path_label.text)
		finish_init_data = false #agar tidak loop
	
	
	if alpha_fade > 0.0:
		queue_redraw()


func _on_lifetime_timeout_timeout() -> void:
	queue_free()
	pass # Replace with function body.



func _rotate_log() -> void:
	if not FileAccess.file_exists(LOG_PATH):
		return
	if FileAccess.get_file_as_bytes(LOG_PATH).size() < MAX_LOG_SIZE:
		return
	
	# hapus backup terlama
	var oldest = ProjectSettings.globalize_path("user://watcher.log.%d" % MAX_LOG_BACKUPS)
	if FileAccess.file_exists(oldest):
		DirAccess.remove_absolute(oldest)
	
	# geser backup: .4 → .5, .3 → .4, dst
	for i in range(MAX_LOG_BACKUPS - 1, 0, -1):
		var old_path = ProjectSettings.globalize_path("user://watcher.log.%d" % i)
		var new_path = ProjectSettings.globalize_path("user://watcher.log.%d" % (i + 1))
		if FileAccess.file_exists(old_path):
			DirAccess.rename_absolute(old_path, new_path)
	
	# rename watcher.log → watcher.log.1
	DirAccess.rename_absolute(
		ProjectSettings.globalize_path(LOG_PATH),
		ProjectSettings.globalize_path("user://watcher.log.1")
	)

func _append_to_log(type: String, name: String, path: String) -> void:
	_rotate_log()
	
	var t = Time.get_datetime_string_from_system()
	var line = "[%s] [%s] %s | %s\n" % [t, type.to_upper(), name, path]
	
	var file := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	else:
		file.seek_end()
	
	if file == null:
		push_warning("Failed to open log file: %s" % LOG_PATH)
		return
	
	file.store_string(line)
	file.close()
	
func _draw() -> void:
	if alpha_fade > 0.0:
		# Poin sudut kotak: [Kiri-Atas, Kanan-Atas, Kanan-Bawah, Kiri-Bawah]
		var points = PackedVector2Array([
			Vector2(0, 0),
			Vector2(size.x, 0),
			Vector2(size.x, size.y),
			Vector2(0, size.y)
		])
		
		# CONTOH 1: Gradien Kuning ke Transparan (Kiri ke Kanan)
		var colors = PackedColorArray([
			Color(1.0, 0.85, 0.0, alpha_fade),       # Kiri-Atas (Kuning)
			Color(1.0, 0.85, 0.0, 0.0),              # Kanan-Atas (Transparan)
			Color(1.0, 0.85, 0.0, 0.0),              # Kanan-Bawah (Transparan)
			Color(1.0, 0.85, 0.0, alpha_fade)        # Kiri-Bawah (Kuning)
		])
		
		# Menggambar kotak dengan warna berbeda di tiap sudut (Gradien)
		draw_primitive(points, colors, PackedVector2Array())
