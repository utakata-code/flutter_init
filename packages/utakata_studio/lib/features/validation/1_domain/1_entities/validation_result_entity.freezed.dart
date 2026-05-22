// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'validation_result_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ValidationResultEntity {

 String get yamlContent; bool get isValid; String? get errorMessage; List<LayerDefinitionEntity> get layers; List<NamingRuleEntity> get namingRules; List<CoreModuleEntity> get coreModules; List<GuideEntity> get guides;
/// Create a copy of ValidationResultEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValidationResultEntityCopyWith<ValidationResultEntity> get copyWith => _$ValidationResultEntityCopyWithImpl<ValidationResultEntity>(this as ValidationResultEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidationResultEntity&&(identical(other.yamlContent, yamlContent) || other.yamlContent == yamlContent)&&(identical(other.isValid, isValid) || other.isValid == isValid)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&const DeepCollectionEquality().equals(other.layers, layers)&&const DeepCollectionEquality().equals(other.namingRules, namingRules)&&const DeepCollectionEquality().equals(other.coreModules, coreModules)&&const DeepCollectionEquality().equals(other.guides, guides));
}


@override
int get hashCode => Object.hash(runtimeType,yamlContent,isValid,errorMessage,const DeepCollectionEquality().hash(layers),const DeepCollectionEquality().hash(namingRules),const DeepCollectionEquality().hash(coreModules),const DeepCollectionEquality().hash(guides));

@override
String toString() {
  return 'ValidationResultEntity(yamlContent: $yamlContent, isValid: $isValid, errorMessage: $errorMessage, layers: $layers, namingRules: $namingRules, coreModules: $coreModules, guides: $guides)';
}


}

/// @nodoc
abstract mixin class $ValidationResultEntityCopyWith<$Res>  {
  factory $ValidationResultEntityCopyWith(ValidationResultEntity value, $Res Function(ValidationResultEntity) _then) = _$ValidationResultEntityCopyWithImpl;
@useResult
$Res call({
 String yamlContent, bool isValid, String? errorMessage, List<LayerDefinitionEntity> layers, List<NamingRuleEntity> namingRules, List<CoreModuleEntity> coreModules, List<GuideEntity> guides
});




}
/// @nodoc
class _$ValidationResultEntityCopyWithImpl<$Res>
    implements $ValidationResultEntityCopyWith<$Res> {
  _$ValidationResultEntityCopyWithImpl(this._self, this._then);

  final ValidationResultEntity _self;
  final $Res Function(ValidationResultEntity) _then;

/// Create a copy of ValidationResultEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? yamlContent = null,Object? isValid = null,Object? errorMessage = freezed,Object? layers = null,Object? namingRules = null,Object? coreModules = null,Object? guides = null,}) {
  return _then(_self.copyWith(
yamlContent: null == yamlContent ? _self.yamlContent : yamlContent // ignore: cast_nullable_to_non_nullable
as String,isValid: null == isValid ? _self.isValid : isValid // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,layers: null == layers ? _self.layers : layers // ignore: cast_nullable_to_non_nullable
as List<LayerDefinitionEntity>,namingRules: null == namingRules ? _self.namingRules : namingRules // ignore: cast_nullable_to_non_nullable
as List<NamingRuleEntity>,coreModules: null == coreModules ? _self.coreModules : coreModules // ignore: cast_nullable_to_non_nullable
as List<CoreModuleEntity>,guides: null == guides ? _self.guides : guides // ignore: cast_nullable_to_non_nullable
as List<GuideEntity>,
  ));
}

}


/// Adds pattern-matching-related methods to [ValidationResultEntity].
extension ValidationResultEntityPatterns on ValidationResultEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ValidationResultEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ValidationResultEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ValidationResultEntity value)  $default,){
final _that = this;
switch (_that) {
case _ValidationResultEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ValidationResultEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ValidationResultEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String yamlContent,  bool isValid,  String? errorMessage,  List<LayerDefinitionEntity> layers,  List<NamingRuleEntity> namingRules,  List<CoreModuleEntity> coreModules,  List<GuideEntity> guides)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ValidationResultEntity() when $default != null:
return $default(_that.yamlContent,_that.isValid,_that.errorMessage,_that.layers,_that.namingRules,_that.coreModules,_that.guides);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String yamlContent,  bool isValid,  String? errorMessage,  List<LayerDefinitionEntity> layers,  List<NamingRuleEntity> namingRules,  List<CoreModuleEntity> coreModules,  List<GuideEntity> guides)  $default,) {final _that = this;
switch (_that) {
case _ValidationResultEntity():
return $default(_that.yamlContent,_that.isValid,_that.errorMessage,_that.layers,_that.namingRules,_that.coreModules,_that.guides);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String yamlContent,  bool isValid,  String? errorMessage,  List<LayerDefinitionEntity> layers,  List<NamingRuleEntity> namingRules,  List<CoreModuleEntity> coreModules,  List<GuideEntity> guides)?  $default,) {final _that = this;
switch (_that) {
case _ValidationResultEntity() when $default != null:
return $default(_that.yamlContent,_that.isValid,_that.errorMessage,_that.layers,_that.namingRules,_that.coreModules,_that.guides);case _:
  return null;

}
}

}

