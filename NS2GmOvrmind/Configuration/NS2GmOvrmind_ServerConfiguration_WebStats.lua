--[[ NS2-GmOvrmind(v10) Web-stastistics (Server-)Configuration
 -------------------------------------------------------------
 Author: player (playeru@live.com)
 Date: 16-4-2011
 Mod-version: v9
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: - Use at your own risk
		   - Feel free to copy this script for use in your own projects
		   - Please reference the Readme for further information regarding the configuration and usage of NS2-GmOvrmind
 ------------------------------------------- This file can be modified   ------------------------------------------]]--

--[[--------------------
 Web-statistics settings
 -------------------]]--

	--[[ Enable the ingame-statistics web-server
	 In: BOOLEAN Enable (Default: false)
	 Out: Nill ]]--
	NS2GmOvrmind.WebStats.SetEnabled(false); -- Work in progress, do not enable (potentially unstable)

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
