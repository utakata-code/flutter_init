// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'validation_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ValidationState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidationState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ValidationState()';
}


}

/// @nodoc
class $ValidationStateCopyWith<$Res>  {
$ValidationStateCopyWith(ValidationState _, $Res Function(ValidationState) __);
}


/// Adds pattern-matching-related methods to [ValidationState].
extension ValidationStatePatterns on ValidationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ValidationStateInitial value)?  initial,TResult Function( ValidationStateLoading value)?  loading,TResult Function( ValidationStateLoaded value)?  loaded,TResult Function( ValidationStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ValidationStateInitial() when initial != null:
return initial(_that);case ValidationStateLoading() when loading != null:
return loading(_that);case ValidationStateLoaded() when loaded != null:
return loaded(_that);case ValidationStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ValidationStateInitial value)  initial,required TResult Function( ValidationStateLoading value)  loading,required TResult Function( ValidationStateLoaded value)  loaded,required TResult Function( ValidationStateError value)  error,}){
final _that = this;
switch (_that) {
case ValidationStateInitial():
return initial(_that);case ValidationStateLoading():
return loading(_that);case ValidationStateLoaded():
return loaded(_that);case ValidationStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ValidationStateInitial value)?  initial,TResult? Function( ValidationStateLoading value)?  loading,TResult? Function( ValidationStateLoaded value)?  loaded,TResult? Function( ValidationStateError value)?  error,}){
final _that = this;
switch (_that) {
case ValidationStateInitial() when initial != null:
return initial(_that);case ValidationStateLoading() when loading != null:
return loading(_that);case ValidationStateLoaded() when loaded != null:
return loaded(_that);case ValidationStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( String? filePath)?  loading,TResult Function( ValidationResultEntity result,  String filePath)?  loaded,TResult Function( String message,  String? filePath)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ValidationStateInitial() when initial != null:
return initial();case ValidationStateLoading() when loading != null:
return loading(_that.filePath);case ValidationStateLoaded() when loaded != null:
return loaded(_that.result,_that.filePath);case ValidationStateError() when error != null:
return error(_that.message,_that.filePath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( String? filePath)  loading,required TResult Function( ValidationResultEntity result,  String filePath)  loaded,required TResult Function( String message,  String? filePath)  error,}) {final _that = this;
switch (_that) {
case ValidationStateInitial():
return initial();case ValidationStateLoading():
return loading(_that.filePath);case ValidationStateLoaded():
return loaded(_that.result,_that.filePath);case ValidationStateError():
return error(_that.message,_that.filePath);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( String? filePath)?  loading,TResult? Function( ValidationResultEntity result,  String filePath)?  loaded,TResult? Function( String message,  String? filePath)?  error,}) {final _that = this;
switch (_that) {
case ValidationStateInitial() when initial != null:
return initial();case ValidationStateLoading() when loading != null:
return loading(_that.filePath);case ValidationStateLoaded() when loaded != null:
return loaded(_that.result,_that.filePath);case ValidationStateError() when error != null:
return error(_that.message,_that.filePath);case _:
  return null;

}
}

}

/// @nodoc


class ValidationStateInitial implements ValidationState {
  const ValidationStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidationStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ValidationState.initial()';
}


}




/// @nodoc


class ValidationStateLoading implements ValidationState {
  const ValidationStateLoading({this.filePath});
  

 final  String? filePath;

/// Create a copy of ValidationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValidationStateLoadingCopyWith<ValidationStateLoading> get copyWith => _$ValidationStateLoadingCopyWithImpl<ValidationStateLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidationStateLoading&&(identical(other.filePath, filePath) || other.filePath == filePath));
}


@override
int get hashCode => Object.hash(runtimeType,filePath);

@override
String toString() {
  return 'ValidationState.loading(filePath: $filePath)';
}


}

/// @nodoc
abstract mixin class $ValidationStateLoadingCopyWith<$Res> implements $ValidationStateCopyWith<$Res> {
  factory $ValidationStateLoadingCopyWith(ValidationStateLoading value, $Res Function(ValidationStateLoading) _then) = _$ValidationStateLoadingCopyWithImpl;
@useResult
$Res call({
 String? filePath
});




}
/// @nodoc
class _$ValidationStateLoadingCopyWithImpl<$Res>
    implements $ValidationStateLoadingCopyWith<$Res> {
  _$ValidationStateLoadingCopyWithImpl(this._self, this._then);

  final ValidationStateLoading _self;
  final $Res Function(ValidationStateLoading) _then;

/// Create a copy of ValidationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? filePath = freezed,}) {
  return _then(ValidationStateLoading(
filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ValidationStateLoaded implements ValidationState {
  const ValidationStateLoaded({required this.result, required this.filePath});
  

 final  ValidationResultEntity result;
 final  String filePath;

/// Create a copy of ValidationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValidationStateLoadedCopyWith<ValidationStateLoaded> get copyWith => _$ValidationStateLoadedCopyWithImpl<ValidationStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidationStateLoaded&&(identical(other.result, result) || other.result == result)&&(identical(other.filePath, filePath) || other.filePath == filePath));
}


@override
int get hashCode => Object.hash(runtimeType,result,filePath);

@override
String toString() {
  return 'ValidationState.loaded(result: $result, filePath: $filePath)';
}


}

/// @nodoc
abstract mixin class $ValidationStateLoadedCopyWith<$Res> implements $ValidationStateCopyWith<$Res> {
  factory $ValidationStateLoadedCopyWith(ValidationStateLoaded value, $Res Function(ValidationStateLoaded) _then) = _$ValidationStateLoadedCopyWithImpl;
@useResult
$Res call({
 ValidationResultEntity result, String filePath
});


$ValidationResultEntityCopyWith<$Res> get result;

}
/// @nodoc
class _$ValidationStateLoadedCopyWithImpl<$Res>
    implements $ValidationStateLoadedCopyWith<$Res> {
  _$ValidationStateLoadedCopyWithImpl(this._self, this._then);

  final ValidationStateLoaded _self;
  final $Res Function(ValidationStateLoaded) _then;

/// Create a copy of ValidationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? result = null,Object? filePath = null,}) {
  return _then(ValidationStateLoaded(
result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as ValidationResultEntity,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ValidationState
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


class ValidationStateError implements ValidationState {
  const ValidationStateError({required this.message, this.filePath});
  

 final  String message;
 final  String? filePath;

/// Create a copy of ValidationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValidationStateErrorCopyWith<ValidationStateError> get copyWith => _$ValidationStateErrorCopyWithImpl<ValidationStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidationStateError&&(identical(other.message, message) || other.message == message)&&(identical(other.filePath, filePath) || other.filePath == filePath));
}


@override
int get hashCode => Object.hash(runtimeType,message,filePath);

@override
String toString() {
  return 'ValidationState.error(message: $message, filePath: $filePath)';
}


}

/// @nodoc
abstract mixin class $ValidationStateErrorCopyWith<$Res> implements $ValidationStateCopyWith<$Res> {
  factory $ValidationStateErrorCopyWith(ValidationStateError value, $Res Function(ValidationStateError) _then) = _$ValidationStateErrorCopyWithImpl;
@useResult
$Res call({
 String message, String? filePath
});




}
/// @nodoc
class _$ValidationStateErrorCopyWithImpl<$Res>
    implements $ValidationStateErrorCopyWith<$Res> {
  _$ValidationStateErrorCopyWithImpl(this._self, this._then);

  final ValidationStateError _self;
  final $Res Function(ValidationStateError) _then;

/// Create a copy of ValidationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? filePath = freezed,}) {
  return _then(ValidationStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
