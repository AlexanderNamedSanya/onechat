# OneChat

AI disclosure: this addon was generated with OpenAI Codex. Its Lua code and
translations received automated checks and source review, while full in-game acceptance and native-speaker localization review remain pending.
User screenshots and feedback informed the interface changes.

OneChat enhances the vanilla **PC keyboard chat** with independent incoming and
outgoing tab settings, temporary channel commands and whispers, guild labels,
message copying, and an optional primary-residence icon. Requires LibAddonMenu-2.0 version 43 or later. The installable folder is [OneChat](OneChat).

Status: **26.11.1 candidate for in-game acceptance**, targeting live API **101051**.
The mouse-driven configuration is not a console/gamepad interface.

## Install and use

Extract `dist/OneChat-26.11.1.zip` into the ESO `live/AddOns` folder, so that
`AddOns/OneChat/OneChat.txt` exists. Use the corresponding `pts/AddOns` folder for
PTS, provided its API matches. Enable OneChat in the character's addon list.

Open the existing chat tab options to configure **Incoming** and **Outgoing**.
All nested channels stay visible with indentation; Incoming is above Outgoing; each section uses two or three columns without scroll containers. Each guild name selects its guild channel, with an indented Officer entry; Incoming Zone combines the base zone and every official language zone; outgoing Zone selects only the base Zone channel. Language zones are excluded from outgoing settings and the channel selector. Group, Whisper and System appear as standalone channels without category headings.
Existing incoming selections are imported on first use; outgoing channels
default to enabled, subject to vanilla permissions and availability.

Choose a remembered channel using the native selector or an allowed guild label.
Manual commands and player-name whispers last until the next submitted message.
Cancelling or editing does not reset them. An empty tab shows `—`; ordinary
messages are blocked with the draft retained, while channel commands still work.
No OneChat action sends a message automatically.

Open Settings → Addons → OneChat, or use `/onechat` / **OneChat settings** in the vanilla tab context menu for
timestamps, a separate message line, guild abbreviations, and home-button
visibility. Changes to message appearance affect new messages.

Right-click text or a player name to copy the displayed message into a standard
selectable edit field; press Ctrl+C there. Existing player actions and embedded
item/achievement links are retained. Home and social actions use vanilla game
functions, with server rejection/error handling left intact.

## Persistence and compatibility

Account preferences and abbreviations use `ZO_SavedVars:NewAccountWide` with the
world name as the profile. Tab settings use `NewCharacterIdSettings`, also by
world, because native chat tabs are character-specific. Guild IDs follow guilds
through slot changes; previous abbreviations are retained if a guild is left.

Live window identity preserves preferences through renaming, reordering and
detaching tabs. Snapshots use native container/tab positions and names across
sessions; ESO exposes no persistent tab ID. If tabs are edited while OneChat is
disabled, mismatched snapshots are reimported from vanilla filters. Identically
named tabs reordered outside OneChat cannot be distinguished reliably.

Deleting a tab clears its preferences and copy history; a full native chat reset
clears OneChat tab preferences too. The native options Reset restores that tab's
default filters and OneChat outgoing defaults. Storage version stays stable;
the explicit schema migration preserves preferences and rejects newer schemas.

Hooks are restricted to chat lifecycle, input, menus and rendering. There is no
polling or per-frame event. Copy history is bounded per buffer by its native
history capacity and is never saved. The existing chat-message formatter is
chained to preserve native metadata/narration. A second addon replacing the same
formatter, input behavior or tab options can still conflict; test those
combinations individually. No code from another addon or third-party texture is
bundled.

## API limits and in-game acceptance

- ESO's text buffer has no public message-under-mouse query. Plain text and
  player/guild labels use local copy links; embedded native links keep their
  original payload and receive an appended Copy action. If the exact same
  native link occurs in multiple retained messages, the copy dialog lists all
  matches instead of guessing. Blank space beyond rendered text is not a
  message hit target. Preexisting buffer history is not retroactively wrapped.
- Travel to an unrelated player is unsupported. Travel to a reachable group
  member, friend or guild member uses vanilla social APIs. Offline state,
  combat, PvP, housing permissions and other server restrictions may still
  reject an action; OneChat does not bypass them.
- English is loaded first, followed by `lang/$(language).lua`. All seven files
  (`en`, `de`, `fr`, `ru`, `es`, `zh`, `jp`) contain actual translations of all
  33 custom strings. Native terminology is reused where available. Custom
  translations need native-speaker review; completeness is not linguistic QA.
- User screenshots informed the layout; full protected-send, interaction and compatibility
  acceptance has not been independently performed. In particular, verify context menus and
  copying on actual text buffers, dialog clipping at UI scales, the hardware
  Enter-key send path, guild permissions, tab transfer/reset, and housing
  errors before publishing this candidate as production-ready.

## Development checks

Python 3 and `lupa` (Lua 5.1 module) are development tools only:

```powershell
python -m pip install lupa
python tools/validate.py
git clone --depth 1 --branch live https://github.com/esoui/esoui.git .reference/esoui
python tools/validate.py --source .reference/esoui
python tools/package.py
```

The source-backed suite runs the inspected native chat parser, channel and
submission methods, real link helpers, native tri-state controls and SavedVars
wrapper against an emulated game boundary. It checks commands, cancel/draft
handling, empty output, whispers, tab isolation, guild slots, message formatting,
copy retention, settings, migrations and residence restrictions. It cannot prove
the private send path works under the real client's security model.

`tools/validate.py` checks Lua 5.1 syntax, strict UTF-8, all seven locales, key
coverage/duplicates, empty values, English copies, format placeholders and the
manifest. `tools/write_locales.py` is the translation authoring source.

## Source verification and attribution

Inspected upstream: [esoui/esoui live](https://github.com/esoui/esoui/tree/86832f7b492a5bd3e2774fe187caf1cc527735df),
commit `86832f7b492a5bd3e2774fe187caf1cc527735df` (2026-10-19), API 101051:

- `ESOUIDocumentation.txt`: chat, TextBuffer, control handlers, housing/social APIs.
- `esoui/ingame/chatsystem/{sharedchatsystem,chatoptions,chatdata,chathandlers}.lua`
  and keyboard/shared XML: native controls, categories, parser and formatter.
- `esoui/libraries/utility/{zo_linkhandler,zo_hook,zo_savedvars}.lua` and native
  button, edit, scroll and dialog templates: reusable behavior and controls.
- Native friends, group and guild roster menus: social and housing actions.

ESO and its built-in UI/art belong to ZeniMax Online Studios and their respective
owners. Only texture paths are referenced; upstream source/assets are excluded
from the release archive. Original OneChat code is MIT licensed.

Guidance consulted: [ESOUI release rules and practices](https://www.esoui.com/forums/showthread.php?t=10790),
[upload rules](https://www.esoui.com/forums/showthread.php?t=9),
[API limitations](https://www.esoui.com/forums/showthread.php?t=9865).
The manifest/localization wiki pages returned HTTP 403 during research; native
source and the forum's localization guidance were used to verify loading instead.
Check the current upload rules and client API before publication. Include this
AI disclosure and an actual in-game screenshot in the public addon listing.

Toolbar: home, reload UI and game UI language selection use original outline glyphs on a shared 32px grid, tinted with ZO_NORMAL_TEXT. Transparent DXT5 textures are generated by tools/build_icons.py and share the code license. Each button has independent visibility in LibAddonMenu. Language selection updates language.2 and reloads the interface; audio language is managed by the launcher.
