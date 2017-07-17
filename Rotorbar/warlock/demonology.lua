Demonology = {
    name = "Demonology",

    empowerNeeded = false,

    class = function()
        Rotorbar.classIcon(.5, 0, .5, 1)
    end,

    icons = function()
        Demonology.doom = Rotorbar.buttonTime("Doom")
        Demonology.summonDarkglare = Rotorbar.buttonTime("Summon Darkglare")
        Demonology.summonDoomguard = Rotorbar.buttonTime("Summon Doomguard")
        Demonology.summonFelguard = Rotorbar.buttonTime("Summon Felguard")
        Demonology.grimoireFelguard = Rotorbar.buttonTime("Grimoire: Felguard")
        Demonology.callDreadstalkers = Rotorbar.buttonTime("Call Dreadstalkers")
        Demonology.handOfGuldan = Rotorbar.buttonTime("Hand of Gul'dan")
        Demonology.soulHarvest = Rotorbar.buttonTime("Soul Harvest")
        Demonology.shadowBolt = Rotorbar.buttonTime("Shadow Bolt")
        Demonology.demonicEmpowerment = Rotorbar.buttonTime("Demonic Empowerment")
        Demonology.consumption = Rotorbar.buttonTime("Thal'kiel's Consumption")
        Demonology.felstorm = Rotorbar.buttonTime("Felstorm")
        Demonology.demonwrath = Rotorbar.buttonTime("Demonwrath")
        Demonology.lifeTap = Rotorbar.buttonTime("Life Tap")

        Demonology.shadowyInspiration = Rotorbar.flash("Shadow Bolt", "Shadowy Inspiration")

        Rotorbar.debuffIcon("Doom")

        Rotorbar.cooldown("Summon Darkglare")
        Rotorbar.cooldown("Summon Doomguard")
        Rotorbar.cooldown("Grimoire: Felguard")
        Rotorbar.cooldown("Soul Harvest")
        Rotorbar.cooldown("Thal'kiel's Consumption")
        Rotorbar.cooldown("Soulstone")
    end,

    rotation = function()
        local soulShards = UnitPower("player", SPELL_POWER_SOUL_SHARDS)
        local soulShardPercent = soulShards / UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)
        local manaPercent = UnitPower("player", SPELL_POWER_MANA) / UnitPowerMax("player", SPELL_POWER_MANA)
        local healthpercent = UnitHealth("player") / UnitHealthMax("player")

        if (Rotorbar.lastCast == "Summon Darkglare" or Rotorbar.lastCast == "Summon Doomguard" or
                Rotorbar.lastCast == "Summon Felguard" or Rotorbar.lastCast == "Grimoire: Felguard" or
                Rotorbar.lastCast == "Call Dreadstalkers" or Rotorbar.lastCast == "Hand of Gul'dan") then
            Demonology.empowerNeeded = true

        elseif (Rotorbar.lastCast == "Demonic Empowerment") then
            Demonology.empowerNeeded = false
        end

        if (not UnitExists("pet")) then
            Rotorbar.showNext(Demonology.summonFelguard)
        end

        if (Rotorbar.petBuffed("Demonic Empowerment") == 0 or Demonology.empowerNeeded) then
            Rotorbar.showNext(Demonology.demonicEmpowerment)
        end

        if (manaPercent <= .4 and healthpercent >= .5) then
            Rotorbar.showNext(Demonology.lifeTap)
        end

        local showedShadow = false
        if (Rotorbar.buffed("Shadowy Inspiration") > 0) then
            Rotorbar.showNext(Demonology.shadowyInspiration)
            showedShadow = true
        end

        if (Rotorbar.debuffed("Doom") == 0) then
            Rotorbar.showNext(Demonology.doom)
        end

        if (Rotorbar.isUsableCooldown("Summon Darkglare")) then
            Rotorbar.showNext(Demonology.summonDarkglare)
        end

        if (Rotorbar.targets() >= 4 and Rotorbar.isTalent("Implosion")) then

        else
            if (Rotorbar.isUsableCooldown("Call Dreadstalkers")) then
                Rotorbar.showNext(Demonology.callDreadstalkers)
            end
        end

        if (Rotorbar.isUsableCooldown("Grimoire: Felguard")) then
            Rotorbar.showNext(Demonology.grimoireFelguard)
        end

        if (Rotorbar.isBoss() and Rotorbar.isUsableCooldown("Summon Doomguard")) then
            Rotorbar.showNext(Demonology.summonDoomguard)
        end

        if (soulShards >= 4) then
            Rotorbar.showNext(Demonology.handOfGuldan)
        end

        if (Rotorbar.isBoss() and Rotorbar.isUsableCooldown("Soul Harvest")) then
            Rotorbar.showNext(Demonology.soulHarvest)
        end

        if (Rotorbar.isBoss() and Rotorbar.isUsableCooldown("Thal'kiel's Consumption")) then
            Rotorbar.showNext(Demonology.consumption)
        end

        if (Rotorbar.isUsableCooldown("Felstorm")) then
            Rotorbar.showNext(Demonology.felstorm)
        end

        if (Rotorbar.targets() >= 3 or manaPercent >= .6) then
            Rotorbar.showNext(Demonology.demonwrath)
        end

        if (not showedShadow) then
            Rotorbar.showNext(Demonology.shadowBolt)
        end
    end
}