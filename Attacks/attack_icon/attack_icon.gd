extends Node2D

var frame = 0: set = set_frame

func set_frame(v: int):
    frame = v
    $WeaponIcon.frame = v