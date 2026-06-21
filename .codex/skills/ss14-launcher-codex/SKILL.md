---
name: ss14-launcher-codex
description: Expert coding guidance for the Space Station 14 launcher repository. Use when Codex edits, reviews, debugs, tests, refactors, or plans code in SS14.Launcher, SS14.Loader, SS14.Launcher.Bootstrap, Robust.LoaderApi, build scripts, Avalonia XAML, localization, SQLite migrations, updater, authentication, server browser, content download, process launch, packaging, or release workflows.
---

# SS14 Launcher Codex

## Mission

Write launcher code that fits this repository instead of generic .NET code. Preserve the launcher's user data, authentication, content integrity, cross-platform behavior, and startup path. Make narrow, tested changes that match existing patterns.

## Codex Operating Mode

- Inspect before editing. Use rg, rg --files, project files, nearby tests, and existing call sites before deciding on shape.
- Prefer patch-based edits and keep diffs scoped to the files required by the request.
- Do not rewrite broad areas, reformat unrelated XAML, upgrade dependencies, or change packaging unless the request requires it.
- Do not revert unrelated user changes. If a file is already modified, understand it and build on it.
- Prefer concrete implementation plus validation over long design discussion unless the user asks for planning.
- When behavior crosses auth, updater, loader signatures, SQLite migrations, platform packaging, or user data, state the risk and verify more aggressively.

## Repository Map

- `SS14.Launcher/`: Avalonia desktop launcher. Owns UI, view models, API clients, login state, server list, updater orchestration, app paths, localization, SQLite-backed settings, content DB coordination, and process launch.
- `SS14.Loader/`: minimal loader executable. Verifies signed engine zips, loads `Robust.Client`, mounts content DB and overlay zips, and passes launcher/redial APIs into Robust.
- `SS14.Launcher.Bootstrap/`: Windows native AOT bootstrap targeting `net10.0-windows`; keep it small and platform-specific.
- `Robust.LoaderApi/`: contract used between loader and Robust client. Treat changes here as cross-project compatibility changes.
- `SS14.Launcher.Tests/`: NUnit tests. Add focused coverage here for parsing, migrations, filters, updater metadata, and pure model logic.
- `Directory.Packages.props`: central NuGet versions. Do not add inline package versions to `.csproj` files.
- `Launcher.props`: shared `TargetFramework` and launcher `Version`.
- `publish.py`, `download_net_runtime.py`, `exe_set_subsystem.py`, `PublishFiles/`, `.github/workflows/`: release and packaging surface.

## Build Invariants

- The main target framework is defined in `Launcher.props` as `net10.0`. If changing it, audit and update at least:
  - `publish.py` `TFM`
  - `download_net_runtime.py`
  - dev loader path logic in `SS14.Launcher/Models/Connector.cs`
  - `.github/workflows/build-test.yml`
  - `.github/workflows/publish-release.yml`
- `FullRelease=True` adds `FULL_RELEASE`; otherwise development builds define `DEVELOPMENT`. Do not accidentally remove dev-only behavior such as the development tab.
- `UseSystemSqlite=True` matters on FreeBSD and changes package/provider behavior. Keep conditional SQLite package references consistent across launcher and loader.
- Keep `Robust.Trimming.targets`, `RobustLinkRoots`, and `RobustLinkAssemblies` in mind when changing reflection-heavy, trimming-sensitive, or dynamically loaded code.
- Prefer central package updates in `Directory.Packages.props`; justify new dependencies and avoid adding libraries for small helpers.

## Coding Style

- Follow `.editorconfig`: 4 spaces generally, 2 spaces for XAML, YAML, `.csproj`, and props.
- Keep nullable correctness. This repository uses `<Nullable>enable</Nullable>` in main projects.
- Use file-local style already present in neighboring files. Do not convert large areas to a different expression-bodied, LINQ-heavy, or pattern-matching style just because it is possible.
- Use structured Serilog messages: `Log.Warning(e, "Message {Property}", value)`. Never log access tokens, auth tokens, private keys, or full command lines containing secrets.
- Prefer explicit records/classes matching existing model shapes. Keep serialization attributes such as `JsonPropertyName` when API names differ from C# names.
- Keep comments only where they explain non-obvious constraints, platform workarounds, security decisions, or historical traps.

## Avalonia UI And MVVM

