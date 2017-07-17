Guardian = {
    name = "Guardian",

    tank = true,

    class = function()
        Rotorbar.classIcon()
    end,

    icons = function()
        Guardian.bear = Rotorbar.buttonTime("Bear Form")
        Guardian.mangle = Rotorbar.buttonTime("Mangle")
        Guardian.thrash = Rotorbar.buttonTime("Thrash")
        Guardian.pulverize = Rotorbar.buttonTime("Pulverize")
        Guardian.maul = Rotorbar.buttonTime("Maul")
        Guardian.swipe = Rotorbar.buttonTime("Swipe")
    end,

    rotation = function()
        local ragePercent = UnitPower("player", SPELL_POWER_RAGE) /  UnitPowerMax("player", SPELL_POWER_RAGE)
        if (GetShapeshiftForm() ~= 3) then
            Rotorbar.showNext(Guardian.bear)

        else
            if (Rotorbar.isUsableCooldown("Mangle")) then
                Rotorbar.showNext(Guardian.mangle)
            end

            if (Rotorbar.isUsableCooldown("Thrash")) then
                Rotorbar.showNext(Guardian.thrash)
            end

            if (Rotorbar.isTalent("Pulverize")) then
                if ((Rotorbar.buffed("Pulverize") > 0 and Rotorbar.debuffed("Thrash") >= 5) or Rotorbar.debuffed("Thrash") >= 5) then
                    Rotorbar.showNext(Guardian.pulverize)
                end
            end

            if (ragePercent > .75) then
                Rotorbar.showNext(Guardian.maul)
            end

            if (Rotorbar.isUsableCooldown("Swipe")) then
                Rotorbar.showNext(Guardian.swipe)
            end
        end
    end
}