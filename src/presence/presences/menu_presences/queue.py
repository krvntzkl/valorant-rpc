from ...presence_utilities import Utilities
from ....localization.localization import Localizer

def presence(rpc,client=None,data=None,content_data=None,config=None):
    if not data:
        return
    
    party_state,party_size = Utilities.build_party_state(data)
    queue_entry_time = data.get('queueEntryTime', "0001.01.01-00.00.00")
    start_time = Utilities.iso8601_to_epoch(queue_entry_time)
    small_image, mode_name = Utilities.fetch_mode_data(data, content_data)
    small_text = mode_name
    
    account_level = data.get("accountLevel", 0)
    party_id = data.get("partyId", "")
    
    rpc.update(
        state=party_state,
        details=f"{Localizer.get_localized_text('presences','client_states','queue')} - {mode_name}",
        start=start_time,
        large_image="game_icon_white",
        large_text=f"{Localizer.get_localized_text('presences','leveling','level')} {account_level}",
        small_image=small_image,
        small_text=small_text,
        party_size=party_size,
        party_id=party_id if party_id else None,
    )
