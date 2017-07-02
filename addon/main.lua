local frame, events = CreateFrame("Frame", "Rotorbar", UIParent), {};

local showIcons = {}
local debuffIcons = {}
local coolIcons = {}

Rotorbar = {
    class = UnitClass("player"),
    specialization = -1,
    equipment = {},

    _handler = nil,
    _mobsInCombat = {},
    _talents = {},
    _global = {
        start = 0,
        duration = 0
    },
    _spec = {}
}

function Rotorbar.startup()

end

function Rotorbar.refreshStart()
    Rotorbar._global = nil
    Rotorbar.resetIcons()
end

function Rotorbar.globalCooldown()
    if (Rotorbar._global == nil) then
        local start, duration = GetSpellCooldown(61304)
        Rotorbar._global = { start = start, duration = duration }
    end
    return Rotorbar._global.start, Rotorbar._global.duration
end

function Rotorbar.isTalent(name)
    return Rotorbar.currentSpec().talents[name] == nil or Rotorbar.currentSpec().talents[name] == true
end

function Rotorbar.currentSpec(spec)
    if (spec == nil) then
        return Rotorbar._spec[Rotorbar.specialization]
    else
        Rotorbar._spec[Rotorbar.specialization] = spec
    end
end

function Rotorbar.loadSpec(spec)
    Rotorbar.currentSpec(spec)
    Rotorbar.updateTalents()

    if (spec.loaded == nil) then
        if (spec.rotation == nil) then
            spec.always = true
            spec.rotation = function() end
            spec.cooldownsOnly = true
        else
            spec.always = false
            spec.cooldownsOnly = false
        end

        spec.cooldowns = {}
        spec.icons()
        spec.loaded = true
    end

    spec.class()
    spec.rotation()
end

function Rotorbar.updateTalents()
    Rotorbar.currentSpec().talents = {}
    for tcol = 1,3 do
        for ttier = 1,7 do
            local talentID, name, texture, selected = GetTalentInfo(ttier,tcol,GetActiveSpecGroup())
            Rotorbar.currentSpec().talents[name] = selected
        end
    end
end

function Rotorbar.debuffed(_name, target)
    if (target == nil) then
        target = "target"
    end

    if (UnitGUID(target) == nil) then
        return -1, 0
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

function Rotorbar.targets()
    return tablelength(Rotorbar._mobsInCombat)
end

function Rotorbar.targetsInRange(spell)
    local t = 0

    if (tablelength(Rotorbar._mobsInCombat) == 0) then
        if (IsSpellInRange(spell, "target")) then
            return 1
        else
            return 0
        end
    end

    local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(spell)

    for k, v in pairs(Rotorbar._mobsInCombat) do
        if (v.range ~= -1 and v.range <= maxRange) then
            t = t + 1
        end
    end

    return t
end

function Rotorbar.targetsDebuffed(debuff)
    local t = 0

    for k, v in pairs(Rotorbar._mobsInCombat) do
        if (v.debuff[debuff]) then
            t = t + 1
        end
    end

    return t
end

function Rotorbar.targetsNotDebuffed(debuff)
    local t = 0

    if (tablelength(Rotorbar._mobsInCombat) == 0) then
        if (Rotorbar.debuffed(debuff, "target") == 0) then
            return 1
        else
            return 0
        end
    end

    for k, v in pairs(Rotorbar._mobsInCombat) do
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

function Rotorbar.isUsableCooldown(spell)
    if (Rotorbar.isTalent(spell)) then
        if (IsUsableSpell(spell)) then
            local start, duration = GetSpellCooldown(spell)
            local gstart, gduration = Rotorbar.globalCooldown()
            if (start == 0) then
                return true, true, 0
            else
                local cdleft = (start+duration)-GetTime()
                if (cdleft <= (gstart+gduration)-GetTime()) then
                    return true, true, 0
                else
                    return false, true, cdleft
                end
            end
        else
            return false, true, -1
        end
    else
        return false, false, -1
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

