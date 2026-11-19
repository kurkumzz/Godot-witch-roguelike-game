extends RefCounted
## Каталог страниц. Вес относится ко всей редкости, а не к отдельной карте.

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
const WEIGHTS := [64, 24, 8, 4]
const COMMON_PERCENT := 10
const EPIC_PERCENT := 40
const STAT_NAMES := {
	&"damage": "Урон", &"range": "Дальность", &"health": "Здоровье",
	&"speed": "Скорость бега", &"fire_rate": "Скорострельность", &"luck": "Удача",
}
const ELEMENTS := {
	&"water": Element.Type.WATER, &"fire": Element.Type.FIRE,
	&"ice": Element.Type.ICE, &"electric": Element.Type.ELECTRIC,
}
const PASSIVES := {
	&"jump": "Двойной прыжок",
	&"double_dash": "Двойной рывок",
	&"dash_invulnerable": "Неуязвимость в рывке",
	&"low_health_shield": "Щит при здоровье ниже 25%",
}


static func rarity(id: StringName) -> Rarity:
	if ELEMENTS.has(id):
		return Rarity.RARE
	if PASSIVES.has(id):
		return Rarity.LEGENDARY
	if id.ends_with("_epic"):
		return Rarity.EPIC
	return Rarity.COMMON


static func stat_id(id: StringName) -> StringName:
	return StringName(id.trim_suffix("_epic"))


static func percent(id: StringName) -> int:
	return EPIC_PERCENT if rarity(id) == Rarity.EPIC else COMMON_PERCENT


static func title(id: StringName, slots: Array[Element.Type], active_slot: int) -> String:
	if ELEMENTS.has(id):
		var name: String = Element.DISPLAY_NAMES[ELEMENTS[id]]
		if slots.size() == 2:
			return "%s → %s" % [Element.DISPLAY_NAMES[slots[active_slot]], name]
		return name
	if PASSIVES.has(id):
		return PASSIVES[id]
	return "%s +%d%%" % [STAT_NAMES[stat_id(id)], percent(id)]


static func deal(rng: RandomNumberGenerator, slots: Array[Element.Type], passives: Array[StringName], opening: bool, luck_percent := 0) -> Array[StringName]:
	var pools: Array[Array] = [[], [], [], []]
	for id: StringName in ELEMENTS:
		if not slots.has(ELEMENTS[id]):
			pools[Rarity.RARE].append(id)
	if not opening:
		for id: StringName in STAT_NAMES:
			pools[Rarity.COMMON].append(id)
			pools[Rarity.EPIC].append(StringName(id + "_epic"))
		for id: StringName in PASSIVES:
			if not passives.has(id):
				pools[Rarity.LEGENDARY].append(id)

	var choices: Array[StringName] = []
	var count := 2 if opening else 3
	var base_weights := PackedFloat32Array(WEIGHTS)
	for tier in range(Rarity.RARE, base_weights.size()):
		base_weights[tier] *= 1.0 + luck_percent / 100.0
	for i in count:
		var weights := base_weights.duplicate()
		for tier in pools.size():
			if pools[tier].is_empty():
				weights[tier] = 0
		var tier := rng.rand_weighted(weights)
		var pool := pools[tier]
		var id: StringName = pool.pop_at(rng.randi_range(0, pool.size() - 1))
		choices.append(id)
		# Не предлагать +10% и +40% к одной характеристике на одном экране.
		if tier == Rarity.COMMON:
			pools[Rarity.EPIC].erase(StringName(id + "_epic"))
		elif tier == Rarity.EPIC:
			pools[Rarity.COMMON].erase(stat_id(id))
	return choices
