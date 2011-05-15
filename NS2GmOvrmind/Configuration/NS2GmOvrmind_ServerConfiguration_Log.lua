--[[ NS2-GmOvrmind(v10) Log (Server-)Configuration
 -------------------------------------------------
 Author: player (playeru@live.com)
 Date: 16-4-2011
 Mod-version: v9
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: - Use at your own risk
		   - Feel free to copy this script for use in your own projects
		   - Please reference the Readme for further information regarding the configuration and usage of NS2-GmOvrmind
 ------------------------------------------- This file can be modified   ------------------------------------------]]--

--[[---------
 Log-settings
 --------]]--
 
	--[[ Enable NS2-GmOvrmind's built-in logger
	 In: BOOLEAN Enable
	 Out: Nill ]]--
	NS2GmOvrmind.Log.SetEnabled(false); -- Work in progress, do not uncomment

	--[[ Specifies which data is to be logged
	 In: INTEGER Options
	 Out: Nill ]]--
	--NS2GmOvrmind.Log.SetRecordingOptions(NS2GmOvrmind.Log.RecordingOptions.All); -- Work in progress, do not uncomment

	--[[ Specifies how often new data will be written to the log-file
	 Remarks: - Date\time-stamps are not affected by the delay between the occurance and being written to file
			  - Frequency is expressed in seconds
	 In: INTEGER Frequency
	 Out: Nill ]]--
	--NS2GmOvrmind.Log.SetUpdateFrequency(3); -- Work in progress, do not uncomment

	--[[ Specifies the target-file(path)name to which to write the log-data
	 In: STRING TargetFile
	 Out: Nill ]]--
	--NS2GmOvrmind.Log.SetTargetFilePath(string.format("%s\\Logs\\%s.txt",NS2GmOvrmind.Name.Internal,NS2GmOvrmind.Server.GetName())); -- Work in progress, do not uncomment
