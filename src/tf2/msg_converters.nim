import geonimetry
import toconv
import rclnim/rosinterfaceimporters
importInterface geometry_msgs/msg/[point, point32, vector3, quaternion, pose, transform], transform.Transform as TransformMsg

{.push inline.}

proc to*[T](value: Vector3, _: typedesc[Vector[3, T]]): Vector[3, T] =
  initVector([value.x.to(T), value.y.to(T), value.z.to(T)])

proc to*[T](value: Point, _: typedesc[Vector[3, T]]): Vector[3, T] =
  initVector([value.x.to(T), value.y.to(T), value.z.to(T)])

proc to*[T](value: Point32, _: typedesc[Vector[3, T]]): Vector[3, T] =
  initVector([value.x.to(T), value.y.to(T), value.z.to(T)])

proc to*[T](value: Quaternion, _: typedesc[Quat[T]]): Quat[T] =
  quat(value.x.to(T), value.y.to(T), value.z.to(T), value.w.to(T))

proc to*[T](value: TransformMsg, _: typedesc[Transform[3, T]]): Transform[3, T] =
  transform3(value.translation.to(Vector[3, T]), value.rotation.to(Quat[T]))

proc to*[T](value: Pose, _: typedesc[Transform[3, T]]): Transform[3, T] =
  transform3(value.position.to(Vector[3, T]), value.orientation.to(Quat[T]))


proc to*[T](value: Vector[3, T], _: typedesc[Vector3]): Vector3 =
  Vector3(x: value.x.to(float64), y: value.y.to(float64), z: value.z.to(float64))

proc to*[T](value: Vector[3, T], _: typedesc[Point]): Point =
  Point(x: value.x.to(float64), y: value.y.to(float64), z: value.z.to(float64))

proc to*[T](value: Vector[3, T], _: typedesc[Point32]): Point32 =
  Point32(x: value.x.to(float32), y: value.y.to(float32), z: value.z.to(float32))

proc to*[T](value: Quat[T], _: typedesc[Quaternion]): Quaternion =
  Quaternion(x: value.x.to(float64), y: value.y.to(float64), z: value.z.to(float64), w: value.w.to(float64))

proc to*[T](value: Transform[3, T], _: typedesc[TransformMsg]): TransformMsg =
  TransformMsg(translation: value.origin.to(Vector3), rotation: value.rotation.to(Quaternion))

proc to*[T](value: Transform[3, T], _: typedesc[Pose]): Pose =
  Pose(position: value.origin.to(Vector3), orientation: value.rotation.to(Quaternion))

{.pop.}
