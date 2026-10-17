# Cawenda Rename Design

## Understanding Summary

- Rename the product from Cawernda to Cawenda across the app, Swift package, source layout, build scripts, tests, and documentation.
- Keep existing reminders and preferences visible after the rename.
- Give users a direct way to open the folder used for custom alarm sounds.
- Continue supporting local MP3 discovery without adding an importer or managed sound library.
- Keep the Git remote unchanged.

## Assumptions

- The rename does not require a new application identity or bundle identifier.
- Existing `Cawernda.*` preference keys are implementation details and may remain unchanged for compatibility.
- User sound collections are small and can be rescanned when Cawenda becomes active.
- MP3 remains the only supported custom sound format.

## Final Design

The Swift package, executable, source and test directories, application bundle, and visible branding use Cawenda. The existing bundle identifier and UserDefaults keys remain unchanged so macOS and the app continue to find existing data.

Custom sounds live in `~/Library/Application Support/Cawenda/Sounds/`. Settings exposes an **Open Sounds Folder** button that creates and opens this directory. On first access, MP3 files from the former Cawernda directory are copied into the new directory without overwriting newer files. The sound picker refreshes when the app becomes active again.

## Decision Log

- Selected a full technical rename instead of a display-name-only alias because the project itself should consistently use Cawenda.
- Retained the bundle identifier and persisted preference keys to avoid a risky data migration.
- Selected **Open Sounds Folder** instead of **Add** because it accurately describes the Finder-based workflow.
- Selected non-destructive legacy sound copying instead of moving or deleting files.
