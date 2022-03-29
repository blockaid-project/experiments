#!/usr/bin/env python3
"""
Measures page-load time (PLT) or fetch latency for an application.  Results are printed to stdout in CSV format.
Output might contain comment lines starting with `#`.
"""
import argparse
import csv
from dataclasses import dataclass
import os
import sys
from time import time, sleep
from timeit import default_timer as timer
from typing import Dict, Iterable, List, Optional, Sequence, Set, TypeVar
import urllib.parse

import requests
from selenium import webdriver
from selenium.webdriver.remote.webdriver import WebDriver
from tqdm import trange
import urllib3
import yaml

T = TypeVar("T")


@dataclass(frozen=True)
class PathTest:
    """A test case specification for a URL."""
    path: str  # URL to load.
    path_abbreviation: str  # Abbreviation for URL shown in paper.
    cookies: Dict[str, str]  # Cookies to send when loading the URL.
    content_snippet: Optional[str]  # To make sure the correct content is fetched; if None, fetched content not checked.
    headers: Dict[str, str] = None  # Extra headers to send (e.g., XMLHttpRequest).
    status_code: int = 200  # Expected status code; ignored in PLT measurements (Selenium doesn't expose status code).
    is_page_main: bool = False  # True if this is a workload's main URL.  We measure PLTs for only main URLs.
    page_name: str = None  # Name of the page used in paper (e.g., "Simple post").  Can only set for main pages.

    # Maps a tag (e.g., "cached" or "no-cache") to the amount of time to sleep after a page fetch.
    # The sleep is so that any asynchronous requests can finish before the next measurement; only for PLT measurements.
    # Only allowed for main pages because only we only measure PLT for those.
    tag2sleep_s: Dict[str, float] = None

    # If not None, this path is a file download.  The "PLT" for a file download is reported as the time difference
    # between when the request is sent and when the downloaded file is ready (because PLT is not well-defined for file
    # downloads).  Fetch latency measurement is no different for file downloads.
    download_file_name: str = None

    def __post_init__(self):
        if self.is_page_main:
            if self.download_file_name:
                assert self.tag2sleep_s is None, f"Sleep durations do not apply to download: {self.path}"
            else:
                assert self.tag2sleep_s is not None,\
                    f"For a non-download main page, sleep durations must be specified: {self.path}"
            assert self.page_name, f"Page name for a main URL cannot be empty: {self.path}"
            assert self.content_snippet is not None, f"A main URL must have a content snippet: {self.path}"
        else:
            assert self.page_name is None, f"Only main pages have names: {self.path}"
            assert self.tag2sleep_s is None,\
                f"For a non-main page URL, sleep durations are meaningless and should not be specified: {self.path}"

        assert self.path_abbreviation, f"Path abbreviation cannot be empty: {self.path}"


@dataclass(frozen=True)
class TestConfig:
    measure_kind: str  # What we're measuring.
    tag: str  # Tag for this run (e.g., no-cache, cold-cache).
    domain: str  # Domain name for the web server.
    warmup_rounds: int
    measure_rounds: int


def measure_fetch(config: TestConfig, path_test: PathTest) -> float:
    """Returns fetch time in milliseconds."""
    full_url = urllib.parse.urljoin(config.domain, path_test.path)
    start_s = timer()
    kwargs = {"cookies": path_test.cookies, "verify": False}
    if path_test.headers is not None:
        kwargs["headers"] = path_test.headers
    r = requests.get(full_url, **kwargs)
    duration_s = timer() - start_s
    assert r.status_code == path_test.status_code,\
        f"for {path_test.path}, expected status is: {path_test.status_code}, but got status: {r.status_code}"
    if path_test.content_snippet is not None:
        assert path_test.content_snippet in r.text, r.text
    return duration_s * 1e3


def measure_plt(config: TestConfig, path_test: PathTest, driver: WebDriver) -> float:
    """Returns page load time in milliseconds.  For a download URL, downloads file to working directory."""
    full_url = urllib.parse.urljoin(config.domain, path_test.path)

    for name, value in path_test.cookies.items():
        driver.add_cookie({"name": name, "value": value})

    download_file_name = path_test.download_file_name
    if download_file_name:
        try:
            os.remove(download_file_name)
        except OSError:
            pass

    start_s = time()
    driver.get(full_url)

    if download_file_name:
        while not os.path.exists(download_file_name):
            pass
        while True:
            with open(download_file_name, "r") as f:
                if path_test.content_snippet in f.read():
                    break
        download_time_ms = (time() - start_s) * 1e3

        return download_time_ms

    navigation_start = driver.execute_script("return window.performance.timing.navigationStart")
    load_event_end = driver.execute_script("return window.performance.timing.loadEventEnd")
    source = driver.page_source
    assert path_test.content_snippet in source, f"snippet not found in: {path_test.page_name} ({path_test.path}); source: {source}"
    plt_ms = load_event_end - navigation_start
    sleep(path_test.tag2sleep_s[config.tag])
    return plt_ms


