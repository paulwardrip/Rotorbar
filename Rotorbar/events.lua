
function registerEvents(events, frame)
    handlerLoaded = false
    initialized = false
    combat = false
    equipped = false

    registerOnUpdate(function (self, inc)
        self.sinceLastUpdate = (self.sinceLastUpdate or 0) + inc;
        self.equipmentInit = (self.equipmentInit or 0) + inc;

        if (self.equipmentInit >= 10 and not equipped) then
            equipmentInit(2) -- Neck
            equipmentInit(11) -- Fingers
            equipmentInit(12)
            equipmentInit(13) -- Trinkets
            equipmentInit(14)
            equipped = true
        end

        if (self.sinceLastUpdate >= 3 or (self.started and self.sinceLastUpdate >= .25)) then
            runhandler()
            self.started = true
            self.sinceLastUpdate = 0;
        end
    end)

    local dotsWithoutAuras = {
        ["Purge the Wicked"] = { time = 20, refresh = 25 }
    }

    local pguid = UnitGUID("player")

    local maxHealth = UnitHealthMax("player")

    function initialize()
        Rotorbar.incomingIcon()

        CombatLogResetFilter()

        CombatLogAddFilter("SPELL_CAST_START", COMBATLOG_FILTER_EVERYTHING)
        CombatLogAddFilter("SPELL_DAMAGE,SWING_DAMAGE", COMBATLOG_FILTER_EVERYTHING)
        CombatLogAddFilter("SPELL_AURA_APPLIED,SPELL_AURA_REFRESH,SPELL_AURA_REMOVED,SPELL_AURA_BROKEN,SPELL_PERIODIC_DAMAGE", pguid, COMBATLOG_FILTER_EVERYTHING)
        CombatLogAddFilter("UNIT_DIED", COMBATLOG_FILTER_EVERYTHING)

        initialized = true
    end

    function loadAll()
        getBindings()
        loadClassHandler()
        handlerLoaded = true
        Rotorbar.updateDebuffIcons()
        maxHealth = UnitHealthMax("player")
    end

    function runhandler()

        if (not handlerLoaded) then
            loadAll()
        end

        if (not initialized) then
            initialize()
        end

        Rotorbar.refreshStart()
        Rotorbar.expireDots()
        Rotorbar.expireMobs()

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

    function events:ACTIVE_TALENT_GROUP_CHANGED()
        handlerLoaded = false
    end

    function events:PLAYER_TALENT_UPDATE()
        handlerLoaded = false
    end

    function events:ACTIONBAR_SLOT_CHANGED()
        getBindings()
    end

    function gearChange()
        if (equipped) then
        Rotorbar.equipment[2].load()
        Rotorbar.equipment[11].load()
        Rotorbar.equipment[12].load()
        Rotorbar.equipment[13].load()
        Rotorbar.equipment[14].load()
        end
    end

    function events:EQUIPMENT_SWAP_FINISHED()
        gearChange()
    end

    function events:PLAYER_EQUIPMENT_CHANGED()
        gearChange()
    end

    function events:PARTY_MEMBERS_CHANGED()
        Rotorbar._guidtounit = {};
        Rotorbar._guidtounit[UnitGUID('player')] = 'player';
        if UnitExists('pet') then
            Rotorbar._guidtounit[UnitGUID('pet')] = 'pet';
        end;
        for i= 1, GetNumPartyMembers() do
            Rotorbar._guidtounit[UnitGUID('party'..i)] = 'party'..i;
            if UnitExists('party'..i..'pet') then
                Rotorbar._guidtounit[UnitGUID('party'..i..'pet')] = 'party'..i..'pet';
            end;
        end;
    end;

    function events:COMBAT_LOG_EVENT(timestamp, type, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
        destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, overkill, school,
        resisted, blocked, absorbed, critical, glancing, crushing)

        function findMob()
            if (UnitAffectingCombat("player")) then
                Rotorbar.combat = true
                local hostile = bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 or (isDummyGUID(destGUID))
                if (hostile) then
                    if (sourceGUID == pguid or Rotorbar._guidtounit[sourceGUID] ~= nil) then
                        if (Rotorbar._mobsInCombat[destGUID] == nil) then
                            Rotorbar._mobsInCombat[destGUID] = { name = destName, debuff = {}, dots = {}, range = -1, since = GetTime() }
                        end
                        return destGUID, 1
                    end
                else
                    hostile = bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 or (isDummyGUID(sourceGUID))

                    if (hostile) then
                        if (destGUID == pguid or Rotorbar._guidtounit[destGUID] ~= nil) then
                            if (Rotorbar._mobsInCombat[sourceGUID] == nil) then
                                Rotorbar._mobsInCombat[sourceGUID] = { name = sourceName, debuff = {}, dots = {}, range = -1, since = GetTime() }
                            end
                        end
                        return sourceGUID, 0
                    end
                end
            else
                if (Rotorbar.combat == true) then
                    mobsInCombat = {}
                end
                Rotorbar.combat = false
            end
        end

        if (type == 'SPELL_AURA_APPLIED' or type == 'SPELL_AURA_REFRESH') then
            if (destGUID ~= pguid) then
                local mob = findMob()

                if (mob ~= nil) then
                    Rotorbar._mobsInCombat[mob].debuff[spellName] = true
                    Rotorbar._mobsInCombat[mob].since = GetTime()
                end
            end

        elseif (type == 'SPELL_PERIODIC_DAMAGE') then
            if (destGUID ~= pguid) then
                local mob = findMob()

                if (mob ~= nil) then
                    if (dotsWithoutAuras[spellName] ~= nil) then
                        if (Rotorbar._mobsInCombat[mob].dots[spellName] == nil) then
                            Rotorbar._mobsInCombat[mob].dots[spellName] = GetTime() + dotsWithoutAuras[spellName].time
                            Rotorbar._mobsInCombat[mob].since = GetTime()
                        end
                    end
                end
            end

        elseif (type == 'SPELL_AURA_REMOVED' or type == 'SPELL_AURA_BROKEN') then
            local mob = findMob()

            if (mob ~= nil) then
                Rotorbar._mobsInCombat[mob].debuff[spellName] = nil
                Rotorbar._mobsInCombat[mob].since = GetTime()
            end

        elseif (type == 'SPELL_DAMAGE') then
            if (sourceName ~= nil and UnitIsUnit(sourceName, "player")) then
                local mob, target = findMob()
                local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(spellName)

                if (target == 1 and sourceGUID == pguid) or (target == 0 and destGUID == pguid) then
                    if (mob ~= nil and maxRange ~= nil and (Rotorbar._mobsInCombat[mob].range > maxRange or Rotorbar._mobsInCombat[mob].range == -1)) then
                        Rotorbar._mobsInCombat[mob].range = maxRange
                        Rotorbar._mobsInCombat[mob].since = GetTime()
                    end
                    if (sourceGUID == pguid and dotsWithoutAuras[spellName] ~= nil) then
                        Rotorbar._mobsInCombat[mob].since = GetTime()
                        if (Rotorbar._mobsInCombat[mob].dots[spellName] ~= nil) then
                            Rotorbar._mobsInCombat[mob].dots[spellName] = GetTime() + dotsWithoutAuras[spellName].refresh
                        else
                            Rotorbar._mobsInCombat[mob].dots[spellName] = GetTime() + dotsWithoutAuras[spellName].time
                        end
                    end
                end

            elseif (Rotorbar.currentSpec().tank == true and destName ~= nil and UnitIsUnit(destName, "player")) then
                Rotorbar.updateIncoming({
                    mame = spellName,
                    school = spellSchool,
                    id = spellId,
                    cast = false,
                    target = sourceGUID == UnitGUID("target")
                })

                local hitFor = amount/maxHealth
                if (Rotorbar.isBoss() and hitFor > .25) then
                    if (RotorbarBossAbilities[sourceGUID] == nil) then
                        RotorbarBossAbilities[sourceGUID] = { spell={} }

                        if (RotorbarBossAbilities[sourceGUID].spell[spellId] == nil) then
                            RotorbarBossAbilities[sourceGUID].spell[spellId] = {
                                name = spellName,
                                school = school,
                                percent = hitFor
                            }
                        end
                    elseif (RotorbarBossAbilities[sourceGUID].spell[spellId].hitFor < hitFor) then
                        RotorbarBossAbilities[sourceGUID].spell[spellId].hitFor = hitFor
                    end
                end
            end

        elseif (type == 'SPELL_CAST_START' and Rotorbar.currentSpec().tank == true) then
            if (destGUID == pguid or sourceGUID == UnitGUID("target")) then
                local incoming = {
                    mame = spellName,
                    school = spellSchool,
                    id = spellId,
                    cast = true,
                    target = sourceGUID == UnitGUID("target")
                }
                if (Rotorbar.isBoss() and RotorbarBossAbilities[sourceGUID] ~= nil and RotorbarBossAbilities[sourceGUID].spell[spellId] ~= nil) then
                    incoming.maxdamage = RotorbarBossAbilities[sourceGUID].spell[spellId].hitFor
                end
                Rotorbar.updateIncoming(incoming)
            end

        elseif (type == 'SWING_DAMAGE') then
            local mob, target = findMob()
            if (destGUID == pguid) then
                Rotorbar.updateIncoming({
                    school = 1,
                    cast = false,
                    target = sourceGUID == UnitGUID("target")
                })
            end

            if (mob ~= nil) then
                if (target == 1 and sourceGUID == pguid) or (target == 0 and destGUID == pguid) then
                    if (Rotorbar._mobsInCombat[mob].range > 5 or Rotorbar._mobsInCombat[mob].range == -1) then
                        Rotorbar._mobsInCombat[mob].range = 5
                        Rotorbar._mobsInCombat[mob].since = GetTime()
                    end
                end
            end

        elseif (type == 'UNIT_DIED') then
            local mob = findMob()
            Rotorbar.updateIncoming()

            if (sourceGUID == pguid) then
                Rotorbar._mobsInCombat = {}
            elseif (mob ~= nil) then
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

end