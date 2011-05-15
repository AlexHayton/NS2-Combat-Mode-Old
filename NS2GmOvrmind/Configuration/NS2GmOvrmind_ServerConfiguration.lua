--[[ NS2-GmOvrmind(v10) Top-level (Server-)Configuration
 -------------------------------------------------------
 Author: player (playeru@live.com)
 Date: 16-4-2011
 Mod-version: v10
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: - Use at your own risk
		   - Feel free to copy this script for use in your own projects
		   - Please reference the Readme for further information regarding the configuration and usage of NS2-GmOvrmind
 ------------------------------------------ This file can be modified   -------------------------------------------]]--
Script.Load("..\\NS2GmOvrmind\\Lua\\NS2GmOvrmind.lua"); -- NS2-GmOvrmind prerequisites
NS2GmOvrmind.ServerConfigs={ -- Config-categories
	"WebAdmin" -- Web-administration
	,"Server" -- Server-information
	,"ServerQuery" -- Server query-responder
	,"RCon" -- RCon-administration
	,"WebStats" -- Web-statistics
	,"Ingame" -- Ingame-administration
	,"Users" -- Ovrmind-users
	,"Bans" -- Ovrmind-bans
	,"Log" -- Logging
	,"Gameplay" -- Gameplay-alterations
	,"IRC" -- IRC-relay\administration
	,"TeamSpeak"}; -- TeamSpeak-server

--[[ Add a server-configuration to the overmind-system
 Remark: - This will add a new table in the toplevel table (NS2GmOvrmind), accessible via the ServerName-string passed here.
		 - For general settings that have to be applicable to all servers, simply use just the toplevel table (NS2GmOvrmind)
 In: STRING ServerName
 Out: Nil ]]--
	--NS2GmOvrmind.AddServer("My NS2-Server","My1","ns2_rockdown"); -- Work in progress, do not uncomment
	--NS2GmOvrmind.AddServer("My second NS2-Server","My2","ns2_tram"); -- Work in progress, do not uncomment
	--NS2GmOvrmind.AddServer("My third NS2-Server","My3","ns2_junction"); -- Work in progress, do not uncomment

for ConfigIndx,Config in ipairs(NS2GmOvrmind.ServerConfigs)do -- Cycle through the config-categories
	Script.Load(string.format("..\\%s\\Configuration\\%s_ServerConfiguration_%s.lua",NS2GmOvrmind.Name.Internal,NS2GmOvrmind.Name.Internal,Config));end; -- Load the config-category