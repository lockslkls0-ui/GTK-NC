extends Node2D

var grille_lamp := Dictionary()
var grille_mais := Dictionary()
var bombes_vis := Array()
var feux_vis := Array()
var explosions_vis := Array()
var crateres_vis := Array()
var lum_torche : Light2D
var lum_phare_g : Light2D
var lum_phare_d : Light2D
var lum_feu : Light2D
var modulate_nuit : CanvasModulate
var torche_active := true
var _t_surv := 15.0
var _cd_lum := 0.0
var _init_fait := false

func _tex_cone() -> ImageTexture:
    var img := Image.new(); img.create(512, 256, false, Image.FORMAT_RGBA8); img.lock()
    for y in range(256):
        for x in range(256):
            var dx := float(x) / 511.0; var dy := (float(y) - 128.0) / 128.0
            var ang_ok : float = clamp(1.0 - abs(dy) / max(dx * 0.72, 0.01), 0.0, 1.0)
            var dist_ok : float = clamp(1.0 - dx, 0.0, 1.0)
            img.set_pixel(x, y, Color(1.0, 1.0, 1.0, ang_ok * sqrt(dist_ok)))
    img.unlock()
    var tex := ImageTexture.new(); tex.create_from_image(img); return tex

func _tex_rond() -> ImageTexture:
    var img := Image.new(); img.create(128, 128, false, Image.FORMAT_RGBA8); img.lock()
    for y in range(128):
        for x in range(128):
            var d : float = Vector2(x - 64, y - 64).length() / 64.0
            var a : float = clamp(1.0 - d, 0.0, 1.0)
            img.set_pixel(x, y, Color(1.0, 0.85, 0.45, a * a))
    img.unlock()
    var tex := ImageTexture.new(); tex.create_from_image(img); return tex

func _ready():
    z_index = 4096
    modulate_nuit = CanvasModulate.new(); modulate_nuit.color = Color(1, 1, 1); add_child(modulate_nuit)
    var tc := _tex_cone(); var tr := _tex_rond()
    lum_torche = Light2D.new(); lum_torche.texture = tc; lum_torche.offset = Vector2(256, 0); lum_torche.texture_scale = 1.0; lum_torche.energy = 1.7; add_child(lum_torche)
    lum_phare_g = Light2D.new(); lum_phare_g.texture = tc; lum_phare_g.offset = Vector2(256, 0); lum_phare_g.texture_scale = 1.3; lum_phare_g.energy = 1.9; add_child(lum_phare_g)
    lum_phare_d = Light2D.new(); lum_phare_d.texture = tc; lum_phare_d.offset = Vector2(256, 0); lum_phare_d.texture_scale = 1.3; lum_phare_d.energy = 1.9; add_child(lum_phare_d)
    lum_feu = Light2D.new(); lum_feu.texture = tr; lum_feu.texture_scale = 3.5; lum_feu.energy = 1.5; lum_feu.enabled = false; add_child(lum_feu)
    var f = File.new()
    if f.open("res://triangulation/nc_reseau_arbres.bin", File.READ) != OK: return
    var nr : int = f.get_32(); var nb : int = f.get_32(); f.get_32(); f.get_32()
    for ir in range(nr):
        if f.get_position() + 20 > f.get_len(): break
        var pa := Vector2(f.get_float(), f.get_float()); f.get_float(); f.get_float(); var lg : float = f.get_float()
        if lg > 35.0 and ir % 12 == 0:
            var k := str(int(floor(pa.x / 6000.0))) + "_" + str(int(floor(pa.y / 6000.0)))
            if not grille_lamp.has(k): grille_lamp[k] = Array()
            if grille_lamp[k].size() < 55: grille_lamp[k].append(pa)
    for ib in range(nb):
        if f.get_position() + 16 > f.get_len(): break
        var cb := Vector2(f.get_float(), f.get_float()); f.get_float(); f.get_float()
        if ib % 7 == 0:
            var k2 := str(int(floor(cb.x / 6000.0))) + "_" + str(int(floor(cb.y / 6000.0)))
            if not grille_mais.has(k2): grille_mais[k2] = Array()
            if grille_mais[k2].size() < 70: grille_mais[k2].append(cb)
    f.close()

