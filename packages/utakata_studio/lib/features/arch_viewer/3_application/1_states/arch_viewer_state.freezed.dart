// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'arch_viewer_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ArchViewerState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchViewerState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ArchViewerState()';
}


}

/// @nodoc
class $ArchViewerStateCopyWith<$Res>  {
$ArchViewerStateCopyWith(ArchViewerState _, $Res Function(ArchViewerState) __);
}


/// Adds pattern-matching-related methods to [ArchViewerState].
extension ArchViewerStatePatterns on ArchViewerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ArchViewerStateInitial value)?  initial,TResult Function( ArchViewerStateLoading value)?  loading,TResult Function( ArchViewerStateLoaded value)?  loaded,TResult Function( ArchViewerStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ArchViewerStateInitial() when initial != null:
return initial(_that);case ArchViewerStateLoading() when loading != null:
return loading(_that);case ArchViewerStateLoaded() when loaded != null:
return loaded(_that);case ArchViewerStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ArchViewerStateInitial value)  initial,required TResult Function( ArchViewerStateLoading value)  loading,required TResult Function( ArchViewerStateLoaded value)  loaded,required TResult Function( ArchViewerStateError value)  error,}){
final _that = this;
switch (_that) {
case ArchViewerStateInitial():
return initial(_that);case ArchViewerStateLoading():
return loading(_that);case ArchViewerStateLoaded():
return loaded(_that);case ArchViewerStateError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ArchViewerStateInitial value)?  initial,TResult? Function( ArchViewerStateLoading value)?  loading,TResult? Function( ArchViewerStateLoaded value)?  loaded,TResult? Function( ArchViewerStateError value)?  error,}){
final _that = this;
switch (_that) {
case ArchViewerStateInitial() when initial != null:
return initial(_that);case ArchViewerStateLoading() when loading != null:
return loading(_that);case ArchViewerStateLoaded() when loaded != null:
return loaded(_that);case ArchViewerStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( String? projectRoot)?  loading,TResult Function( ValidationResultEntity result,  String projectRoot)?  loaded,TResult Function( String message,  String? projectRoot)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ArchViewerStateInitial() when initial != null:
return initial();case ArchViewerStateLoading() when loading != null:
return loading(_that.projectRoot);case ArchViewerStateLoaded() when loaded != null:
return loaded(_that.result,_that.projectRoot);case ArchViewerStateError() when error != null:
return error(_that.message,_that.projectRoot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( String? projectRoot)  loading,required TResult Function( ValidationResultEntity result,  String projectRoot)  loaded,required TResult Function( String message,  String? projectRoot)  error,}) {final _that = this;
switch (_that) {
case ArchViewerStateInitial():
return initial();case ArchViewerStateLoading():
return loading(_that.projectRoot);case ArchViewerStateLoaded():
return loaded(_that.result,_that.projectRoot);case ArchViewerStateError():
return error(_that.message,_that.projectRoot);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( String? projectRoot)?  loading,TResult? Function( ValidationResultEntity result,  String projectRoot)?  loaded,TResult? Function( String message,  String? projectRoot)?  error,}) {final _that = this;
switch (_that) {
case ArchViewerStateInitial() when initial != null:
return initial();case ArchViewerStateLoading() when loading != null:
return loading(_that.projectRoot);case ArchViewerStateLoaded() when loaded != null:
return loaded(_that.result,_that.projectRoot);case ArchViewerStateError() when error != null:
return error(_that.message,_that.projectRoot);case _:
  return null;

}
}

}

/// @nodoc


class ArchViewerStateInitial implements ArchViewerState {
  const ArchViewerStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchViewerStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ArchViewerState.initial()';
}


}




/// @nodoc


class ArchViewerStateLoading implements ArchViewerState {
  const ArchViewerStateLoading({this.projectRoot});
  

 final  String? projectRoot;

/// Create a copy of ArchViewerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArchViewerStateLoadingCopyWith<ArchViewerStateLoading> get copyWith => _$ArchViewerStateLoadingCopyWithImpl<ArchViewerStateLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchViewerStateLoading&&(identical(other.projectRoot, projectRoot) || other.projectRoot == projectRoot));
}


@override
int get hashCode => Object.hash(runtimeType,projectRoot);

@override
String toString() {
  return 'ArchViewerState.loading(projectRoot: $projectRoot)';
}


}

