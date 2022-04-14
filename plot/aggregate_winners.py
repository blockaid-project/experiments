#!/usr/bin/env python3
"""
Counts the number of wins for each solver (excluding warmup runs).

Assumes the number of warmup runs equals the number of actual runs.
"""
from pathlib import Path
from csv import DictWriter
import re
import sys
import tarfile
from typing import Counter, List

APP_NAMES = ("diaspora", "spree", "autolab")

END_OF_TRACE = b"End of trace"
UCORE_WINNER_PATTERN = re.compile(r"name=([^,]+)")
NO_CACHE_WINNER_PATTERN = re.compile(r"Invoke solvers:\s\d+,(.+)")


def read_lines_from_tar(path: Path) -> List[bytes]:
    with tarfile.open(path) as f:
        lines = f.extractfile("server.log").read().split(b'\n')
    return lines


def skip_warmup(lines: List[bytes]) -> List[bytes]:
    total_num_traces = sum(1 for line in lines if END_OF_TRACE in line)
    assert total_num_traces % 2 == 0, "there must be an even number of traces (the first half of which are warmup)"

    # Skip the first half of the traces (they're warmup).
    idx = 0
    for _ in range(total_num_traces // 2):
        while END_OF_TRACE not in lines[idx]:
            idx += 1
        idx += 1

    return lines[idx:]


def print_ucore_winners(data_directory: Path, app_name: str, writer: DictWriter) -> None:
    lines = read_lines_from_tar(data_directory / "fetch" / app_name / "cold-cache" / "server_log.tar.gz")
    lines = skip_warmup(lines)

    num_traces = 0  # Excluding warmup traces.
    ucore_winners = Counter[str]()
    for line in lines:
        if b"Winner:" in line:
            line = line.decode("ascii")
            winner_name = UCORE_WINNER_PATTERN.search(line).group(1)
            if winner_name.startswith("vampire"):
                winner_name = "vampire"
            ucore_winners[winner_name] += 1
        elif END_OF_TRACE in line:
            num_traces += 1

    print(f"[{app_name}, ucore] Total traces (exclude warmup) = {num_traces}", file=sys.stderr)
    for winner, count in ucore_winners.items():
        writer.writerow(dict(app_name=app_name, kind="cold_cache", winner=winner, count=count))


def print_no_cache_winners(data_directory: Path, app_name: str, writer: DictWriter) -> None:
    lines = read_lines_from_tar(data_directory / "fetch" / app_name / "no-cache" / "server_log.tar.gz")
    lines = skip_warmup(lines)

    num_traces = 0
    no_cache_winners = Counter[str]()
    for line in lines:
        if b"Invoke solvers:" in line:
            line = line.decode("ascii")
            winner_name = NO_CACHE_WINNER_PATTERN.search(line).group(1)
            assert winner_name.endswith("_fast")
            winner_name = winner_name.rstrip("_fast")
            if winner_name.startswith("vampire"):
                winner_name = "vampire"
            no_cache_winners[winner_name] += 1
        elif END_OF_TRACE in line:
            num_traces += 1

    print(f"[{app_name}, no_cache] Total traces (exclude warmup) = {num_traces}", file=sys.stderr)
    for winner, count in no_cache_winners.items():
        writer.writerow(dict(app_name=app_name, kind="no_cache", winner=winner, count=count))


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} data_directory")
        sys.exit(1)
    data_directory = Path(sys.argv[1])

    writer = DictWriter(sys.stdout, ["app_name", "kind", "winner", "count"])
    writer.writeheader()

    for app_name in APP_NAMES:
        print_ucore_winners(data_directory, app_name, writer)
        print_no_cache_winners(data_directory, app_name, writer)


if __name__ == '__main__':
    main()