func _input(event):
    if event is InputEventKey and event.pressed and not event.echo:
        var m = get_parent()
        if m == null or m.get("joueur") == null: return
        if event.scancode == KEY_U:
            torche_active = not torche_active
            m.hud.msg_label.text = "🔦 Phares / Torche ALLUMÉS [U]" if torche_active else "🔦 Phares / Torche ÉTEINTS [U]"
            get_tree().set_input_as_handled()
        elif event.scancode == KEY_B and not m.joueur.en_vehicule:
            if m.bois >= 3:
                m.bois -= 3
                var pf : Vector2 = m.joueur.position + Vector2(36, 0).rotated(m.joueur.corps_visuel.rotation)
                feux_vis.append({"pos": pf, "t": 300.0, "nb": 0})
                lum_feu.enabled = true; lum_feu.position = pf
                m.hud.msg_label.text = "🔥 Feu de camp allumé au briquet (-3 bois) ! Attire les survivants alliés."
            else:
                m.hud.msg_label.text = "🪵 Il faut 3 bois pour allumer un feu de camp [B] !"
            get_tree().set_input_as_handled()
        elif event.scancode == KEY_X:
            if m.get("eco") != null and m.eco.explosifs > 0:
                m.eco.explosifs -= 1
                bombes_vis.append({"pos": m.joueur.position, "t": 2.0})
                m.hud.msg_label.text = "💣 Bombe posée ! Explosion dans 2.0s..."
            else:
                m.hud.msg_label.text = "❌ Plus de bombes (Téléphone [P])"
            get_tree().set_input_as_handled()

func _process(delta):
    var m = get_parent()
    if m == null or m.get("joueur") == null: return
    var j = m.joueur; var pj : Vector2 = j.position
    if not _init_fait:
        _init_fait = true
        var k0 := str(int(floor(pj.x / 6000.0))) + "_" + str(int(floor(pj.y / 6000.0)))
        if not grille_lamp.has(k0): grille_lamp[k0] = Array()
        grille_lamp[k0].append(pj + Vector2(85, -45))
    modulate_nuit.color = Color(0.16, 0.20, 0.30) if m.est_nuit else Color(1, 1, 1)
    if j.en_vehicule:
        lum_torche.enabled = false; lum_phare_g.enabled = torche_active; lum_phare_d.enabled = torche_active
        var av : float = j.vehicule_ref.rotation if j.vehicule_ref != null else j.rotation
        var fwd := Vector2(cos(av), sin(av)); var perp := Vector2(-fwd.y, fwd.x) * 11.0
        lum_phare_g.position = pj + fwd * 22.0 + perp; lum_phare_g.rotation = av
        lum_phare_d.position = pj + fwd * 22.0 - perp; lum_phare_d.rotation = av
    else:
        lum_phare_g.enabled = false; lum_phare_d.enabled = false
        lum_torche.enabled = torche_active
        lum_torche.position = pj; lum_torche.rotation = (get_global_mouse_position() - pj).angle()
    if feux_vis.size() > 0:
        var dernier_feu : Vector2 = feux_vis.back()["pos"]
        lum_feu.enabled = true; lum_feu.position = dernier_feu
        _t_surv += delta
        if _t_surv >= 14.0:
            _t_surv = 0.0
            if feux_vis.back().get("nb", 0) < 4:
                var s = KinematicBody2D.new()
                var ang_s := rand_range(0, TAU)
                s.position = dernier_feu + Vector2(cos(ang_s), sin(ang_s)) * 580.0
                s.add_child(m.pop.creer_humain(Color(0.25, 0.75, 0.45)))
                var col = CollisionShape2D.new(); var sh = CircleShape2D.new(); sh.radius = 15.0; col.shape = sh; s.add_child(col)
                s.set_meta("recrute", false); s.set_meta("cd", 0.0); s.set_meta("dir", Vector2(1, 0)); feux_vis.back()["nb"] = feux_vis.back().get("nb", 0) + 1; s.set_meta("cible_feu", dernier_feu)
                m.pop.add_child(s); m.pop.allies.append(s)
                m.hud.msg_label.text = "🔥 Un survivant aperçoit la lueur de ton feu de camp au loin et arrive ([G] pour recruter) !"
    for i in range(bombes_vis.size() - 1, -1, -1):
        bombes_vis[i]["t"] -= delta
        if bombes_vis[i]["t"] <= 0.0:
            var pb : Vector2 = bombes_vis[i]["pos"]
            explosions_vis.append({"pos": pb, "t": 0.85}); crateres_vis.append(pb); m.shake_timer = 0.85
            if m.get("audio") != null: m.audio.p_boom.play()
            var dj : float = m.joueur.position.distance_to(pb)
            if dj < 260.0:
                var deg_j : float = clamp((1.0 - dj / 260.0) * 90.0, 15.0, 90.0)
                m.joueur.pv = max(0.0, m.joueur.pv - deg_j)
                m.joueur.position += (m.joueur.position - pb).normalized() * 65.0
                m.hud.msg_label.text = "💥 SOUFFLE DE L'EXPLOSION ! (-" + str(int(deg_j)) + " PV)"
            for en in m.pop.ennemis:
                if is_instance_valid(en) and en.position.distance_to(pb) < 360.0:
                    en.set_meta("hp", float(en.get_meta("hp")) - 350.0)
            for ia in range(m.pop.allies.size() - 1, -1, -1):
                var al = m.pop.allies[ia]
                if is_instance_valid(al) and al.position.distance_to(pb) < 300.0:
                    al.queue_free(); m.pop.allies.remove(ia)
            for v in m.veh.vehicules:
                if is_instance_valid(v) and v.position.distance_to(pb) < 320.0:
                    var pv_v : float = float(v.get_meta("pv_veh")) if v.has_meta("pv_veh") else 100.0
                    v.set_meta("pv_veh", max(0.0, pv_v - 75.0))
            if m.get("constr") != null:
                for c_it in m.constr.constructions:
                    if c_it["pos"].distance_to(pb) < 320.0: c_it["pv"] -= 700.0
            bombes_vis.remove(i)
    for j_ex in range(explosions_vis.size() - 1, -1, -1):
        explosions_vis[j_ex]["t"] -= delta
        if explosions_vis[j_ex]["t"] <= 0.0: explosions_vis.remove(j_ex)
    update()

