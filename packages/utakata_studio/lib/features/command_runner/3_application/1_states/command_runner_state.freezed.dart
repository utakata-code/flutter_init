// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'command_runner_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommandRunnerState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommandRunnerState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommandRunnerState()';
}


}

/// @nodoc
class $CommandRunnerStateCopyWith<$Res>  {
$CommandRunnerStateCopyWith(CommandRunnerState _, $Res Function(CommandRunnerState) __);
}


/// Adds pattern-matching-related methods to [CommandRunnerState].
extension CommandRunnerStatePatterns on CommandRunnerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Idle value)?  idle,TResult Function( _Running value)?  running,TResult Function( _Completed value)?  completed,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle(_that);case _Running() when running != null:
return running(_that);case _Completed() when completed != null:
return completed(_that);case _Error() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Idle value)  idle,required TResult Function( _Running value)  running,required TResult Function( _Completed value)  completed,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Idle():
return idle(_that);case _Running():
return running(_that);case _Completed():
return completed(_that);case _Error():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Idle value)?  idle,TResult? Function( _Running value)?  running,TResult? Function( _Completed value)?  completed,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle(_that);case _Running() when running != null:
return running(_that);case _Completed() when completed != null:
return completed(_that);case _Error() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( String command,  List<String> outputLines)?  running,TResult Function( CommandResultEntity result)?  completed,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle();case _Running() when running != null:
return running(_that.command,_that.outputLines);case _Completed() when completed != null:
return completed(_that.result);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( String command,  List<String> outputLines)  running,required TResult Function( CommandResultEntity result)  completed,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Idle():
return idle();case _Running():
return running(_that.command,_that.outputLines);case _Completed():
return completed(_that.result);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( String command,  List<String> outputLines)?  running,TResult? Function( CommandResultEntity result)?  completed,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle();case _Running() when running != null:
return running(_that.command,_that.outputLines);case _Completed() when completed != null:
return completed(_that.result);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Idle implements CommandRunnerState {
  const _Idle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Idle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommandRunnerState.idle()';
}


}




/// @nodoc


class _Running implements CommandRunnerState {
  const _Running({required this.command, required final  List<String> outputLines}): _outputLines = outputLines;
  

 final  String command;
 final  List<String> _outputLines;
 List<String> get outputLines {
  if (_outputLines is EqualUnmodifiableListView) return _outputLines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_outputLines);
}


/// Create a copy of CommandRunnerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RunningCopyWith<_Running> get copyWith => __$RunningCopyWithImpl<_Running>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Running&&(identical(other.command, command) || other.command == command)&&const DeepCollectionEquality().equals(other._outputLines, _outputLines));
}


@override
int get hashCode => Object.hash(runtimeType,command,const DeepCollectionEquality().hash(_outputLines));

@override
String toString() {
  return 'CommandRunnerState.running(command: $command, outputLines: $outputLines)';
}


}

/// @nodoc
abstract mixin class _$RunningCopyWith<$Res> implements $CommandRunnerStateCopyWith<$Res> {
  factory _$RunningCopyWith(_Running value, $Res Function(_Running) _then) = __$RunningCopyWithImpl;
@useResult
$Res call({
 String command, List<String> outputLines
});




}
/// @nodoc
class __$RunningCopyWithImpl<$Res>
    implements _$RunningCopyWith<$Res> {
  __$RunningCopyWithImpl(this._self, this._then);

  final _Running _self;
  final $Res Function(_Running) _then;

/// Create a copy of CommandRunnerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? command = null,Object? outputLines = null,}) {
  return _then(_Running(
command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,outputLines: null == outputLines ? _self._outputLines : outputLines // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class _Completed implements CommandRunnerState {
  const _Completed({required this.result});
  

 final  CommandResultEntity result;

/// Create a copy of CommandRunnerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompletedCopyWith<_Completed> get copyWith => __$CompletedCopyWithImpl<_Completed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Completed&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,result);

@override
String toString() {
  return 'CommandRunnerState.completed(result: $result)';
}


}

/// @nodoc
abstract mixin class _$CompletedCopyWith<$Res> implements $CommandRunnerStateCopyWith<$Res> {
  factory _$CompletedCopyWith(_Completed value, $Res Function(_Completed) _then) = __$CompletedCopyWithImpl;
@useResult
$Res call({
 CommandResultEntity result
});




}
/// @nodoc
class __$CompletedCopyWithImpl<$Res>
    implements _$CompletedCopyWith<$Res> {
  __$CompletedCopyWithImpl(this._self, this._then);

  final _Completed _self;
  final $Res Function(_Completed) _then;

/// Create a copy of CommandRunnerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? result = null,}) {
  return _then(_Completed(
result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as CommandResultEntity,
  ));
}


}

/// @nodoc


class _Error implements CommandRunnerState {
  const _Error({required this.message});
  

 final  String message;

/// Create a copy of CommandRunnerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'CommandRunnerState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $CommandRunnerStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of CommandRunnerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
