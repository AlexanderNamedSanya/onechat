local A = OneChat
local function eq(a, b, message)
    checks = checks + 1
    assert(a == b, (message or "mismatch") .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end

-- The real ZO_SavedVars wrapper verifies defaults/migration and isolation.
local world, characterId = "NA Megaserver", "123"
function GetWorldName() return world end
function GetDisplayName() return "@Test" end
function GetUnitName() return "Character" end
function GetCurrentCharacterId() return characterId end
function ZO_ClearTable(t) for key in pairs(t) do t[key] = nil end end
assert(loadstring(savedvars_source))()
eq(A:InitializeSavedVariables(), true)
A.sv.timestamps = false
A.sv.abbreviations["101"] = "ABC"
A.character.tabs = { [1] = { [1] = { name = "Saved", outgoing = { say = false } } } }
eq(A:InitializeSavedVariables(), true)
eq(A.sv.timestamps, false, "false preference survives default merge")
eq(A.character.tabs[1][1].outgoing.say, false, "tab state survives wrapper reload")
characterId = "456"
A:InitializeSavedVariables()
eq(A.sv.abbreviations["101"], "ABC", "account settings shared across characters")
eq(next(A.character.tabs), nil, "tab settings separated by character ID")
world = "EU Megaserver"
A:InitializeSavedVariables()
eq(A.sv.abbreviations["101"], nil, "EU isolated from NA")
world = "PTS"
A:InitializeSavedVariables()
eq(A.sv.timestamps, true, "PTS independent defaults")
world, characterId = "NA Megaserver", "123"
A:InitializeSavedVariables()
eq(A.sv.timestamps, false, "returning to NA restores original preference")
A.sv.schema, A.sv.showTimestamp = 1, true
A:InitializeSavedVariables()
eq(A.sv.timestamps, true, "legacy setting migration through wrapper")
eq(A.sv.showTimestamp, nil, "legacy key removed")

-- Strict method surface and native check-button behavior; geometry/rendering
-- and secure engine execution still require the game client.
BSTATE_NORMAL, BSTATE_PRESSED = 0, 1
local Control = {}
function Control:GetName() return self.name end
function Control:GetNamedChild(name) return assert(self.children[name], name) end
function Control:SetHandler(name, callback) self.handlers[name] = callback end
function Control:GetHandler(name) return self.handlers[name] end
function Control:SetText(text)
    self.text = text
    if self.handlers.OnTextChanged then self.handlers.OnTextChanged(self) end
end
function Control:GetText() return self.text or "" end
function Control:SetFont(font) self.font = font end
function Control:SetDimensions(width, height) self.width, self.height = width, height end
function Control:SetAnchor(...) self.anchor = { ... } end
function Control:SetWidth(width) self.width = width end
function Control:SetHeight(height) self.height = height end
function Control:SetHidden(hidden) self.hidden = not not hidden end
function Control:IsHidden() return self.hidden end
function Control:SetState(state) self.state = state end
function Control:GetState() return self.state or BSTATE_NORMAL end
function Control:SetPressedTexture(texture) self.pressed = texture end
for _, name in ipairs({ "SetTexture", "SetAnchorFill", "SetColor", "ClearAnchors", "SetResizeToFitDescendents",
    "SetExcludeFromResizeToFitExtents", "SetWrapMode", "SetNormalTexture", "SetMouseOverTexture",
    "SetMaxInputChars", "TakeFocus", "SelectAll", "SetShowingHighlight", "SetMouseEnabled" }) do
    Control[name] = function() end
end
local sequence = 0
local function control(name, parent)
    sequence = sequence + 1
    return setmetatable({ name = name or ("Anonymous" .. sequence), parent = parent,
        children = {}, handlers = {}, hidden = true }, { __index = Control })
end
WINDOW_MANAGER = { CreateControl = function(_, name, parent) return control(name, parent) end }
function CreateControlFromVirtual(name, parent, template)
    local c = control(name, parent)
    c.template = template
    if template == "ZO_ScrollContainer" then c.children.ScrollChild = control(name .. "ScrollChild", c) end
    return c
end
local function nativeButton(name)
    local start = assert(button_source:find("function " .. name .. "(", 1, true), name)
    local finish = assert(button_source:find("\nend", start, true), name)
    assert(loadstring(button_source:sub(start, finish + 3)))()
end
for _, name in ipairs({ "ZO_CheckButton_SetLabelText", "ZO_CheckButton_SetLabelWidth", "ZO_CheckButton_SetToggleFunction",
    "ZO_CheckButton_SetTooltipText", "ZO_CheckButton_SetChecked", "ZO_CheckButton_SetUnchecked", "ZO_CheckButton_SetCheckState" }) do nativeButton(name) end
local start = assert(button_source:find("TRISTATE_CHECK_BUTTON_CHECKED =", 1, true))
local finish = assert(button_source:find("function ZO_ReadOnlyCheckBox_OnInitialized", start, true))
assert(loadstring(button_source:sub(start, finish - 1)))()
function ZO_CheckButton_IsTooltipEnabled() return true end
function ZO_CheckButtonLabel_ColorText() end
GuiRoot = control("GuiRoot")
ZO_ChatOptionsDialog = control("ZO_ChatOptionsDialog", GuiRoot)
for _, child in ipairs({ "FilterSection", "GuildSection", "FilterLabel", "GuildChannelLabel" }) do
    ZO_ChatOptionsDialog.children[child] = control("ZO_ChatOptionsDialog" .. child, ZO_ChatOptionsDialog)
end
ZO_ChatOptionsDialog:SetHidden(false)
local window = A.chat.containers[1].windows[1]
local container = A.chat.containers[1]
container.control = control("ZO_ChatWindow", GuiRoot)
function SharedChatContainer:ShowContextMenu() end
CHAT_OPTIONS = { GetCurrentContainer = function() return container end,
    GetCurrentTabIndex = function() return 1 end, Show = function() end, Reset = function() end }
local registeredDialogs, shownDialogs = {}, {}
function ZO_Dialogs_RegisterCustomDialog(name, info) registeredDialogs[name] = info end
function ZO_Dialogs_ShowDialog(name) shownDialogs[#shownDialogs + 1] = name end
assert(loadfile(addon_root .. "/UI.lua"))()
A:InstallOptions()
eq(ZO_ChatOptionsDialog.children.FilterSection.hidden, true, "native filter section hidden")
eq(ZO_ChatOptionsDialog.children.FilterLabel:GetText(), GetString(SI_ONECHAT_INCOMING), "incoming heading")
CHAT_OPTIONS:Show()
local first = A.incomingPane.rows[1]
eq(first.check.label.font, "ZoFontGameBold", "vanilla channel checkbox font")
eq(A.incomingPane.rows[9].check.label.font, "ZoFontWinH4", "vanilla guild name font")
eq(A.incomingPane.rows[9].check.oneChatTokens[1].key:match("^guild:"), "guild:", "guild name controls guild channel")
eq(#A.incomingPane.rows[9].check.oneChatTokens, 1, "guild checkbox excludes officer channel")
eq(A.incomingPane.rows[10].check.oneChatTokens[1].key:match("^officer:"), "officer:", "officer child follows guild name")
eq(A.incomingPane.rows[10].oneChatDepth, 1, "officer indented")
eq(A.incomingPane.rows[6].oneChatDepth, 0, "group channel has no category")
eq(A.incomingPane.rows[7].oneChatDepth, 0, "whisper has no category")
eq(A.incomingPane.rows[1].height, 27, "vanilla row pitch")
eq(A.incomingPane.control.width, 480, "vanilla two-column width")
eq(first.arrow, nil, "no expansion controls")
eq(A.incomingPane.columnCount, 2, "columns are inside incoming section")
eq(A.outgoingPane.columnCount, 2, "columns are inside outgoing section")
eq(ZO_ChatOptionsDialog.children.GuildChannelLabel.anchor[2], A.incomingPane.control, "outgoing section below incoming")
eq(A.incomingPane.control.height < #A.incomingPane.rows * 27, true, "rows distributed between columns")
eq(#A.incomingPane.rows > #A.groups, true, "all nested channels visible")
eq(A.incomingPane.control.template, nil, "plain pane without scroll container")
eq(first.check.template, "ZO_TriStateCheckButton", "native tri-state checkbox reused")
local previousZone = A.windows[window].incoming.zone
ZO_TriStateCheckButton_SetState(first.check, TRISTATE_CHECK_BUTTON_INDETERMINATE)
ZO_TriStateCheckButton_OnClicked(first.check, MOUSE_BUTTON_INDEX_LEFT)
eq(A.windows[window].incoming.say, true, "partial group click enables children")
eq(A.windows[window].incoming.zone, previousZone, "say toggle leaves zone unchanged")
eq(#A.incomingPane.rows[1].check.oneChatTokens, 1, "no aggregate Zone row")
eq(A.incomingPane.rows[1].check.oneChatTokens[1].key, "say", "flat channel list")
for _, index in ipairs({ 6, 7, 8 }) do
    eq(A.incomingPane.rows[index].anchor[4], 0, "Group Tell System stay in left column")
end
local settingsOptions, openedPanel
LibAddonMenu2 = {
    RegisterAddonPanel = function(_, name, data) return { name = name, data = data } end,
    RegisterOptionControls = function(_, name, options) settingsOptions = options end,
    OpenToPanel = function(_, panel) openedPanel = panel end,
}
A:InstallSettings()
A:ShowSettings()
eq(openedPanel, A.settingsPanel, "settings open inside LibAddonMenu")
eq(#settingsOptions, 9 + MAX_GUILDS, "all settings registered")
eq(settingsOptions[1].name, GetString(SI_ONECHAT_FORMATTING), "chat section first")
eq(settingsOptions[4].name, GetString(SI_ONECHAT_BUTTONS_SECTION), "buttons section separates visibility settings")
eq(settingsOptions[8].name, GetString(SI_ONECHAT_ABBREVIATIONS), "abbreviations section third")
settingsOptions[2].setFunc(false)
eq(A.sv.timestamps, false, "LAM setting persists")
settingsOptions[10].setFunc("TEST")
eq(settingsOptions[10].getFunc(), "TEST", "guild abbreviation persists through LAM")
A:ShowCopy("selectable text")
eq(A.copyEdit:GetText(), "selectable text", "copy field populated")
eq(shownDialogs[#shownDialogs], "OneChatCopyDialog", "standard copy dialog")

local house, canTravel, jumps = 0, true, {}
function GetHousingPrimaryHouse() return house end
function CanJumpToHouseFromCurrentLocation() return canTravel end
function IsUnitDead() return false end
function RequestJumpToHouse(id) jumps[#jumps + 1] = id end
ZO_NORMAL_TEXT = { UnpackRGB = function() return 0.77, 0.76, 0.62 end }
A:InstallToolbar()
eq(#A.toolbarButtons, 3, "three action buttons")
eq(A.toolbarButtons[2].control.hidden, false, "reload visible by default")
eq(A.toolbarButtons[3].control.hidden, false, "language visible by default")
local reloads, language, languageMenu = 0, "en", {}
function ReloadUI(gui) eq(gui, "ingame"); reloads = reloads + 1 end
function GetCVar(name) eq(name, "language.2"); return language end
function SetCVar(name, value) eq(name, "language.2"); language = value end
A.toolbarButtons[2].control:GetHandler("OnClicked")()
eq(reloads, 1, "reload button invokes native reload")
local previousClear, previousAdd, previousShow = ClearMenu, AddMenuItem, ShowMenu
function ClearMenu() languageMenu = {} end
function AddMenuItem(text, callback) languageMenu[#languageMenu + 1] = callback end
function ShowMenu(owner) eq(owner, A.toolbarButtons[3].control) end
A.toolbarButtons[3].control:GetHandler("OnClicked")(A.toolbarButtons[3].control)
eq(#languageMenu, 7, "all game languages listed")
languageMenu[4]()
eq(language, "ru", "language selection uses client CVar")
eq(reloads, 2, "language selection reloads the interface")
ClearMenu, AddMenuItem, ShowMenu = previousClear, previousAdd, previousShow
A.sv.toolbar.reload = false
A:RefreshToolbar()
eq(A.toolbarButtons[2].control.hidden, true, "reload visibility independent")
eq(A.toolbarButtons[3].control.hidden, false, "language visibility unaffected")
eq(A.toolbarButtons[1].control.hidden, false, "home button default visible")
A.sv.toolbar.home = false
A:RefreshToolbar()
eq(A.toolbarButtons[1].control.hidden, true, "home button independent setting")
A:TravelHome()
eq(#jumps, 0, "missing residence handled")
house, canTravel = 42, false
A:TravelHome()
eq(#jumps, 0, "travel restrictions respected")
canTravel = true
A:TravelHome()
eq(jumps[1], 42, "travels to current primary residence")

-- A full native reset must discard tab records even when controls are pooled.
A.windows[window].outgoing.say = false
A.chat:ResetChat()
eq(A.windows[window].outgoing.say, true, "full chat reset restores outgoing defaults")
eq(A.activeWindow, window, "reset selects a valid window")

-- Explicit native FREE=false, as well as the omitted argument, means delete.
local disposable = { name = "Disposable", tab = { index = 2, GetHandler = function() end, SetHandler = function() end }, buffer = { GetMaxHistoryLines = function() return 3 end } }
container.windows[2] = disposable
A:GetTabState(container, disposable)
container:RemoveWindow(2, false)
eq(A.windows[disposable], nil, "explicit false frees tab preferences")

-- Check the real TextBuffer handler argument order and preserve native menus.
local function nativeMethod(name)
    local start = assert(native_source:find("function " .. name .. "(", 1, true))
    local finish = assert(native_source:find("\nend", start, true))
    assert(loadstring(native_source:sub(start, finish + 3)))()
end
nativeMethod("SharedChatContainer:AddMessageToWindow")
nativeMethod("SharedChatSystem:ShowPlayerContextMenu")
local originalLinkCalls = 0
local bufferControl = control("Buffer", nil)
function bufferControl:GetMaxHistoryLines() return 3 end
function bufferControl:AddMessage(text) self.lastMessage = text end
bufferControl:SetHandler("OnLinkMouseUp", function() originalLinkCalls = originalLinkCalls + 1 end)
window.buffer = bufferControl
local formatter = function(_, _, text) return text end
function CHAT_ROUTER:GetRegisteredMessageFormatters() return { [EVENT_CHAT_MESSAGE_CHANNEL] = formatter } end
function CHAT_ROUTER:RegisterMessageFormatter(_, callback) formatter = callback end
EVENT_CHAT_MESSAGE_CHANNEL = 99
A:InstallMessages()
local itemLink = "|H1:item:42|h[Item]|h"
container:AddMessageToWindow(window, "Message " .. itemLink, 1, 1, 1, 100)
local menu = {}
function ClearMenu() menu = {} end
function AddMenuItem(text, callback) menu[#menu + 1] = { text = text, callback = callback } end
function ZO_Menu_GetNumMenuItems() return #menu end
bufferControl:GetHandler("OnLinkMouseUp")(bufferControl, "item:42", itemLink, MOUSE_BUTTON_INDEX_RIGHT)
eq(originalLinkCalls, 1, "existing embedded-link handler preserved")
eq(menu[1].text, GetString(SI_ONECHAT_COPY), "copy appended using actual handler arguments")

function IsGroupModificationAvailable() return true end
function IsUnitGrouped() return false end
function IsUnitGroupLeader() return false end
function IsPlayerInGroup() return false end
function IsIgnored() return false end
function IsFriend() return false end
A:PlayerMenu("@Friend", "Friend", A.messageSequence)
eq(#menu, 9, "eight requested player actions plus native report")
local found = {}
for _, item in ipairs(menu) do found[item.text] = true end
eq(found[zo_strformat(SI_CHAT_PLAYER_CONTEXT_REPORT, "Friend")], true, "native report action retained")
eq(found[GetString(SI_CHAT_PLAYER_CONTEXT_WHISPER)], true, "native whisper action retained")
eq(found[GetString(SI_SOCIAL_MENU_SEND_MAIL)], true, "mail action added")

local originalGuildCount, originalGuildId = GetNumGuilds, GetGuildId
GetNumGuilds = function() return 5 end
GetGuildId = function(index) return index * 101 end
A:BuildChannels()
A:RefreshOptions()
eq(A.incomingPane.columnCount, 3, "five guilds use three incoming columns")
eq(A.outgoingPane.columnCount, 3, "five guilds use three outgoing columns")
eq(A.incomingPane.control.height <= 11 * 27, true, "maximum guild count stays compact")
GetNumGuilds, GetGuildId = originalGuildCount, originalGuildId
