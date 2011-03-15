--[[ NS2-GmOvrmind(v7) Prerequisites
 -----------------------------------
 Author: player (playeru@live.com)
 Date: 6-3-2011
 Mod-version: v7
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: Use at your own risk and feel free to copy this script for use in your own projects
 -----------------------------------------------------------------------------------------]]--
if(type(NS2GmOvrmind)~="table")then NS2GmOvrmind={};end;
if(NS2GmOvrmind.IsSlave==nil)then NS2GmOvrmind.IsSlave=false;end;
NS2GmOvrmind.Version=7;NS2GmOvrmind.Name={Normal="NS2-GmOvrmind";};
NS2GmOvrmind.Name.Internal=string.gsub(NS2GmOvrmind.Name.Normal,"-","");
NS2GmOvrmind.Name.Full=string.format("%s(v%i)",NS2GmOvrmind.Name.Normal,NS2GmOvrmind.Version);