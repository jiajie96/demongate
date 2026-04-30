extends Node

signal language_changed

var current_lang: String = "en"

# ═══════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════
func t(key: String) -> String:
	if current_lang == "zh" and _zh.has(key):
		return _zh[key]
	return key

func tf(key: String, args: Dictionary = {}) -> String:
	var template: String
	if _templates.has(key):
		template = _templates[key].get(current_lang, _templates[key].get("en", key))
	else:
		template = key
	for k in args:
		template = template.replace("{" + k + "}", str(args[k]))
	return template

func toggle_language() -> void:
	current_lang = "zh" if current_lang == "en" else "en"
	language_changed.emit()

func lang_display() -> String:
	return "中文" if current_lang == "zh" else "English"

# ═══════════════════════════════════════════════════════
# TEMPLATE STRINGS (keyed by identifier)
# ═══════════════════════════════════════════════════════
var _templates: Dictionary = {
	"hells_core": {
		"en": "Hell's Core: {hp} / {max}",
		"zh": "地狱核心: {hp} / {max}",
	},
	"wave_progress": {
		"en": "Wave {wave} / {max}",
		"zh": "第 {wave} / {max} 波",
	},
	"enemies_count": {
		"en": "Enemies: {count}",
		"zh": "敌人: {count}",
	},
	"dice_count": {
		"en": "Dice: {count} [D]",
		"zh": "骰子: {count} [D]",
	},
	"sins_display": {
		"en": "SINS: {amount}",
		"zh": "罪孽: {amount}",
	},
	"next_wave_timer": {
		"en": "Next wave in {time}s... (Space to skip)",
		"zh": "下一波 {time}秒后到来...(空格跳过)",
	},
	"tower_level": {
		"en": "{name} (Lv.{level})",
		"zh": "{name} (等级{level})",
	},
	"tower_stats": {
		"en": "DMG: {dmg} | RNG: {rng} | SPD: {spd}/s\nDPS: {dps}",
		"zh": "攻击: {dmg} | 射程: {rng} | 速度: {spd}/s\nDPS: {dps}",
	},
	"upgrade_cost": {
		"en": "Upgrade ({cost})",
		"zh": "升级 ({cost})",
	},
	"sell_refund": {
		"en": "Sell (+{cost})",
		"zh": "出售 (+{cost})",
	},
	"hero_pool": {
		"en": "Fallen Hero Pool: {pool} / {threshold}",
		"zh": "堕落英雄池: {pool} / {threshold}",
	},
	"cost_format": {
		"en": "{cost} Sins",
		"zh": "{cost} 罪孽",
	},
	"gameover_stats": {
		"en": "Wave: {wave} | Kills: {kills} | Towers: {towers}",
		"zh": "波次: {wave} | 击杀: {kills} | 塔: {towers}",
	},
	"victory_stats": {
		"en": "Kills: {kills} | Towers: {towers}",
		"zh": "击杀: {kills} | 塔: {towers}",
	},
	"tower_button": {
		"en": "{name} [{symbol}]\n{desc}\n{cost}",
		"zh": "{name} [{symbol}]\n{desc}\n{cost}",
	},
	"tower_button_compact": {
		"en": "{name}\n{cost}",
		"zh": "{name}\n{cost}",
	},
	# Notification templates
	"wave_start_notify": {
		"en": "Wave {wave}: {desc}",
		"zh": "第{wave}波: {desc}",
	},
	"wave_complete_notify": {
		"en": "Wave {wave} complete! +{bonus} Sins",
		"zh": "第{wave}波完成！+{bonus} 罪孽",
	},
	"tower_upgraded": {
		"en": "{name} upgraded to Lv.{level}",
		"zh": "{name} 升级到等级{level}",
	},
	"sold_tower": {
		"en": "Sold {name}",
		"zh": "出售了 {name}",
	},
	"relic_drop": {
		"en": "Relic: {name}",
		"zh": "遗物: {name}",
	},
	"sins_gained": {
		"en": "+{amount} Sins",
		"zh": "+{amount} 罪孽",
	},
	"tower_buff": {
		"en": "{name} +25% damage!",
		"zh": "{name} 伤害+25%！",
	},
	"tower_cursed": {
		"en": "{name} cursed!",
		"zh": "{name} 被诅咒了！",
	},
	# Dice templates
	"dice_title": {
		"en": "DEVIL'S DICE ({count})",
		"zh": "恶魔骰子 ({count})",
	},
	"dice_replenish": {
		"en": "Dice restored! ({count}/{max})",
		"zh": "骰子恢复！({count}/{max})",
	},
	"overview_kills": {
		"en": "{count} kills",
		"zh": "{count} 击杀",
	},
	"free_tower_notify": {
		"en": "Free tower! ({count} left)",
		"zh": "免费建塔！(剩余{count})",
	},
	"legendary_upgrade": {
		"en": "Legendary! {name} upgraded to Lv.{level}!",
		"zh": "传说！{name} 升级到等级{level}！",
	},
}

