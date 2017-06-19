local frame = CreateFrame("Frame", "Rotorbar", UIParent);
local handler
local mobsInCombat = {}

Rotorbar = {}

function loadClassHandler()
    local currentSpec = GetSpecialization()

    if (UnitClass("player") == "Death Knight") then
        if (currentSpec == 1) then
            handler = Blood.init()
            handler()

        elseif (currentSpec == 2) then
            handler = Frost.init()
            handler()

        elseif (currentSpec == 3) then
            handler = Unholy.init()
            handler()
        end

     elseif (UnitClass("player") == "Priest") then
            print (currentSpec)

        if (currentSpec == 1) then
            handler = Discipline.init()
            handler()

        elseif (currentSpec == 2) then
            handler = HolyPriest.init()
            handler()

        elseif (currentSpec == 3) then
            handler = Shadow.init()
            handler()
        end
    end
end

function equipmentUsable(slot)
    local start, duration, enable = GetInventoryItemCooldown("player", slot)

    if (enable) then
        if (start == 0) then
            return true, true, 0
        else
            return true, false, ((start+duration)-GetTime())
        end
    else
        return false
    end
    return enable == 1, start == 0
end

function Rotorbar.debuffed(_name, target)
    if (target == nil) then
        target = "target"
    end

    local name, rank, icon, count, dispelType, duration, expires, caster = UnitDebuff(target, _name)

    if (caster == "player") then
       local timeleft = expires - GetTime()
       if (count > 0) then
           return count, timeleft
       else
           return 1, timeleft
       end
    else
        return 0, 0
    end
end

function Rotorbar.buffed(_name)
    local name, rank, icon, count, dispelType, duration, expires, caster = UnitBuff("player", _name)

    if (name == nil) then
        return 0, 0
    else
        local timeleft = expires - GetTime()
        if (count > 0) then
            return count, timeleft
        else
            return 1, timeleft
        end
    end
end

function Rotorbar.targetsInRange(spell)
    local t = 0
    for k, v in pairs(mobsInCombat) do
        if (IsSpellInRange(spell,k)) then
            t = t + 1
        end
    end
    return t
end

function Rotorbar.targetsDebuffed(debuff)
    local t = 0
    for k, v in pairs(mobsInCombat) do
        if (Rotorbar.debuffed(debuff,k)) then
            t = t + 1
        end
    end
    return t
end

function Rotorbar.targetsNotDebuffed(debuff)
    local t = 0
    for k, v in pairs(mobsInCombat) do
        if (not Rotorbar.debuffed(debuff,k)) then
            t = t + 1
        end
    end
    return t
end

function Rotorbar.isBoss()
    return (IsEncounterInProgress() or
        UnitClassification("target") == "rare" or
        UnitClassification("target") == "rareelite" or
        UnitClassification("target") == "worldboss" or
        (UnitName("target") ~= nil and
            string.match(UnitName("target"), "Dummy") == "Dummy"))
end

function Rotorbar.isUsableCooldown(spell, talent)
    if (talent == nil or talent == true) then
        if (IsUsableSpell(spell)) then
            local start, duration = GetSpellCooldown(spell)
            local gstart, gduration = GetSpellCooldown(61304)
            if (start == 0) then
                return true, 0
            else
                local cdleft = (start+duration)-GetTime()
                if (cdleft <= (gstart+gduration)-GetTime()) then
                    return true, cdleft
                else
                    return false, cdleft
                end
            end
        else
            return false, -1
        end
    else
        return false, -1
    end
end

frame:SetMovable(true)
frame:EnableMouse(true)

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")

frame:RegisterEvent("PLAYER_ENTER_COMBAT")
frame:RegisterEvent("PLAYER_STARTED_MOVING")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
frame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("UNIT_POWER")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")

frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

function showGCD()
    local start, duration, enabled, modRate = GetSpellCooldown(61304)
    frame.cool:SetCooldown(start, duration, modRate)
end

