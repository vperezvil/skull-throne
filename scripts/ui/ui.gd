extends CanvasLayer

signal game_started
signal character_added
signal character_removed
signal continue_adventure
signal return_to_hub(victory: bool)
signal continue_waystation

@onready var main_menu = $"Main-menu"
@onready var character_menu = $"Character-menu"
@onready var game_over_menu = $"Game-Over"
@onready var end_game_menu = $"Level-Ended"
@onready var game_menu = $"Game-menu"
@onready var error_message = $"Character-menu/Error"
@onready var death_count_message = $"Game-Over/InfoDeathsLabel"
@onready var end_message = $"Level-Ended/ExplanationLabel"
@onready var end_title_label = $"Level-Ended/EndLabel"
@onready var main_theme = $"Main-menu/Main Theme"
@onready var game_won_music = $"Level-Ended/Game Won Theme"
@onready var game_over_music = $"Game-Over/Game Over Theme"
@onready var game_over_retry = $"Game-Over/Retry"
@onready var level_ended_retry = $"Level-Ended/Retry"
@onready var exit_dialog = $"Game-menu/ConfirmationDialog"
@onready var item_grid = $"Game-menu/ItemPanel/ItemGrid"
@onready var item_grid_panel = $"Game-menu/ItemPanel"
@onready var character_grid = $"Game-menu/CharacterPanel/CharacterGrid"
@onready var character_grid_panel = $"Game-menu/CharacterPanel"
@onready var options_menu = $"Game-menu/Options"
@onready var zone_title_label: RichTextLabel
@onready var continue_button: Button

var pause_backdrop: ColorRect
var pause_title: Label
var resume_button: Button
var settings_panel: Panel
var settings_open: bool = false
var hub_panel: Panel
var hub_tithe_label: Label
var hub_stats_label: RichTextLabel
var hub_party_label: Label
var hub_run_hint_label: Label
var hub_message_label: Label
var sanctum_button: Button
var hub_tabs: TabContainer
var hub_tab_grum: VBoxContainer
var hub_tab_enchantress: VBoxContainer
var waystation_panel: Panel
var waystation_message: Label
var waystation_gold_label: Label
var early_return_dialog: ConfirmationDialog
var credits_panel: Panel
var party_hud: Panel
var party_hud_labels: Array[Label] = []
var shrine_panel: Panel
var shrine_message: Label
var shrine_option_box: VBoxContainer
var map_toast: Label
var ascended_toggle: CheckButton
var hub_mirror_select: OptionButton
var hub_begin_btn: Button
var hub_party_chip_row: HBoxContainer
var hub_sanctum_map: HubSanctumMap
var hub_details_panel: PanelContainer
var hub_details_toggle: CheckButton
var _shrine_campaign_complete: bool = false
var _menu_backdrop: ColorRect
var main_menu_settings_panel: Panel
var main_menu_settings_open: bool = false
var hub_services_overlay: Panel
var hub_route_panel: Panel
var hub_route_list: ItemList
var hub_prep_panel: Panel
var journey_button: Button
var journey_panel: Panel
var journey_list: ItemList

var character_ids_toggled = []
var characters = []
var in_battle = false
const GAME_OVER_DEATHS_TEMPLATE := "{COUNT} skulls added to the Skull Throne.\nThere's currently {TOTAL_COUNT} skulls on the throne."

func _ready():
	main_theme.stream = ZoneMusic.get_hub_music()
	Global.assign_music_bus(main_theme)
	Global.assign_music_bus(game_won_music)
	Global.assign_music_bus(game_over_music)
	main_theme.play()
	_setup_pause_ui()
	_setup_hub_menu()
	_setup_waystation_panel()
	_setup_early_return_dialog()
	_setup_party_hud()
	_setup_credits_panel()
	_setup_shrine_panel()
	_setup_map_toast()
	_setup_menu_backdrop()
	_setup_main_menu_options()
	_setup_character_select_buttons()
	zone_title_label = RichTextLabel.new()
	zone_title_label.name = "ZoneTitle"
	zone_title_label.offset_left = 32
	zone_title_label.offset_top = 24
	zone_title_label.offset_right = 720
	zone_title_label.offset_bottom = 72
	zone_title_label.visible = false
	add_child(zone_title_label)
	_setup_journey_ui()
	continue_button = Button.new()
	continue_button.name = "Continue"
	continue_button.text = "Continue"
	continue_button.visible = false
	continue_button.offset_left = 873.0
	continue_button.offset_top = 480.0
	continue_button.offset_right = 993.0
	continue_button.offset_bottom = 534.0
	continue_button.pressed.connect(_on_continue_adventure_pressed)
	end_game_menu.add_child(continue_button)
	sanctum_button = Button.new()
	sanctum_button.name = "ReturnToSanctum"
	sanctum_button.text = "Return to Blood Sanctum"
	sanctum_button.visible = false
	sanctum_button.offset_left = 640.0
	sanctum_button.offset_top = 480.0
	sanctum_button.offset_right = 860.0
	sanctum_button.offset_bottom = 534.0
	sanctum_button.pressed.connect(_on_return_to_sanctum_pressed)
	end_game_menu.add_child(sanctum_button)
	_refresh_character_select_locks()
	_rebuild_hub_trainers_and_stash()
	_sync_menu_backdrop()

func _setup_early_return_dialog() -> void:
	early_return_dialog = ConfirmationDialog.new()
	early_return_dialog.title = "Leave the descent?"
	early_return_dialog.dialog_hide_on_ok = false
	early_return_dialog.confirmed.connect(_on_early_return_confirmed)
	add_child(early_return_dialog)

func _request_voluntary_return() -> void:
	if !RunState.campaign_active:
		get_parent().abandon_run()
		return
	early_return_dialog.dialog_text = RunState.get_voluntary_abandon_warning_text()
	early_return_dialog.popup_centered()

func _on_early_return_confirmed() -> void:
	waystation_panel.visible = false
	get_parent().abandon_run()

func _setup_hub_menu() -> void:
	hub_panel = Panel.new()
	hub_panel.name = "BloodSanctumHub"
	hub_panel.visible = false
	hub_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	hub_panel.add_theme_stylebox_override("panel", HubUiHelpers.flat_panel(Color(0.04, 0.02, 0.03, 0.97), Color(0.25, 0.08, 0.06)))
	add_child(hub_panel)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 36)
	hub_panel.add_child(margin)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "Blood Sanctum"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", Global.get_ui_font_size(40))
	header.add_child(title)
	hub_tithe_label = Label.new()
	hub_tithe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hub_tithe_label.add_theme_font_size_override("font_size", Global.get_ui_font_size(18))
	hub_tithe_label.modulate = HubUiHelpers.COLOR_ACCENT
	header.add_child(hub_tithe_label)
	hub_sanctum_map = HubSanctumMap.new()
	hub_sanctum_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hub_sanctum_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hub_sanctum_map.service_picked.connect(_on_hub_service_picked)
	var world_node: Node = get_parent()
	if world_node != null:
		var map_layer := world_node.get_node_or_null("Map") as TileMapLayer
		if map_layer != null and map_layer.tile_set != null:
			hub_sanctum_map.set_template_tile_set(map_layer.tile_set)
	root.add_child(hub_sanctum_map)
	var dock := HBoxContainer.new()
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_theme_constant_override("separation", 12)
	root.add_child(dock)
	var party_btn := Button.new()
	party_btn.text = "Party"
	party_btn.pressed.connect(_on_hub_change_party)
	HubUiHelpers.style_secondary_button(party_btn)
	dock.add_child(party_btn)
	var route_btn := Button.new()
	route_btn.text = "Descent route"
	route_btn.pressed.connect(_on_hub_route_menu_pressed)
	HubUiHelpers.style_secondary_button(route_btn)
	dock.add_child(route_btn)
	var prep_btn := Button.new()
	prep_btn.text = "Run prep"
	prep_btn.pressed.connect(_on_hub_prep_menu_pressed)
	HubUiHelpers.style_secondary_button(prep_btn)
	dock.add_child(prep_btn)
	hub_begin_btn = Button.new()
	hub_begin_btn.text = "Begin descent"
	hub_begin_btn.pressed.connect(_on_hub_begin_descent)
	HubUiHelpers.style_primary_button(hub_begin_btn)
	dock.add_child(hub_begin_btn)
	var main_btn := Button.new()
	main_btn.text = "Main menu"
	main_btn.pressed.connect(_on_hub_main_menu)
	HubUiHelpers.style_ghost_button(main_btn)
	dock.add_child(main_btn)
	hub_message_label = Label.new()
	hub_message_label.modulate = Color(1.0, 0.82, 0.55)
	hub_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hub_message_label.add_theme_font_size_override("font_size", Global.get_ui_font_size(14))
	hub_message_label.visible = false
	root.add_child(hub_message_label)
	_build_hub_services_overlay()
	_build_hub_route_panel()
	_build_hub_prep_panel()
	hub_party_chip_row = HBoxContainer.new()
	hub_party_chip_row.visible = false
	hub_details_panel = PanelContainer.new()
	hub_details_panel.visible = false
	hub_details_toggle = CheckButton.new()
	hub_details_toggle.visible = false
	_refresh_hub_ui()

