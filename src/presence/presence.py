from pypresence import Presence as PyPresence
from pypresence.exceptions import InvalidPipe
from InquirerPy.utils import color_print
import time, sys, traceback, os, ctypes, asyncio, websockets, json, base64, ssl

ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

from ..utilities.config.app_config import Config
from ..content.content_loader import Loader
from ..localization.localization import Localizer
from .presences import (ingame,menu,startup,pregame)

kernel32 = ctypes.WinDLL('kernel32')
user32 = ctypes.WinDLL('user32')
hWnd = kernel32.GetConsoleWindow()

class Presence:

    def __init__(self,config):
        self.config = config
        self.client = None
        self.saved_locale = None
        try:
            self.rpc = PyPresence(client_id=str(Localizer.get_config_value("client_id")))
            self.rpc.connect()
        except InvalidPipe as e:
            raise Exception(e)
        self.content_data = {}
    
    def main_loop(self):
        # async with websockets.connect(f'wss://riot:{self.client.lockfile["password"]}@localhost:{self.client.lockfile["port"]}', ssl=ssl_context) as websocket:
        #     await websocket.send('[5, "OnJsonApiEvent_chat_v4_presences"]')    # subscribing to presence event
            
        #     while True:
        #         response = await websocket.recv()
        #         if response != "":
        #             response = json.loads(response)
        #             if response[2]['data']['presences'][0]['puuid'] == self.client.puuid:
        #                 presence_data = json.loads(base64.b64decode((response[2]['data']['presences'][0]['private'])))
        #                 if presence_data is not None:
        #                     self.update_presence(presence_data["sessionLoopState"],presence_data)
        #                     # print(presence_data)
        #                 else:
        #                     os._exit(1)

        #                 if Localizer.locale != self.saved_locale:
        #                     self.saved_locale = Localizer.locale
        #                     self.content_data = Loader.load_all_content(self.client)


        while True:
            presence_data = self.client.fetch_presence()
            if presence_data is not None:
                session_state = presence_data.get("sessionLoopState")
                
                # Always try to update presence if we have data
                if not session_state or (isinstance(session_state, str) and not session_state.strip()):
                    # If sessionLoopState is missing/empty, try to determine state from other keys
                    # First check if we're in game using coregame
                    in_game = False
                    try:
                        from valclient.exceptions import PhaseError
                        coregame = self.client.coregame_fetch_player()
                        if coregame is not None:
                            in_game = True
                            self.update_presence("INGAME", presence_data)
                    except PhaseError:
                        in_game = False
                    except Exception as e:
                        in_game = False
                    
                    if not in_game:
                        # Not in game, check other indicators
                        if "provisioningFlow" in presence_data:
                            provisioning = presence_data.get("provisioningFlow", "")
                            if provisioning == "ShootingRange":
                                self.update_presence("INGAME", presence_data)
                            else:
                                self.update_presence("MENUS", presence_data)
                        elif "queueId" in presence_data:
                            self.update_presence("MENUS", presence_data)
                        elif "partyState" in presence_data:
                            self.update_presence("MENUS", presence_data)
                        else:
                            self.update_presence("MENUS", presence_data)
                else:
                    self.update_presence(session_state, presence_data)
            else:
                os._exit(1)

            if Localizer.locale != self.saved_locale:
                self.saved_locale = Localizer.locale
                self.content_data = Loader.load_all_content(self.client)
            time.sleep(Localizer.get_config_value("presence_refresh_interval"))


    def init_loop(self):
        try:
            self.content_data = Loader.load_all_content(self.client)
            color_print([("LimeGreen bold", Localizer.get_localized_text("prints","presence","presence_running"))])
            
            presence_data = self.client.fetch_presence()

            if presence_data is not None:
                session_state = presence_data.get("sessionLoopState")
                
                # Always try to update presence if we have data
                if not session_state or (isinstance(session_state, str) and not session_state.strip()):
                    # Check if we're in game first
                    in_game = False
                    try:
                        from valclient.exceptions import PhaseError
                        coregame = self.client.coregame_fetch_player()
                        if coregame is not None:
                            in_game = True
                            self.update_presence("INGAME", presence_data)
                    except:
                        in_game = False
                    
                    if not in_game:
                        # Not in game, check other indicators
                        if "provisioningFlow" in presence_data:
                            provisioning = presence_data.get("provisioningFlow", "")
                            if provisioning == "ShootingRange":
                                self.update_presence("INGAME", presence_data)
                            else:
                                self.update_presence("MENUS", presence_data)
                        elif "queueId" in presence_data:
                            self.update_presence("MENUS", presence_data)
                        elif "partyState" in presence_data:
                            self.update_presence("MENUS", presence_data)
                        else:
                            self.update_presence("MENUS", presence_data)
                else:
                    self.update_presence(session_state, presence_data)
                
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)

            #asyncio.ensure_future(self.main_loop())
            self.main_loop()

                    
        except Exception as e:
            user32.ShowWindow(hWnd, 1)
            kernel32.SetConsoleMode(kernel32.GetStdHandle(-10), (0x4|0x80|0x20|0x2|0x10|0x1|0x40|0x100))
            color_print([("Red bold",Localizer.get_localized_text("prints","errors","error_message"))])
            traceback.print_exc()
            input(Localizer.get_localized_text("prints","errors","exit"))
            os._exit(1)

    def update_presence(self,ptype,data=None):
        try:
            # Normalize ptype to uppercase for comparison
            if isinstance(ptype, str):
                ptype_upper = ptype.upper()
            else:
                ptype_upper = str(ptype).upper()
            
        presence_types = {
                "STARTUP": startup,
            "MENUS": menu,
            "PREGAME": pregame,
            "INGAME": ingame,
        }
            
            # Handle "startup" as a special case (lowercase)
            if ptype_upper == "STARTUP" or ptype == "startup":
                presence_types["STARTUP"].presence(self.rpc,client=self.client,data=data,content_data=self.content_data,config=self.config)
            elif ptype_upper in presence_types.keys():
                try:
                    presence_types[ptype_upper].presence(self.rpc,client=self.client,data=data,content_data=self.content_data,config=self.config)
                except Exception as e:
                    print(f"[ERROR] Failed to update {ptype_upper} presence: {e}")
                    import traceback
                    traceback.print_exc()
            elif data is not None and "partyState" in data:
                # Fallback: if ptype is not recognized but we have partyState, try MENUS
                try:
                    presence_types["MENUS"].presence(self.rpc,client=self.client,data=data,content_data=self.content_data,config=self.config)
                except Exception as e:
                    print(f"[ERROR] Failed to update MENUS presence (partyState): {e}")
                    import traceback
                    traceback.print_exc()
            elif data is not None and "queueId" in data:
                # Fallback: if we have queueId, try MENUS
                try:
                    presence_types["MENUS"].presence(self.rpc,client=self.client,data=data,content_data=self.content_data,config=self.config)
                except Exception as e:
                    print(f"[ERROR] Failed to update MENUS presence (queueId): {e}")
                    import traceback
                    traceback.print_exc()
        except Exception as e:
            print(f"[ERROR] Failed to update presence: {e}")
            import traceback
            traceback.print_exc()