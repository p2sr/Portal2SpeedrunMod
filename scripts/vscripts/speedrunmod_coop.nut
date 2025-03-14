//-----------------------------------------------------------------------------
// Purpose: Coop Speedrun Mod VScript
// Author:  Nanoman2525
// Notes:   This script must be executed upon map loading to function
//          correctly, specifically after mapspawn.nut. Running the script
//          prematurely, before entities are initialized, may result in errors.
//          The script has been developed through a server plugin utilizing the
//          the call to ServerActivate defined in IServerPluginCallbacks.
//-----------------------------------------------------------------------------

if ( !( "Entities" in this ) )
{
    return; // This is the primary method for determining whether the environment is a client VM.
}

//-----------------------------------------------------------------------------
// Purpose: Attempt to figure out if we are on a native CO-OP puzzle map.
//-----------------------------------------------------------------------------
local pszMaps =
[
    // Release
    "mp_coop_start", "mp_coop_lobby_2",
    "mp_coop_doors", "mp_coop_race_2", "mp_coop_laser_2", "mp_coop_rat_maze", "mp_coop_laser_crusher", "mp_coop_teambts",
    "mp_coop_fling_3", "mp_coop_infinifling_train", "mp_coop_come_along", "mp_coop_fling_1", "mp_coop_catapult_1", "mp_coop_multifling_1", "mp_coop_fling_crushers", "mp_coop_fan",
    "mp_coop_wall_intro", "mp_coop_wall_2", "mp_coop_catapult_wall_intro", "mp_coop_wall_block", "mp_coop_catapult_2", "mp_coop_turret_walls", "mp_coop_turret_ball", "mp_coop_wall_5",
    "mp_coop_tbeam_redirect", "mp_coop_tbeam_drill", "mp_coop_tbeam_catch_grind_1", "mp_coop_tbeam_laser_1", "mp_coop_tbeam_polarity", "mp_coop_tbeam_polarity2", "mp_coop_tbeam_polarity3", "mp_coop_tbeam_maze", "mp_coop_tbeam_end",
    "mp_coop_paint_come_along", "mp_coop_paint_redirect", "mp_coop_paint_bridge", "mp_coop_paint_walljumps", "mp_coop_paint_speed_fling", "mp_coop_paint_red_racer", "mp_coop_paint_speed_catch", "mp_coop_paint_longjump_intro",
    "mp_coop_credits",

    // DLC1
    "mp_coop_lobby_3",
    "mp_coop_separation_1", "mp_coop_tripleaxis", "mp_coop_catapult_catch", "mp_coop_2paints_1bridge", "mp_coop_paint_conversion", "mp_coop_bridge_catch", "mp_coop_laser_tbeam", "mp_coop_paint_rat_maze", "mp_coop_paint_crazy_box"
]

local pszMapName = GetMapName();
local bShouldRun = false;

foreach ( pszMap in pszMaps )
{
    if ( pszMapName == pszMap )
    {
        bShouldRun = true;
        break;
    }
}

if ( !bShouldRun )
{
    return; // Not a native coop map.
}

//-----------------------------------------------------------------------------
// Purpose: Speed up checkpoints and ending transitions based on map type.
//-----------------------------------------------------------------------------
local bAlreadyAddedManagerOutput = false;
for ( local pRelay; pRelay = Entities.FindByClassname( pRelay, "logic_relay" ); )
{
    local pszRelayTargetName = pRelay.GetName();
    local bIsExitRelay = false;

    if ( pszRelayTargetName.find( "airlock_exit_door_open_rl" ) != null )
    {
        EntFire( pszRelayTargetName, "AddOutput", "OnTrigger " + pszRelayTargetName + ":Disable" );
    }
    else if ( pszRelayTargetName.find( "rl_start_exit_finished" ) != null )
    {
        // Enable the trigger to exit the map and do so immediately.
        EntFire( pszRelayTargetName, "Enable" );
        bIsExitRelay = true;
    }
    else if ( pszRelayTargetName.find( "rl_start_exit" ) != null )
    {
        // If this is a Course 5 map, end the map immediately.
        if ( Entities.FindByName( null, "blue_trigger_close" ) )
        {
            EntFire( "coop_man_start_transition", "AddOutput", "OnChangeToAllTrue " + pszRelayTargetName + ":Trigger" );
        }
        else
        {
            // Prevent cutscene for disassembly.
            EntFire( pszRelayTargetName, "Disable" );
        }
        continue; // No need to iterate over managers in this scenario.
    }
    else
    {
        continue; // We need a proper relay that either contains "airlock_exit_door_open_rl" or "rl_start_exit_finished".
    }

    for ( local pManager; pManager = Entities.FindByClassname( pManager, "logic_coop_manager" ); )
    {
        local pszManagerTargetName = pManager.GetName();

        if ( bIsExitRelay )
        {
            // Make maps end immediately.
            local iStringIndexMatchExit = pszManagerTargetName.find( "coopman_exit_level" );
            if ( iStringIndexMatchExit != null )
            {
                local pszStringInstance = pszManagerTargetName.slice( 0, iStringIndexMatchExit ); // i.e. "InstanceAuto8-".
                if ( ( pszMapName == "mp_coop_lobby_2" || pszMapName == "mp_coop_lobby_3" ) && ( pszRelayTargetName.find( "rl_start_exit_finished" ) != null ) )
                {
                    // Add this output for all lobby disassemblers.
                    EntFireByHandle( pManager, "AddOutput", "OnChangeToAllTrue " + pszStringInstance + "fade_out:Fade", 0, null, null );
                    EntFireByHandle( pManager, "AddOutput", "OnChangeToAllTrue " + pszStringInstance + "template_movie_level_transition:ForceSpawn::0.6", 0, null, null );
                    EntFireByHandle( pManager, "AddOutput", "OnChangeToAllTrue " + pszStringInstance + "gladosendoflevelrelay:Trigger::2.10", 0, null, null );
                }
                else if ( !bAlreadyAddedManagerOutput )
                {
                    // This section will run on standard maps, excluding disc maps. See AddDiscTransition for those maps.
                    EntFireByHandle( pManager, "AddOutput", "OnChangeToAllTrue " + pszStringInstance + "fade_out:Fade", 0, null, null );
                    EntFireByHandle( pManager, "AddOutput", "OnChangeToAllTrue " + pszStringInstance + "template_movie_level_transition:ForceSpawn::0.6", 0, null, null );

                    // Hacky workaround for the fact that delays do not work with RunScriptCode (We do this so that we can have a nice fade on level exit.)
                    Entities.CreateByClassname( "logic_relay" ).__KeyValueFromString( "targetname", "p2_coop_srm_transition_standard_rl" );
                    if ( pszMapName == "mp_coop_start" )
                    {
						if ( ( "GetHaveSeenDLCTubesReveal" in this ) && GetHaveSeenDLCTubesReveal.getinfos().native )
						{
                            EntFire( "p2_coop_srm_transition_standard_rl", "AddOutput", "OnTrigger " + pszStringInstance + "@command:Command:changelevel mp_coop_lobby_3:2.0" );
						}
                        EntFire( "p2_coop_srm_transition_standard_rl", "AddOutput", "OnTrigger " + pszStringInstance + "@command:Command:changelevel mp_coop_lobby_2:2.0" ); // Fires if Pre-DLC or we don't have mp_coop_lobby_3
                    }
                    else
                    {
                        EntFire( "p2_coop_srm_transition_standard_rl", "AddOutput", "OnTrigger " + pszStringInstance + "transition_script:RunScriptCode:TransitionFromMap();" );
                    }
                    EntFire( pszManagerTargetName, "AddOutput", "OnChangeToAllTrue p2_coop_srm_transition_standard_rl:Trigger::0.25" );

                    bAlreadyAddedManagerOutput = true; // Paranoid: For cleanliness, we don't want to add this output multiple times in standard levels. There is *usually* only one relay of this type anyway.
                }
            }
        }
        else
        {
            // Speed up whichever logic_relay and logic_coop_manager belong to each other. (This allows maps with multiple checkpoints to work properly.)
            local iStringIndexMatchCheckpoint = pszManagerTargetName.find( "coopman_airlock_success" );
            if ( iStringIndexMatchCheckpoint != null )
            {
                local pszSlicedManagerName = pszManagerTargetName.slice( 0, iStringIndexMatchCheckpoint );
                local pszSlicedRelayName = pszRelayTargetName.slice( 0, iStringIndexMatchCheckpoint );
                if ( pszSlicedManagerName != null && pszSlicedRelayName != null && pszSlicedManagerName == pszSlicedRelayName )
                {
                    EntFire( pszManagerTargetName, "AddOutput", "OnChangeToAllTrue " + pszRelayTargetName + ":Trigger" );
                }
            }
        }
    }
}

