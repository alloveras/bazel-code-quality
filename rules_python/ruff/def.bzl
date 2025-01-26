""""Defines Bazel rules for ruff."""

RUFF_TOOLCHAIN_TYPE = Label("//rules_python/ruff:toolchain_type")

RUFF_CHECK_SCRIPT = """
exit_code=0

# Force the creation of the dummy output file to please Bazel.
echo "" > {out}

if ! "{ruff}" check --quiet --config="{config}" "{src}" > {src}.ruff.check; then
    echo "\033[1m=============================== Lint Errors ====================================\033[0m"
    cat "{src}.ruff.check"
    exit_code=1
fi

if ! "{ruff}" format --quiet --config="{config}" --check --diff "{src}" > {src}.ruff.format; then
    echo "\033[1m============================== Format Errors ===================================\033[0m"
    cat "{src}.ruff.format"
    exit_code=1
fi

if [[ ${{exit_code}} -ne 0 ]]; then
    echo "\033[1m================================================================================\033[0m"
fi

exit "${{exit_code}}"
"""

def _ruff_impl(ctx):
    toolchain = ctx.toolchains[RUFF_TOOLCHAIN_TYPE]

    validation_outs = []

    for src in ctx.files.srcs:
        dummy_out = ctx.actions.declare_file(src.path + ".ruff.dummy")
        ctx.actions.run_shell(
            inputs = [src, toolchain.ruff, toolchain.configuration],
            outputs = [dummy_out],
            command = RUFF_CHECK_SCRIPT.format(
                ruff = toolchain.ruff.path,
                config = toolchain.configuration.path,
                src = src.path,
                out = dummy_out.path,
            ),
            env = {
                "RUFF_CACHE_DIR": ".bazel-action-cache/ruff",
                "FORCE_COLOR": "1",
            },
            mnemonic = "RuffCheck",
            toolchain = RUFF_TOOLCHAIN_TYPE,
        )

        validation_outs.append(dummy_out)

    return [
        DefaultInfo(),
        OutputGroupInfo(
            _validation = validation_outs,
        ),
    ]

ruff = rule(
    implementation = _ruff_impl,
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = [".py"],
            allow_empty = False,
        ),
    },
    toolchains = [RUFF_TOOLCHAIN_TYPE],
    doc = "",
)

def _ruff_toolchain_impl(ctx):
    """Defines a Ruff toolchain for Bazel.

    Args:
        ctx: A Bazel rule context object.
    """
    return [
        platform_common.ToolchainInfo(
            name = str(ctx.label),
            ruff = ctx.executable.ruff,
            configuration = ctx.file.configuration,
        ),
    ]

ruff_toolchain = rule(
    implementation = _ruff_toolchain_impl,
    attrs = {
        "ruff": attr.label(
            allow_single_file = ["ruff", "ruff.exe"],
            mandatory = True,
            cfg = "exec",
            executable = True,
            doc = "The ruff executable.",
        ),
        "configuration": attr.label(
            # TODO(alloveras): Support multiple/additional configuration files?
            allow_single_file = ["pyproject.toml"],
            mandatory = True,
            doc = "The pyproject.toml file.",
        ),
    },
    provides = [platform_common.ToolchainInfo],
    doc = "Defines a ruff toolchain.",
)
