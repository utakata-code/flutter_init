// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsState()';
}


}

/// @nodoc
class $SettingsStateCopyWith<$Res>  {
$SettingsStateCopyWith(SettingsState _, $Res Function(SettingsState) __);
}


/// Adds pattern-matching-related methods to [SettingsState].
extension SettingsStatePatterns on SettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SettingsStateInitial value)?  initial,TResult Function( SettingsStateLoading value)?  loading,TResult Function( SettingsStateLoaded value)?  loaded,TResult Function( SettingsStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SettingsStateInitial() when initial != null:
return initial(_that);case SettingsStateLoading() when loading != null:
return loading(_that);case SettingsStateLoaded() when loaded != null:
return loaded(_that);case SettingsStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SettingsStateInitial value)  initial,required TResult Function( SettingsStateLoading value)  loading,required TResult Function( SettingsStateLoaded value)  loaded,required TResult Function( SettingsStateError value)  error,}){
final _that = this;
switch (_that) {
case SettingsStateInitial():
return initial(_that);case SettingsStateLoading():
return loading(_that);case SettingsStateLoaded():
return loaded(_that);case SettingsStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SettingsStateInitial value)?  initial,TResult? Function( SettingsStateLoading value)?  loading,TResult? Function( SettingsStateLoaded value)?  loaded,TResult? Function( SettingsStateError value)?  error,}){
final _that = this;
switch (_that) {
case SettingsStateInitial() when initial != null:
return initial(_that);case SettingsStateLoading() when loading != null:
return loading(_that);case SettingsStateLoaded() when loaded != null:
return loaded(_that);case SettingsStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( AppSettingsEntity settings)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SettingsStateInitial() when initial != null:
return initial();case SettingsStateLoading() when loading != null:
return loading();case SettingsStateLoaded() when loaded != null:
return loaded(_that.settings);case SettingsStateError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( AppSettingsEntity settings)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case SettingsStateInitial():
return initial();case SettingsStateLoading():
return loading();case SettingsStateLoaded():
return loaded(_that.settings);case SettingsStateError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( AppSettingsEntity settings)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case SettingsStateInitial() when initial != null:
return initial();case SettingsStateLoading() when loading != null:
return loading();case SettingsStateLoaded() when loaded != null:
return loaded(_that.settings);case SettingsStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class SettingsStateInitial implements SettingsState {
  const SettingsStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsState.initial()';
}


}




/// @nodoc


class SettingsStateLoading implements SettingsState {
  const SettingsStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsState.loading()';
}


}




/// @nodoc


class SettingsStateLoaded implements SettingsState {
  const SettingsStateLoaded({required this.settings});
  

 final  AppSettingsEntity settings;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsStateLoadedCopyWith<SettingsStateLoaded> get copyWith => _$SettingsStateLoadedCopyWithImpl<SettingsStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsStateLoaded&&(identical(other.settings, settings) || other.settings == settings));
}


@override
int get hashCode => Object.hash(runtimeType,settings);

@override
String toString() {
  return 'SettingsState.loaded(settings: $settings)';
}


}

/// @nodoc
abstract mixin class $SettingsStateLoadedCopyWith<$Res> implements $SettingsStateCopyWith<$Res> {
  factory $SettingsStateLoadedCopyWith(SettingsStateLoaded value, $Res Function(SettingsStateLoaded) _then) = _$SettingsStateLoadedCopyWithImpl;
@useResult
$Res call({
 AppSettingsEntity settings
});


$AppSettingsEntityCopyWith<$Res> get settings;

}
/// @nodoc
class _$SettingsStateLoadedCopyWithImpl<$Res>
    implements $SettingsStateLoadedCopyWith<$Res> {
  _$SettingsStateLoadedCopyWithImpl(this._self, this._then);

  final SettingsStateLoaded _self;
  final $Res Function(SettingsStateLoaded) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? settings = null,}) {
  return _then(SettingsStateLoaded(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as AppSettingsEntity,
  ));
}

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppSettingsEntityCopyWith<$Res> get settings {
  
  return $AppSettingsEntityCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

/// @nodoc


class SettingsStateError implements SettingsState {
  const SettingsStateError(this.message);
  

 final  String message;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsStateErrorCopyWith<SettingsStateError> get copyWith => _$SettingsStateErrorCopyWithImpl<SettingsStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'SettingsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $SettingsStateErrorCopyWith<$Res> implements $SettingsStateCopyWith<$Res> {
  factory $SettingsStateErrorCopyWith(SettingsStateError value, $Res Function(SettingsStateError) _then) = _$SettingsStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$SettingsStateErrorCopyWithImpl<$Res>
    implements $SettingsStateErrorCopyWith<$Res> {
  _$SettingsStateErrorCopyWithImpl(this._self, this._then);

  final SettingsStateError _self;
  final $Res Function(SettingsStateError) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(SettingsStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
