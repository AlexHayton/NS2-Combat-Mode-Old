--[[ NS2-GmOvrmind(v5) (Server-)Configuration
 --------------------------------------------
 Author: player (playeru@live.com)
 Date: 3-3-2011
 Mod-version: v5
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: - Use at your own risk and feel free to copy this script for use in your own projects
		   - Please reference the Readme for further information regarding the configuration of NS2-GmOvrmind
 --------------------------------------------------------------------------------------------------------]]--
Script.Load("..\\NS2GmOvrmind\\Lua\\NS2GmOvrmind.lua"); -- NS2-GmOvrmind prerequisites

--[[--------------------------
 Natural Selection 2 setttings
 -------------------------]]--

	--[[ Indicate the build of NS2 this server runs
	 Remark: This is used by the server-query responder to display the build that is running, and ideally should be updated each new build
	 In: INTEGER Build (Default: (166)
	 Out: Nill ]]--
	NS2GmOvrmind.NS2.SetBuild(166);


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


--[[------------
 Server-settings
 -----------]]--

	--[[ The server-name
	 In: STRING ServerName (Default: "My NS2-server")
	 Out: Nill ]]--
	NS2GmOvrmind.Server.SetName("My NS2-server");

	--[[ The server's external IP (the IP players should connect to)
	 In: STRING ServerName (Default: "127.0.0.1")
	 Out: Nill ]]--
	NS2GmOvrmind.Server.SetExternalIP("127.0.0.1");

	--[[ The server's external port (the port players should use when connecting)
	 In: INTEGER ServerPort (Default: 27015)
	 Out: Nill ]]--
	NS2GmOvrmind.Server.SetExternalPort(27015);
	
	--[[ If the server has a password on it
	 In: BOOLEAN HasPassword (Default: false)
	 Out: Nill ]]--
	NS2GmOvrmind.Server.SetIsPassworded(false);

	--[[ The maximum slots of the server (including the reserved slots)
	 In: INTEGER MaxSlots (Default: 14)
	 Out: Nill ]]--
	NS2GmOvrmind.Server.SetMaxSlots(14);

	--[[ The amount of reserved-slots (that are restricted to users with reserved-slot priviliges)
	 In: INTEGER ReservedSlots (Default: 2)
	 Out: Nill ]]--
	NS2GmOvrmind.Server.SetReservedSlots(2);


--[[--------------------
 Server-query settings
 -------------------]]--

	--[[ Override NS2's default query-responder with NS2-GmOvrmind's built-in version
	 In: BOOLEAN Enable (Default: true)
	 Out: Nill ]]--
	NS2GmOvrmind.ServerQuery.SetEnabled(true);

	--[[ The listening-port of the query-responder
	 Remark: - By default the query-responder will override NS2's responder, which operates 1 port above it's connect-port
			 - Uses the UDP\IP-protocol
	 In: INTEGER ListenPort (Default: NS2GmOvrmind.Server.GetExternalPort()+1)
	 Out: Nill ]]--
	NS2GmOvrmind.ServerQuery.AddListenPort(NS2GmOvrmind.Server.GetExternalPort());
	NS2GmOvrmind.ServerQuery.AddListenPort(NS2GmOvrmind.Server.GetExternalPort()+1);
	
	--[[ The interval between query-data synchronizations
	 Remarks: - Expressed in seconds
			  - Decimal values are valid
	 In: FLOAT Interval (Default: 0.333)
	 Out: Nill ]]--
	NS2GmOvrmind.ServerQuery.SetUpdateInterval(0.333);


--[[-----------------
 Server-RCON settings
 ----------------]]--

	--[[ Enable NS2-GmOvrmind's built-in RCon-system
	 In: BOOLEAN Enable (Default: true)
	 Out: Nill ]]--
	NS2GmOvrmind.RCon.SetEnabled(false); -- Work in progress, do not enable.

	--[[ The listening-port of the RCon-system
	 Remark: - By default the query-responder will override NS2's responder, which operates 1 port above it's connect-port
			 - Uses the TCP\IP-protocol
	 In: INTEGER ListenPort (Default: NS2GmOvrmind.Server.GetExternalPort()+1)
	 Out: Nill ]]--
	NS2GmOvrmind.RCon.AddListenPort(NS2GmOvrmind.Server.GetExternalPort()+1);

	--[[ The interval between RCon-data\command synchronizations
	 Remarks: - Expressed in seconds
			  - Decimal values are valid
			  - It is recommended to use the same value as the query-responder update-interval
	 In: FLOAT Interval (Default: 0.333)
	 Out: Nill ]]--
	NS2GmOvrmind.RCon.SetSynchronizationInterval(0.333);
	
	--[[ Add an authentication-password
	 Remarks: Multiple passwords can co-exist
	 In: STRING Password
	 Out: Nill ]]--
	NS2GmOvrmind.RCon.AddPassword("rconpass");


--[[--------------------
 Web-statistics settings
 -------------------]]--

	--[[ Enable the ingame-statistics web-server
	 In: BOOLEAN Enable (Default: false)
	 Out: Nill ]]--
	NS2GmOvrmind.WebStats.SetEnabled(false); -- Work in progress, do not enable.

	--[[ The listening-port of the web-server
	 Remarks: Uses the TCP\IP-protocol
	 In: INTEGER ListenPort (Default: 8081)
	 Out: Nill ]]--
	NS2GmOvrmind.WebStats.AddListenPort(8081);

	--[[ The interval between statistics-data synchronizations
	 Remarks: - Expressed in seconds
			  - Decimal values are valid
	 In: FLOAT Interval (Default: 3)
	 Out: Nill ]]--
	NS2GmOvrmind.WebStats.SetUpdateInterval(3);

	--[[ Enable the HTML-page on the statistics-webserver
	 In: BOOLEAN Enabled (Default: true)
	 Out: Nill ]]--
	NS2GmOvrmind.WebStats.SetHTMLFeedEnabled(true);

	--[[ Enable the JSON-feed on the statistics-webserver
	 In: BOOLEAN Enabled (Default: true)
	 Out: Nill ]]--
	NS2GmOvrmind.WebStats.SetJSONFeedEnabled(true);

	--[[ Enable the CSV(tab)-feed on the statistics-webserver
	 In: BOOLEAN Enabled (Default: true)
	 Out: Nill ]]--
	NS2GmOvrmind.WebStats.SetCSVFeedEnabled(true);

	--[[ Enable the PHP(serialized)-feed on the statistics-webserver
	 In: BOOLEAN Enabled (Default: true)
	 Out: Nill ]]--
	NS2GmOvrmind.WebStats.SetPHPFeedEnabled(true);

	--[[ Enable the RSS(XML)-feed on the statistics-webserver
	 In: BOOLEAN Enabled (Default: true)
	 Out: Nill ]]--
	NS2GmOvrmind.WebStats.SetRSSFeedEnabled(true);


--[[------------
 Ingame-settings
 -----------]]--

	--[[ The priviliges non-loggedin players will have
	 Remark: The ConsoleCommand_PING-privilige is hardcoded for now, to allow people to find out if the server is (technically) vanilla or not
	 In: INTEGER Priviliges (Default: NS2GmOvrmind.Priviliges.None +
									NS2GmOvrmind.Priviliges.ConsoleCommand_HELP +
									NS2GmOvrmind.Priviliges.ConsoleCommand_MODINFO +
									NS2GmOvrmind.Priviliges.ConsoleCommand_SERVERINFO +
									NS2GmOvrmind.Priviliges.ConsoleCommand_PING)
	 Out: Nill ]]--
	NS2GmOvrmind.SetGuestPriviliges(NS2GmOvrmind.Priviliges.None +
									NS2GmOvrmind.Priviliges.ConsoleCommand_HELP +
									NS2GmOvrmind.Priviliges.ConsoleCommand_MODINFO +
									NS2GmOvrmind.Priviliges.ConsoleCommand_SERVERINFO +
									NS2GmOvrmind.Priviliges.ConsoleCommand_PING);

	--[[ The minimum amount of time (in seconds) between commands, before the anti-flooding system will kick in
	 In: INTEGER FloodInterval (Default: 3)
	 Out: Nill ]]--
	NS2GmOvrmind.SetAntiCommandFloodInterval(3);


--[[--
 Users
--]]--

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


--[[-
 Bans
-]]--

	--NS2GmOvrmind.Bans.SetFileScanInterval(60);
	NS2GmOvrmind.Bans.SetActiveWorkFile(string.format("%s\\Configuration\\ActiveBans.xml",NS2GmOvrmind.Name.Internal));

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