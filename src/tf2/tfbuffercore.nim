import ./private/tf2_abi
import ./common
import concurrent/smartptrs
import results
import std/[times, hashes]
import rclnim/rosinterfaceimporters

importInterface std_msgs/msg/header
importInterface geometry_msgs/msg/[transform_stamped, transform, vector3, quaternion]

type
  TfBufferCoreObj = object
    impl: tf2c_buffer_core_ptr_t

  TfBufferCore* = SharedPtr[TfBufferCoreObj]

  TransformableRequestHandle* = distinct tf2c_transformable_request_handle_t

  TransformableRequestResult* = enum
    TransformAvailable, TransformFailure
  
  TransformableCallback* = proc(requestHandle: TransformableRequestHandle, targetFrame, sourceFrame: FrameId, time: Time, transformableResult: TransformableRequestResult, userdata: pointer) {.nimcall.}

proc `==`*(a, b: TransformableRequestHandle): bool {.borrow.}
proc hash*(a: TransformableRequestHandle): Hash {.borrow.}
proc `$`*(a: TransformableRequestHandle): string {.borrow.}

proc `=destroy`(self: TfBufferCoreObj) =
  if self.impl != nil:
    tf2c_buffer_core_fini(self.impl)

converter toTf2c(dur: Duration): tf2c_duration_t =
  tf2c_duration_t(dur.inNanoseconds)

converter toTf2c(tim: Time): tf2c_timepoint_t =
  tf2c_timepoint_t(tim.toUnix() * 1_000_000_000 + tim.nanosecond)

converter toTf2c(s: string): tf2c_string_t =
  tf2c_string_init(s.cstring, s.len.csize_t)

converter toTf2c(s: FrameId): tf2c_string_t =
  tf2c_string_init(s.string.cstring, s.string.len.csize_t)

converter toTf2c(tr: TransformStamped): tf2c_transform_stamped_t =
  result.header.frame_id = tr.header.frameId
  result.header.stamp.sec = tr.header.stamp.sec
  result.header.stamp.nanosec = tr.header.stamp.nanosec
  result.child_frame_id = tr.childFrameId
  result.transform.rotation.x = tr.transform.rotation.x
  result.transform.rotation.y = tr.transform.rotation.y
  result.transform.rotation.z = tr.transform.rotation.z
  result.transform.rotation.w = tr.transform.rotation.w
  result.transform.translation.x = tr.transform.translation.x
  result.transform.translation.y = tr.transform.translation.y
  result.transform.translation.z = tr.transform.translation.z

converter fromTf2c(s: tf2c_string_t): string =
  if s.len == 0: return
  result = newString(s.len)
  copyMem(addr result[0], s.data, s.len)

converter fromTf2c(s: tf2c_string_array_t): seq[string] =
  if s.len == 0: return
  result = newSeq[string](s.len)
  for i in 0..<s.len:
    result[i] = cast[ptr UncheckedArray[tf2c_string_t]](s.data)[i]

converter fromTf2c(s: tf2c_timepoint_t): Time =
  initTime(s.int64 div 1_000_000_000, s.int64 mod 1_000_000_000)

converter fromTf2c(tr: tf2c_transform_stamped_t): TransformStamped =
  result.header.frame_id = tr.header.frameId
  result.header.stamp.sec = tr.header.stamp.sec
  result.header.stamp.nanosec = tr.header.stamp.nanosec
  result.child_frame_id = tr.childFrameId
  result.transform.rotation.x = tr.transform.rotation.x
  result.transform.rotation.y = tr.transform.rotation.y
  result.transform.rotation.z = tr.transform.rotation.z
  result.transform.rotation.w = tr.transform.rotation.w
  result.transform.translation.x = tr.transform.translation.x
  result.transform.translation.y = tr.transform.translation.y
  result.transform.translation.z = tr.transform.translation.z

proc newTfBufferCore*(cacheDuration = initDuration(seconds=10)): TfBufferCore =
  result = newSharedPtr(TfBufferCoreObj)
  result.impl = tf2c_buffer_core_init(cacheDuration)

proc new*(_: typedesc[TfBufferCore], cacheDuration = initDuration(seconds=10)): TfBufferCore =
  newTfBufferCore(cacheDuration)

using self: TfBufferCore

