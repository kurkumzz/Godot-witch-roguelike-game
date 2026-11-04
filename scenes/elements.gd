class_name Element
extends RefCounted
## Список стихий и их цвета. Используется везде: Element.Type.WATER

enum Type { NONE, FIRE, WATER, ICE, EARTH, AIR, ELECTRIC }

# Цвет снаряда для каждой стихии
const COLORS := {
	Type.NONE: Color.WHITE,
	Type.FIRE: Color(1.0, 0.45, 0.2),
	Type.WATER: Color(0.3, 0.6, 1.0),
	Type.ICE: Color(0.7, 0.95, 1.0),
	Type.EARTH: Color(0.6, 0.45, 0.3),
	Type.AIR: Color(0.85, 1.0, 0.9),
	Type.ELECTRIC: Color(1.0, 0.95, 0.3),
}
