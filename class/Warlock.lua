local _, fu = ...
if fu.classId ~= 9 then return end

local creat = fu.updateOrCreatTextureByIndex

-- ================================================================
--                    恶魔术士 12.0.5 simc APL 优化
-- ================================================================

-- 关键法术ID
local DEMONOLOGY = {
    -- 资源
    SOUL_SHARDS = 7,        -- 灵魂碎片
    -- 核心技能
    SHADOW_BOLT = 231095,   -- 暗影箭
    DEMONBOLT = 264173,     -- 恶魔箭
    HAND_OF_GULDAN = 105174,-- 古尔丹之手
    CALL_DREADSTALKERS = 193332, -- 召唤恐惧猎犬
    SUMMON_DEMONIC_TYRANT = 265187, -- 召唤恶魔暴君
    IMPLOSION = 196277,     -- 内爆
    POWER_SIPHON = 442726,  -- 能量汲取
    DOOM = 442700,          -- 末日
    -- 恶魔技能
    GRIMOIRE_IMP = 111859, -- 魔典：小鬼
    GRIMOIRE_FELGUARD = 111895, -- 魔典：恶魔卫士
    SUMMON_DOOMGUARD = 18540, -- 召唤末日守卫
    SUMMON_FELHUNTER = 691, -- 召唤地狱猎犬
    -- 消耗品
    FELSTORM = 115625,     -- 邪能风暴
    -- 饰品/爆发
    SYMULACRUM = 317078,    -- 邪能镜像
    -- 光环
    DEMONIC_CORE = 264173,  -- 恶魔之心(恶魔箭触发)
    INNER_DEMONS = 267216,  -- 内心恶魔
}

fu.heroSpell = {
    [445486] = 1, -- 地狱召唤者 (Diabolist)
    [449614] = 2, -- 灵魂收割者 (Soul Harvester)
    [428514] = 3, -- 恶魔使徒
}

-- ================================================================
--                    更新光环系统
-- ================================================================
fu.updateAuras = fu.updateAuras or {}
fu.updateAuras.bySuccess = fu.updateAuras.bySuccess or {}
fu.updateAuras.byIcon = fu.updateAuras.byIcon or {}
fu.updateAuras.bySpellOverride = fu.updateAuras.bySpellOverride or {}
fu.updateAuras.bySpellCooldown = fu.updateAuras.bySpellCooldown or {}
fu.updateAuras.byActivationOverlay = fu.updateAuras.byActivationOverlay or {}
fu.updateAuras.byOverlayGlow = fu.updateAuras.byOverlayGlow or {}

-- 初始化光环
fu.auras = fu.auras or {}

fu.spellCooldown = {
    [5782]    = { index = 31, name = "恐惧" },
    [6789]    = { index = 32, name = "死亡缠绕" },
    [20707]   = { index = 33, name = "灵魂石" },
    [30283]   = { index = 34, name = "暗影之怒" },
    [333889]  = { index = 35, name = "邪能统御" },
    [108416]  = { index = 36, name = "黑暗契约" },
    [111771]  = { index = 37, name = "恶魔传送门" },
    [1271748] = { index = 38, name = "虚弱灾厄" },
    [1271802] = { index = 39, name = "语言灾厄" },
    [48018]   = { index = 40, name = "恶魔法阵" },
    [48020]   = { index = 41, name = "恶魔法阵：传送" },
}

