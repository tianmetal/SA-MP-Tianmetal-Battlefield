#include <a_samp>

#include <streamer>
#include <gvar>

#define _YSI_NO_VERSION_CHECK

#include <YSI\y_master>
#include <YSI\y_classes>
#include <YSI\y_groups>
#include <YSI\y_timers>

#define Pressed(%0) ((newkeys & %0) && !(oldkeys & %0))

main() { }

#define COLOR_SQUAD     0x00FF00FF
#define COLOR_ALLY      0x0000FFFF
#define COLOR_ENEMY     0xFF000000

#define CHAT_MODE_GLOBAL    0
#define CHAT_MODE_TEAM      1
#define CHAT_MODE_SQUAD     2

new Group:Spectator;
new Group:America;
new Group:Russia;
new Group:USSquad[10];
new Group:RUSquad[10];

#pragma unused Spectator

new Group:PlayerGroup[MAX_PLAYERS];
new Group:PlayerSquad[MAX_PLAYERS];
new PlayerArea[MAX_PLAYERS];
new ChatMode[MAX_PLAYERS];

new AmericaBounds[4];
new RussiaBounds[4];

new bool:GameStarted = true;
new AmericaScore = 0;
new RussiaScore = 0;

new SquadNames[2][10][] = {
{{"Adams"},{"Boston"},{"Chicago"},{"Denver"},{"Easy"},{"Frank"},{"George"},{"Henry"},{"Ida"},{"John"}},
{{"Alpha"},{"Bravo"},{"Charlie"},{"Delta"},{"Echo"},{"Foxtrot"},{"Golf"},{"Hotel"},{"India"},{"Juliet"}}};

new Spotted[MAX_PLAYERS];

new USMain,USMedic,USEngineer,USScout,
	RUMain,RUMedic,RUEngineer,RUScout;

enum pointinfo
{
	Group:CapturedBy,
	CapturePoint,
	Vehicle[3],
	Area,
	Zone,
	Text3D:Label
}
new PointInfo[5][pointinfo];
new Float:PointSpawns[5][3] = {
{-487.0567,-523.3660,25.5178},
{-461.3968,-61.1654,59.9887},
{-41.6668,-10.7246,3.1172},
{129.8287,-262.4420,1.5781},
{183.1829,-107.5377,2.0234}
};

