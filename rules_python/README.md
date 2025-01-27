# rules_python

This diretory contains a prototype to integrate Python linting and formatting
tools with `rules_python`.

## Goals

- [X] All validations are executed as Bazel actions to benefit from RBE's
  action parallelization, action de-duplication and caching.

- [X] All validations run as part of `bazel {build,test} //...` without any
  additional flags required.

- [X] All validations errors are presented in human-friendly format.

- [X] Successful validation actions produce no output.

- [X] SARIF reports can be requested on-demand using a dedicated
   Bazel output group (e.g. `--output_groups=+static_analysis`).

- [ ] Code editors (e.g. `IntellJ`, `VSCode`) can be easily configured to
  re-use the same Ruff toolchan as Bazel.

## Directory Structure

```
rules_python/
    ruff/
        def.bzl             # Bazel toolchain and build rules for Ruff.
        extensions.bzl      # Bazelmod extension for Ruff.
        repository.bzl      # Repository rules to download and configure Ruff toolchains.
    tests/
        ...                 # Example Python application with formatting and linting errors.
    def.bzl                 # rules_python drop-ins that include Ruff validations.
third_party/
    astral-sh/
        RUFF.MODULE.bazel   # MODULE.bazel configuration snippet.
```

## Examples

### Enable Ruff validations

To enable Ruff validations, modify the `load` statement at the top of
`//rules_python/tests/BUILD.bazel` as shown below:

```diff
- load("@rules_python//python:defs.bzl", "py_binary", "py_library", "py_test")
+ load("//rules_python:defs.bzl", "py_binary", "py_library", "py_test")
```

To see how the integration with Ruff behaves on a project that has some
deliberate linting and formatting failures, run the following Bazel commands.

```shell
bazel build //...
```

```shell
bazel test //...
```

This command should report (in human-friendly format) the linting and formatting
issues found in the codebase. However, due to Bazel's lazy approach to executing
actions, the reported set of errors may **not** be complete because some of the
validations may be either cancelled or not even run after the first failure is
encountered.

As a workaround, consider running the above command the `--keep_going` flag
set to `true` to instruct Bazel not to stop after the first failure:

```shell
bazel build --keep_going=true //...
```

```shell
bazel test --keep_going=true //...
```

Note that the validations are run in both `build` and `test` Bazel subcommands.

## Produce SARIF reports

To request `SARIF` reports for the linting and formatting violations, you can
simply request the additional `static_analysis` output group:

```shell
bazel build --keep_going=true --output_groups=+static_analysis //...
```

```shell
bazel test --keep_going=true --output_groups=+static_analysis //...
```

The commands above keep reporting the validation errors in human-friendly format
but, additionally, produce their corresponding `SARIF` files to facilitate the
integration with external tools (e.g. [GitHub CodeScanning](https://docs.github.com/en/code-security/code-scanning/introduction-to-code-scanning/about-code-scanning#about-third-party-code-scanning-tools)).

You can find all the generated `SARIF` files using the following command:

```shell
find $(bazel info bazel-bin)/ -name "*.sarif"
```
