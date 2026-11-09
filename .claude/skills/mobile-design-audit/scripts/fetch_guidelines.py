#!/usr/bin/env python3
"""Download every Apple HIG page and every Android mobile design page as Markdown.

Usage:
    python3 fetch_guidelines.py OUT_DIR [--apple-only | --android-only]

Writes OUT_DIR/apple/<page>.md and OUT_DIR/android/<page>.md, one file per
page, each starting with its title and source URL. Uses only the Python
standard library. Apple pages come from the JSON that the HIG site itself
loads; Android pages come from the HTML.

Read the pages you need with your file tools. Do not commit the downloaded
text into a project: it is Apple's and Google's content. Link to it instead.
"""

import concurrent.futures as cf
import html
import json
import os
import re
import sys
import urllib.request

APPLE_DATA = "https://developer.apple.com/tutorials/data"
APPLE_ROOT = "/design/human-interface-guidelines"
ANDROID_HOST = "https://developer.android.com"
ANDROID_ROOT = "/design/ui/mobile"
UA = {"User-Agent": "guideline-fetch/1.0"}


def get(url: str) -> bytes:
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=40) as r:
        return r.read()


# ---------------------------------------------------------------- Apple


def _inline(items, refs):
    out = ""
    for x in items or []:
        t = x.get("type")
        if t == "text":
            out += x["text"]
        elif t == "codeVoice":
            out += "`" + x["code"] + "`"
        elif t == "reference":
            out += refs.get(x.get("identifier"), {}).get("title", "")
        elif "inlineContent" in x:
            out += _inline(x["inlineContent"], refs)
    return out


def _blocks(blocks, refs, depth=0):
    out = []
    for b in blocks or []:
        t = b.get("type")
        if t == "heading":
            out.append("\n" + "#" * min(6, b.get("level", 2) + 1) + " " + b.get("text", ""))
        elif t == "paragraph":
            out.append(_inline(b.get("inlineContent"), refs))
        elif t in ("unorderedList", "orderedList"):
            for item in b.get("items", []):
                out.append("  " * depth + "- " + " ".join(_blocks(item.get("content"), refs, depth + 1)).strip())
        elif t == "aside":
            out.append("> " + (b.get("name") or b.get("style", "")) + ": " + " ".join(_blocks(b.get("content"), refs)))
        elif t == "table":
            for row in b.get("rows", []):
                out.append("| " + " | ".join(" ".join(_blocks(c, refs)) for c in row) + " |")
        elif t == "row":
            for col in b.get("columns", []):
                out += _blocks(col.get("content"), refs, depth)
        elif t == "tabNavigator":
            for tab in b.get("tabs", []):
                out.append("**" + tab.get("title", "") + "**")
                out += _blocks(tab.get("content"), refs, depth)
        elif "content" in b:
            out += _blocks(b["content"], refs, depth)
    return out


def _apple_page(path):
    try:
        d = json.loads(get(APPLE_DATA + path + ".json"))
    except Exception:
        return path, None, []
    refs = d.get("references", {})
    lines = [
        "# " + d.get("metadata", {}).get("title", path),
        "Source: https://developer.apple.com" + path,
        _inline(d.get("abstract"), refs),
    ]
    for section in d.get("primaryContentSections", []):
        lines += _blocks(section.get("content"), refs)
    links = {
        v["url"].split("#")[0]
        for v in refs.values()
        if isinstance(v, dict) and v.get("url", "").startswith(APPLE_ROOT)
    }
    return path, "\n".join(lines), links


def fetch_apple(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    seen, queue = set(), {APPLE_ROOT}
    with cf.ThreadPoolExecutor(12) as ex:
        while queue:
            batch = [p for p in queue if p not in seen]
            seen.update(batch)
            queue = set()
            for path, text, links in ex.map(_apple_page, batch):
                if text:
                    name = path.rstrip("/").split("/")[-1] or "index"
                    with open(os.path.join(out_dir, name + ".md"), "w") as f:
                        f.write(text)
                queue |= {l for l in links if l not in seen}
    return len(seen)


# -------------------------------------------------------------- Android


def _android_text(page):
    m = re.search(r'<div class="devsite-article-body[^>]*>(.*?)<devsite-content-footer', page, re.S)
    body = m.group(1) if m else page
    body = re.sub(r"<(script|style|svg)[^>]*>.*?</\1>", "", body, flags=re.S)
    body = re.sub(r"<h([1-6])[^>]*>", lambda x: "\n" + "#" * int(x.group(1)) + " ", body)
    body = re.sub(r"<li[^>]*>", "\n- ", body)
    body = re.sub(r"<(p|br|tr|div)[^>]*>", "\n", body)
    body = html.unescape(re.sub(r"<[^>]+>", "", body))
    return re.sub(r"\n\s*\n+", "\n\n", body).strip()


def _android_page(path):
    try:
        page = get(ANDROID_HOST + path).decode("utf8", "replace")
    except Exception:
        return path, None, set()
    title = re.search(r"<title>(.*?)</title>", page, re.S)
    title = html.unescape(title.group(1)).split("|")[0].strip() if title else path
    text = f"# {title}\nSource: {ANDROID_HOST}{path}\n\n{_android_text(page)}"
    links = {
        l.rstrip("/")
        for l in re.findall(r'href="(?:https://developer\.android\.com)?(' + ANDROID_ROOT + r'[^"#?]*)"', page)
    }
    return path, text, links


def fetch_android(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    seen, queue = set(), {ANDROID_ROOT}
    with cf.ThreadPoolExecutor(8) as ex:
        while queue:
            batch = [p for p in queue if p not in seen]
            seen.update(batch)
            queue = set()
            for path, text, links in ex.map(_android_page, batch):
                if text:
                    name = path.replace(ANDROID_ROOT, "").strip("/").replace("/", "_") or "index"
                    with open(os.path.join(out_dir, name + ".md"), "w") as f:
                        f.write(text)
                queue |= {l for l in links if l not in seen}
    return len(seen)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    out = sys.argv[1]
    if "--android-only" not in sys.argv:
        print("Apple pages:", fetch_apple(os.path.join(out, "apple")))
    if "--apple-only" not in sys.argv:
        print("Android pages:", fetch_android(os.path.join(out, "android")))
