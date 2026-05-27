class_name CardBurst
extends GPUParticles2D

## One-shot particle burst spawned when a card resolves.
## Configures its own material and texture at ready, then auto-frees.


func _ready() -> void:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	texture = ImageTexture.create_from_image(img)
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
	emitting = true
	finished.connect(queue_free)


func set_burst_color(color: Color) -> void:
	if process_material is ParticleProcessMaterial:
		(process_material as ParticleProcessMaterial).color = color