function fu.updateSpecInfo()
    local specIndex = C_SpecializationInfo.GetSpecialization()
    fu.powerType = nil
    fu.blocks = nil
    fu.group_blocks = nil
    fu.assistant_spells = nil
    if specIndex == 1 then
        fu.blocks = {
            ["灵魂碎片"] = 23,
            ["施法技能"] = 24,
            auras = {

            },
        }
        fu.spellCooldown[205180] = { index = 42, name = "召唤黑眼" }
        fu.spellCooldown[48181] = { index = 43, name = "鬼影缠身" }
        fu.spellCooldown[1257052] = { index = 44, name = "幽冥收割" }
        fu.spellCooldown[442726] = { index = 45, name = "怨毒" }
    elseif specIndex == 2 then
        -- ================================================================
        --                    恶魔术士 (Demonology) - 12.0.5 simc APL
        -- ================================================================
        fu.powerType = "MANA"
        
        -- 创建自动布局条 - 内爆
        local eventTable = { "SPELL_UPDATE_USES", "PLAYER_ENTERING_WORLD" }
        fu.CreateAutoLayoutBar(0, 20, DEMONOLOGY.IMPLOSION, eventTable)
        
        -- ================================================================
        --                    关键光环追踪
        -- ================================================================
        fu.blocks = {
            ["灵魂碎片"] = 23,
            ["施法技能"] = 24,
            ["敌人人数"] = 25,
            ["恶魔之心"] = 26,      -- Demonic Core 层数
            auras = {
                -- 魔典：邪能破坏者 (邪能统御召唤的恶魔增强)
                ["魔典：邪能破坏者"] = {
                    index = 31,
                    auraRef = fu.updateAuras.byIcon[1276467],
                    showKey = "isIcon",
                },
                -- 恶魔之心 (恶魔箭触发，可释放瞬发恶魔箭)
                ["恶魔之心"] = {
                    index = 32,
                    auraRef = fu.auras["恶魔之心"],
                    showKey = "count",
                },
                -- 末日 (Doom 持续伤害)
                ["末日"] = {
                    index = 33,
                    auraRef = fu.auras["末日"],
                    showKey = "remaining",
                },
                -- 恶魔暴君增益
                ["恶魔暴君"] = {
                    index = 34,
                    auraRef = fu.auras["恶魔暴君"],
                    showKey = "remaining",
                },
                -- 恐惧猎犬存在
                ["恐惧猎犬"] = {
                    index = 35,
                    auraRef = fu.auras["恐惧猎犬"],
                    showKey = "count",
                },
            },
        }
        
        -- ================================================================
        --                    法术冷却追踪 (优化排序)
        -- ================================================================
        fu.spellCooldown[DEMONOLOGY.IMPLOSION] = { index = 42, name = "内爆" }
        fu.spellCooldown[DEMONOLOGY.SUMMON_DEMONIC_TYRANT] = { index = 43, name = "召唤恶魔暴君" }
        fu.spellCooldown[DEMONOLOGY.CALL_DREADSTALKERS] = { index = 44, name = "召唤恐惧猎犬" }
        fu.spellCooldown[DEMONOLOGY.HAND_OF_GULDAN] = { index = 45, name = "古尔丹之手" }
        fu.spellCooldown[DEMONOLOGY.POWER_SIPHON] = { index = 46, name = "能量汲取" }
        fu.spellCooldown[DEMONOLOGY.DEMONBOLT] = { index = 47, name = "恶魔箭" }
        fu.spellCooldown[1276672] = { index = 48, name = "召唤末日守卫" }
        fu.spellCooldown[104316] = { index = 49, name = "召唤恐惧猎犬" }
        fu.spellCooldown[264187] = { index = 50, name = "恶魔之箭" }
        fu.spellCooldown[1276452] = { index = 51, name = "魔典：小鬼领主" }
        fu.spellCooldown[388215] = { index = 52, name = "吞噬魔法" }
        fu.spellCooldown[30146] = { index = 53, name = "召唤恶魔卫士" }
        fu.spellCooldown[111859] = { index = 54, name = "魔典：小鬼" }
        fu.spellCooldown[111895] = { index = 55, name = "魔典：恶魔卫士" }
        
        -- ================================================================
        --                    光环成功施放事件
        -- ================================================================
        -- 恶魔箭施放成功 - 增加恶魔之心层数
        fu.updateAuras.bySuccess[DEMONOLOGY.DEMONBOLT] = {
            { name = "恶魔之心", step = 1, castBar = true }
        }
        -- 能量汲取 - 减少恶魔之心
        fu.updateAuras.bySuccess[DEMONOLOGY.POWER_SIPHON] = {
            { name = "恶魔之心", step = -2, castBar = true }
        }
        -- 内爆 - 消耗小鬼
        fu.updateAuras.bySuccess[DEMONOLOGY.IMPLOSION] = {
            { name = "小鬼", step = -6, castBar = true }
        }
        -- 召唤恶魔暴君 - 延长恶魔增益
        fu.updateAuras.bySuccess[DEMONOLOGY.SUMMON_DEMONIC_TYRANT] = {
            { name = "恶魔暴君", overrideSpellID = 265187, castBar = true }
        }
        
        -- ================================================================
        --                    初始化恶魔术光环数据
        -- ================================================================
        fu.auras["恶魔之心"] = {
            count = 0,
            countMin = 0,
            countMax = 4,  -- 最多4层
            duration = nil,
        }
        fu.auras["末日"] = {
            remaining = 0,
            duration = 20, -- 基础20秒
        }
        fu.auras["恶魔暴君"] = {
            remaining = 0,
            duration = 15,
        }
        fu.auras["恐惧猎犬"] = {
            count = 0,
            countMin = 0,
            countMax = 4,  -- 2只恐惧猎犬
            duration = 12,
        }
        fu.auras["小鬼"] = {
            count = 0,
            countMin = 0,
            countMax = 20,
            duration = nil,
        }
        
    elseif specIndex == 3 then
        fu.blocks = {
            ["灵魂碎片"] = 23,
            ["施法技能"] = 24,
            auras = {

            },
        }
        fu.spellCooldown[1122] = { index = 42, name = "召唤地狱火" }
        fu.spellCooldown[6353] = { index = 43, name = "灵魂之火" }
        fu.spellCooldown[17962] = { index = 44, name = "燃烧", charge = 45 }
    end
