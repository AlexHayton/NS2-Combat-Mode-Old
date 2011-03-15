--[[ NS2-GmOvrmind(v7) Server-BootLoader
 ---------------------------------------
 Author: player (playeru@live.com)
 Date: 6-3-2011
 Mod-version: v7
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: Use at your own risk and feel free to copy this script for use in your own projects
 -----------------------------------------------------------------------------------------]]--
Script.Load("..\\NS2GmOvrmind\\Lua\\NS2GmOvrmind.lua");NS2GmOvrmind.Lua={};NS2GmOvrmind.DLL={};NS2GmOvrmind.WebAdmin={};NS2GmOvrmind.Server={};class'CNS2GmOvrmind';function CNS2GmOvrmind:__init()
	NS2GmOvrmind.InitFunc,CallRes=package.loadlib(string.format("%s\\Binaries_x86\\%s.dll",NS2GmOvrmind.Name.Internal,NS2GmOvrmind.Name.Internal),string.format("%s_Initialize",NS2GmOvrmind.Name.Internal));
	if(NS2GmOvrmind.InitFunc==nil)then Shared.Message(string.format("%s: Failed to load DLL, diagnostic-message: %s",NS2GmOvrmind.Name.Full,CallRes));
	elseif(not NS2GmOvrmind.IsSlave)then NS2GmOvrmind.InitFunc(0);end;
end;INS2GmOvrmind=CNS2GmOvrmind();