/// @nodoc
abstract mixin class $ArchViewerStateLoadingCopyWith<$Res> implements $ArchViewerStateCopyWith<$Res> {
  factory $ArchViewerStateLoadingCopyWith(ArchViewerStateLoading value, $Res Function(ArchViewerStateLoading) _then) = _$ArchViewerStateLoadingCopyWithImpl;
@useResult
$Res call({
 String? projectRoot
});




}
/// @nodoc
class _$ArchViewerStateLoadingCopyWithImpl<$Res>
    implements $ArchViewerStateLoadingCopyWith<$Res> {
  _$ArchViewerStateLoadingCopyWithImpl(this._self, this._then);

  final ArchViewerStateLoading _self;
  final $Res Function(ArchViewerStateLoading) _then;

/// Create a copy of ArchViewerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? projectRoot = freezed,}) {
  return _then(ArchViewerStateLoading(
projectRoot: freezed == projectRoot ? _self.projectRoot : projectRoot // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ArchViewerStateLoaded implements ArchViewerState {
  const ArchViewerStateLoaded({required this.result, required this.projectRoot});
  

 final  ValidationResultEntity result;
 final  String projectRoot;

/// Create a copy of ArchViewerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArchViewerStateLoadedCopyWith<ArchViewerStateLoaded> get copyWith => _$ArchViewerStateLoadedCopyWithImpl<ArchViewerStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchViewerStateLoaded&&(identical(other.result, result) || other.result == result)&&(identical(other.projectRoot, projectRoot) || other.projectRoot == projectRoot));
}


@override
int get hashCode => Object.hash(runtimeType,result,projectRoot);

@override
String toString() {
  return 'ArchViewerState.loaded(result: $result, projectRoot: $projectRoot)';
}


}

/// @nodoc
abstract mixin class $ArchViewerStateLoadedCopyWith<$Res> implements $ArchViewerStateCopyWith<$Res> {
  factory $ArchViewerStateLoadedCopyWith(ArchViewerStateLoaded value, $Res Function(ArchViewerStateLoaded) _then) = _$ArchViewerStateLoadedCopyWithImpl;
@useResult
$Res call({
 ValidationResultEntity result, String projectRoot
});


$ValidationResultEntityCopyWith<$Res> get result;

}
/// @nodoc
class _$ArchViewerStateLoadedCopyWithImpl<$Res>
    implements $ArchViewerStateLoadedCopyWith<$Res> {
  _$ArchViewerStateLoadedCopyWithImpl(this._self, this._then);

  final ArchViewerStateLoaded _self;
  final $Res Function(ArchViewerStateLoaded) _then;

/// Create a copy of ArchViewerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? result = null,Object? projectRoot = null,}) {
  return _then(ArchViewerStateLoaded(
result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as ValidationResultEntity,projectRoot: null == projectRoot ? _self.projectRoot : projectRoot // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ArchViewerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ValidationResultEntityCopyWith<$Res> get result {
  
  return $ValidationResultEntityCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc


class ArchViewerStateError implements ArchViewerState {
  const ArchViewerStateError({required this.message, this.projectRoot});
  

 final  String message;
 final  String? projectRoot;

/// Create a copy of ArchViewerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArchViewerStateErrorCopyWith<ArchViewerStateError> get copyWith => _$ArchViewerStateErrorCopyWithImpl<ArchViewerStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchViewerStateError&&(identical(other.message, message) || other.message == message)&&(identical(other.projectRoot, projectRoot) || other.projectRoot == projectRoot));
}


@override
int get hashCode => Object.hash(runtimeType,message,projectRoot);

@override
String toString() {
  return 'ArchViewerState.error(message: $message, projectRoot: $projectRoot)';
}


}

/// @nodoc
abstract mixin class $ArchViewerStateErrorCopyWith<$Res> implements $ArchViewerStateCopyWith<$Res> {
  factory $ArchViewerStateErrorCopyWith(ArchViewerStateError value, $Res Function(ArchViewerStateError) _then) = _$ArchViewerStateErrorCopyWithImpl;
@useResult
$Res call({
 String message, String? projectRoot
});




}
/// @nodoc
class _$ArchViewerStateErrorCopyWithImpl<$Res>
    implements $ArchViewerStateErrorCopyWith<$Res> {
  _$ArchViewerStateErrorCopyWithImpl(this._self, this._then);

  final ArchViewerStateError _self;
  final $Res Function(ArchViewerStateError) _then;

/// Create a copy of ArchViewerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? projectRoot = freezed,}) {
  return _then(ArchViewerStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,projectRoot: freezed == projectRoot ? _self.projectRoot : projectRoot // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
