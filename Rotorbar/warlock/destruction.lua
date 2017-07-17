Destruction = {
    name = "Destruction",

    class = function()
        Rotorbar.classIcon(.75,.5,0, 1)
    end,

    icons = function()
        Destruction.havoc = Rotorbar.buttonTime("Havoc")
        Destruction.conflagrate = Rotorbar.buttonTime("Conflagrate")
        Destruction.chaosBolt = Rotorbar.buttonTime("Chaos Bolt")
        Destruction.chaosBoltHavoc = Rotorbar.flash("Chaos Bolt", "Havoc")
        Destruction.immolate = Rotorbar.buttonTime("Immolate")
        Destruction.incinerate = Rotorbar.buttonTime("Incinerate")
        Destruction.drainLife = Rotorbar.buttonTime("Drain Life")
        Destruction.lifeTap = Rotorbar.buttonTime("Life Tap")
        Destruction.soulHarvest = Rotorbar.buttonTime("Soul Harvest")
        Destruction.dimensionalRift = Rotorbar.buttonTime("Dimensional Rift")
        Destruction.channelDemonfire = Rotorbar.buttonTime("Channel Demonfire")
        Destruction.rainOfFire = Rotorbar.buttonTime("Rain of Fire")
        Destruction.cataclysm = Rotorbar.buttonTime("Cataclysm")
        Destruction.summonImp = Rotorbar.buttonTime("Summon Imp")
        Destruction.summonInfernal = Rotorbar.buttonTime("Summon Infernal")
        Destruction.summonDoomguard = Rotorbar.buttonTime("Summon Doomguard")
        Destruction.grimoireImp = Rotorbar.buttonTime("Grimoire: Imp")

        Rotorbar.debuffIcon("Immolate")

        Rotorbar.cooldown("Havoc")
        Rotorbar.cooldown("Cataclysm")
        Rotorbar.cooldown("Channel Demonfire")
        Rotorbar.cooldown("Summon Infernal")
        Rotorbar.cooldown("Summon Doomguard")
        Rotorbar.cooldown("Grimoire: Imp")
        Rotorbar.cooldown("Soulstone")
    end,

    rotation = function()
        local soulShardPercent = UnitPower("player", SPELL_POWER_SOUL_SHARDS) / UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)
        local manaPercent = UnitPower("player", SPELL_POWER_MANA) / UnitPowerMax("player", SPELL_POWER_MANA)
        local healthpercent = UnitHealth("player") / UnitHealthMax("player")

        local riftShown = false
        local chaosShown = false
        local incinerateShown = false

        if (healthpercent <= .5) then
            Rotorbar.showNext(Destruction.drainLife)
        end

        if (not UnitExists("pet")) then
            if (Rotorbar.isTalent("Grimoire of Supremacy")) then
                Rotorbar.showNext(Affliction.summonDoomguard)
            elseif (Rotorbar.isUsableCooldown("Summon Imp")) then
                Rotorbar.showNext(Destruction.summonImp)
            end
        end

        if (((Rotorbar.isTalent("Empowered Life Tap") and Rotorbar.buffed("Empowered Life Tap") == 0) or manaPercent <= .4) and healthpercent >= .6) then
            Rotorbar.showNext(Destruction.lifeTap)
        end

        if (Rotorbar.isUsableCooldown("Chaos Bolt") and Rotorbar.targetsDebuffed("Havoc") > 0) then
            Rotorbar.showNext(Destruction.chaosBoltHavoc)
            chaosShown = true
        end

        if (Rotorbar.debuffed("Immolate") == 0) then
            Rotorbar.showNext(Destruction.immolate)
        end

        if (Rotorbar.isBoss()) then
            if (Rotorbar.buffed("Lord of Flames") > 0 or Rotorbar.targets() >= 3 and Rotorbar.isUsableCooldown("Summon Infernal")) then
                Rotorbar.showNext(Destruction.summonInfernal)
            elseif (Rotorbar.isUsableCooldown("Summon Doomguard")) then
                Rotorbar.showNext(Destruction.summonDoomguard)
            end
        end

        if (Rotorbar.isUsableCooldown("Soul Harvest")) then
            Rotorbar.showNext(Destruction.soulHarvest)
        end

        if (Rotorbar.targets() >= 3) then
            if (Rotorbar.isUsableCooldown("Cataclysm")) then
                Rotorbar.showNext(Destruction.cataclysm)
            end
            if (Rotorbar.isTalent("Fire and Brimstone")) then
                Rotorbar.showNext(Destruction.incinerate)
                incinerateShown = true
            end
            if (Rotorbar.isUsableCooldown("Rain of Fire")) then
                Rotorbar.showNext(Destruction.rainOfFire)
            end
        end

        if (not chaosShown and Rotorbar.isUsableCooldown("Chaos Bolt") and soulShardPercent == 1) then
            if (Rotorbar.targets() > 1 and Rotorbar.targetsDebuffed("Havoc") == 0 and Rotorbar.isUsableCooldown("Havoc")) then
                Rotorbar.showNext(Destruction.havoc)
            end
            Rotorbar.showNext(Destruction.chaosBolt)
            chaosShown = true
        end

        local riftGo, _, _, riftCharge = Rotorbar.isUsableCooldown("Dimensional Rift")
        if (riftGo and riftCharge >= 2 and soulShardPercent < .8) then
            Rotorbar.showNext(Destruction.dimensionalRift)
            riftShown = true
        end

        if (Rotorbar.isBoss() and Rotorbar.isUsableCooldown("Grimoire: Imp")) then
            Rotorbar.showNext(Destruction.grimoireImp)
        end

        if (Rotorbar.isUsableCooldown("Channel Demonfire")) then
            Rotorbar.showNext(Destruction.channelDemonfire)
        end

        if (Rotorbar.isUsableCooldown("Conflagrate")) then
            Rotorbar.showNext(Destruction.conflagrate)
        end

        if (not chaosShown and Rotorbar.isUsableCooldown("Chaos Bolt")) then
            if (Rotorbar.targets() > 1 and Rotorbar.targetsDebuffed("Havoc") == 0 and Rotorbar.isUsableCooldown("Havoc")) then
                Rotorbar.showNext(Destruction.havoc)
            end
            Rotorbar.showNext(Destruction.chaosBolt)
        end

        if (not riftShown and Rotorbar.isUsableCooldown("Dimensional Rift")) then
            Rotorbar.showNext(Destruction.dimensionalRift)
        end

        if (not incinerateShown and Rotorbar.isUsableCooldown("Incinerate")) then
            Rotorbar.showNext(Destruction.incinerate)
        end

    end
}