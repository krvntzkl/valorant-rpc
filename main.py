import ctypes,os,traceback,sys

import requests
import urllib3
original_request = requests.Session.request
def patched_request(*args, **kwargs):
    kwargs['verify'] = False
    return original_request(*args, **kwargs)
requests.Session.request = patched_request
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

import importlib.metadata
_original_version = importlib.metadata.version
def _patched_version(pkg_name):
    try:
        return _original_version(pkg_name)
    except importlib.metadata.PackageNotFoundError:
        return "99.99.99"
importlib.metadata.version = _patched_version


# Vérifier les dépendances AVANT les autres imports
try:
    from src.utilities.dependencies import (
        verify_and_install,
        check_dependencies,
        install_package,
        install_all_dependencies,
    )
    deps_ok, missing_deps = verify_and_install()
    while not deps_ok and missing_deps:
        kernel32 = ctypes.WinDLL('kernel32')
        user32 = ctypes.WinDLL('user32')
        hWnd = kernel32.GetConsoleWindow()
        user32.ShowWindow(hWnd, 1)
        kernel32.SetConsoleMode(kernel32.GetStdHandle(-10), (0x4|0x80|0x20|0x2|0x10|0x1|0x40|0x100))
        try:
            from InquirerPy.utils import color_print
            color_print([("Red bold", "Erreur : Bibliothèques Python manquantes")])
            color_print([("Yellow", f"Les bibliothèques suivantes ne sont pas installées : {', '.join(missing_deps)}")])
            color_print([("Cyan", "(y) installer un module  (n) annuler  (a) tout installer : ")])
        except Exception:
            print("Erreur : Bibliothèques Python manquantes")
            print(f"Les bibliothèques suivantes ne sont pas installées : {', '.join(missing_deps)}")
            print("(y) installer un module  (n) annuler  (a) tout installer : ")
        choice = input().strip().lower()
        if choice == "n":
            try:
                color_print([("White", "pip install -r requirements.txt")])
            except Exception:
                print("pip install -r requirements.txt")
            input("Appuyez sur Entrée pour quitter...")
            os._exit(1)
        if choice == "a":
            if install_all_dependencies():
                deps_ok, missing_deps = verify_and_install()
                if deps_ok:
                    break
            continue
        if choice == "y":
            first = missing_deps[0]
            if install_package(first):
                missing_deps = check_dependencies()
                deps_ok = len(missing_deps) == 0
                if deps_ok:
                    break
            continue
        # Choix invalide, réafficher la question au prochain tour
    if not deps_ok and missing_deps:
        input("Appuyez sur Entrée pour quitter...")
        os._exit(1)
except ImportError:
    # Si le module de vérification n'existe pas, on continue
    pass

from InquirerPy.utils import color_print
from src.startup import Startup 
from src.utilities.config.app_config import default_config
from src.localization.localization import Localizer

# Version affichée au lancement (alignée sur app_config / version.py)
VERSION = "v3.5.1"

kernel32 = ctypes.WinDLL('kernel32')
user32 = ctypes.WinDLL('user32')
hWnd = kernel32.GetConsoleWindow()

if __name__ == "__main__":
    color_print([("Tomato",f""" _   _____   __   ____  ___  ___   _  ________                
| | / / _ | / /  / __ \\/ _ \\/ _ | / |/ /_  __/__________  ____
| |/ / __ |/ /__/ /_/ / , _/ __ |/    / / / /___/ __/ _ \\/ __/
|___/_/ |_/____/\\____/_/|_/_/ |_/_/|_/ /_/     /_/ / .__/\\__/ 
                                                  /_/ """),("White",f"{VERSION}\n")])
    try:
        app = Startup()
    except ModuleNotFoundError as e:
        user32.ShowWindow(hWnd, 1)
        kernel32.SetConsoleMode(kernel32.GetStdHandle(-10), (0x4|0x80|0x20|0x2|0x10|0x1|0x40|0x100))
        color_print([("Red bold", "Erreur : Bibliothèque Python manquante")])
        color_print([("Yellow", f"La bibliothèque '{e.name}' n'est pas installée.")])
        color_print([("Cyan", "Pour installer toutes les dépendances, exécutez :")])
        color_print([("White", "pip install -r requirements.txt")])
        input(Localizer.get_localized_text("prints","errors","exit") if 'Localizer' in globals() else "Appuyez sur Entrée pour quitter...")
        os._exit(1)
    except:
        user32.ShowWindow(hWnd, 1)
        kernel32.SetConsoleMode(kernel32.GetStdHandle(-10), (0x4|0x80|0x20|0x2|0x10|0x1|0x40|0x100))
        color_print([("Red bold",Localizer.get_localized_text("prints","errors","error_message"))])
        traceback.print_exc()
        input(Localizer.get_localized_text("prints","errors","exit"))
        os._exit(1)