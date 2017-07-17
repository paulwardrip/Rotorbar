local frame, events = CreateFrame("Frame", "Rotorbar", UIParent), {};

local showIcons = {}
local debuffIcons = {}
local coolIcons = {}

Rotorbar = {
    class = UnitClass("player"),
    specialization = -1,
    equipment = {},
    damageCounter = {},
    _handler = nil,
    _mobsInCombat = {},
    _mobTargetNum = 0,
    _guidtounit = {},
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
            if (spec.alwaysShowCooldowns ~= nil) then
                spec.always = spec.alwaysShowCooldowns
            else
                spec.always = false
            end
            spec.cooldownsOnly = false
        end

        spec.debuffIcons = {}
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

function Rotorbar.petBuffed(_name)
    local name, rank, icon, count, dispelType, duration, expires, caster = UnitBuff("pet", _name)

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
        if (IsSpellInRange(spell, "target") and not UnitIsDead("target") and UnitCanAttack("player","target")) then
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
        if (Rotorbar.debuffed(debuff, "target") == 0 and not UnitIsDead("target") and UnitCanAttack("player","target")) then
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
                return true, true, 0, GetSpellCharges(spell)
            else
                local cdleft = (start+duration)-GetTime()
                if (cdleft <= (gstart+gduration)-GetTime()) then
                    return true, true, 0, GetSpellCharges(spell)
                else
                    return false, true, cdleft, 0
                end
            end
        else
            return false, true, -1, -1
        end
    else
        return false, false, -1, -1
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

function Rotorbar.runes()
    local count = 0
    for i = 1, 6 do
        if (GetRuneCount(i) ~= nil) then
            count = count + GetRuneCount(i)
        end
    end
    return count
end

function Rotorbar.incomingIcon()
    frame.incoming = CreateFrame("Frame", nil, frame)
    frame.incoming:SetSize((ICON_SIZE * 2)+(BORDER_SIZE * 2),ICON_SIZE+(BORDER_SIZE * 2))
    frameback(frame.incoming)

    frame.incoming.color={}
    frame.incoming.label={}

    function setup(x,f,i)
        frame.incoming.color[x] = frame.incoming:CreateTexture("ARTWORK")
        frame.incoming.color[x]:SetTexture("Interface\\ICONS\\Ability_Defend")
        frame.incoming.color[x]:SetSize(i,i)
        frame.incoming.color[x]:SetPoint("CENTER", frame.incoming)
        frame.incoming.color[x]:SetDesaturated(true)
        frame.incoming.color[x]:SetVertexColor(1,1,1,.5)

        frame.incoming.label[x] = frame.incoming:CreateFontString()
        frame.incoming.label[x]:SetPoint("CENTER", frame.incoming)
        frame.incoming.label[x]:SetSize(ICON_SIZE, ICON_SIZE)
        frame.incoming.label[x]:SetFont("Fonts\\ARIALN.TTF", f, "OUTLINE")
    end

    setup(1, 15, ICON_SIZE)
    setup(2, 12, ICON_SIZE - 4)

    frame.incoming.label[1]:SetPoint("LEFT", frame.incoming, BORDER_SIZE, 0)
    frame.incoming.label[2]:SetPoint("LEFT", frame.incoming, BORDER_SIZE + ICON_SIZE, 0)
    frame.incoming.color[1]:SetPoint("LEFT", frame.incoming, BORDER_SIZE, 0)
    frame.incoming.color[2]:SetPoint("LEFT", frame.incoming, BORDER_SIZE + ICON_SIZE + 6, 2)

    function frame.incoming.draw(inco)
        if (inco == nil) then
            frame.incoming.label[1]:SetText("")
            frame.incoming.color[1]:SetVertexColor(1,1,1,.5)
            frame.incoming.label[2]:SetText("")
            frame.incoming.color[2]:SetVertexColor(1,1,1,.5)

        else
            local x = 1
            if (not inco.target) then
                x = 2
            end

            if (inco.school == 1) then
                frame.incoming.label[x]:SetText("Ph")
                frame.incoming.color[x]:SetVertexColor(.75,.75,.75,1)

            elseif (inco.school == 2) then
                frame.incoming.label[x]:SetText("Ho")
                frame.incoming.color[x]:SetVertexColor(1.00, 0.90, 0.50, 1)

            elseif (inco.school == 4) then
                frame.incoming.label[x]:SetText("Fi")
                frame.incoming.color[x]:SetVertexColor(1.00, 0.50, 0.00, 1)

            elseif (inco.school == 8) then
                frame.incoming.label[x]:SetText("Na")
                frame.incoming.color[x]:SetVertexColor (0.30, 1.00, 0.30, 1)

            elseif (inco.school == 16) then
                frame.incoming.label[x]:SetText("Fr")
                frame.incoming.color[x]:SetVertexColor (0.50, 1.00, 1.00, 1)

            elseif (inco.school == 32) then
                frame.incoming.label[x]:SetText("Sh")
                frame.incoming.color[x]:SetVertexColor (0.50, 0.50, 1.00, 1)

            elseif (inco.school == 64) then
                frame.incoming.label[x]:SetText("Ar")
                frame.incoming.color[x]:SetVertexColor (1.00, 0.50, 1.00, 1)

            else
                frame.incoming.label[x]:SetText("**")
                frame.incoming.color[x]:SetVertexColor (1.0, 1.0, 1.0, 1)
            end

            if (inco ~= nil and inco.cast) then
                UIFrameFlash(frame.incoming.color[x], .25, .25, 1.25, true, 0, 0)
            end
        end

    end
end

function Rotorbar.classIcon(r, g, b, a)
    if (not gcdmade) then
        frame.gcd = CreateFrame("Frame", nil, frame)
        frame.gcd:SetSize(ICON_SIZE,ICON_SIZE)

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
    frame.gcd.ident = Rotorbar.currentSpec().name .. "-GCD"
end

function Rotorbar.flash(name, proc)
    local f = Rotorbar.buttonTime(name, proc)
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

function Rotorbar.cooldown(name)
    local f = Rotorbar._basebutton(name, "Cooldown")

    f.type = "cooldown"

    f.cool = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cool:SetAllPoints()
    f.ends = 0
    f.always = Rotorbar.currentSpec().always
    f.vis = (Rotorbar.isTalent(name) and (f.always == true))


    function f.ifNotTalent(t)
        f.notalent = t
    end

    function f.isRelevant()
        if (f.notalent ~= nil) then
            return (not Rotorbar.isTalent(f.notalent))
        else
            return (Rotorbar.isTalent(f.name))
        end
    end

    function f.showCool()
        local start, duration, enabled = GetSpellCooldown(name)

        if (f.isRelevant() and start ~= nil) then
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

    f.ident = Rotorbar.currentSpec().name .."-Debuff-" .. name
    f:SetSize(ICON_SIZE,ICON_SIZE)
    f:SetPoint("CENTER")
    f:Hide()
    f.name = name
    f.type = "debuff"
    local icon = Rotorbar._texture(aura)

    f.texture = f:CreateTexture("ARTWORK")
    f.texture:SetTexture(icon)
    f.texture:SetSize(ICON_SIZE,ICON_SIZE)
    f.texture:SetPoint("CENTER")

--    table.insert(buttonfr, f)

    f.label = f:CreateFontString()
    f.label:SetPoint("CENTER", f)
    f.label:SetSize(ICON_SIZE, ICON_SIZE)
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
            f.texture:SetTexture(Rotorbar._texture(aura))
        end
    end

    function f.ifNotTalent(t)
        f.notalent = t
    end

    function f.isRelevant()
        if (f.notalent ~= nil) then
            return (not Rotorbar.isTalent(f.notalent))
        else
            return (Rotorbar.isTalent(f.name))
        end
    end

    table.insert(Rotorbar.currentSpec().debuffIcons, f)
    return f, name
end

function Rotorbar.buttonTime(name, proc)
    local f = Rotorbar._basebutton(name, proc)
    local k = findKey(name)


    f.type = "icon"

    f.label = f:CreateFontString()
    f.label:SetPoint("TOPRIGHT", f, "TOPRIGHT", 5, 5)
    f.label:SetSize(ICON_SIZE, ICON_SIZE)
    f.label:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
    f.label:SetText(k)

    function f.updateKey()
        local k = findKey(name)
        f.label:SetText(k)
    end

    return f
end

function Rotorbar._basebutton(name, proc)
    local f=CreateFrame("Frame",nil,frame)

    if (proc ~= nil) then
        f.ident = Rotorbar.currentSpec().name .. "-" .. name .. "-" .. proc
    else
        f.ident = Rotorbar.currentSpec().name .. "-" .. name
    end

    f:SetSize(ICON_SIZE,ICON_SIZE)
    f:SetPoint("CENTER")
    f:Hide()
    f.cool = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cool:SetAllPoints()
    f.name = name
    local icon = Rotorbar._texture(name)

    f.texture = f:CreateTexture("ARTWORK")
    f.texture:SetTexture(icon)
    f.texture:SetSize(ICON_SIZE,ICON_SIZE)
    f.texture:SetPoint("CENTER")

    function f.verifyTexture()
        if (f.texture:GetTexture() == nil) then
            f.texture:SetTexture(Rotorbar._texture(name))
        end
    end

    function f.color(r,g,b,a)
        if (r ~= nil) then
            f.texture:SetDesaturated(true)
            f.texture:SetVertexColor(r,g,b,a)
        else
            f.texture:SetDesaturated(false)
            f.texture:SetVertexColor(1,1,1,1)
        end
        return f
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

 --   table.insert(buttonfr, f)

    return f, name
end


function Rotorbar.itemIcon(name,slot,icon)
    local f = Rotorbar._itemBase(name,icon)
    f.label = f:CreateFontString()
    f.label:SetPoint("TOPRIGHT", f, "TOPRIGHT", 5, 5)
    f.label:SetSize(ICON_SIZE, ICON_SIZE)
    f.label:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
    f.label:SetText(k)
    f.slot = slot

    function f.updateKey()
        local k = findKey(name)
        f.label:SetText(k)
    end

    function f.updateGear(name,texture)
        f.name = name
        f.texture:SetTexture(texture)
        f.updateKey()
    end

    return f, name
end

function Rotorbar._itemBase(name,icon)
    local f=CreateFrame("Frame",nil,frame)

    f:SetSize(ICON_SIZE,ICON_SIZE)
    f:SetPoint("CENTER")
    f:Hide()
    f.cool = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cool:SetAllPoints()
    f.name = name
    f.type = "Item"

    f.ident = "Equipment-" .. name

    f.texture = f:CreateTexture("ARTWORK")
    f.texture:SetTexture(icon)
    f.texture:SetSize(ICON_SIZE,ICON_SIZE)
    f.texture:SetPoint("CENTER")

--    table.insert(buttonfr, f)

    return f, name
end

function Rotorbar.itemCooldown(name,slot,icon)
    local f = Rotorbar._itemBase(name,icon)

    f.type = "item-cooldown"

    f.cool = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cool:SetAllPoints()
    f.slot = slot
    f.ends = 0

    function f.updateGear(name,texture)
        f.name = name
        f.texture:SetTexture(texture)
    end

    function f.showCool()
        local start, duration, enabled = GetInventoryItemCooldown("player", f.slot)

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
    Rotorbar._lastIcons = showIcons
    Rotorbar._lastCool = coolIcons
    showIcons = {}
    coolIcons = {}
end

function Rotorbar.createLogger()
    local f  = CreateFrame("Frame", "RotorLogFrame", UIParent)
    f.width  = 720
    f.height = 480
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetSize(f.width, f.height)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true,
        tileSize = 32,
        edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    f:SetBackdropColor(0, 0, 0, 1)
    f:EnableMouse(true)
    f:EnableMouseWheel(true)

    -- Make movable/resizable
    f:SetMovable(true)
    f:SetResizable(enable)
    f:SetMinResize(100, 100)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    tinsert(UISpecialFrames, "RotorLogFrame")

    -- Close button
    local closeButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeButton:SetPoint("BOTTOM", 0, 10)
    closeButton:SetHeight(25)
    closeButton:SetWidth(70)
    closeButton:SetText(CLOSE)
    closeButton:SetScript("OnClick", function(self)
        HideParentPanel(self)
    end)
    f.closeButton = closeButton

    -- ScrollingMessageFrame
    local messageFrame = CreateFrame("ScrollingMessageFrame", nil, f)
    messageFrame:SetPoint("CENTER", 15, 10)
    messageFrame:SetSize(f.width, f.height - 50)
    messageFrame:SetFontObject(GameFontNormal)
    messageFrame:SetTextColor(1, 1, 1, 1) -- default color
    messageFrame:SetJustifyH("LEFT")
    messageFrame:SetHyperlinksEnabled(true)
    messageFrame:SetFading(false)
    messageFrame:SetMaxLines(10000)
    f.messageFrame = messageFrame

    -------------------------------------------------------------------------------
    -- Scroll bar
    -------------------------------------------------------------------------------
    local scrollBar = CreateFrame("Slider", nil, f, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("RIGHT", f, "RIGHT", -10, 10)
    scrollBar:SetSize(30, f.height - 90)
    scrollBar:SetMinMaxValues(0, 999)
    scrollBar:SetValueStep(1)
    scrollBar.scrollStep = 1
    f.scrollBar = scrollBar

    scrollBar:SetScript("OnValueChanged", function(self, value)
        messageFrame:SetScrollOffset(select(2, scrollBar:GetMinMaxValues()) - value)
    end)

    scrollBar:SetValue(select(2, scrollBar:GetMinMaxValues()))

    f:SetScript("OnMouseWheel", function(self, delta)
        local cur_val = scrollBar:GetValue()
        local min_val, max_val = scrollBar:GetMinMaxValues()

        if delta < 0 and cur_val < max_val then
            cur_val = math.min(max_val, cur_val + 1)
            scrollBar:SetValue(cur_val)
        elseif delta > 0 and cur_val > min_val then
            cur_val = math.max(min_val, cur_val - 1)
            scrollBar:SetValue(cur_val)
        end
    end)

    Rotorbar.logFrame = f
end

Rotorbar.createLogger()

function Rotorbar.log(msg)
    Rotorbar.logFrame.messageFrame:AddMessage(msg)
end

function Rotorbar.combatStart()
    Rotorbar.logFrame.messageFrame:AddMessage(date() .. " Combat Started")
end

function Rotorbar.combatEnd()
    for k, v in pairs(Rotorbar.damageCounter) do
        local indic
        if (v.main) then
            indic = "Primary Target"
        else
            indic = "Enemy #" .. v.index
        end
        local dps = v.damage / (GetTime() - v.start)
        local dpstr
        if (dps > 1000000) then
            dpstr = Rotorbar.round(dps / 1000000, 2) .. "M"
        else
            dpstr = Rotorbar.round(dps / 1000, 2) .. "K"
        end
        Rotorbar.logFrame.messageFrame:AddMessage(date() .. " DPS on " .. indic .. ": " .. dpstr , .5, 0, 0)
    end

    Rotorbar.logFrame.messageFrame:AddMessage(date() .. " Combat Ended")
    Rotorbar.log("------------------------------")
    Rotorbar.damageCounter = {}
    Rotorbar._mobTargetNum = 0
end

function Rotorbar.target(name)
    Rotorbar.logFrame.messageFrame:AddMessage(date() .. " Primary Target " .. name)
end

function Rotorbar.getCounter(guid, main, index)
    if (Rotorbar.damageCounter[guid] == nil) then
        Rotorbar.damageCounter[guid] = {
            start = GetTime(),
            main = main,
            index = index,
            damage = 0
        }
    end
    return Rotorbar.damageCounter[guid]
end

function Rotorbar.kill(guid, index)
    local main = (UnitGUID("target") == guid)
    local dc = Rotorbar.getCounter(guid, main, index)
    local indic
    if (main) then
        indic = "Primary Target"
    else
        indic = "Enemy #" .. index
    end
    local dps = dc.damage / (GetTime() - dc.start)
    local dpstr
    if (dps > 1000000) then
        dpstr = Rotorbar.round(dps / 1000000, 2) .. "M"
    else
        dpstr = Rotorbar.round(dps / 1000, 2) .. "K"
    end
    Rotorbar.logFrame.messageFrame:AddMessage(date() .. indic .. " Killed! DPS on this target: " .. dpstr , 1, 0, 0)
    Rotorbar.damageCounter[guid] = nil
end

function Rotorbar.dot(spell, amount, guid, index)
    local main = (UnitGUID("target") == guid)
    local dc = Rotorbar.getCounter(guid,main,index)
    dc.damage = dc.damage + amount

    local indic
    local scale
    if (not main) then
        indic = "DoT on Enemy #" .. index
        scale = .4
    else
        indic = "Primary Target DoT"
        scale = .6
    end

    Rotorbar.logFrame.messageFrame:AddMessage(date() .. " " .. indic .. " [" .. spell .. "] " .. Rotorbar.damageString(amount, main), scale, scale, scale)
end

function Rotorbar.damage(spell, amount, guid, index)
    local main = (UnitGUID("target") == guid)
    local dc = Rotorbar.getCounter(guid,main,index)
    dc.damage = dc.damage + amount
    local indic
    local scale
    if (not main) then
        indic = "AoE Splash Enemy #" .. index
        scale = .4
    else
        indic = "Primary Target Damage"
        scale = .8
    end
    Rotorbar.logFrame.messageFrame:AddMessage(date() .. " " .. indic .. " [" .. spell .. "] " .. Rotorbar.damageString(amount, main), scale, scale, scale)
end

function Rotorbar.damageString(am,main)
    local amount = tonumber(am)
    local amstr
    if (amount ~= nil) then
        if (amount > 1000000) then
            amstr = Rotorbar.round(amount / 1000000, 2) .. "M"
        else
            amstr = Rotorbar.round(amount / 1000, 2) .. "K"
        end
        if (main) then
            return amstr .. " (" .. Rotorbar.round(amount / UnitHealthMax("target") * 100, 2) .. "%), target health: " .. Rotorbar.round((UnitHealth("target") / UnitHealthMax("target")) * 100, 2) .. "%"
        else
            return amstr
        end
    else
        return ""
    end
end

function Rotorbar.round(number, decimals)
    return (("%%.%df"):format(decimals)):format(number)
end

function Rotorbar.cast(spell, amount)
    local suggest = date() .. " Suggestion [" .. Rotorbar.suggest .. "]"
    if (Rotorbar.suggestReason ~= nil) then
        suggest = suggest .. ": " .. Rotorbar.suggestReason
    end
    Rotorbar.logFrame.messageFrame:AddMessage(suggest, .5, 0, .75)

    if (Rotorbar.suggest ~= spell) then
        Rotorbar.logFrame.messageFrame:AddMessage(date() .. " Cast [" .. spell .. "] " .. Rotorbar.damageString(amount), .75, .5, .25)
    else
        Rotorbar.logFrame.messageFrame:AddMessage(date() .. " Cast [" .. spell .. "] " .. Rotorbar.damageString(amount), .25, .5, .75)
    end
end

function Rotorbar.buttonActive(spell, fr, index)
    spell:SetPoint("LEFT", fr, ((index - 1)  * ICON_SIZE) + BORDER_SIZE, 0)
    spell:Show()
end

function Rotorbar.buttonActions(spell)
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

function Rotorbar._economove(show, last, fr)
    local found = {}
    for i = 1, tablelength(show)  do
        if (tablelength(last) >= i and show[i].ident == last[i].ident) then
            found[show[i].ident] = true
        elseif (tablelength(last) < i or show[i].ident ~= last[i].ident) then
            Rotorbar.buttonActive(show[i], fr, i)
            found[show[i].ident] = true
        end
        Rotorbar.buttonActions(show[i])
    end
    for j = 1, tablelength(last)  do
        if (found[last[j].ident] ~= true) then
            last[j]:Hide()
        end
    end
end

function Rotorbar.refresh()
    local rot = 0
    local rm = 0
    local deb = 0
    local dm = 0
    local inc = 0
    local cool = 0

    if (tablelength(showIcons)) then
        rot = (tablelength(showIcons) * ICON_SIZE)
        if (rot > 0) then
            rot = rot + (BORDER_SIZE * 2)
            rm = BORDER_SIZE
        end
    end

    if (tablelength(Rotorbar.debuffShow) > 0) then
        deb = (tablelength(Rotorbar.debuffShow) * ICON_SIZE)
        if (deb > 0) then
            deb = deb + (BORDER_SIZE * 2)
            dm = BORDER_SIZE
        end
    end

    if (Rotorbar.currentSpec().tank == true) then
        inc = (ICON_SIZE * 2) + BORDER_SIZE
    else

    end
    if (tablelength(coolIcons)) then
        cool = (tablelength(coolIcons) * ICON_SIZE)
        if (cool > 0) then cool = cool + (BORDER_SIZE * 2) end
    end

    frame:SetWidth((rot - rm) + (deb - dm) + inc + cool)

    if (rot == 0) then
        frame.rotation:Hide()
    else
        frame.rotation:Show()
        frame.rotation:SetPoint("LEFT", frame, 0, 0)
        frame.rotation:SetWidth(rot)
    end

    Rotorbar._economove(showIcons, Rotorbar._lastIcons, frame.rotation)


    frame.debuffs:SetPoint("LEFT", frame, rot - rm, 0)

    if (inc > 0) then
        frame.incoming:Show()
        frame.incoming:SetPoint("LEFT", frame, (rot - rm) + (deb - dm), 0)
    else
        frame.incoming:Hide()
    end

    if (cool == 0) then
        frame.cooldowns:Hide()
    else
        frame.cooldowns:Show()
        frame.cooldowns:SetPoint("LEFT", frame, (rot - rm) + (deb - dm) + inc, 0)
        frame.cooldowns:SetWidth(cool)
    end

    Rotorbar._economove(coolIcons, Rotorbar._lastCool, frame.cooldowns)

    for i = 1, tablelength(Rotorbar.currentSpec().debuffIcons) do
        Rotorbar.buttonActions(Rotorbar.currentSpec().debuffIcons[i])
    end
end

function Rotorbar.updateDebuffIcons()
    local icons = tablelength(Rotorbar.currentSpec().debuffIcons)

    for i = 1, tablelength(Rotorbar.debuffShow) do
        Rotorbar.debuffShow[i]:Hide()
    end

    if (icons == 0) then
        frame.debuffs:Hide()
    else
        local vis = 0
        frame.debuffs:Show()

        Rotorbar.debuffShow = {}
        for i = 1, tablelength(Rotorbar.currentSpec().debuffIcons) do
            if (Rotorbar.currentSpec().debuffIcons[i].isRelevant()) then
                table.insert(Rotorbar.debuffShow, Rotorbar.currentSpec().debuffIcons[i])
            end
        end

        frame.debuffs:SetWidth((ICON_SIZE * tablelength(Rotorbar.debuffShow)) + (BORDER_SIZE * 2))
        for i = 1, tablelength(Rotorbar.debuffShow) do
            Rotorbar.buttonActive(Rotorbar.debuffShow[i], frame.debuffs, i)
        end
    end
end

function Rotorbar.updateIncoming(inco)
    frame.incoming.draw(inco)
end

function Rotorbar.showNext (icon, suggest)
    if (icon ~= nil and tablelength(showIcons) == 1) then
        if (suggest ~= nil) then
            Rotorbar.suggest = icon.name
            Rotorbar.suggestReason = suggest
        else
            Rotorbar.suggest = icon.name
            Rotorbar.suggestReason = nil
        end
    end
    table.insert(showIcons, icon)
end

function Rotorbar.showCooldown (icon)
    table.insert(coolIcons, icon)
end

function frameback(fr)
    fr:SetHeight(ICON_SIZE+(BORDER_SIZE*2))
    fr:SetBackdrop({
       -- bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = ICON_SIZE,
        edgeSize = ICON_SIZE,
        insets = {
            left = BORDER_SIZE,
            right = BORDER_SIZE,
            top = BORDER_SIZE,
            bottom = BORDER_SIZE
        }
    })
end

BORDER_SIZE = 12
ICON_SIZE = 32

frame:SetWidth(ICON_SIZE+(BORDER_SIZE * 2))
frame:SetHeight(ICON_SIZE+(BORDER_SIZE * 2))
frame:ClearAllPoints()

function Rotorbar.setPosition()
    print (RotorbarOptions.left, RotorbarOptions.top)
    frame:SetPoint("CENTER",UIParent)
    frame:SetPoint("Top", UIParent, RotorbarOptions.left, RotorbarOptions.top)
    frame:Show()
end

frame:SetMovable(true)
frame:EnableMouse(true)

frame:RegisterForDrag("LeftButton")

frame:SetScript("OnDragStart", function(self)
    self:StartMoving();
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing();
    local _, _, _, left, top = self:GetPoint("Top", UIParent)
    RotorbarOptions.left = left
    RotorbarOptions.top = top
end)

frame.cooldowns = CreateFrame("Frame", "Rotorbar_Cooldowns", frame)
frameback(frame.cooldowns)

frame.debuffs = CreateFrame("Frame", "Rotorbar_Debuffs", frame)
frameback(frame.debuffs)

frame.rotation = CreateFrame("Frame", "Rotorbar_Rotation", frame)
frameback(frame.rotation)

function registerOnUpdate(onup)
    frame.onUpdate = onup
    frame:SetScript("OnUpdate",frame.onUpdate)
end

handler = registerEvents(events, frame)



--buttonfr = {}
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
    if (T ~= nil) then
    for _ in pairs(T) do count = count + 1 end
    end
    return count
end

function Rotorbar._texture(_name)
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

    Rotorbar.equipment[slot].load = function()
        local id = GetInventoryItemID("player", slot)

        if (Rotorbar.equipment[slot].id ~= id) then
            local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(id)

            if (name ~= nil) then
                Rotorbar.equipment[slot].id = id
                Rotorbar.equipment[slot].name = name

                if (Rotorbar.equipment[slot].icon == nil) then
                    Rotorbar.equipment[slot].icon = Rotorbar.itemIcon(name, slot, texture)
                    Rotorbar.equipment[slot].cool = Rotorbar.itemCooldown(name, slot, texture)
                else
                    Rotorbar.equipment[slot].icon.updateGear(name, texture)
                    Rotorbar.equipment[slot].cool.updateGear(name, texture)
                end
            end
        end
    end

    Rotorbar.equipment[slot].show = function()
        local usable, ready, left = equipmentUsable(slot)

        if (Rotorbar.equipment[slot].name ~= nil) then
            return usable, ready, Rotorbar.equipment[slot].icon, Rotorbar.equipment[slot].cool
        else
            return false
        end
    end

    Rotorbar.equipment[slot].load()
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
            --print (GetShapeshiftForm())

            if (GetShapeshiftForm() == 1) then
                actionbar = whatsbound.druid.bear

            elseif (GetShapeshiftForm() == 2) then
                if (Rotorbar.buffed("Prowl") == 0) then
                    actionbar = whatsbound.druid.cat
                else
                    actionbar = whatsbound.druid.prowl
                end


            elseif (GetShapeshiftForm() == 4) then
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


SLASH_ROTORBAR1 = "/rotor"
SlashCmdList.ROTORBAR = function(msg,editbox)
    if (msg == "log") then
        if Rotorbar.logFrame:IsShown() then
            Rotorbar.logFrame:Hide()
        else
            Rotorbar.logFrame:Show()
        end

    elseif (msg == "clear") then
        Rotorbar.logFrame.messageFrame:Clear()

    elseif (msg == "show") then
        frame:Show()

    elseif (msg == "hide") then
        frame:Hide()

    elseif (msg == "position") then
        RotorbarOptions.left = 0
        RotorbarOptions.top = -20
        frame:SetPoint("Top", UIParent, RotorbarOptions.left, RotorbarOptions.top)


    elseif (msg == "gear on") then
        RotorbarOptions.showUsables = true
    elseif (msg == "gear off") then
        RotorbarOptions.showUsables = false

    elseif (msg == "neck off") then
        RotorbarOptions.showGear[2] = false
    elseif (msg == "r1 off") then
        RotorbarOptions.showGear[11] = false
    elseif (msg == "r2 off") then
        RotorbarOptions.showGear[12] = false
    elseif (msg == "t1 off") then
        RotorbarOptions.showGear[13] = false
    elseif (msg == "t2 off") then
        RotorbarOptions.showGear[14] = false

    elseif (msg == "neck on") then
        RotorbarOptions.showGear[2] = true
    elseif (msg == "r1 on") then
        RotorbarOptions.showGear[11] = true
    elseif (msg == "r2 on") then
        RotorbarOptions.showGear[12] = true
    elseif (msg == "t1 on") then
        RotorbarOptions.showGear[13] = true
    elseif (msg == "t2 on") then
        RotorbarOptions.showGear[14] = true
    end
end