func _build_hub_services_overlay() -> void:
	hub_services_overlay = Panel.new()
	hub_services_overlay.name = "HubServicesOverlay"
	hub_services_overlay.visible = false
	hub_services_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	hub_services_overlay.add_theme_stylebox_override("panel", HubUiHelpers.flat_panel(Color(0.02, 0.01, 0.02, 0.94), HubUiHelpers.COLOR_ACCENT))
	hub_panel.add_child(hub_services_overlay)
	var omargin := MarginContainer.new()
	omargin.set_anchors_preset(Control.PRESET_FULL_RECT)
	omargin.add_theme_constant_override("margin_left", 64)
	omargin.add_theme_constant_override("margin_top", 48)
	omargin.add_theme_constant_override("margin_right", 64)
	omargin.add_theme_constant_override("margin_bottom", 48)
	hub_services_overlay.add_child(omargin)
	var ovbox := VBoxContainer.new()
	ovbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	ovbox.add_theme_constant_override("separation", 12)
	omargin.add_child(ovbox)
	var top_row := HBoxContainer.new()
	ovbox.add_child(top_row)
	var svc_title := Label.new()
	svc_title.text = "Sanctum services"
	svc_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	HubUiHelpers.style_section_title(svc_title, 24)
	top_row.add_child(svc_title)
	var close_svc := Button.new()
	close_svc.text = "Close"
	close_svc.pressed.connect(_on_hub_services_close)
	HubUiHelpers.style_ghost_button(close_svc)
	top_row.add_child(close_svc)
	hub_tabs = TabContainer.new()
	hub_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hub_tabs.add_theme_font_size_override("font_size", Global.get_ui_font_size(16))
	ovbox.add_child(hub_tabs)
	hub_tab_grum = VBoxContainer.new()
	hub_tab_grum.name = "Grum"
	hub_tab_grum.add_theme_constant_override("separation", 8)
	HubNpcUi.add_npc_header(
		hub_tab_grum,
		"res://assets/monsters/unique/grum.png",
		"Grum — Quartermaster",
		"Weapons, trinkets, and potions for Blood Tithe."
	)
	HubNpcUi.add_potion_buy(hub_tab_grum, false, hub_message_label)
	HubNpcUi.add_equipment_shop(hub_tab_grum, false, hub_message_label, _rebuild_hub_grum_commerce)
	hub_tabs.add_child(HubUiHelpers.wrap_scroll(hub_tab_grum, 420.0))
	hub_tab_enchantress = VBoxContainer.new()
	hub_tab_enchantress.name = "Enchantress"
	hub_tab_enchantress.add_theme_constant_override("separation", 8)
	HubNpcUi.add_npc_header(
		hub_tab_enchantress,
		"res://assets/monsters/unique/enchantress.png",
		"Enchantress — Tutor",
		"Train skills, purify stains, and spend tithe on lasting power."
	)
	hub_tabs.add_child(HubUiHelpers.wrap_scroll(hub_tab_enchantress, 420.0))
	var tab_boons := VBoxContainer.new()
	tab_boons.name = "Sanctum boons"
	tab_boons.add_theme_constant_override("separation", 8)
	_add_hub_button(tab_boons, "Vitality (+12 HP)", _on_hub_upgrade_vitality, true)
	_add_hub_button(tab_boons, "Fury (+2 ATK)", _on_hub_upgrade_fury, true)
	_add_hub_button(tab_boons, "Supplies (start items)", _on_hub_upgrade_supply, true)
	hub_tabs.add_child(HubUiHelpers.wrap_scroll(tab_boons, 420.0))
	var stash_box := VBoxContainer.new()
	stash_box.name = "Equip stash"
	stash_box.add_theme_constant_override("separation", 8)
	hub_tabs.add_child(HubUiHelpers.wrap_scroll(stash_box, 420.0))
	hub_tabs.set_tab_title(0, "Shop")
	hub_tabs.set_tab_title(1, "Train")
	hub_tabs.set_tab_title(2, "Boons")
	hub_tabs.set_tab_title(3, "Stash")

func _build_hub_route_panel() -> void:
	hub_route_panel = Panel.new()
	hub_route_panel.name = "HubRoutePanel"
	hub_route_panel.visible = false
	hub_route_panel.set_anchors_preset(Control.PRESET_CENTER)
	hub_route_panel.offset_left = -280.0
	hub_route_panel.offset_top = -220.0
	hub_route_panel.offset_right = 280.0
	hub_route_panel.offset_bottom = 220.0
	hub_route_panel.add_theme_stylebox_override("panel", HubUiHelpers.flat_panel(Color(0.08, 0.04, 0.05, 0.96), HubUiHelpers.COLOR_ACCENT))
	hub_panel.add_child(hub_route_panel)
	var rm := MarginContainer.new()
	rm.set_anchors_preset(Control.PRESET_FULL_RECT)
	rm.add_theme_constant_override("margin_left", 24)
	rm.add_theme_constant_override("margin_top", 20)
	rm.add_theme_constant_override("margin_right", 24)
	rm.add_theme_constant_override("margin_bottom", 20)
	hub_route_panel.add_child(rm)
	var rv := VBoxContainer.new()
	rv.set_anchors_preset(Control.PRESET_FULL_RECT)
	rv.add_theme_constant_override("separation", 12)
	rm.add_child(rv)
	var rt := Label.new()
	rt.text = "Descent route"
	HubUiHelpers.style_section_title(rt, 22)
	rv.add_child(rt)
	hub_route_list = ItemList.new()
	hub_route_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hub_route_list.select_mode = ItemList.SELECT_SINGLE
	rv.add_child(hub_route_list)
	var rrow := HBoxContainer.new()
	rrow.add_theme_constant_override("separation", 10)
	rv.add_child(rrow)
	var reroute := Button.new()
	reroute.text = "Reroll route"
	reroute.pressed.connect(_on_hub_reroll_route)
	HubUiHelpers.style_secondary_button(reroute)
	rrow.add_child(reroute)
	var rclose := Button.new()
	rclose.text = "Close"
	rclose.pressed.connect(func() -> void: hub_route_panel.visible = false)
	HubUiHelpers.style_ghost_button(rclose)
	rrow.add_child(rclose)

