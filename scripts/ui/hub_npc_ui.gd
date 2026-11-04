extends RefCounted
class_name HubNpcUi

# Builds shop / trainer / stash controls for ui.gd hub and waystation panels.

static func npc_portrait(path: String) -> TextureRect:
	var tex := TextureRect.new()
	tex.custom_minimum_size = Vector2(96, 96)
	tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(path):
		tex.texture = load(path)
	return tex

static func add_npc_header(parent: VBoxContainer, portrait_path: String, title: String, tagline: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	row.add_child(npc_portrait(portrait_path))
	var col := VBoxContainer.new()
	row.add_child(col)
	var name_lbl := Label.new()
	name_lbl.text = title
	name_lbl.add_theme_font_size_override("font_size", 22)
	col.add_child(name_lbl)
	var tag := Label.new()
	tag.text = tagline
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.add_theme_font_size_override("font_size", 14)
	col.add_child(tag)

static func add_equipment_shop(
	parent: VBoxContainer,
	use_run_gold: bool,
	message_label: Label,
	on_purchased: Callable = Callable()
) -> void:
	for eq_id in EquipmentRegistry.get_shop_ids(use_run_gold):
		var def: EquipmentDefinition = EquipmentRegistry.get_definition(eq_id)
		if def == null:
			continue
		var price: int = def.waystation_price if use_run_gold else def.sanctum_price
		var btn := Button.new()
		btn.text = "%s (%d %s)" % [
			def.display_name,
			price,
			"gold" if use_run_gold else "tithe",
		]
		HubUiHelpers.style_secondary_button(btn)
		btn.pressed.connect(_on_buy_equipment.bind(eq_id, use_run_gold, message_label, def.display_name, on_purchased))
		parent.add_child(btn)

static func _on_buy_equipment(
	eq_id: String,
	use_run_gold: bool,
	message_label: Label,
	display_name: String,
	on_purchased: Callable
) -> void:
	if HubCommerce.buy_equipment(eq_id, use_run_gold):
		message_label.text = "Purchased %s - equip from stash list." % display_name
		if on_purchased.is_valid():
			on_purchased.call()
	else:
		message_label.text = "Cannot afford %s." % display_name

static func add_equip_stash(parent: VBoxContainer, party: Array, message_label: Label) -> void:
	if RunState.equipment_stash.is_empty():
		var empty := Label.new()
		empty.text = "Stash empty."
		parent.add_child(empty)
		return
	for eq_id in RunState.equipment_stash:
		var def: EquipmentDefinition = EquipmentRegistry.get_definition(eq_id)
		if def == null:
			continue
		for member in party:
			if member is Character:
				var ch: Character = member
				var btn := Button.new()
				btn.text = "Give %s → %s" % [def.display_name, ch.name]
				HubUiHelpers.style_secondary_button(btn)
				btn.pressed.connect(_on_equip.bind(ch, eq_id, message_label, def.display_name))
				parent.add_child(btn)

static func _on_equip(character: Character, eq_id: String, message_label: Label, display_name: String) -> void:
	if HubCommerce.equip_on_character(character, eq_id):
		message_label.text = "%s equipped on %s." % [display_name, character.name]
	else:
		message_label.text = "Could not equip."

static func add_skill_trainer(
	parent: VBoxContainer,
	party: Array,
	use_run_gold: bool,
	message_label: Label,
	on_trained: Callable = Callable()
) -> void:
	for member in party:
		if !(member is Character):
			continue
		var ch: Character = member
		var tier: int = MetaProgress.get_skill_tier(ch.character_id)
		var btn := Button.new()
		var price: int = 20 if use_run_gold else 35
		btn.text = "Train %s skills (tier %d/3) - %d %s" % [
			ch.name,
			tier,
			price,
			"gold" if use_run_gold else "tithe",
		]
		btn.disabled = tier >= 3
		HubUiHelpers.style_secondary_button(btn)
		btn.pressed.connect(_on_train.bind(ch, use_run_gold, message_label, on_trained))
		parent.add_child(btn)

static func _on_train(
	character: Character,
	use_run_gold: bool,
	message_label: Label,
	on_trained: Callable
) -> void:
	if HubCommerce.train_skill(character.character_id, use_run_gold):
		message_label.text = "%s skill tier increased." % character.name
		if character is Character:
			character.refresh_skills_from_training()
		if on_trained.is_valid():
			on_trained.call()
	else:
		message_label.text = "Training failed - need currency or max tier."

static func add_trait_treatment(
	parent: VBoxContainer,
	party: Array,
	message_label: Label,
	on_changed: Callable = Callable()
) -> void:
	var header := Label.new()
	header.text = "Purify Stains (breaking an Oath costs more tithe)"
	header.add_theme_font_size_override("font_size", 16)
	parent.add_child(header)
	var any: bool = false
	for member in party:
		if !(member is Character):
			continue
		var ch: Character = member
		for trait_id in MetaProgress.get_traits(ch.character_id):
			any = true
			var btn := Button.new()
			var cost: int = CharacterTraits.treatment_cost(trait_id)
			var cat: String = CharacterTraits.get_category_label(trait_id)
			btn.text = "Purify %s: %s %s (%d tithe)" % [ch.name, cat, CharacterTraits.get_title(trait_id), cost]
			HubUiHelpers.style_secondary_button(btn)
			btn.pressed.connect(_on_treat_trait.bind(ch, trait_id, message_label, on_changed))
			parent.add_child(btn)
	if !any:
		var empty := Label.new()
		empty.text = "No soul marks on the current party."
		parent.add_child(empty)

static func _on_treat_trait(
	character: Character,
	trait_id: String,
	message_label: Label,
	on_changed: Callable
) -> void:
	if HubCommerce.treat_trait(character.character_id, trait_id):
		message_label.text = "%s shed %s: %s." % [
			character.name,
			CharacterTraits.get_category_label(trait_id),
			CharacterTraits.get_title(trait_id),
		]
		if character is Character:
			character.recalculate_combat_stats()
		if on_changed.is_valid():
			on_changed.call()
	else:
		message_label.text = "Cannot treat - need Blood Tithe."

static func add_potion_buy(parent: VBoxContainer, use_run_gold: bool, message_label: Label) -> void:
	var price: int = 18 if use_run_gold else 25
	var btn := Button.new()
	btn.text = "Potion (%d %s)" % [price, "gold" if use_run_gold else "tithe"]
	HubUiHelpers.style_secondary_button(btn)
	btn.pressed.connect(_on_buy_potion.bind(use_run_gold, message_label))
	parent.add_child(btn)

static func _on_buy_potion(use_run_gold: bool, message_label: Label) -> void:
	if HubCommerce.buy_potion(use_run_gold):
		message_label.text = "Potion added to inventory."
	else:
		message_label.text = "Not enough currency."