- Put UI in `Views/` XAML plus code-behind only when UI behavior requires it. Put state and commands in `ViewModels/`.
- Preserve the `ViewLocator` convention: view model type names map to view type names by replacing `ViewModel` with `View`.
- Use existing ReactiveUI patterns:
  - `[Reactive]` for simple mutable bindable properties.
  - `this.RaiseAndSetIfChanged` for manual backing fields.
  - `this.RaisePropertyChanged(nameof(...))` for computed properties.
  - `WhenAnyValue`, `Throttle`, and `ObserveOn(RxApp.MainThreadScheduler)` for UI-bound reactive updates.
- Keep collection changes that affect bound UI on the UI thread. Be careful with `ObservableCollection<T>` and server-list refresh paths.
- In XAML, use existing theme resources, classes, margins, `IconLabel`, and `loc:Loc` patterns. Do not introduce a new design language.
- Include design-time data context when adding new view models if nearby views do so.
- Do not hard-code visible strings in XAML or view models unless the surrounding area already intentionally does that for dev-only UI.

## Localization

- User-facing strings belong in Fluent files under `SS14.Launcher/Assets/Locale/.../text.ftl`.
- Add or update the fallback `en-US` string first. Do not bulk-edit translated locales unless explicitly requested; Weblate likely owns most translations.
- Use stable, descriptive keys matching nearby groups, for example `tab-options-...`, `connecting-status-...`, or `server-entry-...`.
- Use `LocalizationManager.GetString(key, ("arg", value))` and Fluent variables for dynamic values. Do not concatenate localized sentence fragments.
- If adding a new supported language, update `LocalizationManager.AvailableLanguages` and the asset folder naming rules, remembering that some folders use underscores such as `zh_Hans`.

## Data And SQLite

- `DataManager` owns persistent settings, favorites, logins, hubs, filters, installed engines, modules, and privacy-policy acceptance.
- Any persistent schema change needs a migration named in order, such as `Script0008_Name.sql` or `Script0008_Name.cs`, in the correct `Migrations` namespace/folder.
- Migrations are embedded resources. Confirm the `.csproj` includes the migration folder pattern before adding a new migration type.
- Keep migrations idempotent only where practical, but never reorder or rename existing scripts because `SchemaVersions.ScriptName` tracks applied scripts.
- Use Dapper parameters. Do not string-interpolate SQL values.
- Preserve transaction behavior in `Migrator`: savepoint per script, rollback on failure, commit after all successful scripts.
- When queueing DB writes from mutable objects, copy the values first as existing code does. This avoids later mutation changing what is written.
- Content DB code uses WAL, foreign keys, BLOB streaming, and `Pooling=False`. Avoid loading large content files fully into memory.

## Networking And APIs

- Prefer the shared `HttpClient` registered in Splat and created by `HappyEyeballsHttp.CreateHttpClient()`. Do not create ad hoc clients except in diagnostics or narrowly scoped tests.
- Pass `CancellationToken` through network, download, update, and process-start flows.
- Catch errors at API boundaries and map them to launcher states where the UI expects a controlled failure. Keep unexpected exceptions visible in logs.
- Use `System.Net.Http.Json` where existing APIs do, but validate null responses and malformed JSON.
- Preserve URL fallback behavior via `UrlFallbackSet` and URI normalization through `UriHelper`.
- For server addresses, maintain support for `ss14://`, `ss14s://`, host-only input, default port `1212`, and path-preserving API URL construction.

## Authentication And Privacy

- Treat login tokens, refresh tokens, account IDs paired with tokens, and auth server responses as sensitive.
- Do not log tokens or include them in thrown exception messages.
- Keep auth error mapping user-friendly and localized. Internal details belong in structured logs only when safe.
- Preserve privacy policy acceptance semantics: identifier and version both matter, and changed versions must prompt again.
- Do not weaken hub trust warnings. Hubs can spoof servers from other hubs, and priority order matters.

## Updater, Content, And Loader