def do_tests(config: TestConfig, tests: Sequence[PathTest], measure_func, extra_columns: List[str],
             *extra_args) -> None:
    if extra_columns is None:
        extra_columns = []

    for _ in trange(config.warmup_rounds, desc="warmup"):
        for pi, path_test in enumerate(tests):
            measure_func(config, path_test, *extra_args)

    print("# " + " ".join(sys.argv))
    writer = csv.DictWriter(
        sys.stdout, fieldnames=["measure_kind", "tag", "path", "round", "timestamp_s", "dur_ms"] + extra_columns)
    writer.writeheader()
    for i in trange(config.measure_rounds, desc="measure"):
        for pi, path_test in enumerate(tests):
            ts = time()
            dur_ms = measure_func(config, path_test, *extra_args)
            row = dict(measure_kind=config.measure_kind,
                       tag=config.tag,
                       path=path_test.path,
                       round=i,
                       timestamp_s=ts,
                       dur_ms=dur_ms)
            row.update({column: getattr(path_test, column) for column in extra_columns})
            writer.writerow(row)


def assert_no_duplicates(items: Iterable[T], name: str) -> None:
    seen: Set[T] = set()
    for item in items:
        assert item not in seen, f"duplicate {name}: {item}"
        seen.add(item)


def wait_for_web_server(domain: str, timeout_s: int) -> None:
    """Waits for web server to start up."""
    url = urllib.parse.urljoin(domain, "foobar")  # Non-existent URL.

    print("Waiting for server to start up.", file=sys.stderr, flush=True, end="")
    try:
        for _ in range(timeout_s):
            sleep(1)
            r = requests.get(url, verify=False)
            print(".", file=sys.stderr, flush=True, end="")
            if r.status_code == requests.codes.bad_gateway:  # A 502 indicates the server is not yet ready.
                continue
            elif r.status_code == requests.codes.not_found:  # A 404 indicates the server is ready.
                return
            else:
                raise Exception(f"wait_for_web_server: unexpected status code: {r.status_code}")

        raise Exception(f"wait_for_web_server: web server not ready after {timeout_s} seconds")
    finally:
        print(file=sys.stderr)  # Print a newline.



def main() -> None:
    """Entry point for the script."""
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)  # Suppresses warnings for self-signed certs.

    parser = argparse.ArgumentParser(description="Measure application performance.")
    parser.add_argument("measure_kind", choices=("plt", "fetch"),
                        help="what to measure -- page-load time or fetch duration")
    parser.add_argument("tag", type=str, help="tag for this run (e.g., no-cache, cold-cache)")
    parser.add_argument("config_path", type=str, help="path to the YAML configuration containing URLs to test")
    parser.add_argument("--warmup-rounds", type=int, default=2, help="number of loads to perform for warm up")
    parser.add_argument("--measure-rounds", type=int, default=2, help="number of loads to measure")
    args = parser.parse_args()

    # Parse test configuration.
    with open(args.config_path, "r") as f:
        config_content = yaml.safe_load(f)
    config = TestConfig(
        measure_kind=args.measure_kind,
        tag=args.tag,
        domain=config_content["domain"],
        warmup_rounds=args.warmup_rounds,
        measure_rounds=args.measure_rounds
    )
    tests = [PathTest(**d) for d in config_content["path_tests"]]

    # Validation: make sure paths, path abbreviations, and page names (when they exist) are distinct.
    assert_no_duplicates((test.path for test in tests), "path")
    assert_no_duplicates((test.path_abbreviation for test in tests), "path abbreviation")
    assert_no_duplicates((test.page_name for test in tests if test.page_name is not None), "page name")

    wait_for_web_server(config.domain, timeout_s=60)

    if args.measure_kind == "plt":
        chrome_options = webdriver.ChromeOptions()
        chrome_options.headless = True
        chrome_options.add_argument("ignore-certificate-errors")  # Allow self-signed certificates.
        driver = webdriver.Chrome(options=chrome_options)
        driver.implicitly_wait(1)
        try:
            # Must navigate to the domain before setting cookies; a nonexistent page (404) works.
            # https://www.selenium.dev/documentation/webdriver/browser/cookies/
            driver.get(urllib.parse.urljoin(config.domain, "foobar"))

            # Only measure PLTs for the main URL of each page.
            main_url_tests = [t for t in tests if t.is_page_main]
            do_tests(config, main_url_tests, measure_plt, ["page_name"], driver)
        finally:
            driver.close()
    else:
        assert args.measure_kind == "fetch", f"invalid kind: {args.measure_kind}"
        do_tests(config, tests, measure_fetch, ["path_abbreviation"])


if __name__ == '__main__':
    main()
