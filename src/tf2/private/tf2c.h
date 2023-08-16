#ifndef TF2C_H_INCLUDE_GUARD
#define TF2C_H_INCLUDE_GUARD

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* types */
#ifdef C2NIM
#@
type
  tf2c_duration_t* = distinct int64
  tf2c_timepoint_t* = distinct int64
  tf2c_bool_t* = bool
@#
#else
typedef int64_t tf2c_duration_t;
typedef int64_t tf2c_timepoint_t;
typedef uint8_t tf2c_bool_t;
#endif

typedef struct {
  int32_t sec;
  uint32_t nanosec;
} tf2c_time_t;

typedef struct {
  size_t len;
  char* data;
} tf2c_string_t;

typedef struct {
  size_t len;
  tf2c_string_t* data;
} tf2c_string_array_t;

typedef struct {
  tf2c_time_t stamp;
  tf2c_string_t frame_id;
} tf2c_header_t;

typedef struct {
  double x;
  double y;
  double z;
} tf2c_vector3_t;

typedef struct {
  double x;
  double y;
  double z;
  double w;
} tf2c_quaternion_t;

typedef struct {
  tf2c_vector3_t translation;
  tf2c_quaternion_t rotation;
} tf2c_transform_t;

typedef struct {
  tf2c_header_t header;
  tf2c_string_t child_frame_id;
  tf2c_transform_t transform;
} tf2c_transform_stamped_t;

typedef enum {
  TF2C_TRANSFORM_AVAILABLE,
  TF2C_TRANSFORM_FAILURE,
} tf2c_transformable_result_t;

typedef enum {
  TF2C_OK,
  TF2C_ERROR_LOOKUP,
  TF2C_ERROR_CONNECTIVITY,
  TF2C_ERROR_EXTRAPOLATION,
  TF2C_ERROR_INVALID_ARGUMENT,
} tf2c_transform_error_t;

typedef uint64_t tf2c_transformable_request_handle_t;
typedef void(*tf2c_transformable_callback_func_t)(void* userdata,
                                              tf2c_transformable_request_handle_t request_handle,
                                              tf2c_string_t target_frame,
                                              tf2c_string_t source_frame,
                                              tf2c_timepoint_t time,
                                              tf2c_transformable_result_t result);

typedef struct {
  void* userdata;
  tf2c_transformable_callback_func_t func;
} tf2c_transformable_callback_t;


tf2c_string_t tf2c_string_init(const char* chars, size_t len);
void tf2c_string_fini(tf2c_string_t str);

/* WARNING: this function takes ownership of the given strings */
tf2c_string_array_t tf2c_string_array_init(const tf2c_string_t* strs, size_t len);
void tf2c_string_array_fini(tf2c_string_array_t array);

/* BufferCore */
typedef void* tf2c_buffer_core_ptr_t;

tf2c_buffer_core_ptr_t tf2c_buffer_core_init(tf2c_duration_t cache_time);
void tf2c_buffer_core_fini(tf2c_buffer_core_ptr_t buf);
void tf2c_buffer_core_clear(tf2c_buffer_core_ptr_t buf);
tf2c_bool_t tf2c_buffer_core_set_transform(tf2c_buffer_core_ptr_t buf,
                                           const tf2c_transform_stamped_t* transform,
                                           tf2c_string_t authority,
                                           tf2c_bool_t is_static);
tf2c_transform_error_t tf2c_buffer_core_lookup_transform_1(tf2c_buffer_core_ptr_t buf,
                                                           tf2c_string_t target_frame,
                                                           tf2c_timepoint_t target_time,
                                                           tf2c_string_t source_frame,
                                                           tf2c_timepoint_t source_time,
                                                           tf2c_string_t fixed_frame,
                                                           tf2c_transform_stamped_t* result);
tf2c_transform_error_t tf2c_buffer_core_lookup_transform_2(tf2c_buffer_core_ptr_t buf,
                                                           tf2c_string_t target_frame,
                                                           tf2c_string_t source_frame,
                                                           tf2c_timepoint_t time,
                                                           tf2c_transform_stamped_t* result);
tf2c_bool_t tf2c_buffer_core_can_transform_1(tf2c_buffer_core_ptr_t buf,
                                             tf2c_string_t target_frame,
                                             tf2c_string_t source_frame,
                                             tf2c_timepoint_t time,
                                             tf2c_string_t* error_msg);
tf2c_bool_t tf2c_buffer_core_can_transform_2(tf2c_buffer_core_ptr_t buf,
                                             tf2c_string_t target_frame,
                                             tf2c_timepoint_t target_time,
                                             tf2c_string_t source_frame,
                                             tf2c_timepoint_t source_time,
                                             tf2c_string_t fixed_frame,
                                             tf2c_string_t* error_msg);
tf2c_string_array_t tf2c_buffer_core_get_all_frame_names(tf2c_buffer_core_ptr_t buf);
tf2c_string_t tf2c_buffer_core_all_frames_as_yaml_1(tf2c_buffer_core_ptr_t buf,
                                                    tf2c_timepoint_t current_time);
tf2c_string_t tf2c_buffer_core_all_frames_as_yaml_2(tf2c_buffer_core_ptr_t buf);
tf2c_string_t tf2c_buffer_core_all_frames_as_string(tf2c_buffer_core_ptr_t buf);
tf2c_transformable_request_handle_t tf2c_buffer_core_add_transformable_request(tf2c_buffer_core_ptr_t buf,
                                                                               tf2c_transformable_callback_t cb,
                                                                               tf2c_string_t target_frame,
                                                                               tf2c_string_t source_frame,
                                                                               tf2c_timepoint_t time);
void tf2c_cancel_transformable_request(tf2c_buffer_core_ptr_t buf,
                                       tf2c_transformable_request_handle_t handle);


#ifdef __cplusplus
}
#endif

#endif
