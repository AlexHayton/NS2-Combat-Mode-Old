--[[ NS2-GmOvrmind(v10) Server (Server-)Configuration
 ----------------------------------------------------
 Author: player (playeru@live.com)
 Date: 16-4-2011
 Mod-version: v9
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: - Use at your own risk
		   - Feel free to copy this script for use in your own projects
		   - Please reference the Readme for further information regarding the configuration and usage of NS2-GmOvrmind
 ------------------------------------------- This file can be modified   ------------------------------------------]]--

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
	 In: INTEGER MaxSlots (Default: 11)
	 Out: Nill ]]--
	NS2GmOvrmind.Server.SetMaxSlots(11);

	--[[ The amount of reserved-slots (that are restricted to users with reserved-slot priviliges)
	 In: INTEGER ReservedSlots (Default: 1)
	 Out: Nill ]]--
	NS2GmOvrmind.Server.SetReservedSlots(1);
