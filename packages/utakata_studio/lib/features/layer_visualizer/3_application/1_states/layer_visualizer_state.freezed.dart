// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'layer_visualizer_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LayerVisualizerState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LayerVisualizerState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LayerVisualizerState()';
}


}

/// @nodoc
class $LayerVisualizerStateCopyWith<$Res>  {
$LayerVisualizerStateCopyWith(LayerVisualizerState _, $Res Function(LayerVisualizerState) __);
}


/// Adds pattern-matching-related methods to [LayerVisualizerState].
extension LayerVisualizerStatePatterns on LayerVisualizerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LayerVisualizerStateInitial value)?  initial,TResult Function( LayerVisualizerStateLoaded value)?  loaded,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LayerVisualizerStateInitial() when initial != null:
return initial(_that);case LayerVisualizerStateLoaded() when loaded != null:
return loaded(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LayerVisualizerStateInitial value)  initial,required TResult Function( LayerVisualizerStateLoaded value)  loaded,}){
final _that = this;
switch (_that) {
case LayerVisualizerStateInitial():
return initial(_that);case LayerVisualizerStateLoaded():
return loaded(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LayerVisualizerStateInitial value)?  initial,TResult? Function( LayerVisualizerStateLoaded value)?  loaded,}){
final _that = this;
switch (_that) {
case LayerVisualizerStateInitial() when initial != null:
return initial(_that);case LayerVisualizerStateLoaded() when loaded != null:
return loaded(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( List<LayerDefinitionEntity> layers)?  loaded,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LayerVisualizerStateInitial() when initial != null:
return initial();case LayerVisualizerStateLoaded() when loaded != null:
return loaded(_that.layers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( List<LayerDefinitionEntity> layers)  loaded,}) {final _that = this;
switch (_that) {
case LayerVisualizerStateInitial():
return initial();case LayerVisualizerStateLoaded():
return loaded(_that.layers);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( List<LayerDefinitionEntity> layers)?  loaded,}) {final _that = this;
switch (_that) {
case LayerVisualizerStateInitial() when initial != null:
return initial();case LayerVisualizerStateLoaded() when loaded != null:
return loaded(_that.layers);case _:
  return null;

}
}

}

/// @nodoc


class LayerVisualizerStateInitial implements LayerVisualizerState {
  const LayerVisualizerStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LayerVisualizerStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LayerVisualizerState.initial()';
}


}




/// @nodoc


class LayerVisualizerStateLoaded implements LayerVisualizerState {
  const LayerVisualizerStateLoaded({required final  List<LayerDefinitionEntity> layers}): _layers = layers;
  

 final  List<LayerDefinitionEntity> _layers;
 List<LayerDefinitionEntity> get layers {
  if (_layers is EqualUnmodifiableListView) return _layers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_layers);
}


/// Create a copy of LayerVisualizerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LayerVisualizerStateLoadedCopyWith<LayerVisualizerStateLoaded> get copyWith => _$LayerVisualizerStateLoadedCopyWithImpl<LayerVisualizerStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LayerVisualizerStateLoaded&&const DeepCollectionEquality().equals(other._layers, _layers));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_layers));

@override
String toString() {
  return 'LayerVisualizerState.loaded(layers: $layers)';
}


}

/// @nodoc
abstract mixin class $LayerVisualizerStateLoadedCopyWith<$Res> implements $LayerVisualizerStateCopyWith<$Res> {
  factory $LayerVisualizerStateLoadedCopyWith(LayerVisualizerStateLoaded value, $Res Function(LayerVisualizerStateLoaded) _then) = _$LayerVisualizerStateLoadedCopyWithImpl;
@useResult
$Res call({
 List<LayerDefinitionEntity> layers
});




}
/// @nodoc
class _$LayerVisualizerStateLoadedCopyWithImpl<$Res>
    implements $LayerVisualizerStateLoadedCopyWith<$Res> {
  _$LayerVisualizerStateLoadedCopyWithImpl(this._self, this._then);

  final LayerVisualizerStateLoaded _self;
  final $Res Function(LayerVisualizerStateLoaded) _then;

/// Create a copy of LayerVisualizerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? layers = null,}) {
  return _then(LayerVisualizerStateLoaded(
layers: null == layers ? _self._layers : layers // ignore: cast_nullable_to_non_nullable
as List<LayerDefinitionEntity>,
  ));
}


}

// dart format on