func _build_hub_prep_panel() -> void:
	hub_prep_panel = Panel.new()
	hub_prep_panel.name = "HubPrepPanel"
	hub_prep_panel.visible = false
	hub_prep_panel.set_anchors_preset(Control.PRESET_CENTER)
	hub_prep_panel.offset_left = -320.0
	hub_prep_panel.offset_top = -240.0
	hub_prep_panel.offset_right = 320.0
	hub_prep_panel.offset_bottom = 240.0
	hub_prep_panel.add_theme_stylebox_override("panel", HubUiHelpers.flat_panel(Color(0.08, 0.04, 0.05, 0.96), HubUiHelpers.COLOR_ACCENT))
	hub_panel.add_child(hub_prep_panel)
	var pm := MarginContainer.new()
	pm.set_anchors_preset(Control.PRESET_FULL_RECT)
	pm.add_theme_constant_override("margin_left", 24)
	pm.add_theme_constant_override("margin_top", 20)
	pm.add_theme_constant_override("margin_right", 24)
	pm.add_theme_constant_override("margin_bottom", 20)
	hub_prep_panel.add_child(pm)
	var pv := VBoxContainer.new()
	pv.set_anchors_preset(Control.PRESET_FULL_RECT)
	pv.add_theme_constant_override("separation", 10)
	pm.add_child(pv)
	var pt := Label.new()
	pt.text = "Run preparation"
	HubUiHelpers.style_section_title(pt, 22)
	pv.add_child(pt)
	hub_run_hint_label = Label.new()
	hub_run_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HubUiHelpers.style_body_label(hub_run_hint_label, 14)
	pv.add_child(hub_run_hint_label)
	hub_party_label = Label.new()
	hub_party_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HubUiHelpers.style_body_label(hub_party_label, 14)
	pv.add_child(hub_party_label)
	hub_stats_label = RichTextLabel.new()
	hub_stats_label.custom_minimum_size = Vector2(0, 72)
	hub_stats_label.scroll_active = false
	hub_stats_label.fit_content = true
	hub_stats_label.add_theme_font_size_override("normal_font_size", Global.get_ui_font_size(13))
	pv.add_child(hub_stats_label)
	var mirror_row := HBoxContainer.new()
	mirror_row.add_theme_constant_override("separation", 8)
	var mirror_lbl := Label.new()
	mirror_lbl.text = "Lock stats:"
	mirror_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	HubUiHelpers.style_body_label(mirror_lbl, 14)
	mirror_row.add_child(mirror_lbl)
	hub_mirror_select = OptionButton.new()
	hub_mirror_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mirror_row.add_child(hub_mirror_select)
	pv.add_child(mirror_row)
	var reroll_btn := Button.new()
	reroll_btn.text = "Reroll stat preview"
	reroll_btn.pressed.connect(_on_hub_reroll_stats)
	HubUiHelpers.style_secondary_button(reroll_btn)
	pv.add_child(reroll_btn)
	var mirror_btn := Button.new()
	mirror_btn.text = "Lock mirror (60 tithe)"
	mirror_btn.pressed.connect(_on_hub_lock_mirror)
	HubUiHelpers.style_secondary_button(mirror_btn)
	pv.add_child(mirror_btn)
	ascended_toggle = CheckButton.new()
	ascended_toggle.text = "Ascended descent"
	ascended_toggle.toggled.connect(_on_ascended_toggled)
	pv.add_child(ascended_toggle)
	var prep_close := Button.new()
	prep_close.text = "Close"
	prep_close.pressed.connect(func() -> void: hub_prep_panel.visible = false)
	HubUiHelpers.style_ghost_button(prep_close)
	pv.add_child(prep_close)

func _setup_journey_ui() -> void:
	journey_button = Button.new()
	journey_button.name = "JourneyMenuButton"
	journey_button.visible = false
	journey_button.text = "Journey"
	journey_button.offset_left = 32.0
	journey_button.offset_top = 24.0
	journey_button.offset_right = 160.0
	journey_button.offset_bottom = 64.0
	journey_button.pressed.connect(_on_journey_menu_pressed)
	add_child(journey_button)
	journey_panel = Panel.new()
	journey_panel.name = "JourneyPanel"
	journey_panel.visible = false
	journey_panel.set_anchors_preset(Control.PRESET_CENTER)
	journey_panel.offset_left = -300.0
	journey_panel.offset_top = -240.0
	journey_panel.offset_right = 300.0
	journey_panel.offset_bottom = 240.0
	journey_panel.add_theme_stylebox_override("panel", HubUiHelpers.flat_panel(Color(0.06, 0.03, 0.05, 0.96), HubUiHelpers.COLOR_ACCENT))
	add_child(journey_panel)
	var jm := MarginContainer.new()
	jm.set_anchors_preset(Control.PRESET_FULL_RECT)
	jm.add_theme_constant_override("margin_left", 24)
	jm.add_theme_constant_override("margin_top", 20)
	jm.add_theme_constant_override("margin_right", 24)
	jm.add_theme_constant_override("margin_bottom", 20)
	journey_panel.add_child(jm)
	var jv := VBoxContainer.new()
	jv.set_anchors_preset(Control.PRESET_FULL_RECT)
	jv.add_theme_constant_override("separation", 12)
	jm.add_child(jv)
	var jt := Label.new()
	jt.text = "Descent progress"
	HubUiHelpers.style_section_title(jt, 22)
	jv.add_child(jt)
	journey_list = ItemList.new()
	journey_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	jv.add_child(journey_list)
	var jclose := Button.new()
	jclose.text = "Close"
	jclose.pressed.connect(func() -> void: journey_panel.visible = false)
	HubUiHelpers.style_ghost_button(jclose)
	jv.add_child(jclose)

func _add_hub_button(parent: VBoxContainer, text: String, callback: Callable, dynamic_cost: bool = false) -> void:
	var btn := Button.new()
	btn.text = text
	if dynamic_cost:
		btn.set_meta("dynamic_cost", true)
	btn.pressed.connect(callback.bind(btn))
	HubUiHelpers.style_secondary_button(btn)
	parent.add_child(btn)

func show_hub() -> void:
	hub_message_label.text = ""
	RunState.refresh_hub_descent_preview()
	if MetaProgress.should_show_sanctum_tutorial():
		hub_message_label.text = "Select a party, then walk the sanctum (WASD) and talk to NPCs (E)."
		hub_message_label.visible = true
		MetaProgress.mark_sanctum_tutorial_seen()
	hub_panel.visible = true
	character_menu.visible = false
	main_menu.visible = false
	if zone_title_label:
		zone_title_label.visible = false
	_sync_menu_backdrop()
	_rebuild_hub_trainers_and_stash()
	_refresh_hub_ui()

func show_hub_after_run(payload: RunEndPayload) -> void:
	hide_run_overlays()
	hub_panel.visible = true
	RunState.refresh_hub_descent_preview()
	_sync_menu_backdrop()
	var tithe_earned: int = payload.tithe_earned
	var victory: bool = payload.victory
	var penalty: float = payload.penalty_fraction
	if victory:
		hub_message_label.text = "Khorne is slain! You earned %d Blood Tithe." % tithe_earned
	elif penalty > 0.0:
		hub_message_label.text = "Early return penalty (%d%%). You earned %d Blood Tithe after losses." % [
			int(round(penalty * 100.0)), tithe_earned]
	else:
		hub_message_label.text = "The run ends. You earned %d Blood Tithe for the sanctum." % tithe_earned
	var run_summary: Dictionary = payload.run_summary
	if !run_summary.is_empty():
		var mod_name: String = RunModifiers.get_display_name(String(run_summary.get("modifier_id", "")))
		hub_message_label.text += (
			"\n\nRun debrief: %d floor(s), %d run gold, %d shrine blessing(s).\nModifier: %s%s."
			% [
				int(run_summary.get("floors_cleared", 0)),
				int(run_summary.get("gold_earned", 0)),
				int(run_summary.get("blessings_taken", 0)),
				mod_name,
				" | Ascended" if run_summary.get("ascended", false) else "",
			]
		)
		var traits: Array = run_summary.get("traits_gained", [])
		if traits.size() > 0:
			var trait_lines: PackedStringArray = []
			for entry in traits:
				if entry is Dictionary:
					var who: String = String(entry.get("name", "Hero"))
					var title: String = String(entry.get("title", ""))
					var cat: String = String(entry.get("category", CharacterTraits.get_category_label(String(entry.get("trait_id", "")))))
					trait_lines.append("%s: %s %s" % [who, cat, title])
			if trait_lines.size() > 0:
				hub_message_label.text += "\n\nSoul marks gained:\n" + "\n".join(trait_lines)
		if !payload.trait_events.is_empty() and MetaProgress.should_show_stain_tip():
			hub_message_label.text += "\n\nTip: Purify Stains at the Enchantress. Stress breaks can also forge marks."
			MetaProgress.mark_tutorial_stain_seen()
	if zone_title_label:
		zone_title_label.visible = false
	_rebuild_hub_trainers_and_stash()
	_refresh_hub_ui()

func hide_run_overlays() -> void:
	end_game_menu.visible = false
	game_over_menu.visible = false
	continue_button.visible = false
	sanctum_button.visible = false
	game_won_music.stop()
	game_over_music.stop()
	in_battle = false
	if shrine_panel:
		shrine_panel.visible = false
	if map_toast:
		map_toast.visible = false

