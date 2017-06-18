Unholy = {
    epidemic = false,
    blightedRuneWeapon = false,
    clawingShadows = false,
    corpseShield = false,
    darkArbiter = false,
    defile = false,
    soulReaper = false,
    icons = {},
    pulse = {},
    color = {}
}

function Unholy.init()
    print ("Rotorbar Loaded Unholy Death Knight");

    Rotorbar.classIcon(0, 0.75, 0, 0.75)

    for tcol = 1,3 do
        for ttier = 1,7 do
            talentID, name, texture, selected, available, spellID, unknown, row, column, known = GetTalentInfo(ttier,tcol,GetActiveSpecGroup())

            if (name == "Epidemic" and selected) then
                Unholy.epidemic = true
                Unholy.icons.epidemic =  Rotorbar.buttonTime("Epidemic", texture);
            end
            if (name == "Blighted Rune Weapon" and selected) then
                Unholy.blightedRuneWeapon = true
                Unholy.icons.blightedRuneWeapon =  Rotorbar.buttonTime("Blighted Rune Weapon", texture);
            end
            if (name == "Clawing Shadows" and selected) then
                Unholy.clawingShadows = true
                Unholy.icons.clawingShadows =  Rotorbar.buttonTime("Clawing Shadows", texture);
            end
            if (name == "Corpse Shield" and selected) then
                Unholy.corpseShield = true
                Unholy.pulse.corpseShield = Rotorbar.pulse("Corpse Shield", texture);
            end
            if (name == "Dark Arbiter" and selected) then
                Unholy.darkArbiter = true
                Unholy.icons.darkArbiter =  Rotorbar.buttonTime("Dark Arbiter", texture);
            end
            if (name == "Defile" and selected) then
                Unholy.defile = true
                Unholy.icons.defile =  Rotorbar.buttonTime("Defile", texture);
            end
            if (name == "Soul Reaper" and selected) then
                Unholy.soulReaper = true
                Unholy.icons.soulReaper =  Rotorbar.buttonTime("Soul Reaper", texture);
            end
        end
    end

    Unholy.icons.outbreak =  Rotorbar.buttonTime("Outbreak")
    Unholy.icons.deathCoil =  Rotorbar.buttonTime("Death Coil")
    Unholy.icons.scourgeStrike =  Rotorbar.buttonTime("Scourge Strike")
    Unholy.icons.festeringStrike =  Rotorbar.buttonTime("Festering Strike")
    Unholy.icons.armyoftheDead =  Rotorbar.buttonTime("Army of the Dead")
    Unholy.icons.darkTransformation =  Rotorbar.buttonTime("Dark Transformation")
    Unholy.icons.summonGargoyle =  Rotorbar.buttonTime("Summon Gargoyle")
    Unholy.icons.apocalypse =  Rotorbar.buttonTime("Apocalypse")

    Unholy.color.arbiterClawing =  Rotorbar.buttonTime("Clawing Shadows", nil, 1, 0.25, 0.75, 1)
    Unholy.color.arbiterFestering =  Rotorbar.buttonTime("Festering Strike", nil, 0.85, 0.5, 0.95, 1)

    Unholy.pulse.suddenDoom =  Rotorbar.pulse("Death Coil", nil, 0.95, 0.85, 0.50, 1)
    Unholy.pulse.arbiterCoil =  Rotorbar.pulse("Death Coil", nil, 0.90, 0, 0.90, 1)
    Unholy.pulse.raiseDead =  Rotorbar.pulse("Raise Dead")
    Unholy.pulse.deathStrike =  Rotorbar.pulse("Death Strike", nil, 1, 0.5, 0.5, 1)
    Unholy.pulse.iceboundFortitude =  Rotorbar.pulse("Icebound Fortitude")

    return function ()
        function activeArbiter()
            haveTotem, name, startTime, duration, icon = GetTotemInfo(3)
            return (haveTotem and name == "Val'kyr Battlemaiden")
        end

        local health = UnitHealth("player")
        local healthmax = UnitHealthMax("player")
        local healthpercent = health / healthmax

        local arbiter = Unholy.darkArbiter and activeArbiter()

        local showPos = 0
        local showIcons = {}

        function showNext(icon)
            showIcons[showPos] = icon
            showPos = showPos + 1
        end

        -- When health is low, suggest defensive spells.

        if (Unholy.corpseShield and IsUsableSpell("Corpse Shield")) then
            start, duration = GetSpellCooldown("Corpse Shield")
            if (start == 0 and healthpercent < .25) then
               showNext(Unholy.pulse.corpseShield)
            end
        end

        if (IsUsableSpell("Icebound Fortitude")) then
            start, duration = GetSpellCooldown("Icebound Fortitude")
            if (start == 0 and healthpercent < .35) then
               showNext (Unholy.pulse.iceboundFortitude)
            end
        end

        if (IsUsableSpell("Death Strike")) then
            if (healthpercent < .50) then
               showNext (Unholy.pulse.deathStrike)
            end
        end



        -- Spells to suggest during Dark Arbiter.

        if (arbiter) then

            if (IsUsableSpell("Death Coil")) then
                showNext (Unholy.pulse.arbiterCoil)
            end

            if (IsUsableSpell("Clawing Shadows") or IsUsableSpell("Scourge Strike")) then
                if (Rotorbar.debuffed("Festering Wound") > 0) then
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
                showNext (Unholy.pulse.suddenDoom)
            end

            if (IsUsableSpell("Army of the Dead") and Rotorbar.isBoss()) then
                local start, duration, enabled = GetSpellCooldown("Army of the Dead")
                if (start == 0) then
                    showNext (Unholy.icons.armyoftheDead)
                end
            end

            if (Unholy.darkArbiter) then
                if (IsUsableSpell("Dark Arbiter") and Rotorbar.isBoss() and UnitPower("player", 6) == UnitPowerMax("player", 6)) then
                    local start, duration, enabled = GetSpellCooldown("Dark Arbiter")
                    if (start == 0) then
                        showNext (Unholy.icons.darkArbiter)
                    end

                end
            else
                if (IsUsableSpell("Summon Gargoyle") and Rotorbar.isBoss()) then
                    local start, duration, enabled = GetSpellCooldown("Summon Gargoyle")
                    if (start == 0) then
                        showNext (Unholy.icons.summonGargoyle)
                    end
                end
            end

            if (UnitExists("pet")) then
                if (IsUsableSpell("Dark Transformation")) then
                    local start, duration, enabled = GetSpellCooldown("Dark Transformation");
                    if (start == 0) then
                        showNext (Unholy.icons.darkTransformation)
                    end
                end
             else
                showNext (Unholy.pulse.raiseDead)
             end

            if (Unholy.defile) then
                local start, duration, enabled = GetSpellCooldown("Defile");
                if (start == 0) then
                    showNext (Unholy.icons.defile)
                end
            end

            if (IsUsableSpell("Outbreak")) then
                if (Rotorbar.debuffed("Virulent Plague") < 1) then
                    showNext(Unholy.icons.outbreak)
                end
            end

            if (Unholy.blightedRuneWeapon) then
                local start, duration, enabled = GetSpellCooldown("Blighted Rune Weapon");
                if (start == 0) then
                    showNext (Unholy.icons.blightedRuneWeapon)
                end
            end

            if (Unholy.soulReaper) then
                if (UnitPower("player", 5) >= 3 and Rotorbar.debuffed("Festering Wound") >= 3) then
                    local start, duration, enabled = GetSpellCooldown("Soul Reaper");
                    if (start == 0) then
                        showNext (Unholy.icons.soulReaper)
                    end
                end
            end

            if (IsUsableSpell("Apocalypse")) then
                if (Rotorbar.debuffed("Festering Wound") >= 6) then
                    local start, duration, enabled = GetSpellCooldown("Apocalypse");
                    if (start == 0) then
                        showNext(Unholy.icons.apocalypse)
                    end
                end
            end

            if (IsUsableSpell("Clawing Shadows") or IsUsableSpell("Scourge Strike")) then
                if (Rotorbar.debuffed("Festering Wound") >= 4) then
                    if (IsUsableSpell("Clawing Shadows")) then
                        showNext(Unholy.icons.clawingShadows)
                    else
                        showNext(Unholy.icons.scourgeStrike)
                    end
                end
            end

            if (IsUsableSpell("Festering Strike")) then
                showNext(Unholy.icons.festeringStrike)
            end

            if (suddenDoom == 0 and IsUsableSpell("Death Coil")) then
                if (Unholy.darkArbiter and Rotorbar.isBoss()) then
                    local start, duration, enabled = GetSpellCooldown("Dark Arbiter");
                    if (start > 0 and (start+duration)-GetTime()>15) then
                        showNext (Unholy.icons.deathCoil)
                    end
                else
                    showNext (Unholy.icons.deathCoil)
                end
            end

            if (Unholy.epidemic and IsUsableSpell("Epidemic")) then
                if (Rotorbar.debuffed("Virulent Plague") > 0) then
                    local start, duration, enabled = GetSpellCooldown("Epidemic");
                    if (start == 0) then
                        showNext(Unholy.icons.epidemic)
                    end
                end
            end
        end

        Rotorbar.resetButtons()
        Rotorbar.setIcons(showPos)

        for sp = 0, (showPos - 1) do
            Rotorbar.buttonActive(showIcons[sp])
        end
    end
end