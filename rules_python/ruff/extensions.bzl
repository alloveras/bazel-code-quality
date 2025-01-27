"""Module extensions re-export."""

load(
    "//rules_python/ruff:repository.bzl",
    "download_github_release",
    "ruff_toolchains",
)

def _ruff_impl(mctx):
    # For now, we only care about the root module. At this point it is
    # unclear whether or not transitive dependencies should even be considered
    # for Ruff toolchains since it's unlikely for consumers to care/want to
    # lint/format third-party code.
    root_module = mctx.modules[0]

    toolchains = {}
    for gh in root_module.tags.github_toolchains:
        for art, chs in gh.artifacts.items():
            toolchains |= download_github_release(gh.version, art, chs)

    configurations = []
    for cfg in root_module.tags.configuration:
        configurations.append(cfg.file)

    if len(configurations) != 1:
        fail("Expected exactly one Ruff configuration file, but found %s." % configurations)

    ruff_toolchains(
        name = "ruff_toolchains",
        toolchains = {k: json.encode(v) for k, v in toolchains.items()},
        configuration = configurations[0],
    )

    return mctx.extension_metadata(reproducible = True)

ruff = module_extension(
    implementation = _ruff_impl,
    tag_classes = {
        "configuration": tag_class(
            attrs = {
                "file": attr.label(
                    mandatory = True,
                    allow_single_file = ["pyproject.toml"],
                    doc = "The pyproject.toml file.",
                ),
            },
            doc = "The Ruff configuration.",
        ),
        # "host_toolchain": tag_class(
        #     attrs = {
        #         "name": attr.string(
        #             mandatory = True,
        #             doc = "The name of the host toolchain.",
        #         ),
        #         "exec_compatible_with": attr.label_list(
        #             mandatory = False,
        #             providers = [platform_common.ConstraintValueInfo],
        #             doc = "Additional host platform constraints.",
        #         ),
        #     },
        #     doc = "Defines a host toolchain for Ruff.",
        # ),
        "github_toolchains": tag_class(
            attrs = {
                "version": attr.string(
                    mandatory = True,
                    doc = "The Ruff version.",
                ),
                "artifacts": attr.string_dict(
                    mandatory = True,
                    doc = (
                        "The platforms for which to configure toolchains and " +
                        "their respective integrity checksums."
                    ),
                ),
            },
            doc = "Defines Ruff toolchains from an official release.",
        ),
        # "toolchain": tag_class(
        #     attrs = {
        #         "name": attr.string(
        #             mandatory = True,
        #             doc = "The name of the toolchain.",
        #         ),
        #         "ruff": attr.label(
        #             mandatory = True,
        #             allow_single_file = ["ruff", "ruff.exe"],
        #             cfg = "exec",
        #             executable = True,
        #             doc = "The Ruff executable.",
        #         ),
        #         "exec_compatible_with": attr.label_list(
        #             mandatory = True,
        #             providers = [platform_common.ConstraintValueInfo],
        #             doc = "The execution platform constraints.",
        #         ),
        #         "target_compatible_with": attr.label_list(
        #             mandatory = False,
        #             default = [],
        #             providers = [platform_common.ConstraintValueInfo],
        #             doc = "The target platform constraints.",
        #         ),
        #     },
        #     doc = "Defines a Ruff tooolchain.",
        # ),
    },
    doc = "An extension to setup and configure Ruff toolchains.",
)
