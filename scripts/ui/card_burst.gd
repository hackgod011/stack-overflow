class_name CardBurst
extends GPUParticles2D

## One-shot particle burst spawned when a card resolves.
## Static texture is created once and shared across all instances.
## Call emit_burst(color) to trigger; 'burst_finished' signals pool return.

signal burst_finished(burst: CardBurst)

static var _shared_texture: ImageTexture


static func _ensure_texture() -> void:
	if _shared_texture != null:
		return
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_shared_texture = ImageTexture.create_from_image(img)


func _ready() -> void:
	CardBurst._ensure_texture()
	texture = _shared_texture
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0.0, -1.0, 0.0)
	mat.spread = 45.0
	mat.initial_velocity_min = 50.0
	mat.initial_velocity_max = 150.0
	mat.gravity = Vector3(0.0, 200.0, 0.0)
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	process_material = mat
	amount = 16
	one_shot = true
	lifetime = 0.6
	finished.connect(_on_finished)


func emit_burst(color: Color) -> void:
	visible = true
	emitting = false
	(process_material as ParticleProcessMaterial).color = color
	emitting = true


func set_burst_color(color: Color) -> void:
	if process_material is ParticleProcessMaterial:
		(process_material as ParticleProcessMaterial).color = color


func _on_finished() -> void:
	visible = false
	burst_finished.emit(self)
