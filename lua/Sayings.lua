// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Sayings.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Sayings menus and sounds.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

marineRequestSayingsText = {"1. Acknowledged", "2. Need medpack", "3. Need ammo", "4. Need orders"}
marineRequestSayingsSounds = {"sound/ns2.fev/marine/voiceovers/ack", "sound/ns2.fev/marine/voiceovers/medpack", "sound/ns2.fev/marine/voiceovers/ammo", "sound/ns2.fev/marine/voiceovers/need_orders" }
marineRequestActions = {kTechId.MarineAlertAcknowledge, kTechId.MarineAlertNeedMedpack, kTechId.MarineAlertNeedAmmo, kTechId.MarineAlertNeedOrder}

marineGroupSayingsText  = {"1. Follow me", "2. Let's move", "3. Covering you", "4. Hostiles", "5. Taunt"}
marineGroupSayingsSounds = {"sound/ns2.fev/marine/voiceovers/follow_me", "sound/ns2.fev/marine/voiceovers/lets_move", "sound/ns2.fev/marine/voiceovers/covering", "sound/ns2.fev/marine/voiceovers/hostiles", "sound/ns2.fev/marine/voiceovers/taunt"}
marineGroupRequestActions = {kTechId.None, kTechId.None, kTechId.None, kTechId.MarineAlertHostiles, kTechId.None}

alienGroupSayingsText  = {"1. Need healing", "2. Follow me", "3. Chuckle"}
alienGroupSayingsSounds = {"sound/ns2.fev/alien/voiceovers/need_healing", "sound/ns2.fev/alien/voiceovers/follow_me", "sound/ns2.fev/alien/voiceovers/chuckle"}
alienRequestActions = {kTechId.AlienAlertNeedHealing, kTechId.None, kTechId.None}

// Precache all sayings
function precacheSayingsTable(sayings)
    for index, saying in ipairs(sayings) do
        Shared.PrecacheSound(saying)
    end
end

precacheSayingsTable(marineRequestSayingsSounds)
precacheSayingsTable(marineGroupSayingsSounds)
precacheSayingsTable(alienGroupSayingsSounds)