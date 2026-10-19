#!/bin/bash
# SP Football Life 2026 -> SteamOS ARM (tested: Konkr Pocket Fit, SM8650/Adreno 750, Box64 0.4.5)
# Makes a PRE-INSTALLED copy of the game run, without Lutris. Usage:
#   ./install-spfl26.sh ["/path/to/SP Football Life 2026"]
# Without argument it finds the game in ~/Games or on a microSD card (asks if it is in both).
# Safe to re-run; run it again after moving the game folder. Run it from Desktop Mode (Konsole).
# Needs internet (~450 MB download, once).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTERNAL_DIR="$HOME/Games/SP Football Life 2026"
# SteamOS mounts a (non-boot) card at /run/media/<user>/<label> (older builds: /run/media/<label>)
CARD_SEARCH=(/run/media/*/*/"Non-Steam Games/SP Football Life 2026" /run/media/*/"Non-Steam Games/SP Football Life 2026"
             /run/media/*/*/"Games/SP Football Life 2026" /run/media/*/"Games/SP Football Life 2026"
             /run/media/*/*/"SP Football Life 2026" /run/media/*/"SP Football Life 2026")
PROTON_TAG="GE-Proton9-27"
PROTON_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/$PROTON_TAG"
TOOLS_DIR="$HOME/x86ge"
PREFIX="$HOME/Games/SPFL26-prefix"
LAUNCHER="$HOME/Games/launch-spfl26.sh"
DEFAULT_SETTINGS_B64="V0VDRmsAAAB3AgAAgAcAADgEAAACAAAAAAAAAGsWAABsFgAAAAAAAAAAAAAAAAAAAAAAABAeEC0QIBARECwQLhAQEBIQLxAwEQARABBIEFAQSxBNEMgQ0BDLEM0RABEAEQARAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"   # XInput + Full Screen + VSync Enable 2, 1920x1080

say() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

say "Checking system"
[ "$(uname -m)" = aarch64 ] || die "This is for aarch64 (ARM) devices only."
command -v box64 >/dev/null || die "box64 not found. This guide needs the SteamOS ARM image that ships Box64."
grep -q '^enabled' /proc/sys/fs/binfmt_misc/box64 2>/dev/null || die "Box64 binfmt is not enabled (x86 programs can't be run directly)."
command -v curl >/dev/null && command -v python3 >/dev/null || die "curl and python3 are required."

say "Looking for the game folder"
cat <<EOF
The game folder (the one with FL_2026.exe) must be copied BEFORE running this script, to one of:
  1) Internal memory or microSD bootable SteamOS:  $INTERNAL_DIR
  2) MicroSD card - not a bootable SteamOS microSD: /run/media/$USER/<card name>/Non-Steam Games/SP Football Life 2026
     (also accepted on the card: Games/SP Football Life 2026, or SP Football Life 2026 at the top of the card)
Moved it later? Just run this script again.
EOF
if [ -n "${1:-}" ]; then
  GAME_DIR="$1"
else
  CARD_DIR=""
  for d in "${CARD_SEARCH[@]}"; do [ -f "$d/FL_2026.exe" ] && { CARD_DIR="$d"; break; }; done
  INT_OK=""; [ -f "$INTERNAL_DIR/FL_2026.exe" ] && INT_OK=1
  if [ -n "$INT_OK" ] && [ -n "$CARD_DIR" ]; then
    echo; echo "The game was found in both places:"
    echo "  1) Internal memory or microSD bootable SteamOS: $INTERNAL_DIR"
    echo "  2) MicroSD card - not a bootable SteamOS microSD: $CARD_DIR"
    read -r -p "Which one should be used? [1/2] " a || die "No answer. Run it again and pass the game folder as argument."
    case "$a" in 1) GAME_DIR="$INTERNAL_DIR";; 2) GAME_DIR="$CARD_DIR";; *) die "Please answer 1 or 2.";; esac
  elif [ -n "$INT_OK" ]; then GAME_DIR="$INTERNAL_DIR"
  elif [ -n "$CARD_DIR" ]; then GAME_DIR="$CARD_DIR"
  else die "Game not found in the places above. Copy the game folder there (is the microSD card inserted?), or pass it as argument:
  ./install-spfl26.sh \"/path/to/SP Football Life 2026\""
  fi
fi
[ -f "$GAME_DIR/FL_2026.exe" ] || die "FL_2026.exe not found in: $GAME_DIR"
case "$GAME_DIR" in /run/media/*) echo "Using the game on the microSD card (keep the card inserted to play).";; esac
echo "Game folder: $GAME_DIR"

say "Installing $PROTON_TAG (x86_64 build, runs through Box64)"
if [ -x "$TOOLS_DIR/$PROTON_TAG/proton" ]; then
  echo "already installed"
else
  mkdir -p "$TOOLS_DIR" "$HOME/Games/.dl"; cd "$HOME/Games/.dl"
  curl -L --fail -o pt.tar.gz "$PROTON_URL/$PROTON_TAG.tar.gz"
  curl -L --fail -o pt.sha512 "$PROTON_URL/$PROTON_TAG.sha512sum"
  [ "$(sha512sum pt.tar.gz | cut -d' ' -f1)" = "$(cut -d' ' -f1 pt.sha512)" ] || die "Checksum mismatch, download again."
  tar -xf pt.tar.gz -C "$TOOLS_DIR"; rm -f pt.tar.gz pt.sha512
fi

say "Preparing game folder (Sider loader + launcher .bat)"
cd "$GAME_DIR"
if [ ! -f ddraw.dll ]; then
  [ -f xinput1_3.dll ] || die "xinput1_3.dll missing in the game folder (is this the full SPFL install?)"
  [ -f xinput1_3.dll.bak ] || cp xinput1_3.dll xinput1_3.dll.bak
  cp xinput1_3.dll ddraw.dll
fi
printf '%s\r\n' '@echo off' '' 'set "fl=FL_2026.exe"' 'set "sider=SiderAddons\sider.exe"' 'set "log=SiderAddons\sider-app.log"' '' 'cd /d "%~dp0"' 'del %log%' 'echo Launching sider...' 'start "" %sider%' '' ':wait' 'if not exist "%log%" (' '    ping -n 1 127.0.0.1 >nul' '    goto wait' ')' '' 'ping -n 3 127.0.0.1 >nul' 'echo sider active...' 'echo Launching FL...' 'start "" %fl%' > FL_2026.bat

say "Writing launcher $LAUNCHER"
cat > "$LAUNCHER" <<LAUNCH
#!/bin/bash
# SP Football Life 2026: GE-Proton 9 (x86_64) via Box64; starts Sider, then the game (FL_2026.bat)
G="$GAME_DIR"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="\$HOME/.local/share/Steam" STEAM_COMPAT_DATA_PATH="$PREFIX" SteamAppId="\${SteamAppId:-0}" SteamGameId="\${SteamGameId:-0}"
export WINEDLLOVERRIDES="ddraw=n,b;steam_api64=n,b;lsteamclient=d" ENABLE_GAMESCOPE_WSI=0 WINEDEBUG=-all
export PROTON_USE_XALIA=0 PROTON_NO_ESYNC=1 PROTON_NO_FSYNC=1 PROTON_NO_NTSYNC=1 BOX64_NOBANNER=1
export BOX64_DYNAREC_STRONGMEM=0 BOX64_DYNAREC_FASTNAN=1 BOX64_DYNAREC_FASTROUND=1 BOX64_DYNAREC_CALLRET=1 BOX64_DYNAREC_WEAKBARRIER=0  # speed flags; delete this line if a device has problems
[ -n "\$DISPLAY" ] || export DISPLAY=:0
[ -n "\$XDG_RUNTIME_DIR" ] || export XDG_RUNTIME_DIR=/run/user/\$(id -u)
mkdir -p "$PREFIX"; cd "\$G" || exit 1
exec "$TOOLS_DIR/$PROTON_TAG/proton" run "\$G/FL_2026.bat"
LAUNCH
chmod +x "$LAUNCHER"
SETTINGS_LAUNCHER="$HOME/Games/spfl26-settings.sh"
if [ -f "$SCRIPT_DIR/spfl26-settings.sh" ]; then cp -f "$SCRIPT_DIR/spfl26-settings.sh" "$SETTINGS_LAUNCHER"; chmod +x "$SETTINGS_LAUNCHER"; fi

say "Creating Wine prefix (first time takes a few minutes under emulation)"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.local/share/Steam" STEAM_COMPAT_DATA_PATH="$PREFIX" SteamAppId=0 SteamGameId=0
export PROTON_USE_XALIA=0 PROTON_NO_ESYNC=1 PROTON_NO_FSYNC=1 PROTON_NO_NTSYNC=1 BOX64_NOBANNER=1 WINEDEBUG=-all
mkdir -p "$PREFIX"
if [ ! -d "$PREFIX/pfx/drive_c/users/steamuser" ]; then
  timeout 600 "$TOOLS_DIR/$PROTON_TAG/proton" run wineboot -u >/dev/null 2>&1 || true
  sleep 3; WINEPREFIX="$PREFIX/pfx" "$TOOLS_DIR/$PROTON_TAG/files/bin/wineserver" -k 2>/dev/null || true
fi
SD="$PREFIX/pfx/drive_c/users/steamuser/Documents/KONAMI/eFootball PES 2021 SEASON UPDATE"
if [ -d "$PREFIX/pfx/drive_c/users/steamuser" ]; then
  mkdir -p "$SD"
  if [ ! -f "$SD/settings.dat" ]; then echo "$DEFAULT_SETTINGS_B64" | base64 -d > "$SD/settings.dat"; echo "default settings installed"; fi
else
  echo "WARNING: prefix not created; start the game once, quit, then re-run this script to apply settings."
fi

say "Desktop shortcut"
mkdir -p "$HOME/Desktop"
ICON="$HOME/Games/spfl26-icon.png"
[ -f "$SCRIPT_DIR/artwork/icon.png" ] && cp -f "$SCRIPT_DIR/artwork/icon.png" "$ICON" || ICON=applications-games
cat > "$HOME/Desktop/SPFL26.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=SP Football Life 2026
Exec=$LAUNCHER
Path=$GAME_DIR
Icon=$ICON
Terminal=false
Categories=Game;
DESK
chmod +x "$HOME/Desktop/SPFL26.desktop"
SICON="$HOME/Games/spfl26-settings-icon.png"
if [ -f "$SCRIPT_DIR/artwork/settings/icon.png" ]; then cp -f "$SCRIPT_DIR/artwork/settings/icon.png" "$SICON"; else SICON="$ICON"; fi
cat > "$HOME/Desktop/SPFL26-Settings.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=SP Football Life 2026 - Settings
Exec=$SETTINGS_LAUNCHER
Path=$GAME_DIR
Icon=$SICON
Terminal=false
Categories=Game;
DESK
chmod +x "$HOME/Desktop/SPFL26-Settings.desktop"

say "Steam shortcut (for Game Mode)"
SCV=$(ls "$HOME"/.local/share/Steam/userdata/*/config/shortcuts.vdf 2>/dev/null | head -1 || true)
if [ -z "$SCV" ]; then
  echo "No Steam user data found. Open Steam once, then re-run, or add the shortcut by hand (see README)."
