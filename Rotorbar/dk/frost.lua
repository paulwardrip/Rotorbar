Frost = {
    name = "Frost",

    class = function()
        Rotorbar.classIcon(0.25, 0.4, 1, 1)
    end,

    icons = function()
        Frost.deathStrike = Rotorbar.flash("Death Strike").color(1, 0.5, 0.5, 1)
        Frost.iceboundFortitude = Rotorbar.flash("Icebound Fortitude")
        Frost.rime = Rotorbar.flash("Howling Blast", "Rime").color(.6, .6, 1, .75)
        Frost.obliterateKM = Rotorbar.flash("Obliterate", "Killing Machine").color(1, .5, 1, 1)
        Frost.frostscytheKM = Rotorbar.flash("Frostscythe", "Killing Machine").color(1, .5, 1, 1)
        Frost.runeWeaponBS = Rotorbar.flash("Hungering Rune Weapon")

        Frost.howlingBlast =  Rotorbar.buttonTime("Howling Blast")
        Frost.frostStrike =  Rotorbar.buttonTime("Frost Strike")
        Frost.obliterate =  Rotorbar.buttonTime("Obliterate")
        Frost.sindragosasFury =  Rotorbar.buttonTime("Sindragosa's Fury")
        Frost.remorselessWinter =  Rotorbar.buttonTime("Remorseless Winter")
        Frost.pillarOfFrost =  Rotorbar.buttonTime("Pillar of Frost")
        Frost.empowerRuneWeapon = Rotorbar.buttonTime("Empower Rune Weapon");

        Frost.hornOfWinter =  Rotorbar.buttonTime("Horn of Winter");
        Frost.hungeringRuneWeapon =  Rotorbar.buttonTime("Hungering Rune Weapon");
        Frost.frostscythe =  Rotorbar.buttonTime("Frostscythe");
        Frost.obliteration =  Rotorbar.buttonTime("Obliteration");
        Frost.breathOfSindragosa =  Rotorbar.buttonTime("Breath of Sindragosa");
        Frost.glacialAdvance =  Rotorbar.buttonTime("Glacial Advance");

        Rotorbar.cooldown("Icebound Fortitude")
        Rotorbar.cooldown("Pillar of Frost")
        Rotorbar.cooldown("Obliteration")
        Rotorbar.linkedCooldown("Breath of Sindragosa", "Hungering Rune Weapon")
        Rotorbar.cooldown("Sindragosa's Fury")

        Rotorbar.debuffIcon("Frost Fever", "195617")
    end,

    rotation = function()
        local healthpercent = UnitHealth("player") / UnitHealthMax("player")
        local runicPercent = UnitPower("player", 6) / UnitPowerMax("player", 6)
        local runes = Rotorbar.runes()


        -- Death Strike when below 50% or Dark Succor Procs
        if (IsUsableSpell("Death Strike")) then
            if (healthpercent < .50 or Rotorbar.buffed("Dark Succor") > 0) then
                Rotorbar.showNext (Frost.deathStrike)
            end
        end

        -- Icebound Fortitude when critical
        if (IsUsableSpell("Icebound Fortitude")) then
            local start, duration = GetSpellCooldown("Icebound Fortitude")
            if (start == 0 and healthpercent < .30) then
                Rotorbar.showNext (Frost.iceboundFortitude)
            end
        end


        -- Check all buffs and debuffs
        local rime = Rotorbar.buffed("Rime")
        local killingMachine = Rotorbar.buffed("Killing Machine")
        local breathActive = Rotorbar.buffed("Breath of Sindragosa")
        local obliterationActive = Rotorbar.buffed("Obliteration")
        local showedObliterate = false
        local showedHowling = false
        local showedScythe = false

        local scythe = 0
        if (Rotorbar.isTalent("Frostscythe")) then
            scythe = Rotorbar.targetsInRange("Frostscythe")
        end

        -- Horn of Winter, when resources depleted.
        if (Rotorbar.isUsableCooldown("Horn of Winter") and runes <= 2 and runicPercent <= .25) then
            Rotorbar.showNext(Frost.hornOfWinter)
        end

        -- Frost Strike, Killing Machine and Rime priority in different order during Obliteration
        if (obliterationActive > 0) then
            -- Killing Machine: flashes Obliterate and if available, Frostscythe
            if (killingMachine > 0) then

                -- Frostscythe Killing Machine
                if (scythe >= 3 and Rotorbar.isUsableCooldown("Frostscythe")) then
                    Rotorbar.showNext(Frost.frostscytheKM)
                    showedScythe = true
                end

                if (IsUsableSpell("Obliterate")) then
                    Rotorbar.showNext(Frost.obliterateKM)
                    showedObliterate = true
                end

            end

            -- Obliteration: Frost Strike to trigger next Killing Machine.
            if (obliterationActive > 0 and IsUsableSpell("Frost Strike")) then
                Rotorbar.showNext(Frost.frostStrike)
            end

        else
            if (rime > 0 and IsUsableSpell("Howling Blast")) then
                Rotorbar.showNext(Frost.rime)
                showedHowling = true
            end

            -- Killing Machine: flashes Obliterate and if available, Frostscythe
            if (killingMachine > 0) then
                if (scythe >= 3) then
                    Rotorbar.showNext(Frost.frostscytheKM)
                    showedScythe = true
                end

                if (IsUsableSpell("Obliterate")) then
                    Rotorbar.showNext(Frost.obliterateKM)
                    showedObliterate = true
                end
            end
        end

        -- Rune Weapon: Breath of Sindragosa Active
        if (runeWeaponGo and breathActive > 0) then
            Rotorbar.showNext(Frost.runeWeaponBS)
        end

        -- Prioritize Obliterate during Breath of Sindragosa
        if (breathActive > 0 and killingMachine == 0 and Rotorbar.isUsableCooldown("Obliterate")) then
            Rotorbar.showNext(Frost.obliterate)
            showedObliterate = true
        end

        -- Rune Weapon: No Breath of Sindragosa, show when resources depleted.
        local runeWeaponGo, runeWeaponKnown, runeWeaponCool = Rotorbar.isUsableCooldown("Hungering Rune Weapon")
        if (runeWeaponGo and not Rotorbar.isTalent("breathOfSindragosa") and runes <= 1 and runicPercent < .2) then
            Rotorbar.showNext(Frost.hungeringRuneWeapon)
        end

        -- The non-talent rune weapon
        if (not runeWeaponKnown and Rotorbar.isUsableCooldown("Empower Rune Weapon") and runes <= 1 and runicPercent < .2) then
            Rotorbar.showNext(Frost.empowerRuneWeapon)
        end

        -- Sindragosa Fury
        local furyGo = Rotorbar.isUsableCooldown("Sindragosa's Fury")
        if (furyGo and Rotorbar.isBoss()) then
            Rotorbar.showNext(Frost.sindragosasFury)
        end

        -- Breath of Sindragosa
        local breathGo, breathKnown, breathCool = Rotorbar.isUsableCooldown("Breath of Sindragosa")
        if (breathGo and runicPercent == 1 and Rotorbar.isBoss()) then
            if (runeWeaponKnown) then
                if (runeWeaponGo) then
                    Rotorbar.showNext(Frost.breathOfSindragosa)
                end
            else
                Rotorbar.showNext(Frost.breathOfSindragosa)
            end
        end

        -- Glacial Advance
        if (Rotorbar.isUsableCooldown("Glacial Advance")) then
            Rotorbar.showNext(Frost.glacialAdvance)
        end

        -- Remorseless Winter
        if (Rotorbar.isUsableCooldown("Remorseless Winter")) then
            Rotorbar.showNext(Frost.remorselessWinter)
        end

        -- Pillar of Frost
        local pillarGo = Rotorbar.isUsableCooldown("Pillar of Frost")
        if (pillarGo) then
            Rotorbar.showNext(Frost.pillarOfFrost)
        end

        -- Obliteration
        local obliterationGo, obliterationKnown, obliterationCool = Rotorbar.isUsableCooldown("Obliteration")
        if (obliterationGo and runicPercent > .75) then
            Rotorbar.showNext(Frost.obliteration)
        end

        -- Frost Fever Needed
        if (not showedHowling and Rotorbar.targetsNotDebuffed("Frost Fever") > 0 and Rotorbar.isUsableCooldown("Howling Blast")) then
            Rotorbar.showNext(Frost.howlingBlast)
            showedHowling = true
        end

        -- Frostscythe non-killingMachine
        if (not showedScythe and scythe >= 3 and Rotorbar.isUsableCooldown("Frostscythe")) then
            Rotorbar.showNext(Frost.frostscythe)
        end

        -- Obliterate non-killingMachine
        if (not showedObliterate and Rotorbar.isUsableCooldown("Obliterate")) then
            Rotorbar.showNext(Frost.obliterate)
        end

        -- Frost Strike
        if (Rotorbar.isUsableCooldown("Frost Strike")) then
            if (breathKnown and breathActive == 0) then
                if (not Rotorbar.isBoss() or (not breathGo and breathCool > 15) or (not runeWeaponGo and runeWeaponCool > 15)) then
                    Rotorbar.showNext(Frost.frostStrike)
                end
            elseif (obliterationKnown and obliterationActive == 0) then
                if (not obliterationGo and obliterationCool > 5) then
                    Rotorbar.showNext(Frost.frostStrike)
                end
            elseif (not breathKnown and not obliterationKnown) then
                Rotorbar.showNext(Frost.frostStrike)
            end
        end

        -- Howling Blast as last resort spell
        if (not showedHowling and IsUsableSpell("Howling Blast")) then
            Rotorbar.showNext(Frost.howlingBlast)
        end
    end
}