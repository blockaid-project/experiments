from typing import List

from common.measure_fetch import PathTest, JSON_HEADERS

from constants import STUDENT_COOKIES, INSTRUCTOR_COOKIES


DEFAULT_SLEEP = {"original": .2, "modified": .2, "cached": .2, "no-cache": .2}
PATH_TESTS: List[PathTest] = [
    PathTest("/", cookies=STUDENT_COOKIES, content_snippet="Course2 (SEM)", is_page_main=True, tag2sleep_s=DEFAULT_SLEEP),

    PathTest("/courses/Course0/assessments", cookies=STUDENT_COOKIES, content_snippet="Quiz 4", is_page_main=True, tag2sleep_s={"original": .3, "modified": .3, "cached": .3, "no-cache": 3}),
    PathTest("/courses/Course0/metrics/get_num_pending_instances", cookies=STUDENT_COOKIES, headers=JSON_HEADERS, status_code=403),

    PathTest("/courses/Course0/assessments/quiz4", cookies=STUDENT_COOKIES, content_snippet="user0@foo.bar_0_handin.c", is_page_main=True, tag2sleep_s=DEFAULT_SLEEP),

    PathTest("/courses/Course0/assessments/quiz4/submissions/26000028/download", cookies=STUDENT_COOKIES, content_snippet="printf", is_page_main=True, download_file_name="user0@foo.bar_quiz4_0_handin.c"),

    PathTest("/courses/Course0/assessments/quiz4/viewGradesheet", cookies=INSTRUCTOR_COOKIES, content_snippet="user40@foo.bar", is_page_main=True, tag2sleep_s=DEFAULT_SLEEP)
]
