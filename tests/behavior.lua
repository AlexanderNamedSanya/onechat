-- Uses the inspected vanilla parser, submission and channel methods. Only the
-- game engine/UI boundary is stubbed. This is not an in-game acceptance test.
checks = 0
local function eq(a, b, message)
    checks = checks + 1
    assert(a == b, (message or "mismatch") .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end
local function ok(value, message) eq(not not value, true, message) end
local function loadAddon(name) assert(loadfile(addon_root .. "/" .. name))() end

local stringValues = {}
function ZO_CreateStringId(id, value) _G[id] = id; stringValues[id] = value end
function SafeAddString(id, value) stringValues[id] = value end
function GetString(id, category) return stringValues[id] or tostring(category or id) end
loadAddon("lang/en.lua")
setmetatable(_G, { __index = function(_, key)
    if key:match("^SI_") then return key end
end })
zo_strfind, zo_strsub, zo_strlen = string.find, string.sub, string.len
function zo_strformat(format, ...)
    format = GetString(format)
    local args = { ... }
    if format == "SI_UNIT_NAME" or format == "SI_CHAT_MESSAGE_FORMATTER" then return args[1] end
    return (format:gsub("<<(%d+)>>", function(index) return tostring(args[tonumber(index)]) end))
end
function zo_strjoin(delimiter, ...)
    local result = { ... }
    for index, value in ipairs(result) do result[index] = tostring(value) end
    return table.concat(result, delimiter)
end
function zo_strsplit(delimiter, text)
    local result = {}
    for part in (text .. delimiter):gmatch("(.-)" .. delimiter) do result[#result + 1] = part end
    return unpack(result)
end
ZO_CallbackObject = {}
function ZO_CallbackObject:New()
    return { callbacks = {}, RegisterCallback = function(self, key, callback) self.callbacks[key] = callback end }
end
assert(loadstring(link_source))()
assert(loadstring(hook_source))()
function SecurePostHook(object, key, callback)
    local original = assert(object[key], key)
    object[key] = function(...)
        local result = { original(...) }
        callback(...)
        return unpack(result)
    end
end

MOUSE_BUTTON_INDEX_LEFT, MOUSE_BUTTON_INDEX_RIGHT = 1, 2
LINK_STYLE_DEFAULT, LINK_STYLE_BRACKETS = 0, 1
DISPLAY_NAME_PREFIX_BYTE = 64
MAX_GUILDS = 5
CHAT_CHANNEL_SAY, CHAT_CHANNEL_YELL, CHAT_CHANNEL_ZONE = 1, 2, 3
CHAT_CHANNEL_EMOTE, CHAT_CHANNEL_PARTY = 4, 5
CHAT_CHANNEL_WHISPER, CHAT_CHANNEL_WHISPER_SENT = 6, 7
CHAT_CHANNEL_MONSTER_SAY, CHAT_CHANNEL_MONSTER_YELL = 8, 9
CHAT_CHANNEL_MONSTER_WHISPER, CHAT_CHANNEL_MONSTER_EMOTE = 10, 11
CHAT_CATEGORY_WHISPER_INCOMING, CHAT_CATEGORY_WHISPER_OUTGOING = 106, 107
CHAT_CATEGORY_SYSTEM = 200
for index = 1, 5 do
    _G["CHAT_CHANNEL_GUILD_" .. index] = 20 + index
    _G["CHAT_CHANNEL_OFFICER_" .. index] = 25 + index
end
OFFICIAL_LANGUAGE_ITERATION_BEGIN, OFFICIAL_LANGUAGE_ITERATION_END = 0, 6
ZO_OFFICIAL_LANGUAGE_TO_CHAT_INFO = {}
for index = 0, 6 do ZO_OFFICIAL_LANGUAGE_TO_CHAT_INFO[index] = { channel = 40 + index, category = 140 + index } end
function GetChannelCategoryFromChannel(channel) return channel + 100 end
local guilds, grouped, restricted = { 101, 202 }, true, {}
function GetNumGuilds() return #guilds end
function GetGuildId(index) return guilds[index] end
function GetGuildName(id) return "Guild " .. id end
function IsChannelCategoryCommunicationRestricted(category) return restricted[category] == true end
local categorySettings = {}
function IsChatContainerTabCategoryEnabled(container, index, category)
    return categorySettings[container .. ":" .. index .. ":" .. category] ~= false
end
function IsDecoratedDisplayName(name) return name:sub(1, 1) == "@" end
function UndecorateDisplayName(name) return name:gsub("^@", "") end
function DecorateDisplayName(name) return "@" .. UndecorateDisplayName(name) end
function ZO_FormatUserFacingDisplayName(name) return name end
function GetChannelName(channel) return "Channel " .. channel end
function GetChatChannelId(name) return tonumber(name:match("(%d+)$")) end
function ZO_ChatSystem_GetCategoryColorFromChannel() return 0.2, 0.4, 0.6 end
ZO_ColorDef = { New = function() return {} end }
local menus, sent, alerts = {}, {}, {}
function ClearMenu() menus = {} end
function AddMenuItem(text, callback) menus[#menus + 1] = { text = text, callback = callback } end
function ShowMenu() end
function ZO_Alert(_, _, text) alerts[#alerts + 1] = text end
SOUNDS = {}
function IsChatSystemAvailableForCurrentPlatform() return true end
function GetTrialChatIsRestrictedAndWarn() end
function ZO_Menu_SetLastCommandWasFromMenu() end
function SendChatMessage(text, channel, target) sent[#sent + 1] = { text = text, channel = channel, target = target } end
function GetGuiHidden() return false end
function DoesGameHaveFocus() return true end
function IsPlayerActivated() return true end
function IgnoreMouseDownEditFocusLoss() end

SharedChatSystem, SharedChatContainer, TextEntry = {}, {}, {}
local function native(name)
    local start = assert(native_source:find("function " .. name .. "(", 1, true), name)
    local finish = assert(native_source:find("\nend", start, true), name)
    assert(loadstring(native_source:sub(start, finish + 3)))()
end
for _, name in ipairs({ "ValidateSwitch", "TextToSwitchData", "OnTextEntryChanged", "SubmitTextEntry",
    "SetChannel", "SetChannelInternal", "ValidateChatChannel", "StartTextEntry", "CloseTextEntry" }) do
    native("SharedChatSystem:" .. name)
end
for _, name in ipairs({ "SetChannel", "SetColor" }) do native("TextEntry:" .. name) end

local function uiControl()
    return { text = "", GetHandler = function() end, SetHandler = function() end, SetText = function(self, text) self.text = text end,
        GetText = function(self) return self.text end,
        SetColor = function() end, SetDimensionConstraints = function() end }
end
local data = {}
for index = 1, 50 do
    data[index] = { id = index, playerLinkable = true, format = "format" }
end
data[CHAT_CHANNEL_MONSTER_SAY].playerLinkable = false
data[CHAT_CHANNEL_PARTY].requires = function() return grouped end
data[CHAT_CHANNEL_WHISPER].target = true
local switches = {}
for command, channel in pairs({ ["/say"] = 1, ["/zone"] = 3, ["/group"] = 5, ["/w"] = 6 }) do
    switches[command] = data[channel]
    switches[channel] = command
end
for index = 1, 2 do
    for _, kind in ipairs({ "GUILD", "OFFICER" }) do
        local channel = _G["CHAT_CHANNEL_" .. kind .. "_" .. index]
        local command = "/" .. kind:lower() .. index
        switches[command], switches[channel] = data[channel], command
    end
end
local textEntry = setmetatable({ text = "", opened = false, channelLabel = uiControl(), editControl = uiControl() }, { __index = TextEntry })
function textEntry:GetText() return self.text end
function textEntry:SetText(text) self.text = text end
function textEntry:Close(keep) self.opened = false; if not keep then self.text = "" end end
function textEntry:Open(text) self.opened = true; if text then self.text = text end end
function textEntry:IsOpen() return self.opened end
function textEntry:AddCommandHistory() end
function textEntry:GetCursorPosition() return #self.text end
function textEntry:SetCursorPosition() end
function textEntry:CloseAutoComplete() end
function textEntry:GetEditControl() return self.editControl end
function textEntry:GetControl() return self.editControl end
function textEntry:AutoCompleteTarget() end
function textEntry.editControl:TakeFocus() end
local chat = setmetatable({ textEntry = textEntry, channelData = data, switchLookup = switches,
    commandPrefixes = { [47] = function() end }, targets = {},
    ShowTextEntryMenu = function() end, OnLinkClicked = function() end,
    TransferWindow = function() end,
    ResetChat = function() end,
}, { __index = SharedChatSystem })
function chat:GetDefaultChatChannel() return CHAT_CHANNEL_SAY end
function chat:ShouldTextEntryBeBlocked() return false end
function chat:UpdateTextEntryChannel() self.textEntry:SetChannel(data[self.currentChannel], self.currentTarget) end
function chat:IsMinimized() return false end
CHAT_ROUTER = { SetCurrentChannelData = function(_, channel, target) chat:SetChannelInternal(channel.id, target) end }
local function window(name, index)
    return { name = name, tab = { index = index, GetHandler = function() end, SetHandler = function() end }, buffer = { GetMaxHistoryLines = function() return 3 end } }
end
local first, second = window("First", 1), window("Second", 2)
local container = { id = 1, system = chat, windows = { first, second },
    tabGroup = { GetClickedButton = function() return first.tab end }, FadeIn = function() end }
function container:GetTabName(index) return self.windows[index].name end
function GetNumChatContainerTabs() return #container.windows end
function container:SetWindowFilterEnabled(index, category, checked)
    categorySettings[self.id .. ":" .. index .. ":" .. category] = checked
end
function SharedChatContainer:HandleTabClick() end
function SharedChatContainer:LoadWindowSettings() end
function SharedChatContainer:RemoveWindow(index) table.remove(self.windows, index) end
function SharedChatContainer:SetTabName(index, name) self.windows[index].name = name end
function SharedChatContainer:ForceWindowIntoView() end
setmetatable(container, { __index = SharedChatContainer })
chat.primaryContainer, chat.containers = container, { container }

for _, file in ipairs({ "Core.lua", "Channels.lua", "Tabs.lua", "Input.lua", "Messages.lua" }) do loadAddon(file) end
local A = OneChat
A.chat, A.sv, A.character = chat, { timestamps = true, newline = false, abbreviations = {}, toolbar = { home = true } }, { tabs = {} }
A:BuildChannels()
chat:SetChannel(CHAT_CHANNEL_SAY)
A:InstallInput()
A:InstallTabs()
eq(#A.groups, 4, "channel hierarchy")
eq(#A.groups[3].children, 2, "independent guilds")
eq(#A.groups[1].children[3].tokens, 8, "all zone languages grouped")
eq(#A:GroupTokens({ children = { A.groups[1].children[3] } }, "outgoing"), 1, "outgoing Zone contains only base Zone")
local s1, s2 = A.windows[first], A.windows[second]
local languageToken = A.byKey["zone:0"]
s1.outgoing[languageToken.key] = true
s1.last = languageToken.key
A:NormalizeZoneState(container, first, s1)
eq(s1.outgoing[languageToken.key], nil, "legacy outgoing language settings removed")
eq(s1.last, "zone", "legacy selected language migrates to Zone")
for _, t in ipairs(A:Allowed(s1)) do
    eq(t.key:match("^zone:"), nil, "language zones excluded from sending")
end
switches[languageToken.channel] = "/enzone"
switches["/enzone"] = data[languageToken.channel]
ok(s1 ~= s2, "tab states independent")
textEntry:SetText("Menu draft")
chat:ShowTextEntryMenu()
for _, item in ipairs(menus) do eq(item.text == "/enzone", false, "no language zones in selector") end
eq(menus[1].text, "/zone", "zone channels first")
eq(menus[2].text, "/say", "native menu ordering")
eq(menus[3].text, "/guild1", "guild channels before group")
eq(menus[4].text, "/officer1", "officer channel next to its guild")
eq(menus[5].text, "/guild2", "guild slot order")
eq(menus[#menus].text, "/group", "group follows guilds")
eq(textEntry:GetText(), "Menu draft", "opening selector preserves draft")
menus[#menus].callback()
eq(s1.last, "group", "native-looking menu retains tab selection")
A:ChooseChannel(A.byKey.group)
eq(s1.last, "group", "dropdown remembers channel")
local function typeText(text)
    textEntry:SetText(text)
    chat:OnTextEntryChanged(text)
end
typeText("/zone Hello")
eq(chat.currentChannel, CHAT_CHANNEL_ZONE, "native manual switch during typing")
eq(textEntry:GetText(), "Hello", "native parser preserves message body")
eq(s1.last, "group", "manual switch does not persist")
chat:SubmitTextEntry()
eq(sent[#sent].channel, CHAT_CHANNEL_ZONE, "manual message sent to zone")
eq(chat.currentChannel, CHAT_CHANNEL_PARTY, "restored immediately after send")
eq(#sent, 1, "single send")
typeText("/zone Editing")
chat:CloseTextEntry(true)
eq(chat.currentChannel, CHAT_CHANNEL_ZONE, "cancel does not restore")
eq(textEntry:GetText(), "Editing", "cancel keeps draft")
A:RestoreSelection()
textEntry:SetText("Retained draft")
chat:CloseTextEntry(true)
A:RefreshMembership()
eq(textEntry:GetText(), "Retained draft", "availability refresh keeps cancelled draft")
chat:StartTextEntry(nil, CHAT_CHANNEL_WHISPER, "@Friend")
typeText("Secret")
chat:SubmitTextEntry()
eq(sent[#sent].target, "@Friend", "whisper target")
eq(chat.currentChannel, CHAT_CHANNEL_PARTY, "temporary whisper restored")
eq(s1.last, "group", "whisper not persisted")
container:HandleTabClick(second.tab)
A:ChooseChannel(A.byKey.yell)
container:HandleTabClick(first.tab)
eq(chat.currentChannel, CHAT_CHANNEL_PARTY, "first tab selection restored")
container:HandleTabClick(second.tab)
eq(chat.currentChannel, CHAT_CHANNEL_YELL, "second tab selection restored")
for key in pairs(s2.outgoing) do s2.outgoing[key] = false end
A:RestoreSelection()
ok(A.empty, "zero outgoing supported")
chat:ShowTextEntryMenu()
eq(#menus, 1, "empty dropdown opens with explanation")
typeText("Blocked")
local before = #sent
chat:SubmitTextEntry()
eq(#sent, before, "empty selection never sends on hidden native channel")
eq(textEntry:GetText(), "Blocked", "blocked draft retained")
typeText("/zone Allowed")
chat:SubmitTextEntry()
eq(#sent, before + 1, "manual override from empty tab")
eq(sent[#sent].channel, CHAT_CHANNEL_ZONE)
ok(A.empty, "empty selection restored after manual send")
eq(s2.last, nil, "manual override not persisted on empty tab")
A:ChooseChannel(A.byKey.say)
ok(A.empty, "excluded guild/other choices cannot switch")
typeText("/zone")
chat:SubmitTextEntry()
eq(#sent, before + 1, "channel-only command does not send")
eq(chat.currentChannel, CHAT_CHANNEL_ZONE, "channel-only command remains until send")
typeText("After command")
chat:SubmitTextEntry()
ok(A.empty, "channel-only override restored on following send")

container:HandleTabClick(first.tab)
grouped = false
A:RefreshMembership()
eq(s1.last, "say", "unavailable group falls back to first permitted")
restricted[GetChannelCategoryFromChannel(CHAT_CHANNEL_SAY)] = true
A:RestoreSelection()
eq(s1.last, "emote", "restricted channels excluded")
restricted = {}
grouped = true
local guild = A.byKey["guild:101"]
A:SetTokens(container, first, "outgoing", { guild }, false)
A:ChooseChannel(guild)
eq(chat.currentChannel, CHAT_CHANNEL_EMOTE, "blocked guild click")
guilds = { 202, 101 }
A:RefreshMembership()
eq(A.byKey["guild:101"].channel, CHAT_CHANNEL_GUILD_2, "guild slot remapping")
eq(s1.outgoing["guild:101"], false, "guild preference follows ID")
local checked, mixed = A:SelectionState({ say = true, emote = false }, { A.byKey.say, A.byKey.emote })
eq(checked, false); eq(mixed, true, "partial group state")
A:SetTokens(container, first, "incoming", A.groups[1].children[3].tokens, true)
for _, t in ipairs(A.groups[1].children[3].tokens) do
    eq(IsChatContainerTabCategoryEnabled(container.id, first.tab.index, t.category), true, "incoming Zone enables every zone category")
end
A:SetTokens(container, first, "incoming", A.groups[1].children[3].tokens, false)
for _, t in ipairs(A.groups[1].children[3].tokens) do eq(s1.incoming[t.key], false, "zone group all languages") end
container:SetTabName(1, "Renamed")
eq(A.character.tabs[1][1].name, "Renamed", "rename snapshot")
eq(A.windows[first], s1, "rename retains identity")
local saved = A.character.tabs
A.windows = setmetatable({}, { __mode = "k" })
A.character.tabs, A.loadingTabs = saved, true
eq(A:GetTabState(container, first).outgoing["guild:101"], false, "reload restores preferences")
A.loadingTabs = false
A.activeWindow = second
container:RemoveWindow(2)
eq(A.windows[second], nil, "deleted pooled window released")
eq(A.character.tabs[1][2], nil, "deleted tab removed from saved snapshot")

local old = { showTimestamp = false }
ok(A:Migrate(old)); eq(old.timestamps, false); eq(old.schema, 2)
eq(A:Migrate({ schema = 999 }), false, "future schema refused")
function GetSecondsSinceMidnight() return 12 * 3600 + 35 * 60 end
local function base(_, _, text) return "native", CHAT_CHANNEL_WHISPER, "@Sender", text, "narration", "color" end
local item = "|H1:item:42|h[Item]|h"
local formatted, target, display, raw, narration, color = A:FormatMessage(base, CHAT_CHANNEL_SAY, "Character", "Hello " .. item, false, "@Account")
eq(A:PlainText(formatted), "[12:35] @Account > Hello [Item]", "default player format")
eq(target, CHAT_CHANNEL_WHISPER); eq(display, "@Sender"); eq(raw, "Hello " .. item)
eq(narration, "narration"); eq(color, "color", "native metadata preserved")
A.sv.abbreviations["101"] = "TTC"
local guildText = A:FormatMessage(base, CHAT_CHANNEL_GUILD_2, "Character", "Hi", false, "@Account")
local officerText = A:FormatMessage(base, CHAT_CHANNEL_OFFICER_2, "Character", "Hi", false, "@Account")
eq(A:PlainText(guildText), "[12:35] [TTC] @Account > Hi", "guild abbreviation")
eq(A:PlainText(officerText), A:PlainText(guildText), "same officer guild label")
A.sv.newline, A.sv.timestamps = true, false
formatted = A:FormatMessage(base, CHAT_CHANNEL_SAY, "Character", "Hi", false, "@Account")
eq(A:PlainText(formatted), "@Account >\nHi", "timestamp and newline settings")
local wrapped = A:WrapMessage(first, formatted .. " |cFF0000red|r " .. item)
ok(wrapped:find(item, 1, true), "original item link intact")
ok(wrapped:find("|cFF0000", 1, true), "color markup intact")
eq(A:PlainText(wrapped), "@Account >\nHi red [Item]", "copy plain text round trip")
local id = A.messageSequence
local captured
A.ShowCopy = function(_, text) captured = text end
A:CopyMessage(id)
eq(captured, "@Account >\nHi red [Item]", "copy exact message")
A:WrapMessage(first, "next"); A:WrapMessage(first, "third"); A:WrapMessage(first, "fourth")
eq(A.messageRecords[id], nil, "copy history bounded by native buffer limit")
A:ReleaseMessages(first)
eq(next(A.messageRecords), nil, "history cleanup")
local copied = A:WrapMessage(first, "first " .. item)
A:WrapMessage(first, "second " .. item)
ClearMenu()
A:CopyEmbeddedLink(first, item)
eq(#menus, 1, "copy action for native embedded links")
menus[1].callback()
ok(captured:find("first [Item]", 1, true) and captured:find("second [Item]", 1, true), "duplicate link disambiguation")
eq(#sent, before + 2, "formatting and UI never send messages")
