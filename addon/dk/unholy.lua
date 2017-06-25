Unholy = {
    epidemic = false,
    blightedRuneWeapon = false,
    clawingShadows = false,
    corpseShield = false,
    darkArbiter = false,
    defile = false,
    soulReaper = false,
    necrosis = false,

    icons = {},
    flash = {},
    cools = {},
    color = {},

    loaded = false
}

function Unholy.init()
    Rotorbar.classIcon(0, 1, 0, 1)

    for tcol = 1,3 do
        for ttier = 1,7 do
            local talentID, name, texture, selected, available, spellID, unknown, row, column, known = GetTalentInfo(ttier,tcol,GetActiveSpecGroup())

            if (name == "Bursting Sores" and selected) then
                Unholy.burstingSores = true
            end
            if (name == "Epidemic" and selected) then
                Unholy.epidemic = true
            end
            if (name == "Blighted Rune Weapon" and selected) then
                Unholy.blightedRuneWeapon = true
            end
            if (name == "Clawing Shadows" and selected) then
                Unholy.clawingShadows = true
            end
            if (name == "Corpse Shield" and selected) then
                Unholy.corpseShield = true
            end
            if (name == "Necrosis" and selected) then
                Unholy.necrosis = true
            end
            if (name == "Dark Arbiter" and selected) then
                Unholy.darkArbiter = true
            end
            if (name == "Defile" and selected) then
                Unholy.defile = true
            end
            if (name == "Soul Reaper" and selected) then
                Unholy.soulReaper = true
            end
        end
    end

    if (not Unholy.loaded) then
        Unholy.icons.outbreak =  Rotorbar.buttonTime("Outbreak")
        Unholy.icons.deathCoil =  Rotorbar.buttonTime("Death Coil")
        Unholy.icons.scourgeStrike =  Rotorbar.buttonTime("Scourge Strike")
        Unholy.icons.festeringStrike =  Rotorbar.buttonTime("Festering Strike")
        Unholy.icons.armyoftheDead =  Rotorbar.buttonTime("Army of the Dead")
        Unholy.icons.darkTransformation =  Rotorbar.buttonTime("Dark Transformation")
        Unholy.icons.summonGargoyle =  Rotorbar.buttonTime("Summon Gargoyle")
        Unholy.icons.apocalypse =  Rotorbar.buttonTime("Apocalypse")
        Unholy.icons.deathAndDecay = Rotorbar.buttonTime("Death and Decay")

        Unholy.icons.epidemic =  Rotorbar.buttonTime("Epidemic");
        Unholy.icons.blightedRuneWeapon =  Rotorbar.buttonTime("Blighted Rune Weapon");
        Unholy.icons.clawingShadows = Rotorbar.buttonTime("Clawing Shadows");
        Unholy.flash.necrosisClawing = Rotorbar.flash("Clawing Shadows", 1, 0, 0.8, 1);
        Unholy.flash.necrosisScourge = Rotorbar.flash("Scourge Strike", 1, 0, 0.8, 1);
        Unholy.flash.corpseShield = Rotorbar.flash("Corpse Shield");
        Unholy.icons.darkArbiter =  Rotorbar.buttonTime("Dark Arbiter");
        Unholy.icons.defile =  Rotorbar.buttonTime("Defile");
        Unholy.icons.soulReaper =  Rotorbar.buttonTime("Soul Reaper");

        Unholy.flash.arbiterCoil =  Rotorbar.flash("Death Coil", 0.90, 0, 0.70, 1)
        Unholy.color.arbiterClawing =  Rotorbar.buttonTime("Clawing Shadows", 1, 0.25, 0.75, 1)
        Unholy.color.arbiterFestering =  Rotorbar.buttonTime("Festering Strike", 0.85, 0.5, 0.95, 1)

        Unholy.flash.suddenDoom =  Rotorbar.flash("Death Coil", 1, .75, 0, 1)
        Unholy.flash.raiseDead =  Rotorbar.flash("Raise Dead")
        Unholy.flash.deathStrike =  Rotorbar.flash("Death Strike", 1, 0.5, 0.5, 1)
        Unholy.flash.iceboundFortitude =  Rotorbar.flash("Icebound Fortitude")

        Unholy.cools.armyoftheDead = Rotorbar.cooldown("Army of the Dead")
        Unholy.cools.darkTransformation =  Rotorbar.cooldown("Dark Transformation")
        Unholy.cools.summonGargoyle =  Rotorbar.cooldown("Summon Gargoyle")
        Unholy.cools.darkArbiter =  Rotorbar.cooldown("Dark Arbiter")
        Unholy.cools.apocalypse =  Rotorbar.cooldown("Apocalypse")
        Unholy.loaded = true
    end

    return function ()
        local function activeArbiter()
            local haveTotem, name, startTime, duration, icon = GetTotemInfo(3)
            return (haveTotem and name == "Val'kyr Battlemaiden")
        end

        local healthpercent = UnitHealth("player") / UnitHealthMax("player")
        local runicPercent = UnitPower("player", 6) / UnitPowerMax("player", 6)
        local runes = Rotorbar.runes()


        local arbiter = Unholy.darkArbiter and activeArbiter()
        local virulent, virulentLeft = Rotorbar.debuffed("Virulent Plague")
        local wounds = Rotorbar.debuffed("Festering Wound")

        local necro = Rotorbar.buffed("Necrosis")

        local showPos = 0
        local showIcons = {}

        local function showNext(icon)
            showIcons[showPos] = icon
            showPos = showPos + 1
        end

        -- When health is low, suggest defensive spells.

        if (Rotorbar.isUsableCooldown("Corpse Shield") and healthpercent < .25) then
           showNext(Unholy.flash.corpseShield)
        end

        if (Rotorbar.isUsableCooldown("Icebound Fortitude") and healthpercent < .35) then
           showNext (Unholy.flash.iceboundFortitude)
        end

        if (Rotorbar.isUsableCooldown("Death Strike") and healthpercent < .50) then
           showNext (Unholy.flash.deathStrike)
        end



        -- Spells to suggest during Dark Arbiter.

        if (arbiter) then
            if (IsUsableSpell("Death Coil")) then
                showNext (Unholy.flash.arbiterCoil)
            end

            if (IsUsableSpell("Clawing Shadows") or IsUsableSpell("Scourge Strike")) then
                if (wounds > 0) then
                    if (IsUsableSpell("Clawing Shadows")) then
                        showNext(Unholy.color.arbiterClawing)
                    else
                        showNext(Unholy.icons.scourgeStrike)
                    end
                end
            end

            if (IsUsableSpell("Festering Strike")) then
                showNext(Unholy.color.arbiterFestering)
            end

        else

            -- Spells to suggest while not in Dark Arbiter

            local suddenDoom = Rotorbar.buffed("Sudden Doom")
            if (suddenDoom > 0) then
                showNext (Unholy.flash.suddenDoom)
            end

            local armyGo = Rotorbar.isUsableCooldown("Army of the Dead")
            if (armyGo and Rotorbar.isBoss()) then
                 showNext (Unholy.icons.armyoftheDead)
            end

            local arbiterGo, arbiterLeft = Rotorbar.isUsableCooldown("Dark Arbiter", Unholy.darkArbiter)
            local gargoyleGo = false

            if (Unholy.darkArbiter) then
                if (arbiterGo and Rotorbar.isBoss() and runicPercent == 1) then
                    showNext (Unholy.icons.darkArbiter)
                end
            else
                gargoyleGo = Rotorbar.isUsableCooldown("Summon Gargoyle")
                if (gargoyleGo and Rotorbar.isBoss()) then
                    showNext (Unholy.icons.summonGargoyle)
                end
            end

            local xformGo = Rotorbar.isUsableCooldown("Dark Transformation")
            if (UnitExists("pet")) then
                 if (xformGo) then
                    showNext (Unholy.icons.darkTransformation)
                end
             else
                showNext (Unholy.flash.raiseDead)
             end

            if (Rotorbar.isUsableCooldown("Defile", Unholy.defile)) then
               showNext (Unholy.icons.defile)
            end

            if (IsUsableSpell("Outbreak")) then
                local virulent = Rotorbar.targetsNotDebuffed("Virulent Plague")
                if (virulent > 0) then
                    showNext(Unholy.icons.outbreak)
                end
            end

            if (Rotorbar.isUsableCooldown("Blighted Rune Weapon", Unholy.blightedRuneWeapon)) then
                showNext (Unholy.icons.blightedRuneWeapon)
            end

            if (Rotorbar.isUsableCooldown("Soul Reaper", Unholy.soulReaper) and runes >= 3 and wounds >= 3) then
                showNext (Unholy.icons.soulReaper)
            end

            local apocalypseGo, apocalypseLeft = Rotorbar.isUsableCooldown("Apocalypse")
            local apocalypseReady = ((apocalypseGo or apocalypseLeft < 5) and Rotorbar.isBoss())

            if (apocalypseGo and wounds >= 6) then
                showNext(Unholy.icons.apocalypse)
            end

            -- For Necrosis prioritize the Death Coils
            local showedNecrosis = false
            if (Unholy.necrosis) then

                if (necro == 0 and suddenDoom == 0 and IsUsableSpell("Death Coil") and wounds >= 1 and (not apocalypseReady or wounds >= 8)
                    and (IsUsableSpell("Clawing Shadows") or IsUsableSpell("Scourge Strike")) and
                    (not Unholy.darkArbiter or ((not arbiterGo and arbiterLeft > 15) or not Rotorbar.isBoss()))) then
                    showNext (Unholy.icons.deathCoil)
                    showedNecrosis = true
                end
            end

            -- Death and Decay whenever cleave is possible
            if (not Unholy.defile) then
                if ((Unholy.clawingShadows and Rotorbar.targetsInRange("Clawing Shadows") >= 3) or Rotorbar.targetsInRange("Scourge Strike") >= 3) then
                    if (Rotorbar.buffed("Death and Decay") == 0 and Rotorbar.isUsableCooldown("Death and Decay")) then
                        showNext(Unholy.icons.deathAndDecay)
                    end
                end
            end

            if (IsUsableSpell("Clawing Shadows") or IsUsableSpell("Scourge Strike")) then
                local aoeCheck

                -- Clawing Shadows has range like a spell, Scourge Strike is melee
                if (Unholy.clawingShadows) then
                    aoeCheck = Rotorbar.targetsInRange("Clawing Shadows")
                else
                    aoeCheck = Rotorbar.targetsInRange("Scourge Strike")
                end

                -- Against multiple targets you should always use Clawing Shadows (unless Apocalypse is almost ready, then make more sores)
                if ((not apocalypseReady and wounds >= 1) or wounds >= 8) then

                    if (necro > 0) then
                        if (Unholy.clawingShadows) then
                            showNext(Unholy.flash.necrosisClawing)
                        else
                            showNext(Unholy.flash.necrosisScourge)
                        end
                    else
                        if (Unholy.clawingShadows) then
                            showNext(Unholy.icons.clawingShadows)
                        else
                            showNext(Unholy.icons.scourgeStrike)
                        end
                    end
                end
            end

            -- Epidemic: Bursting Sores and Necrosis both do much more damage so this will rarely show up in a build with those two talents.
            -- 2 targets at 40% mastery: ~450%
            -- 3 targets: ~765%
            -- 4 targets: ~1160%
            if (Rotorbar.isUsableCooldown("Epidemic", Unholy.epidemic)) then
                local withPlague = Rotorbar.targetsDebuffed("Virulent Plague")
                local withSores = Rotorbar.targetsDebuffed("Festering Wound")
                local necrosisReady = Rotorbar.buffed("Necrosis")
                if (withPlague >= 3 and necrosisReady == 0) then
                    if (Unholy.burstingSores and withSores == 0 and runes <= 1) then
                        showNext(Unholy.icons.epidemic)
                    else
                        showNext(Unholy.icons.epidemic)
                    end
                end
            end

            -- Festering Strike: Make more sores
            if (IsUsableSpell("Festering Strike")) then
                showNext(Unholy.icons.festeringStrike)
            end

            -- Death Coil Filler
            if (suddenDoom == 0 and showedNecrosis == false and IsUsableSpell("Death Coil")) then
                if (not Unholy.darkArbiter or (not arbiterGo and arbiterLeft > 15)) then
                    showNext (Unholy.icons.deathCoil)
                end
            end

            -- Trinket Ready Icons
            local t1useable, t1ready, t1icon = Rotorbar.equipmentIcon(13)
            local t2useable, t2ready, t2icon = Rotorbar.equipmentIcon(14)

            if (t1useable and t1ready) then showNext(t1icon) end
            if (t2useable and t2ready) then showNext(t2icon) end


            -- Show cooldowns
            if (not xformGo) then
                showNext(Unholy.cools.darkTransformation)
            end

            if (not apocalypseGo) then
                showNext(Unholy.cools.apocalypse)
            end

            if (not armyGo and Rotorbar.isBoss()) then
                showNext(Unholy.cools.armyoftheDead)
            end

            if (Unholy.darkArbiter) then
                if (not arbiterGo and Rotorbar.isBoss()) then
                    showNext(Unholy.cools.darkArbiter)
                end
            else
                if (not gargoyleGo and Rotorbar.isBoss()) then
                    showNext(Unholy.cools.summonGargoyle)
                end
            end

            -- Trinket Cooldown Icons
            if (t1useable and not t1ready) then showNext(t1icon) end
            if (t2useable and not t2ready) then showNext(t2icon) end

        end

        Rotorbar.resetButtons()
        Rotorbar.setIcons(showPos)

        for sp = 0, (showPos - 1) do
            Rotorbar.buttonActive(showIcons[sp])
        end
    end
end