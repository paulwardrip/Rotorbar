Shadow = {
    icons = {},
    flash = {},
    cools = {},
    color = {}
}

function Shadow.init()
    print ("Rotorbar Loaded Shadow Priest");

    Rotorbar.classIcon(1, .5, 1, 0.75)

        return function()
            local showPos = 0
            local showIcons = {}

            function showNext(icon)
                showIcons[showPos] = icon
                showPos = showPos + 1
            end


            Rotorbar.resetButtons()
            Rotorbar.setIcons(showPos)

            for sp = 0, (showPos - 1) do
                Rotorbar.buttonActive(showIcons[sp])
            end
        end
end