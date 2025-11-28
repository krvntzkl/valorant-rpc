from ...presence_utilities import Utilities
from ....localization.localization import Localizer

from .away import presence as away

def presence(rpc,client=None,data=None,content_data=None,config=None):
    if not data:
        return
    
    is_afk = data.get("isIdle", False)
    if is_afk:
        away(rpc,client,data,content_data,config)  
   
    else: 
        party_state,party_size = Utilities.build_party_state(data)
        match_map = data.get("matchMap", "")
        if match_map:
            data["MapID"] = match_map
        game_map,map_name = Utilities.fetch_map_data(data,content_data)
        custom_game_team = data.get("customGameTeam", "")
        team = content_data["team_image_aliases"].get(custom_game_team, "game_icon_white") if custom_game_team in content_data["team_image_aliases"] else "game_icon_white"
        team_patched = content_data["team_aliases"].get(custom_game_team) if custom_game_team in content_data["team_aliases"].keys() else None
        team_patched = Utilities.localize_content_name(team_patched, "presences", "team_names", custom_game_team)
        buttons = Utilities.get_join_state(client,config,data)
        
        party_id = data.get("partyId", "")

        rpc.update(
            state=party_state,
            details=Localizer.get_localized_text("presences","client_states","custom_setup"),
            large_image=f"splash_{game_map.lower()}" if game_map else "game_icon",
            large_text=map_name,
            small_image=team,
            small_text=team_patched,
            party_size=party_size,
            party_id=party_id if party_id else None,
            buttons=buttons
        )