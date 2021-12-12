#!/usr/bin/env python3
import argparse
import os.path
import sys
from time import time, sleep
from typing import NamedTuple, Dict, List
import urllib.parse

from selenium import webdriver
from tqdm import trange

from common.measure_fetch import PathTest


def measure(tag: str, driver, domain: str, path_test: PathTest) -> float:
    """Returns page load time in milliseconds."""
    full_url = urllib.parse.urljoin(domain, path_test.path)

    for name, value in path_test.cookies.items():
        driver.add_cookie({"name": name, "value": value})

    start_s = time()
    driver.get(full_url)
    get_time_ms = (time() - start_s) * 1e3
    download_file_name = path_test.download_file_name
    if download_file_name:
        assert os.path.exists(download_file_name)
        os.remove(download_file_name)
        return get_time_ms

    navigation_start = driver.execute_script("return window.performance.timing.navigationStart")
    load_event_end = driver.execute_script("return window.performance.timing.loadEventEnd")
    source = driver.page_source
    assert path_test.content_snippet in source, f"snippet not found in: {source}"
    plt_ms = load_event_end - navigation_start
    sleep(path_test.tag2sleep_s[tag])
    return plt_ms


def do_measure(domain: str, path_tests: List[PathTest]) -> None:
    path_tests = [pt for pt in path_tests if pt.is_page_main]

    parser = argparse.ArgumentParser(description="Measure page load times.")
    parser.add_argument("tag", type=str, help="identifier for this run")
    parser.add_argument("--warmup-rounds", type=int, default=100, help="number of page loads to perform for warm up")
    parser.add_argument("--measure-rounds", type=int, default=100, help="number of page loads to measure")

    args = parser.parse_args()

    chrome_options = webdriver.ChromeOptions()
    chrome_options.headless = True
    chrome_options.add_argument("ignore-certificate-errors")
    driver = webdriver.Chrome(options=chrome_options)
    driver.implicitly_wait(1)

    tag = args.tag
    try:
        driver.get(urllib.parse.urljoin(domain, "foobar"))

        for _ in trange(args.warmup_rounds, desc="warmup"):
            for pi, path_test in enumerate(path_tests):
                measure(tag, driver, path_test)

        print("# " + " ".join(sys.argv))
        print("tag,path,round,ts,plt_ms")
        for i in trange(args.measure_rounds, desc="measure"):
            for pi, path_test in enumerate(path_tests):
                ts = time()
                plt_ms = measure(tag, driver, domain, path_test)
                print(f"{tag},{path_test.path},{i},{ts},{plt_ms:3g}", flush=True)
    finally:
        driver.close()