func _refresh_hub_ui() -> void:
	if hub_tithe_label == null:
		return
	hub_tithe_label.text = "Blood Tithe: %d\nSkulls on throne: %d" % [
		MetaProgress.blood_tithe,
		Global.get_skull_count(),
	]
	hub_stats_label.text = (
		"Runs: %d attempted · %d victories · %d lifetime floors\n"
		% [MetaProgress.runs_attempted, MetaProgress.runs_won, MetaProgress.get_lifetime_floors_cleared()]
		+ "Upgrades — Vitality %d/%d · Fury %d/%d · Supplies %d/%d\n"
		% [
			MetaProgress.vitality_level,
			MetaProgress.VITALITY_MAX,
			MetaProgress.fury_level,
			MetaProgress.FURY_MAX,
			MetaProgress.supply_level,
			MetaProgress.SUPPLY_MAX,
		]
		+ "Inventory: %d items · Waystation every %d floors"
		% [Inventory.items.keys().size(), GameConstants.FLOORS_BETWEEN_WAYSTATIONS]
	)
	hub_run_hint_label.text = RunState.get_progression_hint_text()
	_refresh_hub_mirror_select()
	_refresh_hub_party_chips()
	var preview_party: Array = _get_hub_party_for_preview()
	RunState.refresh_stat_preview(preview_party)
	var roll_lines: PackedStringArray = []
	for member in preview_party:
		if member is Character:
			roll_lines.append(RunState.format_stat_preview_line(member.character_id, member.name))
	if roll_lines.is_empty():
		hub_party_label.text = "Choose a party with Change party, then reroll preview if you want different stats."
	else:
		hub_party_label.text = "\n".join(roll_lines)
	var party_names: PackedStringArray = []
	for id in character_ids_toggled:
		var def: CharacterDefinition = ContentRegistry.get_character_for_menu_index(id)
		if def != null:
			party_names.append(CharacterTraits.format_roster_line(def.character_id, def.display_name))
	if party_names.size() > 0:
		hub_party_label.text += "\n\n" + CharacterTraits.MARKS_LABEL + ":\n" + "\n".join(party_names)
	var has_party: bool = character_ids_toggled.size() > 0
	if hub_begin_btn:
		hub_begin_btn.disabled = !has_party
		hub_begin_btn.text = "Begin descent" if has_party else "Select a party first"
	if hub_sanctum_map:
		hub_sanctum_map.set_hub_state(has_party, "")
		if has_party and character_ids_toggled.size() > 0:
			var lead_def: CharacterDefinition = ContentRegistry.get_character_for_menu_index(character_ids_toggled[0])
			if lead_def != null and lead_def.scene_path != "":
				var packed: PackedScene = load(lead_def.scene_path) as PackedScene
				if packed != null:
					var preview: Node = packed.instantiate()
					var sprite_node: Node = preview.get_node_or_null("Body")
					if sprite_node == null:
						sprite_node = preview.get_node_or_null("BodySkeleton")
					if sprite_node is Sprite2D:
						var body: Sprite2D = sprite_node as Sprite2D
						if body.texture != null:
							hub_sanctum_map.set_party_walker_texture(body.texture)
					preview.queue_free()
	_refresh_hub_route_list()
	if ascended_toggle:
		ascended_toggle.disabled = !MetaProgress.can_use_ascended()
		ascended_toggle.button_pressed = MetaProgress.ascended_next_run
	_refresh_hub_upgrade_button_labels()

func _on_hub_service_picked(tab_index: int) -> void:
	if hub_tabs == null or hub_services_overlay == null:
		return
	hub_tabs.current_tab = tab_index
	hub_services_overlay.visible = true
	_rebuild_hub_trainers_and_stash()

func _on_hub_services_close() -> void:
	if hub_services_overlay:
		hub_services_overlay.visible = false

func _on_hub_route_menu_pressed() -> void:
	_refresh_hub_route_list()
	if hub_route_panel:
		hub_route_panel.visible = true

func _on_hub_prep_menu_pressed() -> void:
	if hub_prep_panel:
		hub_prep_panel.visible = true

func _refresh_hub_route_list() -> void:
	if hub_route_list == null:
		return
	hub_route_list.clear()
	var zone_ids: Array[String] = RunState.get_hub_descent_preview()
	if zone_ids.is_empty():
		hub_route_list.add_item("Begin descent to roll your path.")
		return
	for i in zone_ids.size():
		var zone_id: String = zone_ids[i]
		var zone: ZoneDefinition = ContentRegistry.get_zone_by_id(zone_id)
		var title: String = zone.display_name if zone != null else zone_id
		if zone != null and zone.is_final_zone:
			title = "Skull Throne"
		var line := "%d. %s" % [i + 1, title]
		if (i + 1) % GameConstants.FLOORS_BETWEEN_WAYSTATIONS == 0 and i + 1 < zone_ids.size():
			line += "  (waystation)"
		hub_route_list.add_item(line)

func _on_journey_menu_pressed() -> void:
	_refresh_journey_list()
	if journey_panel:
		journey_panel.visible = true

func _refresh_journey_list() -> void:
	if journey_list == null:
		return
	journey_list.clear()
	if !RunState.campaign_active:
		journey_list.add_item("No active descent.")
		return
	var current: int = RunState.get_current_floor_number()
	for i in RunState.run_floor_ids.size():
		var zone_id: String = RunState.run_floor_ids[i]
		var zone: ZoneDefinition = ContentRegistry.get_zone_by_id(zone_id)
		var title: String = zone.display_name if zone != null else zone_id
		if zone != null and zone.is_final_zone:
			title = "Skull Throne"
		var prefix := "> " if i + 1 == current else "  "
		journey_list.add_item("%s%d. %s" % [prefix, i + 1, title])

func _on_hub_details_toggled(show_details: bool) -> void:
	if hub_details_panel:
		hub_details_panel.visible = show_details

func _on_hub_reroll_route() -> void:
	RunState.refresh_hub_descent_preview()
	_refresh_hub_route_list()
	hub_message_label.text = "Rolled a new descent route."
	hub_message_label.visible = true

func _refresh_hub_party_chips() -> void:
	if hub_party_chip_row == null:
		return
	for child in hub_party_chip_row.get_children():
		child.queue_free()
	if character_ids_toggled.is_empty():
		var empty := Label.new()
		empty.text = "No heroes selected yet."
		HubUiHelpers.style_body_label(empty, 15)
		hub_party_chip_row.add_child(empty)
		return
	for id in character_ids_toggled:
		var def: CharacterDefinition = ContentRegistry.get_character_for_menu_index(id)
		if def == null:
			continue
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", HubUiHelpers.flat_panel(Color(0.14, 0.07, 0.08, 0.95)))
		var lbl := Label.new()
		lbl.text = def.display_name
		lbl.add_theme_font_size_override("font_size", Global.get_ui_font_size(15))
		chip.add_child(lbl)
		hub_party_chip_row.add_child(chip)

func _get_hub_party_for_preview() -> Array:
	var party: Array = _get_hub_party()
	if party.size() > 0:
		return party
	var world: Node = get_parent()
	if world == null:
		return []
	var fallback: Array = []
	for id in character_ids_toggled:
		if world.character_dict.has(id):
			fallback.append(world.character_dict[id])
	return fallback

func _on_ascended_toggled(on: bool) -> void:
	MetaProgress.set_ascended_next_run(on)

func _on_hub_reroll_stats() -> void:
	RunState.reroll_stat_preview(_get_hub_party_for_preview())
	hub_message_label.text = "Rolled new stat preview for this party."
	_refresh_hub_ui()

func _refresh_hub_mirror_select() -> void:
	if hub_mirror_select == null:
		return
	hub_mirror_select.clear()
	var party: Array = _get_hub_party_for_preview()
	for member in party:
		if member is Character:
			hub_mirror_select.add_item(member.name)
	if party.is_empty():
		hub_mirror_select.add_item("(no party)")
		hub_mirror_select.disabled = true
	else:
		hub_mirror_select.disabled = false
		var locked: String = MetaProgress.get_locked_stat_character_id()
		if locked != "":
			for i in party.size():
				if party[i] is Character and (party[i] as Character).character_id == locked:
					hub_mirror_select.select(i)
					break

func _on_hub_lock_mirror() -> void:
	var party: Array = _get_hub_party_for_preview()
	if party.is_empty():
		hub_message_label.text = "Select a party first."
		return
	var idx: int = hub_mirror_select.selected
	if idx < 0 or idx >= party.size():
		hub_message_label.text = "Choose which hero to lock in the dropdown above."
		return
	var ch: Character = party[idx]
	var roll: Dictionary = RunState.get_stat_preview(ch.character_id)
	if roll.is_empty():
		hub_message_label.text = "No preview roll for that hero."
		return
	if HubCommerce.lock_mirror_for_preview(ch.character_id, roll):
		hub_message_label.text = "Mirror locked stats for %s until you clear it or lock another hero." % ch.name
		_refresh_hub_mirror_select()
	else:
		hub_message_label.text = "Need 60 Blood Tithe to lock the mirror."

