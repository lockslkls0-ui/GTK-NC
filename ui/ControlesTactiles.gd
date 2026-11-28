extends CanvasLayer

var stick_actif := false
var stick_centre := Vector2(140, 560)
var stick_pos := Vector2(140, 560)
var dir_tactile := Vector2.ZERO
var vis_stick : Control

func _ready():
    layer = 15
    if OS.get_name() != "HTML5" and not OS.has_touchscreen_ui_hint():
        visible = false; set_process(false); return
    visible = true
    vis_stick = Control.new(); vis_stick.rect_position = Vector2(40, 420); vis_stick.rect_size = Vector2(220, 220); vis_stick.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(vis_stick)
    var fond_s = ColorRect.new(); fond_s.color = Color(1, 1, 1, 0.16); fond_s.rect_position = Vector2(35, 35); fond_s.rect_size = Vector2(140, 140); fond_s.mouse_filter = Control.MOUSE_FILTER_IGNORE; vis_stick.add_child(fond_s)
    var lbl_s = Label.new(); lbl_s.text = "🕹️ BOUGER"; lbl_s.rect_position = Vector2(62, 95); vis_stick.add_child(lbl_s)
    _btn("🔥 TIR", Vector2(1120, 480), Vector2(115, 115), Color(0.85, 0.22, 0.18, 0.78), "tir")
    _btn("✋ E", Vector2(990, 520), Vector2(95, 85), Color(0.18, 0.58, 0.85, 0.78), "e")
    _btn("🚗 F", Vector2(990, 415), Vector2(95, 85), Color(0.88, 0.58, 0.14, 0.78), "f")
    _btn("🤝 G", Vector2(1120, 370), Vector2(115, 85), Color(0.20, 0.72, 0.36, 0.78), "g")
    _btn("💬 Y", Vector2(875, 520), Vector2(95, 85), Color(0.75, 0.65, 0.18, 0.78), "y")
    _btn("🔫 TAB", Vector2(875, 415), Vector2(95, 85), Color(0.45, 0.48, 0.55, 0.78), "tab")

func _btn(txt : String, pos : Vector2, sz : Vector2, col : Color, act : String):
    var b = Button.new(); b.text = txt; b.rect_position = pos; b.rect_size = sz; b.modulate = col; b.focus_mode = Control.FOCUS_NONE
    var args = Array(); args.append(act)
    b.connect("button_down", self, "_on_btn", args)
    add_child(b)

func _on_btn(act : String):
    var ev = InputEventKey.new(); ev.pressed = true
    if act == "tir": ev.scancode = KEY_SPACE
    elif act == "e": ev.scancode = KEY_E
    elif act == "f": ev.scancode = KEY_F
    elif act == "g": ev.scancode = KEY_G
    elif act == "y": ev.scancode = KEY_Y
    elif act == "tab": ev.scancode = KEY_TAB
    Input.parse_input_event(ev)

func _input(event):
    if not visible: return
    if event is InputEventScreenTouch:
        if event.pressed and event.position.x < 420.0:
            stick_actif = true; stick_centre = event.position; stick_pos = event.position
        elif not event.pressed:
            stick_actif = false; dir_tactile = Vector2.ZERO
    elif event is InputEventScreenDrag and stick_actif:
        var delta_v = event.position - stick_centre
        stick_pos = stick_centre + delta_v.clamped(65.0)
        dir_tactile = delta_v.clamped(65.0) / 65.0

func _process(delta):
    var m = get_tree().get_root().get_node_or_null("Main")
    if m != null and m.get("joueur") != null and dir_tactile.length() > 0.15:
        m.joueur.move_and_slide(dir_tactile * 360.0)
        m.joueur.rotation = dir_tactile.angle()
