local frame = CreateFrame("Frame", "Rotorbar", UIParent);
local handler

mobsInCombat = {}

Rotorbar = {}

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

    if (tablelength(mobsInCombat) == 0) then
        if (IsSpellInRange(spell, "target")) then
            return 1
        else
            return 0
        end
    end

    local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(spell)

    for k, v in pairs(mobsInCombat) do
        if (v.range ~= -1 and v.range <= maxRange) then
            t = t + 1
        end
    end

    return t
end

function Rotorbar.targetsDebuffed(debuff)
    local t = 0

    for k, v in pairs(mobsInCombat) do
        if (v.debuff[debuff]) then
            t = t + 1
        end
    end

    return t
end

function Rotorbar.targetsNotDebuffed(debuff)
    local t = 0

    if (tablelength(mobsInCombat) == 0) then
        if (Rotorbar.debuffed(debuff, "target") == 0) then
            return 1
        else
            return 0
        end
    end

    for k, v in pairs(mobsInCombat) do
        if (not v.debuff[debuff]) then
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
        isTargetDummy())
end

function Rotorbar.isUsableCooldown(spell, talent)
    if (talent == nil or talent == true) then
        if (IsUsableSpell(spell)) then
            local start, duration = GetSpellCooldown(spell)
            local gstart, gduration = globalCooldown()
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

function Rotorbar.spellCasting()
    local name, subText, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("player")
    if (name ~= nil) then
        return name, startTime / 1000, (endTime - startTime) / 1000
    else
        name, subText, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo("player")
        if (name ~= nil) then
            return name, startTime / 1000, (endTime - startTime) / 1000
        end
    end
end

function Rotorbar.isCasting(spell)
    local name, start, duration = Rotorbar.spellCasting()
    return spell == name, start, duration
end


function Rotorbar.setIcons(num)
    frame:SetWidth((36*num) + 56)
end

function Rotorbar.equipmentIcon(slot)
    if (eq[slot] ~= nil and eq[slot].usable) then
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
    if (r ~= nil) then
        frame.icon:SetVertexColor(r,g,b,a)
        frame.icon:SetDesaturated(true)
    else
        frame.icon:SetDesaturated(false)
    end
end

function Rotorbar.runes()
    local count = 0
    for i = 1, 6 do
        if (GetRuneCount(i) ~= nil) then
            count = count + GetRuneCount(i)
        end
    end
    return count
end

function Rotorbar.flash(name,r,g,b,a)
    local f = Rotorbar.buttonTime(name,r,g,b,a)
    UIFrameFlash(f, .75, .25, 10000000, true, .5, 0)

    f:SetPoint("Left", UIParent, -50, -50)
    f:SetScript("OnHide", function(self)
        f:SetPoint("Left", UIParent, -50, -50)
    end)

    return f, name
end

function Rotorbar.cooldown(name,linkcool,cdfn)
    local f = Rotorbar.buttonTime(name,icon)
    f.cool = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cool:SetAllPoints()
    if (cdfn == nil) then
        cdfn = GetSpellCooldown
    end
    function f.showCool()
        local start, duration, enabled, modRate = cdfn(name)
        if (start ~= nil) then
            local spellleft = 0
            if (start > 0) then
                spellleft = (start+duration)-GetTime()
            end

            local gstart, gduration = globalCooldown()
            local gleft = 0

            if (gstart > 0) then
                gleft = (gstart+gduration)-GetTime()
            end

            if (linkcool == nil) then
                if (spellleft > gleft) then
                    f.cool:SetCooldown(start, duration, modRate)
                end
            else
                local linkstart, linkduration, linkenabled, linkmodRate = GetSpellCooldown(linkcool)
                local linkleft = 0

                if (linkstart > 0) then
                    linkleft = (linkstart+linkduration)-GetTime()
                end

                if (linkstart == nil or linkleft <= spellleft) then
                    if (spellleft > gleft) then
                        f.cool:SetCooldown(start, duration, modRate)
                    end
                else
                    if (linkleft > gleft) then
                        f.cool:SetCooldown(linkstart, linkduration, linkmodRate)
                    end
                end
            end
        end
    end
    return f, name
end