function Rotorbar.classIcon(r, g, b, a)
    if (not gcdmade) then
        frame.gcd = CreateFrame("Frame", nil, frame)
        frame.gcd:SetSize(36,36)
        frame.gcd:SetPoint("Left", frame, 10, 0)

        frame.icon = frame.gcd:CreateTexture(nil,"CENTER")
        frame.icon:SetAllPoints()

        frame.cool = CreateFrame("Cooldown", nil, frame.gcd, "CooldownFrameTemplate")
        frame.cool:SetAllPoints()

        frame.gcd.showCool = function()
            local start, duration = Rotorbar.globalCooldown()
            local spell, st, dur = Rotorbar.spellCasting()
            if (spell ~= nil and st + dur > start + duration) then
                if (frame.gcd.ends ~= st + dur ) then
                    frame.cool:SetCooldown(st, dur)
                    frame.gcd.ends = st + dur
                end
            else
                if (frame.gcd.ends ~= start + duration ) then
                    frame.cool:SetCooldown(start, duration)
                    frame.gcd.ends = start + duration
                end
            end
        end

        frame.gcd.type = "gcd"
        frame.gcd.ends = 0
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
        frame.icon:SetVertexColor(1,1,1,1)
        frame.icon:SetDesaturated(false)
    end

    Rotorbar.gcd = frame.gcd
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
    UIFrameFlash(f, .75, .25, 100000, true, .5, 0)

    f:SetPoint("Left", UIParent, -50, -50)
    f:SetScript("OnHide", function(self)
        f:SetPoint("Left", UIParent, -50, -50)
    end)

    return f, name
end

function Rotorbar.linkedCooldown(name, link)
    local f = Rotorbar.cooldown(name)

    function f.showCool()
        local linkstart, linkduration, linkenabled = GetSpellCooldown(link)
        local start, duration, enabled = GetSpellCooldown(name)

        if (Rotorbar.isTalent(name) and Rotorbar.isTalent(link)) then
            local gstart, gduration = Rotorbar.globalCooldown()

            if (gstart+gduration >= start+duration) then
                start = 0
                duration = 0
            end

            if (linkstart+linkduration >= start+duration) then
                start = linkstart
                duration = linkduration
            end

            if (start+duration ~= f.ends) then
                if (start ~= 0) then
                    f.texture:SetDesaturation(true)
                    f.texture:SetVertexColor(1,1,1,1)
                    f.vis = true
                else
                    f.texture:SetDesaturation(false)
                    f.vis = f.always
                end

                f.cool:SetCooldown(start, duration)
                f.ends = start + duration
            end
        else
            f.vis = false
        end

        return f.vis
    end

end

function Rotorbar.cooldown(name, talent)
    local f = Rotorbar._basebutton(name)

    f.type = "cooldown"

    f.cool = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cool:SetAllPoints()
    f.ends = 0
    f.always = Rotorbar.currentSpec().always
    f.vis = (Rotorbar.isTalent(name) and (f.always == true))

    function f.showCool()
        local start, duration, enabled = GetSpellCooldown(name)

        if (Rotorbar.isTalent(name) and start ~= nil) then
            local gstart, gduration = Rotorbar.globalCooldown()

            if (gstart+gduration >= start+duration) then
                start = 0
                duration = 0
            end

            if (start+duration ~= f.ends) then
                if (start ~= 0) then
                    f.texture:SetDesaturation(true)
                    f.texture:SetVertexColor(1,1,1,1)
                    f.vis = true
                else
                    f.texture:SetDesaturation(false)
                    f.vis = f.always
                end

                f.cool:SetCooldown(start, duration)
                f.ends = start + duration
            end
        else
            f.vis = false
        end

        return f.vis
    end

    table.insert(Rotorbar.currentSpec().cooldowns, f)
    return f, name
end

function Rotorbar.debuffIcon(name,aura)
    if (aura == nil) then
        aura = name
    end

    local f=CreateFrame("Frame",nil,frame)
    f:SetSize(36,36)
    f:SetPoint("CENTER")
    f:Hide()
    f.name = name
    f.type = "debuff"
    local icon = sitexture(aura)

    f.texture = f:CreateTexture("ARTWORK")
    f.texture:SetTexture(icon)
    f.texture:SetSize(36,36)
    f.texture:SetPoint("CENTER")

    table.insert(buttonfr, f)

    f.label = f:CreateFontString()
    f.label:SetPoint("CENTER", f)
    f.label:SetSize(36, 36)
    f.label:SetFont("Fonts\\ARIALN.TTF", 20, "OUTLINE")

    function f.refreshCount()
        local k = Rotorbar.targetsNotDebuffed(f.name)
        if (k == 0) then
            f.label:SetText("")
            f.texture:SetDesaturated(true)
        else
            f.label:SetText(k)
            f.texture:SetDesaturated(false)
        end
    end

    function f.verifyTexture()
        if (f.texture:GetTexture() == nil) then
            f.texture:SetTexture(sitexture(aura))
        end
    end

    return f, name
