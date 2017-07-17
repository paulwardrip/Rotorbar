
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

        if (Rotorbar.ready == true and (self.sinceLastUpdate >= 3 or (self.started and self.sinceLastUpdate >= .25))) then
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
            end
        end
    end

    function expireMobs()
        for k, v in pairs(Rotorbar._mobsInCombat) do
            if (GetTime() - Rotorbar._mobsInCombat[k].since > 5) then
                Rotorbar._mobsInCombat[k] = nil
            end
        end
    end

    function targetlog()
        if (combat and UnitName("target") ~= nil) then
            Rotorbar.target(UnitName("target"))
        end
    end

    function onCombatStart()
        Rotorbar.combatStart()
        targetlog()
    end

    function onCombatEnd()
        Rotorbar.combatEnd()
    end

    function initialize()
        Rotorbar.incomingIcon()

        CombatLogResetFilter()

        CombatLogAddFilter("SPELL_CAST_START,SPELL_CAST_SUCCESS", COMBATLOG_FILTER_EVERYTHING)
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
        expireDots()
        expireMobs()

        if (Rotorbar.currentSpec().cooldownsOnly) then
            Rotorbar.showCooldown(Rotorbar.gcd)
        else
            Rotorbar.showNext(Rotorbar.gcd)
        end

        Rotorbar.currentSpec().rotation()
        refreshCooldowns()
        if (RotorbarOptions.showUsables) then
            showEquipment()
        end

        Rotorbar.refresh()

    end

    function showEquipment()
        for k, v in pairs(Rotorbar.equipment) do
            if (RotorbarOptions.showGear[k]) then
                local usable, ready, icon, cool = v.show()
                if (usable and ready and (not Rotorbar.currentSpec().always)) then
                    Rotorbar.showNext(icon)
                elseif (usable and (not ready or Rotorbar.currentSpec().always)) then
                    Rotorbar.showCooldown(cool)
                end
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

    function events:PLAYER_TARGET_CHANGED()
        if (combat) then
            targetlog()
        end
    end

    function events:VARIABLES_LOADED()
        if (RotorbarOptions == nil) then
            RotorbarOptions = {}
        end

        if (RotorbarOptions.left == nil or RotorbarOptions.top == nil) then
            RotorbarOptions.left = 0
            RotorbarOptions.top = -20
        end

        if (RotorbarOptions.showGear == nil) then
            RotorbarOptions.showUsables = true
            RotorbarOptions.showGear = {}
            RotorbarOptions.showGear[2] = true
            RotorbarOptions.showGear[11] = true
            RotorbarOptions.showGear[12] = true
            RotorbarOptions.showGear[13] = true
            RotorbarOptions.showGear[14] = true
        end

        Rotorbar.ready = true
        Rotorbar.setPosition()
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

        function specialSpellHandler()
            -- Death and Decay Generates 3 different spell events, the first has a different ID than the others, this is used to isolate a single cast.
            if (spellName == "Death and Decay") then
                return spellId == 43265
            end

            return true
        end

        function findMob()
            local hostile = bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 or (isDummyGUID(destGUID))
            if (UnitAffectingCombat("player") or UnitAffectingCombat("pet") or (sourceGUID == pguid and hostile)) then
                if (not combat) then
                    combat = true
                    onCombatStart()
                end


                if (hostile) then
                    if (sourceGUID == pguid or Rotorbar._guidtounit[sourceGUID] ~= nil) then
                        if (Rotorbar._mobsInCombat[destGUID] == nil) then
                            Rotorbar._mobTargetNum = Rotorbar._mobTargetNum + 1
                            Rotorbar._mobsInCombat[destGUID] = { name = destName, debuff = {}, dots = {}, range = -1, since = GetTime(), index = Rotorbar._mobTargetNum }
                        end
                        return destGUID, 1, Rotorbar._mobsInCombat[destGUID].index
                    end
                else
                    hostile = bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 or (isDummyGUID(sourceGUID))

                    if (hostile) then
                        if (destGUID == pguid or Rotorbar._guidtounit[destGUID] ~= nil) then
                            if (Rotorbar._mobsInCombat[sourceGUID] == nil) then
                                Rotorbar._mobsInCombat[sourceGUID] = { name = sourceName, debuff = {}, dots = {}, range = -1, since = GetTime(), index = Rotorbar._mobTargetNum }
                            end
                        end
                        return sourceGUID, 0, Rotorbar._mobsInCombat[sourceGUID].index
                    end
                end
            else
                if (combat) then
                    mobsInCombat = {}
                    combat = false
                    onCombatEnd()
                end
            end
        end

        if (type == 'SPELL_AURA_APPLIED' or type == 'SPELL_AURA_REFRESH') then
            if (destGUID ~= pguid) then
                local mob = findMob()

                if (mob ~= nil) then
                    if (Rotorbar.currentSpec().aura ~= nil) then
                        Rotorbar.currentSpec().aura(destGUID, spellName, spellId, 1)
                    end

                    Rotorbar._mobsInCombat[mob].debuff[spellName] = true
                    Rotorbar._mobsInCombat[mob].since = GetTime()
                end
            end

        elseif (type == 'SPELL_PERIODIC_DAMAGE') then
            if (destGUID ~= pguid) then
                local mob, target, index = findMob()
                Rotorbar.dot(spellName, amount, destGUID, index)
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
                if (Rotorbar.currentSpec().aura ~= nil) then
                    Rotorbar.currentSpec().aura(destGUID, spellName, spellId, -1)
                end
                if (Rotorbar._mobsInCombat[mob] ~= nil and spellName ~= nil) then
                 Rotorbar._mobsInCombat[mob].debuff[spellName] = nil
                 Rotorbar._mobsInCombat[mob].since = GetTime()
                end
            end

        elseif (type == 'SPELL_DAMAGE') then
            if (sourceName ~= nil and UnitIsUnit(sourceName, "player")) then
                local mob, target, index = findMob()
                local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(spellName)

                if (target == 1 and sourceGUID == pguid) or (target == 0 and destGUID == pguid) then
                    if (mob ~= nil and maxRange ~= nil and (Rotorbar._mobsInCombat[mob].range > maxRange or Rotorbar._mobsInCombat[mob].range == -1)) then
                        Rotorbar._mobsInCombat[mob].range = maxRange
                        Rotorbar._mobsInCombat[mob].since = GetTime()
                    end
                    if (sourceGUID == pguid) then
                        if (dotsWithoutAuras[spellName] ~= nil) then
                            Rotorbar._mobsInCombat[mob].since = GetTime()
                            if (Rotorbar._mobsInCombat[mob].dots[spellName] ~= nil) then
                                Rotorbar._mobsInCombat[mob].dots[spellName] = GetTime() + dotsWithoutAuras[spellName].refresh
                            else
                                Rotorbar._mobsInCombat[mob].dots[spellName] = GetTime() + dotsWithoutAuras[spellName].time
                            end
                        end
                        Rotorbar.damage(spellName,amount,destGUID,index)
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
                Rotorbar.updateIncoming(incoming)
            end

        elseif (type == 'SPELL_CAST_START' or type == 'SPELL_CAST_SUCCESS') then
            if (sourceGUID == pguid) then
                local mob, target = findMob()
                Rotorbar.lastCast = spellName
                if (combat and specialSpellHandler()) then
                    Rotorbar.cast(spellName)
                end
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
            local mob, target, index = findMob()
            Rotorbar.updateIncoming()

            if (sourceGUID == pguid) then
                Rotorbar._mobsInCombat = {}
            elseif (mob ~= nil) then
                Rotorbar.kill(mob, index)
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