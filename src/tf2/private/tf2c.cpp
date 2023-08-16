#include <tf2/buffer_core.h>
#include "tf2c.h"
#include <string.h>

using namespace tf2;

static Duration convert_duration(tf2c_duration_t from) {
  return Duration(from);
}

static tf2c_duration_t convert_duration(Duration from) {
  return std::chrono::duration_cast<std::chrono::nanoseconds>(from).count();
}

static TimePoint convert_timepoint(tf2c_timepoint_t from) {
  return TimePoint(std::chrono::nanoseconds(from));
}

static tf2c_timepoint_t convert_timepoint(TimePoint from) {
  return convert_duration(from.time_since_epoch());
}

static tf2c_string_t convert_string(const std::string& s) {
  return tf2c_string_init(s.c_str(), s.size());
}

static std::string convert_string(tf2c_string_t s) {
  std::string result;
  if (s.len > 0) {
    result.resize(s.len);
    memcpy(&result[0], s.data, s.len);
  }
  return result;
}

static tf2c_string_array_t convert_string_array(std::vector<std::string> from) {
  if (from.size() == 0) return {0, nullptr};
  std::vector<tf2c_string_t> strs(from.size());
  for (size_t i = 0; i < from.size(); i++) {
    strs[i] = convert_string(from[i]);
  }
  auto result = tf2c_string_array_init(&strs[0], strs.size());
  return result;
}

static geometry_msgs::msg::TransformStamped convert_transform_stamped(const tf2c_transform_stamped_t* from) {
  geometry_msgs::msg::TransformStamped result;
  result.header.frame_id = convert_string(from->header.frame_id);
  result.header.stamp.sec = from->header.stamp.sec;
  result.header.stamp.nanosec = from->header.stamp.nanosec;
  result.child_frame_id = convert_string(from->child_frame_id);
  result.transform.translation.x = from->transform.translation.x;
  result.transform.translation.y = from->transform.translation.y;
  result.transform.translation.z = from->transform.translation.z;
  result.transform.rotation.x = from->transform.rotation.x;
  result.transform.rotation.y = from->transform.rotation.y;
  result.transform.rotation.z = from->transform.rotation.z;
  result.transform.rotation.w = from->transform.rotation.w;
  return result;
}

static tf2c_transform_stamped_t convert_transform_stamped(const geometry_msgs::msg::TransformStamped* from) {
  tf2c_transform_stamped_t result;
  result.header.frame_id = convert_string(from->header.frame_id);
  result.header.stamp.sec = from->header.stamp.sec;
  result.header.stamp.nanosec = from->header.stamp.nanosec;
  result.child_frame_id = convert_string(from->child_frame_id);
  result.transform.translation.x = from->transform.translation.x;
  result.transform.translation.y = from->transform.translation.y;
  result.transform.translation.z = from->transform.translation.z;
  result.transform.rotation.x = from->transform.rotation.x;
  result.transform.rotation.y = from->transform.rotation.y;
  result.transform.rotation.z = from->transform.rotation.z;
  result.transform.rotation.w = from->transform.rotation.w;
  return result;
}

static tf2c_transformable_result_t convert_transformable_result(TransformableResult from) {
  switch (from) {
    case TransformableResult::TransformAvailable:
      return TF2C_TRANSFORM_AVAILABLE;
    case TransformableResult::TransformFailure:
      return TF2C_TRANSFORM_FAILURE;
  }
}


