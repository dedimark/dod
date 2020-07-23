//
// SourceMod Script
//
// Developed by <eVa>Dog
// June 2008
// http://www.theville.org
//

//
// DESCRIPTION:
// For Day of Defeat Source only
// Swaps Allies and Axis Teams at Round End
// Additional round code added by Psychocoder
// Additional round code added by Ben'

//
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.600"

new Handle:g_Cvar_BonusRound = INVALID_HANDLE;
new Handle:g_Cvar_Swapteams = INVALID_HANDLE;
new Handle:g_Cvar_Swapscore = INVALID_HANDLE;

new g_teamchange;
new g_rounds;
new teamrw[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "DoDS Swapteams",
	author = "<eVa>Dog",
	description = "Swap teams at round end for Day of Defeat Source",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_dod_swapteams_version", PLUGIN_VERSION, "Version of sm_dod_swapteams", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_Swapteams = CreateConVar("sm_dod_swapteams", "2", "Enables/Disables sm_dod_swapteams  <0 to disable | # of rounds>", FCVAR_PLUGIN);
	g_Cvar_Swapscore  = CreateConVar("sm_dod_swapscore", "1",  "Enable/disable swap teamscore  <0 to disable | 1 enable>",FCVAR_PLUGIN);
	g_Cvar_BonusRound = FindConVar("dod_bonusroundtime");
	
	HookEvent("dod_round_win", PlayerRoundWinEvent);
	HookEvent("player_team", ChangeTeam, EventHookMode_Pre);
	RegAdminCmd("swapteam", Cmd_Swapteam, ADMFLAG_SLAY, "swapteam");
}

public OnEventShutdown()
{
	UnhookEvent("dod_round_win", PlayerRoundWinEvent);
	UnhookEvent("player_team", ChangeTeam, EventHookMode_Pre);
}

public PlayerRoundWinEvent(Handle:event, const String:name[], bool:dontBroadcast) 
{
	g_rounds+=1;
	new plugin_rounds=GetConVarInt(g_Cvar_Swapteams); 
	if(plugin_rounds != 0)
	{ 
		//Added by psychocoder
		if (plugin_rounds==g_rounds) 
		{ 
			new Float:delay = float(GetConVarInt(g_Cvar_BonusRound)); 
			g_rounds=0; 
			if (delay > 0) 
			{ 
				CreateTimer(delay, DelayedSwitch, 0, 0); 
			}
			else
			{ 
                ChangeTeams(); 
            }
				
			//Added by Ben'
			if (GetConVarInt(g_Cvar_Swapscore))
			{
				PrintToChatAll("\x01\x04[SM] \x05Teams and Teamscore \x04will be swapped in %i seconds", GetConVarInt(g_Cvar_BonusRound));
				new max_entities = GetMaxEntities();
				for (new entity_index = 0; (entity_index < max_entities); entity_index++) {
					if (IsValidEntity(entity_index)) {

						new String: entity_classname[64];
						GetEntityNetClass(entity_index, entity_classname, 64);

						if ((strcmp(entity_classname, "CDODTeam_Allies") == 0) || (strcmp(entity_classname, "CDODTeam_Axis") == 0)) {
							new team_index;
							new index_offset = FindSendPropOffs(entity_classname, "m_iTeamNum");				
							team_index = GetEntData(entity_index, index_offset);
							
							new team_rw;
							new rw_offset = FindSendPropOffs(entity_classname, "m_iRoundsWon");				
							team_rw = GetEntData(entity_index, rw_offset);
							
							if (team_rw != 0) {
								teamrw[team_index] = team_rw;
							}
						}
					}
				}
				CreateTimer(delay, Swap_Score, _, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
				PrintToChatAll("\x01\x04[SM] Teams will be swapped in %i seconds", GetConVarInt(g_Cvar_BonusRound));
			
			
        }
		else
		{
            PrintToChatAll("\x01\x04[SM] Teams will be swapped in %i round(s)", plugin_rounds-g_rounds);
        }
    } 
}

public Action:Cmd_Swapteam(client,args)
{
	new max_entities = GetMaxEntities();
	for (new entity_index = 0; (entity_index < max_entities); entity_index++) {
		if (IsValidEntity(entity_index)) {

			new String: entity_classname[64];
			GetEntityNetClass(entity_index, entity_classname, 64);

			if ((strcmp(entity_classname, "CDODTeam_Allies") == 0) || (strcmp(entity_classname, "CDODTeam_Axis") == 0)) {
				new team_index;
				new index_offset = FindSendPropOffs(entity_classname, "m_iTeamNum");				
				team_index = GetEntData(entity_index, index_offset);
				
				new team_rw;
				new rw_offset = FindSendPropOffs(entity_classname, "m_iRoundsWon");				
				team_rw = GetEntData(entity_index, rw_offset);
				
				if (team_rw != 0) {
					teamrw[team_index] = team_rw;
				}
			}
		}
	}
	
	CreateTimer(0.1, Swap_Score, _, TIMER_FLAG_NO_MAPCHANGE);

	ChangeTeams(); 
	return Plugin_Handled;
}

public Action:Swap_Score (Handle:timer) 
{
	new max_entities = GetMaxEntities();
	for (new entity_index = 0; (entity_index < max_entities); entity_index++) {
		if (IsValidEntity(entity_index)) {

			new String: entity_classname[64];
			GetEntityNetClass(entity_index, entity_classname, 64);

			if ((strcmp(entity_classname, "CDODTeam_Allies") == 0)) {
				new rw_offsetal = FindSendPropOffs(entity_classname, "m_iRoundsWon");	
				SetEntData(entity_index, rw_offsetal, teamrw[3], 4, true);					
			}
			if ((strcmp(entity_classname, "CDODTeam_Axis") == 0)) {
				new rw_offsetax = FindSendPropOffs(entity_classname, "m_iRoundsWon");					
				SetEntData(entity_index, rw_offsetax, teamrw[2], 4, true);					
			}
		}
	}
}


public Action:ChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_teamchange == 1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:DelayedSwitch(Handle:timer)
{
	ChangeTeams();
}

public Action:ChangeTeams()
{
	g_teamchange = 1;
	SetConVarInt(FindConVar("mp_limitteams"), 20);
	
	for (new client=1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && (GetClientTeam(client) == 2))
		{
			ChangeClientTeam(client, 1);
			ChangeClientTeam(client, 3);
			ShowVGUIPanel(client, "class_ger", INVALID_HANDLE, false);
		}
		else if (IsClientInGame(client) && (GetClientTeam(client) == 3))
		{
			ChangeClientTeam(client, 1);
			ChangeClientTeam(client, 2);
			ShowVGUIPanel(client, "class_us", INVALID_HANDLE, false);
		}
	}
	
	SetConVarInt(FindConVar("mp_limitteams"), 1);
	g_teamchange = 0;
			
	return Plugin_Handled;
}