end

function Rotorbar.buttonTime(name,r,g,b,a)
    local f = Rotorbar._basebutton(name,r,g,b,a)
    local k = findKey(name)

    f.type = "icon"

    f.label = f:CreateFontString()
    f.label:SetPoint("TOPRIGHT", f, "TOPRIGHT", 5, 5)
    f.label:SetSize(36, 36)
    f.label:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
    f.label:SetText(k)


    function f.updateKey()
        local k = findKey(name)
        f.label:SetText(k)
    end

    return f
end

function Rotorbar._basebutton(name,r,g,b,a)
    local f=CreateFrame("Frame",nil,frame)

    f:SetSize(36,36)
    f:SetPoint("CENTER")
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

    function f.verifyTexture()
        if (f.texture:GetTexture() == nil) then
            f.texture:SetTexture(sitexture(name))
        end
    end

    function f.showCool()
        local casting, cstart, cdur = Rotorbar.isCasting(name)
        if (casting) then
            f.cool:SetCooldown(cstart, cdur)
        else
           -- local start, duration, modRate = Rotorbar.globalCooldown()
           -- if (start > 0) then
            --    f.cool:SetCooldown(start, duration, modRate)
            --end
        end
    end

    table.insert(buttonfr, f)

    return f, name
end


function Rotorbar.itemIcon(name,icon)
    local f = Rotorbar._itemBase(name,icon)
    f.label = f:CreateFontString()
    f.label:SetPoint("TOPRIGHT", f, "TOPRIGHT", 5, 5)
    f.label:SetSize(36, 36)
    f.label:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
    f.label:SetText(k)

    function f.updateKey()
        local k = findKey(name)
        f.label:SetText(k)
    end

    return f, name
end

function Rotorbar._itemBase(name,icon)
    local f=CreateFrame("Frame",nil,frame)

    f:SetSize(36,36)
    f:SetPoint("CENTER")
    f:Hide()
    f.cool = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cool:SetAllPoints()
    f.name = name
    f.type = "Item"

    f.texture = f:CreateTexture("ARTWORK")
    f.texture:SetTexture(icon)
    f.texture:SetSize(36,36)
    f.texture:SetPoint("CENTER")

    table.insert(buttonfr, f)

    return f, name
end

function Rotorbar.itemCooldown(name,slot,icon)
    local f = Rotorbar._itemBase(name,icon)

    f.type = "item-cooldown"

    f.cool = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cool:SetAllPoints()

    f.ends = 0

    function f.showCool()
        local start, duration, enabled = GetInventoryItemCooldown("player", slot)

            --local gstart, gduration = Rotorbar.globalCooldown()

            --if (gstart+gduration >= start+duration) then
            --    start = 0
            --    duration = 0
            --end

            if (start+duration ~= f.ends) then
                if (start ~= 0) then
                    f.texture:SetDesaturation(true)
                    f.texture:SetVertexColor(1,1,1,1)
                else
                    f.texture:SetDesaturation(false)
                end

                f.cool:SetCooldown(start, duration)
                f.ends = start + duration
            end

    end

    return f, name
end

function Rotorbar.resetIcons()
    showIcons = {}
    debuffIcons = {}
    coolIcons = {}
end

function Rotorbar.buttonActive(spell, fr, index)
    spell:SetPoint("LEFT", fr, ((index - 1)  * 36) + 12, 0)
    spell:Show()

    if (spell.type == "debuff") then
        spell.refreshCount()
    end

    if (spell.showCool ~= nil) then
        spell.showCool()
    end
    if (spell.updateKey ~= nil) then
        spell.updateKey()
    end
    if (spell.verifyTexture ~= nil) then
        spell.verifyTexture()
    end
end

