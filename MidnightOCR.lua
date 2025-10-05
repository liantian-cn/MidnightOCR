--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, RL = ...

if MidnightOCRDB == nil then
    MidnightOCRDB = {}
end

local category = Settings.RegisterVerticalLayoutCategory(addonName)
Settings.RegisterAddOnCategory(category)

do
    local name = "刷新率"
    local tooltip = "每秒刷新速度，这将影响CPU占用，默认10"
    local variable = addonName .. "FPS"
    local defaultValue = 10
    local minValue = 1
    local maxValue = 30
    local step = 1
    local function GetValue()
        return MidnightOCRDB.FPS or defaultValue
    end

    local function SetValue(value)
        MidnightOCRDB.FPS = value
    end

    if MidnightOCRDB.FPS == nil then
        MidnightOCRDB.FPS = defaultValue
    end

    local setting = Settings.RegisterProxySetting(category, variable, type(defaultValue), name, defaultValue, GetValue, SetValue)
    local options = Settings.CreateSliderOptions(minValue, maxValue, step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
    Settings.CreateSlider(category, setting, options, tooltip)
end


-- R	G	B	
-- 17	255	102	PlayerBuffs
-- 34	238	136	PlayerDebuffs
-- 51	221	170	TargetDebuffs
-- 68	204	204	HP
-- 85	187	238	Power
-- 102	170	255	Assisted
-- 119	153	221	
-- 136	136	187	
-- 153	119	153	
-- 170	102	119	
-- 187	85	85	
-- 204	68	51	
-- 221	51	17	
-- 238	34	34	
-- 255	17	68	


-- UI缩放计算函数，用于将设计像素转换为实际游戏中的像素值
local function GetUIScaleFactor(pixelValue)
    local screenHeight = select(2, GetPhysicalScreenSize())
    return pixelValue * (768 / screenHeight) / WorldFrame:GetEffectiveScale()
    -- return pixelValue
end

-- 定义基础尺寸变量
local iconWidth = GetUIScaleFactor(12)
local frameHeight = GetUIScaleFactor(12)
local textWidth = GetUIScaleFactor(100)
local baseFrameWidth = GetUIScaleFactor(115)
local baseFrameHeight = GetUIScaleFactor(24)


local MAX_PLAYER_BUFFS = 24
local MAX_PLAYER_DEBUFFS = 8
local MAX_TARGET_DEBUFFS = 8
local defaultIcon = "Interface\\Addons\\MidnightOCR\\square1"
local markIcon = "Interface\\Addons\\MidnightOCR\\square2"



-- 创建插件主框架
local MainFrame = CreateFrame("Frame", "WowDruidMidnightMainFrame", WorldFrame)
MainFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
MainFrame:SetSize(baseFrameWidth, baseFrameHeight) -- 使用计算后的尺寸
MainFrame:SetMovable(true)
MainFrame:EnableMouse(true)
MainFrame:SetClampedToScreen(true)
MainFrame:Show()


-- 存储主框架的所有行
MainFrame.Rows = {}

-- 更新主框架大小的函数
local function UpdateMainFrameSize()
    local totalHeight = frameHeight -- 标题栏高度

    -- 计算所有计时条的高度
    for i = 1, #MainFrame.Rows do
        totalHeight = totalHeight + frameHeight
    end

    -- 设置主框架的新高度
    MainFrame:SetSize(baseFrameWidth, totalHeight)
end


function MainFrame:AddTitle(r, g, b, title, iconPath)
    r = math.max(0, math.min(255, r)) / 255
    g = math.max(0, math.min(255, g)) / 255
    b = math.max(0, math.min(255, b)) / 255
    iconPath = iconPath or defaultIcon
    local rowIndex = #self.Rows + 1
    local titleFrame = CreateFrame("Frame", "WowDruidMidnightCows" .. rowIndex, MainFrame)
    -- 设置计时条框架尺寸和位置
    titleFrame:SetSize(baseFrameWidth, frameHeight)
    if rowIndex == 1 then
        titleFrame:SetPoint("TOPLEFT", MainFrame, 0, 0)
    else
        titleFrame:SetPoint("TOPLEFT", self.Rows[rowIndex - 1].frame, "BOTTOMLEFT", 0, 0)
    end
    titleFrame:Show()

    -- 设置底色
    local bgTexture = titleFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints()
    bgTexture:SetColorTexture(r, g, b, 1)
    bgTexture:Show()

    -- 创建图标 (10x10，边距1)
    local icon = titleFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(iconWidth, iconWidth)
    icon:SetPoint("LEFT", titleFrame, "LEFT", GetUIScaleFactor(3), 0)
    icon:SetColorTexture(r, g, b, 1)
    icon:SetTexture(iconPath)
    icon:Show()

    -- 创建标题栏右侧的文本条
    local titleText = titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    titleText:SetSize(textWidth, iconWidth)
    titleText:SetPoint("RIGHT", titleFrame, "RIGHT", 0, 0)
    titleText:SetJustifyH("CENTER")
    titleText:SetJustifyV("MIDDLE")
    local fontFile, _, _ = GameFontNormal:GetFont()
    titleText:SetFont(fontFile, 4, "")
    titleText:SetText(title)
    titleText:SetTextColor(1, 1, 1, 1)
    titleText:Show()

    -- 保存计时条信息
    local rowInfo = {
        frame = titleFrame,
        icon = icon,
        text = titleText,
    }

    table.insert(self.Rows, rowInfo)

    -- 更新主框架大小以适应新添加的计时条
    UpdateMainFrameSize()

    titleFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            MainFrame:StartMoving()
        end
    end)

    titleFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            MainFrame:StopMovingOrSizing()
        end
    end)
    return rowInfo
