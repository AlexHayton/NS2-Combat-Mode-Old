--[[ NS2-GmOvrmind(v10) Ingame (Server-)Configuration
 ----------------------------------------------------
 Author: player (playeru@live.com)
 Date: 16-4-2011
 Mod-version: v10
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: - Use at your own risk
		   - Feel free to copy this script for use in your own projects
		   - Please reference the Readme for further information regarding the configuration and usage of NS2-GmOvrmind
 ------------------------------------------- This file can be modified   ------------------------------------------]]--

--[[------------
 Ingame-settings
 -----------]]--

	--[[ The priviliges non-loggedin players will have
	 Remark: The ConsoleCommand_PING-privilige is hardcoded for now, to allow people to find out if the server is (technically) vanilla or not
	 In: INTEGER Priviliges (Default: NS2GmOvrmind.Priviliges.None +
									NS2GmOvrmind.Priviliges.ConsoleCommand_LOGIN +
									NS2GmOvrmind.Priviliges.ConsoleCommand_HELP +
									NS2GmOvrmind.Priviliges.ConsoleCommand_MODINFO +
									NS2GmOvrmind.Priviliges.ConsoleCommand_SERVERINFO +
									NS2GmOvrmind.Priviliges.ConsoleCommand_PING)
	 Out: Nill ]]--
	NS2GmOvrmind.Ingame.SetGuestPriviliges(NS2GmOvrmind.Priviliges.None +
									NS2GmOvrmind.Priviliges.ConsoleCommand_LOGIN +
									NS2GmOvrmind.Priviliges.ConsoleCommand_HELP +
									NS2GmOvrmind.Priviliges.ConsoleCommand_MODINFO +
									NS2GmOvrmind.Priviliges.ConsoleCommand_SERVERINFO +
									NS2GmOvrmind.Priviliges.ConsoleCommand_PING);

	--[[ The minimum amount of time (in seconds) between commands, before the anti-flooding system will kick in
	 In: INTEGER FloodInterval (Default: 3)
	 Out: Nill ]]--
	NS2GmOvrmind.Ingame.SetAntiCommandFloodInterval(3);
