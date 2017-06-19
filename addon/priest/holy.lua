HolyPriest = {
    angelicFeather = false,
    icons = {},
    flash = {},
    cools = {},
    color = {}
}

function HolyPriest.init()
    print ("Rotorbar Loaded Holy Priest");

    Rotorbar.classIcon(1, 1, 1, 0.75)

        for tcol = 1,3 do
            for ttier = 1,7 do
                talentID, name, texture, selected, available, spellID, unknown, row, column, known = GetTalentInfo(ttier,tcol,GetActiveSpecGroup())

                if (name == "Angelic Feather" and selected) then
                    HolyPriest.angelicFeather = true
                    HolyPriest.cools.angelicFeather =  Rotorbar.cooldown("Angelic Feather");
                end
            end
        end

    HolyPriest.cools.prayerOfMending = Rotorbar.cooldown("Prayer of Mending")
    HolyPriest.cools.holyWordSerenity = Rotorbar.cooldown("Holy Word: Serenity")
    HolyPriest.cools.holyWordSanctify = Rotorbar.cooldown("Holy Word: Sanctify")
    HolyPriest.cools.lightOfTuure = Rotorbar.cooldown("Light of T'uure")
    HolyPriest.cools.purify = Rotorbar.cooldown("Purify")
    HolyPriest.cools.massDispel = Rotorbar.cooldown("Mass Dispel")
    HolyPriest.cools.divineHymn = Rotorbar.cooldown("Divine Hymn")
    HolyPriest.cools.guardianSpirit = Rotorbar.cooldown("Guardian Spirit")

    return function()
        local showPos = 0
        local showIcons = {}

        function showNext(icon)
            showIcons[showPos] = icon
            showPos = showPos + 1
        end

        showNext(HolyPriest.cools.prayerOfMending)
        showNext(HolyPriest.cools.lightOfTuure)
        showNext(HolyPriest.cools.holyWordSerenity)
        showNext(HolyPriest.cools.holyWordSanctify)
        showNext(HolyPriest.cools.divineHymn)
        showNext(HolyPriest.cools.guardianSpirit)
        showNext(HolyPriest.cools.massDispel)
        showNext(HolyPriest.cools.purify)
        if (HolyPriest.angelicFeather) then
            showNext(HolyPriest.cools.angelicFeather)
        end

        Rotorbar.resetButtons()
        Rotorbar.setIcons(showPos)

        for sp = 0, (showPos - 1) do
            Rotorbar.buttonActive(showIcons[sp])
        end
    end
end