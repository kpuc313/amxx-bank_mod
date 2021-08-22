/*****************************************************************
*                            MADE BY
*
*   K   K   RRRRR    U     U     CCCCC    3333333      1   3333333
*   K  K    R    R   U     U    C     C         3     11         3
*   K K     R    R   U     U    C               3    1 1         3
*   KK      RRRRR    U     U    C           33333   1  1     33333
*   K K     R        U     U    C               3      1         3
*   K  K    R        U     U    C     C         3      1         3
*   K   K   R         UUUUU U    CCCCC    3333333      1   3333333
*
******************************************************************
*                       AMX MOD X Script                         *
*     You can modify the code, but DO NOT modify the author!     *
******************************************************************
*
* Description:
* ============
* This plugin imitates bank in your Counter-Strike 1.6 server (My very first amxx plugin!).
*
******************************************************************
*
* Thanks to:
* ==========
* VeCo - For the code to take money from player in the next round, if player has took money from the bank.
* independent - Fixing the bug with message announce.
* hateYou - Optimization of the code.
*
*****************************************************************/

#include <amxmodx>
#include <cstrike>
#include <hamsandwich> 

#define VERSION "1.5"
#define TAG "BANK"

new pcv_enable, pcv_increase, pcv_increase_amount, pcv_sounds, pcv_ann_time
new money[32], money_take[33], limit_money[33]
new g_SayText

new sound_wtb[64] = "bank_mod/wtb.wav"
new sound_you_cant[64] = "bank_mod/you_cant.wav"
new sound_you_dead[64] = "bank_mod/you_dead.wav"
new sound_see_you[64] = "bank_mod/see_you.wav"

public plugin_init() {
	register_plugin("Bank Mod", VERSION, "kpuc313")
	register_cvar("bankmod_version", VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("bankmod_version", VERSION)

	register_clcmd("say bank", "ShowBankMenu")
	register_clcmd("say /bank", "ShowBankMenu")
	register_clcmd("say_team bank", "ShowBankMenu")
	register_clcmd("say_team /bank", "ShowBankMenu")
	
	pcv_enable = register_cvar("bm_enable","1")
	pcv_increase = register_cvar("bm_increase","1")
	pcv_increase_amount = register_cvar("bm_increase_amount","200")
	pcv_sounds = register_cvar("bm_sounds","1")
	pcv_ann_time = register_cvar("bm_announce_time","60")

	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", 1)
	
	g_SayText = get_user_msgid("SayText")
	
	set_task(get_pcvar_float(pcv_ann_time), "announce", _, _, _, "b")
}

public plugin_precache()
{
	if(!get_pcvar_num(pcv_sounds)) return
	precache_sound(sound_wtb)
	precache_sound(sound_you_cant)
	precache_sound(sound_you_dead)
	precache_sound(sound_see_you)
}

public announce(id)
{
	if(!is_user_alive(id)) return
	colormsg(id, "\g[%s]\y Write say \t/bank\y to show the Bank Menu", TAG)
}

public fw_PlayerSpawn(id) 
{
	limit_money[id] = false
	if(money_take[id]) {
		if(get_pcvar_num(pcv_increase)) {
			money[id] += get_pcvar_num(pcv_increase_amount)
			colormsg(id, "\g[%s]\y Bank take she's money + \t%d\y increase!", TAG, get_pcvar_num(pcv_increase_amount))
		} else {
			colormsg(id, "\g[%s]\y Bank take she's money!", TAG)
		}
		if(money[id] > cs_get_user_money(id)) {
			cs_set_user_money(id, 0)
		} else {
			cs_set_user_money(id, cs_get_user_money(id) - money[id])
		}
		money_take[id] = false
	}
}

public ShowBankMenu(id)
{
	if(!get_pcvar_num(pcv_enable)) return
	if(is_user_alive(id)) {
		new menu = menu_create("Bank Menu", "menu_press")
			
		menu_additem(menu, "$1000 \yMoney", "1", 0)
		menu_additem(menu, "$2000 \yMoney", "2", 0)
		menu_additem(menu, "$3000 \yMoney", "3", 0)
		menu_additem(menu, "$4000 \yMoney", "4", 0)
		menu_additem(menu, "$5000 \yMoney", "5", 0)
		menu_additem(menu, "$6000 \yMoney", "6", 0)
		menu_additem(menu, "$7000 \yMoney", "7", 0)
			
		menu_display(id, menu, 0)
			
		if(get_pcvar_num(pcv_sounds))
		PlaySound(id,sound_wtb)
	}
	else
	{
		colormsg(id, "\g[%s]\y You can't take money when you dead!", TAG)
		if(get_pcvar_num(pcv_sounds))
		PlaySound(id,sound_you_dead)
	}
}

public menu_press(id, menu, item)
{
	if(item == MENU_EXIT )
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	new data[6], iName[64]
	new access, callback

	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback)

	new key = str_to_num(data)
    
	if(!limit_money[id]) 
	{
		money[id] = key * 1000;
		cs_set_user_money(id, cs_get_user_money(id) + money[id])
		colormsg(id, "\g[%s]\y You have take \t$%d\y money from bank", TAG, money[id])
		if(get_pcvar_num(pcv_sounds))
		PlaySound(id,sound_see_you)

		limit_money[id] = true
		money_take[id] = true
	} else {
		colormsg(id, "\g[%s]\y You can't take more money from bank!", TAG)
		if(get_pcvar_num(pcv_sounds))
		PlaySound(id,sound_you_cant)
	}

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

PlaySound(id,const sound[])
{
	client_cmd(id, "spk ^"%s^"", sound)
}

stock colormsg(const id, const string[], {Float, Sql, Resul,_}:...) {
	new msg[191], players[32], count = 1;
	vformat(msg, sizeof msg - 1, string, 3);
	
	replace_all(msg,190,"\g","^4");
	replace_all(msg,190,"\y","^1");
	replace_all(msg,190,"\t","^3");
	
	if(id)
		players[0] = id;
	else
		get_players(players,count,"ch");
	
	for (new i = 0 ; i < count ; i++)
	{
		if (is_user_connected(players[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, g_SayText,_, players[i]);
			write_byte(players[i]);
			write_string(msg);
			message_end();
		}		
	}
}
