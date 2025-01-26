"""Defines Canva-opinionated rules_python drop-ins."""

load(
    "@rules_python//python:defs.bzl",
    _py_binary = "py_binary",
    _py_library = "py_library",
    _py_test = "py_test",
)
load("//rules_python/ruff:def.bzl", "ruff")

def py_library(name, **kwargs):
    _py_library(**({"name": name} | kwargs))
    ruff(name = "%s.ruff" % name, srcs = kwargs["srcs"])

def py_binary(name, **kwargs):
    _py_binary(**({"name": name} | kwargs))
    ruff(name = "%s.ruff" % name, srcs = kwargs["srcs"])

def py_test(name, **kwargs):
    _py_test(**({"name": name} | kwargs))
    ruff(name = "%s.ruff" % name, srcs = kwargs["srcs"])
