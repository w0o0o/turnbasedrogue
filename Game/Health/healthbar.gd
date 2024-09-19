extends Node2D

var amount: int = 5: set = _set_amount
var max_amount: int = 10

func _set_amount(v):
    amount = v
    # get a float between 0 and 1
    var ratio = float(amount) / float(max_amount)
    $bar.scale.x = ratio
