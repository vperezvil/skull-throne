extends Enemy
class_name ConfigurableEnemy

func configure(definition: EnemyDefinition) -> void:
	if definition == null:
		return
	name = definition.display_name + " Enemy"
	max_hp = definition.max_hp
	attack = definition.attack
	initiative = definition.initiative
	xp_reward = definition.xp_reward
	combat_trait = definition.combat_trait
	if has_node("EnemySprite") and definition.texture_path != "":
		var tex: Texture2D = load(definition.texture_path)
		if tex:
			$EnemySprite.texture = tex
	if progress_bar:
		progress_bar.max_value = max_hp
	current_hp = max_hp

func mark_elite() -> void:
	if is_elite:
		return
	is_elite = true
	max_hp = int(max_hp * 1.5)
	attack = int(attack * 1.25)
	current_hp = max_hp
	xp_reward = int(xp_reward * 2)
	name = "Elite " + name
	if has_node("EnemySprite"):
		$EnemySprite.modulate = Color(1.25, 1.05, 0.5)
	if progress_bar:
		progress_bar.max_value = max_hp

func apply_run_scaling(depth: int) -> void:
	if depth <= 0:
		return
	max_hp += depth * 6
	attack += depth
	current_hp = max_hp
	if progress_bar:
		progress_bar.max_value = max_hp
