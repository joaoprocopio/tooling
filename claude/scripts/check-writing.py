#!/usr/bin/env python3
"""Check agent-facing Markdown against the Writing Guidelines and writing-for-agents.

Usage:
    check-writing.py <path>...        # files, or directories searched for *.md

Findings print as `file:line - issue`, grouped by file, errors before warnings.
Exit status is 1 when any error is found, so a hook or CI step can gate on it.

Errors are rules with one right answer. Warnings are rules that need a human to
confirm, so they report and never gate.

Prose only: fenced code blocks, inline code spans, tables, and front matter are
stripped before the prose rules run, since a command line holds straight quotes,
three dots, and hyphens on purpose.
"""

import re
import sys
from pathlib import Path

BANNED = ["easy", "easily", "simple", "simply", "quick", "quickly", "very", "just", "really"]
WEASEL = ["significantly", "many", "often", "typically", "generally", "usually", "various", "several"]
GENERIC_HEADINGS = {"overview", "notes", "caveats", "details", "introduction", "summary", "usage", "misc", "other"}
NEGATIONS = ["never", "don't", "do not", "avoid", "no need to"]
BE_VERBS = r"(?:is|are|was|were|be|been|being)"
PASSIVE = re.compile(rf"\b{BE_VERBS}\s+(\w+ed|done|made|given|taken|written|held|read|kept|built|sent)\b", re.I)

# Words ending in -ed that follow a be-verb without forming a passive.
PASSIVE_ALLOW = {"based", "used", "aged", "deed", "need", "indeed", "embed"}


class Finding:
    def __init__(self, line, message, level):
        self.line = line
        self.message = message
        self.level = level


def split_blocks(text):
    """Return (prose_lines, fence_spans) where prose_lines is [(lineno, text)].

    Front matter, fenced code, and table rows are dropped from the prose set.
    """
    lines = text.split("\n")
    prose = []
    fences = []
    table_cells = []
    in_fence = False
    fence_marker = ""
    fence_start = 0
    in_front_matter = False

    for i, raw in enumerate(lines, start=1):
        stripped = raw.strip()

        if i == 1 and stripped == "---":
            in_front_matter = True
            continue
        if in_front_matter:
            if stripped == "---":
                in_front_matter = False
            continue

        fence_open = re.match(r"^(`{3,}|~{3,})(.*)$", stripped)
        if fence_open and not in_fence:
            in_fence = True
            fence_marker = fence_open.group(1)
            fence_start = i
            fences.append((i, fence_open.group(2).strip()))
            continue
        if in_fence:
            close = re.match(r"^(`{3,}|~{3,})\s*$", stripped)
            if close and close.group(1)[0] == fence_marker[0] and len(close.group(1)) >= len(fence_marker):
                in_fence = False
            continue

        if stripped.startswith("|"):
            if not re.fullmatch(r"[|\s:-]+", stripped):
                table_cells.append((i, stripped))
            continue

        prose.append((i, raw))

    if in_fence:
        prose.append((fence_start, "<unclosed fence>"))
    return prose, fences, table_cells


def strip_inline_code(line):
    return re.sub(r"`[^`]*`", "``", line)


def sentences(text):
    text = re.sub(r"\s+", " ", text).strip()
    return [s for s in re.split(r"(?<=[.!?])\s+(?=[A-Z(])", text) if s]


