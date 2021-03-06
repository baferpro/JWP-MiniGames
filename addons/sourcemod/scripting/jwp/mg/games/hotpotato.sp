int g_iLastPotatoClient;
int g_iEntityPotato;
float g_flPotatoSpeed;

void ProcessHotPotato()
{
    g_iLastPotatoClient = -1;
    g_iEntityPotato = -1;
    if (g_iWaitTimerT < 10)
        g_iWaitTimerT = 10;
    // Disable damage on all alive players
    g_CvarIgnoreWinRound.SetBool(true, false, false);
    g_flPotatoSpeed = g_KvConfig.GetFloat("potato_speed", 1.0);
    if (g_flPotatoSpeed < 1.0) g_flPotatoSpeed = 1.0;
    
    g_hTerTimer = CreateTimer(1.0, Timer_ProcessHotPotatoStart, _, TIMER_REPEAT);
}

public Action Timer_ProcessHotPotatoStart(Handle timer)
{
    int pl_count = 0;
    if (--g_iWaitTimerT > 0)
    {
        for (int i = 1; i <= MaxClients; ++i)
        {
            if (IsValidClient(i, _, false))
                pl_count++;
        }
        
        if (pl_count < 2)
        {
            PrintCenterTextAll("%t", "JWP_MG_NO_START");
            CS_TerminateRound(1.0, CSRoundEnd_Draw);
            
            g_hTerTimer = null;
            return Plugin_Stop;
        }
        
        PrintCenterTextAll("%t", "JWP_MG_START_TIME", g_iWaitTimerT);
        return Plugin_Continue;
    }
    
    for (int i = 1; i <= MaxClients; ++i)
    {
        if (IsValidClient(i, _, false))
        {
            RemoveAllWeapons(i);
        }
    }
    
    g_iLastPotatoClient = JWP_GetRandomTeamClient(-1, true);
    g_iEntityPotato = GiveWpn(g_iLastPotatoClient, "weapon_deagle", 0, 0);
    float fTime = g_KvConfig.GetFloat("timer_wait_ct", 20.0);
    char sName[MAX_NAME_LENGTH];
    GetClientName(g_iLastPotatoClient, sName, sizeof(sName));
    CPrintToChatAll("%t%t", "JWP_MG_PREFIX", "JWP_MG_POTATO_HOLD", sName);
    if (fTime < 1.0) fTime = 1.0;
    g_hCtTimer = CreateTimer(fTime, FindNewEnemyTimer_Callback, _, TIMER_REPEAT);
    
    g_hTerTimer = null;
    return Plugin_Stop;
}

public Action FindNewEnemyTimer_Callback(Handle timer)
{
    int alive;
    int iLastalive;
    for (int i = 1; i <= MaxClients; ++i)
    {
        if (IsValidClient(i, _, false))
        {
            alive++;
            iLastalive = i;
        }
    }
    
    // Win condition
    if (alive == 1)
    {
        char sName[MAX_NAME_LENGTH];
        GetClientName(iLastalive, sName, sizeof(sName));
        CPrintToChatAll("%t%t", "JWP_MG_PREFIX", "JWP_MG_POTATO_WIN", sName);
        int iTeam = GetClientTeam(iLastalive);
        if (iTeam == CS_TEAM_T)
            CS_TerminateRound(1.0, CSRoundEnd_TerroristWin);
        else
            CS_TerminateRound(1.0, CSRoundEnd_CTWin);
    }
    else if (alive < 1)
    {
        if (g_hCtTimer != null)
            delete g_hCtTimer;
        if (g_hTerTimer != null)
            delete g_hTerTimer;
        CS_TerminateRound(1.0, CSRoundEnd_Draw);
    }
    else
    {
        // kill last potato client and start game again
        if (g_iLastPotatoClient > 0 && IsValidClient(g_iLastPotatoClient))
        {
            if (IsValidEntity(g_iEntityPotato) && RemovePlayerItem(g_iLastPotatoClient, g_iEntityPotato))
                g_iEntityPotato = -1;
            ForcePlayerSuicide(g_iLastPotatoClient);
            char sName[MAX_NAME_LENGTH];
            GetClientName(g_iLastPotatoClient, sName, sizeof(sName));
            CPrintToChatAll("%t%t", "JWP_MG_PREFIX", "JWP_MG_POTATO_LAST_DEAD", sName);
        }
        if (IsValidEntity(g_iEntityPotato))
            AcceptEntityInput(g_iEntityPotato, "Kill");
        
        g_iLastPotatoClient = JWP_GetRandomTeamClient(-1, true);
        g_iEntityPotato = GiveWpn(g_iLastPotatoClient, "weapon_deagle", 0, 0);
        CPrintToChat(g_iLastPotatoClient, "%t%t", "JWP_MG_PREFIX", "JWP_MG_POTATO_THROWN_2");
        
        return Plugin_Continue;
    }
    
    g_hCtTimer = null;
    return Plugin_Stop;
}