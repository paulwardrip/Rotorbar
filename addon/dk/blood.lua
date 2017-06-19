Blood = {
    blooddrinker = false,
    bloodTap = false,
    markOfBlood = false,
    tombstone = false,
    runeTap = false,
    bonestorm = false,
    bloodMirror = false,
    icons = {},
    color = {},
    flash = {},
    cools = {}
}

Blood.init = function()
    print ("Rotorbar Loaded Blood Death Knight");

    Rotorbar.classIcon(1, 0.5, 0.5, 0.75)

    for tcol = 1,3 do
        for ttier = 1,7 do
            talentID, name, texture, selected, available, spellID, unknown, row, column, known = GetTalentInfo(ttier,tcol,GetActiveSpecGroup())

            if (name == "Blooddrinker" and selected) then
                Blood.blooddrinker = true
                Blood.icons.blooddrinker =  Rotorbar.buttonTime("Blooddrinker", texture);

            elseif (name == "Blood Tap" and selected) then
                Blood.bloodTap = true
                Blood.icons.bloodTap =  Rotorbar.buttonTime("Blood Tap", texture);

            elseif (name == "Mark of Blood" and selected) then
                Blood.markOfBlood = true
                Blood.icons.markOfBlood =  Rotorbar.buttonTime("Mark of Blood", texture);

            elseif (name == "Tombstone" and selected) then
                Blood.tombstone = true
                Blood.icons.tombstone =  Rotorbar.buttonTime("Tombstone", texture);

            elseif (name == "Rune Tap" and selected) then
                Blood.runeTap = true
                Blood.icons.runeTap =  Rotorbar.buttonTime("Rune Tap", texture);

            elseif (name == "Bonestorm" and selected) then
                Blood.bonestorm = true
                Blood.icons.bonestorm =  Rotorbar.buttonTime("Bonestorm", texture);
            end
        end
    end

    Blood.flash.deathAndDecay = Rotorbar.flash("Death and Decay", nil, 1, .7, .7, 1)
    Blood.flash.deathStrike = Rotorbar.flash("Death Strike", nil, 1, 0.5, 0.5, 1)
    Blood.flash.iceboundFortitude = Rotorbar.flash("Icebound Fortitude")
    Blood.flash.vampiricBlood = Rotorbar.flash("Vampiric Blood")
    Blood.flash.dancingRuneWeapon = Rotorbar.flash("Dancing Rune Weapon")

    Blood.icons.deathAndDecay = Rotorbar.buttonTime("Death and Decay")
    Blood.icons.deathStrike = Rotorbar.buttonTime("Death Strike")
    Blood.icons.heartStrike = Rotorbar.buttonTime("Heart Strike")
    Blood.icons.marrowrend = Rotorbar.buttonTime("Marrowrend")
    Blood.icons.consumption = Rotorbar.buttonTime("Consumption")
    Blood.icons.bloodBoil = Rotorbar.buttonTime("Blood Boil")

    Blood.cools.deathGrip = Rotorbar.cooldown("Death Grip")
    Blood.cools.gorefiendsGrasp = Rotorbar.cooldown("Gorefiend's Grasp")

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
        local runes = Rotorbar.runes()

        -- Criticals
        local icebound = Rotorbar.isUsableCooldown("Icebound Fortitude")
        local vampire = Rotorbar.isUsableCooldown("Vampiric Blood")
        if (healthpercent < .35) then
            if (vampire and icebound and runicPercent > .5) then
                showNext (Blood.flash.vampiricBlood)
            elseif (icebound) then
                showNext (Blood.flash.iceboundFortitude)
            elseif (vampire) then
                showNext (Blood.flash.vampiricBlood)
            end
        end

        -- Dancing Rune Weapon
        if (healthpercent < .45 and Rotorbar.isUsableCooldown("Dancing Rune Weapon")) then
            showNext(Blood.flash.dancingRuneWeapon)
        end

        -- Death Strike Emergency
        if (Rotorbar.isUsableCooldown("Death Strike") and healthpercent < .50) then
            showNext (Blood.flash.deathStrike)
            showedDS = true
        end

        -- Crimson Scourge Proc
        if (crimson > 0) then
            showNext (Blood.flash.deathAndDecay)
        end

        -- Blood Tap
        if (Rotorbar.isUsableCooldown("Blood Tap", Blood.bloodTap) and runes < 2 and boneShield > 1) then
            showNext (Blood.icons.bloodTap)
        end

        -- Blooddrinker
        if (Rotorbar.isUsableCooldown("Blooddrinker") and healthpercent < .8) then
            showNext (Blood.icons.blooddrinker)
        end

        -- Consumption
        if (Rotorbar.isUsableCooldown("Consumption") and healthpercent < .85) then
            showNext (Blood.icons.consumption)
        end

        -- Death Strike if it will heals 20% or more.
        if (not showedDS and Rotorbar.isUsableCooldown("Death Strike") and healthpercent < .8 and runicPercent > .2) then
            showNext (Blood.icons.deathStrike)
            showedDS = true
        end

        -- Bonestorm
        if (Rotorbar.isUsableCooldown("Bonestorm", Blood.bonestorm) and runicPercent > .8) then
            showNext (Blood.icons.bonestorm)
        end

        -- Blood Mirror
        if (Rotorbar.isUsableCooldown("Blood Mirror", Blood.bloodMirror) and Rotorbar.isBoss()) then
            showNext (Blood.icons.bonestorm)
        end

        -- Mark of Blood
        if (Rotorbar.isUsableCooldown("Mark of Blood") and Rotorbar.isBoss()) then
            local stacks, left = Rotorbar.debuffed("Mark of Blood")
            if (stacks == 0 or left < 2) then
                showNext (Blood.icons.markOfBlood)
            end
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

        -- Heart Strike
        if (Rotorbar.isUsableCooldown("Heart Strike")) then
            showNext (Blood.icons.heartStrike)
        end

        -- Death Strike if heals 10% or if completely runic capped.
        if (not showedDS and Rotorbar.isUsableCooldown("Death Strike") and (healthpercent < .9 or runicPercent == 1)) then
            showNext (Blood.icons.deathStrike)
        end

        -- Tombstone
        if (Rotorbar.isUsableCooldown("Tombstone") and boneShield > 4) then
            showNext (Blood.icons.tombstone)
        end

        -- Rune Tap
        if (Rotorbar.isUsableCooldown("Rune Tap")) then
            showNext (Blood.icons.runeTap)
        end

        showNext(Blood.cools.deathGrip)
        showNext(Blood.cools.gorefiendsGrasp)

        Rotorbar.resetButtons()
        Rotorbar.setIcons(showPos)

        for sp = 0, (showPos - 1) do
            Rotorbar.buttonActive(showIcons[sp])
        end
    end
end