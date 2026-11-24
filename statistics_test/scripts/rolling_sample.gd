extends RefCounted
## Fixed-size rolling sample (FIFO window) for the Statistics Test tool.
##
## Keeps at most `window_size` values: pushing onto a full window first evicts
## the oldest value. This is the "current/rolling" sample only; the reference
## sample is owned separately by the main scene and is never touched here.

var window_size := 30
var _values: Array[float] = []


func _init(initial_values: Array = [], max_window_size: int = 30) -> void:
	setup(initial_values, max_window_size)


## Replaces the window contents with an exact copy of `initial_values`
## (same order, oldest first), truncated to the last `size` values if longer.
func setup(initial_values: Array, max_window_size: int) -> void:
	window_size = maxi(1, max_window_size)
	_values.clear()
	for v in initial_values:
		_values.append(float(v))
	while _values.size() > window_size:
		_values.pop_front()


## Appends `value` to the window. When the window is full, the oldest value is
## removed first and returned; otherwise `value` itself is returned so the
## caller can always treat the result as "the value that left the window".
func push(value: float) -> float:
	var evicted := value
	if _values.size() >= window_size:
		evicted = float(_values.pop_front())
	_values.append(value)
	return evicted


func size() -> int:
	return _values.size()


func is_full() -> bool:
	return _values.size() >= window_size


## Defensive copy of the current window contents, oldest first.
func snapshot() -> Array[float]:
	return _values.duplicate()


func clear() -> void:
	_values.clear()
