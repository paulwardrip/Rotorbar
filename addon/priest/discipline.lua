Discipline = {
    icons = {},
    flash = {},
    cools = {},
    color = {}
}

function Discipline.init()
    print ("Rotorbar Loaded Discipline Priest");

    Rotorbar.classIcon(1, 1, 0, 1)

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