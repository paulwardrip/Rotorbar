function isTargetDummy(target)
    if (target == nil) then target = "target" end

    local name = UnitName(target)
    local guid = UnitGUID(target)

    if (name ~= nil and string.match(name, "Dummy") == "Dummy") then
        return true
    elseif (guid ~= nil) then
        return isDummyGUID(guid)
    else
        return false
    end
end

function isDummyGUID(guid)
    local npc_id = npcId(guid)

    -- These training dummies have other names.
    return npc_id == '101956' -- Dreadscar Rift Rebellious Fel Lord
        or npc_id == '102045' -- Dreadscar Rift Rebellious Wrathguard
        or npc_id == '102048' -- Dreadscar Rift Rebellious Felguard
        or npc_id == '102052' -- Dreadscar Rift Rebellious Imp
        or npc_id == '103397' -- Hall of the Guardian Greater Bulwark Construct
        or npc_id == '103402' -- Hall of the Guardian Lesser Bulwark Construct
        or npc_id == '103404' -- Hall of the Guardian Bulwark Construct
        or npc_id == '107202' -- Ebon Hold Reanimated Monstrosity
        or npc_id == '107483' -- Skyhold Lesser Sparring Partner
        or npc_id == '107484' -- Skyhold Greater Sparring Partner
        or npc_id == '107555' -- Netherlight Temple Bound Void Wraith
        or npc_id == '107556' -- Netherlight Temple Bound Void Walker
        or npc_id == '113636' -- Mardum Imprisoned Forgefiend
        or npc_id == '113674' -- Mardum Imprisoned Centurion
        or npc_id == '113676' -- Mardum Imprisoned Weaver
        or npc_id == '113687' -- Mardum Imprisoned Imp
        or npc_id == '117631' -- Subjugated Felguard


        -- These all have Dummy in their names currently (the rest of the Legion and capital city ones)
        or npc_id == '31144'  -- Capital Cities
        or npc_id == '31145'  -- Capital Cities
        or npc_id == '31146'  -- Capital Cities
        or npc_id == '32666'  -- Capital Cities
        or npc_id == '79414'  -- Broken Shore
        or npc_id == '92164'  -- Training Dummy <Damage>
        or npc_id == '92165'  -- Dungeoneer's Training Dummy <Damage>
        or npc_id == '92165'  -- The Maelstrom
        or npc_id == '92166'  -- The Dreamgrove
        or npc_id == '92168'  -- Dungeoneer's Training Dummy <Tanking>
        or npc_id == '97668'  -- Highmountain
        or npc_id == '98581'  -- Highmountain
        or npc_id == '107557' -- Netherlight Temple
        or npc_id == '109096' -- Normal Tank Dummy
        or npc_id == '111824' -- Aszuna
        or npc_id == '113858' -- Trueshot Lodge
        or npc_id == '113859' -- Trueshot Lodge
        or npc_id == '113860' -- Trueshot Lodge
        or npc_id == '113862' -- Trueshot Lodge
        or npc_id == '113863' -- Trueshot Lodge
        or npc_id == '113864' -- Trueshot Lodge
        or npc_id == '113871' -- Trueshot Lodge
        or npc_id == '113964' -- The Dreamgrove
        or npc_id == '113966' -- The Dreamgrove
        or npc_id == '113967' -- The Dreamgrove
end