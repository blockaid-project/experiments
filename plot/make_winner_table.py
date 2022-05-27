#!/usr/bin/env python3
"""
Takes aggregate winner csv from stdin.
"""
import sys

import pandas as pd

APP_NAMES = {"diaspora": r"\diaspora", "spree": "Spree", "autolab": "Autolab"}
SOLVERS = {"z3": "Z3", "cvc5": r"\cvc", "vampire": "Vampire"}


def print_table(df, kind: str) -> None:
    df = df[df.kind == kind].pivot(index="app_name", columns="winner", values="count")
    print(r"""
    \begin{tabular}{lrrr}
    \toprule
    & \multicolumn{3}{c}{\bf Fraction of Wins (%)} \\
    \cmidrule(lr){2-4} {\bf Application} &
    """)
    print(" & ".join(SOLVERS.values()))
    print(r"\\ \midrule")

    for app_name, app_name_disp in APP_NAMES.items():
        print(app_name_disp, end="")
        for solver in SOLVERS:
            pass
        print(r" \\")

    print(r"\end{tabular}")
    pass


def main():
    df = pd.read_csv(sys.stdin)

    df_cold_cache = df[df.kind == "cold_cache"].pivot(index="app_name", columns="winner", values="count")
    print(df_cold_cache)

    df_no_cache = df[df.kind == "no_cache"].pivot(index="app_name", columns="winner", values="count")


if __name__ == '__main__':
    main()
