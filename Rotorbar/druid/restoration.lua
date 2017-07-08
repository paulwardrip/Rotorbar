RestoDruid = {
    name = "Restoration",

    class = function ()
        Rotorbar.classIcon(0,1,0.5,1)
    end,

    icons = function()
        Rotorbar.cooldown("Wild Growth")
        Rotorbar.cooldown("Swiftmend")
        Rotorbar.cooldown("Cenarion Ward")
        Rotorbar.cooldown("Tranquility")
        Rotorbar.cooldown("Innervate")
        Rotorbar.cooldown("Ironbark")
        Rotorbar.cooldown("Essence of G'Hanir")
        Rotorbar.cooldown("Flourish")
    end
}