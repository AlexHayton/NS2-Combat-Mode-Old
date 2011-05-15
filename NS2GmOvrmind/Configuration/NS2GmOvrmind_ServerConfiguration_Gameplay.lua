--[[ NS2-GmOvrmind(v10) Gameplay (Server-)Configuration
 ------------------------------------------------------
 Author: player (playeru@live.com)
 Date: 16-4-2011
 Mod-version: v10
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: - Use at your own risk
		   - Feel free to copy this script for use in your own projects
		   - Please reference the Readme for further information regarding the configuration and usage of NS2-GmOvrmind
 ------------------------------------------- This file can be modified   ------------------------------------------]]--

--[[-------------------
 Game(play)-alterations
 ------------------]]--

	--[[----------
	 Field-of-View
	 ---------]]--

		--[[ Sets the value with which to multiply all the Field-of-View values
		 Remarks: - The default FoV-values as of build 169 are: Marines=90; Marine\Alien-Commanders=90; Skulks=110; Gorges=95; Lerks=100; Fades=90; Onos=95
				  - Pass 1 to use the default NS2-values
				  - The recommended value is 1+1/6 (equal to about 1.1666) (results in a FoV of 105 for marines and 128 for skulks)
				  - The highest reasonable value is 1+1/4.5 (equal to about 1.222) (results in a FoV of 110 for marines 134 for skulks)
				  - A FoV-value higher than 179 will result in a black screen
		 In: FLOAT Multiplier
		 Out: Nill ]]--
		NS2GmOvrmind.FoV.SetMultiplier(1+1/6);

		--[[ Sets the FoV balance-value (a reference value for other variables)
		 Remarks: - This FoV balance-value isn't in use at the time of writing, and as such has no influence on any FoV-value
				  - The default FoV balance-value is 90
				  - A value of naught triggers no change
				  - A value higher than 179 will result in a black screen
		 In: INTEGER FoV
		 Out: Nill ]]--
		NS2GmOvrmind.FoV.SetBalance(0);
		
		--[[ Sets the FoV player-value (a reference value used for readyroom'ers and marines)
		 Remarks: - The default FoV balance-value is 90
				  - A value of naught triggers no change
				  - Recommended values lie between 90 and 110
				  - A value higher than 179 will result in a black screen
		 In: INTEGER FoV
		 Out: Nill ]]--
		NS2GmOvrmind.FoV.SetPlayer(0);

		--[[ Sets FoV-value for commanders
		 Remarks: - The default FoV-value for commanders is 90
				  - A value of naught triggers no change
				  - A higher FoV value for commanders translates into a more zoomed-out topdown-view
				  - Recommended values lie between 90 and 115
				  - A value higher than 179 will result in a black screen
		 In: INTEGER FoV
		 Out: Nill ]]--
		NS2GmOvrmind.FoV.SetCommander(0);

		--[[ Sets FoV-value for marines while sprinting
		 Remarks: - The default FoV-value for marines while sprinting is 95
				  - A value of naught triggers no change
				  - Recommended value is NS2GmOvrmind.FoV.GetMarine()+5
				  - A value higher than 179 will result in a black screen
		 In: INTEGER FoV
		 Out: Nill ]]--
		NS2GmOvrmind.FoV.SetMarineSprint(0);

		--[[ Sets the FoV-value for skulks
		 Remarks: - The default FoV-value for skulks is 110
				  - A value of naught triggers no change
				  - Recommended values lie between 110 and 140
				  - A value higher than 179 will result in a black screen
		 In: INTEGER FoV
		 Out: Nill ]]--
		NS2GmOvrmind.FoV.SetSkulk(0);

		--[[ Sets the FoV-value for gorges
		 Remarks: - The default FoV-value for gorges is 95
				  - A value of naught triggers no change
				  - Recommended values lie between 95 and 115
				  - A value higher than 179 will result in a black screen
		 In: INTEGER FoV
		 Out: Nill ]]--
		NS2GmOvrmind.FoV.SetGorge(0);

		--[[ Sets the FoV-value for lerks
		 Remarks: - The default FoV-value for lerks is 100
				  - A value of naught triggers no change
				  - Recommended values lie between 100 and 125
				  - A value higher than 179 will result in a black screen
		 In: INTEGER FoV
		 Out: Nill ]]--
		NS2GmOvrmind.FoV.SetLerk(0);

		--[[ Sets the FoV-value for lerks while (spike)zooming
		 Remarks: - The default FoV-value for lerks while (spike)zooming is 45
				  - A value of naught triggers no change
				  - Recommended values lie between 45 and 60
				  - A value higher than 179 will result in a black screen
		 In: INTEGER FoV
		 Out: Nill ]]--
		NS2GmOvrmind.FoV.SetLerkZoom(0);

		--[[ Sets the FoV-value for fades
		 Remarks: - The default FoV-value for fade is 90
				  - A value of naught triggers no change
				  - Recommended values lie between 90 and 110
				  - A value higher than 179 will result in a black screen
		 In: INTEGER FoV
		 Out: Nill ]]--
		NS2GmOvrmind.FoV.SetFade(0);

		--[[ Sets the FoV-value for onosses
		 Remarks: - The default FoV-value for onosses is 95
				  - A value of naught triggers no change
				  - Recommended values lie between 95 and 115
				  - A value higher than 179 will result in a black screen
		 In: INTEGER FoV
		 Out: Nill ]]--
		NS2GmOvrmind.FoV.SetOnos(0);
