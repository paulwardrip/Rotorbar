Shadow = {
    name = "Shadow",

    class = function()
        Rotorbar.classIcon(.75, 0, .75, 1)
    end,

    icons = function()
        Shadow.shadowWordPain = Rotorbar.buttonTime("Shadow Word: Pain")
        Shadow.shadowWordDeath = Rotorbar.buttonTime("Shadow Word: Death")
        Shadow.vampiricTouch = Rotorbar.buttonTime("Vampiric Touch")
        Shadow.mindBlast = Rotorbar.buttonTime("Mind Blast")
        Shadow.mindFlay = Rotorbar.buttonTime("Mind Flay")
        Shadow.voidBolt = Rotorbar.buttonTime("Void Bolt")
        Shadow.voidBolt.name = "Void Eruption"

        Shadow.voidTorrent = Rotorbar.buttonTime("Void Torrent")
        Shadow.shadowfiend = Rotorbar.buttonTime("Shadowfiend")

        Shadow.shadowWordVoid = Rotorbar.buttonTime("Shadow Word: Void")
        Shadow.mindbender = Rotorbar.buttonTime("Mindbender")
        Shadow.powerInfusion = Rotorbar.buttonTime("Power Infusion")
        Shadow.shadowCrash = Rotorbar.buttonTime("Shadow Crash")
        Shadow.surrenderToMadness = Rotorbar.buttonTime("Surrender to Madness")

        Shadow.shadowform = Rotorbar.flash("Shadowform")
        Shadow.voidEruption = Rotorbar.flash("Void Eruption")
        Shadow.shadowyInsight = Rotorbar.flash("Mind Blast", "Shadowy Insight").color(.75, .5, 1, 1)

        Rotorbar.debuffIcon("Shadow Word: Pain")
        Rotorbar.debuffIcon("Vampiric Touch")

        Rotorbar.cooldown("Mind Blast")
        Rotorbar.cooldown("Shadowfiend").ifNotTalent("Mindbender")
        Rotorbar.cooldown("Mindbender")
        Rotorbar.cooldown("Power Infusion")
        Rotorbar.cooldown("Shadow Crash")
        Rotorbar.cooldown("Surrender to Madness")
    end,

    rotation = function()
        local targetHealthPercent = UnitHealth("target")  / UnitHealthMax("target")
        local showedMindBlast = false
        local showedTouch = false
        local voidForm = (Rotorbar.buffed("Voidform") > 0)

        if (Rotorbar.buffed("Shadowform") == 0 and not voidForm) then
            Rotorbar.showNext(Shadow.shadowform)
        end

        if (not voidForm and Rotorbar.isUsableCooldown("Void Eruption") and not Rotorbar.isCasting("Void Eruption")) then
            Rotorbar.showNext(Shadow.voidEruption)
        end

        if (voidForm) then
            if (Rotorbar.isUsableCooldown("Power Infusion") and Rotorbar.isBoss()) then
                Rotorbar.showNext(Shadow.powerInfusion)
            end

            if (Rotorbar.isUsableCooldown("Mindbender") and Rotorbar.isBoss()) then
                Rotorbar.showNext(Shadow.mindbender)
            elseif (Rotorbar.isUsableCooldown("Shadowfiend") and Rotorbar.isBoss()) then
                Rotorbar.showNext(Shadow.shadowfiend)
            end

            local swDeathStacks = GetSpellCharges("Shadow Word: Death")
            local swDeathGo = Rotorbar.isUsableCooldown("Shadow Word: Death")
            if (swDeathGo and swDeathStacks == 2) then
                Rotorbar.showNext(Shadow.shadowWordDeath)
            end
        end

        local mindBlastGo, mindBlastLeft = Rotorbar.isUsableCooldown("Mind Blast")
        if (mindBlastGo and Rotorbar.buffed("Shadowy Insight") > 0) then
            Rotorbar.showNext(Shadow.shadowyInsight)
            showedMindBlast = true
        end

        if (voidForm and Rotorbar.isUsableCooldown("Void Torrent")) then
            Rotorbar.showNext(Shadow.voidTorrent)
        end

        if (voidForm and Rotorbar.isUsableCooldown("Void Bolt")) then
            Rotorbar.showNext(Shadow.voidBolt)
        end

        if (Rotorbar.isUsableCooldown("Shadow Crash") and Rotorbar.targets() >= 3) then
            Rotorbar.showNext(Shadow.shadowCrash)
        end

        local pain, painLeft = Rotorbar.debuffed("Shadow Word: Pain")
        if (pain == 0 or painLeft <= .5) then
            if (Rotorbar.isTalent("Misery")) then
                Rotorbar.showNext(Shadow.vampiricTouch)
                showedTouch = true
            else
                Rotorbar.showNext(Shadow.shadowWordPain)
            end
        end

        local touch, touchLeft = Rotorbar.debuffed("Vampiric Touch")
        if (not showedTouch and not Rotorbar.isCasting("Vampiric Touch") and (touch == 0 or touchLeft <= 1)) then
            Rotorbar. showNext(Shadow.vampiricTouch)
        end

        if (not Rotorbar.isCasting("Mind Blast") and not showedMindBlast and mindBlastGo) then
            Rotorbar.showNext(Shadow.mindBlast)
        end

        if (voidForm and Rotorbar.isUsableCooldown("Shadow Word: Void")) then
            Rotorbar.showNext(Shadow.shadowWordVoid)
        end

        if (voidForm and swDeathGo and mindBlastLeft >= 3) then
            Rotorbar.showNext(Shadow.shadowWordDeath)
        end

        Rotorbar.showNext(Shadow.mindFlay)
    end
}