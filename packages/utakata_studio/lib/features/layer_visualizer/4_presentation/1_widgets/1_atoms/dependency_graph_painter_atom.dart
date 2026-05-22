import 'package:flutter/material.dart';

/// 依存関係の矢印を描画する CustomPainter
///
/// ノード間をベジエ曲線で接続し、矢頭を描画する。
class DependencyGraphPainter extends CustomPainter {
  final List<DependencyEdge> edges;
  final double nodeHeight;
  final double groupPadding;

  DependencyGraphPainter({
    required this.edges,
    this.nodeHeight = 32,
    this.groupPadding = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final paint = Paint()
        ..color = edge.color.withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final startX = edge.startX;
      final startY = edge.startY;
      final endX = edge.endX;
      final endY = edge.endY;

      // ベジエ曲線
      final path = Path();
      path.moveTo(startX, startY);

      if ((startY - endY).abs() < 2) {
        // 同じ行: 直線
        path.lineTo(endX, endY);
      } else {
        // 異なる行: ベジエ曲線
        final midY = (startY + endY) / 2;
        path.cubicTo(startX, midY, endX, midY, endX, endY);
      }

      canvas.drawPath(path, paint);

      // 矢頭
      _drawArrowHead(canvas, endX, endY, edge.color.withValues(alpha: 0.6),
          startX < endX ? 0 : startY < endY ? 1 : -1);
    }
  }

  void _drawArrowHead(
      Canvas canvas, double x, double y, Color color, int direction) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const size = 5.0;

    if (direction == 0) {
      // 右向き
      path.moveTo(x, y);
      path.lineTo(x - size, y - size / 2);
      path.lineTo(x - size, y + size / 2);
    } else if (direction == 1) {
      // 下向き
      path.moveTo(x, y);
      path.lineTo(x - size / 2, y - size);
      path.lineTo(x + size / 2, y - size);
    } else {
      // 上向き
      path.moveTo(x, y);
      path.lineTo(x - size / 2, y + size);
      path.lineTo(x + size / 2, y + size);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DependencyGraphPainter oldDelegate) {
    return edges != oldDelegate.edges;
  }
}

/// 依存エッジ（接続線）のデータ
class DependencyEdge {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final Color color;

  const DependencyEdge({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.color,
  });
}
