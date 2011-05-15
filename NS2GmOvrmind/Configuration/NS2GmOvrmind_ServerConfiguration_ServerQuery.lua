--[[ NS2-GmOvrmind(v10) Server-query (Server-)Configuration
 ----------------------------------------------------------
 Author: player (playeru@live.com)
 Date: 16-4-2011
 Mod-version: v9
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: - Use at your own risk
		   - Feel free to copy this script for use in your own projects
		   - Please reference the Readme for further information regarding the configuration and usage of NS2-GmOvrmind
 ------------------------------------------- This file can be modified   ------------------------------------------]]--

--[[------------------
 Server-query settings
 -----------------]]--

	--[[ Enable NS2-GmOvrmind's built-in custom query-responder
	 In: BOOLEAN Enable (Default: true)
	 Out: Nil ]]--
	NS2GmOvrmind.ServerQuery.SetEnabled(true);

	--[[ Create a new responder-instance
	 Remark: This creates a new responder, but doesn't automatically add it to the overmind-system, use "NS2GmOvrmind.ServerQuery.AddResponder" for that.
	 In: Nil
	 Out: CNS2GmOvrmind_QueryResponder ResponderInstance ]]--
	local QueryResponder=NS2GmOvrmind.ServerQuery.NewResponder();

	--[[--------------------
	 QueryResponder-instance
	 -------------------]]--

		--[[ Specifies the information that will be disclosed via the query-responder
		 Remark: Possible options are as follows:
			NS2GmOvrmind.ServerQuery.Information.Server.Name
			NS2GmOvrmind.ServerQuery.Information.Server.Game
			NS2GmOvrmind.ServerQuery.Information.Server.Map
			NS2GmOvrmind.ServerQuery.Information.Server.MaxPlayers
			NS2GmOvrmind.ServerQuery.Information.Server.Players
			NS2GmOvrmind.ServerQuery.Information.Server.BotCount
			NS2GmOvrmind.ServerQuery.Information.Server.Version
			NS2GmOvrmind.ServerQuery.Information.Server.VAC
			NS2GmOvrmind.ServerQuery.Information.Server.Dedicated
			NS2GmOvrmind.ServerQuery.Information.Server.OS
			NS2GmOvrmind.ServerQuery.Information.Server.GameID
			NS2GmOvrmind.ServerQuery.Information.Rules.ExternalIP
			NS2GmOvrmind.ServerQuery.Information.Rules.ExternalConnectPort
			NS2GmOvrmind.ServerQuery.Information.Rules.ExternalSparkQueryPort
			NS2GmOvrmind.ServerQuery.Information.Rules.ExternalOmQueryPort
			NS2GmOvrmind.ServerQuery.Information.Rules.Cheats
			NS2GmOvrmind.ServerQuery.Information.Rules.DeveloperMode
			NS2GmOvrmind.ServerQuery.Information.Rules.FriendlyFire
			NS2GmOvrmind.ServerQuery.Information.Rules.ReservedSlots
			NS2GmOvrmind.ServerQuery.Information.Rules.MaxSlots
			NS2GmOvrmind.ServerQuery.Information.Rules.StartTime
			NS2GmOvrmind.ServerQuery.Information.Rules.LocalTime
			NS2GmOvrmind.ServerQuery.Information.Rules.Tickrate
			NS2GmOvrmind.ServerQuery.Information.Rules.Uptime
			NS2GmOvrmind.ServerQuery.Information.Rules.OmVersion
			NS2GmOvrmind.ServerQuery.Information.Rules.NS2Version
			NS2GmOvrmind.ServerQuery.Information.Rules.PlayerData.Name
			NS2GmOvrmind.ServerQuery.Information.Rules.PlayerData.IsBot
			NS2GmOvrmind.ServerQuery.Information.Rules.PlayerData.SteamID
			NS2GmOvrmind.ServerQuery.Information.Rules.PlayerData.Score
			NS2GmOvrmind.ServerQuery.Information.Rules.PlayerData.Kills
			NS2GmOvrmind.ServerQuery.Information.Rules.PlayerData.Deaths
			NS2GmOvrmind.ServerQuery.Information.Rules.PlayerData.Ping
			NS2GmOvrmind.ServerQuery.Information.Player.Name
			NS2GmOvrmind.ServerQuery.Information.Player.Kills
			NS2GmOvrmind.ServerQuery.Information.Player.TimeConnected
		 In: DOUBLE Information (Default: NS2GmOvrmind.ServerQuery.Information.All)
		 Out: Nil ]]--
		QueryResponder:SetExposedInformation(NS2GmOvrmind.ServerQuery.Information.All);

		--[[ The listening-port of the query-responder
		 Remark: - By default the query-responder will sit 1 port above NS2's responder, which in turn operates 1 port above it's connect-port
				 - Uses the UDP\IP-protocol
		 In: INTEGER ListenPort (Default: NS2GmOvrmind.Server.GetExternalPort()+2)
		 Out: Nil ]]--
		QueryResponder:AddListenPort(NS2GmOvrmind.Server.GetExternalPort()+2);

		--[[ The interval between query-data synchronizations
		 Remarks: - Expressed in seconds
				  - Decimal values are valid
		 In: DOUBLE Interval (Default: 1/3)
		 Out: Nil ]]--
		QueryResponder:SetUpdateInterval(1/3);
		
		--[[------------------------------
		 QueryResponder Connector-settings
		 -----------------------------]]--

			--[[ Enable the connector-ability
			 In: BOOLEAN Connectable
			 Out: Nil ]]--
			--QueryResponder.Connector.SetEnable(true);

			--[[ Set the connector-timeout period
			 In: INTEGER Period
			 Out: Nil ]]--
			--QueryResponder.Connector.SetTimeOutPeriod(60);

		--[[------------------------------------------------]]--

	--[[ Adds the responder-instance to the overmind-system
	 In: CNS2GmOvrmind_QueryResponder ResponderInstance
	 Out: Nil ]]--
	NS2GmOvrmind.ServerQuery.AddResponder(QueryResponder);
