
function registerEvents(events, frame)
    handlerLoaded = false
    initialized = false
    combat = false

    local dotsWithoutAuras = {
        ["Purge the Wicked"] = { time = 20, refresh = 25 }
    }

    local pguid = UnitGUID("player")

    function initialize()
        equipmentInit(2) -- Neck
        equipmentInit(11) -- Fingers
        equipmentInit(12)
        equipmentInit(13) -- Trinkets
        equipmentInit(14)

        CombatLogResetFilter()

        CombatLogAddFilter("SPELL_DAMAGE,SWING_DAMAGE", pguid, COMBATLOG_FILTER_EVERYTHING)
        CombatLogAddFilter("SPELL_DAMAGE,SWING_DAMAGE", COMBATLOG_FILTER_HOSTILE_UNITS, COMBATLOG_FILTER_FRIENDLY_UNITS)
        CombatLogAddFilter("SPELL_DAMAGE,SWING_DAMAGE", COMBATLOG_FILTER_FRIENDLY_UNITS, COMBATLOG_FILTER_HOSTILE_UNITS)
        CombatLogAddFilter("SPELL_AURA_APPLIED,SPELL_AURA_REFRESH,SPELL_AURA_REMOVED,SPELL_AURA_BROKEN,SPELL_PERIODIC_DAMAGE", pguid, COMBATLOG_FILTER_EVERYTHING)
        CombatLogAddFilter("UNIT_DIED", COMBATLOG_FILTER_HOSTILE_UNITS)

        initialized = true
    end

    function loadAll()
        getBindings()
        loadClassHandler()
        handlerLoaded = true
    end

    function runhandler()

        if (not handlerLoaded) then
            loadAll()
        end

        if (not initialized) then
            initialize()
        end

        Rotorbar.refreshStart()
        expireDots()

        if (Rotorbar.currentSpec().cooldownsOnly) then
            Rotorbar.showCooldown(Rotorbar.gcd)
        else
            Rotorbar.showNext(Rotorbar.gcd)
        end

        Rotorbar.currentSpec().rotation()
        refreshCooldowns()
        showEquipment()

        Rotorbar.refresh()

    end

    function showEquipment()
        for k, v in pairs(Rotorbar.equipment) do
            local usable, ready, icon, cool = v.show()
            if (usable and ready and (not Rotorbar.currentSpec().always)) then
                Rotorbar.showNext(icon)
            elseif (usable and (not ready or Rotorbar.currentSpec().always)) then
                Rotorbar.showCooldown(cool)
            end
        end
    end

    function refreshCooldowns()
        for k, v in pairs(Rotorbar.currentSpec().cooldowns) do
            if (v.type == "cooldown") then
                local show = v.showCool()
                if (show) then
                    Rotorbar.showCooldown(v)
                end
            end
        end
    end

    function expireDots()
        for k, v in pairs(Rotorbar._mobsInCombat) do
            for x, y in pairs(v.dots) do
                local left = y - GetTime()

                if (left <= 0) then
                    Rotorbar._mobsInCombat[k].debuff[x] = nil
                    Rotorbar._mobsInCombat[k].dots[x] = nil
                else
                    Rotorbar._mobsInCombat[k].debuff[x] = true
                end

                --print (k, y, left, Rotorbar._mobsInCombat[k].debuff[x])
            end
        end
    end

    function events:ACTIVE_TALENT_GROUP_CHANGED()
        handlerLoaded = false
    end

    function events:PLAYER_TALENT_UPDATE()
        handlerLoaded = false
    end

    function events:ACTIONBAR_SLOT_CHANGED()
        getBindings()
    end

    function events:PLAYER_LEAVE_COMBAT()
        combat = false
    end

    function events:PLAYER_ENTER_COMBAT()
        combat = true
    end

    function events:COMBAT_LOG_EVENT(timestamp, type, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
        destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, overkill, school,
        resisted, blocked, absorbed, critical, glancing, crushing)

        function findMob()
            if (combat) then
                local hostile = bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == 1 or (isDummyGUID(destGUID))
                if (hostile) then
                    if (Rotorbar._mobsInCombat[destGUID] == nil) then
                        Rotorbar._mobsInCombat[destGUID] = { name = destName, debuff = {}, dots = {}, range = -1 }
                    end
                    return destGUID
                else
                    hostile = bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == 1 or (isDummyGUID(sourceGUID))

                    if (hostile) then
                        if (Rotorbar._mobsInCombat[sourceGUID] == nil) then
                            Rotorbar._mobsInCombat[sourceGUID] = { name = sourceName, debuff = {}, dots = {}, range = -1 }
                        end

                        return sourceGUID
                    end
                end
            end
        end

        if (type == 'SPELL_AURA_APPLIED' or type == 'SPELL_AURA_REFRESH') then
            if (destGUID ~= pguid) then
                local mob = findMob()

                if (mob ~= nil) then
                    Rotorbar._mobsInCombat[mob].debuff[spellName] = true
                end
            end

        elseif (type == 'SPELL_PERIODIC_DAMAGE') then
            if (destGUID ~= pguid) then
                local mob = findMob()

                if (mob ~= nil) then
                    if (dotsWithoutAuras[spellName] ~= nil) then
                        if (Rotorbar._mobsInCombat[mob].dots[spellName] == nil) then
                            Rotorbar._mobsInCombat[mob].dots[spellName] = GetTime() + dotsWithoutAuras[spellName].time
                        end

                    end
                end
            end

        elseif (type == 'SPELL_AURA_REMOVED' or type == 'SPELL_AURA_BROKEN') then
            local mob = findMob()

            if (mob ~= nil) then
                Rotorbar._mobsInCombat[mob].debuff[spellName] = nil
            end

        elseif (type == 'SPELL_DAMAGE') then
            if (sourceName ~= nil and UnitIsUnit(sourceName, "player")) then
                local mob = findMob()
                local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(spellName)
                if (mob ~= nil and maxRange ~= nil and (Rotorbar._mobsInCombat[mob].range > maxRange or Rotorbar._mobsInCombat[mob].range == -1)) then
                    Rotorbar._mobsInCombat[mob].range = maxRange
                end
                if (sourceGUID == pguid and dotsWithoutAuras[spellName] ~= nil) then
                    if (Rotorbar._mobsInCombat[mob].dots[spellName] ~= nil) then
                        Rotorbar._mobsInCombat[mob].dots[spellName] = GetTime() + dotsWithoutAuras[spellName].refresh
                    else
                        Rotorbar._mobsInCombat[mob].dots[spellName] = GetTime() + dotsWithoutAuras[spellName].time
                    end
                end
            end

        elseif (type == 'SWING_DAMAGE') then
            if (sourceName ~= nil and UnitIsUnit(sourceName, "player")) then
                local mob = findMob()
                if (mob ~= nil) then
                    if (Rotorbar._mobsInCombat[mob].range > 5 or Rotorbar._mobsInCombat[mob].range == -1) then
                        Rotorbar._mobsInCombat[mob].range = 5
                    end
                end
            end

        elseif (type == 'UNIT_DIED') then
            local mob = findMob()
            if (mob ~= nil) then
                Rotorbar._mobsInCombat[mob] = nil
            end
        end
    end

    frame:SetScript("OnEvent", function(self, event, ...)
        events[event](self, ...); -- call one of the functions above
    end);

    for k, v in pairs(events) do
        frame:RegisterEvent(k); -- Register all events for which handlers have been defined
    end

    return runhandler
end