frame:SetScript("OnEvent", function(self, event, arg1, ...)
    if (event == "PLAYER_ENTERING_WORLD") then
        loadClassHandler()
        getBindings()

        equipmentInit(13)
        equipmentInit(14)

    elseif (event == "ACTIVE_TALENT_GROUP_CHANGED") then
        loadClassHandler()
        getBindings()

    elseif (event == "PLAYER_TALENT_UPDATE") then
        loadClassHandler()

    elseif (event == "COMBAT_LOG_EVENT_UNFILTERED") then
        local type,srcGuid,srcName,_,tarGuid,tarName,_ = select(3,...)

        if (UnitIsEnemy("player", srcGuid)) then
            if (type == "UNIT_DIED") then
                mobsInCombat.remove(srcGuid)
            else
                if (mobsInCombat[srcGuid] == nil) then
                    mobsInCombat[srcGuid] = srcName
                end
            end
        end

    elseif (event == "ACTIONBAR_SLOT_CHANGED") then
        getBindings()

    else
        if (handler == nil) then
        else
            handler()
            showGCD()
        end
    end
end)

frame:SetWidth(80+20)
frame:SetHeight(40+20)
frame:ClearAllPoints()
frame:SetBackdrop(StaticPopup1:GetBackdrop())
frame:SetPoint("CENTER",UIParent)
frame:SetPoint("Top", UIParent, 0, -20)
frame:Show()

buttonpos = 0
buttonfr = {}
blcurr = 0
gcdmade = false
eq = {}



function Rotorbar.setIcons(num)
    frame:SetWidth((36*num) + 56)
end

function sitexture(_name)
    local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(_name)
    return icon
end

function equipmentInit(slot)
    eq[slot] = {}
    eq[slot].usable = equipmentUsable(slot)
    if (eq[slot].usable) then
        local tex = GetInventoryItemTexture(slot)
        eq[slot].icon = Rotorbar.buttonTime(slot, tex)
        local function cooler()
            return GetInventoryItemCooldown("player", slot)
        end
        eq[slot].cool = Rotorbar.cooldown(slot, nil, tex, cooler)
    end
end

function Rotorbar.equipmentIcon(slot)
    if (eq[slot].usable) then
        local usable, ready, left = equipmentUsable(slot)
        if (ready) then
            return true, true, eq[slot].icon
        else
            return true, false, eq[slot].cool
        end
    else
        return false
    end
end

function Rotorbar.classIcon(r, g, b, a)
    if (not gcdmade) then
        frame.gcd = CreateFrame("Frame", nil, frame)
        frame.gcd:SetSize(36,36)
        frame.gcd:SetPoint("Left", frame, 10, 0)

        frame.icon = frame.gcd:CreateTexture(nil,"CENTER")
        frame.icon:SetAllPoints()

        frame.cool = CreateFrame("Cooldown", nil, frame.gcd, "CooldownFrameTemplate")
        frame.cool:SetAllPoints()

        gcdmade = true
    end

    local _,class = UnitClass("player")
    frame.icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES");
    local coords = CLASS_ICON_TCOORDS[class]
    frame.icon:SetTexCoord(unpack(coords))
    frame.icon:SetVertexColor(r,g,b,a)

end

function Rotorbar.runes()
    local count = 0
    for i = 1, 6 do
        count = count + GetRuneCount(i)
    end
    return count
end

function Rotorbar.flash(name,icon,r,g,b,a)
    local f = Rotorbar.buttonTime(name,icon,r,g,b,a)
    UIFrameFlash(f, .75, .25, 10000000, true, .5, 0)

    f:SetPoint("Left", UIParent, -50, -50)
    f:SetScript("OnHide", function(self)
        f:SetPoint("Left", UIParent, -50, -50)
    end)

    return f, name
end

