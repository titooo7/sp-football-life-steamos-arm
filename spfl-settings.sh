#!/bin/bash
# Native settings editor for SP Football Life 2026 / 2027 (replaces the game's Settings.exe, which needs .NET/Mono
# and crashes under Box64). Edits settings.dat in the Wine prefix. Close the game before using it.
# Needs: zenity, python3 (both ship with SteamOS Desktop Mode).
# install-spfl.sh copies this to ~/Games/spflYY-settings.sh with YEAR set to that edition.
YEAR="${SPFL_YEAR:-2026}"  # set by install-spfl.sh
YY="${YEAR:2}"; NAME="SP Football Life $YEAR"
PREFIX="${SPFL_PREFIX:-$HOME/Games/SPFL$YY-prefix}"
DAT="$PREFIX/pfx/drive_c/users/steamuser/Documents/KONAMI/eFootball PES 2021 SEASON UPDATE/settings.dat"
[ -f "$DAT" ] || { zenity --error --text="settings.dat not found:\n$DAT\n\nStart the game once first." 2>/dev/null || echo "settings.dat not found: $DAT"; exit 1; }
[ -f "$DAT.backup" ] || cp "$DAT" "$DAT.backup"

# current values: byte8 = controller (6 DirectInput / 7 XInput) in high nibble, screen (6 Windowed / 7 Full Screen) in low nibble,
# byte9 = V-Sync (02 off / 04 Enable 1 / 08 Enable 2); width at offset 12, height at offset 16 (little-endian uint32)
read -r CTRL SCREEN VSYNC W H < <(python3 - "$DAT" <<'PY'
import sys,struct
d=open(sys.argv[1],"rb").read()
print(d[8]>>4, d[8]&15, d[9], struct.unpack_from("<I",d,12)[0], struct.unpack_from("<I",d,16)[0])
PY
)
case $CTRL in 6) C="DirectInput";; *) C="XInput";; esac
case $SCREEN in 6) S="Windowed";; *) S="Full Screen";; esac
case $VSYNC in 2) V="Disabled";; 4) V="Enable 1";; *) V="Enable 2";; esac
CUR="${W}x${H}"

first() { # put current value first so it is the default in the combo
  local cur="$1"; shift; local out="$cur"; for x in "$@"; do [ "$x" = "$cur" ] || out="$out|$x"; done; echo "$out"; }
RES=$(first "$CUR" 854x480 960x540 1280x720 1366x768 1600x900 1920x1080 1920x1200 2560x1440 3840x2160)

OUT=$(zenity --forms --title="$NAME - Settings" --width=420 \
  --text="Current: $CUR, $S, V-Sync $V, $C" \
  --add-combo="Resolution" --combo-values="$RES" \
  --add-combo="Screen mode" --combo-values="$(first "$S" "Full Screen" "Windowed")" \
  --add-combo="V-Sync" --combo-values="$(first "$V" "Enable 2" "Enable 1" "Disabled")" \
  --add-combo="Controller" --combo-values="$(first "$C" "XInput" "DirectInput")" \
  --separator="|" 2>/dev/null) || exit 0

python3 - "$DAT" "$OUT" <<'PY'
import sys,struct
p,out=sys.argv[1],sys.argv[2]
res,scr,vs,ctl=out.split("|")
w,h=map(int,res.split("x"))
d=bytearray(open(p,"rb").read())
c={"DirectInput":6,"XInput":7}[ctl]; s={"Windowed":6,"Full Screen":7}[scr]; v={"Disabled":2,"Enable 1":4,"Enable 2":8}[vs]
d[8]=(c<<4)|s; d[9]=v
struct.pack_into("<I",d,12,w); struct.pack_into("<I",d,16,h)
open(p,"wb").write(d)
print("saved:",res,scr,"V-Sync",vs,ctl)
PY
if zenity --question --title="$NAME" --text="Settings saved.\n\nLaunch the game now?" \
     --ok-label="Launch game" --cancel-label="Close" --width=300 2>/dev/null; then
  LAUNCHER="${SPFL_LAUNCHER:-$HOME/Games/launch-spfl$YY.sh}"
  if [ -x "$LAUNCHER" ]; then
    setsid nohup "$LAUNCHER" >/dev/null 2>&1 < /dev/null &
  else
    zenity --error --text="Launcher not found:\n$LAUNCHER" 2>/dev/null
  fi
fi
