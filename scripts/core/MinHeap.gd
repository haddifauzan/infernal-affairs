class_name MinHeap
extends RefCounted

var heap: Array = []

func is_empty() -> bool:
	return heap.size() == 0

func push(element: Vector2i, priority: float) -> void:
	heap.append({"element": element, "priority": priority})
	_sift_up(heap.size() - 1)

func pop() -> Vector2i:
	if is_empty():
		return Vector2i(-1, -1)
	var root = heap[0]["element"]
	var last = heap.pop_back()
	if not is_empty():
		heap[0] = last
		_sift_down(0)
	return root

func _sift_up(idx: int) -> void:
	while idx > 0:
		var parent = (idx - 1) / 2
		if heap[idx]["priority"] < heap[parent]["priority"]:
			var temp = heap[idx]
			heap[idx] = heap[parent]
			heap[parent] = temp
			idx = parent
		else:
			break

func _sift_down(idx: int) -> void:
	var size = heap.size()
	while true:
		var smallest = idx
		var left = 2 * idx + 1
		var right = 2 * idx + 2
		
		if left < size and heap[left]["priority"] < heap[smallest]["priority"]:
			smallest = left
		if right < size and heap[right]["priority"] < heap[smallest]["priority"]:
			smallest = right
			
		if smallest != idx:
			var temp = heap[idx]
			heap[idx] = heap[smallest]
			heap[smallest] = temp
			idx = smallest
		else:
			break
