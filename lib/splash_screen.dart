import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_routes.dart';
import 'app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sceneFade;
  late Animation<double> _routeProgress;
  late Animation<double> _logoScale;
  late Animation<double> _brandFade;
  late Animation<Offset> _brandSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5800),
    );

    _sceneFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.18, curve: Curves.easeOut),
      ),
    );

    _routeProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.16, 0.78, curve: Curves.easeInOutCubic),
      ),
    );

    _logoScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.68, 0.88, curve: Curves.elasticOut),
      ),
    );

    _brandFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.78, 1.0, curve: Curves.easeOut),
      ),
    );

    _brandSlide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.78, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 7500), () {
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _sceneFade,
                      child: Container(
                        width: 340,
                        height: 220,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4F0),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE8DDD2)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              CustomPaint(
                                size: const Size(340, 220),
                                painter: _GridRoutePainter(
                                  progress: _routeProgress.value,
                                  primary: AppColors.primary,
                                  muted: const Color(0xFFD9CEC2),
                                  gridMajor: const Color(0xFFC4B5A5),
                                  gridMinor: const Color(0xFFE0D6CC),
                                  textColor: AppColors.textSecondary,
                                ),
                              ),
                              Positioned(
                                left: 12,
                                top: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.92),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFE8DDD2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.near_me_rounded,
                                        size: 12,
                                        color:
                                            AppColors.primary.withOpacity(0.85),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tapal Kuda',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary
                                              .withOpacity(0.9),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 14,
                                top: 36,
                                child: Transform.scale(
                                  scale: _logoScale.value,
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            AppColors.primary.withOpacity(0.35),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withOpacity(0.18),
                                          blurRadius: 14,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) {
                                        return const Icon(
                                          Icons.local_cafe_rounded,
                                          color: AppColors.primary,
                                          size: 26,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _brandFade,
                      child: SlideTransition(
                        position: _brandSlide,
                        child: Column(
                          children: [
                            Text(
                              'Kopiku Mana',
                              style: AppTextStyles.headingLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 30,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppConstants.appTagline,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 110,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          value: _controller.value,
                          backgroundColor: const Color(0xFFE6D8C8),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GridRoutePainter extends CustomPainter {
  final double progress;
  final Color primary;
  final Color muted;
  final Color gridMajor;
  final Color gridMinor;
  final Color textColor;

  _GridRoutePainter({
    required this.progress,
    required this.primary,
    required this.muted,
    required this.gridMajor,
    required this.gridMinor,
    required this.textColor,
  });

  static const double _cell = 28;

  List<_CityPoint> _cities(Size size) {
    return [
      _CityPoint(
        'Probolinggo',
        Offset(size.width * 0.13, size.height * 0.48),
        0.08,
        labelSide: _LabelSide.above,
      ),
      _CityPoint(
        'Lumajang',
        Offset(size.width * 0.27, size.height * 0.64),
        0.22,
        labelSide: _LabelSide.below,
      ),
      _CityPoint(
        'Jember',
        Offset(size.width * 0.42, size.height * 0.76),
        0.36,
        labelSide: _LabelSide.below,
      ),
      _CityPoint(
        'Bondowoso',
        Offset(size.width * 0.52, size.height * 0.54),
        0.50,
        labelSide: _LabelSide.left,
      ),
      _CityPoint(
        'Situbondo',
        Offset(size.width * 0.62, size.height * 0.34),
        0.64,
        labelSide: _LabelSide.above,
      ),
      _CityPoint(
        'Banyuwangi',
        Offset(size.width * 0.84, size.height * 0.52),
        0.78,
        labelSide: _LabelSide.below,
      ),
    ];
  }

  Path _buildRoute(Size size) {
    final cities = _cities(size);
    final p0 = cities[0].offset;
    final p1 = cities[1].offset;
    final p2 = cities[2].offset;
    final p3 = cities[3].offset;
    final p4 = cities[4].offset;
    final p5 = cities[5].offset;

    return Path()
      ..moveTo(p0.dx, p0.dy)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.44,
        size.width * 0.21,
        size.height * 0.66,
        p1.dx,
        p1.dy,
      )
      ..cubicTo(
        size.width * 0.32,
        size.height * 0.70,
        size.width * 0.34,
        size.height * 0.82,
        p2.dx,
        p2.dy,
      )
      ..cubicTo(
        size.width * 0.46,
        size.height * 0.70,
        size.width * 0.47,
        size.height * 0.48,
        p3.dx,
        p3.dy,
      )
      ..cubicTo(
        size.width * 0.56,
        size.height * 0.42,
        size.width * 0.57,
        size.height * 0.30,
        p4.dx,
        p4.dy,
      )
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.28,
        size.width * 0.76,
        size.height * 0.58,
        p5.dx,
        p5.dy,
      );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawRoute(canvas, size);
    _drawCities(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final minorPaint = Paint()
      ..color = gridMinor.withOpacity(0.55)
      ..strokeWidth = 0.6;

    final majorPaint = Paint()
      ..color = gridMajor.withOpacity(0.45)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += _cell) {
      final isMajor = (x / _cell).round() % 4 == 0;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMajor ? majorPaint : minorPaint,
      );
    }

    for (double y = 0; y <= size.height; y += _cell) {
      final isMajor = (y / _cell).round() % 4 == 0;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isMajor ? majorPaint : minorPaint,
      );
    }

    final crossPaint = Paint()
      ..color = primary.withOpacity(0.12)
      ..strokeWidth = 1;

    for (double x = _cell; x < size.width; x += _cell * 2) {
      for (double y = _cell; y < size.height; y += _cell * 2) {
        const len = 3.0;
        canvas.drawLine(Offset(x - len, y), Offset(x + len, y), crossPaint);
        canvas.drawLine(Offset(x, y - len), Offset(x, y + len), crossPaint);
      }
    }
  }

  void _drawRoute(Canvas canvas, Size size) {
    final routePath = _buildRoute(size);

    final basePaint = Paint()
      ..color = muted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(routePath, basePaint);

    for (final metric in routePath.computeMetrics()) {
      final visible = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(visible, activePaint);

      if (progress > 0.03 && progress < 0.97) {
        final tangent = metric.getTangentForOffset(metric.length * progress);
        if (tangent != null) {
          final p = tangent.position;
          final angle = tangent.vector.direction;

          _drawNavArrow(canvas, p, angle);

          canvas.drawCircle(p, 11, Paint()..color = primary.withOpacity(0.2));
          canvas.drawCircle(p, 5, Paint()..color = primary);
          canvas.drawCircle(
            p,
            5,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }
    }
  }

  void _drawNavArrow(Canvas canvas, Offset center, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final arrow = Path()
      ..moveTo(14, 0)
      ..lineTo(8, -4)
      ..lineTo(8, 4)
      ..close();

    canvas.drawPath(
      arrow,
      Paint()
        ..color = primary.withOpacity(0.35)
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  void _drawCities(Canvas canvas, Size size) {
    final cities = _cities(size);

    for (final city in cities) {
      _drawCityDot(canvas, city, progress >= city.threshold);
    }

    for (final city in cities) {
      if (progress >= city.threshold) {
        _drawCityLabel(canvas, city);
      }
    }
  }

  void _drawCityDot(Canvas canvas, _CityPoint city, bool active) {
    if (active) {
      canvas.drawRect(
        Rect.fromCenter(center: city.offset, width: 18, height: 18),
        Paint()
          ..color = primary.withOpacity(0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    final outer = Paint()
      ..color = active ? primary.withOpacity(0.18) : muted.withOpacity(0.45)
      ..style = PaintingStyle.fill;

    final inner = Paint()
      ..color = active ? primary : Colors.white
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = active ? primary : muted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(city.offset, active ? 7 : 6, outer);
    canvas.drawCircle(city.offset, 3.5, inner);
    canvas.drawCircle(city.offset, 3.5, border);
  }

  void _drawCityLabel(Canvas canvas, _CityPoint city) {
    const gap = 10.0;

    final tp = TextPainter(
      text: TextSpan(
        text: city.name,
        style: TextStyle(
          color: textColor.withOpacity(0.92),
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, _labelTopLeft(city, tp.size, gap));
  }

  Offset _labelTopLeft(_CityPoint city, Size textSize, double gap) {
    switch (city.labelSide) {
      case _LabelSide.above:
        return Offset(
          city.offset.dx - textSize.width / 2,
          city.offset.dy - gap - textSize.height,
        );
      case _LabelSide.below:
        return Offset(
          city.offset.dx - textSize.width / 2,
          city.offset.dy + gap,
        );
      case _LabelSide.left:
        return Offset(
          city.offset.dx - gap - textSize.width,
          city.offset.dy - textSize.height / 2,
        );
      case _LabelSide.right:
        return Offset(
          city.offset.dx + gap,
          city.offset.dy - textSize.height / 2,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _GridRoutePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primary != primary ||
        oldDelegate.muted != muted ||
        oldDelegate.gridMajor != gridMajor ||
        oldDelegate.gridMinor != gridMinor ||
        oldDelegate.textColor != textColor;
  }
}

enum _LabelSide { above, below, left, right }

class _CityPoint {
  final String name;
  final Offset offset;
  final double threshold;
  final _LabelSide labelSide;

  _CityPoint(
    this.name,
    this.offset,
    this.threshold, {
    this.labelSide = _LabelSide.below,
  });
}
