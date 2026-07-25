// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FileNode {

@HiveField(0) NodeType get type;@HiveField(1) String get title; List<FileNode>? get children;@HiveField(2) String? get hash;@HiveField(3) String? get mediaStreamUrl;@HiveField(4) String? get mediaDownloadUrl;@HiveField(5) double? get duration;@HiveField(6) int? get size;@HiveField(7) String? get workTitle;@HiveField(8) String? get artist;@HiveField(9) int get lastModified;@HiveField(10) NodeStatus get nodeStatus;@HiveField(11) int? get workId;@HiveField(12) NodeSource get source;// Media-library index fields.
@HiveField(13) String? get path;@HiveField(14) String? get folderPath;@HiveField(15) String? get rootPath;@HiveField(16) String? get parentPath;@HiveField(17) int get depth; int get subItemsCount;
/// Create a copy of FileNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileNodeCopyWith<FileNode> get copyWith => _$FileNodeCopyWithImpl<FileNode>(this as FileNode, _$identity);

  /// Serializes this FileNode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileNode&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.children, children)&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.mediaStreamUrl, mediaStreamUrl) || other.mediaStreamUrl == mediaStreamUrl)&&(identical(other.mediaDownloadUrl, mediaDownloadUrl) || other.mediaDownloadUrl == mediaDownloadUrl)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.size, size) || other.size == size)&&(identical(other.workTitle, workTitle) || other.workTitle == workTitle)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.lastModified, lastModified) || other.lastModified == lastModified)&&(identical(other.nodeStatus, nodeStatus) || other.nodeStatus == nodeStatus)&&(identical(other.workId, workId) || other.workId == workId)&&(identical(other.source, source) || other.source == source)&&(identical(other.path, path) || other.path == path)&&(identical(other.folderPath, folderPath) || other.folderPath == folderPath)&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.parentPath, parentPath) || other.parentPath == parentPath)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.subItemsCount, subItemsCount) || other.subItemsCount == subItemsCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,type,title,const DeepCollectionEquality().hash(children),hash,mediaStreamUrl,mediaDownloadUrl,duration,size,workTitle,artist,lastModified,nodeStatus,workId,source,path,folderPath,rootPath,parentPath,depth,subItemsCount]);

@override
String toString() {
  return 'FileNode(type: $type, title: $title, children: $children, hash: $hash, mediaStreamUrl: $mediaStreamUrl, mediaDownloadUrl: $mediaDownloadUrl, duration: $duration, size: $size, workTitle: $workTitle, artist: $artist, lastModified: $lastModified, nodeStatus: $nodeStatus, workId: $workId, source: $source, path: $path, folderPath: $folderPath, rootPath: $rootPath, parentPath: $parentPath, depth: $depth, subItemsCount: $subItemsCount)';
}


}

