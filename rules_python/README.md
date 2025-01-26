# rules_python

This diretory contains a prototype to integrate Canva's linting and formatting
tools for Python with `rules_python`.

## Goals

- [X] All validations must be done as Bazel actions to benefit from Bazel's RBE
  action parallelization, action de-duplication and caching.

- [X] All validations must run as part of `bazel {build,test} //...`. That is,
  no additional flags required.

- [X] All validations errors must be presented in human-friendly format.

- [X] Successful validation actions must produce no output.

- [ ] Additional machine-readable validation output can be requested on-demand
  (e.g. `sarif`, `jsonl`, `diff`) via Bazel output groups.

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

To see how the integration with Ruff behaves on a project that has some
deliberate linting and formatting failures, run the following Bazel command:

```shell
bazel test //rules_python/tests/...
```

**Note**: The command above stops at the first error encountered. If an
exhaustive list of errors is desired, then `--keep_going=true` must be used.

```shell
bazel test --keep_going=true  //rules_python/tests/...
```
