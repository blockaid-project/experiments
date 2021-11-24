from typing import List

from common.measure_fetch import do_measure, PathTest, JSON_HEADERS

from constants import DOMAIN, COOKIES


PATH_TESTS: List[PathTest] = [
        # Account.
        PathTest("/account", cookies=COOKIES, content_snippet="123 Home Avenue"),
        PathTest("/en/account_link?currency=USD", cookies=COOKIES, content_snippet="MY ACCOUNT"),
        PathTest("/api_tokens", cookies=COOKIES, content_snippet="order_token", headers=JSON_HEADERS),
        PathTest("/en/cart_link?currency=USD", cookies=COOKIES, content_snippet="cart-icon", headers=JSON_HEADERS),

        # Available item -- Polo T Shirt.
        PathTest("/products/polo-t-shirt", cookies=COOKIES, content_snippet="Polo T Shirt"),
        #    Account link.
        #    API tokens.
        #    Cart link.

        # Discontinued item -- Checked Shirt.
        PathTest("/products/checked-shirt", cookies=COOKIES, content_snippet="You may have mistyped", status_code=404),

        # Cart.
        PathTest("/cart", cookies=COOKIES, content_snippet="Stripped Jumper"),
        #    Account link.
        #    API tokens.
        #    Cart link.

        # Order.
        PathTest("/orders/R713119258", cookies=COOKIES, content_snippet="UPS Two Day"),
        #    Account link.
        #    API tokens.
        #    Cart link.
]


if __name__ == "__main__":
    do_measure(DOMAIN, PATH_TESTS)

