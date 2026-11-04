extends RefCounted
class_name WaystationUi

static func default_intro(first_visit: bool) -> String:
	if first_visit:
		return "Safe camp between floors. Run gold only. Campfire can purify a Stain."
	return "A safe camp between floors. Trade, train, then push onward."
