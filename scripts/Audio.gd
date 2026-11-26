extends Node

var p_tir : AudioStreamPlayer
var p_boom : AudioStreamPlayer
var p_ok : AudioStreamPlayer

func charger_wav(chemin : String) -> AudioStreamSample:
    var f = File.new()
    if f.open(chemin, File.READ) != OK:
        return null
    var bytes = f.get_buffer(f.get_len())
    f.close()
    var s = AudioStreamSample.new()
    s.format = AudioStreamSample.FORMAT_16_BITS
    s.mix_rate = 22050
    if bytes.size() > 44:
        s.data = bytes.subarray(44, bytes.size() - 1)
    return s

func _ready():
    p_tir = AudioStreamPlayer.new(); p_tir.stream = charger_wav("res://sons/tir.wav"); add_child(p_tir)
    p_boom = AudioStreamPlayer.new(); p_boom.stream = charger_wav("res://sons/boom.wav"); add_child(p_boom)
    p_ok = AudioStreamPlayer.new(); p_ok.stream = charger_wav("res://sons/ok.wav"); add_child(p_ok)
