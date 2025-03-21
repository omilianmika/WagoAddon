local addonName, addon = ...
local frame = CreateFrame("Frame")
local WagoAddonDB = WagoAddonDB or {}

-- Initialize saved variables
if not WagoAddonDB.enabled then
    WagoAddonDB.enabled = true
    WagoAddonDB.showIcon = true
    WagoAddonDB.position = {"CENTER", 0, 0}
    WagoAddonDB.scale = 1.0
    WagoAddonDB.alpha = 1.0
    WagoAddonDB.showCooldown = true
    WagoAddonDB.showRange = true
    WagoAddonDB.showKeybind = true
    WagoAddonDB.combatState = {}
end

-- Create main frame with improved movement
local mainFrame = CreateFrame("Frame", "WagoAddonFrame", UIParent)
mainFrame:SetSize(50, 50)
mainFrame:SetPoint(unpack(WagoAddonDB.position))
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
mainFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local _, _, _, x, y = self:GetPoint()
    WagoAddonDB.position = {"TOPLEFT", x, y}
end)
mainFrame:SetScale(WagoAddonDB.scale)
mainFrame:SetAlpha(WagoAddonDB.alpha)

-- Create icon with cooldown overlay
local icon = mainFrame:CreateTexture(nil, "OVERLAY")
icon:SetAllPoints()
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local cooldown = CreateFrame("Cooldown", nil, mainFrame, "CooldownFrameTemplate")
cooldown:SetAllPoints()
cooldown:SetHideCountdownNumbers(true)

-- Create range indicator
local rangeIndicator = mainFrame:CreateTexture(nil, "OVERLAY")
rangeIndicator:SetSize(12, 12)
rangeIndicator:SetPoint("TOPRIGHT", -2, -2)
rangeIndicator:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")

-- Create keybind text
local keybindText = mainFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
keybindText:SetPoint("BOTTOMRIGHT", -2, 2)

