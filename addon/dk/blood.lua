Blood = {
    class = function()
        Rotorbar.classIcon(1, 0, 0, 1)
    end,

    icons = function()
        Blood.deathAndDecayCrimson = Rotorbar.flash("Death and Decay", 1, .25, .25, 1)
        Blood.deathStrikeHeals = Rotorbar.flash("Death Strike", 1, 0.5, 0.5, 1)
        Blood.deathStrikeIce = Rotorbar.flash("Death Strike", .75, 0, 1, 1)
        Blood.blooddrinkerHeals =  Rotorbar.flash("Blooddrinker")
        Blood.consumptionHeals = Rotorbar.flash("Consumption")
        Blood.iceboundFortitude = Rotorbar.flash("Icebound Fortitude")
        Blood.vampiricBlood = Rotorbar.flash("Vampiric Blood")
        Blood.dancingRuneWeapon = Rotorbar.flash("Dancing Rune Weapon")

        Blood.deathAndDecay = Rotorbar.buttonTime("Death and Decay")
        Blood.deathStrike = Rotorbar.buttonTime("Death Strike")
        Blood.heartStrike = Rotorbar.buttonTime("Heart Strike")
        Blood.marrowrend = Rotorbar.buttonTime("Marrowrend")
        Blood.consumption = Rotorbar.buttonTime("Consumption")
        Blood.bloodBoil = Rotorbar.buttonTime("Blood Boil")

        Blood.blooddrinker =  Rotorbar.buttonTime("Blooddrinker")
        Blood.bloodTap =  Rotorbar.buttonTime("Blood Tap")
        Blood.bloodMirror =  Rotorbar.buttonTime("Blood Mirror")
        Blood.markOfBlood =  Rotorbar.buttonTime("Mark of Blood")
        Blood.tombstone =  Rotorbar.buttonTime("Tombstone")
        Blood.runeTap =  Rotorbar.buttonTime("Rune Tap")
        Blood.bonestorm =  Rotorbar.buttonTime("Bonestorm")

        Blood.bloodPlague = Rotorbar.debuffIcon("Blood Plague", "55078")

        Rotorbar.cooldown("Death Grip")
        Rotorbar.cooldown("Gorefiend's Grasp")
        Rotorbar.cooldown("Wraith Walk")
        Rotorbar.cooldown("Icebound Fortitude")
        Rotorbar.cooldown("Vampiric Blood")
        Rotorbar.cooldown("Dancing Rune Weapon")
        Rotorbar.cooldown("Tombstone")
        Rotorbar.cooldown("Blood Mirror")
        Rotorbar.cooldown("Bonestorm")
        Rotorbar.cooldown("Raise Ally")

    end,

    rotation = function()
        Rotorbar.showDebuff(Blood.bloodPlague)

        local showedDS = false
        local showedBD = false
        local showedCN = false
        local boneShield, boneLeft = Rotorbar.buffed("Bone Shield")
        local bloodPlague, bloodLeft = Rotorbar.debuffed("Blood Plague")
        local crimson = Rotorbar.buffed("Crimson Scourge")

        local healthpercent = UnitHealth("player") / UnitHealthMax("player")
        local runicPercent = UnitPower("player", 6) / UnitPowerMax("player", 6)
        local runes = Rotorbar.runes()

        local iceboundActive = Rotorbar.buffed("Icebound Fortitude")

        if (iceboundActive and Rotorbar.isTalent("Heart of Ice")) then

            -- Death Strike Extends
            if (Rotorbar.isUsableCooldown("Death Strike")) then
                Rotorbar.showNext (Blood.deathStrikeIce)
            end

            -- Marrowrend if Bone Shield is Needed
            if (Rotorbar.isUsableCooldown("Marrowrend") and (boneShield < 9 or boneLeft < 5)) then
                Rotorbar.showNext (Blood.marrowrend)
            end

            -- Heart Strike
            if (Rotorbar.isUsableCooldown("Heart Strike")) then
                Rotorbar.showNext (Blood.heartStrike)
            end

        else
            -- Criticals
            local icebound = Rotorbar.isUsableCooldown("Icebound Fortitude")
            local vampire = Rotorbar.isUsableCooldown("Vampiric Blood")
            if (healthpercent < .5) then
                if (vampire and icebound) then
                    Rotorbar.RshowNext (Blood.vampiricBlood)
                elseif (icebound) then
                    Rotorbar.showNext (Blood.iceboundFortitude)
                elseif (vampire) then
                    Rotorbar.showNext (Blood.vampiricBlood)
                end
            end

            -- Dancing Rune Weapon
            local runeWeaponGo = Rotorbar.isUsableCooldown("Dancing Rune Weapon")
            if (healthpercent < .5 and runeWeaponGo) then
                Rotorbar.showNext(Blood.dancingRuneWeapon)
            end

            -- Blooddrinker Heals
            if (Rotorbar.isUsableCooldown("Blooddrinker") and healthpercent < .75) then
                Rotorbar.showNext (Blood.blooddrinkerHeals)
                showedBD = true
            end

            -- Consumption Heals
            if (Rotorbar.isUsableCooldown("Consumption") and healthpercent < .75) then
                Rotorbar.showNext (Blood.consumptionHeals)
            end

            -- Death Strike Emergency
            if (Rotorbar.isUsableCooldown("Death Strike") and healthpercent < .50) then
                Rotorbar.showNext (Blood.deathStrikeHeals)
                showedDS = true
            end

            -- Crimson Scourge Proc
            if (crimson > 0) then
                Rotorbar.showNext (Blood.deathAndDecayCrimson)
            end

            -- Blood Tap
            if (Rotorbar.isUsableCooldown("Blood Tap") and runes < 2 and boneShield > 1) then
                Rotorbar.showNext (Blood.bloodTap)
            end

            -- Death Strike if it will heals 25% or more.
            if (not showedDS and Rotorbar.isUsableCooldown("Death Strike") and healthpercent < .75 and runicPercent > .22) then
                Rotorbar.showNext (Blood.deathStrike)
                showedDS = true
            end

            -- Bonestorm
            local bonestormGo, bonestormLeft = Rotorbar.isUsableCooldown("Bonestorm")
            if (bonestormGo and runicPercent == 1) then
                Rotorbar.showNext (Blood.bonestorm)
            end

            -- Blood Mirror
            local mirrorGo, mirrorLeft = Rotorbar.isUsableCooldown("Blood Mirror")
            if (mirrorGo and Rotorbar.isBoss()) then
                Rotorbar.showNext (Blood.bloodMirror)
            end

            -- Mark of Blood
            if (Rotorbar.isUsableCooldown("Mark of Blood") and Rotorbar.isBoss()) then
                local stacks, left = Rotorbar.debuffed("Mark of Blood")
                if (stacks == 0 or left < 2) then
                    Rotorbar.showNext (Blood.markOfBlood)
                end
            end

            -- Blood Boil
            if (Rotorbar.isUsableCooldown("Blood Boil") and (bloodPlague == 0 or bloodLeft < 3)) then
                Rotorbar.showNext (Blood.bloodBoil)
            end

            -- Death and Decay
            if (crimson == 0 and Rotorbar.isUsableCooldown("Death and Decay")) then
                Rotorbar.showNext (Blood.deathAndDecay)
            end

            -- Marrowrend if Bone Shield is Needed
            if (Rotorbar.isUsableCooldown("Marrowrend") and (boneShield < 9 or boneLeft < 5)) then
                Rotorbar.showNext (Blood.marrowrend)
            end

            -- Blooddrinker
            if (not showedBD and Rotorbar.isUsableCooldown("Blooddrinker")) then
                Rotorbar.showNext (Blood.blooddrinker)
            end

            -- Consumption
            if (not showedCN and Rotorbar.isUsableCooldown("Consumption")) then
                Rotorbar.showNext (Blood.consumption)
            end

            -- Heart Strike
            if (Rotorbar.isUsableCooldown("Heart Strike")) then
                Rotorbar.showNext (Blood.heartStrike)
            end

            -- Death Strike if heals 10% or if completely runic capped.
            if (not showedDS and Rotorbar.isUsableCooldown("Death Strike") and (healthpercent < .9 or runicPercent == 1)) then
                Rotorbar.showNext (Blood.deathStrike)
            end

            -- Tombstone
            local tombstoneGo, tombstoneLeft = Rotorbar.isUsableCooldown("Tombstone")
            if (tombstoneGo and boneShield > 4) then
                Rotorbar.showNext (Blood.tombstone)
            end

            -- Rune Tap
            if (Rotorbar.isUsableCooldown("Rune Tap")) then
                Rotorbar.showNext (Blood.runeTap)
            end
        end
    end
}