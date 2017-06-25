
function loadClassHandler()
    local currentSpec = GetSpecialization()

    if (UnitClass("player") == "Death Knight") then
        if (currentSpec == 1) then
            handler = Blood.init()
            handler()

        elseif (currentSpec == 2) then
            handler = Frost.init()
            handler()

        elseif (currentSpec == 3) then
            handler = Unholy.init()
            handler()
        end

    elseif (UnitClass("player") == "Priest") then
        if (currentSpec == 1) then
            handler = Discipline.init()
            handler()

        elseif (currentSpec == 2) then
            handler = HolyPriest.init()
            handler()

        elseif (currentSpec == 3) then
            handler = Shadow.init()
            handler()
        end
    end
end
