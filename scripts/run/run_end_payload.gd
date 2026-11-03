extends RefCounted
class_name RunEndPayload

var victory: bool = false
var voluntary_abandon: bool = false
var penalty_fraction: float = 0.0
var tithe_earned: int = 0
var run_summary: Dictionary = {}
var trait_events: Array = []
var stress_events: Array = []

func from_run(victory: bool, voluntary_abandon: bool, penalty: float, tithe: int, summary: Dictionary, traits: Array, stress: Array = []) -> RunEndPayload:
	var p := RunEndPayload.new()
	p.victory = victory
	p.voluntary_abandon = voluntary_abandon
	p.penalty_fraction = penalty
	p.tithe_earned = tithe
	p.run_summary = summary
	p.trait_events = traits
	p.stress_events = stress
	return p
