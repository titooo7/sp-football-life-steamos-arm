# SP Football Life 2026 / 2027 on SteamOS ARM (Konkr Pocket Fit, AYN Odin 2 and similar)

Run a **copy of SP Football Life 2026 or 2027 you already have** (SmokePatch, `FL_2026.exe` / `FL_2027.exe`) on an ARM handheld
running SteamOS, without Lutris (you can copy the pre-installed folder from your Windows PC).
Tested with SP Football Life 2026 on the Konkr Pocket Fit Gen3 (Snapdragon SM8650, Adreno 750! with game on the SteamOS partition) and with SP Football Life 2027 on
the AYN Odin 2 (Snapdragon SM8550, Adreno 740; with the game on the microSD card): menus, matches, Sider mods and the built-in controller
all work in **Game Mode**. Both editions use the same setup (same engine, PES 2021, same Sider loader).

Both editions can be installed side by side. Each one gets its own Wine prefix (so saves and settings stay separate), launcher,
settings tool, Desktop icons and Steam shortcuts. GE-Proton is downloaded once and shared.

The game itself is **not included**. You need your own working game folder (the one with `FL_2026.exe` or `FL_2027.exe`,
`SiderAddons/`, `Data/`).

## Quick start

1. Copy your game folder to one of these places (the script looks there; it does not copy the game for you):
   - **Internal memory, or a microSD card that SteamOS itself boots from:** `~/Games/SP Football Life 2027/`
     (e.g. `/home/steamos/Games/SP Football Life 2027/`; for 2026: `~/Games/SP Football Life 2026/`)
   - **A microSD card used only for storage (not a bootable SteamOS card):**
     `<card>/Non-Steam Games/SP Football Life 2027/`, e.g. `/run/media/steamos/MicroSD/Non-Steam Games/SP Football Life 2027/`
2. Copy this whole folder (it must keep `install-spfl.sh`, `spfl-settings.sh` and `artwork/` together) to the device.
3. Switch to **Desktop Mode**, open Konsole in that folder and run:
   ```
   chmod +x install-spfl*.sh
   ./install-spfl.sh
   ```
   It finds the game in those places. If it finds more than one (2026 and 2027, or the same game in two places), it
   lists them and asks which one to set up. Run it once per edition to install both. Other ways to run it:
   - `./install-spfl.sh 27` (or `./install-spfl27.sh`): only look for SP Football Life 2027 (`26` / `./install-spfl26.sh` for 2026)
   - `./install-spfl.sh "/path/to/SP Football Life 2027"`: game somewhere else (the edition is taken from the `.exe` in it)
4. When it asks, let it close Steam (needed to add the Game Mode shortcuts).
5. Switch to Game Mode and start **SP Football Life 2027** (or 2026) from *Library > Non-Steam*, or double-click the Desktop icon.

You also get a second shortcut, **SP Football Life 2027 - Settings** (or 2026), to change resolution, V-Sync and so on
(see "Changing settings" below).

Already set up SP Football Life 2026 with the old `install-spfl26.sh`? Nothing changes for it: the new script uses the same
prefix, launcher and shortcut names, so re-running it for 2026 updates them in place (no duplicates).

The script is safe to run again. It needs internet once (about 450 MB download) and about 3 GB of free space.

### Moved the game folder?

The launcher and shortcuts point to the folder the script found, so after moving the game (e.g. from internal
memory to the microSD card) it won't start. Run `./install-spfl.sh` again: it finds the new place and fixes the
launcher, Desktop icons and Steam shortcuts. Proton and the Wine prefix stay in internal memory and your settings
are kept. With the game on a storage microSD card, the card must be inserted to play.

## Requirements