function Rotorbar.buttonTime(name,r,g,b,a)
    local f=CreateFrame("Frame",nil,frame)
    local spell = CreateFrame("Button",nil, f)
    f:SetSize(36,36)
    spell:SetSize(36,36)
    f:SetPoint("CENTER")
    spell:SetPoint("CENTER")
    f:Hide()
    f.cool = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cool:SetAllPoints()
    f.name = name
    local icon = sitexture(name)

    f.texture = f:CreateTexture("ARTWORK")
    f.texture:SetTexture(icon)
    f.texture:SetSize(36,36)
    f.texture:SetPoint("CENTER")

    if (r ~= nil) then
        f.texture:SetDesaturated(true)
        f.texture:SetVertexColor(r,g,b,a)
    else
        f.texture:SetDesaturated(false)
        f.texture:SetVertexColor(1,1,1,1)
    end

    local k = findKey(name)
    spell.label = spell:CreateFontString()
    spell.label:SetPoint("TOPRIGHT", spell, "TOPRIGHT", 5, 5)
    spell.label:SetSize(36, 36)
    spell.label:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
    spell.label:SetText(k)

    function f.updateKey()
        local k = findKey(name)
        spell.label:SetText(k)
    end

    function f.showCool()
        local start, duration, modRate = globalCooldown()
        if (start > 0) then
            f.cool:SetCooldown(start, duration, modRate)
        end
    end

    buttonfr[buttonpos] = f;
    buttonpos = buttonpos + 1

    return f, name
end

function Rotorbar.buttonActive(spell)
    spell:SetPoint("Left", frame, (blcurr  * 36) + 46, 0)
    spell:Show()
    spell.showCool()
    spell.updateKey()
    blcurr = blcurr + 1
end

function Rotorbar.resetButtons()
    for i = 0, (buttonpos - 1) do
        buttonfr[i]:Hide()
    end
    blcurr = 0;
end

frame:SetWidth(80+20)
frame:SetHeight(40+20)
frame:ClearAllPoints()
frame:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 36,
    edgeSize = 36,
    insets = {
        left = 11,
        right = 12,
        top = 12,
        bottom = 11
    }
})
frame:SetPoint("CENTER",UIParent)
frame:SetPoint("Top", UIParent, 0, -20)
frame:Show()

frame:SetMovable(true)
frame:EnableMouse(true)

buttonpos = 0
buttonfr = {}
blcurr = 0
gcdmade = false

eq = {}

registerEvents(frame)

function globalCooldown()
    return GetSpellCooldown(61304)
end

function showGCD()
    local start, duration, enabled, modRate = GetSpellCooldown(61304)
    local spell, st, dur = Rotorbar.spellCasting()
    if (spell ~= nil and dur > duration) then
        frame.cool:SetCooldown(st, dur)
    else
        frame.cool:SetCooldown(start, duration, modRate)
    end
end

function npcId(guid)
    if (guid  ~= nil) then
        local type, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", guid);
        return npc_id
    else
        return
    end
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function sitexture(_name)
    local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(_name)
    return icon
end

function equipmentUsable(slot)
    local start, duration, enable = GetInventoryItemCooldown("player", slot)

    if (enable == 1) then
        if (start == 0) then
            return true, true, 0
        else
            return true, false, ((start+duration)-GetTime())
        end
    else
        return false
    end
end

function equipmentInit(slot)
    local usable = equipmentUsable(slot)
    eq[slot] = { usable = usable }

    if (usable) then
        local id = GetInventoryItemID("player", slot)
        local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(id)
        eq[slot].icon = Rotorbar.buttonTime(name)
        eq[slot].icon.texture:SetTexture(GetInventoryItemTexture("player", slot))
        local function cooler()
            return GetInventoryItemCooldown("player", slot)
        end
        eq[slot].cool = Rotorbar.cooldown(name, nil, cooler)
        eq[slot].cool.texture:SetTexture(GetInventoryItemTexture("player", slot))
    end
end

whatsbound = {}
actionIndex = 1

function getBindings()
    for i = 1, GetNumBindings() do
        local commandName, binding1, binding2 = GetBinding(i)
        if (string.match(commandName, "ACTIONBUTTON") or string.match(commandName, "MULTIACTION")) then
            local key = binding2
            if (key ~= nil) then
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

    function readBinding(i,adjust)
        local maintype, actionid, subtype = GetActionInfo(i)
        if (maintype == "spell") then
            local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(actionid)
            whatsbound[i + adjust].spell = name
        elseif (maintype == "item") then
            local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(actionid)
            whatsbound[i + adjust].spell = name
        elseif (maintype == "macro") then
            local name, rank, spellID = GetMacroSpell(actionid)
            whatsbound[i + adjust].spell = name
        end
    end

    for i = 1, 24 do
        readBinding(i,0)
    end
    for i = 25, 30 do
        readBinding(i,23)
    end
    for i = 31, 42 do
        readBinding(i,0)
    end
    for i = 48, 60 do
        readBinding(i,-13)
    end
    for i = 61, 66 do
        readBinding(i,-37)
    end
end


function findKey(spell)
    for i = 1, actionIndex - 1 do
        if (whatsbound[i].spell == spell) then
            return whatsbound[i].key
        end
    end
end
