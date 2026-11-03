extends RefCounted
class_name MapEventHandler

const EVENT_IDS: Array[String] = [
	"healing_spring",
	"gamble",
	"wisdom",
	"gas_trap",
	"ambush",
]

static func roll_event_id() -> String:
	return EVENT_IDS[randi() % EVENT_IDS.size()]

static func resolve(event_id: String, world: Node2D, party: Array) -> String:
	match event_id:
		"healing_spring":
			for member in party:
				if member is Character:
					var heal: int = maxi(8, int(member.max_hp * 0.28))
					member.apply_healing(heal)
			return "A hidden spring mends the party."
		"gamble":
			if !RunState.spend_run_gold(15):
				return "You lack 15 run gold to gamble."
			if randf() < 0.5:
				RunState.add_run_gold(35)
				return "The spirits favor you: +35 run gold!"
			return "The spirits take your stake."
		"wisdom":
			for member in party:
				if member is Character:
					member.gain_xp(18, true)
			return "Ancient whispers grant insight (+18 XP each)."
		"gas_trap":
			for member in party:
				if member is Character:
					member.apply_poison(2)
			return "Toxic gas! The party is poisoned."
		"ambush":
			if world.has_method("start_map_ambush"):
				world.start_map_ambush()
				return "Ambush!"
			return "Nothing stirs."
		_:
			return ""