end

-- 在标题栏下方添加计时条的方法
function MainFrame:AddStatusBar(r, g, b, iconPath, minValue, maxValue)
    r = math.max(0, math.min(255, r)) / 255
    g = math.max(0, math.min(255, g)) / 255
    b = math.max(0, math.min(255, b)) / 255
    minValue = minValue or 0
    maxValue = maxValue or 100
    iconPath = iconPath or defaultIcon

    local rowIndex = #self.Rows + 1
    local barFrame = CreateFrame("Frame", "WowDruidMidnightCows" .. rowIndex, MainFrame)

    -- 设置计时条框架尺寸和位置
    barFrame:SetSize(baseFrameWidth, frameHeight)
    if rowIndex == 1 then
        barFrame:SetPoint("TOPLEFT", MainFrame, 0, 0)
    else
        barFrame:SetPoint("TOPLEFT", self.Rows[rowIndex - 1].frame, "BOTTOMLEFT", 0, 0)
    end
    barFrame:Show()

    -- 设置底色
    local bgTexture = barFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints()
    bgTexture:SetColorTexture(r, g, b, 1)
    bgTexture:Show()

    -- 创建图标 (10x10，边距1)
    local icon = barFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(iconWidth, iconWidth)
    icon:SetPoint("LEFT", barFrame, "LEFT", GetUIScaleFactor(3), 0)
    icon:SetColorTexture(r, g, b, 1)
    icon:SetTexture(iconPath)
    icon:Show()

    -- 创建StatusBar (10x100，上下边距1)
    local statusBar = CreateFrame("StatusBar", nil, barFrame)
    statusBar:SetSize(textWidth, iconWidth)
    statusBar:SetPoint("RIGHT", barFrame, "RIGHT", 0, 0)
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar") -- 使用纯色材质
    statusBar:GetStatusBarTexture():SetColorTexture(1, 1, 1, 1)              -- 白色计时条
    statusBar:SetStatusBarColor(1, 1, 1, 1)
    statusBar:SetMinMaxValues(minValue, maxValue)
    statusBar:SetValue(minValue)
    statusBar:Show()

    -- 设置StatusBar背景为纯黑色
    local statusBarBG = statusBar:CreateTexture(nil, "BACKGROUND")
    statusBarBG:SetAllPoints(statusBar)
    statusBarBG:SetColorTexture(0, 0, 0, 1)
    statusBarBG:Show()

    -- 保存计时条信息
    local rowInfo = {
        frame = barFrame,
        icon = icon,
        statusBar = statusBar,
        defaultIcon = iconPath
    }

    table.insert(self.Rows, rowInfo)

    -- 更新主框架大小以适应新添加的计时条
    UpdateMainFrameSize()

    function rowInfo:reset()
        icon:SetTexture(self.defaultIcon)
        statusBar:SetMinMaxValues(minValue, maxValue)
        statusBar:SetValue(minValue)
    end

    function rowInfo:setV(iconFile, minV, maxV, curV)
        icon:SetTexture(iconFile)
        statusBar:SetMinMaxValues(minV, maxV)
        statusBar:SetValue(curV)
    end

    return rowInfo
end

--- 正式开始
---
--- 初始化
MainFrame:AddTitle(0, 0, 0, "MidnightOCR", markIcon)


MainFrame:AddTitle(102, 170, 255, "AssistedCombat", "interface/icons/wow_token02.blp")
MainFrame.AssistedCombat = MainFrame:AddStatusBar(102, 170, 255, "interface/icons/wow_token02.blp")


