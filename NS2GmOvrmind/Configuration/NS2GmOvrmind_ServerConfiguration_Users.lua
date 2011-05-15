--[[ NS2-GmOvrmind(v10) Users (Server-)Configuration
 ---------------------------------------------------
 Author: player (playeru@live.com)
 Date: 16-4-2011
 Mod-version: v9
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: - Use at your own risk
		   - Feel free to copy this script for use in your own projects
		   - Please reference the Readme for further information regarding the configuration and usage of NS2-GmOvrmind
 ------------------------------------------- This file can be modified   ------------------------------------------]]--

--[[--
 Users
 -]]--

	--[[ Add a group of steam-users to the Overmind-system
	 Remarks: - The group-name should match that of the URL (http://steamcommunity.com/games/<group-name>)
			  - The SyncInterval indicates how often the Overmind-system should rescan the steam-group for changes
			  - The guest-priviliges are automatically added to these users (so no need to re-specify them here)
	 In: STRING GroupName
	 In: INTEGER SyncInterval (expressed in seconds)(Default: 3600 (every hour))
	 In: INTEGER Priviliges (Default: NS2GmOvrmind.Priviliges.ReservedSlot)
	 Out: Nill ]]--
	--NS2GmOvrmind.Users.AddSteamGroup("ns2",3600,NS2GmOvrmind.Priviliges.ReservedSlot); -- Work in progress, do not uncomment

	--[[ Adds a user to the Overmind-system
	 In: STRING UserName
	 In: STRING IP-Mask (Not implemented, use "")
	 In: STRING SteamID (Classic variant, use "STEAM_0:n:x")
	 In: STRING LoginName (If not used, use "")
	 In: STRING LoginPass (If not used, use "")
	 In: INTEGER Priviliges (Default: NS2GmOvrmind.Priviliges.All)
	 Out: Nill ]]--
	--NS2GmOvrmind.Users.Add("Average Joe","","STEAM_0:1:23456789","","",NS2GmOvrmind.Priviliges.All);

	--[[ Identical to the previous definition, except the SteamID-(3rd)parameter
	 In: INTEGER SteamID (New variant, use STEAM_0:x:n -> 2n+x) ]]--
	--NS2GmOvrmind.Users.Add("Average Joe","",46913579,"","",NS2GmOvrmind.Priviliges.All);
