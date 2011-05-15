--[[ NS2-GmOvrmind(v10) RCon (Server-)Configuration
 --------------------------------------------------
 Author: player (playeru@live.com)
 Date: 16-4-2011
 Mod-version: v9
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: - Use at your own risk
		   - Feel free to copy this script for use in your own projects
		   - Please reference the Readme for further information regarding the configuration and usage of NS2-GmOvrmind
 ------------------------------------------- This file can be modified   ------------------------------------------]]--

--[[-----------------
 Server-RCON settings
 ----------------]]--

	--[[ Enable NS2-GmOvrmind's built-in RCon-system
	 In: BOOLEAN Enable (Default: true)
	 Out: Nill ]]--
	NS2GmOvrmind.RCon.SetEnabled(false);

	--[[ The listening-port of the RCon-system
	 Remark: - By default the query-responder will override NS2's responder, which operates 1 port above it's connect-port
			 - Uses the TCP\IP-protocol
	 In: INTEGER ListenPort (Default: NS2GmOvrmind.Server.GetExternalPort()+1
									  NS2GmOvrmind.Server.GetExternalPort()+2)
	 Out: Nill ]]--
	NS2GmOvrmind.RCon.AddListenPort(NS2GmOvrmind.Server.GetExternalPort()+1);
	NS2GmOvrmind.RCon.AddListenPort(NS2GmOvrmind.Server.GetExternalPort()+2);

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
	--NS2GmOvrmind.RCon.AddPassword("rconpass"); -- Commented for security-reasons, when uncommenting be sure to edit the password
