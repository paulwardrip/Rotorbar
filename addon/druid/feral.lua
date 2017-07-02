Feral = {
    class = function()
        Rotorbar.classIcon(1, 0.75, 0, 1)
    end,

    icons = function()
        Feral.catform = Rotorbar.buttonTime("Cat Form")
        Feral.prowl = Rotorbar.buttonTime("Prowl")
        Feral.rip = Rotorbar.buttonTime("Rip")
        Feral.rake = Rotorbar.buttonTime("Rake")
        Feral.thrash = Rotorbar.buttonTime("Thrash")
        Feral.shred = Rotorbar.buttonTime("Shred")
        Feral.swipe = Rotorbar.buttonTime("Swipe")
        Feral.savageRoar = Rotorbar.buttonTime("Savage Roar")
        Feral.ferociousBite = Rotorbar.buttonTime("Ferocious Bite")
        Feral.tigersFury = Rotorbar.buttonTime("Tiger's Fury")
        Feral.ashamanesFrenzy = Rotorbar.buttonTime("Ashamane's Frenzy")
        Feral.king = Rotorbar.buttonTime("Incarnation: King of the Jungle")
        Feral.berserk = Rotorbar.buttonTime("Berserk")

        Rotorbar.cooldown("Tiger Fury")
        Rotorbar.cooldown("Ashamane's Frenzy")
        Rotorbar.cooldown("Berserk")

        Feral.ripDebuff = Rotorbar.debuffIcon("Rip")
        Feral.rakeDebuff = Rotorbar.debuffIcon("Rake")
    end,

    rotation =  function()
        if (GetShapeshiftForm() ~= 2) then
            Rotorbar.showNext(Feral.catform)

        else
            local energy = UnitPower("player", 3)
            local comboPoints = UnitPower("player", 4)
            local targetHealthPercent = UnitHealth("target") / UnitHealthMax("target")

            Rotorbar.showDebuff(Feral.ripDebuff)
            Rotorbar.showDebuff(Feral.rakeDebuff)

            if (Rotorbar.buffed("Prowl") == 0 and Rotorbar.isUsableCooldown("Prowl")) then
                Rotorbar.showNext(Feral.prowl)

            elseif (Rotorbar.buffed("Prowl") > 0) then
                Rotorbar.showNext(Feral.rake)

            else
                local ripOn, ripLeft = Rotorbar.debuffed("Rip")
                local showedBite = false

                if (comboPoints == 5 and targetHealthPercent <= .25 or (Rotorbar.isTalent("Sabertooth") and ripLeft > 0)) then
                    Rotorbar.showNext(Feral.ferociousBite)
                    showedBite = true
                end

                if (Rotorbar.isUsableCooldown("Rip") and (ripOn == 0 or (ripLeft <= 5 and not Rotorbar.isTalent("Sabertooth"))) and comboPoints == 5) then
                    Rotorbar.showNext(Feral.rip)
                end

                local roarOn, roarLeft = Rotorbar.buffed("Savage Roar")
                if (Rotorbar.isUsableCooldown("Savage Roar") and comboPoints == 5 and roarOn == 0) then
                    Rotorbar.showNext(Feral.savageRoar)
                end

                if (comboPoints == 5 and not showedBite) then
                    Rotorbar.showNext(Feral.ferociousBite)
                end

                if (Rotorbar.isTalent("Incarnation: King of the Jungle")) then
                    if (Rotorbar.isUsableCooldown("Incarnation: King of the Jungle")) then
                        Rotorbar.showNext(Feral.king)
                    end
                elseif (Rotorbar.isUsableCooldown("Berserk") and Rotorbar.isUsableCooldown("Ashamane's Frenzy")
                        and Rotorbar.isUsableCooldown("Tiger's Fury") and Rotorbar.isBoss()) then
                    Rotorbar.showNext(Feral.berserk)
                end

                if ((energy <= 30 or Rotorbar.buffed("Berserk") > 0) and Rotorbar.isUsableCooldown("Tiger's Fury")) then
                    Rotorbar.showNext(Feral.tigersFury)
                end

                if (Rotorbar.isUsableCooldown("Ashamane's Frenzy")) then
                    Rotorbar.showNext(Feral.ashamanesFrenzy)
                end

                if (Rotorbar.targets() >= 3 and Rotorbar.debuffed("Thrash") == 0) then
                    Rotorbar.showNext(Feral.thrash)
                end

                if (Rotorbar.isUsableCooldown("Rake") and Rotorbar.debuffed("Rake") == 0) then
                    Rotorbar.showNext(Feral.rake)
                end

                if (Rotorbar.targets() >= 3) then
                    if (Rotorbar.isUsableCooldown("Swipe")) then
                        Rotorbar.showNext(Feral.swipe)
                    end
                else
                    if (Rotorbar.isUsableCooldown("Shred")) then
                        Rotorbar.showNext(Feral.shred)
                    end
                end
            end
        end
    end
}