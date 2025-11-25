extends Node3D

func _ready():
	_process_node(self)

func _process_node(node: Node):
	for child in node.get_children():
		if child is MeshInstance3D:
			create_collision_for_mesh(child)
		_process_node(child)

func create_collision_for_mesh(mesh_instance: MeshInstance3D):
	if mesh_instance.mesh == null:
		return
		
	# Check if it already has a StaticBody3D child to avoid duplicates
	for child in mesh_instance.get_children():
		if child is StaticBody3D:
			return

	var static_body = StaticBody3D.new()
	mesh_instance.add_child(static_body)
	
	var collision_shape = CollisionShape3D.new()
	static_body.add_child(collision_shape)
	
	# Create a concave polygon shape (trimesh) which is good for static level geometry
	var shape = mesh_instance.mesh.create_trimesh_shape()
	collision_shape.shape = shape
