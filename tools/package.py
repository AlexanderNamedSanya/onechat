"""Validate and build the installable OneChat archive; no development files."""
from pathlib import Path
import hashlib
import subprocess
import sys
import zipfile
import re

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / "tools/validate.py")], check=True)
destination = root / "dist"
destination.mkdir(exist_ok=True)
manifest = (root / "OneChat/OneChat.txt").read_text(encoding="utf-8")
version = re.search(r"^## Version: ([0-9.]+)$", manifest, re.M).group(1)
archive = destination / f"OneChat-{version}.zip"
files = sorted((root / "OneChat").rglob("*"))
with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as package:
    for file in files:
        if file.is_file():
            assert file.suffix in {".lua", ".txt", ".dds"}, file
            package.write(file, file.relative_to(root).as_posix())
with zipfile.ZipFile(archive) as package:
    assert package.testzip() is None
    assert "OneChat/OneChat.txt" in package.namelist()
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
archive.with_suffix(".zip.sha256").write_text(f"{digest}  {archive.name}\n", encoding="ascii")
print(f"Created {archive} ({archive.stat().st_size:,} bytes)")
print(f"SHA-256: {digest}")

(destination / f"OneChat-{version}-ESOUI-description.txt").write_text((root / "ESOUI-description.txt").read_text(encoding="utf-8"), encoding="utf-8")
