from typing import List

from common.measure_fetch import PathTest, JSON_HEADERS

from constants import COOKIES


DEFAULT_SLEEP = {"original": .2, "modified": .2, "cached": .2, "no-cache": 0}
PATH_TESTS: List[PathTest] = [
        # Account.
        PathTest("/account", cookies=COOKIES, content_snippet="123 Home Avenue", is_page_main=True, tag2sleep_s=DEFAULT_SLEEP),
        PathTest("/en/account_link?currency=USD", cookies=COOKIES, content_snippet="MY ACCOUNT"),
        PathTest("/api_tokens", cookies=COOKIES, content_snippet="order_token", headers=JSON_HEADERS),
        PathTest("/en/cart_link?currency=USD", cookies=COOKIES, content_snippet="cart-icon"),

        # Available item -- Polo T Shirt.
        PathTest("/products/polo-t-shirt", cookies=COOKIES, content_snippet="Polo T Shirt", is_page_main=True, tag2sleep_s=DEFAULT_SLEEP),
        #    Account link.
        #    API tokens.
        #    Cart link.

        # Discontinued item -- Checked Shirt.
        PathTest("/products/checked-shirt", cookies=COOKIES, content_snippet="You may have mistyped", status_code=404, is_page_main=True, tag2sleep_s=DEFAULT_SLEEP),

        # Cart.
        PathTest("/cart", cookies=COOKIES, content_snippet="Stripped Jumper", is_page_main=True, tag2sleep_s=DEFAULT_SLEEP),
        #    Account link.
        #    API tokens.
        #    Cart link.

        # Order.
        PathTest("/orders/R713119258", cookies=COOKIES, content_snippet="UPS Two Day", is_page_main=True, tag2sleep_s=DEFAULT_SLEEP),
        #    Account link.
        #    API tokens.
        #    Cart link.
]

