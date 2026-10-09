#!/usr/bin/env python3
"""Regenerate manifest.json (sha256 + sizes) for Ryostore lockscreens shape."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.1.0"
ID = "felix-lock-strip"

# (source relative to ROOT, destination under qylock theme, install?)
ENTRIES = [
    ("LICENSE", "LICENSE", True),
    ("PROVENANCE.txt", "PROVENANCE.txt", True),
    ("assets/preview.png", "preview.png", False),
    ("content/Main.qml", "Main.qml", True),
    ("content/metadata.desktop", "metadata.desktop", True),
    ("content/theme.conf", "theme.conf", True),
    ("content/i18n/I18n.qml", "i18n/I18n.qml", True),
    ("content/i18n/qmldir", "i18n/qmldir", True),
]


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> None:
    files = []
    for source, dest, install in ENTRIES:
        path = ROOT / source
        if not path.is_file():
            raise SystemExit(f"missing: {source}")
        files.append(
            {
                "source": source,
                "destination": dest,
                "mode": "0644",
                "size": path.stat().st_size,
                "sha256": sha256(path),
                "install": install,
            }
        )
    manifest = {
        "schema": 1,
        "id": ID,
        "category": "lockscreens",
        "version": VERSION,
        "destination": f"qylock/themes/{ID}",
        "files": files,
    }
    out = ROOT / "manifest.json"
    out.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {out}")
    print("manifestSha256", sha256(out))


if __name__ == "__main__":
    main()
