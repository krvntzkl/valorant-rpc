from .menu_presences import (default,queue,custom_setup)

def presence(rpc,client=None,data=None,content_data=None,config=None):
    state_types = {
        "DEFAULT": default,
        "MATCHMAKING": queue,
        "CUSTOM_GAME_SETUP": custom_setup,
    }
    # Check if partyState exists and is valid
    if data and 'partyState' in data and data['partyState'] in state_types.keys():
        state_types[data['partyState']].presence(rpc,client=client,data=data,content_data=content_data,config=config)
    elif data and 'queueId' in data:
        # If we have a queueId, we're likely in queue
        if data.get('queueEntryTime') and data['queueEntryTime'] != "0001.01.01-00.00.00":
            # We're in queue
            queue.presence(rpc,client=client,data=data,content_data=content_data,config=config)
        else:
            # We're in menu but not in queue
            default.presence(rpc,client=client,data=data,content_data=content_data,config=config)
    elif data:
        # Fallback to default menu presence
        default.presence(rpc,client=client,data=data,content_data=content_data,config=config)