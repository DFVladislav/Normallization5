#!/usr/bin/env python3
"""Keep SQL query records and their continuation lines from a MySQL general log."""

import re
import sys
from pathlib import Path


RECORD = re.compile(
    r"^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?"
    r"(?:Z|[+-]\d{2}:\d{2})?\s+\d+\s+([A-Za-z]+)\s+(.*)$"
)
INTERNAL_QUERY = re.compile(
    r"^(?:--|/\*|#|select @@version_comment\b|set names\b|"
    r"set global (?:general_log|general_log_file|log_output)\b)",
    re.IGNORECASE,
)


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "Usage: python sql/filter_log.py <general-log> <actions-log>",
            file=sys.stderr,
        )
        return 2

    source = Path(sys.argv[1])
    target = Path(sys.argv[2])
    kept: list[str] = []
    keep_continuation = False

    for line in source.read_text(encoding="utf-8-sig", errors="replace").splitlines():
        match = RECORD.match(line)
        if match:
            command, argument = match.groups()
            keep_continuation = (
                command.lower() in {"query", "execute"}
                and not INTERNAL_QUERY.match(argument.strip())
            )
            if keep_continuation:
                kept.append(line)
        elif keep_continuation and line.strip():
            kept.append(line)

    if not kept:
        print(f"No user SQL actions found in {source}", file=sys.stderr)
        return 1

    target.write_text("\n".join(kept) + "\n", encoding="utf-8", newline="\n")
    print(f"Wrote {len(kept)} lines to {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
