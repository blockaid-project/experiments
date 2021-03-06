#!/usr/bin/env python3
import argparse
from contextlib import ExitStack
from pathlib import Path
from typing import Optional, TextIO

import pandas as pd
import yaml

EXPERIMENTS_DIR = Path(__file__).parent.resolve().parent
APP_NAMES = ("diaspora", "spree", "autolab")


def format_duration(dur_ms: float, use_siunitx: bool) -> str:
    """
    If under 1000 ms, returns the millisecond duration as an integer (with no units); otherwise, returns duration in
    seconds (with ``s'').
    """
    if dur_ms < 1000:
        return f"{dur_ms:.0f}"

    if use_siunitx:
        return r"\SI{" + f"{dur_ms/1000:.2g}" + "}{s}"
    else:
        return f"{dur_ms/1000:.2g} s"


def print_app_data(data_directory: Path, app_name: str, use_siunitx: bool, overheads_file: Optional[TextIO]) -> None:
    # Load experiment data.
    df = pd.concat([pd.read_csv(p, comment='#') for p in (data_directory / app_name).glob("*/*.csv")])
    assert (df["measure_kind"] == "plt").all()
    dur_agg = df.groupby(["path", "tag"]).dur_ms.quantile([.5, .95])

    _format_duration = lambda _dur: format_duration(_dur, use_siunitx)
    def _dur_str(_path: str, _tag: str) -> str:
        return " / ".join(map(_format_duration, dur_agg[_path, _tag]))

    # Load application experiment metadata.
    with (EXPERIMENTS_DIR / app_name / "tests.yaml").open("r") as f:
        metadata = yaml.safe_load(f)

    print(r"\textbf{" + metadata["app_name"] + r"}\\")
    for path_test in metadata["path_tests"]:
        if not path_test.get("is_page_main"):
            continue
        path = path_test["path"]
        print(r"    \quad{}" + path_test["page_name"]
              + " & " + _dur_str(path, "original")
              + " & " + _dur_str(path, "modified")
              + " & " + _dur_str(path, "cached")
              + " & " + _dur_str(path, "no-cache") + r" \\")

        if overheads_file is not None:
            original = dur_agg[path, "original"]
            cached = dur_agg[path, "cached"]
            modified = dur_agg[path, "modified"]
            no_cache = dur_agg[path, "no-cache"]

            cached_over_modified   = ",".join(map(str, (cached - modified) / modified))
            no_cache_over_modified = ",".join(map(str, (no_cache - modified) / modified))
            modified_over_original = ",".join(map(str, (modified - original) / original))
            print(f"{app_name},{path_test['page_name']},{cached_over_modified},{no_cache_over_modified},{modified_over_original}", file=overheads_file)


def main():
    parser = argparse.ArgumentParser(description="Prints LaTeX table for page load times")
    parser.add_argument("data_directory")
    parser.add_argument("--no-siunitx", action="store_true", help="do not use siunitx")
    parser.add_argument("--overheads-output-path", type=str, help="print overhead CSV to this path")
    args = parser.parse_args()

    print(r"""
\begin{tabular}{lrrrr}
\toprule
& \multicolumn{4}{c}{\textbf{Page Load Time} (median / P95, default unit: ms)} \\
\cmidrule(lr){2-5}
& Original & Modified & Cached & No cache \\ \midrule
    """)

    with ExitStack() as stack:
        if args.overheads_output_path is not None:
            overheads_file = stack.enter_context(open(args.overheads_output_path, "w"))
            print("app,path,cached/modified50,cached/modified95,no_cache/modified50,no_cache/modified95,modified/original50,modified/original95", file=overheads_file)
        else:
            overheads_file = None

        data_directory = Path(args.data_directory) / "plt"
        for app_name in APP_NAMES:
            print_app_data(data_directory, app_name, use_siunitx=not args.no_siunitx, overheads_file=overheads_file)

        print(r"\bottomrule\end{tabular}")


if __name__ == '__main__':
    main()

