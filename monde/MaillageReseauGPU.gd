extends Node2D

static func _quad(st : SurfaceTool, pa : Vector2, pb : Vector2, demi : float, col : Color):
    var dir := (pb - pa)
    if dir.length_squared() < 1.0: return
    var n := Vector2(-dir.y, dir.x).normalized() * demi
    var v0 := Vector3(pa.x - n.x, pa.y - n.y, 0.0); var v1 := Vector3(pa.x + n.x, pa.y + n.y, 0.0)
    var v2 := Vector3(pb.x + n.x, pb.y + n.y, 0.0); var v3 := Vector3(pb.x - n.x, pb.y - n.y, 0.0)
    st.add_color(col); st.add_vertex(v0); st.add_color(col); st.add_vertex(v1); st.add_color(col); st.add_vertex(v2)
    st.add_color(col); st.add_vertex(v0); st.add_color(col); st.add_vertex(v2); st.add_color(col); st.add_vertex(v3)

static func construire_reseau(parent : Node2D):
    var f = File.new()
    if f.open("res://triangulation/nc_reseau_arbres.bin", File.READ) != OK: return
    var nr : int = f.get_32(); var nb : int = f.get_32(); var nrv : int = f.get_32(); var na : int = f.get_32()
    var st_r := SurfaceTool.new(); st_r.begin(Mesh.PRIMITIVE_TRIANGLES)
    var st_b := SurfaceTool.new(); st_b.begin(Mesh.PRIMITIVE_TRIANGLES)
    var c_rt := Color(0.18, 0.19, 0.22); var c_pi := Color(0.68, 0.44, 0.24); var c_riv := Color(0.14, 0.56, 0.88)
    for _ir in range(nr):
        var pa := Vector2(f.get_float(), f.get_float()); var pb := Vector2(f.get_float(), f.get_float()); var lg : float = f.get_float()
        _quad(st_r, pa, pb, 16.0 if lg <= 35.0 else 36.0, c_pi if lg <= 35.0 else c_rt)
    var cols_t := [Color(0.82, 0.54, 0.40), Color(0.72, 0.76, 0.80), Color(0.32, 0.54, 0.74), Color(0.76, 0.36, 0.28)]
    for ib in range(nb):
        var cb := Vector2(f.get_float(), f.get_float()); var dm := Vector2(f.get_float(), f.get_float())
        _quad(st_b, Vector2(cb.x - dm.x, cb.y), Vector2(cb.x + dm.x, cb.y), max(dm.y, 4.0), cols_t[ib % 4])
    for _irv in range(nrv):
        var ra := Vector2(f.get_float(), f.get_float()); var rb := Vector2(f.get_float(), f.get_float()); var rlg : float = f.get_float()
        _quad(st_r, ra, rb, clamp(rlg * 0.35, 18.0, 55.0), c_riv)
    var st_a := SurfaceTool.new(); st_a.begin(Mesh.PRIMITIVE_TRIANGLES)
    var cols_a := Array(); cols_a.append(Color(0.14, 0.44, 0.16, 0.92)); cols_a.append(Color(0.18, 0.52, 0.18, 0.92)); cols_a.append(Color(0.10, 0.36, 0.13, 0.92))
    for ia in range(na):
        if f.get_position() + 12 > f.get_len(): break
        var ap := Vector2(f.get_float(), f.get_float()); var ar : float = clamp(f.get_float(), 5.0, 18.0)
        var ca : Color = cols_a[ia % 3]
        st_a.add_color(ca); st_a.add_vertex(Vector3(ap.x, ap.y - ar, 0.0))
        st_a.add_color(ca); st_a.add_vertex(Vector3(ap.x + ar * 0.9, ap.y + ar * 0.7, 0.0))
        st_a.add_color(ca); st_a.add_vertex(Vector3(ap.x - ar * 0.9, ap.y + ar * 0.7, 0.0))
    f.close()
    var mat := CanvasItemMaterial.new()
    var mr := MeshInstance2D.new(); mr.mesh = st_r.commit(); mr.material = mat; mr.z_index = 2; parent.add_child(mr)
    var mb := MeshInstance2D.new(); mb.mesh = st_b.commit(); mb.material = mat; mb.z_index = 3; parent.add_child(mb)
