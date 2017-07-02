Frost = {
    freezingFog = false,
    hornOfWinter = false,
    hungeringRuneWeapon = false,
    frostscythe = false,
    obliteration = false,
    breathOfSindragosa = false,
    glacialAdvance = false,

    icons = {},
    flash = {},
    cools = {},
    color = {},
    debuff = {},

    loaded = false
}

function Frost.init()
    Rotorbar.classIcon(0.25, 0.25, 1, 1)

    for tcol = 1,3 do
        for ttier = 1,7 do
            local talentID, name, texture, selected = GetTalentInfo(ttier,tcol,GetActiveSpecGroup())

            if (name == "Freezing Fog") then
                Frost.freezingFog = selected
            elseif (name == "Horn of Winter") then
                Frost.hornOfWinter = selected
            elseif (name == "Hungering Rune Weapon") then
                Frost.hungeringRuneWeapon = selected
            elseif (name == "Frostscythe") then
                Frost.frostscythe = selected
            elseif (name == "Obliteration") then
                Frost.obliteration = selected
            elseif (name == "Breath of Sindragosa") then
                Frost.breathOfSindragosa = selected
            elseif (name == "Glacial Advance") then
                Frost.glacialAdvance = selected
            end
        end
    end

    if (not Frost.loaded) then
        Frost.flash.deathStrike = Rotorbar.flash("Death Strike", 1, 0.5, 0.5, 1)
        Frost.flash.iceboundFortitude = Rotorbar.flash("Icebound Fortitude")
        Frost.flash.howlingBlast = Rotorbar.flash("Howling Blast", 1, 1, 1, .75)
        Frost.flash.obliterate = Rotorbar.flash("Obliterate", 1, .5, 1, 1)
        Frost.flash.frostscythe = Rotorbar.flash("Frostscythe", 1, .5, 1, 1)
        Frost.flash.hungeringRuneWeapon = Rotorbar.flash("Hungering Rune Weapon")

        Frost.icons.howlingBlast =  Rotorbar.buttonTime("Howling Blast")
        Frost.icons.frostStrike =  Rotorbar.buttonTime("Frost Strike")
        Frost.icons.obliterate =  Rotorbar.buttonTime("Obliterate")
        Frost.icons.sindragosasFury =  Rotorbar.buttonTime("Sindragosa's Fury")
        Frost.icons.remorselessWinter =  Rotorbar.buttonTime("Remorseless Winter")
        Frost.icons.pillarOfFrost =  Rotorbar.buttonTime("Pillar of Frost")
        Frost.icons.empowerRuneWeapon = Rotorbar.buttonTime("Empower Rune Weapon");

        Frost.icons.hornOfWinter =  Rotorbar.buttonTime("Horn of Winter");
        Frost.icons.hungeringRuneWeapon =  Rotorbar.buttonTime("Hungering Rune Weapon");
        Frost.icons.frostscythe =  Rotorbar.buttonTime("Frostscythe");
        Frost.icons.obliteration =  Rotorbar.buttonTime("Obliteration");
        Frost.icons.breathOfSindragosa =  Rotorbar.buttonTime("Breath of Sindragosa");
        Frost.icons.glacialAdvance =  Rotorbar.buttonTime("Glacial Advance");

        Frost.cools.sindragosasFury = Rotorbar.cooldown("Sindragosa's Fury")
        Frost.cools.pillarOfFrost = Rotorbar.cooldown("Pillar of Frost")
        Frost.cools.obliteration = Rotorbar.cooldown("Obliteration")
        Frost.cools.breathOfSindragosa = Rotorbar.cooldown("Breath of Sindragosa", "Hungering Rune Weapon")

        Frost.debuff.frostFever = Rotorbar.debuffIcon("Frost Fever", "195617")

        Frost.loaded = true
    end

    return function()
        local healthpercent = UnitHealth("player") / UnitHealthMax("player")
        local runicPercent = UnitPower("player", 6) / UnitPowerMax("player", 6)
        local runes = Rotorbar.runes()

        Rotorbar.showDebuff(Frost.debuff.frostFever)

        -- Death Strike when below 50%
        if (IsUsableSpell("Death Strike")) then
            if (healthpercent < .50) then
                Rotorbar.showNext (Frost.flash.deathStrike)
            end
        end

        -- Icebound Fortitude when critical
        if (IsUsableSpell("Icebound Fortitude")) then
            local start, duration = GetSpellCooldown("Icebound Fortitude")
            if (start == 0 and healthpercent < .30) then
                Rotorbar.showNext (Frost.flash.iceboundFortitude)
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
        if (Frost.frostscythe) then
            scythe = Rotorbar.targetsInRange("Frostscythe")
        end

        -- Horn of Winter, when resources depleted.
        if (Rotorbar.isUsableCooldown("Horn of Winter", Frost.hornOfWinter) and runes <= 2 and runicPercent <= .25) then
            Rotorbar.showNext(Frost.icons.hornOfWinter)
        end

        -- Frost Strike, Killing Machine and Rime priority in different order during Obliteration
        if (obliterationActive > 0) then
            -- Killing Machine: flashes Obliterate and if available, Frostscythe
            if (killingMachine > 0) then

                -- Frostscythe Killing Machine
                if (scythe >= 3 and Rotorbar.isUsableCooldown("Frostscythe")) then
                    Rotorbar.showNext(Frost.flash.frostscythe)
                    showedScythe = true
                end

                if (IsUsableSpell("Obliterate")) then
                    Rotorbar.showNext(Frost.flash.obliterate)
                    showedObliterate = true
                end

            end

            -- Obliteration: Frost Strike to trigger next Killing Machine.
            if (obliterationActive > 0 and IsUsableSpell("Frost Strike")) then
                Rotorbar.showNext(Frost.icons.frostStrike)
            end

        else
            local howlingRange = Rotorbar.targetsInRange("Howling Blast")
            if (rime > 0 and IsUsableSpell("Howling Blast")) then
                Rotorbar.showNext(Frost.flash.howlingBlast)
                showedHowling = true
            end

            -- Killing Machine: flashes Obliterate and if available, Frostscythe
            if (killingMachine > 0) then
                if (scythe >= 3) then
                    Rotorbar.showNext(Frost.flash.frostscythe)
                    showedScythe = true
                end

                if (IsUsableSpell("Obliterate")) then
                    Rotorbar.showNext(Frost.flash.obliterate)
                    showedObliterate = true
                end
            end
        end

        -- Rune Weapon: Breath of Sindragosa Active
        if (runeWeaponGo and breathActive > 0) then
            Rotorbar.showNext(Frost.flash.hungeringRuneWeapon)
        end

        -- Prioritize Obliterate during Breath of Sindragosa
        if (breathActive > 0 and killingMachine == 0 and Rotorbar.isUsableCooldown("Obliterate")) then
            Rotorbar.showNext(Frost.icons.obliterate)
            showedObliterate = true
        end

        -- Rune Weapon: No Breath of Sindragosa, show when resources depleted.
        local runeWeaponGo, runeWeaponCool = Rotorbar.isUsableCooldown("Hungering Rune Weapon", Frost.hungeringRuneWeapon)
        if (runeWeaponGo and not Frost.breathOfSindragosa and runes <= 1 and runicPercent < .2) then
            Rotorbar.showNext(Frost.icons.hungeringRuneWeapon)
        end

        -- The non-talent rune weapon
        if (not Frost.hungeringRuneWeapon and Rotorbar.isUsableCooldown("Empower Rune Weapon") and runes <= 1 and runicPercent < .2) then
            Rotorbar.showNext(Frost.icons.empowerRuneWeapon)
        end

        -- Sindragosa Fury
        local furyGo = Rotorbar.isUsableCooldown("Sindragosa's Fury")
        if (furyGo and Rotorbar.isBoss()) then
            Rotorbar.showNext(Frost.icons.sindragosasFury)
        end

        -- Breath of Sindragosa
        local breathGo, breathCool = Rotorbar.isUsableCooldown("Breath of Sindragosa", Frost.breathOfSindragosa)
        if (breathGo and runicPercent == 1 and Rotorbar.isBoss()) then
            if (Frost.hungeringRuneWeapon) then
                if (runeWeaponGo) then
                    Rotorbar.showNext(Frost.icons.breathOfSindragosa)
                end
            else
                Rotorbar.showNext(Frost.icons.breathOfSindragosa)
            end
        end

        -- Glacial Advance
        if (Rotorbar.isUsableCooldown("Glacial Advance", Frost.glacialAdvance)) then
            Rotorbar.showNext(Frost.icons.glacialAdvance)
        end

        -- Remorseless Winter
        if (Rotorbar.isUsableCooldown("Remorseless Winter")) then
            Rotorbar.showNext(Frost.icons.remorselessWinter)
        end

        -- Pillar of Frost
        local pillarGo = Rotorbar.isUsableCooldown("Pillar of Frost")
        if (pillarGo) then
            Rotorbar.showNext(Frost.icons.pillarOfFrost)
        end

        -- Obliteration
        local obliterationGo, obliterationCool = Rotorbar.isUsableCooldown("Obliteration", Frost.obliteration)
        if (obliterationGo and runicPercent > .75) then
            Rotorbar.showNext(Frost.icons.obliteration)
        end

        -- Frost Fever Needed
        if (not showedHowling and Rotorbar.targetsNotDebuffed("Frost Fever") > 0 and Rotorbar.isUsableCooldown("Howling Blast")) then
            Rotorbar.showNext(Frost.icons.howlingBlast)
            showedHowling = true
        end

        -- Frostscythe non-killingMachine
        if (not showedScythe and scythe >= 3 and Rotorbar.isUsableCooldown("Frostscythe")) then
            Rotorbar.showNext(Frost.icons.frostscythe)
        end

        -- Obliterate non-killingMachine
        if (not showedObliterate and Rotorbar.isUsableCooldown("Obliterate")) then
            Rotorbar.showNext(Frost.icons.obliterate)
        end

        -- Frost Strike
        if (Rotorbar.isUsableCooldown("Frost Strike")) then
            if (Frost.breathOfSindragosa and breathActive == 0) then
                if (not Rotorbar.isBoss() or (not breathGo and breathCool > 15) or (not runeWeaponGo and runeWeaponCool > 15)) then
                    Rotorbar.showNext(Frost.icons.frostStrike)
                end
            elseif (Frost.obliteration and obliterationActive == 0) then
                if (not obliterationGo and obliterationCool > 5) then
                    Rotorbar.showNext(Frost.icons.frostStrike)
                end
            elseif (not Frost.breathOfSindragosa and not Frost.obliteration) then
                Rotorbar.showNext(Frost.icons.frostStrike)
            end
        end

        -- Howling Blast as last resort spell
        if (not showedHowling and IsUsableSpell("Howling Blast")) then
            Rotorbar.showNext(Frost.icons.howlingBlast)
        end


        if (not pillarGo) then
            Rotorbar.showCooldown(Frost.cools.pillarOfFrost)
        end

        if (Frost.obliteration and not obliterationGo) then
            Rotorbar.showCooldown(Frost.cools.obliteration)
        end

        -- Show Cooldowns
        if (Frost.breathOfSindragosa) then
            if (not breathGo or (Frost.hungeringRuneWeapon and not runeWeaponGo)) then
                Rotorbar.showCooldown(Frost.cools.breathOfSindragosa)
            end
        end

        if (not furyGo) then
            Rotorbar.showCooldown(Frost.cools.sindragosasFury)
        end
    end
end