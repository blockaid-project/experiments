#!/usr/bin/env python3
"""
Extracts decision templates from colored log.
"""
from collections import defaultdict
from pathlib import Path
import sys


TEMPLATE_START = b"\x1b[30m\x1B[43m"
TEMPLATE_END = b"\x1b[0m"


def main():
    log_content = Path(sys.argv[1]).read_bytes()

    templates = []
    template_set = set()
    find_start = 0
    while True:
        this_start = log_content.find(TEMPLATE_START, find_start)
        if this_start == -1:
            break
        this_start += len(TEMPLATE_START)
        this_end = log_content.find(TEMPLATE_END, this_start)
        assert this_end != -1
        this_template = log_content[this_start:this_end].decode("ascii")
        if this_template not in template_set:
            template_set.add(this_template)
            templates.append(this_template)
        find_start = this_end + len(TEMPLATE_END)

    for t in templates:
        print(t)
        print()

    # templates_by_last_line = defaultdict(list)
    # for t in templates:
        # last_line = t.splitlines()[-1]
        # templates_by_last_line[last_line].append(t)


if __name__ == '__main__':
    main()

