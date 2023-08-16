# Package

version       = "0.1.0"
author        = "Pylgos"
description   = "tf2 binding"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0"
requires "rclnim"
requires "results"

task genTf2cBinding, "generate tf2c binding with c2nim":
  exec """c2nim ./src/tf2/private/tf2c.h \
            --header \
            --stdints \
            --cdecl \
            --reordercomments \
            -o:src/tf2/private/tf2c_gen.nim"""
