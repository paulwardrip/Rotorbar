Balance = {
    name = "Balance",

    class = function()
        Rotorbar.classIcon(0.75,0,0.90,1)
    end,

    icons = function()
        Balance.moonkin = Rotorbar.buttonTime("Moonkin Form")
        Balance.moonfire = Rotorbar.buttonTime("Moonfire")
        Balance.sunfire = Rotorbar.buttonTime("Sunfire")
        Balance.starsurge = Rotorbar.buttonTime("Starsurge")
        Balance.lunarStrike = Rotorbar.buttonTime("Lunar Strike")
        Balance.solarWrath = Rotorbar.buttonTime("Solar Wrath")
        Balance.lunarStrikeEmpowered = Rotorbar.flash("Lunar Strike", "Empowered")
        Balance.solarWrathEmpowered = Rotorbar.flash("Solar Wrath", "Empowered")
        Balance.newMoon = Rotorbar.buttonTime("New Moon")
        Balance.celestialAlignment = Rotorbar.buttonTime("Celestial Alignment")
        Balance.incarnation = Rotorbar.buttonTime("Incarnation: Chosen of Elune")
        Balance.starfall = Rotorbar.buttonTime("Starfall")
        Balance.stellarFlare = Rotorbar.buttonTime("Stellar Flare")
        Balance.renewal = Rotorbar.buttonTime("Renewal")

        Rotorbar.debuffIcon("Moonfire")
        Rotorbar.debuffIcon("Sunfire")
        Rotorbar.debuffIcon("Stellar Flare")

        Rotorbar.cooldown("Innervate")
        Rotorbar.cooldown("Blessing of the Ancients")
        Rotorbar.cooldown("Incarnation: Chosen of Elune")
        Rotorbar.cooldown("Celestial Alignment").ifNotTalent("Incarnation: Chosen of Elune")
        Rotorbar.cooldown("Rebirth")
        Rotorbar.cooldown("Renewal")
    end,

    rotation = function()
        if (GetShapeshiftForm() ~= 4) then
            Rotorbar.showNext(Balance.moonkin)

        else
            local healthpercent = UnitHealth("player") / UnitHealthMax("player")

            local newMoonGo, _, _, newMoonCharges = Rotorbar.isUsableCooldown("New Moon")

            if (healthpercent < .7 and Rotorbar.isUsableCooldown("Renewal")) then
                Rotorbar.showNext(Balance.renewal)
            end

            if (newMoonGo and newMoonCharges == 3) then
                Rotorbar.showNext(Balance.newMoon)
            end

            if (Rotorbar.debuffed("Moonfire") == 0) then
                Rotorbar.showNext(Balance.moonfire)
            end

            if (Rotorbar.debuffed("Sunfire") == 0) then
                Rotorbar.showNext(Balance.sunfire)
            end

            if (Rotorbar.isTalent("Stellar Flare") and Rotorbar.debuffed("Stellar Flare") == 0 and IsUsableSpell("Stellar Flare")) then
                Rotorbar.showNext(Balance.stellarFlare)
            end

            if (Rotorbar.isBoss()) then
                if (Rotorbar.isUsableCooldown("Incarnation: Chosen of Elune")) then
                    Rotorbar.showNext(Balance.incarnation)
                elseif (Rotorbar.isUsableCooldown("Celestial Alignment")) then
                    Rotorbar.showNext(Balance.celestialAlignment)
                end
            end

            if (newMoonGo and newMoonCharges < 3) then
                Rotorbar.showNext(Balance.newMoon)
            end

            if (Rotorbar.buffed("Lunar Empowerment") < 3 and Rotorbar.buffed("Solar Empowerment") < 3) then
                if (Rotorbar.targets() < 3) then
                    if (Rotorbar.isUsableCooldown("Starsurge")) then
                        Rotorbar.showNext(Balance.starsurge)
                    end
                else
                    if (Rotorbar.isUsableCooldown("Starfall")) then
                        Rotorbar.showNext(Balance.starfall)
                    end
                end
            end

            local showedLunar = false
            if (Rotorbar.buffed("Lunar Empowerment") > 0) then
                Rotorbar.showNext(Balance.lunarStrikeEmpowered)
                showedLunar = true
            end

            local showedSolar = false
            if (Rotorbar.buffed("Solar Empowerment") > 0) then
                Rotorbar.showNext(Balance.solarWrathEmpowered)
                showedSolar = true
            end

            if (not showedLunar) then
                Rotorbar.showNext(Balance.lunarStrike)
            end

            if (not showedSolar) then
                Rotorbar.showNext(Balance.solarWrath)
            end
        end
    end
}