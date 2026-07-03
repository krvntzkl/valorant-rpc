# -*- mode: python ; coding: utf-8 -*-
from PyInstaller.utils.hooks import collect_submodules, collect_all

block_cipher = None

# Collect all submodules from src + dépendances parfois manquées par l'analyse
hiddenimports = ['pystray._win32', 'iso8601']
try:
    hiddenimports += collect_submodules('src')
except:
    pass

# Explicitly add all src modules as backup
hiddenimports += [
    'src',
    'src.startup',
    'src.utilities',
    'src.utilities.killable_thread',
    'src.utilities.config',
    'src.utilities.config.app_config',
    'src.utilities.config.modify_config',
    'src.utilities.processes',
    'src.utilities.rcs',
    'src.utilities.systray',
    'src.utilities.version_checker',
    'src.utilities.logging',
    'src.utilities.program_data',
    'src.utilities.filepath',
    'src.localization',
    'src.localization.localization',
    'src.localization.locales',
    'src.presence',
    'src.presence.presence',
    'src.presence.presence_utilities',
    'src.presence.presences',
    'src.presence.presences.startup',
    'src.presence.presences.menu',
    'src.presence.presences.pregame',
    'src.presence.presences.ingame',
    'src.presence.presences.menu_presences',
    'src.presence.presences.menu_presences.default',
    'src.presence.presences.menu_presences.queue',
    'src.presence.presences.menu_presences.away',
    'src.presence.presences.menu_presences.custom_setup',
    'src.presence.presences.ingame_presences',
    'src.presence.presences.ingame_presences.session',
    'src.presence.presences.ingame_presences.range',
    'src.webserver',
    'src.webserver.server',
    'src.content',
    'src.content.content_loader',
]

# Collect all data from pystray and PIL
datas = [('assets', 'assets')]
binaries = []
tmp_ret = collect_all('pystray')
datas += tmp_ret[0]
binaries += tmp_ret[1]
hiddenimports += tmp_ret[2]
import certifi
tmp_ret = collect_all('PIL')
datas += tmp_ret[0]
binaries += tmp_ret[1]
hiddenimports += tmp_ret[2]
from PyInstaller.utils.hooks import copy_metadata

datas.append(('cacert.pem', '.'))
datas += copy_metadata('prompt_toolkit')


a = Analysis(
    ['main.py'],
    pathex=['.'],
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='valorant-rpc',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    version='version.py',
    icon='favicon.ico',
)