/// @nodoc
abstract mixin class $FileNodeCopyWith<$Res>  {
  factory $FileNodeCopyWith(FileNode value, $Res Function(FileNode) _then) = _$FileNodeCopyWithImpl;
@useResult
$Res call({
@HiveField(0) NodeType type,@HiveField(1) String title, List<FileNode>? children,@HiveField(2) String? hash,@HiveField(3) String? mediaStreamUrl,@HiveField(4) String? mediaDownloadUrl,@HiveField(5) double? duration,@HiveField(6) int? size,@HiveField(7) String? workTitle,@HiveField(8) String? artist,@HiveField(9) int lastModified,@HiveField(10) NodeStatus nodeStatus,@HiveField(11) int? workId,@HiveField(12) NodeSource source,@HiveField(13) String? path,@HiveField(14) String? folderPath,@HiveField(15) String? rootPath,@HiveField(16) String? parentPath,@HiveField(17) int depth, int subItemsCount
});




}
/// @nodoc
class _$FileNodeCopyWithImpl<$Res>
    implements $FileNodeCopyWith<$Res> {
  _$FileNodeCopyWithImpl(this._self, this._then);

  final FileNode _self;
  final $Res Function(FileNode) _then;

/// Create a copy of FileNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? title = null,Object? children = freezed,Object? hash = freezed,Object? mediaStreamUrl = freezed,Object? mediaDownloadUrl = freezed,Object? duration = freezed,Object? size = freezed,Object? workTitle = freezed,Object? artist = freezed,Object? lastModified = null,Object? nodeStatus = null,Object? workId = freezed,Object? source = null,Object? path = freezed,Object? folderPath = freezed,Object? rootPath = freezed,Object? parentPath = freezed,Object? depth = null,Object? subItemsCount = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NodeType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,children: freezed == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as List<FileNode>?,hash: freezed == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String?,mediaStreamUrl: freezed == mediaStreamUrl ? _self.mediaStreamUrl : mediaStreamUrl // ignore: cast_nullable_to_non_nullable
as String?,mediaDownloadUrl: freezed == mediaDownloadUrl ? _self.mediaDownloadUrl : mediaDownloadUrl // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,workTitle: freezed == workTitle ? _self.workTitle : workTitle // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,lastModified: null == lastModified ? _self.lastModified : lastModified // ignore: cast_nullable_to_non_nullable
as int,nodeStatus: null == nodeStatus ? _self.nodeStatus : nodeStatus // ignore: cast_nullable_to_non_nullable
as NodeStatus,workId: freezed == workId ? _self.workId : workId // ignore: cast_nullable_to_non_nullable
as int?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as NodeSource,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,folderPath: freezed == folderPath ? _self.folderPath : folderPath // ignore: cast_nullable_to_non_nullable
as String?,rootPath: freezed == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String?,parentPath: freezed == parentPath ? _self.parentPath : parentPath // ignore: cast_nullable_to_non_nullable
as String?,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as int,subItemsCount: null == subItemsCount ? _self.subItemsCount : subItemsCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FileNode].
extension FileNodePatterns on FileNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileNode value)  $default,){
final _that = this;
switch (_that) {
case _FileNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileNode value)?  $default,){
final _that = this;
switch (_that) {
case _FileNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  NodeType type, @HiveField(1)  String title,  List<FileNode>? children, @HiveField(2)  String? hash, @HiveField(3)  String? mediaStreamUrl, @HiveField(4)  String? mediaDownloadUrl, @HiveField(5)  double? duration, @HiveField(6)  int? size, @HiveField(7)  String? workTitle, @HiveField(8)  String? artist, @HiveField(9)  int lastModified, @HiveField(10)  NodeStatus nodeStatus, @HiveField(11)  int? workId, @HiveField(12)  NodeSource source, @HiveField(13)  String? path, @HiveField(14)  String? folderPath, @HiveField(15)  String? rootPath, @HiveField(16)  String? parentPath, @HiveField(17)  int depth,  int subItemsCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileNode() when $default != null:
return $default(_that.type,_that.title,_that.children,_that.hash,_that.mediaStreamUrl,_that.mediaDownloadUrl,_that.duration,_that.size,_that.workTitle,_that.artist,_that.lastModified,_that.nodeStatus,_that.workId,_that.source,_that.path,_that.folderPath,_that.rootPath,_that.parentPath,_that.depth,_that.subItemsCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  NodeType type, @HiveField(1)  String title,  List<FileNode>? children, @HiveField(2)  String? hash, @HiveField(3)  String? mediaStreamUrl, @HiveField(4)  String? mediaDownloadUrl, @HiveField(5)  double? duration, @HiveField(6)  int? size, @HiveField(7)  String? workTitle, @HiveField(8)  String? artist, @HiveField(9)  int lastModified, @HiveField(10)  NodeStatus nodeStatus, @HiveField(11)  int? workId, @HiveField(12)  NodeSource source, @HiveField(13)  String? path, @HiveField(14)  String? folderPath, @HiveField(15)  String? rootPath, @HiveField(16)  String? parentPath, @HiveField(17)  int depth,  int subItemsCount)  $default,) {final _that = this;
switch (_that) {
case _FileNode():
return $default(_that.type,_that.title,_that.children,_that.hash,_that.mediaStreamUrl,_that.mediaDownloadUrl,_that.duration,_that.size,_that.workTitle,_that.artist,_that.lastModified,_that.nodeStatus,_that.workId,_that.source,_that.path,_that.folderPath,_that.rootPath,_that.parentPath,_that.depth,_that.subItemsCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  NodeType type, @HiveField(1)  String title,  List<FileNode>? children, @HiveField(2)  String? hash, @HiveField(3)  String? mediaStreamUrl, @HiveField(4)  String? mediaDownloadUrl, @HiveField(5)  double? duration, @HiveField(6)  int? size, @HiveField(7)  String? workTitle, @HiveField(8)  String? artist, @HiveField(9)  int lastModified, @HiveField(10)  NodeStatus nodeStatus, @HiveField(11)  int? workId, @HiveField(12)  NodeSource source, @HiveField(13)  String? path, @HiveField(14)  String? folderPath, @HiveField(15)  String? rootPath, @HiveField(16)  String? parentPath, @HiveField(17)  int depth,  int subItemsCount)?  $default,) {final _that = this;
switch (_that) {
case _FileNode() when $default != null:
return $default(_that.type,_that.title,_that.children,_that.hash,_that.mediaStreamUrl,_that.mediaDownloadUrl,_that.duration,_that.size,_that.workTitle,_that.artist,_that.lastModified,_that.nodeStatus,_that.workId,_that.source,_that.path,_that.folderPath,_that.rootPath,_that.parentPath,_that.depth,_that.subItemsCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FileNode extends FileNode {
   _FileNode({@HiveField(0) required this.type, @HiveField(1) required this.title, final  List<FileNode>? children, @HiveField(2) this.hash, @HiveField(3) this.mediaStreamUrl, @HiveField(4) this.mediaDownloadUrl, @HiveField(5) this.duration, @HiveField(6) this.size, @HiveField(7) this.workTitle, @HiveField(8) this.artist, @HiveField(9) this.lastModified = 0, @HiveField(10) this.nodeStatus = NodeStatus.normal, @HiveField(11) this.workId, @HiveField(12) this.source = NodeSource.asmrServer, @HiveField(13) this.path, @HiveField(14) this.folderPath, @HiveField(15) this.rootPath, @HiveField(16) this.parentPath, @HiveField(17) this.depth = 0, this.subItemsCount = 0}): _children = children,super._();
  factory _FileNode.fromJson(Map<String, dynamic> json) => _$FileNodeFromJson(json);

@override@HiveField(0) final  NodeType type;
@override@HiveField(1) final  String title;
 final  List<FileNode>? _children;
@override List<FileNode>? get children {
  final value = _children;
  if (value == null) return null;
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@HiveField(2) final  String? hash;
@override@HiveField(3) final  String? mediaStreamUrl;
@override@HiveField(4) final  String? mediaDownloadUrl;
@override@HiveField(5) final  double? duration;
@override@HiveField(6) final  int? size;
@override@HiveField(7) final  String? workTitle;
@override@HiveField(8) final  String? artist;
@override@JsonKey()@HiveField(9) final  int lastModified;
@override@JsonKey()@HiveField(10) final  NodeStatus nodeStatus;
@override@HiveField(11) final  int? workId;
@override@JsonKey()@HiveField(12) final  NodeSource source;
// Media-library index fields.
@override@HiveField(13) final  String? path;
@override@HiveField(14) final  String? folderPath;
@override@HiveField(15) final  String? rootPath;
@override@HiveField(16) final  String? parentPath;
@override@JsonKey()@HiveField(17) final  int depth;
@override@JsonKey() final  int subItemsCount;

/// Create a copy of FileNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileNodeCopyWith<_FileNode> get copyWith => __$FileNodeCopyWithImpl<_FileNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileNodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileNode&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._children, _children)&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.mediaStreamUrl, mediaStreamUrl) || other.mediaStreamUrl == mediaStreamUrl)&&(identical(other.mediaDownloadUrl, mediaDownloadUrl) || other.mediaDownloadUrl == mediaDownloadUrl)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.size, size) || other.size == size)&&(identical(other.workTitle, workTitle) || other.workTitle == workTitle)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.lastModified, lastModified) || other.lastModified == lastModified)&&(identical(other.nodeStatus, nodeStatus) || other.nodeStatus == nodeStatus)&&(identical(other.workId, workId) || other.workId == workId)&&(identical(other.source, source) || other.source == source)&&(identical(other.path, path) || other.path == path)&&(identical(other.folderPath, folderPath) || other.folderPath == folderPath)&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.parentPath, parentPath) || other.parentPath == parentPath)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.subItemsCount, subItemsCount) || other.subItemsCount == subItemsCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,type,title,const DeepCollectionEquality().hash(_children),hash,mediaStreamUrl,mediaDownloadUrl,duration,size,workTitle,artist,lastModified,nodeStatus,workId,source,path,folderPath,rootPath,parentPath,depth,subItemsCount]);

@override
String toString() {
  return 'FileNode(type: $type, title: $title, children: $children, hash: $hash, mediaStreamUrl: $mediaStreamUrl, mediaDownloadUrl: $mediaDownloadUrl, duration: $duration, size: $size, workTitle: $workTitle, artist: $artist, lastModified: $lastModified, nodeStatus: $nodeStatus, workId: $workId, source: $source, path: $path, folderPath: $folderPath, rootPath: $rootPath, parentPath: $parentPath, depth: $depth, subItemsCount: $subItemsCount)';
}


}

/// @nodoc
abstract mixin class _$FileNodeCopyWith<$Res> implements $FileNodeCopyWith<$Res> {
  factory _$FileNodeCopyWith(_FileNode value, $Res Function(_FileNode) _then) = __$FileNodeCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) NodeType type,@HiveField(1) String title, List<FileNode>? children,@HiveField(2) String? hash,@HiveField(3) String? mediaStreamUrl,@HiveField(4) String? mediaDownloadUrl,@HiveField(5) double? duration,@HiveField(6) int? size,@HiveField(7) String? workTitle,@HiveField(8) String? artist,@HiveField(9) int lastModified,@HiveField(10) NodeStatus nodeStatus,@HiveField(11) int? workId,@HiveField(12) NodeSource source,@HiveField(13) String? path,@HiveField(14) String? folderPath,@HiveField(15) String? rootPath,@HiveField(16) String? parentPath,@HiveField(17) int depth, int subItemsCount
});




}
/// @nodoc
class __$FileNodeCopyWithImpl<$Res>
    implements _$FileNodeCopyWith<$Res> {
  __$FileNodeCopyWithImpl(this._self, this._then);

  final _FileNode _self;
  final $Res Function(_FileNode) _then;

/// Create a copy of FileNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? title = null,Object? children = freezed,Object? hash = freezed,Object? mediaStreamUrl = freezed,Object? mediaDownloadUrl = freezed,Object? duration = freezed,Object? size = freezed,Object? workTitle = freezed,Object? artist = freezed,Object? lastModified = null,Object? nodeStatus = null,Object? workId = freezed,Object? source = null,Object? path = freezed,Object? folderPath = freezed,Object? rootPath = freezed,Object? parentPath = freezed,Object? depth = null,Object? subItemsCount = null,}) {
  return _then(_FileNode(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NodeType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,children: freezed == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<FileNode>?,hash: freezed == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String?,mediaStreamUrl: freezed == mediaStreamUrl ? _self.mediaStreamUrl : mediaStreamUrl // ignore: cast_nullable_to_non_nullable
as String?,mediaDownloadUrl: freezed == mediaDownloadUrl ? _self.mediaDownloadUrl : mediaDownloadUrl // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,workTitle: freezed == workTitle ? _self.workTitle : workTitle // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,lastModified: null == lastModified ? _self.lastModified : lastModified // ignore: cast_nullable_to_non_nullable
as int,nodeStatus: null == nodeStatus ? _self.nodeStatus : nodeStatus // ignore: cast_nullable_to_non_nullable
as NodeStatus,workId: freezed == workId ? _self.workId : workId // ignore: cast_nullable_to_non_nullable
as int?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as NodeSource,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,folderPath: freezed == folderPath ? _self.folderPath : folderPath // ignore: cast_nullable_to_non_nullable
as String?,rootPath: freezed == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String?,parentPath: freezed == parentPath ? _self.parentPath : parentPath // ignore: cast_nullable_to_non_nullable
as String?,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as int,subItemsCount: null == subItemsCount ? _self.subItemsCount : subItemsCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