-- Create tooltip with enhanced information
local tooltip = CreateFrame("GameTooltip", "WagoAddonTooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(mainFrame, "ANCHOR_RIGHT")

-- Combat state tracking
local combatState = {
    lastSpellCast = 0,
    lastSpellName = "",
    targetHealth = 100,
    playerHealth = 100,
    targetCasting = false,
    targetCastingSpell = "",
    targetCastingTime = 0,
    targetBuffs = {},
    targetDebuffs = {},
    playerBuffs = {},
    playerDebuffs = {},
    inCombat = false,
    lastUpdate = 0
}

-- Enhanced PvP strategies database with all classes and more specific conditions
local pvpStrategies = {
    WARRIOR = {
        offensive = {
            {spell = "Polymorph", priority = 1, condition = function() 
                return not IsSpellInRange("Charge", "target") and 
                       combatState.targetHealth > 50 and
                       not combatState.targetCasting 
            end},
            {spell = "Frostbolt", priority = 2, condition = function() 
                return not IsSpellInRange("Charge", "target") and
                       combatState.targetHealth > 30
            end},
            {spell = "Frost Nova", priority = 3, condition = function() 
                return IsSpellInRange("Charge", "target") and
                       not combatState.targetCasting
            end},
            {spell = "Blink", priority = 4, condition = function() 
                return IsSpellInRange("Charge", "target") and
                       combatState.targetCasting and
                       combatState.targetCastingSpell == "Charge"
            end},
            {spell = "Ice Lance", priority = 5, condition = function() 
                return combatState.targetHealth < 30 or
                       (combatState.targetCasting and combatState.targetCastingSpell == "Shield Wall")
            end}
        },
        defensive = {
            {spell = "Ice Barrier", priority = 1, condition = function() 
                return not UnitBuff("player", "Ice Barrier") and
                       (combatState.playerHealth < 70 or combatState.targetCasting)
            end},
            {spell = "Counterspell", priority = 2, condition = function() 
                return UnitCastingInfo("target") and
                       (combatState.targetCastingSpell == "Mortal Strike" or
                        combatState.targetCastingSpell == "Shield Slam")
            end},
            {spell = "Blink", priority = 3, condition = function() 
                return IsSpellInRange("Charge", "target") and
                       (combatState.playerHealth < 50 or combatState.targetCasting)
            end}
        }
    }
    -- ... (rest of the class strategies)
}

-- Enhanced function to get next move based on current situation
local function GetNextMove(playerClass, targetClass, isOffensive)
    local strategies = pvpStrategies[targetClass]
    if not strategies then return nil end
    
    local moveList = isOffensive and strategies.offensive or strategies.defensive
    if not moveList then return nil end
    
    -- Sort moves by priority
    table.sort(moveList, function(a, b) return a.priority < b.priority end)
    
    -- Return the highest priority move that's available and meets conditions
    for _, move in ipairs(moveList) do
        if IsSpellKnown(move.spell) and not IsSpellOnCooldown(move.spell) then
            if not move.condition or move.condition() then
                return move.spell
            end
        end
    end
    
    return nil
end

-- Update combat state
local function UpdateCombatState()
    local currentTime = GetTime()
    if currentTime - combatState.lastUpdate < 0.1 then return end
    combatState.lastUpdate = currentTime

    -- Update health
    combatState.targetHealth = UnitHealth("target") / UnitHealthMax("target") * 100
    combatState.playerHealth = UnitHealth("player") / UnitHealthMax("player") * 100

    -- Update casting state
    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo("target")
    combatState.targetCasting = name ~= nil
    combatState.targetCastingSpell = name or ""
    combatState.targetCastingTime = endTime and (endTime - GetTime()) / 1000 or 0

    -- Update buffs and debuffs
    combatState.targetBuffs = {}
    combatState.targetDebuffs = {}
    combatState.playerBuffs = {}
    combatState.playerDebuffs = {}

    for i = 1, 40 do
        local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID = UnitBuff("target", i)
        if name then
            combatState.targetBuffs[name] = {
                count = count,
                duration = duration,
                expirationTime = expirationTime,
                spellID = spellID
            }
        end
    end

    for i = 1, 40 do
        local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID = UnitDebuff("target", i)
        if name then
            combatState.targetDebuffs[name] = {
                count = count,
                duration = duration,
                expirationTime = expirationTime,
                spellID = spellID
            }
        end
    end

    -- Update combat state
    combatState.inCombat = UnitAffectingCombat("player") or UnitAffectingCombat("target")
end

-- Update UI elements
local function UpdateUI(spellName)
    if not spellName then return end

    -- Update icon
    icon:SetTexture(GetSpellTexture(spellName))

    -- Update cooldown
    if WagoAddonDB.showCooldown then
        local start, duration = GetSpellCooldown(spellName)
        if start and duration then
            cooldown:SetCooldown(start, duration)
        end
    end

    -- Update range indicator
    if WagoAddonDB.showRange then
        local inRange = IsSpellInRange(spellName, "target")
        rangeIndicator:SetShown(not inRange)
    end

    -- Update keybind
    if WagoAddonDB.showKeybind then
        local key = GetBindingKey("SPELL " .. spellName)
        keybindText:SetText(key or "")
    end

    -- Update tooltip
    tooltip:SetSpellByID(GetSpellID(spellName))
end

-- Combat event handler with enhanced logic
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:SetScript("OnEvent", function(self, event, ...)
    UpdateCombatState()

    if event == "PLAYER_TARGET_CHANGED" then
        local target = UnitExists("target") and UnitClass("target")
        if target then
            local nextMove = GetNextMove(UnitClass("player"), target, true)
            if nextMove then
                UpdateUI(nextMove)
                mainFrame:Show()
            else
                mainFrame:Hide()
            end
        else
            mainFrame:Hide()
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName = CombatLogGetCurrentEventInfo()
        
        if subevent == "SPELL_CAST_SUCCESS" and sourceGUID == UnitGUID("target") then
            local nextMove = GetNextMove(UnitClass("player"), UnitClass("target"), false)
            if nextMove then
                UpdateUI(nextMove)
            end
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" then
            local nextMove = GetNextMove(UnitClass("player"), UnitClass("target"), true)
            if nextMove then
                UpdateUI(nextMove)
            end
        end
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" or unit == "target" then
            local nextMove = GetNextMove(UnitClass("player"), UnitClass("target"), true)
            if nextMove then
                UpdateUI(nextMove)
            end
        end
    end
end)

-- Enhanced slash commands
SLASH_WAGOADDON1 = "/wago"
SLASH_WAGOADDON2 = "/wagoaddon"
SlashCmdList["WAGOADDON"] = function(msg)
    if msg == "toggle" then
        WagoAddonDB.enabled = not WagoAddonDB.enabled
        mainFrame:SetShown(WagoAddonDB.enabled)
    elseif msg == "reset" then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint("CENTER")
        WagoAddonDB.position = {"CENTER", 0, 0}
    elseif msg == "scale" then
        local scale = tonumber(msg:match("%d+%.?%d*"))
        if scale then
            WagoAddonDB.scale = scale
            mainFrame:SetScale(scale)
        end
    elseif msg == "alpha" then
        local alpha = tonumber(msg:match("%d+%.?%d*"))
        if alpha then
            WagoAddonDB.alpha = alpha
            mainFrame:SetAlpha(alpha)
        end
    elseif msg == "cooldown" then
        WagoAddonDB.showCooldown = not WagoAddonDB.showCooldown
    elseif msg == "range" then
        WagoAddonDB.showRange = not WagoAddonDB.showRange
    elseif msg == "keybind" then
        WagoAddonDB.showKeybind = not WagoAddonDB.showKeybind
    else
        print("WagoAddon commands:")
        print("/wago toggle - Toggle the addon on/off")
        print("/wago reset - Reset the position of the icon")
        print("/wago scale <number> - Set the scale of the icon (0.5-2.0)")
        print("/wago alpha <number> - Set the transparency of the icon (0.0-1.0)")
        print("/wago cooldown - Toggle cooldown display")
        print("/wago range - Toggle range indicator")
        print("/wago keybind - Toggle keybind display")
    end
end 