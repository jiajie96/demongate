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
	"pact_accepted_notify": {
		"en": "Pact accepted: {name}",
		"zh": "已接受契约: {name}",
	},
	"pact_button": {
		"en": "{name}\n+ {benefit}\n- {cost_desc}",
		"zh": "{name}\n+ {benefit}\n- {cost_desc}",
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
	"DEMONIC PACT": "恶魔契约",
	"Choose a pact — great power at great cost.": "选择一个契约 - 强大力量，沉重代价。",
	"No Deal": "拒绝交易",

	# --- HUD labels ---
	"TOWERS": "塔防",
	"SEND NEXT WAVE": "发送下一波",
	"MAX LEVEL": "最高等级",
	"Right-click: Deselect | Tab: Overview\nSpace: Skip Timer | Esc: Cancel": "右键：取消选择 | Tab：总览\n空格：跳过等待 | Esc：取消",

	# --- Dice UI ---
	"DEVIL'S DICE": "恶魔骰子",
	"Roll during battle! High = blessing, low = curse.": "战斗中投掷！点数高=祝福，点数低=诅咒。",
	"ROLL THE DICE": "投掷骰子",
	"Only during waves": "仅限战斗中",
	"No dice left": "没有骰子了",

	# --- Dice effect descriptions ---
	"All enemies instantly destroyed!": "所有敌人瞬间毁灭！",
	"All towers 3x attack speed for 20s!": "所有塔攻速3倍，持续20秒！",
	"30% damage to all enemies!": "对所有敌人造成30%伤害！",
	"15% damage to all enemies!": "对所有敌人造成15%伤害！",
	"All towers +50% attack speed for 10s!": "所有塔攻速+50%，持续10秒！",
	"Gained 30 bonus Sins!": "获得30额外罪孽！",
	"All towers -30% speed for 10s": "所有塔速度-30%，持续10秒",
	"All towers disabled for 3 seconds": "所有塔禁用3秒",
	"Lost 15% of current Sins": "失去当前15%的罪孽",

	# --- Dice outcome names (new) ---
	"Quick Hands": "快手",
	"Small Spark": "小火花",
	"Minor Blessing": "小祝福",
	"Slow Curse": "减速诅咒",
	"Tremor": "微震",
	"Devil's Tax": "恶魔税",
	"Demonic Pact offered!": "恶魔契约来了！",

	# --- Settings popup ---
	"SETTINGS": "设置",
	"Pause": "暂停",
	"Resume": "继续",
	"Restart": "重新开始",
	"Language": "语言",
	"Close": "关闭",

	# --- Game world labels ---
	"SPAWN": "出生点",
	"HELL'S CORE": "地狱核心",
	"SHIELD END": "护盾边界",

	# --- Tower names ---
	"Demon Archer": "恶魔弓手",
	"Hellfire Mage": "地狱火法师",
	"Necromancer": "死灵法师",
	"Lucifer": "路西法",
	"Hades": "哈迪斯",

	# --- Tower descriptions ---
	"Fast attacks, reliable early damage": "快速攻击，可靠的前期伤害",
	"AoE blasts, essential vs swarms": "范围爆炸，对付群敌必备",
	"Slows enemies on hit, force multiplier": "命中减速，战力倍增",
	"Global pulse damages ALL enemies, slow attack": "全局脉冲伤害所有敌人，攻速慢",
	"Buffs nearby tower attack speed periodically": "定期提升范围内塔的攻速",

	# --- Enemy names ---
	"Angel Scout": "天使斥候",
	"Holy Knight": "圣骑士",
	"Divine Hunter": "神圣猎手",
	"God of War": "战神",
	"Paladin": "圣武士",
	"Monk": "武僧",
	"Archangel Commander": "大天使指挥官",
	"Divine Guardian": "神圣守卫",
	"Archangel Michael": "大天使米迦勒",
	"Zeus": "宙斯",

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
	"BOSS: Paladin with Archangel guard": "首领：圣武士与大天使护卫",
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

	# --- Pact names ---
	"Blood Rage": "血怒",
	"Infernal Discount": "地狱折扣",
	"Soul Harvest": "灵魂收割",
	"Hellfire Rain": "地狱火雨",
	"Demonic Fervor": "恶魔狂热",
	"Sin Amplifier": "罪孽放大器",

	# --- Pact benefits ---
	"All towers 2x damage for 3 waves": "所有塔3波内伤害翻倍",
	"Next 3 towers are free": "接下来3座塔免费",
	"Triple sin income for 1 wave": "1波内罪孽收入三倍",
	"Instant massive AoE to all enemies": "对所有敌人造成大范围伤害",
	"All towers +50% attack speed (perm)": "所有塔攻击速度永久+50%",
	"All sin earnings doubled for 5 waves": "5波内所有罪孽收入翻倍",

	# --- Pact costs ---
	"Core loses 20 HP": "核心失去20生命值",
	"Enemies 30% faster for 2 waves": "敌人2波内速度增加30%",
	"Enemies 20% faster for 2 waves": "敌人2波内速度增加20%",
	"All towers disabled 10 seconds": "所有塔禁用10秒",
	"Core max HP reduced by 25": "核心最大生命值减少25",
	"All current sins halved": "当前所有罪孽减半",

	# --- Dice outcomes ---
	"HELLFIRE APOCALYPSE": "地狱火天启",
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

	# --- Notification messages ---
	"A Fallen Hero has joined your cause!": "一位堕落英雄加入了你的阵营！",
	"Prepare your defenses!": "准备你的防御！",
	"No deal.": "拒绝交易。",
	"Trojan Relic! Elite enemies spawned!": "特洛伊遗物！精锐敌人出现！",
	"Only one Lucifer allowed!": "只能拥有一个路西法！",
}
