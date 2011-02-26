--[[ NS2-GmOvrmind(v4) Server-BootLoader
 ---------------------------------------
 Author: player (playeru@live.com)
 Date: 26-1-2011
 Mod-version: v4
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: Use at your own risk and feel free to copy this script for use in your own projects
 -----------------------------------------------------------------------------------------]]--
NS2GmOvrmind={Version=4;};NS2GmOvrmind.Name={Normal="NS2-GmOvrmind";};
NS2GmOvrmind.Name.Internal=string.gsub(NS2GmOvrmind.Name.Normal,"-","");
NS2GmOvrmind.Name.Full=string.format("%s(v%i)",NS2GmOvrmind.Name.Normal,NS2GmOvrmind.Version);
NS2GmOvrmind.Lua={};NS2GmOvrmind.DLL={};NS2GmOvrmind.WebAdmin={};class'CNS2GmOvrmind';function CNS2GmOvrmind:__init()
	NS2GmOvrmind.InitFunc,CallRes=package.loadlib(string.format("%s\\Binaries\\%s_x86.dll",NS2GmOvrmind.Name.Internal,NS2GmOvrmind.Name.Internal),string.format("%s_Initialize",NS2GmOvrmind.Name.Internal));
	if(NS2GmOvrmind.InitFunc==nil)then Shared.Message(string.format("%s: Failed to load DLL, diagnostic-message: %s",NS2GmOvrmind.Name.Full,CallRes));
	elseif(NS2MltiMod==nil)then NS2GmOvrmind.InitFunc(0);end;
end;INS2GmOvrmind=CNS2GmOvrmind();