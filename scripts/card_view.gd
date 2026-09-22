class_name CardView
extends Control
signal carta_seleccionada(carta_data: Carta, esta_seleccionada: bool)

@onready var base_card: TextureRect = $BaseCard
@onready var icono: TextureRect = $Icon
@onready var label_valor: Label = $LabelValor
@onready var label_name: Label = $LabelName

var datos: Carta
var seleccionada: bool = false

func _ready() -> void:
	pivot_offset = Vector2(42,56)

	# Conectar eventos de cursor
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func cargar_carta(carta_data: Carta) -> void:
	datos = carta_data
	seleccionada = false
	self_modulate = Color(1, 1, 1)
	position.y = 0.0
	z_index = 0

	if carta_data.base_texture_path != "" and ResourceLoader.exists(carta_data.base_texture_path):
		base_card.texture = load(carta_data.base_texture_path)
	if carta_data.icon_texture_path != "" and ResourceLoader.exists(carta_data.icon_texture_path):
		icono.texture = load(carta_data.icon_texture_path)

	label_valor.text = str(carta_data.valor)
	if label_name != null:
		label_name.text = carta_data.get_nombre()

func set_seleccionada(valor_sel: bool) -> void:
	seleccionada = valor_sel
	if seleccionada:
		self_modulate = Color(1.3, 1.3, 0.7) # Resaltado
		position.y = -16.0
		z_index = 2
	else:
		self_modulate = Color(1, 1, 1)
		position.y = 0.0
		z_index = 0

# Hover
func _on_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1).set_trans(Tween.TRANS_SINE)
	if not seleccionada:
		z_index = 1

func _on_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
	if not seleccionada:
		z_index = 0

# Clic
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		set_seleccionada(not seleccionada)
		carta_seleccionada.emit(datos, seleccionada)
		
		# Rebote al clic
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
		tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.05).set_delay(0.05)