Discipline = {
    class = function()
        Rotorbar.classIcon(1, 1, 0, 1)
    end,

    icons = function()
        Discipline.shadowWordPain = Rotorbar.buttonTime("Shadow Word: Pain")
        Discipline.penance = Rotorbar.buttonTime("Penance")
        Discipline.purgeTheWicked = Rotorbar.buttonTime("Purge the Wicked")
        Discipline.smite = Rotorbar.buttonTime("Smite")
        Discipline.schism = Rotorbar.buttonTime("Schism")
        Discipline.powerWordSolace = Rotorbar.buttonTime("Power Word: Solace")
        Discipline.lightsWrath = Rotorbar.buttonTime("Light's Wrath")

        Rotorbar.cooldown("Divine Star")
        Rotorbar.cooldown("Halo")
        Rotorbar.cooldown("Mindbender")
        Rotorbar.cooldown("Shadowfiend")
        Rotorbar.cooldown("Power Infusion")
        Rotorbar.cooldown("Evangelism")

        Discipline.shadowWordPainDebuff = Rotorbar.debuffIcon("Shadow Word: Pain")
        Discipline.purgeTheWickedDebuff = Rotorbar.debuffIcon("Purge the Wicked")
    end,

    rotation = function()
        if (Rotorbar.isTalent("Purge the Wicked")) then
            local purge = Rotorbar.debuffed("Purge the Wicked")

            if (purge < 1) then
                Rotorbar.showNext(Discipline.purgeTheWicked)
            end

            Rotorbar.showDebuff(Discipline.purgeTheWickedDebuff)
        else
            if (Rotorbar.debuffed("Shadow Word: Pain") == 0) then
                Rotorbar.showNext(Discipline.shadowWordPain)
            end

            Rotorbar.showDebuff(Discipline.shadowWordPainDebuff)
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