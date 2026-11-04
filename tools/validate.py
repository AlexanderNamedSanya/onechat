"""Targeted package/localization checks. Requires lupa (Lua 5.1 runtime).

python -m pip install lupa
python tools/validate.py [--source .reference/esoui]
"""
from pathlib import Path
from collections import Counter
import argparse
import re
import sys
import struct

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".tools"))
from lupa.lua51 import LuaRuntime

LANGUAGES = ("en", "de", "fr", "ru", "es", "zh", "jp")
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--source", type=Path)
args = parser.parse_args()
lua = LuaRuntime(unpack_returned_tuples=True)
compile_lua = lua.eval("function(text, name) local f, e = loadstring(text, name); assert(f, e) end")
errors = []
locales = {}

def require(condition, message):
    if not condition:
        errors.append(message)

def placeholders(value):
    return Counter(re.findall(r"<<[^>]+>>|%(?:\d+\$)?[-+ #0]*\d*(?:\.\d+)?[cdeEfgGiouXxsq%]", value))

for path in (ROOT / "OneChat").rglob("*.lua"):
    try:
        text = path.read_bytes().decode("utf-8", errors="strict")
        require("\ufeff" not in text, f"{path}: unexpected BOM")
        compile_lua(text, str(path))
    except Exception as exc:
        errors.append(f"{path}: {exc}")

for language in LANGUAGES:
    path = ROOT / "OneChat/lang" / f"{language}.lua"
    require(path.is_file(), f"Missing language: {language}")
    if not path.is_file():
        continue
    text = path.read_text(encoding="utf-8")
    keys = re.findall(r"^\s*(SI_ONECHAT_\w+)\s*=", text, re.M)
    require(len(keys) == len(set(keys)), f"{language}: duplicate keys")
    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.execute("""
        values = {}
        function ZO_CreateStringId(id, value) _G[id] = id; values[id] = value end
        function SafeAddString(id, value, version) assert(id); values[id] = value end
    """)
    if language != "en":
        runtime.execute((ROOT / "OneChat/lang/en.lua").read_text(encoding="utf-8"))
        runtime.execute("values = {}")
    runtime.execute(text)
    locales[language] = dict(runtime.globals()["values"])
    require(set(keys) == set(locales[language]), f"{language}: keys not registered")

base = locales.get("en", {})
required = set(re.findall(r"SI_ONECHAT_\w+", "\n".join(
    p.read_text(encoding="utf-8") for p in (ROOT / "OneChat").glob("*.lua"))))
require(required <= base.keys(), f"Missing base IDs: {required - base.keys()}")
for language, values in locales.items():
    require(values.keys() == base.keys(), f"{language}: incomplete key set")
    for key, value in values.items():
        require(isinstance(value, str) and bool(value.strip()), f"{language}: empty {key}")
        require(placeholders(value) == placeholders(base.get(key, "")), f"{language}: placeholders differ: {key}")
        require(not re.search(r"\b(TODO|FIXME|TBD)\b", value), f"{language}: placeholder {key}")
        if language != "en" and re.search(r"[a-zA-Z]{3}", value):
            require(value != base.get(key), f"{language}: English copy: {key}")

manifest = (ROOT / "OneChat/OneChat.txt").read_text(encoding="utf-8")
for icon in ("home", "reload", "language"):
    path = ROOT / "OneChat/art" / f"{icon}.dds"
    require(path.is_file(), f"Missing toolbar icon: {icon}")
    if path.is_file():
        data = path.read_bytes()
        require(data[:4] == b"DDS " and len(data) >= 128, f"Invalid DDS: {icon}")
        require(struct.unpack_from("<II", data, 12) == (32, 32), f"Icon size differs: {icon}")
        require(data[84:88] == b"DXT5", f"Icon alpha format differs: {icon}")
require("## APIVersion: 101051" in manifest, "Manifest API version missing")
require("## AddOnVersion: 261101" in manifest, "Manifest integer version missing")
require("## SavedVariables: OneChatSavedVariables" in manifest, "SavedVariables declaration missing")
entries = [line.strip() for line in manifest.splitlines() if line.strip() and not line.startswith("##")]
require(entries[:2] == ["lang/en.lua", "lang/$(language).lua"], "Base/active locale load order")
for entry in entries:
    for language in LANGUAGES if "$(language)" in entry else ("en",):
        require((ROOT / "OneChat" / entry.replace("$(language)", language)).is_file(), f"Missing manifest file: {entry}")

if args.source:
    source = args.source.resolve()
    functions = (source / "esoui/ingame/chatsystem/sharedchatsystem.lua").read_text(encoding="utf-8-sig")
    lua.globals().native_source = functions
    lua.globals().link_source = (source / "esoui/libraries/utility/zo_linkhandler.lua").read_text(encoding="utf-8-sig")
    lua.globals().hook_source = (source / "esoui/libraries/utility/zo_hook.lua").read_text(encoding="utf-8-sig")
    lua.globals().button_source = (source / "esoui/libraries/zo_templates/buttontemplates.lua").read_text(encoding="utf-8-sig")
    lua.globals().savedvars_source = (source / "esoui/libraries/utility/zo_savedvars.lua").read_text(encoding="utf-8-sig")
    lua.globals().addon_root = (ROOT / "OneChat").as_posix()
    lua.execute((ROOT / "tests/behavior.lua").read_text(encoding="utf-8"))
    lua.execute((ROOT / "tests/ui_and_savedvars.lua").read_text(encoding="utf-8"))
    print(f"Behavior checks passed: {lua.globals().checks} assertions against native chat methods")

if errors:
    print("\n".join(errors), file=sys.stderr)
    raise SystemExit(1)
print(f"PASS: Lua 5.1 syntax, UTF-8, manifest, and {len(base)} strings in each of {len(locales)} languages")
