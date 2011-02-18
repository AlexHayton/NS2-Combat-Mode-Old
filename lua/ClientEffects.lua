// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommonEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Use this file to set up looping effects that are always playing on specific units in the game.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kClientEffectData = 
{
    on_init =
    {
        initEffects =
        {
            {looping_cinematic = "cinematics/alien/gorge/spit.cinematic", classname = "Spit", done = true},
            
            // Play spin for spinning infantry portal
            {looping_cinematic = "cinematics/marine/infantryportal/spin.cinematic", classname = "InfantryPortal", active = true, done = true},
            
            // Destroy it if not spinning
            {stop_cinematic = "cinematics/marine/infantryportal/spin.cinematic", classname = "InfantryPortal", active = false, done = true},
        },
    },  

    // Called on client only, whenever the "active" state of a structure is changed (currently only the IP)
    client_active_changed =
    {
        activeChanged =
        {
            // Play spin for spinning infantry portal
            {looping_cinematic = "cinematics/marine/infantryportal/spin.cinematic", classname = "InfantryPortal", active = true, done = true},
            
            // Destroy it if not spinning
            {stop_cinematic = "cinematics/marine/infantryportal/spin.cinematic", classname = "InfantryPortal", active = false, done = true},
        },
    },
}

GetEffectManager():AddEffectData("ClientEffectData", kClientEffectData)