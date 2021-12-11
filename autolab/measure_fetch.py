from common.measure_fetch import do_measure
from path_tests import PATH_TESTS
from constants import DOMAIN, STUDENT_COOKIES, INSTRUCTOR_COOKIES


if __name__ == "__main__":
    do_measure(DOMAIN, PATH_TESTS)

