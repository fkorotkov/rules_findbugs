load("//findbugs:findbugs.bzl", "findbugs_test")

java_library(
    name = "good-lib",
    srcs = ["Good.java"],
)

findbugs_test(
    name="good-bugs",
    deps = [
        ":good-lib",
    ]
)

java_library(
    name = "bad-lib",
    srcs = ["Bad.java"],
)

findbugs_test(
    name="bad-bugs",
    deps = [
        ":bad-lib",
    ]
)

findbugs_test(
    name="bad-bugs-excluded",
    exclude="exclude.xml",
    deps = [
        ":bad-lib",
    ]
)