end

local staticSpells = {
    -- ================================================================
    --                    通用技能
    -- ================================================================
    [1] = "恐惧",
    [2] = "死亡缠绕",
    [3] = "[@cursor]暗影之怒",
    [4] = "邪能统御",
    [5] = "黑暗契约",
    [6] = "虚弱灾厄",
    [7] = "语言灾厄",
    [8] = "恶魔法阵",
    [9] = "恶魔法阵：传送",
    [10] = "灵魂石",
    [11] = "法术封锁",
    [12] = "吞噬魔法",
    [13] = "放逐术",
    [14] = "疲劳诅咒",
    [15] = "语言诅咒",
    
    -- ================================================================
    --                    恶魔术核心技能 (12.0.5 simc APL)
    -- ================================================================
    -- 优先级: 召唤恐惧猎犬 > 能量汲取 > 内爆 > 古尔丹之手 > 瞬发恶魔箭 > 暗影箭
    [20] = "召唤恐惧猎犬",     -- Call Dreadstalkers - 冷却好了就用
    [21] = "能量汲取",         -- Power Siphon - 不要在3+恶魔之心时使用
    [22] = "内爆",             -- Implosion - 6+小鬼时使用
    [23] = "古尔丹之手",       -- Hand of Gul'dan - 3+碎片时使用
    [24] = "恶魔箭",           -- Demonbolt - 有恶魔之心时瞬发
    [25] = "暗影箭",           -- Shadow Bolt - 填充技能
    [26] = "召唤恶魔暴君",     -- Summon Demonic Tyrant - 主要爆发
    [27] = "末日",             -- Doom - 传播用
    [28] = "魔典：小鬼",       -- Grimoire: Imp
    [29] = "魔典：恶魔卫士",   -- Grimoire: Felguard
    [30] = "召唤末日守卫",     -- Summon Doomguard
    
    -- ================================================================
    --                    召唤技能
    -- ================================================================
    [40] = "召唤地狱猎犬",
    [41] = "召唤小鬼",
    [42] = "召唤虚空行者",
    [43] = "召唤恶魔卫士",
    [44] = "召唤黑眼",
    [45] = "魔典：小鬼领主",
    
    -- ================================================================
    --                    痛苦术技能 (备用)
    -- ================================================================
    [50] = "腐蚀术",
    [51] = "痛楚",
    [52] = "吸取生命",
    [53] = "枯萎",
    [54] = "鬼影缠身",
    [55] = "痛苦无常",
    [56] = "暗影灼烧",
    [57] = "腐蚀之种",
    [58] = "暗影之箭",
    
    -- ================================================================
    --                    毁灭术技能 (备用)
    -- ================================================================
    [60] = "燃烧",
    [61] = "混乱之箭",
    [62] = "烧尽",
    [63] = "灵魂之火",
    [64] = "献祭",
    [65] = "火焰之雨",
    [66] = "召唤地狱火",
    [67] = "大灾变",
    [68] = "浩劫",
    [69] = "吸取灵魂",
}

function fu.CreateClassMacro()
    fu.CreateMacro({}, staticSpells)
end