func _refresh_hub_upgrade_button_labels() -> void:
	if hub_panel == null:
		return
	for child in hub_panel.get_children():
		_walk_hub_buttons(child)

func _walk_hub_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is Button and child.get_meta("dynamic_cost", false):
			if child.text.begins_with("Vitality"):
				child.text = "Vitality (+12 HP) - %d tithe" % MetaProgress.upgrade_vitality_cost()
				child.disabled = !MetaProgress.can_upgrade_vitality()
			elif child.text.begins_with("Fury"):
				child.text = "Fury (+2 ATK) - %d tithe" % MetaProgress.upgrade_fury_cost()
				child.disabled = !MetaProgress.can_upgrade_fury()
			elif child.text.begins_with("Supplies"):
				child.text = "Supplies (start items) - %d tithe" % MetaProgress.upgrade_supply_cost()
				child.disabled = !MetaProgress.can_upgrade_supply()
		_walk_hub_buttons(child)

func _on_hub_upgrade_vitality(_btn: Button) -> void:
	if MetaProgress.buy_upgrade_vitality():
		hub_message_label.text = "Vitality boon purchased."
	else:
		hub_message_label.text = "Cannot purchase Vitality upgrade."
	_refresh_hub_ui()

func _on_hub_upgrade_fury(_btn: Button) -> void:
	if MetaProgress.buy_upgrade_fury():
		hub_message_label.text = "Fury boon purchased."
	else:
		hub_message_label.text = "Cannot purchase Fury upgrade."
	_refresh_hub_ui()

func _on_hub_upgrade_supply(_btn: Button) -> void:
	if MetaProgress.buy_upgrade_supply():
		hub_message_label.text = "Supply lines improved."
	else:
		hub_message_label.text = "Cannot purchase Supplies upgrade."
	_refresh_hub_ui()

func _on_hub_rest_pressed() -> void:
	var world: Node = get_parent()
	if world != null and world.has_method("_refresh_party_at_hub"):
		world._refresh_party_at_hub()
	hub_message_label.text = "The sanctum mends your wounds. Party restored."

func _on_hub_begin_descent() -> void:
	if character_ids_toggled.is_empty():
		hub_message_label.text = "Pick at least one hero with Change party, then try again."
		_refresh_hub_ui()
		return
	hub_panel.visible = false
	_sync_menu_backdrop()
	game_started.emit()

func _on_hub_change_party() -> void:
	hub_panel.visible = false
	character_menu.visible = true
	_refresh_character_select_locks()
	_sync_menu_backdrop()

func _on_hub_main_menu() -> void:
	hub_panel.visible = false
	character_menu.visible = false
	main_menu.visible = true
	main_theme.stream = ZoneMusic.get_hub_music()
	main_theme.play()
	_sync_menu_backdrop()

func _on_return_to_sanctum_pressed() -> void:
	return_to_hub.emit(true)

func _setup_waystation_panel() -> void:
	waystation_panel = Panel.new()
	waystation_panel.name = "WaystationHub"
	waystation_panel.visible = false
	waystation_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.03, 0.06, 0.96)
	waystation_panel.add_theme_stylebox_override("panel", bg)
	add_child(waystation_panel)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 32)
	waystation_panel.add_child(margin)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(root)
	var title := Label.new()
	title.text = "Caravan Waystation"
	title.add_theme_font_size_override("font_size", 40)
	root.add_child(title)
	waystation_gold_label = Label.new()
	waystation_gold_label.add_theme_font_size_override("font_size", 20)
	root.add_child(waystation_gold_label)
	waystation_message = Label.new()
	waystation_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	waystation_message.modulate = Color(1.0, 0.8, 0.5)
	root.add_child(waystation_message)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)
	var grum_tab := VBoxContainer.new()
	grum_tab.name = "Grum stall"
	HubNpcUi.add_npc_header(
		grum_tab,
		"res://assets/monsters/unique/grum.png",
		"Grum - Traveling merchant",
		"Spend run gold on gear and potions."
	)
	HubNpcUi.add_potion_buy(grum_tab, true, waystation_message)
	HubNpcUi.add_equipment_shop(grum_tab, true, waystation_message, _rebuild_waystation_grum_commerce)
	tabs.add_child(grum_tab)
	var en_tab := VBoxContainer.new()
	en_tab.name = "Enchantress"
	HubNpcUi.add_npc_header(
		en_tab,
		"res://assets/monsters/unique/enchantress.png",
		"Enchantress - Camp instructor",
		"Train skills with gold found on this descent."
	)
	tabs.add_child(en_tab)
	tabs.set_tab_title(0, "Grum")
	tabs.set_tab_title(1, "Enchantress")
	var btn_row := HBoxContainer.new()
	root.add_child(btn_row)
	var campfire := Button.new()
	campfire.text = "Campfire (35 gold: rest, cleanse, stress, maybe purify one Stain)"
	campfire.pressed.connect(_on_waystation_campfire)
	btn_row.add_child(campfire)
	var rest_w := Button.new()
	rest_w.text = "Rest party"
	rest_w.pressed.connect(_on_waystation_rest)
	btn_row.add_child(rest_w)
	var cont := Button.new()
	cont.text = "Continue into the realms"
	cont.pressed.connect(_on_waystation_continue)
	btn_row.add_child(cont)
	var abandon := Button.new()
	abandon.text = "Return to Blood Sanctum"
	abandon.pressed.connect(_on_waystation_abandon)
	btn_row.add_child(abandon)

func _setup_shrine_panel() -> void:
	shrine_panel = Panel.new()
	shrine_panel.name = "ShrineOfChoice"
	shrine_panel.visible = false
	shrine_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.02, 0.08, 0.94)
	shrine_panel.add_theme_stylebox_override("panel", bg)
	add_child(shrine_panel)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 40)
	shrine_panel.add_child(margin)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(root)
	var title := Label.new()
	title.text = "Shrine of Choice"
	title.add_theme_font_size_override("font_size", 40)
	root.add_child(title)
	shrine_message = Label.new()
	shrine_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shrine_message.text = "Khorne offers a blessing. Choose one."
	root.add_child(shrine_message)
	shrine_option_box = VBoxContainer.new()
	shrine_option_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(shrine_option_box)

func _setup_map_toast() -> void:
	map_toast = Label.new()
	map_toast.name = "MapToast"
	map_toast.visible = false
	map_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	map_toast.offset_bottom = -48.0
	map_toast.offset_left = -400.0
	map_toast.offset_right = 400.0
	map_toast.add_theme_font_size_override("font_size", 22)
	map_toast.modulate = Color(1.0, 0.85, 0.55)
	add_child(map_toast)

func show_map_toast(message: String) -> void:
	if map_toast == null or message == "":
		return
	map_toast.text = message
	map_toast.visible = true
	var timer: SceneTreeTimer = get_tree().create_timer(4.5)
	timer.timeout.connect(func(): map_toast.visible = false)

func show_shrine(party: Array, campaign_complete: bool) -> void:
	characters = party
	_shrine_campaign_complete = campaign_complete
	hide_run_overlays()
	shrine_panel.visible = true
	shrine_message.text = "The altar offers three blessings for this run (pick one)."
	_populate_shrine_options()

func _populate_shrine_options() -> void:
	if shrine_option_box == null:
		return
	for child in shrine_option_box.get_children():
		shrine_option_box.remove_child(child)
		child.queue_free()
	for option_id in RunState.get_shrine_options():
		var btn := Button.new()
		btn.text = "%s - %s" % [ShrineChoices.get_title(option_id), ShrineChoices.get_description(option_id)]
		btn.pressed.connect(_on_shrine_option_pressed.bind(option_id))
		shrine_option_box.add_child(btn)

func _on_shrine_option_pressed(option_id: String) -> void:
	var result: String = ShrineChoices.apply(option_id, characters)
	shrine_message.text = result
	shrine_panel.visible = false
	show_zone_cleared(characters, _shrine_campaign_complete)

func show_waystation(party: Array) -> void:
	characters = party
	waystation_panel.visible = true
	_play_waystation_music()
	if MetaProgress.should_show_waystation_tip():
		waystation_message.text = WaystationUi.default_intro(true)
		MetaProgress.mark_tutorial_waystation_seen()
	else:
		waystation_message.text = WaystationUi.default_intro(false)
	_refresh_waystation_ui()
	_rebuild_waystation_grum_commerce()
	_rebuild_waystation_trainers(party)
	_rebuild_waystation_stash(party)