public OnPlayerText(playerid,text[])
{
	new string[144],playername[MAX_PLAYER_NAME];
	GetPlayerName(playerid,playername,sizeof(playername));
	switch(ChatMode[playerid])
	{
	    case CHAT_MODE_GLOBAL:
	    {
	        new Group:enemy = ((PlayerGroup[playerid] == America) ? (Russia) : (America));
	        format(string,sizeof(string),"[ALL] {00ffff}%s{ffffff}: %s",playername,text);
	        foreach(new i : GroupMember(PlayerGroup[playerid]))
	        {
	            if(i == playerid) continue;
	            if(Group_GetPlayer(PlayerSquad[playerid],i)) continue;
	            SendClientMessage(i,-1,string);
	        }
	        format(string,sizeof(string),"[ALL] {00ff00}%s{ffffff}: %s",playername,text);
	        foreach(new i : GroupMember(PlayerSquad[playerid]))
	        {
	            SendClientMessage(i,-1,string);
	        }
	        format(string,sizeof(string),"[ALL] {ff0000}%s{ffffff}: %s",playername,text);
	        foreach(new i : GroupMember(enemy))
	        {
	            SendClientMessage(i,-1,string);
	        }
	    }
	    case CHAT_MODE_TEAM:
	    {
	        format(string,sizeof(string),"[TEAM] {00ffff}%s{ffffff}: %s",playername,text);
	        foreach(new i : GroupMember(PlayerGroup[playerid]))
	        {
	            if(i == playerid) continue;
	            if(Group_GetPlayer(PlayerSquad[playerid],i)) continue;
	            SendClientMessage(i,-1,string);
	        }
	        format(string,sizeof(string),"[TEAM] {00ff00}%s{ffffff}: %s",playername,text);
	        foreach(new i : GroupMember(PlayerSquad[playerid]))
	        {
	            SendClientMessage(i,-1,string);
	        }
	    }
	    case CHAT_MODE_SQUAD:
	    {
	        format(string,sizeof(string),"[SQUAD] {00ff00}%s{ffffff}: %s",playername,text);
	        foreach(new i : GroupMember(PlayerSquad[playerid]))
	        {
	            SendClientMessage(i,-1,string);
	        }
	    }
	}
	return 0;
}
public OnGameModeInit()
{
	new string[128];

	DisableInteriorEnterExits();
    EnableVehicleFriendlyFire();

	SetGameModeText("JG:BF 0.1");

    GameStarted = true;

    Spectator = Group_Create("Spectator");
	America = Group_Create("United States");
	Russia = Group_Create("Russian Federation");
	
	for(new i = 0; i < 10; i++)
	{
		USSquad[i] = Group_Create(SquadNames[0][i]);
		Group_SetGroup(America,USSquad[i],true);
	}
	for(new i = 0; i < 10; i++)
	{
		RUSquad[i] = Group_Create(SquadNames[1][i]);
		Group_SetGroup(Russia,RUSquad[i],true);
	}
	
	AmericaBounds[0] = GangZoneCreate(-1120.0,311.0,4000.0,4000.0);
	AmericaBounds[1] = GangZoneCreate(517.0,-4000.0,4000.0,311.0);
	AmericaBounds[2] = GangZoneCreate(-4000.0,-4000.0,517.0,-766.0);
	AmericaBounds[3] = GangZoneCreate(-4000.0,-766.0,-1120.0,4000.0);

	RussiaBounds[0] = GangZoneCreate(-962.0,460.0,4000.0,4000.0);
	RussiaBounds[1] = GangZoneCreate(675.0,-4000.0,4000.0,460.0);
	RussiaBounds[2] = GangZoneCreate(-4000.0,-4000.0,675.0,-645.0);
	RussiaBounds[3] = GangZoneCreate(-4000.0,-645.0,-962.0,4000.0);
	
	USMain = Class_AddForGroup(America,287,-1021.1161,-638.7183,32.0078,4.5701,31,500,24,70,16,2);
	USMedic = Class_AddForGroup(America,275,-1021.1161,-638.7183,32.0078,4.5701,25,100,22,300,16,1);
	USEngineer = Class_AddForGroup(America,42,-1021.1161,-638.7183,32.0078,4.5701,29,300,36,3,16,1);
	USScout = Class_AddForGroup(America,73,-1021.1161,-638.7183,32.0078,4.5701,34,100,23,200,16,1);
	RUMain = Class_AddForGroup(Russia,285,584.6122,380.9302,18.9297,216.1082,30,500,24,70,16,2);
	RUMedic = Class_AddForGroup(Russia,276,584.6122,380.9302,18.9297,216.1082,25,100,22,300,16,1);
	RUEngineer = Class_AddForGroup(Russia,50,584.6122,380.9302,18.9297,216.1082,29,300,35,3,16,1);
	RUScout = Class_AddForGroup(Russia,126,584.6122,380.9302,18.9297,216.1082,34,100,23,200,16,1);

	CreateVehicle(470, -1006.2512, -630.4595, 32.0356, 87.0736, 0, 0, 120);
	CreateVehicle(470, -1005.9141, -634.1339, 32.0306, 86.0733, 0, 0, 120);
	CreateVehicle(470, -1005.6704, -638.6704, 32.0359, 85.7648, 0, 0, 120);
	CreateVehicle(469, -124.8140, -288.5700, 30.4885, 204.2253, 0, 0, 300);
	CreateVehicle(469, -1045.1706, -667.6444, 31.9491, 295.7359, 0, 0, 300);
	CreateVehicle(433, -1013.5336, -657.4805, 32.3771, 5.2440, 0, 0, -1);
	CreateVehicle(433, -1007.0798, -657.0817, 32.3772, 14.6545, 0, 0, -1);

	CreateVehicle(470, 606.2531, 355.8976, 18.9583, 213.8809, -1, -1, 120);
	CreateVehicle(470, 600.5552, 364.3801, 18.9589, 213.2082, -1, -1, 120);
	CreateVehicle(470, 594.2916, 372.9616, 18.9583, 216.9106, -1, -1, 120);
	CreateVehicle(469, 591.3432, 318.3272, 19.2049, 162.3014, -1, -1, 300);
	CreateVehicle(469, 572.4553, 313.4254, 18.3086, 171.3799, -1, -1, 300);
	CreateVehicle(433, 600.5718, 352.7698, 19.3046, 214.8992, -1, -1, -1);
	CreateVehicle(433, 592.1424, 364.8628, 19.3688, 214.5977, -1, -1, -1);
	
	PointInfo[0][Vehicle][0] = CreateVehicle(470, -502.8778, -484.7270, 25.4484, 196.7521, -1, -1, 120);
	PointInfo[0][Vehicle][1] = CreateVehicle(470, -496.7784, -483.5766, 25.4153, 197.9182, -1, -1, 120);
	PointInfo[0][Vehicle][2] = CreateVehicle(470, -490.3414, -484.2034, 25.5490, 200.1021, -1, -1, 120);
	PointInfo[1][Vehicle][0] = CreateVehicle(470, -529.0543, -74.3520, 62.6240, 270.1170, -1, -1, 120);
	PointInfo[1][Vehicle][1] = CreateVehicle(470, -535.9885, -60.9563, 63.0204, 271.9352, -1, -1, 120);
	PointInfo[1][Vehicle][2] = CreateVehicle(470, -524.5026, -60.7295, 62.4745, 271.6145, -1, -1, 120);
	PointInfo[2][Vehicle][0] = CreateVehicle(470, -75.4308, 0.7766, 3.1441, 161.3681, -1, -1, 120);
	PointInfo[2][Vehicle][1] = CreateVehicle(470, -80.9027, 4.2924, 3.0134, 167.0033, -1, -1, 120);
	PointInfo[2][Vehicle][2] = CreateVehicle(470, -84.7141, -19.7829, 3.1437, 343.4898, -1, -1, 120);
	PointInfo[3][Vehicle][0] = CreateVehicle(470, 126.0074, -279.0897, 1.4814, 43.4955, -1, -1, 120);
	PointInfo[3][Vehicle][1] = CreateVehicle(470, 118.9174, -281.4050, 1.5481, 18.7309, -1, -1, 120);
	PointInfo[3][Vehicle][2] = CreateVehicle(470, 105.3235, -283.7354, 1.4885, 1.6904, -1, -1, 120);
	PointInfo[4][Vehicle][0] = CreateVehicle(470, 225.6997, -98.3659, 1.6059, 184.4612, -1, -1, 120);
	PointInfo[4][Vehicle][1] = CreateVehicle(470, 226.3283, -110.3872, 1.7454, 177.8060, -1, -1, 120);
	PointInfo[4][Vehicle][2] = CreateVehicle(470, 239.3437, -100.7026, 1.5343, 2.9117, -1, -1, 120);
	
	for(new i = 0; i < 5; i++)
	{
		format(string,sizeof(string),"Point %c\nNone\n[          ]",'A'+i);
		PointInfo[i][CapturedBy] = INVALID_GROUP;
		PointInfo[i][CapturePoint] = 0;
		PointInfo[i][Area] = CreateDynamicCube(PointSpawns[i][0]-20.0,PointSpawns[i][1]-20.0,PointSpawns[i][2]-20.0,PointSpawns[i][0]+20.0,PointSpawns[i][1]+20.0,PointSpawns[i][2]+20.0,0,0);
		PointInfo[i][Zone] = GangZoneCreate(PointSpawns[i][0]-20.0,PointSpawns[i][1]-20.0,PointSpawns[i][0]+20.0,PointSpawns[i][1]+20.0);
		PointInfo[i][Label] = CreateDynamic3DTextLabel(string,0xFFFFFFFF,PointSpawns[i][0],PointSpawns[i][1],PointSpawns[i][2]+3.0,100.0,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,0,0,-1,500.0);
		for(new j = 0; j < 3; j++)
		{
			SetVehicleVirtualWorld(PointInfo[i][Vehicle][j],1);
		}
	}
	
	return 1;
}
public OnGameModeExit()
{
	return 1;
}

