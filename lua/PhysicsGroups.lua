//=============================================================================
//
// RifleRange/PhysicsGroups.lua
// 
// Created by Max McGuire (max@unknownworlds.com)
// Copyright 2010, Unknown Worlds Entertainment
//
//=============================================================================

/**
 * Returns a bit mask with the specified groups filtered out.
 */
function CreateGroupsFilterMask(...)
  
    local mask = 0xFFFFFFFF
    local args = {...}
    
    for i,v in ipairs(args) do
        mask = bit.band( mask, bit.bnot(bit.lshift(1,v)) )
    end
  
    return mask
    
end

// Different groups that physics objects can be assigned to.
// Physics models and controllers can only be in ONE group (SetGroup()).
PhysicsGroup = enum
    { 
        'RagdollGroup',             // Ragdolls are in this group
        'PlayerControllersGroup',   // Bullets will not collide with this group.
        'PlayerGroup',              // Ignored for movement
        'ProjectileGroup',
        'CommanderPropsGroup',
        'CommanderUnitGroup',       // Macs, Drifters, doors, etc.
        'AttachClassGroup',         // Nozzles, tech points, etc.
        'CollisionGeometryGroup'    // Used so players walk smoothly gratings and skulks wall-run on railings, etc.
    }

// Pre-defined physics group masks.
PhysicsMask = enum
    {
        // Filters anything that should not be collided with for player movement.
        Movement = CreateGroupsFilterMask(PhysicsGroup.RagdollGroup, PhysicsGroup.PlayerGroup, PhysicsGroup.ProjectileGroup),
        
        // For Drifters, MACs
        AIMovement = CreateGroupsFilterMask(PhysicsGroup.RagdollGroup, PhysicsGroup.PlayerGroup, PhysicsGroup.AttachClassGroup),
        
        // Use these with trace functions to determine which entities we collide with. Use the filter to then
        // ignore specific entities. 
        AllButPCs = CreateGroupsFilterMask(PhysicsGroup.PlayerControllersGroup),

        // Used for all types of prediction
        AllButPCsAndRagdolls = CreateGroupsFilterMask(PhysicsGroup.PlayerControllersGroup, PhysicsGroup.RagdollGroup),
        
        // Shooting and hive sight
        Bullets = CreateGroupsFilterMask(PhysicsGroup.PlayerControllersGroup, PhysicsGroup.RagdollGroup, PhysicsGroup.CollisionGeometryGroup),

        // Allows us to mark props as non interfering for commander selection (culls out any props with commAlpha < 1)
        CommanderSelect = CreateGroupsFilterMask(PhysicsGroup.PlayerControllersGroup, PhysicsGroup.RagdollGroup, PhysicsGroup.CommanderPropsGroup),

        // The same as commander select mask, minus player entities and structures
        CommanderBuild = CreateGroupsFilterMask(PhysicsGroup.PlayerControllersGroup, PhysicsGroup.RagdollGroup, PhysicsGroup.CommanderPropsGroup, PhysicsGroup.CommanderUnitGroup),
        
        // When Onos charges, players don't stop our movement
        Charge = CreateGroupsFilterMask(PhysicsGroup.RagdollGroup, PhysicsGroup.PlayerGroup, PhysicsGroup.PlayerControllersGroup),
    }