//-----------------------------------------------------------------------------
// Purpose: Allow for the last map in a course to end after inserting the disc.
//-----------------------------------------------------------------------------
local AddDiscTransition = function( vecTriggerx, vecTriggery, vecTriggerz )
{
    // Make disc transition the map.
    EntFireByHandle( Entities.FindByClassnameNearest( "trigger_once", Vector( vecTriggerx, vecTriggery, vecTriggerz ), 3 ), "AddOutput", "OnStartTouch transition_fadeout_1:Fade", 0, null, null );
    EntFireByHandle( Entities.FindByClassnameNearest( "trigger_once", Vector( vecTriggerx, vecTriggery, vecTriggerz ), 3 ), "AddOutput", "OnStartTouch template_movie_level_transition:ForceSpawn::1", 0, null, null );

    // Hacky workaround for the fact that delays do not work with RunScriptCode. (We do this so that we can have a nice fade on level exit.)
    Entities.CreateByClassname( "logic_relay" ).__KeyValueFromString( "targetname", "p2_coop_srm_transition_rl" );
    EntFireByHandle( Entities.FindByName( null, "p2_coop_srm_transition_rl" ), "AddOutput", "OnTrigger transition_script:RunScriptCode:SaveMPStatsData()", 0, null, null );
    EntFireByHandle( Entities.FindByName( null, "p2_coop_srm_transition_rl" ), "AddOutput", "OnTrigger transition_script:RunScriptCode:MarkMapComplete( \"" + GetMapName() + "\" )", 0, null, null );
    if ( ( "GetHaveSeenDLCTubesReveal" in this ) && GetHaveSeenDLCTubesReveal.getinfos().native )
    {
        EntFireByHandle( Entities.FindByName( null, "p2_coop_srm_transition_rl" ), "AddOutput", "OnTrigger transition_script:RunScriptCode:SetCameFromLastDLCMapFlag()", 0, null, null );
        EntFireByHandle( Entities.FindByName( null, "p2_coop_srm_transition_rl" ), "AddOutput", "OnTrigger @command:Command:changelevel mp_coop_lobby_3:1.0", 0, null, null );
    }
    EntFireByHandle( Entities.FindByName( null, "p2_coop_srm_transition_rl" ), "AddOutput", "OnTrigger @command:Command:changelevel mp_coop_lobby_2:1.0", 0, null, null ); // Fires if Pre-DLC or we don't have mp_coop_lobby_3
    EntFireByHandle( Entities.FindByClassnameNearest( "trigger_once", Vector( vecTriggerx, vecTriggery, vecTriggerz ), 3 ), "AddOutput", "OnStartTouch p2_coop_srm_transition_rl:Trigger::1.60", 0, null, null );
}

//-----------------------------------------------------------------------------
// Purpose: Allow for players to fall faster on disc maps.
//-----------------------------------------------------------------------------
local FastFall = function( pszBlueTriggerName, pszRedTriggerName )
{
    EntFire( pszBlueTriggerName, "AddOutput", "OnEndTouchBluePlayer !activator:AddOutput:basevelocity 0 0 -1000" );
    EntFire( pszRedTriggerName, "AddOutput", "OnEndTouchOrangePlayer !activator:AddOutput:basevelocity 0 0 -1000" );
}

//-----------------------------------------------------------------------------
// Purpose: Get rid of the gel spread RNG on C5 and C6 maps.
//-----------------------------------------------------------------------------
local SpeedUpGel = function()
{
    for ( local pEnt; pEnt = Entities.FindByClassname( pEnt, "info_paint_sprayer" ); )
    {
        pEnt.__KeyValueFromString( "blob_streak_percentage", "100" );
        pEnt.__KeyValueFromString( "min_streak_time", "2" );
        pEnt.__KeyValueFromString( "min_streak_speed_dampen", "1" );
        pEnt.__KeyValueFromString( "max_streak_speed_dampen", "1" );
    }
}