else
  if pgrep -x steam >/dev/null; then
    read -r -p "Steam must be closed to add the shortcut. Close it now? [y/N] " a || a=n
    if [[ "$a" =~ ^[Yy] ]]; then steam -shutdown >/dev/null 2>&1 || true; for i in $(seq 20); do pgrep -x steam >/dev/null || break; sleep 1; done; fi
  fi
  if pgrep -x steam >/dev/null; then
    echo "Steam still running: skipped. In Steam use 'Add a Non-Steam Game' -> SP Football Life 2026."
  else
    python3 - "$SCV" "$LAUNCHER" "$SETTINGS_LAUNCHER" "$GAME_DIR" "$SCRIPT_DIR/artwork" <<'PY'
import sys,re,zlib,shutil,struct,os
p,exe_game,exe_set,start,art=sys.argv[1:6]
SRC=(("grid.png","%d.png"),("portrait.png","%dp.png"),("hero.png","%d_hero.png"),("logo.png","%d_logo.png"),("icon.png","%d_icon.png"),("logo-position.json","%d.json"))
d=open(p,"rb").read() if os.path.exists(p) else b"\x00shortcuts\x00\x08\x08"
if os.path.exists(p) and not os.path.exists(p+".bak-before-spfl26"): shutil.copy(p,p+".bak-before-spfl26")
s=lambda k,v:b"\x01"+k+b"\x00"+v+b"\x00"
i=lambda k,v:b"\x02"+k+b"\x00"+struct.pack("<I",v)
def put_art(appid,art):
    gd=os.path.join(os.path.dirname(p),"grid"); os.makedirs(gd,exist_ok=True); n=0
    for src,dst in SRC:
        sp=os.path.join(art,src); dp=os.path.join(gd,dst%appid)
        if os.path.exists(sp) and not os.path.exists(dp): shutil.copy(sp,dp); n+=1
    return n
