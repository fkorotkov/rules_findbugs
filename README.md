# [FindBugs](http://findbugs.sourceforge.net/) Rules for [Bazel Build System](http://bazel.io/)

`findbugs_test` rule is used for finding bugs in Java projects with Bazel. In order to use `scala_findbugs_test` you must have bazel 0.2.0 and add the following to your WORKSPACE file:

```python
git_repository(
    name = "com_github_fkorotkov_rules_findbugs",
    remote = "https://github.com/fkorotkov/rules_findbugs.git",
    tag = "0.1"
)
load("@com_github_fkorotkov_rules_findbugs//findbugs:findbugs.bzl", "findbugs_repository")
findbugs_repository()
```

## Usage

```python
java_library(name = "foo-lib", ...)

findbugs_test(
    name="foo-findbugs",
    exclude="findbugs-exclude.xml",
    deps = [
        ":foo-lib",
    ],
    size="small"
)
```