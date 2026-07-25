// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_scanner_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScanTarget {

@HiveField(0) String get path;@HiveField(1) int get addedAt;@HiveField(2) int? get lastScannedAt;@HiveField(3) ScanMode get scanMode;
/// Create a copy of ScanTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanTargetCopyWith<ScanTarget> get copyWith => _$ScanTargetCopyWithImpl<ScanTarget>(this as ScanTarget, _$identity);

  /// Serializes this ScanTarget to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanTarget&&(identical(other.path, path) || other.path == path)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.lastScannedAt, lastScannedAt) || other.lastScannedAt == lastScannedAt)&&(identical(other.scanMode, scanMode) || other.scanMode == scanMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,addedAt,lastScannedAt,scanMode);

@override
String toString() {
  return 'ScanTarget(path: $path, addedAt: $addedAt, lastScannedAt: $lastScannedAt, scanMode: $scanMode)';
}


}

/// @nodoc
abstract mixin class $ScanTargetCopyWith<$Res>  {
  factory $ScanTargetCopyWith(ScanTarget value, $Res Function(ScanTarget) _then) = _$ScanTargetCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String path,@HiveField(1) int addedAt,@HiveField(2) int? lastScannedAt,@HiveField(3) ScanMode scanMode
});




}
/// @nodoc
class _$ScanTargetCopyWithImpl<$Res>
    implements $ScanTargetCopyWith<$Res> {
  _$ScanTargetCopyWithImpl(this._self, this._then);

  final ScanTarget _self;
  final $Res Function(ScanTarget) _then;

/// Create a copy of ScanTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? addedAt = null,Object? lastScannedAt = freezed,Object? scanMode = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as int,lastScannedAt: freezed == lastScannedAt ? _self.lastScannedAt : lastScannedAt // ignore: cast_nullable_to_non_nullable
as int?,scanMode: null == scanMode ? _self.scanMode : scanMode // ignore: cast_nullable_to_non_nullable
as ScanMode,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanTarget].
extension ScanTargetPatterns on ScanTarget {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanTarget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanTarget() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanTarget value)  $default,){
final _that = this;
switch (_that) {
case _ScanTarget():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanTarget value)?  $default,){
final _that = this;
switch (_that) {
case _ScanTarget() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String path, @HiveField(1)  int addedAt, @HiveField(2)  int? lastScannedAt, @HiveField(3)  ScanMode scanMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanTarget() when $default != null:
return $default(_that.path,_that.addedAt,_that.lastScannedAt,_that.scanMode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String path, @HiveField(1)  int addedAt, @HiveField(2)  int? lastScannedAt, @HiveField(3)  ScanMode scanMode)  $default,) {final _that = this;
switch (_that) {
case _ScanTarget():
return $default(_that.path,_that.addedAt,_that.lastScannedAt,_that.scanMode);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String path, @HiveField(1)  int addedAt, @HiveField(2)  int? lastScannedAt, @HiveField(3)  ScanMode scanMode)?  $default,) {final _that = this;
switch (_that) {
case _ScanTarget() when $default != null:
return $default(_that.path,_that.addedAt,_that.lastScannedAt,_that.scanMode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScanTarget implements ScanTarget {
  const _ScanTarget({@HiveField(0) required this.path, @HiveField(1) required this.addedAt, @HiveField(2) this.lastScannedAt, @HiveField(3) required this.scanMode});
  factory _ScanTarget.fromJson(Map<String, dynamic> json) => _$ScanTargetFromJson(json);

@override@HiveField(0) final  String path;
@override@HiveField(1) final  int addedAt;
@override@HiveField(2) final  int? lastScannedAt;
@override@HiveField(3) final  ScanMode scanMode;

/// Create a copy of ScanTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanTargetCopyWith<_ScanTarget> get copyWith => __$ScanTargetCopyWithImpl<_ScanTarget>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScanTargetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanTarget&&(identical(other.path, path) || other.path == path)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.lastScannedAt, lastScannedAt) || other.lastScannedAt == lastScannedAt)&&(identical(other.scanMode, scanMode) || other.scanMode == scanMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,addedAt,lastScannedAt,scanMode);

@override
String toString() {
  return 'ScanTarget(path: $path, addedAt: $addedAt, lastScannedAt: $lastScannedAt, scanMode: $scanMode)';
}


}

/// @nodoc
abstract mixin class _$ScanTargetCopyWith<$Res> implements $ScanTargetCopyWith<$Res> {
  factory _$ScanTargetCopyWith(_ScanTarget value, $Res Function(_ScanTarget) _then) = __$ScanTargetCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String path,@HiveField(1) int addedAt,@HiveField(2) int? lastScannedAt,@HiveField(3) ScanMode scanMode
});




}
/// @nodoc
class __$ScanTargetCopyWithImpl<$Res>
    implements _$ScanTargetCopyWith<$Res> {
  __$ScanTargetCopyWithImpl(this._self, this._then);

  final _ScanTarget _self;
  final $Res Function(_ScanTarget) _then;

/// Create a copy of ScanTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? addedAt = null,Object? lastScannedAt = freezed,Object? scanMode = null,}) {
  return _then(_ScanTarget(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as int,lastScannedAt: freezed == lastScannedAt ? _self.lastScannedAt : lastScannedAt // ignore: cast_nullable_to_non_nullable
as int?,scanMode: null == scanMode ? _self.scanMode : scanMode // ignore: cast_nullable_to_non_nullable
as ScanMode,
  ));
}


}

/// @nodoc
mixin _$FileBrowserState {

/// 当前扫描目标的根路径
 String get rootPath; ScanMode get scanMode;/// 当前所处文件夹的路??
 String? get currentFolderPath;/// 当前目录下要渲染的子项列??
 List<FileNode> get children;/// 是否正在进行底层文件扫描
 bool get isScanning;/// 是否处于根目??
 bool get isHome;
/// Create a copy of FileBrowserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileBrowserStateCopyWith<FileBrowserState> get copyWith => _$FileBrowserStateCopyWithImpl<FileBrowserState>(this as FileBrowserState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileBrowserState&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.scanMode, scanMode) || other.scanMode == scanMode)&&(identical(other.currentFolderPath, currentFolderPath) || other.currentFolderPath == currentFolderPath)&&const DeepCollectionEquality().equals(other.children, children)&&(identical(other.isScanning, isScanning) || other.isScanning == isScanning)&&(identical(other.isHome, isHome) || other.isHome == isHome));
}


@override
int get hashCode => Object.hash(runtimeType,rootPath,scanMode,currentFolderPath,const DeepCollectionEquality().hash(children),isScanning,isHome);

@override
String toString() {
  return 'FileBrowserState(rootPath: $rootPath, scanMode: $scanMode, currentFolderPath: $currentFolderPath, children: $children, isScanning: $isScanning, isHome: $isHome)';
}


}

