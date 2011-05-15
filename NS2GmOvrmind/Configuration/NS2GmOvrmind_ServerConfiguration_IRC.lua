--[[ NS2-GmOvrmind(v10) IRC (Server-)Configuration
 -------------------------------------------------
 Author: player (playeru@live.com)
 Date: 16-4-2011
 Mod-version: v9
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: - Use at your own risk
		   - Feel free to copy this script for use in your own projects
		   - Please reference the Readme for further information regarding the configuration and usage of NS2-GmOvrmind
 ------------------------------------------- This file can be modified   ------------------------------------------]]--

--[[------------
 IRC-Relay\Admin
 -----------]]--

	--[[ Enable Ovrmind's IRC-system
	 In: BOOLEAN Enable
	 Out: Nill ]]--
	NS2GmOvrmind.IRC.SetEnabled(false);  -- Work in progress, do not enable

	--[[ Creates a new bot-instance
	 Remark: This creates a new bot, but doesn't automatically add it to the overmind-system, use "NS2GmOvrmind.IRC.AddConnection" for that. 
	 In: Nill
	 Out: CNS2GmOvrmind_IRCBot BotInstance ]]--
	--TestIRCBot=NS2GmOvrmind.IRC.NewConnection(); -- Work in progress, do not uncomment

	--[[-----
	 Test-bot
	 ----]]--

		--[[ Set the hostname the bot has to connect to
		 In: STRING HostName
		 Out: Nill ]]--
		--TestIRCBot:SetHostName("127.0.0.1"); -- Work in progress, do not uncomment

		--[[ Sets the port the bot should connect through to
		 In: INTEGER Port
		 Out: Nill ]]--
		--TestIRCBot:SetPort("6667"); -- Work in progress, do not uncomment

		--[[ Sets the password the bot should use
		 In: INTEGER Port
		 Out: Nill ]]--
		--TestIRCBot:SetPassword(""); -- Work in progress, do not uncomment

		--[[ Sets the nick-name the bot should use on IRC
		 In: STRING NickName
		 Out: Nill ]]--
		--TestIRCBot:SetNickName("My-NS2-Server"); -- Work in progress, do not uncomment

		--[[ Sets the ident the bot should report to the IRC-server
		 In: STRING Ident
		 Out: Nill ]]--
		--TestIRCBot:SetIdent("GmOvrmind"); -- Work in progress, do not uncomment

		--[[ Sets the ident the bot should report to the IRC-server
		 In: STRING Ident
		 Out: Nill ]]--
		--TestIRCBot:SetRealName("NS2-GmOvrmind IRC-relay&admin"); -- Work in progress, do not uncomment

		--[[ Adds a channel the bot should join upon establishing a connection
		 Remark: The number-sign (#) is allowed to be ommited
		 In: STRING Channel
		 Out: Nill ]]--
		--TestIRCBot:AddChannel("testchan1"); -- Work in progress, do not uncomment
		--TestIRCBot:AddChannel("testchan2"); -- Work in progress, do not uncomment

	--[[ Adds the bot-instance to the overmind-system
	 In: CNS2GmOvrmind_IRCBot BotInstance
	 Out: Nill ]]--
	--NS2GmOvrmind.IRC.AddConnection(TestIRCBot); -- Work in progress, do not uncomment
