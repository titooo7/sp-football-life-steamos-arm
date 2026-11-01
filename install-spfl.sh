#!/bin/bash
# SP Football Life 2026 / 2027 -> SteamOS ARM (tested with 2026: Konkr Pocket Fit, SM8650/Adreno 750, Box64 0.4.5)
# Makes a PRE-INSTALLED copy of the game run, without Lutris. Usage:
#   ./install-spfl.sh                     finds SPFL 2026 and/or 2027 in ~/Games or on a microSD card (asks if several)
#   ./install-spfl.sh 27                  only look for SP Football Life 2027 (or 26 for 2026)
#   ./install-spfl.sh "/path/to/game"     use this folder (the edition is detected from FL_2026.exe / FL_2027.exe)
# Each edition gets its own Wine prefix, launcher, settings tool and shortcuts, so both can be installed side by side.
# Safe to re-run; run it again after moving a game folder. Run it from Desktop Mode (Konsole).
# Needs internet (~450 MB download, once; shared by both editions).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YEARS=(2026 2027)   # supported editions: the game folder must contain FL_<year>.exe
PROTON_TAG="GE-Proton9-27"
PROTON_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/$PROTON_TAG"
TOOLS_DIR="$HOME/x86ge"
# Both editions are built on PES 2021 and keep their settings/saves here, inside each edition's own prefix
SAVE_SUBDIR="drive_c/users/steamuser/Documents/KONAMI/eFootball PES 2021 SEASON UPDATE"
DEFAULT_SETTINGS_B64="V0VDRmsAAAB3AgAAgAcAADgEAAACAAAAAAAAAGsWAABsFgAAAAAAAAAAAAAAAAAAAAAAABAeEC0QIBARECwQLhAQEBIQLxAwEQARABBIEFAQSxBNEMgQ0BDLEM0RABEAEQARAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"   # XInput + Full Screen + V-Sync disabled, 1920x1080

say() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

WANT_YEAR=""; GAME_ARG=""
for a in "$@"; do
  case "$a" in
    26|2026) WANT_YEAR=2026;;
    27|2027) WANT_YEAR=2027;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) [ -z "$GAME_ARG" ] || die "Only one game folder can be given."; GAME_ARG="$a";;
  esac
done
[ -n "$WANT_YEAR" ] && SEARCH_YEARS=("$WANT_YEAR") || SEARCH_YEARS=("${YEARS[@]}")

say "Checking system"
[ "$(uname -m)" = aarch64 ] || die "This is for aarch64 (ARM) devices only."
command -v box64 >/dev/null || die "box64 not found. This guide needs the SteamOS ARM image that ships Box64."
grep -q '^enabled' /proc/sys/fs/binfmt_misc/box64 2>/dev/null || die "Box64 binfmt is not enabled (x86 programs can't be run directly)."
command -v curl >/dev/null && command -v python3 >/dev/null || die "curl and python3 are required."

