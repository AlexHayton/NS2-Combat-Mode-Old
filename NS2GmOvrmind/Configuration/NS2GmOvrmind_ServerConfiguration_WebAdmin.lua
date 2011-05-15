--[[ NS2-GmOvrmind(v10) Web-administration (Server-)Configuration
 ----------------------------------------------------------------
 Author: player (playeru@live.com)
 Date: 16-4-2011
 Mod-version: v9
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: - Use at your own risk
		   - Feel free to copy this script for use in your own projects
		   - Please reference the Readme for further information regarding the configuration and usage of NS2-GmOvrmind
 ------------------------------------------- This file can be modified   ------------------------------------------]]--

--[[------------------------
 Web-administration settings
 -----------------------]]--

	--[[ Override NS2's default admin-webpage with NS2-GmOvrmind's built-in version
	 In: BOOLEAN Enabled (Default: true)
	 Out: Nill ]]--
	NS2GmOvrmind.WebAdmin.SetEnabled(true);

	--[[ The amount of console-messages that will be cached and displayed
	 In: INTEGER Depth (Default: 15)
	 Out: Nill ]]--
	NS2GmOvrmind.WebAdmin.SetConsoleHistoryDepth(15);
