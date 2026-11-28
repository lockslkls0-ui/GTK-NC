extends Node2D

static func _quad(st : SurfaceTool, pa : Vector2, pb : Vector2, demi : float, col : Color):
    var dir := (pb - pa)
    if dir.length_squared() < 36.0: return
    var n := Vector2(-dir.y, dir.x).normalized() * demi
    var v0 := Vector3(pa.x - n.x, pa.y - n.y, 0.0); var v1 := Vector3(pa.x + n.x, pa.y + n.y, 0.0)
    var v2 := Vector3(pb.x + n.x, pb.y + n.y, 0.0); var v3 := Vector3(pb.x - n.x, pb.y - n.y, 0.0)
    st.add_color(col); st.add_vertex(v0); st.add_color(col); st.add_vertex(v1); st.add_color(col); st.add_vertex(v2)
    st.add_color(col); st.add_vertex(v0); st.add_color(col); st.add_vertex(v2); st.add_color(col); st.add_vertex(v3)

static func _ligne_reguliere(st : SurfaceTool, pa : Vector2, pb : Vector2, col : Color):
    var d : float = pa.distance_to(pb)
    if d < 24.0: return
    var u : Vector2 = (pb - pa) / d
    var pos := 6.0
    while pos + 16.0 < d:
        _quad(st, pa + u * pos, pa + u * (pos + 16.0), 1.8, col)
        pos += 36.0

static func construire_reseau(parent : Node2D):
    var f = File.new()
    if f.open("res://triangulation/nc_reseau_arbres.bin", File.READ) != OK: return
    var nr : int = f.get_32(); var nb : int = f.get_32(); var nrv : int = f.get_32(); var _na : int = f.get_32()
    var st_trot := SurfaceTool.new(); st_trot.begin(Mesh.PRIMITIVE_TRIANGLES)
    var st_r := SurfaceTool.new(); st_r.begin(Mesh.PRIMITIVE_TRIANGLES)
    var st_b := SurfaceTool.new(); st_b.begin(Mesh.PRIMITIVE_TRIANGLES)
    var c_trot := Color(0.55, 0.53, 0.48); var c_rt := Color(0.18, 0.19, 0.22); var c_pi := Color(0.68, 0.44, 0.24); var c_riv := Color(0.14, 0.56, 0.88)
    var c_bl := Color(0.94, 0.94, 0.90, 0.85)
    var dir_prec := Vector2.ZERO
    for ir in range(nr):
        var pa := Vector2(f.get_float(), f.get_float()); var pb := Vector2(f.get_float(), f.get_float()); var lg : float = f.get_float()
        var est_capitale : bool = pa.length_squared() < 1600000000.0
        var est_grand_axe : bool = lg >= 55.0
        if lg > 35.0:
            if est_capitale or est_grand_axe:
                _quad(st_trot, pa, pb, 43.0, c_trot)
            _quad(st_r, pa, pb, 36.0, c_rt)
            if est_capitale:
                var dir_act := (pb - pa).normalized()
                var en_virage : bool = dir_prec != Vector2.ZERO and dir_act.dot(dir_prec) < 0.965
                if en_virage:
                    _quad(st_r, pa, pb, 2.0, c_bl)
                elif ir % 2 == 0:
                    _ligne_reguliere(st_r, pa, pb, c_bl)
                dir_prec = dir_act
        else:
            _quad(st_r, pa, pb, 16.0, c_pi)
    var cols_t := Array(); cols_t.append(Color(0.82, 0.54, 0.40)); cols_t.append(Color(0.72, 0.76, 0.80)); cols_t.append(Color(0.32, 0.54, 0.74)); cols_t.append(Color(0.76, 0.36, 0.28))
    for ib in range(nb):
        var cb := Vector2(f.get_float(), f.get_float()); var dm := Vector2(f.get_float(), f.get_float())
        _quad(st_b, Vector2(cb.x - dm.x, cb.y), Vector2(cb.x + dm.x, cb.y), max(dm.y, 4.0), cols_t[ib % 4])
    for _irv in range(nrv):
        var ra := Vector2(f.get_float(), f.get_float()); var rb := Vector2(f.get_float(), f.get_float()); var rlg : float = f.get_float()
        _quad(st_r, ra, rb, clamp(rlg * 0.35, 18.0, 55.0), c_riv)
    f.close()
    var mat := CanvasItemMaterial.new()
    var mt := MeshInstance2D.new(); mt.mesh = st_trot.commit(); mt.material = mat; mt.z_index = 1; parent.add_child(mt)
    var mr := MeshInstance2D.new(); mr.mesh = st_r.commit(); mr.material = mat; mr.z_index = 2; parent.add_child(mr)
    var mb := MeshInstance2D.new(); mb.mesh = st_b.commit(); mb.material = mat; mb.z_index = 3; parent.add_child(mb)
