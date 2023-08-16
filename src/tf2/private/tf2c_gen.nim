##  types

type
  tf2c_duration_t* = distinct int64
  tf2c_timepoint_t* = distinct int64
  tf2c_bool_t* = bool
type
  tf2c_time_t* {.importc: "tf2c_time_t", header: "tf2c.h", bycopy.} = object
    sec* {.importc: "sec".}: int32
    nanosec* {.importc: "nanosec".}: uint32

  tf2c_string_t* {.importc: "tf2c_string_t", header: "tf2c.h", bycopy.} = object
    len* {.importc: "len".}: csize_t
    data* {.importc: "data".}: cstring

  tf2c_string_array_t* {.importc: "tf2c_string_array_t", header: "tf2c.h",
                         bycopy.} = object
    len* {.importc: "len".}: csize_t
    data* {.importc: "data".}: ptr tf2c_string_t

  tf2c_header_t* {.importc: "tf2c_header_t", header: "tf2c.h", bycopy.} = object
    stamp* {.importc: "stamp".}: tf2c_time_t
    frame_id* {.importc: "frame_id".}: tf2c_string_t

  tf2c_vector3_t* {.importc: "tf2c_vector3_t", header: "tf2c.h", bycopy.} = object
    x* {.importc: "x".}: cdouble
    y* {.importc: "y".}: cdouble
    z* {.importc: "z".}: cdouble

  tf2c_quaternion_t* {.importc: "tf2c_quaternion_t", header: "tf2c.h", bycopy.} = object
    x* {.importc: "x".}: cdouble
    y* {.importc: "y".}: cdouble
    z* {.importc: "z".}: cdouble
    w* {.importc: "w".}: cdouble

  tf2c_transform_t* {.importc: "tf2c_transform_t", header: "tf2c.h", bycopy.} = object
    translation* {.importc: "translation".}: tf2c_vector3_t
    rotation* {.importc: "rotation".}: tf2c_quaternion_t

  tf2c_transform_stamped_t* {.importc: "tf2c_transform_stamped_t",
                              header: "tf2c.h", bycopy.} = object
    header* {.importc: "header".}: tf2c_header_t
    child_frame_id* {.importc: "child_frame_id".}: tf2c_string_t
    transform* {.importc: "transform".}: tf2c_transform_t

  tf2c_transformable_result_t* {.size: sizeof(cint).} = enum
    TF2C_TRANSFORM_AVAILABLE, TF2C_TRANSFORM_FAILURE
  tf2c_transform_error_t* {.size: sizeof(cint).} = enum
    TF2C_OK, TF2C_ERROR_LOOKUP, TF2C_ERROR_CONNECTIVITY,
    TF2C_ERROR_EXTRAPOLATION, TF2C_ERROR_INVALID_ARGUMENT
  tf2c_transformable_request_handle_t* = uint64
  tf2c_transformable_callback_func_t* = proc (userdata: pointer;
      request_handle: tf2c_transformable_request_handle_t;
      target_frame: tf2c_string_t; source_frame: tf2c_string_t;
      time: tf2c_timepoint_t; result: tf2c_transformable_result_t) {.cdecl.}
  tf2c_transformable_callback_t* {.importc: "tf2c_transformable_callback_t",
                                   header: "tf2c.h", bycopy.} = object
    userdata* {.importc: "userdata".}: pointer
    `func`* {.importc: "func".}: tf2c_transformable_callback_func_t




proc tf2c_string_init*(chars: cstring; len: csize_t): tf2c_string_t {.cdecl,
    importc: "tf2c_string_init", header: "tf2c.h".}
proc tf2c_string_fini*(str: tf2c_string_t) {.cdecl, importc: "tf2c_string_fini",
    header: "tf2c.h".}
proc tf2c_string_array_init*(strs: ptr tf2c_string_t; len: csize_t): tf2c_string_array_t {.
    cdecl, importc: "tf2c_string_array_init", header: "tf2c.h".}
  ##  WARNING: this function takes ownership of the given strings
proc tf2c_string_array_fini*(array: tf2c_string_array_t) {.cdecl,
    importc: "tf2c_string_array_fini", header: "tf2c.h".}
type
  tf2c_buffer_core_ptr_t* = pointer ##  BufferCore

proc tf2c_buffer_core_init*(cache_time: tf2c_duration_t): tf2c_buffer_core_ptr_t {.
    cdecl, importc: "tf2c_buffer_core_init", header: "tf2c.h".}
