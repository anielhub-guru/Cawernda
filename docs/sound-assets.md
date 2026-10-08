# Sound Asset Design

## Understanding

- Pixabay-derived audio must not be distributed as standalone files in the public repository.
- Cawernda must continue to demonstrate working alarm playback out of the box.
- Three creator-owned MP3 files may be committed and distributed as defaults.
- Developers can add ignored MP3 files before packaging.
- Installed-app users can add MP3 files without rebuilding.

## Assumptions

- MP3 is the only supported format.
- Sounds remain local; Cawernda never downloads or uploads audio.
- Collections are small enough for direct directory scanning.
- Missing or unreadable selections safely behave as No Sound.

## Final Design

Cawernda merges MP3 files from its bundled `sounds` resource directory and `~/Library/Application Support/Cawernda/Sounds/`. Filenames are matched case-insensitively, and the user-installed file wins on a collision. Build scripts copy any MP3 files present in the project `sounds` directory and succeed when no optional files exist.

The repository ignores all MP3 files except `default-1.mp3`, `default-2.mp3`, and `default-3.mp3`. Historical Pixabay paths are removed from every published commit.

## Decision Log

- Chose direct filesystem discovery over a managed import interface.
- Supported both source-build and installed-app customization.
- Retained three creator-owned defaults for immediate functionality.
- Chose user-installed precedence for predictable customization.
- Chose history rewriting because deleting only current files would leave standalone audio publicly downloadable.
