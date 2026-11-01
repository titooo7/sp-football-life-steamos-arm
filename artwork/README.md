# Artwork notice

The images in this folder (`2026/`: grid, portrait, hero, logo, icon) are Steam library artwork
for SP Football Life 2026, obtained through the SteamGridDB plugin for Decky Loader.
They were created by third parties (SteamGridDB community artists / game rights holders).

- They are **not** covered by this repository's MIT license, and the repository owner makes no
  claim over them. Their original authors and rights holders keep all rights.
- They are included only for convenience so the installer can set up the Steam library entry.
- If you are an author or rights holder and want an image removed, open an issue and it will be taken down.
- You can delete this folder: `install-spfl.sh` simply skips the artwork step, and you can pick your own
  images in Steam or with the Decky SteamGridDB plugin.

The `2027/` set was made for this project:
- `grid.png`, `portrait.png`, `hero.png` show seven players cut out of Wikimedia Commons photos by Bryan Berlin
  (CC BY-SA 4.0), placed on an original stadium drawing. These three images are licensed **CC BY-SA 4.0**; photo credits
  and links are in `2027/CREDITS.md`. Rebuild them with `compose-players.py` (see the notes at the top of that file).
- `logo.png`, `icon.png` and everything in `2027/settings/` were drawn from scratch by `make-artwork.py` (no third-party
  images) and are covered by this repository's MIT license like the scripts.

To make a set for another edition: `python3 artwork/make-artwork.py 2028` (needs Pillow and the Fira Sans fonts; it draws
the plain stadium version with no players). Careful: `make-artwork.py 2027` would replace the 2027 player images with
the plain version. Any folder named after a year (e.g. `2028/`, plus `2028/settings/`) with the same file names is picked
up by the installer.
