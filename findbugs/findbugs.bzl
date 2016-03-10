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
    cmd = "external/local_jdk/bin/java -jar {findbugslib} -output {out} {jars}"

    jars = _collect_jars(ctx.attr.deps)
    findbugslib = ctx.files._findbugslib[0]
    cmd = cmd.format(
        findbugslib=findbugslib.path,
        out=ctx.outputs.executable.path,
        jars=" ".join([j.path for j in jars]),
    )
    all_inputs = list(jars) + ctx.files._jdk + ctx.files._findbugslib
    ctx.action(
        inputs=all_inputs,
        outputs=[ctx.outputs.executable],
        command=cmd,
        progress_message="FindBugs %s" % ctx.label,
        mnemonic = "FindBugs",
        use_default_shell_env = True
    )
    all_runfiles = ctx.runfiles(files = all_inputs, collect_data = True)
    return struct(
        files=set([ctx.outputs.executable]),
        runfiles=all_runfiles)

findbugs_test = rule(
    implementation=_findbugs_impl,
    attrs={
        "deps": attr.label_list(allow_files=False),
        "_findbugslib": attr.label(default=Label("@findbugs//:lib/findbugs.jar"), single_file=True, allow_files=True),
        "_jdk": attr.label(default=Label("//tools/defaults:jdk"), allow_files=True),
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