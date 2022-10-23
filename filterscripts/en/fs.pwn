/*
        @Author: El-SpaceX
        @Github: https://github.com/El-SpaceX/
        @Discord: SpaceX#5568

        thanks:
            + maddinat0r -> discord-connector
            + Akshay Mohan -> discord-cmd
            + sscanf developers and contributors
*/


//-------------------------------- Settings --------------------------------

//Link discord
#define DISCORD_LINK            "LINK DISCORD"

//prefix.
#define PREFIX                 "!"
#define DCMD_PREFIX            '!'

//IDs guild & role's
#define ID_ROLE_WHITELIST      2222222222222222222//"ID_ROLE" 
#define GUILD_ID               2222222222222222222//"ID_GUILD"

//Use -1 so that it is possible to use the command any channel 
#define ID_CHANNEL_WHITELIST   -1   //ID channel whitelist
#define ID_CHANNEL_RWHITELIST  -1   //ID channel rwhitelist. Not recommend use -1

//true or false.
#define CHANGE_NICKNAME         true


//Dir database
#define DIRECTORY_DATABASE      ".\\Whitelist\\database.db"



//Strings
#define STR_KICK_NOT_WHITELIST   "Your nick was not found in our whitelist, make it in our discord: "DISCORD_LINK""
#define STR_PLAYER_IN_WHITELIST  "Your nick was found in our whitelist, good game."
#define STR_EXISTS_NICK_WL       "This nick is already registered in our whitelist, try another one."
#define STR_ID_EXISTS_WL         "We found your discord account ID registered in our database, you have been set in your account."
#define STR_DCMD_INCORRECT       "Incorrect parameters, use "#PREFIX"wl [Nickname]"
#define STR_NICKNAME_INCORRECT   "The nickname must contain 3 to 24 characters."
#define STR_WHITELIST_SUCESS     "Whitelist successfully done, good game."
#define STR_RWHITELIST_INCORRECT "Incorrect parameters, use "#PREFIX"rwl [Nickname]"
#define STR_RWHITELIST_SUCESS    "Whitelist removed successfully."
#define STR_NICK_NOT_EXISTS      "No user with this nick was found in our whitelist"

//-------------------------------- libraries --------------------------------

#include <a_samp>
#include <discord-connector>
#include <discord-cmd>
#include <sscanf2>


//-------------------------------- Vars --------------------------------
new DCC_Role:role, DCC_Guild:guildid;
new DB:DBConnection;
new DBResult:DBResult;


////-------------------------------- Functions --------------------------------

forward KickDelay(playerid);
public KickDelay(playerid) {
    Kick(playerid);
}

forward SetAccounOfTheID(const userid[]);
public SetAccounOfTheID(const userid[]) {
    new
        DCC_User:user = DCC_FindUserById(userid);

    DCC_AddGuildMemberRole(guildid, user, role);
    #if CHANGE_NICKNAME == true
        new query[70], playername[MAX_PLAYER_NAME+1];
        format(query, sizeof(query), "SELECT playername FROM accept WHERE userid='%q'", userid);
        DBResult = db_query(DBConnection, query);
        db_get_field_assoc(DBResult, "playername", playername);
        DCC_SetGuildMemberNickname(guildid, user, playername);
    #endif

}

CreateDatabase(const directory[]=DIRECTORY_DATABASE) {
    if((DBConnection = db_open(directory)) != DB:1){
        return print("[WARNING-SQL] Whitelist database not loaded.");
    }
    else {

        db_query(DBConnection, "CREATE TABLE IF NOT EXISTS accept(playername VARCHAR(25) NOT NULL,\
        userid VARCHAR(21) NOT NULL);");

        return print("[WARNING-SQL] Whitelist database successfully loaded.");
    }
        
}


bool:IsPlayerInWhitelist(const playername[]) {
    new query[80];
    format(query, sizeof(query), "SELECT playername FROM accept WHERE playername='%q';", playername);
    DBResult = db_query(DBConnection, query);
    if(db_num_rows(DBResult) > 0)
        return true;
    else
        return false;
}

bool:IsIDInWhitelist(const userid[]) {
    new query[66];
    format(query, sizeof(query), "SELECT userid FROM accept WHERE userid='%q';", userid);
    DBResult = db_query(DBConnection, query);
    if(db_num_rows(DBResult) > 0)
        return true;
    else
        return false;
}


InsertWhitelist(const playername[], const userid[]) {
    new 
        query[84],
        DCC_User:user = DCC_FindUserById(userid);

    format(query, sizeof(query), "INSERT INTO accept VALUES ('%q', '%q');", playername, userid);
    db_query(DBConnection, query);
    DCC_AddGuildMemberRole(guildid, user, role);
    #if CHANGE_NICKNAME == true
        DCC_SetGuildMemberNickname(guildid, user, playername);
    #endif
}

