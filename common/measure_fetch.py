#!/usr/bin/env python3
import argparse
import sys
from time import time
from timeit import default_timer as timer
from typing import NamedTuple, Dict, List
import urllib.parse

import requests
from tqdm import trange
import urllib3


class PathTest(NamedTuple):
    path: str
    cookies: Dict[str, str]
    content_snippet: str = None  # To make sure the correct content is fetched.
    headers: Dict[str, str] = None
    status_code: int = 200
    tag2sleep_s: Dict[str, int] = None


JSON_HEADERS = {"Accept": "application/json, text/javascript", "X-Requested-With": "XMLHttpRequest"}


def measure(domain: str, path_test: PathTest) -> float:
    """Returns fetch time in milliseconds."""
    full_url = urllib.parse.urljoin(domain, path_test.path)
    start = timer()
    kwargs = dict(cookies=path_test.cookies, verify=False)
    if path_test.headers is not None:
        kwargs["headers"] = path_test.headers
    r = requests.get(full_url, **kwargs)
    duration_s = timer() - start
    assert r.status_code == path_test.status_code, r.status_code
    if path_test.content_snippet is not None:
        assert path_test.content_snippet in r.text, r.text
    return duration_s * 1e3


def do_measure(domain: str, path_tests: List[PathTest]) -> None:
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    parser = argparse.ArgumentParser(description="Measure URL fetch times.")
    parser.add_argument("tag", type=str, help="identifier for this run")
    parser.add_argument("--warmup-rounds", type=int, default=100, help="number of page loads to perform for warm up")
    parser.add_argument("--measure-rounds", type=int, default=100, help="number of page loads to measure")

    args = parser.parse_args()

    # print(f"WARMUP {pi+1}/{len(path_tests)}: {path_test.path}", file=sys.stderr)
    for _ in trange(args.warmup_rounds, desc="warmup"):
        for pi, path_test in enumerate(path_tests):
            measure(domain, path_test)

    print("# " + " ".join(sys.argv))
    print("tag,path,round,ts,dur_ms")
    for i in trange(args.measure_rounds, desc="measure"):
        for pi, path_test in enumerate(path_tests):
            ts = time()
            dur_ms = measure(domain, path_test)
            print(f"{args.tag},{path_test.path},{i},{ts},{dur_ms:3g}")