stock abs(const value)
{
	new ret = value;
	if(ret < 0)
	{
	    ret = (ret*-1);
	}
	return ret;
}
stock Group:FindSquad(Group:team)
{
	foreach(new Group:squad : GroupChild[team])
	{
	    if(Group_GetCount(squad) >= 5) continue;
	    return squad;
	}
	return INVALID_GROUP;
}
stock GetXYRightOfPoint(Float:x,Float:y,&Float:x2,&Float:y2,Float:A,Float:distance)
{
	x2 = x - (distance * floatsin(-A+90.0,degrees));
	y2 = y - (distance * floatcos(-A+90.0,degrees));
}
stock GetXYBehindPoint(Float:x,Float:y,&Float:x2,&Float:y2,Float:A,Float:distance)
{
	x2 = x - (distance * floatsin(-A,degrees));
	y2 = y - (distance * floatcos(-A,degrees));
}
stock SendGroupMessage(Group:group,color,const message[])
{
	foreach(new p : GroupMember(group))
	{
	    SendClientMessage(p,color,message);
	}
	return 1;
}

public OnPlayerConnect(playerid)
{
    new string[128];
	new Group:joined = Group_SetBalanced(playerid,_:America,_:Russia);
	new Group:squad = FindSquad(joined);
	PlayerGroup[playerid] = joined;
	SendClientMessage(playerid,-1,"SERVER: Welcome to {00ffff}Jogjagamers: Battlefield - {ffff00}ALPHA");
	SendClientMessage(playerid,-1,"SERVER: {00ffff}Blue {ffffff}and {00ff00}Lime {ffffff}colored players are your teammates");
	SendClientMessage(playerid,-1,"SERVER: {ff0000}Red {ffffff}colored players are your enemies");
	SendClientMessage(playerid,-1,"SERVER: You can not go within the {ff0000}red area {ffffff}on your map");
	SendClientMessage(playerid,-1,"SERVER: Your objective is to capture points shown in maps and kill many enemies");
	
	StopAudioStreamForPlayer(playerid);
	
	format(string,sizeof(string),"INFO: You've joined team \"%s\"",Group_GetName(joined));
	SendClientMessage(playerid,-1,string);
	
	PlayerArea[playerid] = CreateDynamicSphere(0.0,0.0,0.0,5.0,0,0);
	
	if(squad != INVALID_GROUP)
	{
	    PlayerSquad[playerid] = squad;
	    format(string,sizeof(string),"INFO: You've been assigned to squad \"%s\"",Group_GetName(squad));
		Group_SetPlayer(squad,playerid,true);
		SendClientMessage(playerid,-1,string);
	}
	
	if(joined == America)
	{
	    Class_SetPlayer(USMain,playerid,true);
	    Class_SetPlayer(USMedic,playerid,true);
	    Class_SetPlayer(USEngineer,playerid,true);
	    Class_SetPlayer(USScout,playerid,true);
	    Class_SetPlayer(RUMain,playerid,false);
	    Class_SetPlayer(RUMedic,playerid,false);
	    Class_SetPlayer(RUEngineer,playerid,false);
	    Class_SetPlayer(RUScout,playerid,false);
	}
	else
	{
	    Class_SetPlayer(RUMain,playerid,true);
	    Class_SetPlayer(RUMedic,playerid,true);
	    Class_SetPlayer(RUEngineer,playerid,true);
	    Class_SetPlayer(RUScout,playerid,true);
	    Class_SetPlayer(USMain,playerid,false);
	    Class_SetPlayer(USMedic,playerid,false);
	    Class_SetPlayer(USEngineer,playerid,false);
	    Class_SetPlayer(USScout,playerid,false);
	}
	return 1;
}
public OnPlayerDisconnect(playerid,reason)
{
	DestroyDynamicArea(PlayerArea[playerid]);
	return 1;
}
public OnPlayerRequestClass(playerid,classid)
{
	if(GameStarted == false)
	{
	    TogglePlayerSpectating(playerid,1);
	}
    SetPlayerPos(playerid,-92.7156,-222.7055,41.2267);
	SetPlayerFacingAngle(playerid,0.0);
    SetPlayerVirtualWorld(playerid,(playerid+1));
	PlayerSpectatePlayer(playerid,playerid,SPECTATE_MODE_FIXED);
	SetPlayerCameraPos(playerid,-92.7156,-212.7055,43.2267);
	SetPlayerCameraLookAt(playerid,-92.7156,-222.7055,41.2267);
	if(classid == USMain || classid == RUMain) GameTextForPlayer(playerid,"Assault",2000,6);
	else if(classid == USMedic || classid == RUMedic) GameTextForPlayer(playerid,"Medic",2000,6);
	else if(classid == USEngineer || classid == RUEngineer) GameTextForPlayer(playerid,"Engineer",2000,6);
	else if(classid == USScout || classid == RUScout) GameTextForPlayer(playerid,"Scout",2000,6);
	return 1;
}
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(Pressed(KEY_YES))
	{
	    ChatMode[playerid]++;
	    if(ChatMode[playerid] > 2) ChatMode[playerid] = 0;
	    switch(ChatMode[playerid])
	    {
	        case CHAT_MODE_GLOBAL: SendClientMessage(playerid,-1,"CHAT: Chat mode changed to [ALL]");
	        case CHAT_MODE_TEAM: SendClientMessage(playerid,-1,"CHAT: Chat mode changed to [TEAM]");
	        case CHAT_MODE_SQUAD: SendClientMessage(playerid,-1,"CHAT: Chat mode changed to [SQUAD]");
	    }
	}
	return 1;
}
stock ShowSpawnDialog(playerid)
{
    new string[256],substring[32];
	strcat(string,"{00ffff}Base\n",sizeof(string));
	for(new i = 0; i < 5; i++)
	{
	    format(substring,sizeof(substring),"Point %c\n",'A'+i);
	    if(PointInfo[i][CapturedBy] == PlayerGroup[playerid])
	    {
			strcat(string,"{00ffff}",sizeof(string));
	    }
	    else if(PointInfo[i][CapturedBy] == INVALID_GROUP)
	    {
	        strcat(string,"{ffffff}",sizeof(string));
	    }
	    else
	    {
	        strcat(string,"{ff0000}",sizeof(string));
	    }
	    strcat(string,substring,sizeof(string));
	}
	foreach(new p : GroupMember(PlayerSquad[playerid]))
	{
	    if(p == playerid) continue;
		GetPlayerName(p,substring,sizeof(substring));
		format(substring,sizeof(substring),"{00ff00}%s\n",substring);
		strcat(string,substring,sizeof(string));
	}
	ShowPlayerDialog(playerid,123,DIALOG_STYLE_LIST,"Spawn",string,"Spawn","Select Class");
	return 1;
}
public OnPlayerRequestSpawn(playerid)
{
	ShowSpawnDialog(playerid);
	return 0;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
	    case 123:
	    {
	        if(response)
	        {
		        if(listitem == 0)
		        {
		            SetPlayerVirtualWorld(playerid,0);
		            SpawnPlayer(playerid);
		        }
		        else if(6 > listitem > 0)
		        {
		            new point = (listitem-1);
		            if(PointInfo[point][CapturedBy] == PlayerGroup[playerid])
		            {
		                SetPlayerVirtualWorld(playerid,0);
		                SpawnPlayer(playerid);
		                SetPlayerPos(playerid,PointSpawns[point][0],PointSpawns[point][1],PointSpawns[point][2]);
					}
					else ShowSpawnDialog(playerid);
		        }
		        else
		        {
		            new idx = 0;
		            foreach(new p : GroupMember(PlayerSquad[playerid]))
					{
					    if(p == playerid) continue;
					    if((listitem-6) == idx)
					    {
					        if(GetPlayerState(p) == PLAYER_STATE_ONFOOT)
					        {
					            new Float:cPos[4];
					            GetPlayerPos(p,cPos[0],cPos[1],cPos[2]);
					            GetPlayerFacingAngle(p,cPos[3]);
					            GetXYBehindPoint(cPos[0],cPos[1],cPos[0],cPos[1],cPos[3],1.5);
					            
					            SetPlayerVirtualWorld(playerid,0);
				                SpawnPlayer(playerid);
				                SetPlayerPos(playerid,cPos[0],cPos[1],cPos[2]);
				                SetPlayerFacingAngle(playerid,cPos[3]);
				                return 1;
					        }
					        else if(GetPlayerState(p) == PLAYER_STATE_DRIVER || GetPlayerState(p) == PLAYER_STATE_PASSENGER)
					        {
					            new vehid = GetPlayerVehicleID(p);
	            				new maxslot = 4;
								if(GetVehicleModel(vehid) == 469) maxslot = 2;
								else if(GetVehicleModel(vehid) == 433) maxslot = 2;
								new bool:slot[8] = {false,false,false,false,false,false,false,false};
								for(new i = 0; i < maxslot; i++)
								{
								    slot[i] = true;
								}
								foreach(new i : Player)
								{
								    if(GetPlayerVehicleID(i) != vehid) continue;
									slot[GetPlayerVehicleSeat(i)] = false;
								}
								for(new i = 0; i < maxslot; i++)
								{
								    if(slot[i])
								    {
								        SetPlayerVirtualWorld(playerid,0);
             							SpawnPlayer(playerid);
								        SetPlayerArmedWeapon(playerid,0);
								        PutPlayerInVehicle(playerid,vehid,i);
								        return 1;
								    }
								}
					        }
					        ShowSpawnDialog(playerid);
					        break;
					    }
					    idx++;
					}
		        }
			}
	    }
	}
	return 1;
}
public OnPlayerSpawn(playerid)
{
	AttachDynamicAreaToPlayer(PlayerArea[playerid],playerid);
	for(new i = 0; i < 5; i++)
	{
		if(PointInfo[i][CapturedBy] ==  INVALID_GROUP)
		{
		    GangZoneShowForPlayer(playerid,PointInfo[i][Zone],0xFFFFFFFF);
			SetPlayerMapIcon(playerid,i,PointSpawns[i][0],PointSpawns[i][1],PointSpawns[i][2],19,0xFFFFFFFF,MAPICON_GLOBAL);
		}
		else if(Group_GetPlayer(PointInfo[i][CapturedBy],playerid))
		{
		    GangZoneShowForPlayer(playerid,PointInfo[i][Zone],COLOR_ALLY);
		    SetPlayerMapIcon(playerid,i,PointSpawns[i][0],PointSpawns[i][1],PointSpawns[i][2],30,COLOR_ALLY,MAPICON_GLOBAL);
		}
		else
		{
		    GangZoneShowForPlayer(playerid,PointInfo[i][Zone],COLOR_ENEMY | 0xFF);
		    SetPlayerMapIcon(playerid,i,PointSpawns[i][0],PointSpawns[i][1],PointSpawns[i][2],20,COLOR_ENEMY | 0xFF,MAPICON_GLOBAL);
		}
	}
	if(PlayerGroup[playerid] == America)
	{
	    SetPlayerTeam(playerid,1);
		SetPlayerWorldBounds(playerid,517.0,-1120.0,311.0,-766.0);
		for(new i = 0; i < 4; i++)
		{
			GangZoneShowForPlayer(playerid,AmericaBounds[i],0xFF0000AA);
		}
	}
	else if(PlayerGroup[playerid] == Russia)
	{
	    SetPlayerTeam(playerid,2);
	    SetPlayerWorldBounds(playerid,675.0,-962.0,460.0,-645.0);
	    for(new i = 0; i < 4; i++)
		{
			GangZoneShowForPlayer(playerid,RussiaBounds[i],0xFF0000AA);
		}
	}
	
	foreach(new i : Player)
	{
	    if(i == playerid)
	    {
            SetPlayerMarkerForPlayer(playerid,playerid,COLOR_SQUAD);
	    }
		else if(PlayerGroup[playerid] == PlayerGroup[i])
		{
		    if(PlayerSquad[playerid] == PlayerSquad[i])
		    {
		        SetPlayerMarkerForPlayer(playerid,i,COLOR_SQUAD);
		    	ShowPlayerNameTagForPlayer(playerid,i,true);
				SetPlayerMarkerForPlayer(i,playerid,COLOR_SQUAD);
				ShowPlayerNameTagForPlayer(i,playerid,true);
		    }
		    else
		    {
		    	SetPlayerMarkerForPlayer(playerid,i,COLOR_ALLY);
		    	ShowPlayerNameTagForPlayer(playerid,i,true);
				SetPlayerMarkerForPlayer(i,playerid,COLOR_ALLY);
				ShowPlayerNameTagForPlayer(i,playerid,true);
			}
		}
		else
		{
			SetPlayerMarkerForPlayer(playerid,i,COLOR_ENEMY);
			ShowPlayerNameTagForPlayer(playerid,i,false);
			SetPlayerMarkerForPlayer(i,playerid,COLOR_ENEMY);
			ShowPlayerNameTagForPlayer(i,playerid,false);
		}
	}
	
	return 1;
}
public OnPlayerEnterDynamicArea(playerid,areaid)
{
	return 1;
}
public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	new maxslot = 4;
	if(GetVehicleModel(vehicleid) == 469) maxslot = 2;
	else if(GetVehicleModel(vehicleid) == 433) maxslot = 8;
	new bool:slot[8] = {false,false,false,false,false,false,false,false};
	for(new i = 0; i < maxslot; i++)
	{
	    slot[i] = true;
	}
	foreach(new p : Player)
	{
	    if(GetPlayerVehicleID(p) != vehicleid) continue;
		slot[GetPlayerVehicleSeat(p)] = false;
	}
	for(new i = ispassenger; i < maxslot; i++)
	{
	    if(slot[i])
	    {
	        SetPlayerArmedWeapon(playerid,0);
	        PutPlayerInVehicle(playerid,vehicleid,i);
	        return 1;
	    }
	}
	TogglePlayerControllable(playerid,1);
	return 1;
}
public OnPlayerExitVehicle(playerid,vehicleid)
{
	new Float:cPos[4];
	if(GetVehicleModel(vehicleid) == 469) GivePlayerWeapon(playerid,46,1);
	GetVehiclePos(vehicleid,cPos[0],cPos[1],cPos[2]);
	GetVehicleZAngle(vehicleid,cPos[3]);
	GetXYRightOfPoint(cPos[0],cPos[1],cPos[0],cPos[1],cPos[3],2.0);
	SetPlayerPos(playerid,cPos[0],cPos[1],cPos[2]);
	SetPlayerFacingAngle(playerid,cPos[3]);
	return 1;
}
public OnPlayerDeath(playerid,killerid,reason)
{
	new Float:cPos[3];
	GetPlayerPos(playerid,cPos[0],cPos[1],cPos[2]);
	SendDeathMessage(killerid,playerid,reason);
	TogglePlayerSpectating(playerid,1);
	if(killerid != INVALID_PLAYER_ID)
	{
	    PlayerSpectatePlayer(playerid,killerid,SPECTATE_MODE_FIXED);
	    SetPlayerCameraPos(playerid,cPos[0],cPos[1],cPos[2]);
	    if(PlayerGroup[playerid] != PlayerGroup[killerid])
	    {
	        SetPlayerScore(killerid,GetPlayerScore(killerid)+1);
	        if(PlayerGroup[killerid] == America)
	        {
	            AmericaScore++;
	            if(AmericaScore == 50)
	            {
	                GameStarted = false;
	                foreach(new p : Player)
	                {
	                    TogglePlayerSpectating(p,1);
	                    PlayAudioStreamForPlayer(p,"http://bit.ly/SWPZfN");
	                }
	                GameTextForAll("America Wins",10000,1);
	                defer RestartMode();
	            }
	        }
	        else
	        {
	            RussiaScore++;
	            if(RussiaScore == 50)
	            {
	                GameStarted = false;
	                foreach(new p : Player)
	                {
	                    TogglePlayerSpectating(p,1);
	                    PlayAudioStreamForPlayer(p,"http://bit.ly/R5vIGY");
	                }
	                GameTextForAll("Russia Wins",10000,1);
	                defer RestartMode();
	            }
	        }
	    }
	}
	else
	{
	    SetPlayerCameraPos(playerid,cPos[0],cPos[1],cPos[2]+20.0);
	    SetPlayerCameraLookAt(playerid,cPos[0],cPos[1],cPos[2]);
	}
	if(GameStarted)
	{
		defer RespawnTimer(playerid);
	}
	return 1;
}

