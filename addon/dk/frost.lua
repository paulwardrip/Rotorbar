Frost = {
    hornOfWinter = false,
    hungeringRuneWeapon = false,
    frostscythe = false,
    obliteration = false,
    breathOfSindragosa = false,
    glacialAdvance = false,
    icons = {},
    pulse = {},
    color = {}
}

function Frost.init()
    print ("Rotorbar Loaded Frost Death Knight");

    Rotorbar.classIcon(0.5, 0.5, 1, 0.75)

    for tcol = 1,3 do
        for ttier = 1,7 do
            talentID, name, texture, selected, available, spellID, unknown, row, column, known = GetTalentInfo(ttier,tcol,GetActiveSpecGroup())

            if (name == "Horn of Winter" and selected) then
                Frost.hornOfWinter = true
                Frost.icons.hornOfWinter =  Rotorbar.buttonTime("Horn of Winter", texture);
            elseif (name == "Hungering Rune Weapon" and selected) then
                Frost.hungeringRuneWeapon = true
                Frost.icons.hungeringRuneWeapon =  Rotorbar.buttonTime("Hungering Rune Weapon", texture);
            elseif (name == "Frostscythe" and selected) then
                Frost.frostscythe = true
                Frost.icons.frostscythe =  Rotorbar.buttonTime("Frostscythe", texture);
            elseif (name == "Obliteration" and selected) then
                Frost.obliteration = true
                Frost.icons.obliteration =  Rotorbar.buttonTime("Obliteration", texture);
            elseif (name == "Breath of Sindragosa" and selected) then
                Frost.breathOfSindragosa = true
                Frost.icons.breathOfSindragosa =  Rotorbar.buttonTime("Breath of Sindragosa", texture);
            elseif (name == "Glacial Advance" and selected) then
                Frost.glacialAdvance = true
                Frost.icons.glacialAdvance =  Rotorbar.buttonTime("Glacial Advance", texture);
            end
        end
    end

    Frost.pulse.deathStrike = Rotorbar.flash("Death Strike", nil, 1, 0.5, 0.5, 1)
    Frost.pulse.iceboundFortitude = Rotorbar.flash("Icebound Fortitude")
    Frost.pulse.howlingBlast = Rotorbar.flash("Howling Blast", nil, 0, .75, 1, 1)
    Frost.pulse.obliterate = Rotorbar.flash("Obliterate", nil, 1, .5, .5, 1)
    Frost.pulse.frostscythe = Rotorbar.flash("Frostscythe", nil, 1, .5, 0, 1)
    Frost.pulse.hungeringRuneWeapon = Rotorbar.flash("Hungering Rune Weapon")

    Frost.icons.howlingBlast =  Rotorbar.buttonTime("Howling Blast")
    Frost.icons.frostStrike =  Rotorbar.buttonTime("Frost Strike")
    Frost.icons.obliterate =  Rotorbar.buttonTime("Obliterate")
    Frost.icons.sindragosasFury =  Rotorbar.buttonTime("Sindragosa's Fury")
    Frost.icons.remorselessWinter =  Rotorbar.buttonTime("Remorseless Winter")
    Frost.icons.pillarOfFrost =  Rotorbar.buttonTime("Pillar of Frost")


    return function()
        local showPos = 0
        local showIcons = {}

        function showNext(icon)
            showIcons[showPos] = icon
            showPos = showPos + 1
        end

        local healthpercent = UnitHealth("player") / UnitHealthMax("player")
        local runicPercent = UnitPower("player", 6) / UnitPowerMax("player", 6)
        local runes = UnitPower("player", 5)

        -- Death Strike when below 50%
        if (IsUsableSpell("Death Strike")) then
            if (healthpercent < .50) then
               showNext (Frost.pulse.deathStrike)
            end
        end

        -- Icebound Fortitude when critical
        if (IsUsableSpell("Icebound Fortitude")) then
            start, duration = GetSpellCooldown("Icebound Fortitude")
            if (start == 0 and healthpercent < .30) then
               showNext (Frost.pulse.iceboundFortitude)
            end
        end


        -- Check all buffs and debuffs
        local rime = Rotorbar.buffed("Rime")
        local killingMachine = Rotorbar.buffed("Killing Machine")
        local breathActive = Rotorbar.buffed("Breath of Sindragosa")
        local frostFever = Rotorbar.debuffed("Frost Fever")
        local obliterationActive = Rotorbar.buffed("Obliteration")


        -- Rime: flashing Howling Blast
        if (rime > 0 and IsUsableSpell("Howling Blast")) then
            showNext(Frost.pulse.howlingBlast)
        end

        -- Killing Machine: flashes Obliterate and if available, Frostscythe
        if (killingMachine > 0) then
            if (IsUsableSpell("Obliterate")) then
                showNext(Frost.pulse.obliterate)
            end
            if (Frost.frostscythe and IsUsableSpell("Frostscythe")) then
                showNext(Frost.pulse.frostscythe)
            end
        end

        -- Obliteration: Frost Strike to trigger next Killing Machine.
        if (obliterationActive > 0 and IsUsableSpell("Frost Strike")) then
            showNext(Frost.icons.frostStrike)
        end

        -- Rune Weapon: No Breath of Sindragosa, show when resources depleted.
        local runeWeaponGo, runeWeaponCool = Rotorbar.isUsableCooldown("Hungering Rune Weapon", Frost.hungeringRuneWeapon)
        if (runeWeaponGo and not Frost.breathOfSindragosa and runes == 0 and runicPercent < .2 and Rotorbar.isBoss()) then
            showNext(Frost.icons.hungeringRuneWeapon)
        end

        -- Horn of Winter, when resources depleted.
        if (Rotorbar.isUsableCooldown("Horn of Winter", Frost.hornOfWinter) and runes == 0 and runicPercent < .2) then
            showNext(Frost.icons.hornOfWinter)
        end

        -- Sindragosa Fury
        if (Rotorbar.isUsableCooldown("Sindragosa's Fury") and Rotorbar.isBoss()) then
            showNext(Frost.icons.sindragosasFury)
        end

        -- Breath of Sindragosa
        breathGo, breathCool = Rotorbar.isUsableCooldown("Breath of Sindragosa", Frost.breathOfSindragosa)
        if (breathGo and runicPercent == 1 and Rotorbar.isBoss()) then
            if (Frost.hungeringRuneWeapon) then
                if (runeWeaponGo) then
                    showNext(Frost.icons.breathOfSindragosa)
                end
            else
                showNext(Frost.icons.breathOfSindragosa)
            end
        end

        -- print (runeWeaponGo, runeWeaponCool, breathActive)
        -- Rune Weapon: Breath of Sindragosa Active
        if (runeWeaponGo and breathActive > 0) then
            showNext(Frost.pulse.hungeringRuneWeapon)
        end

        -- Glacial Advance
        if (Rotorbar.isUsableCooldown("Glacial Advance", Frost.glacialAdvance)) then
            showNext(Frost.icons.glacialAdvance)
        end

        -- Remorseless Winter
        if (Rotorbar.isUsableCooldown("Remorseless Winter")) then
            showNext(Frost.icons.remorselessWinter)
        end

        -- Pillar of Frost
        if (Rotorbar.isUsableCooldown("Pillar of Frost")) then
            showNext(Frost.icons.pillarOfFrost)
        end

        -- Obliteration
        obliterationGo, obliterationCool = Rotorbar.isUsableCooldown("Obliteration", Frost.obliteration)
        if (obliterationGo and runicPercent > .75) then
            showNext(Frost.icons.obliteration)
        end

        -- Frost Fever Needed
        if (rime == 0 and frostFever == 0 and Rotorbar.isUsableCooldown("Howling Blast")) then
            showNext(Frost.icons.howlingBlast)
        end

        -- Frost Strike
        if (Frost.breathOfSindragosa and breathActive == 0) then
            if (not Rotorbar.isBoss() or (not breathGo and breathCool > 15)) then
                showNext(Frost.icons.frostStrike)
            end
        elseif (Frost.obliteration and obliterationActive == 0) then
            if (not obliterationGo and obliterationCool > 5) then
                showNext(Frost.icons.frostStrike)
            end
        elseif (not Frost.breathOfSindragosa and not Frost.obliteration) then
            showNext(Frost.icons.frostStrike)
        end

        -- Obliterate/Frostscythe, non-killingMachine
        if (killingMachine == 0) then
            if (Rotorbar.isUsableCooldown("Obliterate")) then
                showNext(Frost.icons.obliterate)
            end
            if (Rotorbar.isUsableCooldown("Frostscythe", Frost.frostscythe)) then
                showNext(Frost.icons.frostscythe)
            end
        end

        -- Howling Blast as last resort spell
        if (rime == 0 and frostFever > 0 and IsUsableSpell("Howling Blast")) then
            showNext(Frost.icons.howlingBlast)
        end

        Rotorbar.resetButtons()
        Rotorbar.setIcons(showPos)

        for sp = 0, (showPos - 1) do
            Rotorbar.buttonActive(showIcons[sp])
        end
    end
end