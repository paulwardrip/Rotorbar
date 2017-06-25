HolyPriest = {
    icons = {},
    flash = {},
    cools = {},
    color = {},
    loaded = false
}

function HolyPriest.init()
    HolyPriest.angelicFeather = false
    HolyPriest.bodyAndMind = false
    HolyPriest.shiningForce = false
    HolyPriest.symbolOfHope = false
    HolyPriest.divineStar = false
    HolyPriest.halo = false
    HolyPriest.circleOfHealing = false
    HolyPriest.apotheosis = false

    Rotorbar.classIcon()

    for tcol = 1,3 do
        for ttier = 1,7 do
            local talentID, name, texture, selected = GetTalentInfo(ttier,tcol,GetActiveSpecGroup())

            if (name == "Angelic Feather" and selected) then
                HolyPriest.angelicFeather = true
            elseif (name == "Body and Mind" and selected) then
                HolyPriest.bodyAndMind = true
            elseif (name == "Shining Force" and selected) then
                HolyPriest.shiningForce = true
            elseif (name == "Symbol of Hope" and selected) then
                HolyPriest.symbolOfHope = true
            elseif (name == "Divine Star" and selected) then
                HolyPriest.divineStar = true
            elseif (name == "Halo" and selected) then
                HolyPriest.halo = true
            elseif (name == "Circle of Healing" and selected) then
                HolyPriest.circleOfHealing = true
            elseif (name == "Apotheosis" and selected) then
                HolyPriest.apotheosis = true
            end
        end
    end

    if (not HolyPriest.loaded) then
        HolyPriest.cools.prayerOfMending = Rotorbar.cooldown("Prayer of Mending")
        HolyPriest.cools.holyWordSerenity = Rotorbar.cooldown("Holy Word: Serenity")
        HolyPriest.cools.holyWordSanctify = Rotorbar.cooldown("Holy Word: Sanctify")
        HolyPriest.cools.lightOfTuure = Rotorbar.cooldown("Light of T'uure")
        HolyPriest.cools.purify = Rotorbar.cooldown("Purify")
        HolyPriest.cools.massDispel = Rotorbar.cooldown("Mass Dispel")
        HolyPriest.cools.divineHymn = Rotorbar.cooldown("Divine Hymn")
        HolyPriest.cools.guardianSpirit = Rotorbar.cooldown("Guardian Spirit")

        HolyPriest.cools.angelicFeather =  Rotorbar.cooldown("Angelic Feather");
        HolyPriest.cools.bodyAndMind =  Rotorbar.cooldown("Body And Mind");
        HolyPriest.cools.shiningForce =  Rotorbar.cooldown("Shining Force");
        HolyPriest.cools.symbolOfHope =  Rotorbar.cooldown("Symbol of Hope");
        HolyPriest.cools.divineStar =  Rotorbar.cooldown("Divine Star");
        HolyPriest.cools.halo =  Rotorbar.cooldown("Halo");
        HolyPriest.cools.circleOfHealing =  Rotorbar.cooldown("Circle of Healing");
        HolyPriest.cools.apotheosis =  Rotorbar.cooldown("Apotheosis");

        HolyPriest.loaded = true
    end

    return function()
        local showPos = 0
        local showIcons = {}

        local function showNext(icon)
            showIcons[showPos] = icon
            showPos = showPos + 1
        end

        showNext(HolyPriest.cools.prayerOfMending)
        showNext(HolyPriest.cools.lightOfTuure)
        if (HolyPriest.apotheosis) then
            showNext(HolyPriest.cools.apotheosis)
        end
        showNext(HolyPriest.cools.holyWordSerenity)
        showNext(HolyPriest.cools.holyWordSanctify)
        if (HolyPriest.halo) then
            showNext(HolyPriest.cools.halo)
        end
        if (HolyPriest.divineStar) then
            showNext(HolyPriest.cools.divineStar)
        end
        if (HolyPriest.circleOfHealing) then
            showNext(HolyPriest.cools.circleOfHealing)
        end
        showNext(HolyPriest.cools.divineHymn)
        showNext(HolyPriest.cools.guardianSpirit)
        if (HolyPriest.symbolOfHope) then
            showNext(HolyPriest.cools.symbolOfHope)
        end
        showNext(HolyPriest.cools.massDispel)
        showNext(HolyPriest.cools.purify)


        -- Trinket Ready Icons
        local t1useable, t1ready, t1icon = Rotorbar.equipmentIcon(13)
        local t2useable, t2ready, t2icon = Rotorbar.equipmentIcon(14)

        if (t1useable) then showNext(t1icon) end
        if (t2useable) then showNext(t2icon) end


        if (HolyPriest.bodyAndMind) then
            showNext(HolyPriest.cools.bodyAndMind)
        end
        if (HolyPriest.shiningForce) then
            showNext(HolyPriest.cools.shiningForce)
        end
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