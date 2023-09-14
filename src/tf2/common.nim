import std/[hashes, times]
import results
import rclnim/rosinterfaceimporters
importInterface geometry_msgs/msg/[transform_stamped]

type
  TransformError* {.pure.} = enum
    LookupError = 1, ConnectivityError = 2,
    ExtrapolationError = 3, InvalidArgumentError = 4

  TransformResult* = Result[TransformStamped, TransformError]

  FrameId* = distinct string

proc `==`*(a, b: FrameId): bool {.borrow.}
proc hash*(a: FrameId): Hash {.borrow.}
proc `$`*(a: FrameId): string {.borrow.}

const TimePointZero* = Time.low