func _refresh_waystation_ui() -> void:
	if waystation_gold_label:
		waystation_gold_label.text = "Run gold: %d   |   Floors cleared: %d" % [
			RunState.run_gold,
			RunState.floors_cleared_this_run,
		]

func _rebuild_waystation_trainers_from_ui() -> void:
	_rebuild_waystation_trainers(characters)

func _rebuild_waystation_trainers(party: Array) -> void:
	var tabs := waystation_panel.get_node("MarginContainer/VBoxContainer/TabContainer") as TabContainer
	if tabs == null or tabs.get_tab_count() < 2:
		return
	var en_tab := tabs.get_tab_control(1) as VBoxContainer
	if en_tab == null:
		return
	for i in range(en_tab.get_child_count() - 1, 0, -1):
		var c = en_tab.get_child(i)
		if c is Button:
			en_tab.remove_child(c)
			c.queue_free()
	HubNpcUi.add_skill_trainer(en_tab, party, true, waystation_message, _rebuild_waystation_trainers_from_ui)

func _rebuild_waystation_stash(party: Array) -> void:
	var tabs := waystation_panel.get_node("MarginContainer/VBoxContainer/TabContainer") as TabContainer
	if tabs == null:
		return
	var grum_tab := tabs.get_tab_control(0) as VBoxContainer
	if grum_tab == null:
		return
	for child in grum_tab.get_children():
		if child is Button and str(child.text).begins_with("Give "):
			grum_tab.remove_child(child)
			child.queue_free()
	HubNpcUi.add_equip_stash(grum_tab, party, waystation_message)

func _rebuild_hub_grum_commerce() -> void:
	_clear_vbox_buttons(hub_tab_grum)
	HubNpcUi.add_potion_buy(hub_tab_grum, false, hub_message_label)
	HubNpcUi.add_equipment_shop(hub_tab_grum, false, hub_message_label, _rebuild_hub_grum_commerce)
	_rebuild_hub_trainers_and_stash()
	_refresh_hub_ui()

func _rebuild_waystation_grum_commerce() -> void:
	var tabs := waystation_panel.get_node("MarginContainer/VBoxContainer/TabContainer") as TabContainer
	if tabs == null:
		return
	var grum_tab := tabs.get_tab_control(0) as VBoxContainer
	if grum_tab == null:
		return
	_clear_vbox_buttons(grum_tab)
	HubNpcUi.add_potion_buy(grum_tab, true, waystation_message)
	HubNpcUi.add_equipment_shop(grum_tab, true, waystation_message, _rebuild_waystation_grum_commerce)
	_rebuild_waystation_stash(characters)

func _clear_vbox_buttons(tab: VBoxContainer) -> void:
	for i in range(tab.get_child_count() - 1, 0, -1):
		var c = tab.get_child(i)
		if c is Button:
			tab.remove_child(c)
			c.queue_free()

func _rebuild_hub_trainers_and_stash() -> void:
	var party: Array = _get_hub_party()
	while hub_tab_enchantress.get_child_count() > 1:
		var c = hub_tab_enchantress.get_child(1)
		hub_tab_enchantress.remove_child(c)
		c.queue_free()
	HubNpcUi.add_skill_trainer(hub_tab_enchantress, party, false, hub_message_label, _rebuild_hub_trainers_and_stash)
	HubNpcUi.add_trait_treatment(hub_tab_enchantress, party, hub_message_label, _rebuild_hub_trainers_and_stash)
	if hub_tabs.get_tab_count() >= 4:
		var equip_scroll := hub_tabs.get_tab_control(3) as ScrollContainer
		var equip_tab: VBoxContainer = null
		if equip_scroll != null and equip_scroll.get_child_count() > 0:
			equip_tab = equip_scroll.get_child(0) as VBoxContainer
		if equip_tab != null:
			for child in equip_tab.get_children():
				if child is Button:
					equip_tab.remove_child(child)
					child.queue_free()
			HubNpcUi.add_equip_stash(equip_tab, party, hub_message_label)

func _get_hub_party() -> Array:
	var world: Node = get_parent()
	if world != null and world.get("characters") != null:
		var party: Array = world.characters
		if party.size() > 0:
			return party
	return []

func _on_waystation_rest() -> void:
	HubCommerce.rest_party(characters)
	waystation_message.text = "The camp fires warm your bones. Party rested."

func _on_waystation_campfire() -> void:
	if HubCommerce.waystation_campfire(characters):
		waystation_message.text = "Campfire: party rested, statuses cleared, stress eased."
	else:
		waystation_message.text = "Need 35 run gold for the campfire."

func _on_waystation_continue() -> void:
	waystation_panel.visible = false
	continue_waystation.emit()

func _on_waystation_abandon() -> void:
	_request_voluntary_return()

func _setup_pause_ui() -> void:
	pause_backdrop = ColorRect.new()
	pause_backdrop.name = "PauseBackdrop"
	pause_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_backdrop.color = Color(0, 0, 0, 0.55)
	pause_backdrop.visible = false
	pause_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(pause_backdrop)
	pause_title = Label.new()
	pause_title.text = "Paused"
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.add_theme_font_size_override("font_size", 42)
	pause_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	pause_title.offset_top = 120
	pause_title.offset_left = -200
	pause_title.offset_right = 200
	pause_title.visible = false
	add_child(pause_title)
	resume_button = Button.new()
	resume_button.text = "Resume (Esc)"
	resume_button.pressed.connect(_on_resume_pressed)
	options_menu.add_child(resume_button)
	options_menu.move_child(resume_button, 0)
	settings_panel = Panel.new()
	settings_panel.name = "AudioSettingsPanel"
	settings_panel.visible = false
	settings_panel.offset_left = 680.0
	settings_panel.offset_top = 240.0
	settings_panel.offset_right = 1240.0
	settings_panel.offset_bottom = 580.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.08, 0.92)
	panel_style.border_color = Color("#FF8D4D")
	panel_style.set_border_width_all(2)
	panel_style.content_margin_left = 24
	panel_style.content_margin_top = 20
	panel_style.content_margin_right = 24
	panel_style.content_margin_bottom = 20
	settings_panel.add_theme_stylebox_override("panel", panel_style)
	game_menu.add_child(settings_panel)
	var settings_margin := MarginContainer.new()
	settings_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_margin.add_theme_constant_override("margin_left", 24)
	settings_margin.add_theme_constant_override("margin_top", 20)
	settings_margin.add_theme_constant_override("margin_right", 24)
	settings_margin.add_theme_constant_override("margin_bottom", 20)
	settings_panel.add_child(settings_margin)
	var settings_vbox := VBoxContainer.new()
	settings_vbox.add_theme_constant_override("separation", 14)
	settings_margin.add_child(settings_vbox)
	var title := Label.new()
	title.text = "Audio"
	title.add_theme_font_size_override("font_size", 28)
	settings_vbox.add_child(title)
	_add_volume_row(settings_vbox, "Master", Global.master_volume, Global.set_master_volume)
	_add_volume_row(settings_vbox, "Music", Global.music_volume, Global.set_music_volume)
	_add_volume_row(settings_vbox, "SFX", Global.sfx_volume, Global.set_sfx_volume)
	PauseSettingsUi.add_accessibility_section(settings_vbox)
	PauseSettingsUi.add_controls_section(settings_vbox)
	var debug_lbl := Label.new()
	debug_lbl.name = "PauseDebugMessage"
	settings_vbox.add_child(debug_lbl)
	PauseSettingsUi.add_debug_section(settings_vbox, debug_lbl)
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.pressed.connect(_on_settings_back_pressed)
	settings_vbox.add_child(back_btn)

	var abandon_btn := Button.new()
	abandon_btn.text = "Abandon run"
	abandon_btn.pressed.connect(_request_voluntary_return)
	options_menu.add_child(abandon_btn)
	var hint := Label.new()
	hint.text = "Esc: resume   |   Pause menu: inventory & exit"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 16)
	hint.modulate = Color(0.85, 0.85, 0.85)
	options_menu.add_child(hint)
	var credits_btn := Button.new()
	credits_btn.text = "Credits & music"
	credits_btn.pressed.connect(_on_credits_pressed)
	options_menu.add_child(credits_btn)