def check_file(path):
    text = path.read_text()
    lines = text.split("\n")
    prose, fences, table_cells = split_blocks(text)
    out = []

    def err(line, msg):
        out.append(Finding(line, msg, "error"))

    def warn(line, msg):
        out.append(Finding(line, msg, "warning"))

    # Fence rules: every fence carries a language tag.
    for line, info in fences:
        if not info:
            err(line, "code block missing language tag")

    for line, cell in table_cells:
        clean = strip_inline_code(cell)
        if "—" in clean or "–" in clean:
            err(line, "em or en dash in a table cell; use a colon or a comma")
        if "..." in clean:
            err(line, '"..." should be the ellipsis "…"')

    for line, raw in prose:
        clean = strip_inline_code(raw)
        stripped = clean.strip()

        if not stripped:
            continue

        if "—" in clean or "–" in clean:
            err(line, "em or en dash as punctuation; use a colon, a comma, or a period")

        if "..." in clean:
            err(line, '"..." should be the ellipsis "…"')

        if re.fullmatch(r"-{3,}|\*{3,}|_{3,}", stripped):
            err(line, "horizontal rule between sections; use a heading")

        if re.search(r"\b\d+(KB|MB|GB|TB|ms|MS|kb)\b", clean):
            err(line, "bare unit; write a space and an uppercase unit, as in 64 KB or 200 ms")

        for word in BANNED:
            if re.search(rf"\b{re.escape(word)}\b", clean, re.I):
                err(line, f'banned word "{word}"')

        for word in WEASEL:
            if re.search(rf"\b{word}\b", clean, re.I):
                warn(line, f'weasel word "{word}"; give the number or the specific claim')

        heading = re.match(r"^(#{1,6})\s+(.*)$", stripped)
        if heading:
            title = heading.group(2).strip()
            words = [w for w in re.findall(r"[A-Za-z][\w'-]*", title)]
            if len(words) > 1:
                rest = [w for w in words[1:] if not re.fullmatch(r"[A-Z]{2,}s?", w)]
                capped = [w for w in rest if w[0].isupper() and not w.isupper()]
                if len(capped) >= 2 and len(capped) >= len(rest) / 2:
                    err(line, f'title case in heading "{title}"; use sentence case')
            if title.lower() in GENERIC_HEADINGS:
                warn(line, f'generic heading "{title}"; name what the section holds')
            continue

        if re.match(r"^[-*+]\s|^\d+\.\s", stripped):
            continue

        if stripped.endswith("?"):
            warn(line, "rhetorical question")

        for phrase in NEGATIONS:
            if re.search(rf"(?<![\w-])({re.escape(phrase)})\b", clean, re.I):
                warn(line, f'negation "{phrase}"; state the target behaviour instead')
                break

        for match in PASSIVE.finditer(clean):
            if match.group(1).lower() in PASSIVE_ALLOW:
                continue
            warn(line, f'possible passive voice "{match.group(0)}"; name the actor')

        for sentence in sentences(clean):
            count = len(sentence.split())
            if count > 30:
                warn(line, f"sentence of {count} words; the target is under 20")

    # A list opens on a colon, and a paragraph is one source line.
    for idx, raw in enumerate(lines):
        line = idx + 1
        stripped = raw.strip()
        if re.match(r"^[-*+]\s|^\d+\.\s", stripped):
            prev = lines[idx - 1].strip() if idx else ""
            prev_is_list = bool(re.match(r"^[-*+]\s|^\d+\.\s", prev))
            if prev and not prev_is_list and not prev.endswith(":") and not prev.startswith("|"):
                err(line, "list introduced without a colon on the line above")

    prose_map = dict(prose)
    for idx, raw in enumerate(lines):
        line = idx + 1
        if line not in prose_map:
            continue
        stripped = raw.strip()
        nxt = lines[idx + 1].strip() if idx + 1 < len(lines) else ""
        if not stripped or not nxt:
            continue
        plain = not re.match(r"^([-*+#>|]|\d+\.|```)", stripped)
        nxt_plain = not re.match(r"^([-*+#>|]|\d+\.|```)", nxt)
        if plain and nxt_plain and (line + 1) in prose_map:
            err(line, "hard-wrapped paragraph; keep a paragraph on one source line")

        if re.match(r"^#{1,6}\s", stripped) and idx and lines[idx - 1].strip():
            err(line, "heading without a blank line above it")

        if plain:
            paragraph = sentences(strip_inline_code(stripped))
            if len(paragraph) > 4:
                warn(line, f"paragraph of {len(paragraph)} sentences; split past four")

    return out


def collect(paths):
    files = []
    for arg in paths:
        p = Path(arg)
        if p.is_dir():
            files.extend(sorted(p.rglob("*.md")))
        elif p.is_file():
            files.append(p)
        else:
            print(f"no such path: {arg}", file=sys.stderr)
    return files


def main(argv):
    if not argv:
        print(__doc__)
        return 2

    files = collect(argv)
    errors = 0
    warnings = 0

    for path in files:
        findings = check_file(path)
        if not findings:
            print(f"\n## {path}\n\n✓ pass")
            continue
        findings.sort(key=lambda f: (f.level != "error", f.line))
        print(f"\n## {path}\n")
        for f in findings:
            mark = "" if f.level == "error" else "warn: "
            print(f"{path}:{f.line} - {mark}{f.message}")
            errors += f.level == "error"
            warnings += f.level == "warning"

    print(f"\n{errors} error(s), {warnings} warning(s), {len(files)} file(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
