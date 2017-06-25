

function registerEvents(frame)
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    frame:RegisterEvent("PLAYER_TALENT_UPDATE")
    frame:RegisterEvent("PLAYER_ENTER_COMBAT")
    frame:RegisterEvent("PLAYER_LEAVE_COMBAT")
    frame:RegisterEvent("PLAYER_STARTED_MOVING")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    frame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    frame:RegisterEvent("UNIT_AURA")
    frame:RegisterEvent("UNIT_POWER")
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

    frame:SetScript("OnEvent", function(self, event, arg1, ...)
        if (event == "PLAYER_ENTERING_WORLD") then
            equipmentInit(13)
            equipmentInit(14)

            getBindings()
            loadClassHandler()

        elseif (event == "ACTIVE_TALENT_GROUP_CHANGED") then
            getBindings()
            loadClassHandler()

        elseif (event == "PLAYER_TALENT_UPDATE") then
            getBindings()
            loadClassHandler()

        elseif (event == "ACTIONBAR_SLOT_CHANGED") then
            getBindings()

        elseif (event == "COMBAT_LOG_EVENT_UNFILTERED") then
            local type, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,
            spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = select(1,...)

            function findMob()
                local hostile = bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == 1 or (isDummyGUID(destGUID))

                if (hostile) then
                    if (mobsInCombat[destGUID] == nil) then
                        mobsInCombat[destGUID] = { name = destName, debuff = {}, range = -1 }
                    end
                    return destGUID
                else
                    hostile = bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == 1 or (isDummyGUID(sourceGUID))

                    if (hostile) then
                        if (mobsInCombat[sourceGUID] == nil) then
                            mobsInCombat[sourceGUID] = { name = sourceName, debuff = {}, range = -1 }
                        end

                        return sourceGUID
                    end
                end
            end

            if (type == 'SPELL_AURA_REFRESH') then
                local mob = findMob()
                if (mob ~= nil) then
                    mobsInCombat[mob].debuff[spellName] = true
                end

            elseif (type == 'SPELL_AURA_REMOVED' or type == 'SPELL_AURA_BROKEN') then
                local mob = findMob()
                if (mob ~= nil) then
                    mobsInCombat[mob].debuff[spellName] = nil
                end

            elseif (type == 'SPELL_DAMAGE') then
                if (sourceName ~= nil and UnitIsUnit(sourceName, "player")) then
                    local mob = findMob()
                    local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(spellName)
                    if (maxRange ~= nil and (mobsInCombat[mob].range > maxRange or mobsInCombat[mob].range == -1)) then
                        mobsInCombat[mob].range = maxRange
                    end
                end

            elseif (type == 'SPELL_DAMAGE' or type == 'SWING_DAMAGE') then
                if (sourceName ~= nil and UnitIsUnit(sourceName, "player")) then
                    local mob = findMob()
                    if (mobsInCombat[mob].range > 5 or mobsInCombat[mob].range == -1) then
                        mobsInCombat[mob].range = 5
                    end
                end

            elseif (type == 'UNIT_DIED') then
                local mob = findMob()
                if (mob ~= nil) then
                    mobsInCombat[mob] = nil
                end
            end

        elseif (event == "PLAYER_LEAVE_COMBAT") then
            mobsInCombat = {}

        else
            if (handler ~= nil) then
                handler()
                showGCD()
            end
        end
    end)
end