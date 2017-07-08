Discipline = {
    name = "Discipline",

    class = function()
        Rotorbar.classIcon(1, 1, 0, 1)
    end,

    alwaysShowCooldowns = true,

    icons = function()
        Discipline.shadowWordPain = Rotorbar.buttonTime("Shadow Word: Pain")
        Discipline.penance = Rotorbar.buttonTime("Penance")
        Discipline.purgeTheWicked = Rotorbar.buttonTime("Purge the Wicked")
        Discipline.smite = Rotorbar.buttonTime("Smite")
        Discipline.schism = Rotorbar.buttonTime("Schism")
        Discipline.powerWordSolace = Rotorbar.buttonTime("Power Word: Solace")
        Discipline.lightsWrath = Rotorbar.buttonTime("Light's Wrath")

        Rotorbar.cooldown("Angelic Feather")
        Rotorbar.cooldown("Leap of Faith")
        Rotorbar.cooldown("Power Word: Shield")
        Rotorbar.cooldown("Pain Suppression")
        Rotorbar.cooldown("Purify")
        Rotorbar.cooldown("Mass Dispel")
        Rotorbar.cooldown("Power Word: Radiance")
        Rotorbar.cooldown("Power Word: Barrier")
        Rotorbar.cooldown("Divine Star")
        Rotorbar.cooldown("Halo")
        Rotorbar.cooldown("Mindbender")
        Rotorbar.cooldown("Shadowfiend").ifNotTalent("Mindbender")
        Rotorbar.cooldown("Power Infusion")
        Rotorbar.cooldown("Evangelism")
        Rotorbar.cooldown("Rapture")

        Rotorbar.debuffIcon("Shadow Word: Pain").ifNotTalent("Purge the Wicked")
        Rotorbar.debuffIcon("Purge the Wicked")
    end,

    rotation = function()
        if (Rotorbar.isTalent("Purge the Wicked")) then
            local purge = Rotorbar.debuffed("Purge the Wicked")

            if (purge < 1) then
                Rotorbar.showNext(Discipline.purgeTheWicked)
            end
        else
            if (Rotorbar.debuffed("Shadow Word: Pain") == 0) then
                Rotorbar.showNext(Discipline.shadowWordPain)
            end
        end

        if (Rotorbar.isUsableCooldown("Schism")) then
            Rotorbar.showNext(Discipline.schism)
        end

        if (Rotorbar.isUsableCooldown("Light's Wrath")) then
            Rotorbar.showNext(Discipline.lightsWrath)
        end

        if (Rotorbar.isUsableCooldown("Penance")) then
            Rotorbar.showNext(Discipline.penance)
        end

        if (Rotorbar.isUsableCooldown("Power Word: Solace")) then
            Rotorbar.showNext(Discipline.powerWordSolace)
        end

        Rotorbar.showNext(Discipline.smite)
    end

}