/// @nodoc


class _ValidationResultEntity extends ValidationResultEntity {
  const _ValidationResultEntity({required this.yamlContent, required this.isValid, this.errorMessage, final  List<LayerDefinitionEntity> layers = const [], final  List<NamingRuleEntity> namingRules = const [], final  List<CoreModuleEntity> coreModules = const [], final  List<GuideEntity> guides = const []}): _layers = layers,_namingRules = namingRules,_coreModules = coreModules,_guides = guides,super._();
  

@override final  String yamlContent;
@override final  bool isValid;
@override final  String? errorMessage;
 final  List<LayerDefinitionEntity> _layers;
@override@JsonKey() List<LayerDefinitionEntity> get layers {
  if (_layers is EqualUnmodifiableListView) return _layers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_layers);
}

 final  List<NamingRuleEntity> _namingRules;
@override@JsonKey() List<NamingRuleEntity> get namingRules {
  if (_namingRules is EqualUnmodifiableListView) return _namingRules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_namingRules);
}

 final  List<CoreModuleEntity> _coreModules;
@override@JsonKey() List<CoreModuleEntity> get coreModules {
  if (_coreModules is EqualUnmodifiableListView) return _coreModules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coreModules);
}

 final  List<GuideEntity> _guides;
@override@JsonKey() List<GuideEntity> get guides {
  if (_guides is EqualUnmodifiableListView) return _guides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_guides);
}


/// Create a copy of ValidationResultEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ValidationResultEntityCopyWith<_ValidationResultEntity> get copyWith => __$ValidationResultEntityCopyWithImpl<_ValidationResultEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ValidationResultEntity&&(identical(other.yamlContent, yamlContent) || other.yamlContent == yamlContent)&&(identical(other.isValid, isValid) || other.isValid == isValid)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&const DeepCollectionEquality().equals(other._layers, _layers)&&const DeepCollectionEquality().equals(other._namingRules, _namingRules)&&const DeepCollectionEquality().equals(other._coreModules, _coreModules)&&const DeepCollectionEquality().equals(other._guides, _guides));
}


@override
int get hashCode => Object.hash(runtimeType,yamlContent,isValid,errorMessage,const DeepCollectionEquality().hash(_layers),const DeepCollectionEquality().hash(_namingRules),const DeepCollectionEquality().hash(_coreModules),const DeepCollectionEquality().hash(_guides));

@override
String toString() {
  return 'ValidationResultEntity(yamlContent: $yamlContent, isValid: $isValid, errorMessage: $errorMessage, layers: $layers, namingRules: $namingRules, coreModules: $coreModules, guides: $guides)';
}


}

/// @nodoc
abstract mixin class _$ValidationResultEntityCopyWith<$Res> implements $ValidationResultEntityCopyWith<$Res> {
  factory _$ValidationResultEntityCopyWith(_ValidationResultEntity value, $Res Function(_ValidationResultEntity) _then) = __$ValidationResultEntityCopyWithImpl;
@override @useResult
$Res call({
 String yamlContent, bool isValid, String? errorMessage, List<LayerDefinitionEntity> layers, List<NamingRuleEntity> namingRules, List<CoreModuleEntity> coreModules, List<GuideEntity> guides
});




}
/// @nodoc
class __$ValidationResultEntityCopyWithImpl<$Res>
    implements _$ValidationResultEntityCopyWith<$Res> {
  __$ValidationResultEntityCopyWithImpl(this._self, this._then);

  final _ValidationResultEntity _self;
  final $Res Function(_ValidationResultEntity) _then;

/// Create a copy of ValidationResultEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? yamlContent = null,Object? isValid = null,Object? errorMessage = freezed,Object? layers = null,Object? namingRules = null,Object? coreModules = null,Object? guides = null,}) {
  return _then(_ValidationResultEntity(
yamlContent: null == yamlContent ? _self.yamlContent : yamlContent // ignore: cast_nullable_to_non_nullable
as String,isValid: null == isValid ? _self.isValid : isValid // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,layers: null == layers ? _self._layers : layers // ignore: cast_nullable_to_non_nullable
as List<LayerDefinitionEntity>,namingRules: null == namingRules ? _self._namingRules : namingRules // ignore: cast_nullable_to_non_nullable
as List<NamingRuleEntity>,coreModules: null == coreModules ? _self._coreModules : coreModules // ignore: cast_nullable_to_non_nullable
as List<CoreModuleEntity>,guides: null == guides ? _self._guides : guides // ignore: cast_nullable_to_non_nullable
as List<GuideEntity>,
  ));
}


}

// dart format on
