from typing import List

from common.measure_fetch import do_measure, PathTest, JSON_HEADERS

from constants import DOMAIN, STUDENT_COOKIES, INSTRUCTOR_COOKIES


PATH_TESTS: List[PathTest] = [
    PathTest("/", cookies=STUDENT_COOKIES, content_snippet="Course2 (SEM)"),

    PathTest("/courses/Course0/assessments", cookies=STUDENT_COOKIES, content_snippet="Quiz 4"),
    PathTest("/courses/Course0/metrics/get_num_pending_instances", cookies=STUDENT_COOKIES, headers=JSON_HEADERS,
             status_code=403),

    PathTest("/courses/Course0/assessments/quiz4", cookies=STUDENT_COOKIES,
             content_snippet="user0@foo.bar_0_handin.c"),

    PathTest("/courses/Course0/assessments/quiz4/submissions/26000028/download", cookies=STUDENT_COOKIES,
             content_snippet="printf"),

    PathTest("/courses/Course0/assessments/quiz4/viewGradesheet", cookies=INSTRUCTOR_COOKIES,
             content_snippet="user40@foo.bar")
]


if __name__ == "__main__":
    do_measure(DOMAIN, PATH_TESTS)