local function refreshAssistedCombat()
    local spellID = C_AssistedCombat.GetNextCastSpell(false)
    if spellID == nil then
        MainFrame.AssistedCombat:setV(defaultIcon, 0, 10, 5)
        return
    end
    local gcd = C_Spell.GetSpellCooldown(61304)
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    local now = GetTime()
    local timer_star = now - 1
    -- print("time:" .. now .. "end" .. timer_end .. "d" .. spellCooldownInfo.duration)
    MainFrame.AssistedCombat:setV(spellInfo.iconID, timer_star, now, gcd.startTime)
end

MainFrame.PlayerBuffs = {}
MainFrame:AddTitle(17, 255, 102, "PlayerBuffs")
for i = 1, MAX_PLAYER_BUFFS do
    local rowInfo = MainFrame:AddStatusBar(17, 255, 102)
    table.insert(MainFrame.PlayerBuffs, rowInfo)
end


MainFrame.PlayerDebuffs = {}
MainFrame:AddTitle(34, 238, 136, "PlayerDebuffs")
for i = 1, MAX_PLAYER_DEBUFFS do
    local rowInfo = MainFrame:AddStatusBar(34, 238, 136)
    table.insert(MainFrame.PlayerDebuffs, rowInfo)
end

MainFrame.TargetDebuffs = {}
MainFrame:AddTitle(51, 221, 170, "TargetDebuffs")
for i = 1, MAX_TARGET_DEBUFFS do
    local rowInfo = MainFrame:AddStatusBar(51, 221, 170)
    table.insert(MainFrame.TargetDebuffs, rowInfo)
end


local function refreshBuffsAndDebuffs()
    -- 刷新玩家 buffs
    local now = GetTime()
    local timer_end = now + 10
    for i = 1, MAX_PLAYER_BUFFS do
        local row = MainFrame.PlayerBuffs[i]
        row:reset()
    end

    for i = 1, MAX_PLAYER_BUFFS do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL|PLAYER")
        if not aura then break end
        local row = MainFrame.PlayerBuffs[i]
        row:setV(aura.icon, now, timer_end, aura.expirationTime)
    end

    for i = 1, MAX_PLAYER_DEBUFFS do
        local row = MainFrame.PlayerDebuffs[i]
        row:reset()
    end

    for i = 1, MAX_PLAYER_DEBUFFS do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HARMFUL")
        if not aura then break end
        local row = MainFrame.PlayerDebuffs[i]
        row:setV(aura.icon, now, timer_end, aura.expirationTime)
    end

    for i = 1, MAX_TARGET_DEBUFFS do
        local row = MainFrame.TargetDebuffs[i]
        row:reset()
    end

    if UnitExists("target") then
        for i = 1, MAX_TARGET_DEBUFFS do
            local aura = C_UnitAuras.GetAuraDataByIndex("target", i, "HARMFUL|PLAYER")
            if not aura then break end
            local row = MainFrame.TargetDebuffs[i]
            row:setV(aura.icon, now, timer_end, aura.expirationTime)
        end
    end
end

local hpicon = "interface/icons/inv_gizmo_runichealthinjector.blp"
local powericon = "interface/icons/inv_gizmo_runicmanainjector.blp"

MainFrame:AddTitle(68, 204, 204, "HP")
MainFrame.PlayerHP = MainFrame:AddStatusBar(68, 204, 204, hpicon)

MainFrame:AddTitle(85, 187, 238, "Power")
MainFrame.PlayerPower = MainFrame:AddStatusBar(85, 187, 238, powericon)

local function refreshHPandPower()
    local playerHP = UnitHealth("player")
    local playerMaxHP = UnitHealthMax("player")
    MainFrame.PlayerHP:setV(hpicon, 0, playerMaxHP, playerHP)

    local playerPower = UnitPower("player")
    local playerMaxPower = UnitPowerMax("player")
    MainFrame.PlayerPower:setV(powericon, 0, playerMaxPower, playerPower)
end



-- 更新计时条的OnUpdate脚本
local tickTimer = GetTime()
MainFrame:SetScript("OnUpdate", function(self, elapsed)
    local targetFps = MidnightOCRDB["FPS"];
    local tickOffset = 1.0 / targetFps;
    if GetTime() > tickTimer then
        tickTimer = GetTime() + tickOffset;
        refreshHPandPower();
        refreshBuffsAndDebuffs()
        refreshAssistedCombat()
    end
    return
end)



MainFrame:AddTitle(0, 0, 0, "MidnightEND", markIcon)