RemovePlayerWhitelist(const playername[]) {
    new 
        query[100], 
        userid[DCC_ID_SIZE],
        DCC_User:user;
        
        
    format(query, sizeof(query), "SELECT userid FROM accept WHERE playername='%q'", playername);
    DBResult = db_query(DBConnection, query);
    db_get_field_assoc(DBResult, "userid", userid, sizeof(userid));

    user = DCC_FindUserById(userid);
    
    #if CHANGE_NICKNAME == true
        DCC_SetGuildMemberNickname(guildid, user, "");
    #endif
    DCC_RemoveGuildMemberRole(guildid, user, role);


    format(query, sizeof(query), "DELETE FROM accept WHERE playername='%q'", playername);
    db_free_result(db_query(DBConnection, query));
    
}

//-------------------------------- Callbacks --------------------------------


public OnFilterScriptInit() {
    CreateDatabase();
    guildid = DCC_FindGuildById(#GUILD_ID);
    role = DCC_FindRoleById(#ID_ROLE_WHITELIST);
    return 1;
}

public OnFilterScriptExit() {
    db_close(DBConnection);
    return 1;
}


public OnPlayerRequestClass(playerid, classid) {
    new playername[MAX_PLAYER_NAME+1];
    GetPlayerName(playerid, playername);
    if(!IsPlayerInWhitelist(playername)) {
        ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "Whitelist", STR_KICK_NOT_WHITELIST, "OK", #);
        SetTimerEx("KickDelay", 250, false, "i", playerid);
    }
    else{
        SendClientMessage(playerid, -1, STR_PLAYER_IN_WHITELIST);
    }
    return 1;
}


//-------------------------------- Commands --------------------------------

DCMD:wl(user, channel, params[]) {

    #if ID_CHANNEL_WHITELIST != -1
        if(channel != DCC_FindChannelById(#ID_CHANNEL_WHITELIST))
            return 1;
    #endif
    new 
        playername[MAX_PLAYER_NAME+1], 
        userid[DCC_ID_SIZE];

    if(sscanf(params, "s[25]", playername))
        return DCC_SendChannelEmbedMessage(channel, DCC_Embed:DCC_CreateEmbed("WhiteList", STR_DCMD_INCORRECT, .color=14226452));
   
    if(strlen(playername) > 24 || strlen(playername) < 3) 
        return DCC_SendChannelEmbedMessage(channel, DCC_Embed:DCC_CreateEmbed("WhiteList", STR_NICKNAME_INCORRECT, .color=14226452));
    

    DCC_GetUserId(user, userid);
    if(IsIDInWhitelist(userid)) {
        SetAccounOfTheID(userid);
        return DCC_SendChannelEmbedMessage(channel, DCC_Embed:DCC_CreateEmbed("WhiteList", STR_ID_EXISTS_WL, .color=2067276));
        
    }
    else if(IsPlayerInWhitelist(playername)) {
        return DCC_SendChannelEmbedMessage(channel, DCC_Embed:DCC_CreateEmbed("WhiteList", STR_EXISTS_NICK_WL, .color=14226452));
    }

    InsertWhitelist(playername, userid);
    DCC_SendChannelEmbedMessage(channel, DCC_Embed:DCC_CreateEmbed("WhiteList", STR_WHITELIST_SUCESS, .color=2067276));
    return 1;
}

DCMD:rwl(user, channel, params[]) {
    #if ID_CHANNEL_RWHITELIST != -1
        if(channel != DCC_FindChannelById(#ID_CHANNEL_RWHITELIST))
            return 1;
    #endif
    new 
        playername[MAX_PLAYER_NAME+1];
    if(sscanf(params, "s[25]", playername))
        return DCC_SendChannelEmbedMessage(channel, DCC_Embed:DCC_CreateEmbed("WhiteList", STR_RWHITELIST_INCORRECT, .color=14226452)); 

    if(strlen(playername) > 24 || strlen(playername) < 3) 
        return DCC_SendChannelEmbedMessage(channel, DCC_Embed:DCC_CreateEmbed("WhiteList", STR_NICKNAME_INCORRECT, .color=14226452));
    
    if(!IsPlayerInWhitelist(playername))
        return DCC_SendChannelEmbedMessage(channel, DCC_Embed:DCC_CreateEmbed("WhiteList", STR_NICK_NOT_EXISTS, .color=14226452));

    RemovePlayerWhitelist(playername);
    DCC_SendChannelEmbedMessage(channel, DCC_Embed:DCC_CreateEmbed("WhiteList", STR_RWHITELIST_SUCESS, .color=2067276));
    return 1;
}