func _setup_party_hud() -> void:
	party_hud = Panel.new()
	party_hud.name = "PartyHud"
	party_hud.visible = false
	party_hud.offset_left = 28.0
	party_hud.offset_top = 118.0
	party_hud.offset_right = 400.0
	party_hud.offset_bottom = 250.0
	var hud_style := StyleBoxFlat.new()
	hud_style.bg_color = Color(0, 0, 0, 0.45)
	hud_style.content_margin_left = 10
	hud_style.content_margin_top = 8
	hud_style.content_margin_right = 10
	hud_style.content_margin_bottom = 8
	party_hud.add_theme_stylebox_override("panel", hud_style)
	add_child(party_hud)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	party_hud.add_child(vbox)
	for _i in 4:
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 16)
		vbox.add_child(lbl)
		party_hud_labels.append(lbl)

func update_party_hud(party: Array, show: bool) -> void:
	if party_hud == null:
		return
	party_hud.visible = show
	for i in party_hud_labels.size():
		if !show:
			continue
		if i < party.size() and party[i] is Character:
			var ch: Character = party[i]
			party_hud_labels[i].text = PartyHudUi.format_member_line(ch)
			party_hud_labels[i].tooltip_text = PartyHudUi.tooltip_for_member(ch)
			party_hud_labels[i].add_theme_font_size_override("font_size", Global.get_ui_font_size(16))
			party_hud_labels[i].modulate = Color.WHITE if ch.current_hp > 0 else Color(0.55, 0.55, 0.55)
		else:
			party_hud_labels[i].text = ""

func _setup_credits_panel() -> void:
	credits_panel = Panel.new()
	credits_panel.name = "CreditsPanel"
	credits_panel.visible = false
	credits_panel.set_anchors_preset(Control.PRESET_CENTER)
	credits_panel.offset_left = -420.0
	credits_panel.offset_top = -280.0
	credits_panel.offset_right = 420.0
	credits_panel.offset_bottom = 280.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.05, 0.08, 0.96)
	panel_style.border_color = Color("#FF8D4D")
	panel_style.set_border_width_all(2)
	panel_style.content_margin_left = 24
	panel_style.content_margin_top = 20
	panel_style.content_margin_right = 24
	panel_style.content_margin_bottom = 20
	credits_panel.add_theme_stylebox_override("panel", panel_style)
	game_menu.add_child(credits_panel)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_bottom = -48.0
	credits_panel.add_child(scroll)
	var body := RichTextLabel.new()
	body.bbcode_enabled = false
	body.fit_content = true
	body.scroll_active = false
	body.custom_minimum_size = Vector2(760, 0)
	body.text = _credits_text()
	scroll.add_child(body)
	var close := Button.new()
	close.text = "Back"
	close.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	close.offset_top = -40.0
	close.pressed.connect(_on_credits_back_pressed)
	credits_panel.add_child(close)

func _credits_text() -> String:
	return (
		"Skull Throne - third-party assets\n\n"
		+ "Music (OpenGameArt.org):\n"
		+ "Miguel Herrero, pheonton, remaxim, Telaron, Marcus Rasseli, Baŝto.\n"
		+ "Overworld track names appear on the floor title during a run.\n\n"
		+ "Sprites: LPC contributors, Chris Hamons (Dungeon Crawl), and others listed in README.md.\n\n"
		+ "Full links and licenses: docs/third-party-licenses.md and repository Acknowledgements.\n"
		+ "Game original work: CC BY-NC-ND 4.0."
	)

func _on_credits_pressed() -> void:
	options_menu.visible = false
	credits_panel.visible = true

func _on_credits_back_pressed() -> void:
	credits_panel.visible = false
	options_menu.visible = true

func _add_volume_row(parent: VBoxContainer, label_text: String, initial: float, apply_callable: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 88
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.custom_minimum_size.y = 28.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value = initial
	slider.value_changed.connect(func(v: float): apply_callable.call(v))
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 52
	value_label.text = "%d%%" % int(initial * 100.0)
	slider.value_changed.connect(func(v: float): value_label.text = "%d%%" % int(v * 100.0))
	row.add_child(value_label)

func _on_resume_pressed() -> void:
	if credits_panel != null and credits_panel.visible:
		_on_credits_back_pressed()
		return
	if settings_open:
		_on_settings_back_pressed()
		return
	get_parent().resume_paused_game()

func _on_audio_settings_pressed() -> void:
	settings_open = true
	settings_panel.visible = true
	options_menu.visible = false

func _on_settings_back_pressed() -> void:
	settings_open = false
	settings_panel.visible = false
	if game_menu.visible:
		options_menu.visible = true

func _setup_main_menu_options() -> void:
	var options_btn := Button.new()
	options_btn.name = "Options"
	options_btn.text = "Options"
	options_btn.offset_left = 873.0
	options_btn.offset_top = 600.0
	options_btn.offset_right = 993.0
	options_btn.offset_bottom = 654.0
	options_btn.pressed.connect(_on_main_menu_options_pressed)
	main_menu.add_child(options_btn)
	main_menu_settings_panel = Panel.new()
	main_menu_settings_panel.name = "MainMenuAudioPanel"
	main_menu_settings_panel.visible = false
	main_menu_settings_panel.offset_left = 560.0
	main_menu_settings_panel.offset_top = 280.0
	main_menu_settings_panel.offset_right = 1300.0
	main_menu_settings_panel.offset_bottom = 560.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.08, 0.92)
	panel_style.border_color = Color("#FF8D4D")
	panel_style.set_border_width_all(2)
	panel_style.content_margin_left = 24
	panel_style.content_margin_top = 20
	panel_style.content_margin_right = 24
	panel_style.content_margin_bottom = 20
	main_menu_settings_panel.add_theme_stylebox_override("panel", panel_style)
	main_menu.add_child(main_menu_settings_panel)
	var mm_margin := MarginContainer.new()
	mm_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	mm_margin.add_theme_constant_override("margin_left", 28)
	mm_margin.add_theme_constant_override("margin_top", 24)
	mm_margin.add_theme_constant_override("margin_right", 28)
	mm_margin.add_theme_constant_override("margin_bottom", 24)
	main_menu_settings_panel.add_child(mm_margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	mm_margin.add_child(vbox)
	var title := Label.new()
	title.text = "Sound & music"
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)
	_add_volume_row(vbox, "Master", Global.master_volume, Global.set_master_volume)
	_add_volume_row(vbox, "Music", Global.music_volume, Global.set_music_volume)
	_add_volume_row(vbox, "SFX", Global.sfx_volume, Global.set_sfx_volume)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(_on_main_menu_settings_back)
	vbox.add_child(back)

func _on_main_menu_options_pressed() -> void:
	main_menu_settings_open = true
	main_menu_settings_panel.visible = true

func _on_main_menu_settings_back() -> void:
	main_menu_settings_open = false
	main_menu_settings_panel.visible = false

func _on_play_pressed():
	main_menu.visible = false
	character_menu.visible = true
	_refresh_character_select_locks()
	_sync_menu_backdrop()

func _on_world_map_generated():
	main_theme.stop()
	character_menu.visible = false
	hub_panel.visible = false
	waystation_panel.visible = false
	if zone_title_label:
		zone_title_label.visible = false
	if journey_button:
		journey_button.visible = true

func set_zone_title(title: String) -> void:
	if zone_title_label:
		zone_title_label.visible = false
	var index: int = RunState.get_current_floor_number()
	var total: int = RunState.get_run_floor_count()
	if journey_button:
		journey_button.visible = RunState.campaign_active
		journey_button.text = "Floor %d/%d" % [index, total]
		journey_button.tooltip_text = title
	_refresh_journey_list()

func show_zone_cleared(remaining_characters: Array, campaign_complete: bool) -> void:
	var character_names: PackedStringArray = []
	for character in remaining_characters:
		character_names.append(character.name)
	var zone: ZoneDefinition = RunState.get_current_zone()
	var zone_name: String = zone.display_name if zone != null else "the realm"
	if end_title_label:
		if campaign_complete:
			end_title_label.text = "Victory"
		else:
			end_title_label.text = "Floor cleared"
	end_message.text = "You cleared %s with: %s." % [zone_name, ", ".join(character_names)]
	if campaign_complete:
		end_message.text += " Khorne falls. The Skull Throne is yours."
		continue_button.visible = false
		sanctum_button.visible = true
	else:
		end_message.text += " Press Continue for the next floor."
		continue_button.visible = true
		sanctum_button.visible = false
	end_game_menu.visible = true
	game_won_music.stream = ZoneMusic.get_victory_music(campaign_complete)
	game_won_music.play()
	if level_ended_retry:
		level_ended_retry.visible = false

func _on_continue_adventure_pressed() -> void:
	end_game_menu.visible = false
	game_won_music.stop()
	continue_adventure.emit()

