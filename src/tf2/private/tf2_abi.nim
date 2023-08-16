import rclnim/rospkgfinder
import std/os

static:
  configureRosPackage("tf2")

{.passC: "-I" & currentSourcePath.parentDir.}
{.compile: "tf2c.cpp".}

include tf2c_gen

proc `=destroy`(s: tf2c_string_t) =
  if s.data == nil: return
  tf2c_string_fini(s)

proc `=copy`(dest: var tf2c_string_t, src: tf2c_string_t) {.error.}

proc `=destroy`(s: tf2c_string_array_t) =
  if s.data == nil: return
  tf2c_string_array_fini(s)

proc `=copy`(dest: var tf2c_string_array_t, src: tf2c_string_array_t) {.error.}

# when isMainModule:
#   let buf = tf2c_buffer_core_init(10000000)
#   echo repr buf
#   tf2c_buffer_core_fini(buf)
#   echo "hi"
