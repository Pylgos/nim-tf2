import ./[tfbuffercore, common]
import std/times except milliseconds, seconds
import rclnim/[rosinterfaceimporters, nodes, subscriptions, qosprofiles, chronossupport, init]
import chronos
import results

importInterface geometry_msgs/msg/[transform_stamped, transform, vector3, quaternion]
importInterface tf2_msgs/msg/tf_message

type
  TfBuffer* = ref TfBufferObj
    
  TfBufferObj* = object of RootObj
    sub, staticSub: Subscription[TFMessage]
    staticCallbackFuture, callbackFuture: Future[void]
    node: Node
    buf: TfBufferCore

proc `=destroy`(self: var TfBufferObj) =
  self.staticCallbackFuture.cancel()
  self.callbackFuture.cancel()
  `=destroy`(self.sub)
  `=destroy`(self.staticSub)
  `=destroy`(self.staticCallbackFuture)
  `=destroy`(self.callbackFuture)
  `=destroy`(self.node)
  `=destroy`(self.buf)

const
  DynamicListenerQoS* = SystemDefaultQoS.withPolicies(depth = 100)
  StaticListenerQoS* = SystemDefaultQoS.withPolicies(depth = 100, durability = TransientLocal, reliability = Reliable)

proc newTfBuffer*(
      node: Node,
      cacheDuration = initDuration(seconds=10),
      qos = DynamicListenerQoS,
      staticQoS = StaticListenerQoS): TfBuffer =
  new result
  result.buf = newTfBufferCore(cacheDuration)
  result.node = node
  result.sub = node.createSubscription(TFMessage, "/tf", qos)
  result.staticSub = node.createSubscription(TFMessage, "/tf_static", staticQoS)

  proc loop(buf: TfBufferCore, sub: Subscription[TFMessage], isStatic: bool) {.async.} =
    while true:
      let msg = await sub.recv()
      let authority = "Authority undetectable"
      for t in msg.transforms:
        discard buf.setTransform(t, authority, isStatic)
  
  result.callbackFuture = loop(result.buf, result.sub, false)
  result.staticCallbackFuture = loop(result.buf, result.staticSub, true)

proc new*(_: typedesc[TfBuffer], node: Node,
      cacheDuration = initDuration(seconds=10),
      qos = DynamicListenerQoS,
      staticQoS = StaticListenerQoS): TfBuffer =
  newTfBuffer(node, cacheDuration, qos, staticQoS)

using self: TfBuffer

proc buffer*(self): TfBufferCore =
  self.buf

proc lookupTransform*(self;
    targetFrame: FrameId, targetTime: Time,
    sourceFrame: FrameId, sourceTime: Time, fixedFrame: FrameId): TransformResult =
  self.buf.lookupTransform(targetFrame, targetTime, sourceFrame, sourceTime, fixedFrame)

proc lookupTransform*(self;
    targetFrame, sourceFrame: FrameId, time: Time): TransformResult =
  self.buf.lookupTransform(targetFrame, sourceFrame, time)

proc canTransform*(self;
    targetFrame, sourceFrame: FrameId, time: Time): bool =
  self.buf.canTransform(targetFrame, sourceFrame, time)

proc canTransform*(self;
    targetFrame: FrameId, targetTime: Time,
    sourceFrame: FrameId, sourceTime: Time, fixedFrame: FrameId): bool =
  self.buf.canTransform(targetFrame, targetTime, sourceFrame, sourceTime, fixedFrame)

proc waitForTransform*(self; targetFrame, sourceFrame: FrameId, time: Time): Future[TransformResult] =
  type Payload = object
    buf: TfBufferCore
    fut: Future[TransformResult]

  proc callback(
      requestHandle: TransformableRequestHandle,
      targetFrame, sourceFrame: FrameId, time: Time,
      transformableResult: TransformableRequestResult, userdata: pointer) {.nimcall.} =
    let payload = cast[ptr Payload](userdata)
    case transformableResult
    of TransformAvailable:
      let res = payload.buf.lookupTransform(targetFrame, sourceFrame, time)
      payload.fut.complete(res)
    of TransformFailure:
      payload.fut.complete(TransformResult.err(TransformError.LookupError))
    `=destroy`(payload[])
    deallocShared(payload)

  let payload = createShared(Payload)
  let retFut = newFuture[TransformResult]("tfbuffers.waitForTransform")
  payload.fut = retFut
  payload.buf = self.buf
  let handle = self.buf.addTransformableRequest(callback, targetFrame, sourceFrame, time, payload)
  if handle.uint64 == 0:
    # immediately transformable
    retFut.complete(self.buf.lookupTransform(targetFrame, sourceFrame, time))
    {.cast(gcsafe), cast(raises: []).}: `=destroy`(payload[])
    deallocShared(payload)
  elif handle.uint64 == uint64.high:
    # never transformable
    retFut.complete(TransformResult.err(TransformError.LookupError))
    {.cast(gcsafe), cast(raises: []).}: `=destroy`(payload[])
    deallocShared(payload)
  else:
    proc cancellation(udata: pointer) {.gcsafe, raises: [].} =
      payload.buf.cancelTransformableRequest(handle)
      {.cast(gcsafe), cast(raises: []).}: `=destroy`(payload[])
      deallocShared(payload)
    retFut.cancelCallback = cancellation
  retFut

export common

when isMainModule:
  init()
  
  proc main {.async.} =
    let node = Node.new("test_node")
    let buf = TfBuffer.new(node)
  
    await sleepAsync 1.seconds

    let fut = buf.waitForTransform(FrameId"base_link", FrameId"odom", TimePointZero)
    if await withTimeout(fut, 5.seconds):
      echo fut.read()
    else:
      echo "timeout"
      fut.cancel()

  waitFor main()
