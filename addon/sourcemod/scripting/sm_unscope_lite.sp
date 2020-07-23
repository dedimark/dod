//
// SourceMod Script
//
// Developed by Misery
// DECEMBER 2008
// http://thelw.forum-actif.net
//
// CHANGELOG :
// - 21.12.2008 Version 1.4
// - Enable/disable DoD:S Unscope sound for the Attacker
//
// - 23.12.2008 Version 1.5
// - Fix bug with GetClientName when Client is not connected
//
// - 26.05.2009 Version 1.6.0
// - Notify clients which are informed about UNSCOPE
//
// - 02.06.2009 Version 1.6.1
// - Fix bug, add second and thirst BEST UNSCOPED SNIPER
//
// - 10.06.2009 Version 1.6.2
// - New list for show score
//
// - 12.06.2009 Version 1.6.3
// - Fix small bug
//
// - 13.06.2009 Version 1.6.4
// - Fix bug with GetClientName when Client is not connected
//
// - 15.06.2009 Version 1.6.5
// - Fix small bug with GetClientName in loop
//
// - 27.01.2010 Version 1.6.6 by n0n
// - Simplyfied Plugin again to play only a sound and to be useable for working with HLstats:CE and this: 
// - http://forums.alliedmods.net/showthread.php?p=834440
// - Menu is killed now
//
// - 03.02.2011 Version 1.6.7 Lite by n0n
// - deleted Info on respawn
// - Did some grammar fixes to the Prints ^^

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.6.7 Lite"

public Plugin:myinfo = 
{
	name = "UNSCOPED LITE",
	author = "Misery, Lite by n0n",
	description = "MOD Unscoped sniper for DoD:S",
	version = PLUGIN_VERSION,
	url = "http://www.ocb-bastards.de"
};

new Handle:Cvar_unscope_Enable
new Handle:Cvar_unscope_Attacker_Enable

new UnscopeCount[64]

public OnPluginStart()
{
        CreateConVar("sm_dod_unscope_version", PLUGIN_VERSION, "DoD:S rules for MG Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)

	Cvar_unscope_Enable = CreateConVar("sm_dod_unscope_enable", "1", "Enable/disable DoD:S Unscope Mod", FCVAR_PLUGIN)
	Cvar_unscope_Attacker_Enable = CreateConVar("sm_dod_unscope_attacker_enable", "1", "Enable/disable DoD:S Unscope sound for the Attacker", FCVAR_PLUGIN)
			
	HookEvent("dod_stats_player_damage", PlayerDamageEvent)
	
}

public OnEventShutdown()
{
	UnhookEvent("dod_stats_player_damage", PlayerDamageEvent)
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/unscope/unstoppable.mp3")
	AddFileToDownloadsTable("sound/unscope/fall_1.mp3")
	AddFileToDownloadsTable("sound/unscope/perfect.mp3")

	PrecacheSound("unscope/unstoppable.mp3", true)	
	PrecacheSound("unscope/fall_1.mp3", true)
	PrecacheSound("unscope/perfect.mp3", true)	
}

public PlayerDamageEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	
	if (attacker == 0 || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || IsFakeClient(attacker))
	{
		return
	}
	
	if (GetConVarInt(Cvar_unscope_Enable) == 1 && client != 0 && !IsFakeClient(client))
	{
		new weapon_pos = GetEventInt(event, "weapon")
		
		switch (weapon_pos)
		{
			case 9,10:
			{
				if (GetClientHealth(client) < 1)
				{
      					new hitgroup = GetEventInt(event, "hitgroup")

         				new String:attacker_name[64]
         				GetClientName(attacker, attacker_name, 64)
      		
      					// Hitgroups
      					// 1 = Head
      					
					if (hitgroup == 1)
					{
         					if (attacker == 0 || !IsPlayerAlive(attacker))
         					{
            						return
         					}
						
						UnscopeCount[attacker] = UnscopeCount[attacker] + 1
						
						EmitSoundToClient(client, "unscope/unstoppable.mp3")
               					PrintToChat(client, "\x01\x04[UNSCOPE]\x01 %s killed you with an unscope in your head", attacker_name)

						if (GetConVarInt(Cvar_unscope_Attacker_Enable) == 1 && attacker != 0 && IsClientInGame(attacker) && IsPlayerAlive(attacker))
						{
         						new String:victim_name[64]
         						GetClientName(client, victim_name, 64)

							EmitSoundToClient(attacker, "unscope/perfect.mp3")

							if (client != 0 && IsClientInGame(client))
							{
               							PrintToChat(attacker, "\x01\x04[UNSCOPE]\x01 You killed \x01\x04%s\x01 with an unscope in his head", victim_name)
							}
						}
					}
					else
					{
         					if (attacker == 0 || !IsPlayerAlive(attacker))
         					{
            						return
         					}
						
						UnscopeCount[attacker] = UnscopeCount[attacker] + 1

						if (client != 0 || IsClientInGame(client))
						{
							EmitSoundToClient(client, "unscope/unstoppable.mp3")
               						PrintToChat(client, "\x01\x04[UNSCOPE]\x01 %s killed you with an unscope", attacker_name)
						}

						if (GetConVarInt(Cvar_unscope_Attacker_Enable) == 1 && attacker != 0 && IsClientInGame(attacker) && IsPlayerAlive(attacker))
						{
         						new String:victim_name[64]
         						GetClientName(client, victim_name, 64)

							EmitSoundToClient(attacker, "unscope/perfect.mp3")

							if (client != 0 && IsClientInGame(client))
							{
               							PrintToChat(attacker, "\x01\x04[UNSCOPE]\x01 You killed \x01\x04%s\x01 with an unscope", victim_name)
							}
						}
					}
				}
				else
				{
         				if (client == 0 || !IsPlayerAlive(client))
         				{
            					return
         				}
					else
					{
						if (GetClientHealth(client) >= 1 && GetClientHealth(client) < 100)
						{
         						if (attacker == 0 || !IsClientInGame(attacker) || !IsPlayerAlive(attacker))
         						{
            							return
         						}
							
         						new String:attacker_name[64]
         						GetClientName(attacker, attacker_name, 64)

							EmitSoundToClient(client, "unscope/fall_1.mp3")
							PrintToChat(client, "\x01\x04[UNSCOPE]\x01 %s hurt you with an unscope", attacker_name)

							if (GetConVarInt(Cvar_unscope_Attacker_Enable) == 1 && attacker != 0 && IsClientInGame(attacker) && IsPlayerAlive(attacker))
							{
         							new String:victim_name[64]
         							GetClientName(client, victim_name, 64)

								EmitSoundToClient(attacker, "unscope/perfect.mp3")

								if (client != 0 && IsClientInGame(client))
								{
               								PrintToChat(attacker, "\x01\x04[UNSCOPE]\x01 You hurt \x01\x04%s\x01 with an unscope", victim_name)
								}
							}
						}
					}
				}
			}
		}	
	}
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	/* Do nothing */
}