function Rotorbar.refresh()
    for i = 1, tablelength(buttonfr) do
        buttonfr[i]:Hide()
    end

    local rot = 0
    local rm = 0
    local deb = 0
    local dm = 0
    local cool = 0

    if (tablelength(showIcons)) then
        rot = (tablelength(showIcons) * 36)
        if (rot > 0) then
            rot = rot + 24
            rm = 8
        end
    end
    if (tablelength(debuffIcons)) then
        deb = (tablelength(debuffIcons) * 36)
        if (deb > 0) then
            deb = deb + 24
            dm = 8
        end
    end
    if (tablelength(coolIcons)) then
        cool = (tablelength(coolIcons) * 36)
        if (cool > 0) then cool = cool + 24 end
    end

    frame:SetWidth((rot - rm) + (deb - dm) + cool)

    if (rot == 0) then
        frame.rotation:Hide()
    else
        frame.rotation:Show()
        frame.rotation:SetPoint("LEFT", frame, 0, 0)
        frame.rotation:SetWidth(rot)
        for i = 1, tablelength(showIcons)  do
            Rotorbar.buttonActive(showIcons[i], frame.rotation, i)
        end
    end

    if (deb == 0) then
        frame.debuffs:Hide()
    else
        frame.debuffs:Show()
        frame.debuffs:SetPoint("LEFT", frame, rot - rm, 0)
        frame.debuffs:SetWidth(deb)
        for i = 1, tablelength(debuffIcons) do
            Rotorbar.buttonActive(debuffIcons[i], frame.debuffs, i)
        end
    end

    if (cool == 0) then
        frame.cooldowns:Hide()
    else
        frame.cooldowns:Show()
        frame.cooldowns:SetPoint("LEFT", frame, (rot - rm) + (deb - dm), 0)
        frame.cooldowns:SetWidth(cool)
        for i = 1, tablelength(coolIcons) do
            Rotorbar.buttonActive(coolIcons[i], frame.cooldowns, i)
        end
    end

end

function Rotorbar.showNext (icon)
    table.insert(showIcons, icon)
end

function Rotorbar.showDebuff (icon)
    table.insert(debuffIcons, icon)
end

function Rotorbar.showCooldown (icon)
    table.insert(coolIcons, icon)
end