/// @nodoc
abstract mixin class $FileBrowserStateCopyWith<$Res>  {
  factory $FileBrowserStateCopyWith(FileBrowserState value, $Res Function(FileBrowserState) _then) = _$FileBrowserStateCopyWithImpl;
@useResult
$Res call({
 String rootPath, ScanMode scanMode, String? currentFolderPath, List<FileNode> children, bool isScanning, bool isHome
});




}
/// @nodoc
class _$FileBrowserStateCopyWithImpl<$Res>
    implements $FileBrowserStateCopyWith<$Res> {
  _$FileBrowserStateCopyWithImpl(this._self, this._then);

  final FileBrowserState _self;
  final $Res Function(FileBrowserState) _then;

/// Create a copy of FileBrowserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rootPath = null,Object? scanMode = null,Object? currentFolderPath = freezed,Object? children = null,Object? isScanning = null,Object? isHome = null,}) {
  return _then(_self.copyWith(
rootPath: null == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String,scanMode: null == scanMode ? _self.scanMode : scanMode // ignore: cast_nullable_to_non_nullable
as ScanMode,currentFolderPath: freezed == currentFolderPath ? _self.currentFolderPath : currentFolderPath // ignore: cast_nullable_to_non_nullable
as String?,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as List<FileNode>,isScanning: null == isScanning ? _self.isScanning : isScanning // ignore: cast_nullable_to_non_nullable
as bool,isHome: null == isHome ? _self.isHome : isHome // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FileBrowserState].
extension FileBrowserStatePatterns on FileBrowserState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileBrowserState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileBrowserState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileBrowserState value)  $default,){
final _that = this;
switch (_that) {
case _FileBrowserState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileBrowserState value)?  $default,){
final _that = this;
switch (_that) {
case _FileBrowserState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String rootPath,  ScanMode scanMode,  String? currentFolderPath,  List<FileNode> children,  bool isScanning,  bool isHome)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileBrowserState() when $default != null:
return $default(_that.rootPath,_that.scanMode,_that.currentFolderPath,_that.children,_that.isScanning,_that.isHome);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String rootPath,  ScanMode scanMode,  String? currentFolderPath,  List<FileNode> children,  bool isScanning,  bool isHome)  $default,) {final _that = this;
switch (_that) {
case _FileBrowserState():
return $default(_that.rootPath,_that.scanMode,_that.currentFolderPath,_that.children,_that.isScanning,_that.isHome);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String rootPath,  ScanMode scanMode,  String? currentFolderPath,  List<FileNode> children,  bool isScanning,  bool isHome)?  $default,) {final _that = this;
switch (_that) {
case _FileBrowserState() when $default != null:
return $default(_that.rootPath,_that.scanMode,_that.currentFolderPath,_that.children,_that.isScanning,_that.isHome);case _:
  return null;

}
}

}