timer RespawnTimer[5000](playerid)
{
    TogglePlayerSpectating(playerid,0);
	Class_ForceReselection(playerid);
	return 1;
}
timer RestartMode[5000]()
{
	GameModeExit();
	return 1;
}
task PointTimer[1000]()
{
	new string[128];
	for(new i = 0; i < 5; i++)
	{
	    new points = 0;
	    foreach(new p : GroupMember(America))
	    {
	        if(IsPlayerInDynamicArea(p,PointInfo[i][Area]))
	        {
	        	points += 5;
			}
	    }
	    foreach(new p : GroupMember(Russia))
	    {
	        if(IsPlayerInDynamicArea(p,PointInfo[i][Area]))
	        {
	        	points -= 5;
			}
	    }
	    if(points != 0)
	    {
	        PointInfo[i][CapturePoint] += points;
	        if(PointInfo[i][CapturePoint] >= 100)
	        {
	            PointInfo[i][CapturePoint] = 100;
	            if(PointInfo[i][CapturedBy] != America)
	            {
	                format(string,sizeof(string),"Point %c\n%s\n[||||||||||]",'A'+i,Group_GetName(America));
	            	UpdateDynamic3DTextLabelText(PointInfo[i][Label],0xFFFFFFFF,string);
	                PointInfo[i][CapturedBy] = America;
	                foreach(new p : Player)
	                {
	                    if(Group_GetPlayer(America,p))
	                    {
							GangZoneHideForPlayer(p,PointInfo[i][Zone]);
							GangZoneShowForPlayer(p,PointInfo[i][Zone],COLOR_ALLY);
							SetPlayerMapIcon(p,i,PointSpawns[i][0],PointSpawns[i][1],PointSpawns[i][2],30,COLOR_ALLY,MAPICON_GLOBAL);
	                    }
	                    else
	                    {
	                        GangZoneHideForPlayer(p,PointInfo[i][Zone]);
							GangZoneShowForPlayer(p,PointInfo[i][Zone],COLOR_ENEMY | 0xFF);
							SetPlayerMapIcon(p,i,PointSpawns[i][0],PointSpawns[i][1],PointSpawns[i][2],20,COLOR_ENEMY | 0xFF,MAPICON_GLOBAL);
	                    }
						PlayerPlaySound(p,1057,0.0,0.0,0.0);
	                }
					for(new v = 0; v < 3; v++)
					{
					    SetVehicleVirtualWorld(PointInfo[i][Vehicle][v],0);
					}
					format(string,sizeof(string),"HQ: {00ff00}Our team {ffffff}has captured {ffff00}point %c",'A'+i);
					SendGroupMessage(America,0x00FFFFFF,string);
					format(string,sizeof(string),"HQ: {ff0000}Enemy team {ffffff}has captured {ffff00}point %c",'A'+i);
					SendGroupMessage(Russia,0x00FFFFFF,string);
	            }
	        }
	        else if(PointInfo[i][CapturePoint] <= -100)
	        {
	            PointInfo[i][CapturePoint] = -100;
	            if(PointInfo[i][CapturedBy] != Russia)
	            {
	                format(string,sizeof(string),"Point %c\n%s\n[||||||||||]",'A'+i,Group_GetName(Russia));
	            	UpdateDynamic3DTextLabelText(PointInfo[i][Label],0xFFFFFFFF,string);
                    PointInfo[i][CapturedBy] = Russia;
                    foreach(new p : Player)
	                {
	                    if(Group_GetPlayer(Russia,p))
	                    {
							GangZoneHideForPlayer(p,PointInfo[i][Zone]);
							GangZoneShowForPlayer(p,PointInfo[i][Zone],COLOR_ALLY);
							SetPlayerMapIcon(p,i,PointSpawns[i][0],PointSpawns[i][1],PointSpawns[i][2],30,COLOR_ALLY,MAPICON_GLOBAL);
	                    }
	                    else
	                    {
	                        GangZoneHideForPlayer(p,PointInfo[i][Zone]);
							GangZoneShowForPlayer(p,PointInfo[i][Zone],COLOR_ENEMY | 0xFF);
							SetPlayerMapIcon(p,i,PointSpawns[i][0],PointSpawns[i][1],PointSpawns[i][2],20,COLOR_ENEMY | 0xFF,MAPICON_GLOBAL);
	                    }
	                    PlayerPlaySound(p,1057,0.0,0.0,0.0);
	                }
	                format(string,sizeof(string),"HQ: {00ff00}Our team {ffffff}has captured {ffff00}point %c",'A'+i);
					SendGroupMessage(Russia,0x00FFFFFF,string);
					format(string,sizeof(string),"HQ: {ff0000}Enemy team {ffffff}has captured {ffff00}point %c",'A'+i);
					SendGroupMessage(America,0x00FFFFFF,string);
	            }
	        }
	        else if((PointInfo[i][CapturePoint] >= 0) && (PointInfo[i][CapturedBy] == Russia))
	        {
	            PointInfo[i][CapturedBy] = INVALID_GROUP;
	            format(string,sizeof(string),"Point %c\nNone\n[          ]",'A'+i);
	            UpdateDynamic3DTextLabelText(PointInfo[i][Label],0xFFFFFFFF,string);
	            foreach(new p : Player)
	            {
	                if(Group_GetPlayer(America,p))
                    {
						GangZoneFlashForPlayer(p,PointInfo[i][Zone],COLOR_ALLY);
                    }
                    else
                    {
						GangZoneFlashForPlayer(p,PointInfo[i][Zone],COLOR_ENEMY | 0xFF);
                    }
                    SetPlayerMapIcon(p,i,PointSpawns[i][0],PointSpawns[i][1],PointSpawns[i][2],19,0xFFFFFFFF,MAPICON_GLOBAL);
                    if(IsPlayerInDynamicArea(p,PointInfo[i][Area]))
		            {
		                PlayerPlaySound(p,1056,0.0,0.0,0.0);
		            }
	            }
	            format(string,sizeof(string),"HQ: We have lost {ffff00}point %c",'A'+i);
				SendGroupMessage(Russia,0x00FFFFFF,string);
	        }
	        else if((PointInfo[i][CapturePoint] <= 0) && (PointInfo[i][CapturedBy] == America))
	        {
	            PointInfo[i][CapturedBy] = INVALID_GROUP;
	            format(string,sizeof(string),"Point %c\nNone\n[          ]",'A'+i);
	            UpdateDynamic3DTextLabelText(PointInfo[i][Label],0xFFFFFFFF,string);
	            foreach(new p : Player)
	            {
	                if(Group_GetPlayer(Russia,p))
                    {
						GangZoneFlashForPlayer(p,PointInfo[i][Zone],COLOR_ALLY);
                    }
                    else
                    {
						GangZoneFlashForPlayer(p,PointInfo[i][Zone],COLOR_ENEMY | 0xFF);
                    }
                    SetPlayerMapIcon(p,i,PointSpawns[i][0],PointSpawns[i][1],PointSpawns[i][2],19,0xFFFFFFFF,MAPICON_GLOBAL);
                    if(IsPlayerInDynamicArea(p,PointInfo[i][Area]))
		            {
		                PlayerPlaySound(p,1056,0.0,0.0,0.0);
		            }
	            }
	            format(string,sizeof(string),"HQ: We have lost {ffff00}point %c",'A'+i);
				SendGroupMessage(America,0x00FFFFFF,string);
	        }
	        else
	        {
	            new view = (abs(PointInfo[i][CapturePoint])/10);
				if(PointInfo[i][CapturedBy] == INVALID_GROUP)
				{
				    format(string,sizeof(string),"Point %c\nNone\n[",'A'+i);
				}
				else
				{
				    format(string,sizeof(string),"Point %c\n%s\n[",'A'+i,Group_GetName(PointInfo[i][CapturedBy]));
				}
				for(new x = 0; x < 10; x++)
			    {
			        if(view != 0)
			        {
			            strcat(string,"|",sizeof(string));
			            view--;
			        }
			        else strcat(string," ",sizeof(string));
			    }
			    strcat(string,"]",sizeof(string));
			    UpdateDynamic3DTextLabelText(PointInfo[i][Label],0xFFFFFFFF,string);
	            foreach(new p : Player)
	            {
	            	if(IsPlayerInDynamicArea(p,PointInfo[i][Area]))
	            	{
	            	    PlayerPlaySound(p,1056,0.0,0.0,0.0);
	            	}
				}
	        }
	    }
	}
	return 1;
}
ptask PlayerTimer[1000](playerid)
{
	new target = GetPlayerTargetPlayer(playerid);
	if(target != INVALID_PLAYER_ID)
	{
	    if(!Group_GetPlayer(PlayerGroup[playerid],target))
	    {
			if(Spotted[target] == 0)
			{
	        	foreach(new i : GroupMember(PlayerGroup[playerid]))
	        	{
	        	    SetPlayerMarkerForPlayer(i,target,COLOR_ENEMY | 0xFF);
	        	    ShowPlayerNameTagForPlayer(i,target,true);
	        	    Spotted[target] = 5;
	        	}
			}
			else
			{
			    Spotted[target] = 5;
			}
	    }
	}
	if(Spotted[playerid] > 0)
	{
	    Spotted[playerid]--;
	    if(Spotted[playerid] == 0)
	    {
	        foreach(new i : Player)
	        {
	            if(!Group_GetPlayer(PlayerGroup[playerid],i))
				{
					SetPlayerMarkerForPlayer(i,playerid,COLOR_ENEMY);
					ShowPlayerNameTagForPlayer(i,playerid,false);
				}
	        }
	    }
	}
	return 1;
}