function frameback(fr)
    fr:SetHeight(40+20)
    fr:SetBackdrop({
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
end

frame:SetWidth(40+20)
frame:SetHeight(40+20)
frame:ClearAllPoints()

frame:SetPoint("CENTER",UIParent)
frame:SetPoint("Top", UIParent, 0, -20)
frame:Show()

frame:SetMovable(true)
frame:EnableMouse(true)

frame.cooldowns = CreateFrame("Frame", "Rotorbar_Cooldowns", frame)
frameback(frame.cooldowns)

frame.debuffs = CreateFrame("Frame", "Rotorbar_Debuffs", frame)
frameback(frame.debuffs)

frame.rotation = CreateFrame("Frame", "Rotorbar_Rotation", frame)
frameback(frame.rotation)

local handler = registerEvents(events, frame)
local started = false

function frame:onUpdate(sinceLastUpdate)
    self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;

    if (self.sinceLastUpdate >= 3 or (started and self.sinceLastUpdate >= .35)) then
        handler()
        started = true
        self.sinceLastUpdate = 0;
    end
end

frame:SetScript("OnUpdate",frame.onUpdate)

buttonfr = {}
gcdmade = false

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

    local gstart, gduration = Rotorbar.globalCooldown()

    if (enable == 1) then
        if (start == 0 or duration <= gduration) then
            return true, true, 0
        else
            return true, false, ((start+duration)-GetTime())
        end
    else
        return false
    end
end

function equipmentInit(slot)
    Rotorbar.equipment[slot] = {}
    local id = GetInventoryItemID("player", slot)

    Rotorbar.equipment[slot].show = function()
        local id = GetInventoryItemID("player", slot)
        local usable, ready, left = equipmentUsable(slot)

        if (usable and Rotorbar.equipment[slot].id ~= id) then

            local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(id)

            if (name ~= nil) then
                Rotorbar.equipment[slot].id = id
                Rotorbar.equipment[slot].name = name

                if (Rotorbar.equipment[slot].icon == nil) then
                    Rotorbar.equipment[slot].icon = Rotorbar.itemIcon(name, texture)
                    Rotorbar.equipment[slot].cool = Rotorbar.itemCooldown(name, slot, texture)
                end
            end
        end

        if (Rotorbar.equipment[slot].name ~= nil) then
            return usable, ready, Rotorbar.equipment[slot].icon, Rotorbar.equipment[slot].cool
        else
            return false
        end
    end
end

whatsbound = {
    actionbar = {},
    actionbar2 = {},
    multiactionbar1 = {},
    multiactionbar2 = {},
    multiactionbar3 = {},
    multiactionbar4 = {},
    druid = {
        cat = {},
        bear = {},
        moonkin = {},
        prowl = {}
    }
}

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

                if (string.match(key, "CTRL")) then
                    key = "C" .. string.gsub(key, "%a*-(%d*)", "%1")
                end

                if (string.match(key, "ALT")) then
                    key = "A" .. string.gsub(key, "%a*-(%d*)", "%1")
                end

                if (string.match(key, "BUTTON")) then
                    key = "M" .. string.gsub(key, "%a*(%d*)", "%1")
                end
            end

            if (string.match(commandName, "ACTIONBUTTON")) then
                table.insert(whatsbound.actionbar, {key = key, command = commandName})
                table.insert(whatsbound.actionbar2, {key = key, command = commandName})
                table.insert(whatsbound.druid.cat, {key = key, command = commandName})
                table.insert(whatsbound.druid.prowl, {key = key, command = commandName})
                table.insert(whatsbound.druid.bear, {key = key, command = commandName})
                table.insert(whatsbound.druid.moonkin, {key = key, command = commandName})

            elseif (string.match(commandName, "MULTIACTIONBAR1")) then
                table.insert(whatsbound.multiactionbar1, {key = key, command = commandName})
            elseif (string.match(commandName, "MULTIACTIONBAR2")) then
                table.insert(whatsbound.multiactionbar2, {key = key, command = commandName})
            elseif (string.match(commandName, "MULTIACTIONBAR3")) then
                table.insert(whatsbound.multiactionbar3, {key = key, command = commandName})
            elseif (string.match(commandName, "MULTIACTIONBAR4")) then
                table.insert(whatsbound.multiactionbar4, {key = key, command = commandName})
            end
         end
    end

    function readBinding(i,adjust,set)
        local maintype, actionid, subtype = GetActionInfo(i+adjust)

        if (maintype == "spell") then
            local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(actionid)
            set[i].spell = name
        elseif (maintype == "item") then
            local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(actionid)
            set[i].spell = name
        elseif (maintype == "macro") then
            local name, rank, spellID = GetMacroSpell(actionid)
            set[i].spell = name
        end
    end

    for i = 1, 12 do
        readBinding(i,0,whatsbound.actionbar)
    end
    for i = 1, 12 do -- 13-24
        readBinding(i,12,whatsbound.actionbar2)
    end
    for i = 1, 12 do -- 25-36
        readBinding(i,24,whatsbound.multiactionbar3)
    end
    for i = 1, 12 do -- 37-48
        readBinding(i,36,whatsbound.multiactionbar4)
    end
    for i = 1, 12 do -- 49-60
        readBinding(i,48,whatsbound.multiactionbar2)
    end
    for i = 1, 12 do -- 61-72
        readBinding(i,60,whatsbound.multiactionbar1)
    end

    if (Rotorbar.class == "Druid") then
        for i = 1, 12 do -- 73-84
            readBinding(i,72,whatsbound.druid.cat)
        end
        for i = 1, 12 do -- 85-96
            readBinding(i,84,whatsbound.druid.prowl)
        end
        for i = 1, 12 do -- 97-108
            readBinding(i,96,whatsbound.druid.bear)
        end
        for i = 1, 12 do -- 109-120
            readBinding(i,108,whatsbound.druid.moonkin)
        end
    end
end


function findKey(spell)
    if (spell ~= nil) then
        local actionbar = whatsbound.actionbar

        if (Rotorbar.class == "Druid") then
            if (GetShapeshiftForm() == 1) then
                actionbar = whatsbound.druid.bear

            elseif (GetShapeshiftForm() == 2) then
                if (Rotorbar.buffed("Prowl") == 0) then
                    actionbar = whatsbound.druid.cat
                else
                    actionbar = whatsbound.druid.prowl
                end

            elseif (GetShapeshiftForm() == 5) then
                actionbar = whatsbound.druid.moonkin
            end
        end

        for i = 1, 12 do
            if (actionbar[i].spell == spell) then
                return actionbar[i].key
            end
        end

        for i = 1, 12 do
            if (whatsbound.multiactionbar1[i].spell == spell) then
                return whatsbound.multiactionbar1[i].key
            end
        end
        for i = 1, 12 do
            if (whatsbound.multiactionbar2[i].spell == spell) then
                return whatsbound.multiactionbar2[i].key
            end
        end
        for i = 1, 12 do
            if (whatsbound.multiactionbar3[i].spell == spell) then
                return whatsbound.multiactionbar3[i].key
            end
        end
        for i = 1, 12 do
            if (whatsbound.multiactionbar4[i].spell == spell) then
                return whatsbound.multiactionbar4[i].key
            end
        end
    end
end
