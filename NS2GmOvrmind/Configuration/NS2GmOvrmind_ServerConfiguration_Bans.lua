--[[ NS2-GmOvrmind(v10) Bans (Server-)Configuration
 --------------------------------------------------
 Author: player (playeru@live.com)
 Date: 16-4-2011
 Mod-version: v10
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: - Use at your own risk
		   - Feel free to copy this script for use in your own projects
		   - Please reference the Readme for further information regarding the configuration and usage of NS2-GmOvrmind
 ------------------------------------------- This file can be modified   ------------------------------------------]]--

--[[-
 Bans
 ]]--

	--[[ Add a SQL-database of users to the Overmind-system
	 Remark: WriteAccess indicates whether modifications (new users \ changed users) will be written into the table.
	 In: STRING Hostname
	 In: INTEGER Port
	 In: STRING Username
	 In: STRING Password
	 In: STRING Database
	 In: STRING Table
	 In: INTEGER SyncInterval (Default: 60)
	 Out: Nill ]]--
	--NS2GmOvrmind.Bans.AddPassiveSQL("omitted",omitted,"omitted","omitted","omitted","Bans",60); -- Work in progress, do not uncomment

	--[[ Adds a passive-banfile to the Overmind-system
	 Remarks: - The SyncInterval indicates how often the Overmind-system should rescan the file for changes.
			  - Passive-banfiles are treated as read-only and aren't updated with newly added bans.
	 In: STRING FilePath
	 In: INTEGER SyncInterval (expressed in seconds)(Default: 60)
	 Out: Nill ]]--
	--NS2GmOvrmind.Bans.AddPassiveFile(string.format("%s\\Configuration\\Bans.xml",NS2GmOvrmind.Name.Internal),60); -- Work in progress, do not uncomment

	--[[ Adds an active-banfile to the Overmind-system
	 Remarks: - The SyncInterval indicates how often the Overmind-system should rescan the file for changes and immediately update it, and is expressed in seconds.
			  - Active-banfiles are treated as read\write and are scanned and updated at the same time.
	 In: STRING FilePath
	 In: INTEGER SyncInterval (expressed in seconds)(Default: 60)
	 Out: Nill ]]--
	--NS2GmOvrmind.Bans.SetActiveFile(string.format("%s\\Configuration\\ActiveBans.xml",NS2GmOvrmind.Name.Internal),60); -- Work in progress, do not uncomment

	--[[ Adds a ban to the Overmind-system
	 In: STRING UserName
	 In: STRING IP-Mask (Not implemented, use "")
	 In: STRING SteamID (Classic variant, use "STEAM_0:n:x")
	 In: STRING Reason
	 Out: Nill ]]--
	--NS2GmOvrmind.Bans.Add("Average Bob","","STEAM_0:0:12345678","Griefing");

	--[[ Identical to the previous definition, except the SteamID-(2nd)parameter
	 In: INTEGER SteamID (New variant, use STEAM_0:x:n -> 2n+x) ]]--
	--NS2GmOvrmind.Bans.Add("Average Bob","",24691356,"Griefing");
