import 'package:flutter/foundation.dart';

@immutable
class CustomInput {
  const CustomInput({required this.name, required this.value});

  factory CustomInput.fromJson(Map<String, Object?> json) {
    return CustomInput(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  final String name;
  final String value;

  bool get isEmpty => name.trim().isEmpty && value.trim().isEmpty;

  CustomInput copyWith({String? name, String? value}) {
    return CustomInput(name: name ?? this.name, value: value ?? this.value);
  }

  Map<String, Object?> toJson() => <String, Object?>{'name': name, 'value': value};

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomInput && other.name == name && other.value == value;
  }

  @override
  int get hashCode => Object.hash(name, value);
}