func _on_start_run_pressed():
	if character_ids_toggled.size() > 0:
		error_message.visible = false
		character_menu.visible = false
		show_hub()
		_rebuild_hub_trainers_and_stash()
		_sync_menu_backdrop()
	else:
		error_message.visible = true

func _on_world_paused_game(is_paused, characters_in_party: Array = []):
	game_menu.visible = is_paused
	options_menu.visible = is_paused and not settings_open and (credits_panel == null or !credits_panel.visible)
	item_grid_panel.visible = false
	character_grid_panel.visible = false
	characters = characters_in_party
	if pause_backdrop:
		pause_backdrop.visible = is_paused
	if pause_title:
		pause_title.visible = is_paused
	if is_paused and not settings_open:
		settings_panel.visible = false
		if credits_panel:
			credits_panel.visible = false

func _play_waystation_music() -> void:
	var world: Node = get_parent()
	if world == null or !world.has_node("Map Theme"):
		return
	var player: AudioStreamPlayer = world.get_node("Map Theme")
	player.stream = ZoneMusic.get_overworld_music_for_theme("throne_approach")
	player.play()


func _on_game_over_return_pressed():
	game_over_menu.visible = false
	end_game_menu.visible = false
	continue_button.visible = false
	sanctum_button.visible = false
	game_won_music.stop()
	game_over_music.stop()
	return_to_hub.emit(false)

func _setup_menu_backdrop() -> void:
	_menu_backdrop = ColorRect.new()
	_menu_backdrop.name = "MenuBackdrop"
	_menu_backdrop.color = Color(0.06, 0.04, 0.05, 1.0)
	_menu_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_menu_backdrop)
	move_child(_menu_backdrop, 0)
	_sync_menu_backdrop()

func _sync_menu_backdrop() -> void:
	if _menu_backdrop == null:
		return
	_menu_backdrop.visible = main_menu.visible or character_menu.visible or (hub_panel != null and hub_panel.visible)

func _setup_character_select_buttons() -> void:
	const VIEWPORT_W := 1920.0
	const ROW_W := 580.0
	var intro: RichTextLabel = character_menu.get_node("RichTextLabel")
	intro.set_anchors_preset(Control.PRESET_TOP_LEFT)
	intro.offset_left = (VIEWPORT_W - 900.0) * 0.5
	intro.offset_top = 186.0
	intro.offset_right = intro.offset_left + 900.0
	intro.offset_bottom = 340.0
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(900, 0)
	intro.scroll_active = false
	intro.fit_content = true
	var row: HBoxContainer = character_menu.get_node("CharacterSelection/HBoxContainer")
	row.set_anchors_preset(Control.PRESET_TOP_LEFT)
	row.offset_left = (VIEWPORT_W - ROW_W) * 0.5
	row.offset_top = 390.0
	row.offset_right = row.offset_left + ROW_W
	row.offset_bottom = 490.0
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	var button_paths := [
		"Character-menu/CharacterSelection/HBoxContainer/TinyBones",
		"Character-menu/CharacterSelection/HBoxContainer/Beth",
		"Character-menu/CharacterSelection/HBoxContainer/Dalf",
		"Character-menu/CharacterSelection/HBoxContainer/Trece",
	]
	for path in button_paths:
		var button: TextureButton = get_node(path)
		button.custom_minimum_size = Vector2(88, 88)
		button.ignore_texture_size = true
		for child in button.get_children():
			if child is Control:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _refresh_character_select_locks() -> void:
	var button_paths := [
		"Character-menu/CharacterSelection/HBoxContainer/TinyBones",
		"Character-menu/CharacterSelection/HBoxContainer/Beth",
		"Character-menu/CharacterSelection/HBoxContainer/Dalf",
		"Character-menu/CharacterSelection/HBoxContainer/Trece",
	]
	for i in button_paths.size():
		var button: TextureButton = get_node(button_paths[i])
		var definition: CharacterDefinition = ContentRegistry.get_character_for_menu_index(i)
		var unlocked: bool = definition == null or RunState.is_character_unlocked(definition)
		button.disabled = !unlocked
		button.modulate = Color.WHITE if unlocked else Color(0.45, 0.45, 0.45, 1.0)
		if definition != null and !unlocked:
			var need: int = definition.unlock_after_zones_cleared
			var have: int = MetaProgress.get_lifetime_floors_cleared()
			button.tooltip_text = "Unlock after %d lifetime floor clears (%d/%d)." % [need, have, need]
		else:
			button.tooltip_text = definition.display_name if definition != null else ""

func character_toggle(toggled_on, id):
	var definition: CharacterDefinition = ContentRegistry.get_character_for_menu_index(id)
	if definition != null and !RunState.is_character_unlocked(definition):
		return
	if toggled_on:
		character_ids_toggled.append(id)
		character_added.emit(id)
	else:
		character_ids_toggled.erase(id)
		character_removed.emit(id)
	if hub_panel != null and hub_panel.visible:
		_refresh_hub_ui()

func _on_player_0_select_toggled(toggled_on):
	character_toggle(toggled_on, 0)

func _on_player_1_select_toggled(toggled_on):
	character_toggle(toggled_on, 1)

func _on_player_2_select_toggled(toggled_on):
	character_toggle(toggled_on, 2)

func _on_player_3_select_toggled(toggled_on):
	character_toggle(toggled_on, 3)

func _on_battle_game_over(dead_players):
	var message: String = GAME_OVER_DEATHS_TEMPLATE
	if dead_players > 1:
		message = message.replace("{COUNT}", str(dead_players))
	else:
		message = message.replace("{COUNT} skulls", str(dead_players) + " skull")
	if Global.get_skull_count() > 1:
		message = message.replace("{TOTAL_COUNT}", str(Global.get_skull_count()))
	else:
		message = message.replace("{TOTAL_COUNT} skulls", str(Global.get_skull_count()) + " skull")
	message += "\nSkulls on the throne: %d" % Global.get_skull_count()
	message += "\nDefeat does not apply retreat Stains; only abandoning the run can."
	death_count_message.text = message
	game_over_menu.visible = true
	game_over_music.play()
	if game_over_retry:
		game_over_retry.text = "Return to Blood Sanctum"
		game_over_retry.visible = true

func _on_battle_level_ended(_remaining_characters):
	pass

func _on_inventory_pressed():
	clear_item_grid()
	if in_battle:
		game_menu.visible = true
	if !item_grid_panel.visible:
		display_grid_items()
	else:
		item_grid_panel.visible = false

func _on_item_pressed(item):
	clear_character_grid()
	display_grid_characters(item)

func _on_character_pressed(item, character):
	character_grid_panel.visible = false
	if item.type == "healing":
		character.apply_healing(item.healing_amount)
	elif item.type == "weapon":
		character.attack += item.attack_amount
	clear_character_grid()
	Inventory.remove_item(item)
	if Inventory.get_item_count(item) == 0:
		clear_item_grid()
		display_grid_items()
	if in_battle:
		get_parent().resume_paused_game()

func _on_exit_pressed():
	exit_dialog.visible = true


func _on_confirmation_dialog_confirmed():
	get_tree().quit()

func clear_item_grid():
	for child in item_grid.get_children():
		item_grid.remove_child(child)
		child.queue_free()

func clear_character_grid():
	for child in character_grid.get_children():
		if !(child is Label):
			character_grid.remove_child(child)
			child.queue_free()
		

func display_grid_items():
	for item in Inventory.items.keys():
		if (item.usable_outside_battle and !in_battle) or in_battle:
			var icon = item.icon.texture
			var item_button = Button.new()
			var style_box = StyleBoxFlat.new()
			style_box.bg_color = Color.html("#FF8D4D")
			item_button.add_theme_stylebox_override("normal", style_box)
			item_button.icon = icon
			item_button.text = "x"+str(Inventory.get_item_count(item))
			item_button.pressed.connect(_on_item_pressed.bind(item))
			item_grid.add_child(item_button)
	if item_grid.get_child_count() > 0:
		item_grid_panel.visible = true
	else:
		item_grid_panel.visible = false
		
func display_grid_characters(item):
	for character in characters:
		var character_button = Button.new()
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color.html("#FF8D4D")
		character_button.text = character.name
		character_button.add_theme_stylebox_override("normal", style_box)
		character_button.pressed.connect(_on_character_pressed.bind(item, character))
		character_grid.add_child(character_button)
	if character_grid.get_child_count() > 0:
		character_grid_panel.visible = true
	else:
		character_grid_panel.visible = false
