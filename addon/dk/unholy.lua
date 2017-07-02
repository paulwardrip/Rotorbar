Unholy = {
    class = function()
        Rotorbar.classIcon(0, 1, 0, 1)
    end,

    icons = function()
        Unholy.outbreak =  Rotorbar.buttonTime("Outbreak")
        Unholy.deathCoil =  Rotorbar.buttonTime("Death Coil")
        Unholy.scourgeStrike =  Rotorbar.buttonTime("Scourge Strike")
        Unholy.festeringStrike =  Rotorbar.buttonTime("Festering Strike")
        Unholy.armyoftheDead =  Rotorbar.buttonTime("Army of the Dead")
        Unholy.darkTransformation =  Rotorbar.buttonTime("Dark Transformation")
        Unholy.summonGargoyle =  Rotorbar.buttonTime("Summon Gargoyle")
        Unholy.apocalypse =  Rotorbar.buttonTime("Apocalypse")
        Unholy.deathAndDecay = Rotorbar.buttonTime("Death and Decay")
        Unholy.epidemic =  Rotorbar.buttonTime("Epidemic")
        Unholy.blightedRuneWeapon =  Rotorbar.buttonTime("Blighted Rune Weapon")
        --Unholy.clawingShadows = Rotorbar.buttonTime("Clawing Shadows")
        --Unholy.necrosisClawing = Rotorbar.flash("Clawing Shadows", 1, 0, 0.8, 1)
        Unholy.necrosisScourge = Rotorbar.flash("Scourge Strike", 1, 0, 0.8, 1)
        Unholy.corpseShield = Rotorbar.flash("Corpse Shield");
        --Unholy.darkArbiter =  Rotorbar.buttonTime("Dark Arbiter");
        Unholy.defile =  Rotorbar.buttonTime("Defile");
        Unholy.soulReaper =  Rotorbar.buttonTime("Soul Reaper");

        Unholy.arbiterCoil =  Rotorbar.flash("Death Coil", 0.90, 0, 0.70, 1)
        --Unholy.arbiterClawing =  Rotorbar.buttonTime("Clawing Shadows", 1, 0.25, 0.75, 1)
        Unholy.arbiterScourge =  Rotorbar.buttonTime("Scourge Strike", 1, 0.25, 0.75, 1)
        Unholy.arbiterFestering =  Rotorbar.buttonTime("Festering Strike", 0.85, 0.5, 0.95, 1)

        Unholy.suddenDoom =  Rotorbar.flash("Death Coil", 1, .75, 0, 1)
        Unholy.raiseDead =  Rotorbar.flash("Raise Dead")
        Unholy.deathStrike =  Rotorbar.flash("Death Strike", 1, 0.5, 0.5, 1)
        Unholy.iceboundFortitude =  Rotorbar.flash("Icebound Fortitude")

        Unholy.virulentPlague = Rotorbar.debuffIcon("Virulent Plague", "191587")
        Unholy.festeringWound = Rotorbar.debuffIcon("Festering Wound", "194310")

        Rotorbar.cooldown("Dark Transformation")
        Rotorbar.cooldown("Apocalypse")
        Rotorbar.cooldown("Blighted Rune Weapon")
        Rotorbar.cooldown("Army of the Dead")
        Rotorbar.cooldown("Summon Gargoyle", "Dark Arbiter")
    end,

    darkArbiterActive = function()
        if Rotorbar.isTalent("Dark Arbiter") then
            local haveTotem, name, startTime, duration, icon = GetTotemInfo(3)
            return (haveTotem and name == "Val'kyr Battlemaiden")
        else
            return false
        end
    end,

    rotation = function()
        Rotorbar.showDebuff(Unholy.virulentPlague)
        Rotorbar.showDebuff(Unholy.festeringWound)

        local healthpercent = UnitHealth("player") / UnitHealthMax("player")
        local runicPercent = UnitPower("player", 6) / UnitPowerMax("player", 6)
        local runes = Rotorbar.runes()

        local arbiter = Unholy.darkArbiterActive()
        local virulent, virulentLeft = Rotorbar.debuffed("Virulent Plague")
        local wounds = Rotorbar.debuffed("Festering Wound")

        local necro = Rotorbar.buffed("Necrosis")


        -- When health is low, suggest defensive spells.

        if (Rotorbar.isUsableCooldown("Corpse Shield") and healthpercent < .25) then
            Rotorbar.showNext(Unholy.corpseShield)
        end

        if (Rotorbar.isUsableCooldown("Icebound Fortitude") and healthpercent < .35) then
            Rotorbar.showNext (Unholy.iceboundFortitude)
        end

        if (Rotorbar.isUsableCooldown("Death Strike") and healthpercent < .50) then
            Rotorbar.showNext (Unholy.deathStrike)
        end

        local scourgeGo = Rotorbar.isUsableCooldown("Scourge Strike")


        -- Spells to suggest during Dark Arbiter.

        if (arbiter) then
            if (IsUsableSpell("Death Coil")) then
                Rotorbar.showNext (Unholy.arbiterCoil)
            end

            if (IsUsableSpell("Scourge Strike") and wounds > 0) then
                Rotorbar.showNext(Unholy.arbiterScourge)
            end

            if (IsUsableSpell("Festering Strike")) then
                Rotorbar.showNext(Unholy.arbiterFestering)
            end

        else

            -- Spells to suggest while not in Dark Arbiter

            local suddenDoom = Rotorbar.buffed("Sudden Doom")
            if (suddenDoom > 0) then
                Rotorbar.showNext (Unholy.suddenDoom)
            end

            local armyGo = Rotorbar.isUsableCooldown("Army of the Dead")
            if (armyGo and Rotorbar.isBoss()) then
                Rotorbar.showNext (Unholy.armyoftheDead)
            end

            local arbiterKnown = Rotorbar.isTalent("Dark Arbiter")
            local gargoyleGo, _, gargoyleLeft = Rotorbar.isUsableCooldown("Summon Gargoyle")
            local arbiterSoon = Rotorbar.isTalent("Dark Arbiter") and Rotorbar.isBoss() and (gargoyleGo or gargoyleLeft < 15)
            if (gargoyleGo and Rotorbar.isBoss() and (not arbiterKnown or runicPercent == 1)) then
                Rotorbar.showNext (Unholy.summonGargoyle)
            end

            local xformGo = Rotorbar.isUsableCooldown("Dark Transformation")
            if (UnitExists("pet")) then
                 if (xformGo) then
                     Rotorbar.showNext (Unholy.darkTransformation)
                end
             else
                Rotorbar.showNext (Unholy.raiseDead)
            end

            local defileGo, defileKnown = Rotorbar.isUsableCooldown("Defile")
            if (defileGo) then
                Rotorbar.showNext (Unholy.defile)
            end

            if (IsUsableSpell("Outbreak")) then
                local virulent = Rotorbar.targetsNotDebuffed("Virulent Plague")
                if (virulent > 0) then
                    Rotorbar.showNext(Unholy.outbreak)
                end
            end

            if (Rotorbar.isUsableCooldown("Blighted Rune Weapon")) then
                Rotorbar.showNext (Unholy.blightedRuneWeapon)
            end

            if (Rotorbar.isUsableCooldown("Soul Reaper") and runes >= 3 and wounds >= 3) then
                Rotorbar.showNext (Unholy.soulReaper)
            end

            local apocalypseGo, _, apocalypseLeft = Rotorbar.isUsableCooldown("Apocalypse")
            local apocalypseSoon = ((apocalypseGo or apocalypseLeft < 5) and Rotorbar.isBoss())

            if (apocalypseGo and wounds >= 6) then
                Rotorbar.showNext(Unholy.apocalypse)
            end

            -- For Necrosis prioritize the Death Coils
            local showedNecrosis = false
            if (Rotorbar.isTalent("Necrosis")) then
                local apocalypseStealing = (apocalypseSoon and wounds < 8)

                if (necro == 0 and suddenDoom == 0 and IsUsableSpell("Death Coil") and wounds >= 1 and runes >= 1
                    and not apocalypseStealing and not arbiterSoon) then
                    Rotorbar.showNext (Unholy.deathCoil)
                    showedNecrosis = true
                end
            end

            -- Death and Decay whenever cleave is possible
            if (not defileKnown) then
                if (Rotorbar.targets() >= 3 and Rotorbar.buffed("Death and Decay") == 0 and Rotorbar.isUsableCooldown("Death and Decay")) then
                    Rotorbar.showNext(Unholy.deathAndDecay)
                end
            end

            if (IsUsableSpell("Scourge Strike")) then
                local aoeCheck

                -- Clawing Shadows has range like a spell, Scourge Strike is melee
                if (Rotorbar.isTalent("Clawing Shadows")) then
                    aoeCheck = Rotorbar.targetsInRange("Clawing Shadows")
                else
                    aoeCheck = Rotorbar.targetsInRange("Scourge Strike")
                end

                -- Against multiple targets you should always use Clawing Shadows (unless Apocalypse is almost ready, then make more sores)
                if ((not apocalypseReady and wounds >= 1) or wounds >= 8) then

                    if (necro > 0) then
                        Rotorbar.showNext(Unholy.necrosisScourge)
                    else
                        Rotorbar.showNext(Unholy.scourgeStrike)
                    end
                end
            end

            -- Epidemic: Bursting Sores and Necrosis both do much more damage so this will rarely show up in a build with those two talents.
            -- 2 targets at 40% mastery: ~450%
            -- 3 targets: ~765%
            -- 4 targets: ~1160%
            if (Rotorbar.isUsableCooldown("Epidemic")) then
                local withPlague = Rotorbar.targetsDebuffed("Virulent Plague")
                local withSores = Rotorbar.targetsDebuffed("Festering Wound")
                local necrosisReady = Rotorbar.buffed("Necrosis")
                if (withPlague >= 3 and necrosisReady == 0) then
                    if (Rotorbar.isTalent("Bursting Sores") and withSores == 0 and runes <= 1) then
                        Rotorbar.showNext(Unholy.epidemic)
                    else
                        Rotorbar.showNext(Unholy.epidemic)
                    end
                end
            end

            -- Festering Strike: Make more sores
            if (IsUsableSpell("Festering Strike")) then
                Rotorbar.showNext(Unholy.festeringStrike)
            end

            -- Death Coil Filler
            if (suddenDoom == 0 and showedNecrosis == false and IsUsableSpell("Death Coil")) then
                if (not arbiterSoon) then
                    Rotorbar.showNext (Unholy.deathCoil)
                end
            end
        end
    end
}