say "Looking for the game folder"
# SteamOS mounts a (non-boot) card at /run/media/<user>/<label> (older builds: /run/media/<label>)
card_dirs() { local n="$1"
  printf '%s\n' /run/media/*/*/"Non-Steam Games/$n" /run/media/*/"Non-Steam Games/$n" \
                /run/media/*/*/"Games/$n" /run/media/*/"Games/$n" /run/media/*/*/"$n" /run/media/*/"$n"; }
FOUND_YEAR=(); FOUND_DIR=()
if [ -n "$GAME_ARG" ]; then
  [ -d "$GAME_ARG" ] || die "Folder not found: $GAME_ARG"
  for y in "${SEARCH_YEARS[@]}"; do [ -f "$GAME_ARG/FL_$y.exe" ] && { FOUND_YEAR+=("$y"); FOUND_DIR+=("$GAME_ARG"); }; done
  [ ${#FOUND_YEAR[@]} -gt 0 ] || die "No $(printf 'FL_%s.exe ' "${SEARCH_YEARS[@]}")found in: $GAME_ARG"
  [ ${#FOUND_YEAR[@]} -eq 1 ] || die "That folder has more than one FL_20xx.exe. Say which edition, e.g.: ./install-spfl.sh 27 \"$GAME_ARG\""
else
  for y in "${SEARCH_YEARS[@]}"; do
    n="SP Football Life $y"
    [ -f "$HOME/Games/$n/FL_$y.exe" ] && { FOUND_YEAR+=("$y"); FOUND_DIR+=("$HOME/Games/$n"); }
    while IFS= read -r d; do
      [ -f "$d/FL_$y.exe" ] && { FOUND_YEAR+=("$y"); FOUND_DIR+=("$d"); break; }
    done < <(card_dirs "$n")
  done
fi
if [ ${#FOUND_YEAR[@]} -eq 0 ]; then
  for y in "${SEARCH_YEARS[@]}"; do cat <<EOF
SP Football Life $y: copy the game folder (the one with FL_$y.exe) BEFORE running this script, to one of:
  1) Internal memory or microSD bootable SteamOS:  $HOME/Games/SP Football Life $y
  2) MicroSD card - not a bootable SteamOS microSD: /run/media/$USER/<card name>/Non-Steam Games/SP Football Life $y
     (also accepted on the card: Games/SP Football Life $y, or SP Football Life $y at the top of the card)
EOF
  done
  die "Game not found in the places above (is the microSD card inserted?). Or pass the folder as argument:
  ./install-spfl.sh \"/path/to/SP Football Life ${SEARCH_YEARS[-1]}\""
elif [ ${#FOUND_YEAR[@]} -eq 1 ]; then
  YEAR="${FOUND_YEAR[0]}"; GAME_DIR="${FOUND_DIR[0]}"
else
  echo; echo "Found more than one game folder:"
  for k in "${!FOUND_YEAR[@]}"; do
    case "${FOUND_DIR[$k]}" in /run/media/*) w="microSD card - not a bootable SteamOS microSD";; *) w="internal memory or microSD bootable SteamOS";; esac
    echo "  $((k+1))) SP Football Life ${FOUND_YEAR[$k]} ($w): ${FOUND_DIR[$k]}"
  done
  echo "(To set up both editions, run the script once for each.)"
  read -r -p "Which one should be set up now? [1-${#FOUND_YEAR[@]}] " a || die "No answer. Run it again and pass the game folder as argument."
  [[ "$a" =~ ^[0-9]+$ ]] && [ "$a" -ge 1 ] && [ "$a" -le ${#FOUND_YEAR[@]} ] || die "Please answer a number from 1 to ${#FOUND_YEAR[@]}."
  YEAR="${FOUND_YEAR[$((a-1))]}"; GAME_DIR="${FOUND_DIR[$((a-1))]}"
fi

YY="${YEAR:2}"
NAME="SP Football Life $YEAR"
EXE="FL_$YEAR.exe"; BAT="FL_$YEAR.bat"
PREFIX="$HOME/Games/SPFL$YY-prefix"
LAUNCHER="$HOME/Games/launch-spfl$YY.sh"
SETTINGS_LAUNCHER="$HOME/Games/spfl$YY-settings.sh"
ART="$SCRIPT_DIR/artwork/$YEAR"   # optional: Steam library images for this edition (+ settings/ subfolder)

case "$GAME_DIR" in /run/media/*) echo "Using the game on the microSD card (keep the card inserted to play).";; esac
echo "Game: $NAME"
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
# the .bat waits for Sider's log before starting the game, so without sider.exe it would wait forever
[ -f SiderAddons/sider.exe ] || die "SiderAddons/sider.exe missing in the game folder (is this the full SPFL install?)"
if [ ! -f ddraw.dll ]; then
  [ -f xinput1_3.dll ] || die "xinput1_3.dll missing in the game folder (is this the full SPFL install?)"
  [ -f xinput1_3.dll.bak ] || cp xinput1_3.dll xinput1_3.dll.bak
  cp xinput1_3.dll ddraw.dll
fi
printf '%s\r\n' '@echo off' '' "set \"fl=$EXE\"" 'set "sider=SiderAddons\sider.exe"' 'set "log=SiderAddons\sider-app.log"' '' 'cd /d "%~dp0"' 'del %log%' 'echo Launching sider...' 'start "" %sider%' '' ':wait' 'if not exist "%log%" (' '    ping -n 1 127.0.0.1 >nul' '    goto wait' ')' '' 'ping -n 3 127.0.0.1 >nul' 'echo sider active...' 'echo Launching FL...' 'start "" %fl%' > "$BAT"

say "Writing launcher $LAUNCHER"
mkdir -p "$HOME/Games"
cat > "$LAUNCHER" <<LAUNCH
#!/bin/bash
# $NAME: GE-Proton 9 (x86_64) via Box64; starts Sider, then the game ($BAT)
G="$GAME_DIR"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="\$HOME/.local/share/Steam" STEAM_COMPAT_DATA_PATH="$PREFIX" SteamAppId="\${SteamAppId:-0}" SteamGameId="\${SteamGameId:-0}"
export WINEDLLOVERRIDES="ddraw=n,b;steam_api64=n,b;lsteamclient=d" ENABLE_GAMESCOPE_WSI=0 WINEDEBUG=-all
export PROTON_USE_XALIA=0 PROTON_NO_ESYNC=1 PROTON_NO_FSYNC=1 PROTON_NO_NTSYNC=1 BOX64_NOBANNER=1
export BOX64_DYNAREC_STRONGMEM=0 BOX64_DYNAREC_FASTNAN=1 BOX64_DYNAREC_FASTROUND=1 BOX64_DYNAREC_CALLRET=1 BOX64_DYNAREC_WEAKBARRIER=0  # speed flags; delete this line if a device has problems
[ -n "\$DISPLAY" ] || export DISPLAY=:0
[ -n "\$XDG_RUNTIME_DIR" ] || export XDG_RUNTIME_DIR=/run/user/\$(id -u)
mkdir -p "$PREFIX"; cd "\$G" || exit 1
exec "$TOOLS_DIR/$PROTON_TAG/proton" run "\$G/$BAT"
LAUNCH
chmod +x "$LAUNCHER"
if [ -f "$SCRIPT_DIR/spfl-settings.sh" ]; then
  sed "s/^YEAR=.*/YEAR=\"\${SPFL_YEAR:-$YEAR}\"  # set by install-spfl.sh/" "$SCRIPT_DIR/spfl-settings.sh" > "$SETTINGS_LAUNCHER"
  chmod +x "$SETTINGS_LAUNCHER"
fi

say "Creating Wine prefix (first time takes a few minutes under emulation)"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.local/share/Steam" STEAM_COMPAT_DATA_PATH="$PREFIX" SteamAppId=0 SteamGameId=0
export PROTON_USE_XALIA=0 PROTON_NO_ESYNC=1 PROTON_NO_FSYNC=1 PROTON_NO_NTSYNC=1 BOX64_NOBANNER=1 WINEDEBUG=-all
mkdir -p "$PREFIX"
if [ ! -d "$PREFIX/pfx/drive_c/users/steamuser" ]; then
  timeout 600 "$TOOLS_DIR/$PROTON_TAG/proton" run wineboot -u >/dev/null 2>&1 || true
  sleep 3; WINEPREFIX="$PREFIX/pfx" "$TOOLS_DIR/$PROTON_TAG/files/bin/wineserver" -k 2>/dev/null || true
fi
SD="$PREFIX/pfx/$SAVE_SUBDIR"
if [ -d "$PREFIX/pfx/drive_c/users/steamuser" ]; then
  mkdir -p "$SD"
  if [ ! -f "$SD/settings.dat" ]; then echo "$DEFAULT_SETTINGS_B64" | base64 -d > "$SD/settings.dat"; echo "default settings installed"; fi
else
  echo "WARNING: prefix not created; start the game once, quit, then re-run this script to apply settings."
fi

say "Desktop shortcut"
mkdir -p "$HOME/Desktop"
ICON="$HOME/Games/spfl$YY-icon.png"
[ -f "$ART/icon.png" ] && cp -f "$ART/icon.png" "$ICON" || ICON=applications-games
cat > "$HOME/Desktop/SPFL$YY.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=$NAME
Exec=$LAUNCHER
Path=$GAME_DIR
Icon=$ICON
Terminal=false
Categories=Game;
DESK
chmod +x "$HOME/Desktop/SPFL$YY.desktop"
SICON="$HOME/Games/spfl$YY-settings-icon.png"
if [ -f "$ART/settings/icon.png" ]; then cp -f "$ART/settings/icon.png" "$SICON"; else SICON="$ICON"; fi
cat > "$HOME/Desktop/SPFL$YY-Settings.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=$NAME - Settings
Exec=$SETTINGS_LAUNCHER
Path=$GAME_DIR
Icon=$SICON
Terminal=false
Categories=Game;
DESK
chmod +x "$HOME/Desktop/SPFL$YY-Settings.desktop"

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
    echo "Steam still running: skipped. In Steam use 'Add a Non-Steam Game' -> $NAME."
  else
    python3 - "$SCV" "$LAUNCHER" "$SETTINGS_LAUNCHER" "$GAME_DIR" "$ART" "$NAME" "$YY" <<'PY'
import sys,re,zlib,shutil,struct,os
p,exe_game,exe_set,start,art,name,yy=sys.argv[1:8]
SRC=(("grid.png","%d.png"),("portrait.png","%dp.png"),("hero.png","%d_hero.png"),("logo.png","%d_logo.png"),("icon.png","%d_icon.png"),("logo-position.json","%d.json"))
d=open(p,"rb").read() if os.path.exists(p) else b"\x00shortcuts\x00\x08\x08"
bak=p+".bak-before-spfl"+yy
if os.path.exists(p) and not os.path.exists(bak): shutil.copy(p,bak)
s=lambda k,v:b"\x01"+k+b"\x00"+v+b"\x00"
i=lambda k,v:b"\x02"+k+b"\x00"+struct.pack("<I",v)
def put_art(appid,art):
    gd=os.path.join(os.path.dirname(p),"grid"); os.makedirs(gd,exist_ok=True); n=0
    for src,dst in SRC:
        sp=os.path.join(art,src); dp=os.path.join(gd,dst%appid)
        if os.path.exists(sp) and not os.path.exists(dp): shutil.copy(sp,dp); n+=1
    return n
for exe,label,adir in ((exe_game,name.encode(),art),(exe_set,(name+" - Settings").encode(),os.path.join(art,"settings"))):
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
    print("  artwork: %d file(s) added"%put_art(appid_n,adir) if os.path.isdir(adir) else "  no artwork folder for it, skipped (pick images in Steam or with Decky SteamGridDB)")
open(p,"wb").write(d)
PY
  fi
fi

say "DONE. Launch $NAME from the Desktop icon, or from Steam Game Mode (Library > Non-Steam). First start can take a minute."