proc clear*(self) =
  tf2c_buffer_core_clear(self.impl)

proc setTransform*(self; transform: TransformStamped, authority: string, isStatic = false): bool =
  let tr = transform.toTf2c()
  result = tf2c_buffer_core_set_transform(self.impl, addr tr, authority, isStatic)

proc lookupTransform*(self; 
    targetFrame: FrameId, targetTime: Time,
    sourceFrame: FrameId, sourceTime: Time, fixedFrame: FrameId): TransformResult =
  var res: tf2c_transform_stamped_t
  let err = tf2c_buffer_core_lookup_transform_1(
    self.impl,
    targetFrame, targetTime,
    sourceFrame, sourceTime,
    fixedFrame, addr res)
  if err == TF2C_OK:
    result.ok(res)
  else:
    result.err(err.int.TransformError)

proc lookupTransform*(self;
    targetFrame, sourceFrame: FrameId, time: Time): TransformResult =
  var res: tf2c_transform_stamped_t
  let err = tf2c_buffer_core_lookup_transform_2(
    self.impl, targetFrame, sourceFrame, time, addr res)
  if err == TF2C_OK:
    result.ok(res)
  else:
    result.err(err.int.TransformError)

proc canTransform*(self;
    targetFrame, sourceFrame: FrameId, time: Time): bool =
  tf2c_buffer_core_can_transform_1(
    self.impl, targetFrame, sourceFrame, time, nil)

proc canTransform*(self;
    targetFrame: FrameId, targetTime: Time,
    sourceFrame: FrameId, sourceTime: Time, fixedFrame: FrameId): bool =
  tf2c_buffer_core_can_transform_2(
    self.impl, targetFrame, targetTime, sourceFrame, sourceTime, fixedFrame, nil)

proc getAllFrameNames*(self): seq[string] =
  tf2c_buffer_core_get_all_frame_names(self.impl)

proc allFramesAsYaml*(self; currentTime: Time): string =
  tf2c_buffer_core_all_frames_as_yaml_1(self.impl, currentTime)

proc allFramesAsYaml*(self): string =
  tf2c_buffer_core_all_frames_as_yaml_2(self.impl)

proc allFramesAsString*(self): string =
  tf2c_buffer_core_all_frames_as_string(self.impl)

proc addTransformableRequest*(
    self; callback: TransformableCallback, targetFrame: FrameId, sourceFrame: FrameId, time: Time, userdata: pointer): TransformableRequestHandle =
  type Payload = object
    userdata: pointer
    callback: TransformableCallback
  let payload = createShared(Payload)
  payload.userdata = userdata
  payload.callback = callback
  let cb =
    proc (userdata: pointer;
        request_handle: tf2c_transformable_request_handle_t;
        target_frame: tf2c_string_t; source_frame: tf2c_string_t;
        time: tf2c_timepoint_t; res: tf2c_transformable_result_t) {.cdecl.} =
      let payload = cast[ptr Payload](userdata)
      payload.callback(request_handle.TransformableRequestHandle,
        target_frame.string.FrameId,
        source_frame.string.FrameId,
        time.Time,
        res.int.TransformableRequestResult,
        payload.userdata)
      deallocShared(userdata)
  
  tf2c_buffer_core_add_transformable_request(
    self.impl, tf2c_transformable_callback_t(userdata: payload, `func`: cb),
    targetFrame, sourceFrame, time).TransformableRequestHandle

proc cancelTransformableRequest*(
    self; handle: TransformableRequestHandle) =
  tf2c_cancel_transformable_request(self.impl, handle.tf2c_transformable_request_handle_t)

export common

when isMainModule:
  let buf = newTfBufferCore()
  proc cb(requestHandle: TransformableRequestHandle, targetFrame, sourceFrame: FrameId, time: Time, transformableResult: TransformableRequestResult, userdata: pointer) =
    echo sourceFrame, " ", targetFrame
  let handle = buf.addTransformableRequest(cb, FrameId"to", FrameId"from", TimePointZero, nil)
  echo handle
  # buf.cancelTransformableRequest(handle)
  echo buf.setTransform(TransformStamped(header: Header(frameId: "to"), childFrameId: "from"), "")
  echo buf.allFramesAsYaml()
  echo buf.allFramesAsString()


