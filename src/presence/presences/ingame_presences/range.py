import time

from ..menu_presences.away import presence as away
from ...presence_utilities import Utilities
from ....localization.localization import Localizer

class Range_Session:

    def __init__(self,rpc,client,data,match_id,content_data,config):
        self.rpc = rpc
        self.client = client
        self.config = config
        self.content_data = content_data
        self.match_id = match_id  
        self.puuid = self.client.puuid

        data["MapID"] = "/Game/Maps/Poveglia/Range" # hotfix :)
        self.start_time = time.time()
        self.map_name, self.mode_name = Utilities.fetch_map_data(data, content_data)
        self.map_image = "splash_range"
        self.small_image = None
        self.small_text = None

        if Localizer.get_config_value("presences","modes","range","show_rank_in_range"):
            self.small_image, self.small_text = Utilities.fetch_rank_data(self.client,self.content_data)

    def main_loop(self):
        presence = self.client.fetch_presence()
        # Don't rely on sessionLoopState, check if we're still in range
        while presence is not None:
            try:
                # Check if we're still in range by checking provisioningFlow
                current_presence = self.client.fetch_presence()
                if current_presence is None:
                    break
                provisioning = current_presence.get("provisioningFlow", "")
                if provisioning != "ShootingRange":
                    # No longer in range, exit loop
                    break
            except:
                # Error checking, continue anyway
                pass
            
                presence = self.client.fetch_presence()
            if presence is None:
                break
                
            try:
                is_afk = presence.get("isIdle", False)
                if is_afk:
                    away(self.rpc,self.client,presence,self.content_data,self.config)  
                else:
                    party_state,party_size = Utilities.build_party_state(presence)

                    # Ensure small_text is at least 2 characters or None
                    small_text_final = self.small_text if self.small_text and len(self.small_text) >= 2 else None
                    small_image_final = self.small_image if small_text_final else None

                    self.rpc.update(
                        state=party_state,
                        details=self.mode_name,
                        start=self.start_time,
                        large_image=self.map_image,
                        large_text=self.map_name,
                        small_image=small_image_final,
                        small_text=small_text_final,
                        party_size=party_size,
                        party_id=presence.get("partyId", "") if presence.get("partyId") else None,
                    )

                time.sleep(Localizer.get_config_value("presence_refresh_interval"))
            except Exception as e:
                # Log error and exit
                import traceback
                print(f"[ERROR] Range_Session.main_loop failed: {e}")
                traceback.print_exc()
                return