extern "C" {

tf2c_string_t tf2c_string_init(const char* chars, size_t len) {
  if (len == 0) return {0, nullptr};
  tf2c_string_t result;
  result.len = len;
  result.data = static_cast<char*>(malloc(len));
  memcpy(result.data, chars, len);
  return result;
}

void tf2c_string_fini(tf2c_string_t str) {
  if (str.data == nullptr) return;
  free(str.data);
  str.data = nullptr;
  str.len = 0;
}

tf2c_string_array_t tf2c_string_array_init(const tf2c_string_t* strs, size_t len) {
  if (len == 0) return {0, nullptr};
  tf2c_string_array_t result;
  result.len = len;
  result.data = static_cast<tf2c_string_t*>(malloc(sizeof(tf2c_string_t) * len));
  memcpy(result.data, strs, sizeof(tf2c_string_t) * len);
  return result;
}

void tf2c_string_array_fini(tf2c_string_array_t array) {
  if (array.data == nullptr) return;
  for (size_t i = 0; i < array.len; i++) {
    tf2c_string_fini(array.data[i]);
  }
  free(array.data);
}

#define self static_cast<BufferCore*>(buf)

tf2c_buffer_core_ptr_t tf2c_buffer_core_init(tf2c_duration_t cache_time) {
  const auto time = convert_duration(cache_time);
  return new BufferCore(time);
}

void tf2c_buffer_core_fini(tf2c_buffer_core_ptr_t buf) {
  delete self;
}

void tf2c_buffer_core_clear(tf2c_buffer_core_ptr_t buf) {
  self->clear();
}

tf2c_bool_t tf2c_buffer_core_set_transform(tf2c_buffer_core_ptr_t buf,
                                           const tf2c_transform_stamped_t* transform,
                                           tf2c_string_t authority,
                                           tf2c_bool_t is_static) {
  const auto auth = convert_string(authority);
  const auto tr = convert_transform_stamped(transform);
  return self->setTransform(tr, auth, is_static);
}

tf2c_transform_error_t tf2c_buffer_core_lookup_transform_1(tf2c_buffer_core_ptr_t buf,
                                                           tf2c_string_t target_frame,
                                                           tf2c_timepoint_t target_time,
                                                           tf2c_string_t source_frame,
                                                           tf2c_timepoint_t source_time,
                                                           tf2c_string_t fixed_frame,
                                                           tf2c_transform_stamped_t* result) {
  try {
    const auto tgt_frame = convert_string(target_frame);
    const auto tgt_time = convert_timepoint(target_time);
    const auto src_frame = convert_string(source_frame);
    const auto src_time = convert_timepoint(source_time);
    const auto f_frame = convert_string(fixed_frame);
    auto res = self->lookupTransform(tgt_frame, tgt_time, src_frame, src_time, f_frame);
    *result = convert_transform_stamped(&res);
  } catch (LookupException&) {
    return TF2C_ERROR_LOOKUP;
  } catch (ConnectivityException&) {
    return TF2C_ERROR_CONNECTIVITY;
  } catch (ExtrapolationException&) {
    return TF2C_ERROR_EXTRAPOLATION;
  } catch (InvalidArgumentException&) {
    return TF2C_ERROR_INVALID_ARGUMENT;
  }
  return TF2C_OK;
}

tf2c_transform_error_t tf2c_buffer_core_lookup_transform_2(tf2c_buffer_core_ptr_t buf,
                                                           tf2c_string_t target_frame,
                                                           tf2c_string_t source_frame,
                                                           tf2c_timepoint_t time,
                                                           tf2c_transform_stamped_t* result) {
  try {
    const auto tgt_frame = convert_string(target_frame);
    const auto src_frame = convert_string(source_frame);
    const auto t = convert_timepoint(time);
    auto res = self->lookupTransform(tgt_frame, src_frame, t);
    *result = convert_transform_stamped(&res);
  } catch (LookupException&) {
    return TF2C_ERROR_LOOKUP;
  } catch (ConnectivityException&) {
    return TF2C_ERROR_CONNECTIVITY;
  } catch (ExtrapolationException&) {
    return TF2C_ERROR_EXTRAPOLATION;
  } catch (InvalidArgumentException&) {
    return TF2C_ERROR_INVALID_ARGUMENT;
  }
  return TF2C_OK;
}

tf2c_bool_t tf2c_buffer_core_can_transform_1(tf2c_buffer_core_ptr_t buf,
                                             tf2c_string_t target_frame,
                                             tf2c_string_t source_frame,
                                             tf2c_timepoint_t time,
                                             tf2c_string_t* error_msg) {
  std::string error;
  const auto tgt_frame = convert_string(target_frame);
  const auto src_frame = convert_string(source_frame);
  const auto t = convert_timepoint(time);
  bool isOk = self->canTransform(tgt_frame, src_frame, t, &error);
  if (!isOk && error_msg != nullptr) {
    *error_msg = convert_string(error);
  }
  return isOk;
}

tf2c_bool_t tf2c_buffer_core_can_transform_2(tf2c_buffer_core_ptr_t buf,
                                             tf2c_string_t target_frame,
                                             tf2c_timepoint_t target_time,
                                             tf2c_string_t source_frame,
                                             tf2c_timepoint_t source_time,
                                             tf2c_string_t fixed_frame,
                                             tf2c_string_t* error_msg) {
  std::string error;
  const auto tgt_frame = convert_string(target_frame);
  const auto tgt_time = convert_timepoint(target_time);
  const auto src_frame = convert_string(source_frame);
  const auto src_time = convert_timepoint(source_time);
  const auto f_frame = convert_string(fixed_frame);
  bool isOk = self->canTransform(tgt_frame, tgt_time, src_frame, src_time, f_frame, &error);
  if (!isOk && error_msg != nullptr) {
    *error_msg = convert_string(error);
  }
  return isOk;
}


tf2c_string_array_t tf2c_buffer_core_get_all_frame_names(tf2c_buffer_core_ptr_t buf) {
  const auto names = self->getAllFrameNames();
  const auto conv = convert_string_array(names);
  return conv;
}

tf2c_string_t tf2c_buffer_core_all_frames_as_yaml_1(tf2c_buffer_core_ptr_t buf,
                                                    tf2c_timepoint_t current_time) {
  return convert_string(self->allFramesAsYAML(convert_timepoint(current_time)));
}

tf2c_string_t tf2c_buffer_core_all_frames_as_yaml_2(tf2c_buffer_core_ptr_t buf) {
  return convert_string(self->allFramesAsYAML());
}

tf2c_string_t tf2c_buffer_core_all_frames_as_string(tf2c_buffer_core_ptr_t buf) {
  return convert_string(self->allFramesAsString());
}

tf2c_transformable_request_handle_t tf2c_buffer_core_add_transformable_request(tf2c_buffer_core_ptr_t buf,
                                                                               tf2c_transformable_callback_t cb,
                                                                               tf2c_string_t target_frame,
                                                                               tf2c_string_t source_frame,
                                                                               tf2c_timepoint_t time) {
  BufferCore::TransformableCallback converted_cb = [cb](
      TransformableRequestHandle request_handle,
      const std::string& target_frame,
      const std::string& source_frame,
      TimePoint time,
      TransformableResult result) -> void {
    const auto tgt_frame = convert_string(target_frame);
    const auto src_frame = convert_string(source_frame);
    const auto t = convert_timepoint(time);
    const auto res = convert_transformable_result(result);
    cb.func(cb.userdata, request_handle, tgt_frame, src_frame, t, res);
  };
  const auto tgt_frame = convert_string(target_frame);
  const auto src_frame = convert_string(source_frame);
  const auto t = convert_timepoint(time);
  return self->addTransformableRequest(converted_cb, tgt_frame, src_frame, t);
}

void tf2c_cancel_transformable_request(tf2c_buffer_core_ptr_t buf,
                                       tf2c_transformable_request_handle_t handle) {
  self->cancelTransformableRequest(handle);
}

#undef self

}