# ═══════════════════════════════════════════════════════
# DIRECT TRANSLATIONS (English key → Chinese value)
# ═══════════════════════════════════════════════════════
var _zh: Dictionary = {
	# --- Menu / Overlays ---
	"HELLGATE DEFENDERS": "地狱门守卫者",
	"Defend Hell's Core against\nthe Divine Army!": "保卫地狱核心\n抵御神圣大军！",
	"BEGIN THE DEFENSE": "开始防御",
	"HELL HAS FALLEN": "地狱已陷落",
	"TRY AGAIN": "再试一次",
	"HELL ENDURES!": "地狱永存！",
	"PLAY AGAIN": "再来一局",
	# --- HUD labels ---
	"TOWERS": "塔防",
	"SEND NEXT WAVE": "发送下一波",
	"MAX LEVEL": "最高等级",
	"4-9: Towers | U: Upgrade | X: Sell | T: Target | P: Pause\nSpace: Skip | Tab: Overview | D: Dice | Esc: Cancel": "4-9：选塔 | U：升级 | X：出售 | T：目标 | P：暂停\n空格：跳过 | Tab：总览 | D：骰子 | Esc：取消",

	# --- Dice UI ---
	"DEVIL'S DICE": "恶魔骰子",
	"Roll during battle! High = blessing, low = curse.": "战斗中投掷！点数高=祝福，点数低=诅咒。",
	"ROLL THE DICE": "投掷骰子",
	"Only during waves": "仅限战斗中",
	"No dice left": "没有骰子了",

	# --- Dice effect descriptions ---
	"All towers +80% attack speed for 15s!": "所有塔攻速+80%，持续15秒！",
	"25% damage to all enemies!": "对所有敌人造成25%伤害！",
	"10% damage to all enemies!": "对所有敌人造成10%伤害！",
	"All towers +30% attack speed for 10s!": "所有塔攻速+30%，持续10秒！",
	"Gained 25 bonus Sins!": "获得25额外罪孽！",
	"Gained 10 bonus Sins!": "获得10额外罪孽！",
	"Gained 50 bonus Sins!": "获得50额外罪孽！",
	"All towers -25% speed for 10s": "所有塔速度-25%，持续10秒",
	"All towers disabled for 3 seconds": "所有塔禁用3秒",
	"Lost 10% of current Sins": "失去当前10%的罪孽",

	# --- Dice outcome names (new) ---
	"Quick Hands": "快手",
	"Small Spark": "小火花",
	"Minor Blessing": "小祝福",
	"Slow Curse": "减速诅咒",
	"Tremor": "微震",
	"Devil's Tax": "恶魔税",
	# --- Settings popup ---
	"SETTINGS": "设置",
	"Pause": "暂停",
	"Resume": "继续",
	"Restart": "重新开始",
	"Language": "语言",
	"Close": "关闭",
	"Master": "主音量",
	"Music": "音乐",
	"SFX": "音效",

	# --- Game world labels ---
	"SPAWN": "出生点",
	"HELL'S CORE": "地狱核心",
	"SHIELD END": "护盾边界",

	# --- Tower names ---
	"Bone Marksman": "骨弓手",
	"Inferno Warlock": "炼狱术士",
	"Soul Reaper": "灵魂收割者",
	"Lucifer": "路西法",
	"Hades": "哈迪斯",
	"Cocytus": "科赛特斯",

	# --- Tower descriptions ---
	"Fast attacks, reliable early damage": "快速攻击，可靠的前期伤害",
	"AoE blasts, essential vs swarms": "范围爆炸，对付群敌必备",
	"Slows enemies on hit, force multiplier": "命中减速，战力倍增",
	"Global pulse damages ALL enemies, slow attack": "全局脉冲伤害所有敌人，攻速慢",
	"Buffs nearby tower attack speed periodically": "定期提升范围内塔的攻速",
	"Ice spike ramps damage on same target": "冰锥射击，对同一目标伤害递增",

	# --- Enemy names ---
	"Seraph Scout": "炽天斥候",
	"Crusader": "十字军",
	"Swift Ranger": "迅捷游侠",
	"War Titan": "战争巨人",
	"Grand Paladin": "大圣武士",
	"Temple Cleric": "神殿牧师",
	"Archangel Marshal": "大天使元帅",
	"Holy Sentinel": "神圣哨兵",
	"Archangel Michael": "大天使米迦勒",
	"Zeus": "宙斯",
	"Archangel Raphael": "大天使拉斐尔",

	# --- Wave descriptions ---
	"The first scouts arrive": "第一批斥候来了",
	"The crusade begins": "十字军出征",
	"Knights join the crusade": "骑士加入战场",
	"Hunters arrive - fast and deadly": "猎手来了——快速致命",
	"Healers bolster the ranks": "治疗者增援到来",
	"The Archangel takes command!": "大天使降临指挥！",
	"The Gods of War descend": "战神降临",
	"Heavy assault under command": "指挥下的猛攻",
	"Twin commanders rally the host": "双指挥官集结大军",
	"BOSS: Raphael heals the Paladin!": "首领：拉斐尔治愈圣武士！",
	"The Guardian's shield descends!": "守卫之盾降临！",
	"Zeus strikes from the storm!": "宙斯从风暴中降临！",
	"Shielded heavy hitters with lightning": "有护盾的重击者与闪电",
	"Armored column, double guarded": "重甲纵队，双重守卫",
	"BOSS: Michael descends with divine shield!": "首领：米迦勒携神盾降临！",
	"The flood, lightning and command": "洪潮，闪电与指挥",
	"Elite forces with Zeus support": "精锐部队与宙斯支援",
	"Full combined arms": "全兵种联合",
	"The final onslaught — Michael leads": "最终猛攻——米迦勒领军",
	"BOSS: Heaven's last stand — all heroes": "首领：天堂的最后一战——全英雄出击",
	"Michael's divine shield protects all!": "米迦勒的神盾保护了所有人！",

	# --- Dice outcomes ---
	"Tithe": "献金",
	"Demonic Surge": "恶魔涌潮",
	"Hellstorm": "地狱风暴",
	"Backfire": "反噬",
	"Earthquake": "地震",
	"DEVIL'S BETRAYAL": "恶魔背叛",

	# --- Relic names ---
	"Hellfire Bomb": "地狱火弹",
	"Sin Cache": "罪孽宝箱",
	"Tower Blessing": "塔防祝福",
	"Corruption Wave": "腐化之波",
	"Time Warp": "时间扭曲",
	"Legendary Blueprint": "传说蓝图",
	"Divine Curse": "神圣诅咒",
	"Trojan Relic": "特洛伊遗物",
	"Pandora's True Gift": "潘多拉的真礼物",

	# --- Relic effect messages ---
	"Corruption Wave! All enemies slowed!": "腐化之波！所有敌人被减速！",
	"Time Warp! Enemies crawl for 5 seconds!": "时间扭曲！敌人缓行5秒！",
	"Time Warp faded": "时间扭曲消退",
	"All towers maxed! +80 Sins instead": "所有塔已满级！替换为+80罪孽",
	"Pandora grants 2x damage for 1 wave!": "潘多拉赐予1波2倍伤害！",
	"Pandora grants 100 Sins!": "潘多拉赐予100罪孽！",
	"PANDORA'S TRUE GIFT": "潘多拉的真礼物",
	"Choose your reward wisely.": "明智地选择你的奖励。",
	"2x Damage (1 wave)": "2倍伤害（1波）",
	"+100 Sins": "+100 罪孽",
	"Next:": "下一波：",

	# --- Notification messages ---
	"A Fallen Hero has joined your cause!": "一位堕落英雄加入了你的阵营！",
	"Prepare your defenses!": "准备你的防御！",
	"Trojan Relic! Elite enemies spawned!": "特洛伊遗物！精锐敌人出现！",
	"Only one Lucifer allowed!": "只能拥有一个路西法！",
	"Not enough sins!": "罪孽不足！",

	# --- HUD buttons ---
	"Upgrade": "升级",
	"Sell": "出售",
	"Target": "目标",

	# --- Overview labels ---
	"GLOBAL": "全局",
	"SUPPORT": "辅助",
}