func _draw():
    var m = get_parent()
    if m == null or m.get("joueur") == null: return
    var j = m.joueur; var pj : Vector2 = j.position
    var gx := int(floor(pj.x / 6000.0)); var gy := int(floor(pj.y / 6000.0))
    var r_portee : int = clamp(int(ceil(j.cam.zoom.x)), 1, 4)
    var c_halo := Color(1.0, 0.65, 0.15, 0.45); var c_coeur := Color(1.0, 0.88, 0.35, 0.96)
    for dx in range(-r_portee, r_portee + 1):
        for dy in range(-r_portee, r_portee + 1):
            var k := str(gx + dx) + "_" + str(gy + dy)
            if grille_lamp.has(k):
                for lp in grille_lamp[k]:
                    draw_circle(lp, 40.0, c_halo); draw_circle(lp, 9.0, c_coeur)
            if grille_mais.has(k):
                for ms in grille_mais[k]:
                    draw_circle(ms, 24.0, Color(1.0, 0.65, 0.15, 0.38))
                    draw_rect(Rect2(ms - Vector2(7, 6), Vector2(14, 12)), Color(1.0, 0.85, 0.32, 0.95))
    for b in bombes_vis:
        draw_circle(b["pos"], 12.0, Color(0.15, 0.15, 0.18)); draw_circle(b["pos"], 5.0, Color(1.0, 0.2, 0.1))
    for cr in crateres_vis:
        draw_circle(cr, 88.0, Color(0.08, 0.07, 0.06, 0.85)); draw_circle(cr, 34.0, Color(0.03, 0.03, 0.03, 0.92))
    for ex in explosions_vis:
        var r_ex : float = (0.85 - ex["t"]) * 560.0
        draw_circle(ex["pos"], r_ex, Color(1.0, 0.55, 0.10, 0.78)); draw_circle(ex["pos"], r_ex * 0.55, Color(1.0, 0.92, 0.45, 0.92))
    if m.constr.a_un_abri:
        var pf : Vector2 = m.constr.dernier_abri + Vector2(0, 62)
        draw_circle(pf, 46.0, Color(1.0, 0.65, 0.15, 0.38)); draw_circle(pf, 11.0, Color(1.0, 0.45, 0.10, 0.95))
