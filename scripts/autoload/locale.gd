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

## Public check for whether a tf() template key is defined. Lets other systems
## (e.g. GM.targeting_mode_label) choose between a template and a fallback without
## reaching into the private _templates dictionary.
func has_template(key: String) -> bool:
	return _templates.has(key)

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
		"en": "Wave: {wave} | Kills: {kills} | Bosses: {bosses} | Towers: {towers}\nSins: {sins} | Dmg: {dmg} | Leaked: {core_dmg}",
		"zh": "波次: {wave} | 击杀: {kills} | Boss: {bosses} | 塔: {towers}\n罪孽: {sins} | 伤害: {dmg} | 泄漏: {core_dmg}",
	},
	"victory_stats": {
		"en": "Kills: {kills} | Bosses: {bosses} | Towers: {towers}\nSins: {sins} | Dmg: {dmg} | Leaked: {core_dmg}",
		"zh": "击杀: {kills} | Boss: {bosses} | 塔: {towers}\n罪孽: {sins} | 伤害: {dmg} | 泄漏: {core_dmg}",
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
	"unique_tower_limit": {
		"en": "Only one {name} allowed!",
		"zh": "只能拥有一个{name}！",
	},
	"legendary_upgrade": {
		"en": "Legendary! {name} upgraded to Lv.{level}!",
		"zh": "传说！{name} 升级到等级{level}！",
	},
	"legendary_fallback": {
		"en": "All towers maxed! +{amount} Sins instead",
		"zh": "所有塔已满级！获得{amount}罪恶值",
	},
	"pandora_sins": {
		"en": "Pandora grants {amount} Sins!",
		"zh": "潘多拉赐予{amount}罪恶值！",
	},
	"soul_surge": {
		"en": "Soul Surge! +{amount} to the Fallen Hero pool!",
		"zh": "灵魂涌动！堕落英雄进度 +{amount}！",
	},
	"core_healed": {
		"en": "Vital Surge! Hell's Core +{amount} HP!",
		"zh": "生命涌动！地狱核心 +{amount} 生命！",
	},
	"sins_taxed": {
		"en": "Devil's Tax! -{amount} Sins",
		"zh": "魔鬼税！-{amount}罪恶值",
	},
	# Targeting-mode labels — used by the tower's Target button so the priority
	# reads in the player's language instead of a raw English mode name.
	"targeting_closest": {"en": "Closest", "zh": "最近"},
	"targeting_first": {"en": "First", "zh": "最前"},
	"targeting_last": {"en": "Last", "zh": "最后"},
	"targeting_strongest": {"en": "Strongest", "zh": "最强"},
	"targeting_weakest": {"en": "Weakest", "zh": "最弱"},
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
	"4-9: Towers | U: Upgrade | X: Sell | T: Target | P: Pause\nSpace: Skip | Tab: Overview | D: Dice | Y/N: Pacts | Esc: Cancel": "4-9：选塔 | U：升级 | X：出售 | T：目标 | P：暂停\n空格：跳过 | Tab：总览 | D：骰子 | Y/N：契约 | Esc：取消",

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

	# --- Tower descriptions (must match TOWER_DATA desc strings exactly —
	# the old post-redesign strings had drifted, leaving zh players with
	# untranslated English tooltips) ---
	"Fast attacks, reliable early damage": "快速攻击，可靠的前期伤害",
	"AoE blast ignites burn stacks (1 dps/stack, caps 4, 3s)": "范围爆炸点燃灼烧层数（每层1伤害/秒，上限4层，持续3秒）",
	"Slow aura: enemies in range move 40% slower": "减速光环：范围内敌人移速降低40%",
	"Buffs nearby towers, damages enemies, +15% Cocytus corruption": "增益附近塔防，伤害敌人，科赛特斯腐蚀+15%",
	"Continuous frost cone — always casting in one direction": "持续冰霜锥形——始终向一个方向施放",
	"Global pulse, executes enemies below 15% HP": "全局脉冲，处决生命值低于15%的敌人",

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
	"Soul Surge": "灵魂涌动",
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
	"A Demonic Pact is offered...": "一份恶魔契约正在等待...",
	"Accepted!": "已接受！",
	"Pact declined.": "契约已拒绝。",
	"Accept": "接受",
	"Decline": "拒绝",

	# --- Pact descriptions ---
	"+50% Sin income for 2 waves": "+50%罪孽收入，持续2波",
	"Lose 15 Core HP": "失去15核心生命值",
	"All towers +20% damage permanently": "所有塔永久+20%伤害",
	"2 random towers disabled for 8s": "2座随机塔禁用8秒",
	"Gain 120 Sins instantly": "立即获得120罪孽",
	"Enemies +30% speed for 2 waves": "敌人速度+30%，持续2波",
	"Restore 20 Core HP": "恢复20核心生命值",
	"Lose 25% of current Sins": "失去当前25%的罪孽",
	"Double damage for 1 wave": "1波内伤害翻倍",
	"Next wave spawns 3 extra War Titans": "下一波额外生成3个战争巨人",
	"Next tower placement is free": "下一座塔免费放置",
	"All towers -15% damage for 3 waves": "所有塔伤害-15%，持续3波",
	"Blood Tithe": "血之献祭",
	"Infernal Forge": "地狱锻造",
	"Soul Harvest": "灵魂收割",
	"Dark Resilience": "黑暗韧性",
	"Chaos Pact": "混沌契约",
	"Abyssal Gambit": "深渊赌局",

	# --- HUD buttons ---
	"Upgrade": "升级",
	"Sell": "出售",
	"Target": "目标",

	# --- Overview labels ---
	"GLOBAL": "全局",
	"SUPPORT": "辅助",

	# --- Tower role tooltips ---
	"Role: Global Pulse — damages all enemies on screen": "定位：全局脉冲 - 对屏幕上所有敌人造成伤害",
	"Role: Support — buffs nearby towers and damages enemies": "定位：辅助 - 增强附近塔并对敌人造成伤害",
	"Role: Area Denial — continuous frost cone in one direction": "定位：区域封锁 - 向一个方向持续发射冰霜锥形",
	"Role: Swarm Clearer — AoE damage hits groups": "定位：清群 - 范围伤害打击群体",
	"Role: Force Multiplier — slows enemies in aura range": "定位：增效 - 减速光环范围内的敌人",
	"Role: Single-Target DPS — fast reliable damage": "定位：单体输出 - 快速稳定的伤害",
}
