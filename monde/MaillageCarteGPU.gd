extends Node2D

static func construire_mesh(parent : Node2D):
    var f = File.new()
    if f.open("res://triangulation/nc_monde_propre.bin", File.READ) != OK: return
    var st_bas := SurfaceTool.new(); st_bas.begin(Mesh.PRIMITIVE_TRIANGLES)
    var st_haut := SurfaceTool.new(); st_haut.begin(Mesh.PRIMITIVE_TRIANGLES)
    var nb : int = f.get_32()
    var n_b := 0; var n_h := 0
    for _i in range(nb):
        if f.get_position() + 34 > f.get_len(): break
        var c : int = f.get_8(); var cd : int = f.get_8()
        f.get_float(); f.get_float()
        var p0 := Vector3(f.get_float(), f.get_float(), 0.0)
        var p1 := Vector3(f.get_float(), f.get_float(), 0.0)
        var p2 := Vector3(f.get_float(), f.get_float(), 0.0)
        if c == 1:
            var ct := Color(0.16, 0.38, 0.20)
            st_bas.add_color(ct); st_bas.add_vertex(p0); st_bas.add_color(ct); st_bas.add_vertex(p1); st_bas.add_color(ct); st_bas.add_vertex(p2); n_b += 1
        elif c == 2:
            var col := Color(0.24, 0.86, 0.86, 0.86) if cd == 1 else (Color(0.16, 0.72, 0.82, 0.78) if cd == 2 else (Color(0.94, 0.86, 0.58, 0.94) if cd == 3 else (Color(0.10, 0.48, 0.68, 0.76) if cd == 4 else (Color(0.06, 0.28, 0.48, 0.84) if cd == 5 else Color(0.88, 0.76, 0.50, 0.88)))))
            st_bas.add_color(col); st_bas.add_vertex(p0); st_bas.add_color(col); st_bas.add_vertex(p1); st_bas.add_color(col); st_bas.add_vertex(p2); n_b += 1
        elif c == 3 or c == 4 or c == 5:
            var col2 := Color(0.46, 0.41, 0.30, 0.58) if c == 3 else (Color(0.12, 0.30, 0.13, 0.82) if c == 4 else (Color(0.24, 0.82, 0.96, 0.98) if cd == 3 else Color(0.10, 0.46, 0.80, 0.95)))
            st_haut.add_color(col2); st_haut.add_vertex(p0); st_haut.add_color(col2); st_haut.add_vertex(p1); st_haut.add_color(col2); st_haut.add_vertex(p2); n_h += 1
    f.close()
    var mat := CanvasItemMaterial.new()
    if n_b > 0:
        var m1 := MeshInstance2D.new(); m1.mesh = st_bas.commit(); m1.material = mat; m1.z_index = -1; parent.add_child(m1)
    if n_h > 0:
        var m2 := MeshInstance2D.new(); m2.mesh = st_haut.commit(); m2.material = mat; m2.z_index = 1; parent.add_child(m2)
