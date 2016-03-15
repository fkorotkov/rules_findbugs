_xml_filetype = FileType([".xml"])

def _collect_jars(targets):
    """Compute the runtime and compile-time dependencies from the given targets"""
    jars = set()  # not transitive
    for target in targets:
        if hasattr(target, "java"):
            # we don't want stripped ijar jars from transitive_deps
            jars = jars | set(target.java.transitive_runtime_deps)
        else:
            fail('Bad target %s! FindBugs expects only java ones!' % target.label)
    return jars

def _findbugs_impl(ctx):
    cmd = """#!/bin/bash
    set -e
    output=$({java} -jar {findbugslib} {findbugs_args} {jars})
    echo "$output"
    if [ -n "$output" ]; then
        exit 1
    fi
    """

    java = ctx.file._java
    findbugslib = ctx.file._findbugslib
    jars = _collect_jars(ctx.attr.deps)

    files_for_cmd = [java, findbugslib]
    findbugs_args = ['-textui']

    if ctx.attr.options:
        findbugs_args += [ctx.attr.options]
    if ctx.file.include:
        files_for_cmd += [ctx.file.include]
        findbugs_args += ['-include', ctx.file.include.short_path]
    if ctx.file.exclude:
        files_for_cmd += [ctx.file.exclude]
        findbugs_args += ['-exclude', ctx.file.exclude.short_path]

    cmd = cmd.format(
        java=java.short_path,
        findbugslib=findbugslib.short_path,
        findbugs_args=" ".join(findbugs_args),
        jars=" ".join([j.short_path for j in jars]),
    )
    ctx.file_action(
        output=ctx.outputs.executable,
        content=cmd
    )

    runfiles = ctx.runfiles(
        files = list(jars) + [ctx.outputs.executable] + list(files_for_cmd),
        collect_data = True
    )
    return struct(files=set([ctx.outputs.executable]), runfiles=runfiles)

findbugs_test = rule(
    implementation=_findbugs_impl,
    attrs={
        "deps": attr.label_list(allow_files=False),
        "options": attr.string(mandatory=False),
        "include": attr.label(mandatory=False, allow_files=_xml_filetype, single_file=True),
        "exclude": attr.label(mandatory=False, allow_files=_xml_filetype, single_file=True),
        "_findbugslib": attr.label(default=Label("@findbugs//:lib/findbugs.jar"), single_file=True, allow_files=True),
        "_java": attr.label(executable=True, default=Label("@bazel_tools//tools/jdk:java"), single_file=True, allow_files=True),
    },
    test=True,
)

FINDBUGS_BUILD_FILE = """
# findbugs.BUILD
exports_files(["lib/findbugs.jar"])

filegroup(
    name = "findbugs_lib",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)
"""

def findbugs_repository():
    native.new_http_archive(
        name = "findbugs",
        strip_prefix = "findbugs-3.0.1",
        sha256 = "e8c88afb639f6ac09344afc74fb50be870db8473649e72596e4652fcc8c06bf5",
        # Seems Bazel doesn't handle Sourceforge's redirects
        url = "http://iweb.dl.sourceforge.net/project/findbugs/findbugs/3.0.1/findbugs-noUpdateChecks-3.0.1.zip",
        build_file_content = FINDBUGS_BUILD_FILE,
    )