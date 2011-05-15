--[[ NS2-GmOvrmind(v10) Prerequisites
 -----------------------------------
 Author: player (playeru@live.com)
 Date: 16-4-2011
 Mod-version: v10
 Readme(and Feedback)-URL: http://www.unknownworlds.com/forums/index.php?showtopic=112026
 Comments: - Use at your own risk
		   - feel free to copy this script for use in your own projects
 -------------------------- Do not modify this file ---------------------------------]]--
if(type(NS2GmOvrmind)~="table")then NS2GmOvrmind={};end;
if(NS2GmOvrmind.IsSlave==nil)then NS2GmOvrmind.IsSlave=false;end;
NS2GmOvrmind.Version=10;NS2GmOvrmind.Name={Normal="NS2-GmOvrmind";};
NS2GmOvrmind.Name.Internal=string.gsub(NS2GmOvrmind.Name.Normal,"-","");
NS2GmOvrmind.Name.Full=string.format("%s(v%i)",NS2GmOvrmind.Name.Normal,NS2GmOvrmind.Version);