# Audio Credits

All audio assets below are licensed **CC0 (Public Domain)**. Attribution is
not legally required, but we credit the creators as a courtesy.

## Music

| File                          | Title                      | Creator           | Source                                                         |
|-------------------------------|----------------------------|-------------------|----------------------------------------------------------------|
| `music/cavern_ambient.ogg`    | Dark Cavern Ambient (loop) | Paul Wortmann     | https://opengameart.org/content/dark-cavern-ambient            |
| `music/determined_pursuit.ogg`| Determined Pursuit         | Emma_MA           | https://opengameart.org/content/determined-pursuit-epic-orchestra-loop |
| `music/epic_boss.ogg`         | Epic Boss Battle           | Juhani Junkala    | https://opengameart.org/content/boss-battle-music              |

Tracks are tiered by wave intensity (see `MUSIC_TIER_MID` / `MUSIC_TIER_PEAK`
in `scripts/autoload/audio_manager.gd`):

- Waves 1–7   → Cavern Ambient (calm)
- Waves 8–14  → Determined Pursuit (mid)
- Waves 15–20 → Epic Boss Battle (peak)

Original WAV sources were re-encoded to Ogg Vorbis (`oggenc -q 3`,
~112 kb/s avg) to shrink size from ~40 MB to ~3 MB total.
