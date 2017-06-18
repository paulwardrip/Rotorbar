Blood = {
    icons = {},
    pulse = {},
    color = {}
}

Blood.init = function()
    print ("Rotorbar Loaded Blood Death Knight");

    Rotorbar.classIcon(1, 0.5, 0.5, 0.75)

    Blood.pulse.deathAndDecay = Rotorbar.flash("Death and Decay", nil, 1, .7, .7, 1)
    Blood.pulse.deathStrike = Rotorbar.flash("Death Strike", nil, 1, 0.5, 0.5, 1)
    Blood.pulse.iceboundFortitude = Rotorbar.flash("Icebound Fortitude")
    Blood.pulse.vampiricBlood = Rotorbar.flash("Vampiric Blood")
    Blood.pulse.dancingRuneWeapon = Rotorbar.flash("Dancing Rune Weapon")

    Blood.icons.deathAndDecay = Rotorbar.buttonTime("Death and Decay")
    Blood.icons.deathStrike = Rotorbar.buttonTime("Death Strike")
    Blood.icons.heartStrike = Rotorbar.buttonTime("Heart Strike")
    Blood.icons.marrowrend = Rotorbar.buttonTime("Marrowrend")
    Blood.icons.consumption = Rotorbar.buttonTime("Consumption")
    Blood.icons.bloodBoil = Rotorbar.buttonTime("Blood Boil")

    return function()

        local showPos = 0
        local showIcons = {}

        function showNext(icon)
            showIcons[showPos] = icon
            showPos = showPos + 1
        end

        local showedDS = false
        local boneShield, boneLeft = Rotorbar.buffed("Bone Shield")
        local bloodPlague, bloodLeft = Rotorbar.debuffed("Blood Plague")
        local crimson = Rotorbar.buffed("Crimson Scourge")

        local healthpercent = UnitHealth("player") / UnitHealthMax("player")
        local runicPercent = UnitPower("player", 6) / UnitPowerMax("player", 6)
        local runes = UnitPower("player", 5)

        -- Criticals
        local icebound = Rotorbar.isUsableCooldown("Icebound Fortitude")
        local vampire = Rotorbar.isUsableCooldown("Vampiric Blood")
        if (healthpercent < .35) then
            if (vampire and icebound and runicPercent > .5) then
                showNext (Blood.pulse.vampiricBlood)
            elseif (icebound) then
                showNext (Blood.pulse.iceboundFortitude)
            elseif (vampire) then
                showNext (Blood.pulse.vampiricBlood)
            end
        end

        -- Dancing Rune Weapon
        if (healthpercent < .45 and Rotorbar.isUsableCooldown("Dancing Rune Weapon")) then
            showNext(Blood.pulse.dancingRuneWeapon)
        end

        -- Death Strike Emergency
        if (Rotorbar.isUsableCooldown("Death Strike") and healthpercent < .50) then
            showNext (Blood.pulse.deathStrike)
            showedDS = true
        end

        -- Crimson Scourge Proc
        if (crimson > 0) then
            showNext (Blood.pulse.deathAndDecay)
        end

        -- Blood Boil
        if (Rotorbar.isUsableCooldown("Blood Boil") and (bloodPlague == 0 or bloodLeft < 3)) then
            showNext (Blood.icons.bloodBoil)
        end

        -- Death and Decay
        if (crimson == 0 and Rotorbar.isUsableCooldown("Death and Decay")) then
            showNext (Blood.icons.deathAndDecay)
        end

        -- Marrowrend if Bone Shield is Needed
        if (Rotorbar.isUsableCooldown("Marrowrend") and (boneShield < 9 or boneLeft < 5)) then
            showNext (Blood.icons.marrowrend)
        end

        -- Death Strike if it will heals 20% or more.
        if (not showedDS and Rotorbar.isUsableCooldown("Death Strike") and healthpercent < .8 and runicPercent > .2) then
            showNext (Blood.icons.deathStrike)
            showedDS = true
        end

        -- Consumption
        if (not showedDS and Rotorbar.isUsableCooldown("Consumption") and healthpercent < .9) then
            showNext (Blood.icons.consumption)
        end

        -- Heart Strike
        if (Rotorbar.isUsableCooldown("Heart Strike")) then
            showNext (Blood.icons.heartStrike)
        end

        -- Death Strike if heals 10% or if completely runic capped.
        if (not showedDS and Rotorbar.isUsableCooldown("Death Strike") and (healthpercent < .9 or runicPercent == 1)) then
            showNext (Blood.icons.deathStrike)
        end

        Rotorbar.resetButtons()
        Rotorbar.setIcons(showPos)

        for sp = 0, (showPos - 1) do
            Rotorbar.buttonActive(showIcons[sp])
        end
    end
end