proc tf2c_buffer_core_fini*(buf: tf2c_buffer_core_ptr_t) {.cdecl,
    importc: "tf2c_buffer_core_fini", header: "tf2c.h".}
proc tf2c_buffer_core_clear*(buf: tf2c_buffer_core_ptr_t) {.cdecl,
    importc: "tf2c_buffer_core_clear", header: "tf2c.h".}
proc tf2c_buffer_core_set_transform*(buf: tf2c_buffer_core_ptr_t;
                                     transform: ptr tf2c_transform_stamped_t;
                                     authority: tf2c_string_t;
                                     is_static: tf2c_bool_t): tf2c_bool_t {.
    cdecl, importc: "tf2c_buffer_core_set_transform", header: "tf2c.h".}
proc tf2c_buffer_core_lookup_transform_1*(buf: tf2c_buffer_core_ptr_t;
    target_frame: tf2c_string_t; target_time: tf2c_timepoint_t;
    source_frame: tf2c_string_t; source_time: tf2c_timepoint_t;
    fixed_frame: tf2c_string_t; result: ptr tf2c_transform_stamped_t): tf2c_transform_error_t {.
    cdecl, importc: "tf2c_buffer_core_lookup_transform_1", header: "tf2c.h".}
proc tf2c_buffer_core_lookup_transform_2*(buf: tf2c_buffer_core_ptr_t;
    target_frame: tf2c_string_t; source_frame: tf2c_string_t;
    time: tf2c_timepoint_t; result: ptr tf2c_transform_stamped_t): tf2c_transform_error_t {.
    cdecl, importc: "tf2c_buffer_core_lookup_transform_2", header: "tf2c.h".}
proc tf2c_buffer_core_can_transform_1*(buf: tf2c_buffer_core_ptr_t;
                                       target_frame: tf2c_string_t;
                                       source_frame: tf2c_string_t;
                                       time: tf2c_timepoint_t;
                                       error_msg: ptr tf2c_string_t): tf2c_bool_t {.
    cdecl, importc: "tf2c_buffer_core_can_transform_1", header: "tf2c.h".}
proc tf2c_buffer_core_can_transform_2*(buf: tf2c_buffer_core_ptr_t;
                                       target_frame: tf2c_string_t;
                                       target_time: tf2c_timepoint_t;
                                       source_frame: tf2c_string_t;
                                       source_time: tf2c_timepoint_t;
                                       fixed_frame: tf2c_string_t;
                                       error_msg: ptr tf2c_string_t): tf2c_bool_t {.
    cdecl, importc: "tf2c_buffer_core_can_transform_2", header: "tf2c.h".}
proc tf2c_buffer_core_get_all_frame_names*(buf: tf2c_buffer_core_ptr_t): tf2c_string_array_t {.
    cdecl, importc: "tf2c_buffer_core_get_all_frame_names", header: "tf2c.h".}
proc tf2c_buffer_core_all_frames_as_yaml_1*(buf: tf2c_buffer_core_ptr_t;
    current_time: tf2c_timepoint_t): tf2c_string_t {.cdecl,
    importc: "tf2c_buffer_core_all_frames_as_yaml_1", header: "tf2c.h".}
proc tf2c_buffer_core_all_frames_as_yaml_2*(buf: tf2c_buffer_core_ptr_t): tf2c_string_t {.
    cdecl, importc: "tf2c_buffer_core_all_frames_as_yaml_2", header: "tf2c.h".}
proc tf2c_buffer_core_all_frames_as_string*(buf: tf2c_buffer_core_ptr_t): tf2c_string_t {.
    cdecl, importc: "tf2c_buffer_core_all_frames_as_string", header: "tf2c.h".}
proc tf2c_buffer_core_add_transformable_request*(buf: tf2c_buffer_core_ptr_t;
    cb: tf2c_transformable_callback_t; target_frame: tf2c_string_t;
    source_frame: tf2c_string_t; time: tf2c_timepoint_t): tf2c_transformable_request_handle_t {.
    cdecl, importc: "tf2c_buffer_core_add_transformable_request",
    header: "tf2c.h".}
proc tf2c_cancel_transformable_request*(buf: tf2c_buffer_core_ptr_t; handle: tf2c_transformable_request_handle_t) {.
    cdecl, importc: "tf2c_cancel_transformable_request", header: "tf2c.h".}