for exe,label,adir in ((exe_game,b"SP Football Life 2026",art),(exe_set,b"SP Football Life 2026 - Settings",os.path.join(art,"settings") if os.path.isdir(os.path.join(art,"settings")) else art)):
    exe_q=('"%s"'%exe).encode(); appid_n=(zlib.crc32(exe_q+label)|0x80000000)&0xffffffff
    if exe_q in d:
        # keep StartDir in step with the game folder (it changes when the game is moved, e.g. to the microSD card)
        pat=re.compile(rb"(\x01Exe\x00"+re.escape(exe_q)+rb"\x00\x01StartDir\x00)[^\x00]*\x00")
        d=pat.sub(lambda m:m.group(1)+('"%s"'%start).encode()+b"\x00",d)
        print("Steam shortcut already present:",label.decode(),"(start folder updated)")
    else:
        ids=[int(x) for x in re.findall(rb"\x00(\d+)\x00\x02appid\x00",d)]; idx=(max(ids)+1) if ids else 0
        e=(b"\x00"+str(idx).encode()+b"\x00\x02appid\x00"+struct.pack("<I",appid_n)+s(b"AppName",label)+s(b"Exe",exe_q)+s(b"StartDir",('"%s"'%start).encode())+s(b"icon",b"")+s(b"ShortcutPath",b"")+s(b"LaunchOptions",b"")
         +i(b"IsHidden",0)+i(b"AllowDesktopConfig",1)+i(b"AllowOverlay",0)+i(b"OpenVR",0)+i(b"Devkit",0)+s(b"DevkitGameID",b"")+i(b"DevkitOverrideAppID",0)+i(b"LastPlayTime",0)+s(b"FlatpakAppID",b"")+b"\x01sortas\x00\x00\x00tags\x00\x08\x08")
        assert d.endswith(b"\x08\x08")
        d=d[:-2]+e+b"\x08\x08"; print("Steam shortcut added:",label.decode())
    print("  artwork: %d file(s) added"%put_art(appid_n,adir) if os.path.isdir(adir) else "  no artwork folder, skipped")
open(p,"wb").write(d)
PY
  fi
fi

say "DONE. Launch from the Desktop icon, or from Steam Game Mode (Library > Non-Steam). First start can take a minute."