- A SteamOS ARM image with **Box64** and x86 support already set up. Tested on **SteamOS for ARM v1.3** from
  [hashtagbasit/SteamOS-ARM-Port](https://github.com/hashtagbasit/SteamOS-ARM-Port/) on a Konkr Pocket Fit. Other builds may work if they provide Box64.
  Check with `box64 --version` and `cat /proc/sys/fs/binfmt_misc/box64`.
- `curl` and `python3` (normally already installed).

## Changing settings (resolution, full screen, V-Sync, controller)

Open the **SP Football Life 2027 - Settings** (or 2026) shortcut (Steam, Game Mode or Desktop icon), or run `~/Games/spfl27-settings.sh`
(`~/Games/spfl26-settings.sh` for 2026).
Close the game first, pick your values and press **OK**. It then asks **"Launch the game now?"**: choose **Launch game** to
play straight away, or **Close**. It works from Game Mode, so you never need to go back to Desktop Mode.

(This is a small replacement for the game's own `Settings.exe`, which needs .NET and crashes on ARM.)

## Tips

- **Use Game Mode to play.** In Desktop Mode some controller buttons don't work during matches.
- **Quit from the game's own menu.** Do not close the small black window or "Sider" from the taskbar: that can leave
  the game unable to start (see Troubleshooting).
- **Sider** is the mod loader behind the SmokePatch extras (stadiums, kits, anthems...). It starts by itself, you don't have to do
  anything. Its optional on-screen menu opens with the **Space** key (a keyboard is needed).
- **Speed:** the game is limited by the CPU (x86 emulation), not the GPU, so lowering the resolution barely helps. The launcher therefore sets
  these Box64 flags: `STRONGMEM=0 FASTNAN=1 FASTROUND=1 CALLRET=1 WEAKBARRIER=0` (all `BOX64_DYNAREC_*`). On the Konkr they took the game from
  about 40-45 fps to a steady 60 fps at 1080p. If a device has crashes or glitches, delete that line from `~/Games/launch-spfl27.sh` (or `launch-spfl26.sh`).
- **V-Sync is disabled by default** (with Enable 2 the game was held back below what the device can do). You can change it in the Settings shortcut.
- **Smoother with a fixed frame rate:** the script doesn't set a cap, but locking the rate to your screen helps. Add `export DXVK_FRAME_RATE=60`
  to `~/Games/launch-spfl26.sh` (before the last line, `exec ...`) and set the refresh rate to **120 Hz** in the quick access menu. If your device only
  reaches about 45 fps, use `45` with **90 Hz** instead (45 divides evenly into 90).
- **Frame generation (Lossless Scaling / lsfg-vk via Decky):** it loads into the game (the launcher passes Steam's app ID on, so per-game
  profiles match), but in my tests on the Konkr it did **not** help: 2x only reached a steady 60 with visible artifacts on the ball,
  and 3x/4x was worse. Your device or settings may give better results, so it is worth a try, but don't expect miracles.
- **Don't try more aggressive Box64 options** such as `BOX64_DYNAREC_BIGBLOCK=3` or `BOX64_DYNAREC_SAFEFLAGS=0`: they make the match never finish loading.
- Leave the Steam overlay **off** for these shortcuts (the script already does this).
- Gameplay "Switcher": the Windows `FL26 switcher.exe` needs .NET and wasn't tested on ARM. eskay993's repo has a bash version
  (`FL_2026_Switcher-Linux.zip`, needs `yad`): https://github.com/eskay993/gamefiles/tree/main/sp-football-life-2026

## Troubleshooting

File names below use 2026. For 2027, replace `26` with `27` and `2026` with `2027` (e.g. `~/Games/SPFL27-prefix`,
`launch-spfl27.sh`, `fl_2027.exe-*`).

- **The game hangs on a black window saying "Launching sider... sider active... Launching FL..." (or on a small grey window in
  Game Mode), one CPU core at 100%.** Usually caused by closing the game or Sider from the taskbar instead of quitting normally.
  Box64 keeps a code cache for the game and a broken one makes the next launch spin forever. Fix, in Desktop Mode (Konsole):
  1. Stop everything left over: `WINEPREFIX=~/Games/SPFL26-prefix/pfx ~/x86ge/GE-Proton9-27/files/bin/wineserver -k`
  2. Move the game's cache files away (they are rebuilt on the next launch, so the first start is a bit slower):
     ```
     mkdir -p ~/box64-cache-aside
     mv ~/.cache/box64/fl_2026.exe-* ~/.cache/box64/sider.* ~/.cache/box64/ddraw.dll-* ~/box64-cache-aside/
     ```
  3. Start the game again.
- **Game never opens, one CPU core at 100%, and you didn't close anything:** wrong Proton version (see the table below) or
  the `PROTON_NO_*SYNC` variables are missing from `~/Games/launch-spfl26.sh`.
- **Black screen with sound in Game Mode:** make sure `ENABLE_GAMESCOPE_WSI=0` is in `~/Games/launch-spfl26.sh`.
- **Start from scratch:** delete `~/Games/SPFL26-prefix` and run the script again. This also deletes your saves, so back up
  `~/Games/SPFL26-prefix/pfx/drive_c/users/steamuser/Documents/KONAMI/` first.
- **Updating the game (SmokePatch `SPFL26_XXX.exe` / `SPFL27_XXX.exe` updates):** install the update on a Windows PC, copy the changed files over the
  game folder on the device, then run the script again (safe).
- Keep a backup copy of the game folder somewhere safe: the script does not install the game itself.

## How it works (for doing it by hand, or if you are curious)

The script does this (shown for 2026; for 2027 every `26`/`2026` becomes `27`/`2027`):

1. Downloads **GE-Proton9-27 (x86_64 build)** from the GloriousEggroll releases, checks its SHA-512 and extracts it to `~/x86ge/`.
2. In the game folder: copies `xinput1_3.dll` to `ddraw.dll` (this is how Sider hooks in, same as the Lutris script
   does) and writes `FL_2026.bat` (starts `SiderAddons\sider.exe`, waits for its log, then starts `FL_2026.exe`).
3. Writes `~/Games/launch-spfl26.sh`, which runs `proton run FL_2026.bat` with:
   - `WINEDLLOVERRIDES="ddraw=n,b;steam_api64=n,b;lsteamclient=d"`
   - `PROTON_NO_ESYNC=1 PROTON_NO_FSYNC=1 PROTON_NO_NTSYNC=1` (needed: Wine under Box64 deadlocks on ntsync)
   - `PROTON_USE_XALIA=0`, `ENABLE_GAMESCOPE_WSI=0`
   - the Wine prefix in `~/Games/SPFL26-prefix`
4. Creates that prefix and installs a default `settings.dat` (XInput, Full Screen, V-Sync disabled, 1920x1080) into
   `…/pfx/drive_c/users/steamuser/Documents/KONAMI/eFootball PES 2021 SEASON UPDATE/`.
5. Installs the settings tool `~/Games/spfl26-settings.sh` (a copy of `spfl-settings.sh` set to that edition).
6. Creates two Desktop icons and two non-Steam shortcuts (overlay off): **SP Football Life 2026** and
   **SP Football Life 2026 - Settings**. It installs the Steam library artwork from `artwork/2026/` (game) and `artwork/2026/settings/`
   (Settings) under each shortcut's ID. There is no `artwork/2027/` yet: SP Football Life 2027 gets a generic icon and
   no library images until you add that folder (same file names) or pick images in Steam. Existing images are never overwritten, so you can replace them later with the
   Decky SteamGridDB plugin.

### Why GE-Proton 9 + Box64 (don't "upgrade")

All of these were tried and **fail** for SP Football Life 2026 on the Konkr (2027 uses the same working setup):

| Attempt | Result |
|---|---|
| Valve Proton 11 / Experimental (ARM64, FEX) | `FL_2026.exe` hits an invalid instruction (`0F 3E`) in its protector, FEX loops on the exception and the game never opens |
| Proton-CachyOS and GE-Proton 11 ARM64 (FEX) | same crash |
| GE-Proton 11 x86_64 via Box64 | spins forever at 100% on one thread, never opens a window |
| **GE-Proton 9-27 x86_64 via Box64** | **works** |

The SPFL community also reports that Wine/GE-Proton newer than Wine 10.16 / GE-Proton 10 break the Steam API
hooks this game relies on, so stay on 9.x.

## License

The script and documentation are released under the [MIT License](LICENSE): use, copy, modify and share freely.
The images in `artwork/` are **not** covered by it (third-party artwork, see `artwork/README.md`).
SP Football Life 2026 / 2027 itself is not included and is not part of this project; get it from SmokePatch.
This project is not affiliated with SmokePatch, Konami or Valve.

## Credits

- [SmokePatch](https://www.pessmokepatch.com/): SP Football Life (the game and mod).
- [GloriousEggroll](https://github.com/GloriousEggroll/proton-ge-custom): GE-Proton.
- [ptitSeb](https://github.com/ptitSeb/box64): Box64, which makes x86 programs run on ARM.
- [eskay993](https://github.com/eskay993/gamefiles/tree/main/sp-football-life-2026): the original Lutris/Wine script for
  SPFL 2026 on Linux. The `ddraw.dll` trick for Sider, the launcher `.bat`, the DLL overrides and the settings-file layout come from there.
- The SPFL community thread on [evoweb](https://evoweb.uk/threads/sp-fl-2026-on-linux.106593/), which pointed to Wine/GE-Proton 9.x
  as the working version.
- SteamGridDB and its community artists: the Steam artwork (see `artwork/README.md`).
- [hashtagbasit](https://github.com/hashtagbasit/SteamOS-ARM-Port/) and contributors: the SteamOS ARM port (v1.3) with the Box64 / x86 setup this relies on.
