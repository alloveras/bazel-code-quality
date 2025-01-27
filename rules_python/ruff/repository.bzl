load("//rules_python/ruff:def.bzl", "RUFF_TOOLCHAIN_TYPE")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

TOOLCHAIN_TEMPLATE = """\
load("@//rules_python/ruff:def.bzl", "ruff_toolchain")

ruff_toolchain(
    name = "toolchain-cfg",
    ruff = "{ruff_label}",
    configuration = "{configuration_label}",
)

toolchain(
    name = "toolchain",
    exec_compatible_with = {exec_compatible_with},
    target_compatible_with = {target_compatible_with},
    toolchain_type = "{toolchain_type}",
    toolchain = ":toolchain-cfg",
    visibility = ["//visibility:public"],
)
"""

ARCHIVE_BUILD_FILE_TEMPLATE = """\
exports_files(
    ["{name}{exe}"],
    visibility = ["//visibility:public"],
)
"""

TRIPLE_CONSTRAINTS = {
    "aarch64-apple-darwin": ["@platforms//os:macos", "@platforms//cpu:aarch64"],
    "aarch64-pc-windows-msvc": ["@platforms//os:windows", "@platforms//cpu:aarch64"],
    "aarch64-unknown-linux-gnu": ["@platforms//os:linux", "@platforms//cpu:aarch64"],
    "aarch64-unknown-linux-musl": ["@platforms//os:linux", "@platforms//cpu:aarch64"],
    "x86_64-apple-darwin": ["@platforms//os:macos", "@platforms//cpu:x86_64"],
    "x86_64-pc-windows-msvc": ["@platforms//os:windows", "@platforms//cpu:x86_64"],
    "x86_64-unknown-linux-gnu": ["@platforms//os:linux", "@platforms//cpu:x86_64"],
    "x86_64-unknown-linux-musl": ["@platforms//os:linux", "@platforms//cpu:x86_64"],
}

def download_github_release(version, artifact, checksum):
    """Downloads a Ruff artifact from a GitHub release.

    Args:
        version: The Ruff version.
        artifact: The artifact name.
        checksum: The artifact integrity checksum.

    Returns:
        A single-entry dictionary where the key is Ruff's Bazel
        label and the value is Ruff's execution platform constraints.
    """
    base_url = "https://github.com/astral-sh/ruff/releases/download"

    exe = "ruff.exe" if "-windows-" in artifact else ""
    triple = artifact.removeprefix("ruff-").split(".")[0]
    strip_prefix = artifact.split(".")[0]

    name = "com_astral_sh_ruff_{version}_{suffix}".format(
        version = version.replace(".", "_"),
        suffix = triple.replace("-", "_"),
    )

    http_archive(
        name = name,
        urls = ["/".join([base_url, version, artifact])],
        integrity = checksum,
        strip_prefix = strip_prefix,
        build_file_content = ARCHIVE_BUILD_FILE_TEMPLATE.format(
            name = "ruff",
            exe = exe,
        ),
    )

    constraints = {
        "exec_compatible_with": TRIPLE_CONSTRAINTS[triple],
        # Ruff produces non-executable files and, hence,
        # they are compatible with all target platforms.
        "target_compatible_with": [],
    }

    return {
        "@{name}//:ruff{exe}".format(name = name, exe = exe): constraints,
    }

def _ruff_toolchains_impl(rctx):
    root = rctx.path(".")

    for label, raw_constraints in rctx.attr.toolchains.items():
        constraints = json.decode(raw_constraints)
        build_file = root.get_child(label.repo_name).get_child("BUILD.bazel")
        rctx.file(
            build_file,
            content = TOOLCHAIN_TEMPLATE.format(
                exec_compatible_with = constraints["exec_compatible_with"],
                target_compatible_with = constraints["target_compatible_with"],
                toolchain_type = RUFF_TOOLCHAIN_TYPE,
                ruff_label = label,
                configuration_label = rctx.attr.configuration,
            ),
            executable = False,
        )

    # Bazel does not allow calls to 'register_toolchains' with target patterns
    # that expand to empty sets. Hence we add an empty filegroup to the root
    # BUILD file to work around it.
    rctx.file(
        root.get_child("BUILD.bazel"),
        content = 'filegroup(name = "empty")',
        executable = False,
    )

ruff_toolchains = repository_rule(
    implementation = _ruff_toolchains_impl,
    attrs = {
        "configuration": attr.label(
            mandatory = True,
            allow_single_file = ["pyproject.toml"],
            doc = "The Ruff configuration.",
        ),
        "toolchains": attr.label_keyed_string_dict(
            mandatory = True,
            doc = "A mapping between toolchain label and its properties.",
        ),
    },
    doc = "Creates a bazel toolchains hub for Ruff.",
)
