
function loadClassHandler()
    Rotorbar.specialization = GetSpecialization()

    if (Rotorbar.class == "Death Knight") then
        if (Rotorbar.specialization == 1) then
            Rotorbar.loadSpec(Blood)

        elseif (Rotorbar.specialization == 2) then
            Rotorbar.loadSpec(Frost)

        elseif (Rotorbar.specialization == 3) then
            Rotorbar.loadSpec(Unholy)
        end

    elseif (Rotorbar.class == "Priest") then
        if (Rotorbar.specialization == 1) then
            Rotorbar.loadSpec(Discipline)

        elseif (Rotorbar.specialization == 2) then
            Rotorbar.loadSpec(HolyPriest)

        elseif (Rotorbar.specialization == 3) then
            Rotorbar.loadSpec(Shadow)
        end

    elseif (Rotorbar.class == "Druid") then
        if (Rotorbar.specialization == 1) then
        elseif (Rotorbar.specialization == 2) then
            Rotorbar.loadSpec(Feral)

        elseif (Rotorbar.specialization == 3) then
        elseif (Rotorbar.specialization == 4) then
        end
    end
end
