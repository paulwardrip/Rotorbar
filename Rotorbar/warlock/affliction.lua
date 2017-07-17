Affliction = {
    name = "Affliction",

    stacks = {},

    class = function()
        Rotorbar.classIcon()
    end,

    icons = function()
        Affliction.haunt = Rotorbar.buttonTime("Haunt")
        Affliction.agony = Rotorbar.buttonTime("Agony")
        Affliction.corruption = Rotorbar.buttonTime("Corruption")
        Affliction.siphonLife = Rotorbar.buttonTime("Siphon Life")
        Affliction.unstableAffliction = Rotorbar.buttonTime("Unstable Affliction")
        Affliction.phantomSingularity = Rotorbar.buttonTime("Phantom Singularity")
        Affliction.reapSouls = Rotorbar.buttonTime("Reap Souls")
        Affliction.lifeTap = Rotorbar.buttonTime("Life Tap")
        Affliction.drainSoul = Rotorbar.buttonTime("Drain Soul")
        Affliction.seedOfCorruption = Rotorbar.buttonTime("Seed of Corruption")

        Affliction.summonDoomguard = Rotorbar.buttonTime("Summon Doomguard")
        Affliction.summonFelhunter = Rotorbar.buttonTime("Summon Felhunter")
        Affliction.agony = Rotorbar.buttonTime("Agony")

        Rotorbar.debuffIcon("Agony")
        Rotorbar.debuffIcon("Corruption")
        Rotorbar.debuffIcon("Siphon Life")
        Rotorbar.debuffIcon("Unstable Affliction")

        Rotorbar.cooldown("Soulstone")
    end,

    rotation = function()
        local soulShards = UnitPower("player", SPELL_POWER_SOUL_SHARDS)
        local soulShardPercent = soulShards / UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)
        local manaPercent = UnitPower("player", SPELL_POWER_MANA) / UnitPowerMax("player", SPELL_POWER_MANA)
        local healthpercent = UnitHealth("player") / UnitHealthMax("player")

        local unstableStacks = Affliction.stacks[UnitGUID("target")]

        if (not UnitExists("pet")) then
            if (Rotorbar.isTalent("Grimoire of Supremacy")) then
                Rotorbar.showNext(Affliction.summonDoomguard)
            else
                Rotorbar.showNext(Affliction.summonFelhunter)
            end
        end

        if (((Rotorbar.isTalent("Empowered Life Tap") and Rotorbar.buffed("Empowered Life Tap") == 0) or manaPercent <= .4) and healthpercent >= .6) then
            Rotorbar.showNext(Affliction.lifeTap)
        end

        if (Rotorbar.targets() >= 4) then
            if (Rotorbar.debuffed("Agony") == 0) then
                Rotorbar.showNext(Affliction.agony)
            end

            local reapGo, _, _, reapStack = Rotorbar.isUsableCooldown("Reap Souls")
            if (reapGo and reapStack >= 2) then
                Rotorbar.showNext(Affliction.reapSouls)
            end

            if (Rotorbar.isUsableCooldown("Seed of Corruption")) then
                Rotorbar.showNext(Affliction.seedOfCorruption)
            end
        else
            if (Rotorbar.isUsableCooldown("Haunt")) then
                Rotorbar.showNext(Affliction.haunt)
            end
            if (Rotorbar.debuffed("Agony") == 0) then
                Rotorbar.showNext(Affliction.agony)
            end
            if (Rotorbar.debuffed("Corruption") == 0) then
                Rotorbar.showNext(Affliction.corruption)
            end
            if (Rotorbar.debuffed("Siphon Life") == 0) then
                Rotorbar.showNext(Affliction.siphonLife)
            end

            if (Rotorbar.isUsableCooldown("Phantom Singularity")) then
                Rotorbar.showNext(Affliction.phantomSingularity)
            end

            if (unstableStacks == nil or (Rotorbar.isBoss() and soulShards >= 3)) then
                Rotorbar.showNext(Affliction.unstableAffliction)
            end

            local reapGo, _, _, reapStack = Rotorbar.isUsableCooldown("Reap Souls")
            if (reapGo and (reapStack >= 4 or (unstableStacks ~= nil and unstableStacks > 1))) then
                Rotorbar.showNext(Affliction.reapSouls)
            end

            if (healthpercent > .5) then
                Rotorbar.showNext(Affliction.drainSoul)
            end
        end
    end,

    aura = function(guid, name, id, added)
        if (name == "Unstable Affliction") then
            if (Affliction.stacks[guid] == nil) then
                Affliction.stacks[guid] = 1
            else
                Affliction.stacks[guid] = Affliction.stacks[guid] + added
                if (Affliction.stacks[guid] == 0) then
                    Affliction.stacks[guid] = nil
                end
            end
        end
    end
}