/// @nodoc


class _FileBrowserState extends FileBrowserState {
  const _FileBrowserState({required this.rootPath, this.scanMode = ScanMode.audio, this.currentFolderPath, final  List<FileNode> children = const [], this.isScanning = false, this.isHome = true}): _children = children,super._();
  

/// 当前扫描目标的根路径
@override final  String rootPath;
@override@JsonKey() final  ScanMode scanMode;
/// 当前所处文件夹的路??
@override final  String? currentFolderPath;
/// 当前目录下要渲染的子项列??
 final  List<FileNode> _children;
/// 当前目录下要渲染的子项列??
@override@JsonKey() List<FileNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}

/// 是否正在进行底层文件扫描
@override@JsonKey() final  bool isScanning;
/// 是否处于根目??
@override@JsonKey() final  bool isHome;

/// Create a copy of FileBrowserState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileBrowserStateCopyWith<_FileBrowserState> get copyWith => __$FileBrowserStateCopyWithImpl<_FileBrowserState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileBrowserState&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.scanMode, scanMode) || other.scanMode == scanMode)&&(identical(other.currentFolderPath, currentFolderPath) || other.currentFolderPath == currentFolderPath)&&const DeepCollectionEquality().equals(other._children, _children)&&(identical(other.isScanning, isScanning) || other.isScanning == isScanning)&&(identical(other.isHome, isHome) || other.isHome == isHome));
}


@override
int get hashCode => Object.hash(runtimeType,rootPath,scanMode,currentFolderPath,const DeepCollectionEquality().hash(_children),isScanning,isHome);

@override
String toString() {
  return 'FileBrowserState(rootPath: $rootPath, scanMode: $scanMode, currentFolderPath: $currentFolderPath, children: $children, isScanning: $isScanning, isHome: $isHome)';
}


}

/// @nodoc
abstract mixin class _$FileBrowserStateCopyWith<$Res> implements $FileBrowserStateCopyWith<$Res> {
  factory _$FileBrowserStateCopyWith(_FileBrowserState value, $Res Function(_FileBrowserState) _then) = __$FileBrowserStateCopyWithImpl;
@override @useResult
$Res call({
 String rootPath, ScanMode scanMode, String? currentFolderPath, List<FileNode> children, bool isScanning, bool isHome
});




}
/// @nodoc
class __$FileBrowserStateCopyWithImpl<$Res>
    implements _$FileBrowserStateCopyWith<$Res> {
  __$FileBrowserStateCopyWithImpl(this._self, this._then);

  final _FileBrowserState _self;
  final $Res Function(_FileBrowserState) _then;

/// Create a copy of FileBrowserState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rootPath = null,Object? scanMode = null,Object? currentFolderPath = freezed,Object? children = null,Object? isScanning = null,Object? isHome = null,}) {
  return _then(_FileBrowserState(
rootPath: null == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String,scanMode: null == scanMode ? _self.scanMode : scanMode // ignore: cast_nullable_to_non_nullable
as ScanMode,currentFolderPath: freezed == currentFolderPath ? _self.currentFolderPath : currentFolderPath // ignore: cast_nullable_to_non_nullable
as String?,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<FileNode>,isScanning: null == isScanning ? _self.isScanning : isScanning // ignore: cast_nullable_to_non_nullable
as bool,isHome: null == isHome ? _self.isHome : isHome // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
