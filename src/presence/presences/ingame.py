from .ingame_presences.session import Game_Session
from .ingame_presences.range import Range_Session
from valclient.exceptions import PhaseError
from ..presence_utilities import Utilities
from ...localization.localization import Localizer

def presence(rpc,client=None,data=None,content_data=None,config=None):
    try:
        coregame = client.coregame_fetch_player()

        if coregame is not None:
            match_id = coregame["MatchID"]
            provisioning = data.get("provisioningFlow", "") if data else ""
            
            # Update presence immediately with basic info
            if data:
                try:
                    party_state, party_size = Utilities.build_party_state(data)
                    mode_image, mode_name = Utilities.fetch_mode_data(data, content_data)
                    
                    # Basic presence update
                    rpc.update(
                        state=party_state,
                        details=f"En partie - {mode_name}",
                        large_image="game_icon",
                        large_text="VALORANT",
                        small_image=mode_image,
                        small_text=mode_name,
                        party_size=party_size,
                        party_id=data.get("partyId", "") if data.get("partyId") else None,
                    )
                except Exception as e:
                    # If immediate update fails, continue anyway
                    pass
            
            # Then start the detailed session loop
            if provisioning != "ShootingRange":
                try:
                    session = Game_Session(rpc,client,data,match_id,content_data,config)
                    session.main_loop()
                except Exception as e:
                    # Log error but don't crash
                    import traceback
                    print(f"[ERROR] Game_Session failed: {e}")
                    traceback.print_exc()
            else:
                session = Range_Session(rpc,client,data,match_id,content_data,config)
                session.main_loop()

    except PhaseError:
        # Not in game phase, this is normal
        pass
    except Exception as e:
        import traceback
        print(f"[ERROR] ingame.presence failed: {e}")
        traceback.print_exc()
