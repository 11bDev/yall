import 'dart:convert';

/// Model for persisting window state
class WindowState {
  final double? x;
  final double? y;
  final double? width;
  final double? height;
  final bool isMaximized;
  final bool isMinimized;
  final bool isVisible;

  const WindowState({
    this.x,
    this.y,
    this.width,
    this.height,
    this.isMaximized = false,
    this.isMinimized = false,
    this.isVisible = true,
  });

  /// Default window state
  static const WindowState defaultState = WindowState(
    width: 800,
    height: 600,
    isMaximized: false,
    isMinimized: false,
    isVisible: true,
  );

  /// Create WindowState from JSON
  factory WindowState.fromJson(Map<String, dynamic> json) {
    return WindowState(
      x: json['x']?.toDouble(),
      y: json['y']?.toDouble(),
      width: json['width']?.toDouble(),
      height: json['height']?.toDouble(),
      isMaximized: json['isMaximized'] ?? false,
      isMinimized: json['isMinimized'] ?? false,
      isVisible: json['isVisible'] ?? true,
    );
  }

  /// Convert WindowState to JSON
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'isMaximized': isMaximized,
      'isMinimized': isMinimized,
      'isVisible': isVisible,
    };
  }

  /// Create WindowState from JSON string
  factory WindowState.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return WindowState.fromJson(json);
    } catch (e) {
      return defaultState;
    }
  }

  /// Convert WindowState to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create a copy of this WindowState with updated values
  WindowState copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    bool? isMaximized,
    bool? isMinimized,
    bool? isVisible,
  }) {
    return WindowState(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      isMaximized: isMaximized ?? this.isMaximized,
      isMinimized: isMinimized ?? this.isMinimized,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  /// Check if window has valid position
  bool get hasValidPosition => x != null && y != null;

  /// Check if window has valid size
  bool get hasValidSize =>
      width != null && height != null && width! > 0 && height! > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WindowState &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height &&
        other.isMaximized == isMaximized &&
        other.isMinimized == isMinimized &&
        other.isVisible == isVisible;
  }

  @override
  int get hashCode {
    return Object.hash(
      x,
      y,
      width,
      height,
      isMaximized,
      isMinimized,
      isVisible,
    );
  }

  @override
  String toString() {
    return 'WindowState(x: $x, y: $y, width: $width, height: $height, '
        'isMaximized: $isMaximized, isMinimized: $isMinimized, isVisible: $isVisible)';
  }
}
