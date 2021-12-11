from typing import List

from common.measure_fetch import PathTest, JSON_HEADERS

from constants import COOKIES


PATH_TESTS: List[PathTest] = [
    # Simple post.
    PathTest("/posts/33000073", cookies=COOKIES, content_snippet="Here's a post for my #family.", is_page_main=True, tag2sleep_s={"original": .3, "modified": .3, "cached": .3, "no-cache": 6}),
    PathTest("/notifications?per_page=10&page=1&_=1618953548170", cookies=COOKIES, content_snippet="unread_count", headers=JSON_HEADERS),
    PathTest("/posts/33000073/comments?_=1620113426256", cookies=COOKIES, content_snippet="yay!", headers=JSON_HEADERS),

    # Unauthorized post.
    PathTest("/posts/33000003", cookies=COOKIES, content_snippet="The page you were looking for doesn't exist (404)", status_code=404, is_page_main=True, tag2sleep_s={"original": .1, "modified": .1, "cached": .1, "no-cache": .1}),

    # Complex post.
    PathTest("/posts/33000071", cookies=COOKIES, content_snippet="A fourth poll!", is_page_main=True, tag2sleep_s={"original": .3, "modified": .3, "cached": .3, "no-cache": 35}),
    PathTest("/posts/33000071/comments?_=1620109750030", cookies=COOKIES, content_snippet="Nice poll!", headers=JSON_HEADERS),
    #   Notifications -- same as before.

    # Profile.
    PathTest("/people/30c2ef608e5c0139d94f011df6dc47b7", cookies=COOKIES, content_snippet="Homer Simpson", is_page_main=True, tag2sleep_s={"original": .3, "modified": .3, "cached": .3, "no-cache": 6}),
    PathTest("/people/30c2ef608e5c0139d94f011df6dc47b7/stream?_=1620109783129", cookies=COOKIES, content_snippet="I am an unauthorized Homer Simpson.", headers=JSON_HEADERS),
    #   Notifications -- same as before.

    # Conversation.
    PathTest("/conversations?conversation_id=12000002", cookies=COOKIES, content_snippet="Message 3.", is_page_main=True, tag2sleep_s={"original": .3, "modified": .3, "cached": .3, "no-cache": 6}),
    #   Notifications -- same as before.
]