- Treat engine signature verification as a security boundary. Do not bypass Ed25519 verification in release code.
- `SS14_DISABLE_SIGNING` is for debug/development paths only. Do not make it effective in release builds.
- Preserve `signing_key` handling and the loader argument contract: robust zip path, signature, public key, then engine args.
- Use `ProcessStartInfo.ArgumentList` and environment variables instead of shell-concatenated command strings.
- Keep loader environment variable names exact: `SS14_LOADER_CONTENT_DB`, `SS14_LOADER_CONTENT_VERSION`, `SS14_LOADER_OVERLAY_ZIP`, `SS14_LAUNCHER_PATH`, module env vars, and DOTNET tuning vars.
- Overlay zips must mount before normal content so overlays mask base files.
- Be careful with content bundles and replays. Large zip files are common, and comments in `Connector` explain tradeoffs that should not be casually rewritten.
- Keep `SS14.Loader` minimal. Avoid adding UI, launcher service dependencies, or network calls there unless the loader contract truly requires it.

## Platform Rules

- Windows:
  - Respect minimum supported Windows checks and `VcRedistCheck`.
  - Keep bootstrap AOT Windows-specific.
  - Preserve subsystem changes done by `exe_set_subsystem.py`.
- Linux and FreeBSD:
  - Respect executable bits and `UseSystemSqlite` behavior.
  - Do not assume Windows path separators or drive roots.
- macOS:
  - Preserve app bundle layout in `PublishFiles/Space Station 14 Launcher.app`.
  - Keep quarantine-clearing and architecture selection behavior in `Connector.GetLoaderStartInfo()`.
  - Be careful with Apple Silicon and Rosetta warnings.
- Wine:
  - Keep Wine detection and messaging conservative; do not block users from continuing unless existing behavior does.

## Async And Concurrency

- Prefer `Task` returning methods. Use `async void` only for UI event handlers or existing fire-and-forget patterns, and wrap bodies in try/catch when failures would otherwise disappear.
- Keep cancellation meaningful. If a method accepts a token, pass it to I/O and delay operations.
- Avoid blocking the UI thread with downloads, hashing, database work, DNS, process waits, or zip processing.
- Dispose streams, `SqliteConnection`, transactions, `ZipArchive`, processes, and file handles deliberately.
- When using `Task.Run`, make sure it is for real CPU/blocking work and not to hide missing async APIs.

## Server Browser And Filters

- Server list operations can be large and frequent. Keep search/filter/sort paths efficient and avoid repeated expensive allocations if touching refresh logic.
- Preserve throttling for search text updates.
- When adding filters, update:
  - filter model and persistence
  - migration if stored
  - view model text and counts
  - XAML controls
  - localization keys
  - tests for matching and persistence where feasible

## Release And Packaging

- For version changes, audit `Launcher.props`, packaging scripts, runtime download scripts, local dev launch paths, and workflows.
- For new runtime IDs, update publish layout, dependency runtime download paths, loader placement, and archive naming.
- Do not change release archive structure casually; external distribution and updater expectations may depend on it.
- Keep publish scripts shell-safe by passing argument arrays to subprocess APIs.

## Testing Strategy

- Add NUnit tests in `SS14.Launcher.Tests` for pure logic, parsing, migrations, filtering, sorting, API result mapping, and updater metadata.
- Use `[TestFixture]`, `[Test]`, `[TestCase]`, and `[Parallelizable]` consistently with existing tests.
- Use temporary directories or `SS14_LAUNCHER_APPDATA_NAME=launcherTest` for tests or manual runs that touch user data.
- Prefer small deterministic tests over network-dependent tests. Mock or isolate HTTP where possible.
- For migration tests, verify both fresh DB creation and upgrade from the prior schema when practical.

## Validation Commands

Run the strongest set that matches the change:

```powershell
dotnet restore
dotnet build --configuration Release --no-restore
dotnet test SS14.Launcher.Tests/SS14.Launcher.Tests.csproj -v n
```

For app-data touching manual runs:

```powershell
$env:SS14_LAUNCHER_APPDATA_NAME = "launcherTest"
dotnet run --project SS14.Launcher/SS14.Launcher.csproj
```

For packaging-sensitive changes, also inspect or run the relevant part of:

```powershell
& .\publish.py windows --x64-only
& .\publish.py linux --x64-only
& .\publish.py osx
```

## Change Checklist

Before finishing:

- Confirm the change belongs in the selected project and layer.
- Confirm user-facing text is localized.
- Confirm persistent data changes have migrations.
- Confirm auth, token, signing, and content-integrity boundaries were not weakened.
- Confirm platform-specific code has guards such as `OperatingSystem.IsWindows()` or `RuntimeInformation.IsOSPlatform(...)`.
- Confirm large downloads, content DB, and zip paths avoid unnecessary full-memory buffering.
- Confirm tests or a clear test gap are reported.