function Rotorbar.cooldown(name,icon,linkcool,cdfn)
    local f = Rotorbar.buttonTime(name)
    f.cool = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cool:SetAllPoints()
    f.cooldownButton = true
    if (cdfn == nil) then
        cdfn = GetSpellCooldown
    end
    function f.showCool()
        local start, duration, enabled, modRate = cdfn(name)
        if (start == nil) then
        else
            local spellleft = 0
            if (start > 0) then
                spellleft = (start+duration)-GetTime()
            end

            if (linkcool == nil) then
                f.cool:SetCooldown(start, duration, modRate)
            else
                local linkstart, linkduration, linkenabled, linkmodRate = GetSpellCooldown(linkcool)
                local linkleft = 0

                if (linkstart == nil) then
                    f.cool:SetCooldown(start, duration, modRate)
                elseif (linkstart > 0) then
                    linkleft = (linkstart+linkduration)-GetTime()
                elseif (linkleft <= spellleft) then
                    f.cool:SetCooldown(start, duration, modRate)
                else
                    f.cool:SetCooldown(linkstart, linkduration, linkmodRate)
                end
            end
        end
    end
    return f, name
end

function Rotorbar.buttonTime(name,icon,r,g,b,a)
   local f=CreateFrame("Frame",nil,frame)
   local spell = CreateFrame("Button",nil, f,"ActionButtonTemplate")
   f:SetSize(36,36)
   spell:SetSize(36,36)
   f:SetPoint("CENTER")
   spell:SetPoint("CENTER")
   f:Hide()

   f.name = name
   if (icon) then
   else
    icon = sitexture(name)
   end

   f.texture = f:CreateTexture("ARTWORK")
   f.texture:SetTexture(icon)
   f.texture:SetSize(36,36)
   f.texture:SetPoint("CENTER")

   if (r == nil) then
   else
       f.texture:SetVertexColor(r,g,b,a)
   end

   local k = findKey(name)

   if (k == nil) then
   else
       spell.label = spell:CreateFontString()
       spell.label:SetPoint("TOPRIGHT", spell, "TOPRIGHT", 5, 5)
       spell.label:SetSize(36, 36)
       spell.label:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
       spell.label:SetText(k)
   end

   buttonfr[buttonpos] = f;
   buttonpos = buttonpos + 1

   return f, name
end

function Rotorbar.buttonActive(spell)
    spell:SetPoint("Left", frame, (blcurr  * 36) + 46, 0)
    spell:Show()
    if (spell.cooldownButton) then
        spell.showCool()
    end
    blcurr = blcurr + 1
end

function Rotorbar.resetButtons()
    for i = 0, (buttonpos - 1) do
        buttonfr[i]:Hide()
    end
    blcurr = 0;
end

whatsbound = {}
actionIndex = 1

function getBindings()
    for i = 1, GetNumBindings() do
        local commandName, binding1, binding2 = GetBinding(i)
        if (string.match(commandName, "ACTIONBUTTON") or string.match(commandName, "MULTIACTION")) then
            local key = binding2
            if (key == nil) then
            else
                if (string.match(key, "NUM")) then
                    key = "N" .. string.gsub(key, "%a*(%d*)", "%1")
                end

                if (string.match(key, "SHIFT")) then
                    key = "S" .. string.gsub(key, "%a*-(%d*)", "%1")
                end
            end
            whatsbound[actionIndex] = {}
            whatsbound[actionIndex].key = key
            whatsbound[actionIndex].command = commandName
            actionIndex = actionIndex + 1
        end
    end

    for i = 1, 24 do
        local maintype, actionid, subtype = GetActionInfo(i)
        if (maintype == "spell") then
            local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(actionid)
            whatsbound[i].spell = name
        end
    end
    for i = 25, 30 do
        local maintype, actionid, subtype = GetActionInfo(i)
        if (maintype == "spell") then
            local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(actionid)
            whatsbound[i + 23].spell = name
        end
    end
    for i = 31, 42 do
        local maintype, actionid, subtype = GetActionInfo(i)
        if (maintype == "spell") then
            local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(actionid)
        end
    end

    for i = 48, 60 do
        local maintype, actionid, subtype = GetActionInfo(i)
        if (maintype == "spell") then
            local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(actionid)
            whatsbound[i-13].spell = name
        end
    end

    for i = 61, 66 do
        local maintype, actionid, subtype = GetActionInfo(i)
        if (maintype == "spell") then
            local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(actionid)
            whatsbound[i-37].spell = name
        end
    end
end


function findKey(spell)
    for i = 1, actionIndex - 1 do
        if (whatsbound[i].spell == spell) then
            return whatsbound[i].key
        end
    end
end
