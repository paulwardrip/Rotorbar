Shadow = {
    icons = {},
    flash = {},
    cools = {},
    color = {},
    loaded = false
}

function Shadow.init()
    Rotorbar.classIcon(.75, 0, .75, 1)

    Shadow.shadowWordVoid = false
    Shadow.mindbender = false
    Shadow.powerInfusion = false
    Shadow.misery = false
    Shadow.shadowCrash = false
    Shadow.surrenderToMadness = false

    for tcol = 1,3 do
        for ttier = 1,7 do
            local talentID, name, texture, selected = GetTalentInfo(ttier,tcol,GetActiveSpecGroup())

            if (name == "Shadow Word: Void" and selected) then
                Shadow.shadowWordVoid = true
            end
            if (name == "Mindbender" and selected) then
                Shadow.mindbender = true
            end
            if (name == "Power Infusion" and selected) then
                Shadow.powerInfusion = true
            end
            if (name == "Misery" and selected) then
                Shadow.misery = true
            end
            if (name == "Shadow Crash" and selected) then
                Shadow.shadowCrash = true
            end
            if (name == "Surrender to Madness" and selected) then
                Shadow.surrenderToMadness = true
            end
        end
    end

    if (not Shadow.loaded) then
        Shadow.icons.shadowWordPain = Rotorbar.buttonTime("Shadow Word: Pain")
        Shadow.icons.shadowWordDeath = Rotorbar.buttonTime("Shadow Word: Death")
        Shadow.icons.vampiricTouch = Rotorbar.buttonTime("Vampiric Touch")
        Shadow.icons.mindBlast = Rotorbar.buttonTime("Mind Blast")
        Shadow.icons.mindFlay = Rotorbar.buttonTime("Mind Flay")
        Shadow.icons.voidBolt = Rotorbar.buttonTime("Void Bolt")
        Shadow.icons.voidBolt.name = "Void Eruption"

        Shadow.icons.voidTorrent = Rotorbar.buttonTime("Void Torrent")
        Shadow.icons.shadowfiend = Rotorbar.buttonTime("Shadowfiend")

        Shadow.icons.shadowWordVoid = Rotorbar.buttonTime("Shadow Word: Void")
        Shadow.icons.mindbender = Rotorbar.buttonTime("Mindbender")
        Shadow.icons.powerInfusion = Rotorbar.buttonTime("Power Infusion")
        Shadow.icons.shadowCrash = Rotorbar.buttonTime("Shadow Crash")
        Shadow.icons.surrenderToMadness = Rotorbar.buttonTime("Surrender to Madness")

        Shadow.flash.shadowform = Rotorbar.flash("Shadowform")
        Shadow.flash.voidEruption = Rotorbar.flash("Void Eruption")
        Shadow.flash.mindBlast = Rotorbar.flash("Mind Blast", nil, .75, .5, 1, 1)

        Shadow.loaded = true
    end

    return function()
        local showPos = 0
        local showIcons = {}

        function showNext(icon)
            showIcons[showPos] = icon
            showPos = showPos + 1
        end

        local targetHealthPercent = UnitHealth("target")  / UnitHealthMax("target")
        local showedMindBlast = false
        local showedTouch = false
        local voidForm = (Rotorbar.buffed("Voidform") > 0)

        if (Rotorbar.buffed("Shadowform") == 0 and not voidForm) then
            showNext(Shadow.flash.shadowform)
        end

        if (not voidForm and Rotorbar.isUsableCooldown("Void Eruption") and not Rotorbar.isCasting("Void Eruption")) then
            showNext(Shadow.flash.voidEruption)
        end

        if (voidForm) then
            if (Shadow.powerInfusion and Rotorbar.isUsableCooldown("Power Infusion")) then
                showNext(Shadow.icons.powerInfusion)
            end

            if (Shadow.mindbender and Rotorbar.isUsableCooldown("Mindbender")) then
                showNext(Shadow.icons.mindbender)
            elseif (not Shadow.mindbender and Rotorbar.isUsableCooldown("Shadowfiend")) then
                showNext(Shadow.icons.shadowfiend)
            end

            local swDeathStacks = GetSpellCharges("Shadow Word: Death")
            local swDeathGo = Rotorbar.isUsableCooldown("Shadow Word: Death")
            if (swDeathGo and swDeathStacks == 2) then
                showNext(Shadow.icons.shadowWordDeath)
            end
        end

        local mindBlastGo, mindBlastLeft = Rotorbar.isUsableCooldown("Mind Blast")
        if (mindBlastGo and Rotorbar.buffed("Shadowy Insight") > 0) then
            showNext(Shadow.flash.mindBlast)
            showedMindBlast = true
        end

        if (voidForm and Rotorbar.isUsableCooldown("Void Torrent")) then
            showNext(Shadow.icons.voidTorrent)
        end

        if (voidForm and Rotorbar.isUsableCooldown("Void Bolt")) then
            showNext(Shadow.icons.voidBolt)
        end

        if (Shadow.shadowCrash and Rotorbar.isUsableCooldown("Shadow Crash") and Rotorbar.targetsInRange("Shadow Crash") >= 3) then
            showNext(Shadow.icons.shadowCrash)
        end

        local pain, painLeft = Rotorbar.debuffed("Shadow Word: Pain")
        if (pain == 0 or painLeft <= .5) then
            if (Shadow.misery) then
                showNext(Shadow.icons.vampiricTouch)
                showedTouch = true
            else
                showNext(Shadow.icons.shadowWordPain)
            end
        end

        local touch, touchLeft = Rotorbar.debuffed("Vampiric Touch")
        if (not showedTouch and not Rotorbar.isCasting("Vampiric Touch") and (touch == 0 or touchLeft <= 1)) then
            showNext(Shadow.icons.vampiricTouch)
        end

        if (not Rotorbar.isCasting("Mind Blast") and not showedMindBlast and mindBlastGo) then
            showNext(Shadow.icons.mindBlast)
        end

        if (voidForm and Shadow.shadowWordVoid and Rotorbar.isUsableCooldown("Shadow Word: Void")) then
            showNext(Shadow.icons.shadowWordVoid)
        end

        if (voidForm and swDeathGo and mindBlastLeft >= 3) then
            showNext(Shadow.icons.shadowWordDeath)
        end

        showNext(Shadow.icons.mindFlay)

        Rotorbar.resetButtons()
        Rotorbar.setIcons(showPos)

        for sp = 0, (showPos - 1) do
            Rotorbar.buttonActive(showIcons[sp])
        end
    end
end