//-----------------------------------------------------------------------------
// Purpose: Attempt to filter out the correct map-specific code.
//-----------------------------------------------------------------------------
if ( pszMapName == "mp_coop_start" )
{
    // Pinging and taunting is always enabled when starting on this map in the game.
    // Fix an edge case where someone changes level to this while the state is disabled.
    EntFireByHandle( Entities.FindByName( null, "@global_no_pinging_blue" ), "TurnOff", "", 0, null, null );
    EntFireByHandle( Entities.FindByName( null, "@global_no_pinging_orange" ), "TurnOff", "", 0, null, null );
    EntFireByHandle( Entities.FindByName( null, "@global_no_taunting_blue" ), "TurnOff", "", 0, null, null );
    EntFireByHandle( Entities.FindByName( null, "@global_no_taunting_orange" ), "TurnOff", "", 0, null, null );

    // Skip the video from playing on map loads.
    local pRelayStartConnected = Entities.FindByName( null, "@relay_start_both_connected" )
    if ( pRelayStartConnected )
    {
        // Enable both triggers that bring players to the top.
        // This also starts SAR timer.
        EntFireByHandle( pRelayStartConnected, "AddOutput", "OnTrigger teleport_start:Enable", 0, null, null );
    }
    EntFire( "playmovie_connect_intro", "Kill" );

    // Skip the starting dialogue.
    EntFireByHandle( Entities.FindByName( null, "relay_start_glados_coop" ), "Disable", "", 0, null, null );

    // As soon as we drop to the bottom of the taunt area, enable the event listener for gesturing
    EntFireByHandle( Entities.FindByName( null, "counter_start_glados_coop" ), "AddOutput", "OnHitMax relay_gesture_hints:Trigger", 0, null, null );
    EntFireByHandle( Entities.FindByName( null, "counter_start_glados_coop" ), "AddOutput", "OnHitMax @glados:RunScriptCode:GladosPlayVcd(\"mp_coop_startRelaxationVaultIntro02\")", 0, null, null );

    // Can't recreate the counter, so we set the max counter to 5 to prevent outputs from being fired.
    // Then, check if it reaches 0 and proceed as normal with our own outputs.
    local pCounter = Entities.FindByName( null, "counter_gesture_test" );
    EntFireByHandle( pCounter, "SetMinValueNoFire", "0", 0, null, null );
    EntFireByHandle( pCounter, "SetMaxValueNoFire", "5", 0, null, null );
    EntFireByHandle( pCounter, "SetValueNoFire", "2", 0, null, null );
    EntFire( "eventlisten_gestures", "AddOutput", "OnEventFired counter_gesture_test:Subtract:2:0.03:1" ) // Must be delayed for both listeners.
    EntFireByHandle( pCounter, "AddOutput", "OnHitMin hint_gesture_1:EndHint", 0, null, null );
    EntFireByHandle( pCounter, "AddOutput", "OnHitMin eventlisten_gestures:Disable", 0, null, null );
    EntFireByHandle( pCounter, "AddOutput", "OnHitMin relay_gesture_1_move_on:Trigger", 0, null, null );

    // Set up the voice lines in a way that do not queue up into the next ones, and prevent the hint output from firing after the first line finishes.
    local pGlados = Entities.FindByName( null, "@glados" );
    if ( pGlados )
    {
        pGlados.ValidateScriptScope();
        local pScope = pGlados.GetScriptScope();
        if ( pScope )
        {
            delete pScope.SceneTable[ "mp_coop_startRelaxationVaultIntro02" ].fires;    // "Please wave to your partner."
            pScope.SceneTable[ "mp_coop_startcoop_ping_blue_success00" ].next = null;   // "Good."
            pScope.SceneTable[ "mp_coop_startcoop_ping_orange_success02" ].next = null; // "Really? Okay."
        }
    }

    // Speed up the Blue's pinging area.
    local pBluePingTrigger = Entities.FindByClassnameNearest( "trigger_once", Vector( -9984, -4384, 2072 ), 3 );
    if ( pBluePingTrigger )
    {
        EntFireByHandle( pBluePingTrigger, "AddOutput", "OnTrigger @glados:AddOutput:targetname p2_coop_srm_@glados", 0, null, null ); // Change the name to prevent dialogue from playing
        EntFireByHandle( pBluePingTrigger, "AddOutput", "OnTrigger relay_begin_ping_1:Trigger", 0, null, null );

        for ( local i = 1; i <= 9; i++ )
        {
            local pPingTrigger = Entities.FindByName( null, "pingdet_BLUE_" + i.tostring() );
            if ( pPingTrigger )
            {
                EntFireByHandle( pPingTrigger, "AddOutput", "OnBluePlayerPinged p2_coop_srm_@glados:AddOutput:targetname @glados:0.03", 0, null, null ); // Set the name back after a delay
                EntFireByHandle( pPingTrigger, "AddOutput", "OnBluePlayerPinged @glados:RunScriptCode:GladosPlayVcd(\"mp_coop_startcoop_ping_blue_success00\"):0.05", 0, null, null );
                EntFireByHandle( pPingTrigger, "AddOutput", "OnBluePlayerPinged relay_ping_1_move_on:Trigger", 0, null, null );
            }
        }
    }

    // Speed up Orange's pinging area.
    local pRedPingTrigger = Entities.FindByClassnameNearest( "trigger_once", Vector( -9984, -4392, 1015 ), 3 );
    if ( pRedPingTrigger )
    {
        EntFireByHandle( pRedPingTrigger, "AddOutput", "OnTrigger @glados:AddOutput:targetname p2_coop_srm_@glados", 0, null, null ); // Change the name to prevent dialogue from playing
        EntFireByHandle( pRedPingTrigger, "AddOutput", "OnTrigger relay_begin_ping_2:Trigger", 0, null, null );

        for ( local i = 1; i <= 9; i++ )
        {
            local pPingTrigger = Entities.FindByName( null, "pingdet_ORANGE_" + i.tostring() );
            if ( pPingTrigger )
            {
                EntFireByHandle( pPingTrigger, "AddOutput", "OnOrangePlayerPinged p2_coop_srm_@glados:AddOutput:targetname @glados:0.03", 0, null, null ); // Set the name back after a delay
                EntFireByHandle( pPingTrigger, "AddOutput", "OnOrangePlayerPinged @glados:RunScriptCode:GladosPlayVcd(\"mp_coop_startcoop_ping_orange_success02\"):0.05", 0, null, null );
                EntFireByHandle( pPingTrigger, "AddOutput", "OnOrangePlayerPinged relay_ping_2_move_on:Trigger", 0, null, null );
            }
        }
    }

    // Expose the two weapons faster and as soon as we get to them.
    EntFire( "player_1_portalgun_door_pedistal_removal_lvl2", "SetSpeed", "40" ); // Red
    EntFire( "player_2_portalgun_door_pedistal_removal_lvl2", "SetSpeed", "40" ); // Blue
    pGunCalibrationTrigger <- Entities.FindByClassnameNearest( "trigger_once", Vector( -10004, -4400, 300 ), 3 );
    if ( pGunCalibrationTrigger )
    {
        local AddCalibrationTriggerOutput = function( pszOutput ) { EntFireByHandle( pGunCalibrationTrigger, "AddOutput", "OnTrigger " + pszOutput, 0, null, null ); }
        AddCalibrationTriggerOutput( "player_1_portalgun_door_pedistal_removal_lvl2:Close" );
        AddCalibrationTriggerOutput( "player_2_portalgun_door_pedistal_removal_lvl2:Close" );
        AddCalibrationTriggerOutput( "ping_detector_blue:Enable::1.5" );
        AddCalibrationTriggerOutput( "ping_detector_orange:Enable::1.5" );
        AddCalibrationTriggerOutput( "tank_portalgun_orange:Activate::1.5" );
        AddCalibrationTriggerOutput( "tank_portalgun_blue:Activate::1.5" );
        AddCalibrationTriggerOutput( "snd_gun_steam:PlaySound" );
        AddCalibrationTriggerOutput( "snd_gun_steam:Kill::1.00" );
        AddCalibrationTriggerOutput( "steam_guns:Start" );
        AddCalibrationTriggerOutput( "steam_guns:Stop::1.00" );
        AddCalibrationTriggerOutput( "steam_guns:Kill::1.00" );
    }
    delete pGunCalibrationTrigger;

    // For an inbounds run, allow the final button to enable the team camera immediately.
    local pRelayRobotsMeet = Entities.FindByName( null, "relay_robots_meet" );
    if ( pRelayRobotsMeet )
    {
        EntFireByHandle( pRelayRobotsMeet, "AddOutput", "OnTrigger team_trigger_door:Enable", 0, null, null );
    }

    // Silently award the taunt for highFive.
    local pRelayComeTogether = Entities.FindByName( null, "@relay_come_together" );
    if ( pRelayComeTogether )
    {
        pRelayComeTogether.Destroy();
        Entities.CreateByClassname( "logic_relay" ).__KeyValueFromString( "targetname", "@relay_come_together" );
        EntFire( "@relay_come_together", "AddOutput", "OnTrigger team_trigger_door:Kill" );
        EntFire( "@relay_come_together", "AddOutput", "OnTrigger @glados:RunScriptCode:RespondToTaunt(1)" );
        EntFire( "@relay_come_together", "AddOutput", "OnTrigger @command:Command:mp_earn_taunt highFive 1;" );
        EntFire( "@relay_come_together", "AddOutput", "OnTrigger ach_hi_five:FireEvent::3.00" );
    }
}
else if ( pszMapName == "mp_coop_lobby_2" || pszMapName == "mp_coop_lobby_3" )
{
    // Remove starting tube blocker.
    EntFire( "relay_elevator_open", "Trigger" );
    EntFire( "relay_elevator_open", "Disable" );
    EntFire( "relay_elevator_open1", "Trigger" );
    EntFire( "relay_elevator_open1", "Disable" );
    EntFire( "blocker_blue", "Kill" );
    EntFire( "blocker_orange", "Kill" );
    EntFireByHandle( Entities.FindByClassnameNearest( "trigger_playerteam", Vector( 3924, 3352, -480 ), 1 ), "Disable", "", 0, null, null );
    EntFireByHandle( Entities.FindByClassnameNearest( "trigger_playerteam", Vector( 3924, 3496, -480 ), 1 ), "Disable", "", 0, null, null );

    // Open C1-C4 hub doors.
    // We do it this way since it is too early to tell if the game is splitscreen or not.
    function OpenCourseDoors()
    {
        Entities.FindByName( null, "trigger_run_script" ).DisconnectOutput( "OnStartTouchAll", "OpenCourseDoors" ); // We only need to fire this function once.

        if ( IsLocalSplitScreen() ) // Splitscreen has everything unlocked.
        {
            for ( local iCourse = 1; iCourse < 5; iCourse++ ) // (Courses 5 and 6 taken care of outside of this function.)
            {
                // Keep this particular track's door open.
                EntFire( "track" + iCourse.tostring() + "-math_coop_door_open", "Add", "1" );
                EntFire( "track" + iCourse.tostring() + "-math_coop_door_open", "Kill" );
            }

            return;
        }

        // We must check the progress and unlock courses accordingly.
        local iHighestActiveCourse = GetHighestActiveBranch();
        for ( local i = 1; i <= iHighestActiveCourse; i++ )
        {
            if ( i >= 6 ) { continue; } // 6 is handled much earlier and also applies to splitscreen.

            if ( i == 5 ) // Keep this particular track's door open.
            {
                // If we aren't newbies, check if this is a reveal for Course 5 and speed it up.
                if ( !( GetGladosSpokenFlags( 2 ) & ( 1 << 4 ) ) ) // Didn't say "Congratulations on completing the Aperture Science standard cooperative testing courses.".
                {
                    // Treat it as if the dialogue was spoken and we are returning back to the hub.
                    EntFire( "counter_return_to_hub", "SetValue", "5" );
                    EntFire( "counter_choose_course", "SetValue", "0" ); // Set it back to 0.
                    // AddGladosSpokenFlags( 2, ( 1 << 4 ) ); // Done through Valve's VScript. (mp_coop_lobby.nut)
                }
            }
            else
            {
                // Note that C1 should be open if we have no progress whatsoever in any other levels.
                EntFire( "track" + i.tostring() + "-math_coop_door_open", "Add", "1" );
                EntFire( "track" + i.tostring() + "-math_coop_door_open", "Kill" );
            }
        }
    }
    Entities.FindByName( null, "trigger_run_script" ).ConnectOutput( "OnStartTouchAll", "OpenCourseDoors" );

    if ( pszMapName == "mp_coop_lobby_3" )
    {
        function OpenDLCDoors()
        {
            // Keep DLC door open after the DLC course is selected.
            local pCoopScreen = Entities.FindByName( null, "coopman_screen" );
            if ( pCoopScreen )
            {
                pCoopScreen.Destroy();
            }
            local pCoopDoor = Entities.FindByName( null, "track6-compare_coop_door_open" );
            if ( pCoopDoor )
            {
                pCoopDoor.Destroy();
            }
            EntFire( "track6-track_door_open_trigger", "AddOutput", "OnTrigger track6-prop_door_hall:Open:::1" );
            EntFire( "script_dlc_screen_logic", "RunScriptCode", "OpenScreenStart()" );
            EntFireByHandle( Entities.FindByClassnameNearest( "trigger_playerteam", Vector( 3635.199951, -1184, -456 ), 1 ), "AddOutput", "OnTrigger hint_dlc:ShowHint", 0, null, null );
        }
        Entities.FindByName( null, "trigger_run_script" ).ConnectOutput( "OnStartTouchAll", "OpenDLCDoors" );
    }

    // Doesn't really matter in local games, but we run this anyway just for cleanliness.
    // Remake the unlock course relays for courses 2 and 3 so that the taunts are silently awarded.
    Entities.FindByName( null, "relay_glados_fling" ).Destroy();
    Entities.FindByName( null, "relay_glados_bridge" ).Destroy();
    Entities.CreateByClassname( "logic_relay" ).__KeyValueFromString( "targetname", "relay_glados_fling" );
    Entities.CreateByClassname( "logic_relay" ).__KeyValueFromString( "targetname", "relay_glados_bridge" );
    Entities.FindByName( null, "relay_glados_fling" ).SetOrigin( Vector( 5112, 3848, -472 ) );
    Entities.FindByName( null, "relay_glados_bridge" ).SetOrigin( Vector( 5112, 3832, -472 ) );
    EntFire( "relay_glados_fling", "Disable" );
    EntFire( "relay_glados_bridge", "Disable" );
    EntFire( "relay_glados_fling", "AddOutput", "OnTrigger @glados:RunScriptCode:CoopHubTrack02()" );
    EntFire( "relay_glados_fling", "AddOutput", "OnTrigger @command:Command:mp_earn_taunt laugh 1" );
    EntFire( "relay_glados_bridge", "AddOutput", "OnTrigger @glados:RunScriptCode:CoopHubTrack03()" );
    EntFire( "relay_glados_bridge", "AddOutput", "OnTrigger @command:Command:mp_earn_taunt teamtease 1" );

    // Speed up C5 entry.
    Entities.FindByName( null, "trigger_paint_door_open" ).Destroy();
    EntFire( "catapult_paint", "AddOutput", "exactVelocityChoiceType 2" ); // Note: This is needed so that the catapult speed change works with network clients.
    EntFire( "catapult_paint", "AddOutput", "playerSpeed 2850" );
    EntFire( "catapult_paint", "AddOutput", "OnCatapulted AutoInstance1-relay_dooropen:Trigger:::1" );
    EntFire( "track5-man_fall", "AddOutput", "OnChangeToAllTrue track5-template_movie_level_transition:ForceSpawn::1.00" );
    EntFire( "track5-man_fall", "AddOutput", "OnChangeToAllTrue track5-gladosendoflevelrelay:Trigger::1.50" );
    EntFire( "track5-man_fall", "AddOutput", "OnChangeToAllTrue track5-fade_exit_level:Fade" );

    // Exists in only the new lobby. Speed up the DLC course area.
    if ( pszMapName == "mp_coop_lobby_3" )
    {
        // Reveal faster. (Also account for Pre-DLC missing function.)
        if ( ( "GetHaveSeenDLCTubesReveal" in this ) && GetHaveSeenDLCTubesReveal.getinfos().native && !GetHaveSeenDLCTubesReveal() )
        {
            EntFire( "dlc_transport_sheath", "SetSpeed", "500" );
        }

        // Skip the viewcontrol for the tube travel to the DLC area. (Note that Blue will always end up on the left side, while Orange ends up on the right side.)
        Entities.FindByName( null, "blue_hub_to_dlc_cam" ).Destroy();
        Entities.FindByName( null, "blue_hub_to_dlc_fade" ).Destroy();
        Entities.FindByName( null, "orange_hub_to_dlc_cam" ).Destroy();
        Entities.FindByName( null, "orange_hub_to_dlc_fade" ).Destroy();
        local pFirstTeleportTrigger = Entities.FindByClassnameNearest( "trigger_playerteam", Vector( 2112, -1244, -832 ), 3 );
        EntFireByHandle( pFirstTeleportTrigger, "AddOutput", "OnStartTouchBluePlayer left_hub_to_dlc_destination:TeleportEntity:!activator", 0, null, null );
        EntFireByHandle( pFirstTeleportTrigger, "AddOutput", "OnStartTouchOrangePlayer right_hub_to_dlc_destination:TeleportEntity:!activator", 0, null, null );

        // Skip viewcontrol back to hub. (Note that unlike normal spawns, Blue ends up on the left side and Orange ends up on left.)
        Entities.FindByName( null, "blue_dlc_to_hub_cam" ).Destroy();
        Entities.FindByName( null, "blue_dlc_to_hub_fade" ).Destroy();
        Entities.FindByName( null, "orange_dlc_to_hub_cam" ).Destroy();
        Entities.FindByName( null, "orange_dlc_to_hub_fade" ).Destroy();
        local pSecondTeleportTrigger = Entities.FindByClassnameNearest( "trigger_playerteam", Vector( 2432, -1244, -832 ), 3 );
        EntFireByHandle( pSecondTeleportTrigger, "AddOutput", "OnStartTouchBluePlayer left_dlc_to_hub_destination:TeleportEntity:!activator", 0, null, null );
        EntFireByHandle( pSecondTeleportTrigger, "AddOutput", "OnStartTouchOrangePlayer right_dlc_to_hub_destination:TeleportEntity:!activator", 0, null, null );

        // Offset the teleport so that Orange's velocity remains consistent with Blue's.
        Entities.FindByName( null, "right_hub_to_dlc_destination" ).SetAbsOrigin( Vector( 3200, -1232, 1688 ) );
    }
}
else if ( pszMapName == "mp_coop_laser_crusher" )
{
    // Speed up the crushers lifting up, but not closing.
    local pLaserCatcher = Entities.FindByClassnameNearest( "prop_laser_catcher", Vector( 2720, -592, 32 ), 1 );
    if ( pLaserCatcher )
    {
        EntFireByHandle( pLaserCatcher, "AddOutput", "OnPowered crasher1:SetSpeed:300", 0, null, null );
        EntFireByHandle( pLaserCatcher, "AddOutput", "OnUnPowered crasher1:SetSpeed:30", 0, null, null );
    }

    pLaserCatcher = Entities.FindByClassnameNearest( "prop_laser_catcher", Vector( 2496, -1680, 32 ), 1 );
    if ( pLaserCatcher )
    {
        EntFireByHandle( pLaserCatcher, "AddOutput", "OnPowered crasher2:SetSpeed:300", 0, null, null );
        EntFireByHandle( pLaserCatcher, "AddOutput", "OnUnPowered crasher2:SetSpeed:30", 0, null, null );
    }
}
else if ( pszMapName == "mp_coop_rat_maze" )
{
    // Prevent taunt at start of map, but also trigger the dialogue at the right time and conditions.
    Entities.FindByName( null, "coop_man_give_taunt" ).Destroy();
    Entities.CreateByClassname( "logic_coop_manager" ).__KeyValueFromString( "targetname", "p2coop_taunt_manager" );
    EntFire( "p2coop_taunt_manager", "AddOutput", "OnChangeToAllTrue @glados:RunScriptCode:RespondToTaunt(3);" );
    EntFire( "p2coop_taunt_manager", "AddOutput", "OnChangeToAllTrue @command:Command:mp_earn_taunt rps 1;" );
    EntFireByHandle( Entities.FindByClassnameNearest( "trigger_playerteam", Vector( -176, -656, -632 ), 3 ), "AddOutput", "OnStartTouchBluePlayer p2coop_taunt_manager:SetStateBTrue", 0, null, null );
    EntFireByHandle( Entities.FindByClassnameNearest( "trigger_playerteam", Vector( -176, -656, -632 ), 3 ), "AddOutput", "OnStartTouchOrangePlayer p2coop_taunt_manager:SetStateATrue", 0, null, null );
}
else if ( pszMapName == "mp_coop_teambts" )
{
    FastFall( "InstanceAuto15-blue_dropper-cube_dropper_droptrigger_bottom", "InstanceAuto15-red_dropper-cube_dropper_droptrigger_bottom" );

    AddDiscTransition( 1164, -3051, 5682 );
}
else if ( pszMapName == "mp_coop_catapult_1" )
{
    // Silently award the taunt for robotDance.
    Entities.FindByName( null, "@relay_exit_door_opened" ).Destroy();
    Entities.CreateByClassname( "logic_relay" ).__KeyValueFromString( "targetname", "@relay_exit_door_opened" );
    EntFire( "@relay_exit_door_opened", "AddOutput", "OnTrigger team_trigger_door:Kill" );
    EntFire( "@relay_exit_door_opened", "AddOutput", "OnTrigger @command:Command:mp_earn_taunt robotDance 1;" );
    EntFire( "@relay_exit_door_opened", "AddOutput", "OnTrigger @glados:RunScriptCode:RespondToTaunt(5)" );
}
else if ( pszMapName == "mp_coop_multifling_1" )
{
    // Make catapults in second room faster.
    EntFire( "catapult2a", "AddOutput", "playerSpeed 2000" );
    EntFire( "catapult2a", "AddOutput", "physicsSpeed 1800" );
    EntFire( "catapult2a1", "AddOutput", "playerSpeed 800" );
    EntFire( "catapult2a1", "AddOutput", "physicsSpeed 600" );
    EntFire( "catapult2a2", "AddOutput", "playerSpeed 2300" );
    EntFire( "catapult2a2", "AddOutput", "physicsSpeed 1000" );
}
else if ( pszMapName == "mp_coop_fan" )
{
    FastFall( "blue_dropper-blue_dropper-cube_dropper_droptrigger_bottom", "blue_dropper-red_dropper-cube_dropper_droptrigger_bottom" );

    // Make fan faster at slowing down, but not speeding up.
    EntFire( "catcher", "AddOutput", "OnPowered brush_fan:AddOutput:fanfriction 90" );
    EntFire( "catcher", "AddOutput", "OnUnPowered brush_fan:AddOutput:fanfriction 18" );

    AddDiscTransition( -259.8, 881.89, 231.28 );
}
else if ( pszMapName == "mp_coop_wall_5" )
{
    FastFall( "blue_dropper-cube_dropper_droptrigger_bottom", "red_dropper-cube_dropper_droptrigger_bottom" ); // Red team can strafe on the word "official".

    // Silently award the taunt for teamhug.
    Entities.FindByName( null, "@relay_come_together" ).Destroy();
    Entities.CreateByClassname( "logic_relay" ).__KeyValueFromString( "targetname", "@relay_come_together" );
    EntFire( "@relay_come_together", "AddOutput", "OnTrigger @glados:RunScriptCode:RespondToTaunt(8)" );
    EntFire( "@relay_come_together", "AddOutput", "OnTrigger @command:Command:mp_earn_taunt teamhug 1;" );
    EntFire( "@relay_come_together", "AddOutput", "OnTrigger success_detector:Kill" );

    AddDiscTransition( 2133.35, -1587.71, 297.86 );
}
else if ( pszMapName == "mp_coop_tbeam_redirect" )
{
    // Make tractor beam faster.
    EntFireByHandle( Entities.FindByClassnameNearest( "prop_tractor_beam", Vector( 352, -416, 512 ), 1 ), "SetLinearForce", "400", 0, null, null );
}
else if ( pszMapName == "mp_coop_tbeam_drill" )
{
    // Make tractor beam faster.
    EntFireByHandle( Entities.FindByClassnameNearest( "prop_tractor_beam", Vector( 736, 544, 576 ), 1 ), "SetLinearForce", "350", 0, null, null );
}
else if ( pszMapName == "mp_coop_tbeam_catch_grind_1" )
{
    // Make tractor beam faster.
    EntFire( "tractorbeam_emitter", "SetLinearForce", "500" );
}
else if ( pszMapName == "mp_coop_tbeam_laser_1" )
{
    // Make tractor beam faster.
    EntFire( "tbeam_ride", "SetLinearForce", "400" );

    // Prevent taunt at start of map, but also trigger the dialogue at the right time and conditions.
    Entities.FindByName( null, "@relay_grant_taunt" ).Destroy();
    Entities.CreateByClassname( "logic_relay" ).__KeyValueFromString( "targetname", "@relay_grant_taunt" );
    EntFire( "@relay_grant_taunt", "AddOutput", "OnTrigger @glados:RunScriptCode:RespondToTaunt(9);" );
    EntFire( "@relay_grant_taunt", "AddOutput", "OnTrigger @command:Command:mp_earn_taunt trickfire 1;" );
}
else if ( pszMapName == "mp_coop_tbeam_polarity" )
{
    // Make tractor beam faster.
    EntFire( "tbeam", "SetLinearForce", "600" );
    EntFire( "button_1_pressed", "Disable" );
    EntFire( "button_1_unpressed", "Disable" );
    EntFire( "button_1-button", "AddOutput", "OnPressed tbeam:SetLinearForce:-600" );
    EntFire( "button_1-button", "AddOutput", "OnPressed toggle_indicators:SetTextureIndex:1" );
    EntFire( "button_1-button", "AddOutput", "OnUnPressed tbeam:SetLinearForce:600" );
    EntFire( "button_1-button", "AddOutput", "OnUnPressed toggle_indicators:SetTextureIndex:0" );
}
else if ( pszMapName == "mp_coop_tbeam_polarity2" )
{
    // Make tractor beam faster.
    EntFire( "tbeam", "SetLinearForce", "600" );
    EntFire( "button_1_pressed", "Disable" );
    EntFire( "button_1_unpressed", "Disable" );
    EntFire( "button_1", "AddOutput", "OnPressed tbeam:SetLinearForce:-600" );
    EntFire( "button_1", "AddOutput", "OnPressed toggle_indicators:SetTextureIndex:1" );
    EntFire( "button_1", "AddOutput", "OnUnPressed tbeam:SetLinearForce:600" );
    EntFire( "button_1", "AddOutput", "OnUnPressed toggle_indicators:SetTextureIndex:0" );
}
else if ( pszMapName == "mp_coop_tbeam_polarity3" )
{
    // Make tractor beam faster.
    EntFire( "tbeam", "SetLinearForce", "600" );
    EntFire( "button_1_pressed", "Disable" );
    EntFire( "button_1_unpressed", "Disable", "", 1.5 ); // A logic_auto invokes this, so give ample time for it to trigger.
    EntFire( "button_1-button", "AddOutput", "OnPressed tbeam:SetLinearForce:-600" );
    EntFire( "button_1-button", "AddOutput", "OnPressed toggle_indicators:SetTextureIndex:1" );
    EntFire( "button_1-button", "AddOutput", "OnPressed fizzler1_enable_rl:Trigger" );
    EntFire( "button_1-button", "AddOutput", "OnUnPressed tbeam:SetLinearForce:600" );
    EntFire( "button_1-button", "AddOutput", "OnUnPressed toggle_indicators:SetTextureIndex:0" );
    EntFire( "button_1-button", "AddOutput", "OnUnPressed fizzler1_disable_rl:Trigger" );
}
else if ( pszMapName == "mp_coop_tbeam_maze" )
{
    // Make tractor beam only slightly faster. We want to make sure that it's not too fast for doing the actual maze.
    EntFire( "tbeam", "SetLinearForce", "300" );
    EntFire( "button_1_pressed", "Disable" );
    EntFire( "button_1_unpressed", "Disable" );
    EntFire( "button_1-button", "AddOutput", "OnPressed tbeam:SetLinearForce:-300" );
    EntFire( "button_1-button", "AddOutput", "OnPressed toggle_indicators:SetTextureIndex:1" );
    EntFire( "button_1-button", "AddOutput", "OnUnPressed tbeam:SetLinearForce:300" );
    EntFire( "button_1-button", "AddOutput", "OnUnPressed toggle_indicators:SetTextureIndex:0" );
}
else if ( pszMapName == "mp_coop_tbeam_end" )
{
    // Make both tractor beams faster.
    EntFire( "tractorbeam_emitter", "SetLinearForce", "300" );

    FastFall( "InstanceAuto68-blue_dropper-cube_dropper_droptrigger_bottom", "InstanceAuto68-red_dropper-cube_dropper_droptrigger_bottom" );

    AddDiscTransition( 2572.99, -907.71, 130 );
}
else if ( pszMapName == "mp_coop_paint_come_along" )
{
    // Speed up gel.
    SpeedUpGel();

    // Speed up both of the lifts.
    EntFire( "lift3_rm5", "SetSpeed", "150" );
    EntFire( "lift2", "SetSpeed", "150" );
}
else if ( pszMapName == "mp_coop_paint_redirect" )
{
    // Speed up gel.
    SpeedUpGel();

    // Make tractor beam faster.
    EntFire( "tbeam", "SetLinearForce", "400" );
}
else if ( pszMapName == "mp_coop_paint_bridge" || pszMapName == "mp_coop_paint_walljumps" || pszMapName == "mp_coop_paint_speed_fling" )
{
    // Speed up gel.
    SpeedUpGel();
}
else if ( pszMapName == "mp_coop_paint_red_racer" )
{
    // Speed up gel.
    SpeedUpGel();

    // Make catapult trigger faster.
    EntFire( "catapult_launch_exit", "AddOutput", "lowerThreshold 0.6" );
    EntFire( "catapult_launch_exit", "AddOutput", "upperThreshold 1.56" );
    EntFire( "catapult_launch_exit", "AddOutput", "playerSpeed 1800" );
}
else if ( pszMapName == "mp_coop_paint_speed_catch" )
{
    // Speed up gel.
    SpeedUpGel();
}
else if ( pszMapName == "mp_coop_paint_longjump_intro" )
{
    // Speed up gel.
    SpeedUpGel();

    // Speed up spawning door.
    EntFireByHandle( Entities.FindByClassnameNearest( "trigger_once", Vector( 224, -7366, 948 ), 1 ), "AddOutput", "OnTrigger AutoInstance1-door_open:Trigger", 0, null, null );
    EntFireByHandle( Entities.FindByClassnameNearest( "trigger_once", Vector( 224, -7366, 948 ), 1 ), "AddOutput", "OnTrigger AutoInstance1-door_open:Disable::0.3", 0, null, null );
    EntFire( "AutoInstance1-door_upper", "SetSpeed", "150" );
    EntFire( "AutoInstance1-door_lower", "SetSpeed", "150" );

    // Prevent pushback with gagged turret.
    EntFireByHandle( Entities.FindByClassnameNearest( "npc_portal_turret_floor", Vector( 255.347458, -6304.168945, 896.335876 ), 1 ), "AddOutput", "DamageForce 0", 0, null, null );

    // Add enough speed to a paint sprayer that allows for the challenge mode ending strat without failure.
    EntFire( "paint_speed_2", "AddOutput", "min_speed 1200" );

    // Make gel spread faster after pressing both of the final levers.
    // We need to remake a trigger's outputs here with different timings.
    Entities.FindByName( null, "trigger_bluedoor" ).Destroy();

    // Open the next area.
    pTargetCoopManager <- Entities.FindByName( null, "coopman_turret_door1" );
    local AddLongJumpOutput = function( pszOutput ) { EntFireByHandle( pTargetCoopManager, "AddOutput", "OnChangeToAllTrue " + pszOutput, 0, null, null ); }
    AddLongJumpOutput( "chamber_exit_a-proxy:OnProxyRelay1:::1" );
    AddLongJumpOutput( "chamber_exit_a-proxy:OnProxyRelay1:::1" );
    AddLongJumpOutput( "turrets:Enable::1.00:1" );
    AddLongJumpOutput( "snd_alarm:StopSound::2.00:1" );
    AddLongJumpOutput( "snd_paint_speed_mid:PlaySound:::1" );
    AddLongJumpOutput( "snd_paint_speed_mid_end:PlaySound::3.00:1" );

    // Paint
    EntFire( "paint_speed_mid", "AddOutput", "blobs_per_second 50" ); // Dispenses slowly by default.
    Entities.FindByName( null, "paint_speed_mid" ).SetAngles( 49, 90, 90 ); // Push it up so that there isn't a gap in the sheet of gel.
    EntFire( "paint_speed_mid_main", "AddOutput", "blobs_per_second 50" ); // Dispenses slowly by default.
    AddLongJumpOutput( "part_paint_speed_1:Start:::1" );
    AddLongJumpOutput( "part_paint_speed_1:Stop::1.00:1" );
    AddLongJumpOutput( "part_paint_speed_2:Start:::1" );
    AddLongJumpOutput( "part_paint_speed_2:Stop::1.00:1" );
    AddLongJumpOutput( "paint_speed_mid:Start:::1" );
    AddLongJumpOutput( "paint_speed_mid:Stop::1.00:1" );
    AddLongJumpOutput( "paint_speed_mid_main:Start:::1" );
    AddLongJumpOutput( "paint_speed_mid_main:Stop::1.00:1" );
    delete pTargetCoopManager;
}
else if ( pszMapName == "mp_coop_tripleaxis" )
{
    // Make crusher trigger faster.
    Entities.FindByName( null, "crusher_sequence_start_rl" ).Destroy();
    Entities.CreateByClassname( "logic_relay" ).__KeyValueFromString( "targetname", "crusher_sequence_start_rl" );
    EntFire( "crusher_sequence_start_rl", "AddOutput", "OnTrigger crusher:SetAnimation:Smash_in" );
    EntFire( "crusher_sequence_start_rl", "AddOutput", "OnTrigger gibshooter_0:Shoot::0.60" );
    EntFire( "crusher_sequence_start_rl", "AddOutput", "OnTrigger breakpanel_0_shake:StartShake::0.60" );
    EntFire( "crusher_sequence_start_rl", "AddOutput", "OnTrigger smashed_panels_0:Enable::0.60" );
    EntFire( "crusher_sequence_start_rl", "AddOutput", "OnTrigger breakpanel_0:Break::0.60" );
    EntFire( "crusher_sequence_start_rl", "AddOutput", "OnTrigger crusher_track_wav:PlaySound::0.60" );
    EntFire( "crusher_sequence_start_rl", "AddOutput", "OnTrigger @glados:RunScriptCode:DLC1_mp_coop_tripleaxis_intro():1.25" ); // The delay works here...
    EntFire( "crusher_sequence_start_rl", "AddOutput", "OnTrigger crusher:SetAnimation:Smash_out:1.25" );
    EntFire( "crusher_sequence_start_rl", "AddOutput", "OnTrigger crusher_blocker:Kill::2.50" );
    EntFire( "crusher_sequence_start_rl", "AddOutput", "OnTrigger trigger_hide_crusher:Enable::2.50" );

    Entities.FindByClassnameNearest( "trigger_once", Vector( 1760, 2888, 128 ), 1 ).Destroy();
    EntFireByHandle( Entities.FindByClassnameNearest( "trigger_once", Vector( 1036, 3072, 168 ), 1 ), "AddOutput", "OnStartTouch crusher_sequence_start_rl:Trigger", 0, null, null );

    // Make ending platform rise twice as fast.
    EntFire( "lift_1_door_ride", "SetSpeed", "300" );

    // Make tractor beam faster.
    EntFireByHandle( Entities.FindByClassnameNearest( "prop_tractor_beam", Vector( 1440, 1727.969971, 192 ), 1 ), "SetLinearForce", "500", 0, null, null );
}
else if ( pszMapName == "mp_coop_catapult_catch" )
{
    // Make catapults faster.
    EntFire( "catapult_01", "AddOutput", "playerSpeed 900" );
    EntFire( "catapult_01", "AddOutput", "physicsSpeed 900" );
    EntFire( "catapult_02", "AddOutput", "playerSpeed 900" );
    EntFire( "catapult_02", "AddOutput", "playerSpeed 900" );
    EntFire( "fling_catapult", "AddOutput", "physicsSpeed 1100" );
}
else if ( pszMapName == "mp_coop_2paints_1bridge" )
{
    // Speed up gel.
    SpeedUpGel();

    // Make paint sprayer in the first room distill faster.
    EntFire( "paint_sprayer_blue_1", "AddOutput", "max_speed 600" );
    EntFire( "paint_sprayer_blue_1", "AddOutput", "maxblobcount 60" );
    EntFire( "paint_sprayer_blue_1", "AddOutput", "blobs_per_second 30" );

    // Make checkpoint door stop being weird upon first entry.
    Entities.FindByName( null, "entry_airlock-trig_diable_entry" ).Destroy();

    // Make second room paint sprayers always stay on once we get to them.
    Entities.FindByName( null, "paint_timer_blue" ).Destroy();
    Entities.FindByName( null, "paint_timer_orange" ).Destroy();
    EntFireByHandle( Entities.FindByClassnameNearest( "trigger_once", Vector( 1472, 1650, 256 ), 1 ), "AddOutput", "OnTrigger paint_sprayer_blue:Start", 0, null, null );
    EntFireByHandle( Entities.FindByClassnameNearest( "trigger_once", Vector( 1472, 1650, 256 ), 1 ), "AddOutput", "OnTrigger paint_sprayer_orange:Start", 0, null, null );

    // Special case for broken disassemblers fast transition.
    EntFire( "InstanceAuto9-start_malfunction_rl", "Disable" );
    EntFire( "InstanceAuto9-coopman_exit_level", "AddOutput", "OnChangeToAllTrue @malfunction_end_rl:Trigger" );
}
else if ( pszMapName == "mp_coop_paint_conversion" )
{
    // Speed up gel.
    SpeedUpGel();

    // Make breaker room faster.
    Entities.FindByName( null, "disassembler_start_relay" ).Destroy();
    Entities.CreateByClassname( "logic_relay" ).__KeyValueFromString( "targetname", "disassembler_start_relay" );
    pDisassemblerRelay <- Entities.FindByName( null, "disassembler_start_relay" );
    local AddRelayOutput = function( pszOutput ) { EntFireByHandle( pDisassemblerRelay, "AddOutput", "OnTrigger " + pszOutput, 0, null, null ); }
    AddRelayOutput( "disassembler_door_2_blocker_disable_relay:CancelPending" );
    AddRelayOutput( "disassembler_door_1_blocker_disable_relay:CancelPending" );
    AddRelayOutput( "disassembler_door_1_blocker_disable_relay:Kill" );
    AddRelayOutput( "disassembler_door_2_blocker_disable_relay:Kill" );
    AddRelayOutput( "disassembler_2_door_2:Close" );
    AddRelayOutput( "disassembler_2_door_1:Close" );
    AddRelayOutput( "disassembler_1_door_2:Close" );
    AddRelayOutput( "disassembler_1_door_1:Close" );
    AddRelayOutput( "@glados:RunScriptCode:DLC1_2Paints_1Bridge_PowerCycle()" );
    AddRelayOutput( "disassembler_2_door_antiblocker:Disable" );
    AddRelayOutput( "disassembler_1_door_antiblocker:Disable" );
    AddRelayOutput( "disassembler_1_steam:Start" );
    AddRelayOutput( "disassembler_1_steam_fx:PlaySound" );
    AddRelayOutput( "disassembler_2_steam:Start" );
    AddRelayOutput( "disassembler_2_steam_fx:PlaySound" );
    AddRelayOutput( "disassembler_start_clunk:PlaySound::0.50" );
    AddRelayOutput( "disassembler_dropper_props:SetAnimation:item_dropper_open:1.50" );
    AddRelayOutput( "disassembler_dropper_props_sound:PlaySound::1.50" );
    AddRelayOutput( "disassembler_glow_sprites:Color:0 255 0:1.50" );
    AddRelayOutput( "disassembler_start_ding:PlaySound::1.50" );
    delete pDisassemblerRelay;

    // Make conversion gel in the final room distill faster.
    EntFire( "paint_sprayer_white", "AddOutput", "maxblobcount 60" );
    EntFire( "paint_sprayer_white", "AddOutput", "blobs_per_second 20" );
}
else if ( pszMapName == "mp_coop_laser_tbeam" )
{
    // Make tractor beam faster. (Hack: There's no real good way to do it for this map...)
    Entities.FindByName( null, "tbeam" ).__KeyValueFromString( "targetname", "tbeam_renamed" );
    EntFire( "tbeam_renamed", "SetLinearForce", "500" );
    local pCatcher = Entities.FindByClassnameNearest( "prop_laser_catcher", Vector( -144, 320, -480 ), 1 );
    if ( pCatcher )
    {
        EntFireByHandle( pCatcher, "AddOutput", "OnPowered tbeam_renamed:SetLinearForce:-500", 0, null, null );
        EntFireByHandle( pCatcher, "AddOutput", "OnUnpowered tbeam_renamed:SetLinearForce:500", 0, null, null );
    }
}
else if ( pszMapName == "mp_coop_paint_rat_maze" )
{
    // Speed up gel.
    SpeedUpGel();

    // Make paint sprayers always stay on.
    local pEnt = Entities.FindByName( null, "bounce_paint_timer" );
    if ( pEnt )
    {
        pEnt.Destroy();
    }
    EntFire( "bounce_paint_sprayer", "Start" );
    EntFire( "speed_paint_sprayer", "Start" );
}
else if ( pszMapName == "mp_coop_paint_crazy_box" )
{
    // Speed up gel.
    SpeedUpGel();

    // Prevent night vision view.
    EntFire( "bts_nightvision_fade_to_black", "Disable" );
    EntFire( "bts_nightvision_enable", "Disable" );
    EntFire( "bts_nightvision_fade_to_white", "Disable" );
    EntFire( "bts_nightvision_disable", "Disable" );
    EntFire( "team_door-exit_door-trigger_glados_exit_door", "AddOutput", "OnStartTouch bts_wall_undamaged:Disable" );
    EntFire( "team_door-exit_door-trigger_glados_exit_door", "AddOutput", "OnStartTouch bts_wall_damaged:Enable" );
    EntFire( "team_door-exit_door-trigger_glados_exit_door", "AddOutput", "OnStartTouch bts_wall_areaportal:Open" );
    EntFire( "team_door-exit_door-trigger_glados_exit_door", "AddOutput", "OnStartTouch bts_wall_playerpusher:Disable::1.00" );

    // Make ending faster.
    EntFire( "both_players_in_rl", "Disable" );
    EntFire( "coopman_airlock_success", "AddOutput", "OnChangeToAllTrue team_trigger_walkway:Kill" );
    EntFire( "coopman_airlock_success", "AddOutput", "OnChangeToAllTrue walkway_gate_door:Open" );
    EntFire( "coopman_airlock_success", "AddOutput", "OnChangeToAllTrue InstanceAuto76-fade_return_hub:Fade" );
    EntFire( "coopman_airlock_success", "AddOutput", "OnChangeToAllTrue final_door_fade_to_black:Trigger::1.5" );
}
else if ( pszMapName == "mp_coop_credits" )
{
    AddCoopCreditsName( "" ); // First slot doesn't work apparently...
    AddCoopCreditsName( "P2 Coop SRM by Nanoman2525" );
    AddCoopCreditsName( "Special thanks:" );
    AddCoopCreditsName( "someturkeywithacomputer" );
    AddCoopCreditsName( "tricksurf" );
    AddCoopCreditsName( "Bumpy" );
    AddCoopCreditsName( "That's about it lol" );
}
