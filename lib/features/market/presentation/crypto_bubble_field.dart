import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/crypto_market_repository.dart';

/// Animated bubble field backed by live crypto assets.
///
/// Bubble size follows the absolute 24h percentage move. Movement is
/// deliberately slow, and collisions use an elastic impulse so touching
/// bubbles bounce apart.
class CryptoBubbleField extends StatefulWidget {
  const CryptoBubbleField({
    super.key,
    required this.assets,
    required this.minRadius,
    required this.maxRadius,
    this.padding = 8,
    this.speed = 9,
    this.onBubbleTap,
  });

  final List<CryptoAsset> assets;
  final double minRadius;
  final double maxRadius;
  final double padding;
  final double speed;
  final ValueChanged<CryptoAsset>? onBubbleTap;

  @override
  State<CryptoBubbleField> createState() => _CryptoBubbleFieldState();
}

class _CryptoBubbleFieldState extends State<CryptoBubbleField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_BubbleBody> _bodies = [];
  Duration? _previousElapsed;
  Size _fieldSize = Size.zero;
  String _assetSignature = '';

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didUpdateWidget(covariant CryptoBubbleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameAssets(oldWidget.assets, widget.assets)) {
      _assetSignature = '';
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  bool _sameAssets(List<CryptoAsset> left, List<CryptoAsset> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index].symbol != right[index].symbol ||
          left[index].quoteVolume != right[index].quoteVolume ||
          left[index].changePercent != right[index].changePercent) {
        return false;
      }
    }
    return true;
  }

  void _tick(Duration elapsed) {
    final previous = _previousElapsed;
    _previousElapsed = elapsed;
    if (previous == null || _bodies.isEmpty || _fieldSize.isEmpty) return;

    final rawSeconds = (elapsed - previous).inMicroseconds / 1000000;
    final seconds = rawSeconds.clamp(0.0, 1 / 30);
    _advance(seconds);
    if (mounted) setState(() {});
  }

  void _advance(double seconds) {
    final left = widget.padding;
    final top = widget.padding;
    final right = _fieldSize.width - widget.padding;
    final bottom = _fieldSize.height - widget.padding;

    for (final body in _bodies) {
      var position = body.position + body.velocity * seconds;
      var velocity = body.velocity;

      if (position.dx - body.radius < left) {
        position = Offset(left + body.radius, position.dy);
        velocity = Offset(velocity.dx.abs(), velocity.dy);
      } else if (position.dx + body.radius > right) {
        position = Offset(right - body.radius, position.dy);
        velocity = Offset(-velocity.dx.abs(), velocity.dy);
      }
      if (position.dy - body.radius < top) {
        position = Offset(position.dx, top + body.radius);
        velocity = Offset(velocity.dx, velocity.dy.abs());
      } else if (position.dy + body.radius > bottom) {
        position = Offset(position.dx, bottom - body.radius);
        velocity = Offset(velocity.dx, -velocity.dy.abs());
      }

      body
        ..position = position
        ..velocity = velocity;
    }

    for (var first = 0; first < _bodies.length; first++) {
      for (var second = first + 1; second < _bodies.length; second++) {
        _resolveCollision(_bodies[first], _bodies[second]);
      }
    }

    // Collision separation can move an edge bubble by a few pixels. Clamp
    // once more so no bubble can escape the visible device-sized canvas.
    for (final body in _bodies) {
      body.position = _clampPosition(body.position, body.radius, _fieldSize);
    }
  }

  void _resolveCollision(_BubbleBody first, _BubbleBody second) {
    var delta = second.position - first.position;
    var distance = delta.distance;
    final minimumDistance = first.radius + second.radius + 1.5;
    if (distance >= minimumDistance) return;

    if (distance < .001) {
      delta = const Offset(1, 0);
      distance = 1;
    }
    final normal = delta / distance;
    final overlap = minimumDistance - distance;
    final totalMass = first.mass + second.mass;

    first.position -= normal * (overlap * second.mass / totalMass);
    second.position += normal * (overlap * first.mass / totalMass);

    final relativeVelocity = second.velocity - first.velocity;
    final velocityOnNormal =
        relativeVelocity.dx * normal.dx + relativeVelocity.dy * normal.dy;
    if (velocityOnNormal >= 0) return;

    const restitution = .94;
    final impulse =
        -(1 + restitution) *
        velocityOnNormal /
        ((1 / first.mass) + (1 / second.mass));
    final impulseVector = normal * impulse;
    first.velocity -= impulseVector / first.mass;
    second.velocity += impulseVector / second.mass;

    first.velocity = _limitedVelocity(first.velocity, first.seed);
    second.velocity = _limitedVelocity(second.velocity, second.seed);
  }

  Offset _limitedVelocity(Offset velocity, int seed) {
    final magnitude = velocity.distance;
    final minimum = widget.speed * .52;
    final maximum = widget.speed * 1.65;
    if (magnitude < .001) {
      final angle = (seed % 628) / 100;
      return Offset(math.cos(angle), math.sin(angle)) * minimum;
    }
    if (magnitude < minimum) return velocity / magnitude * minimum;
    if (magnitude > maximum) return velocity / magnitude * maximum;
    return velocity;
  }

  void _ensureSimulation(Size size) {
    final signature = widget.assets
        .map(
          (asset) =>
              '${asset.symbol}:${asset.quoteVolume}:${asset.changePercent}',
        )
        .join('|');
    if (_fieldSize == size && _assetSignature == signature) return;

    _fieldSize = size;
    _assetSignature = signature;
    _reconcileBodies(size);
  }

  void _reconcileBodies(Size size) {
    if (widget.assets.isEmpty || size.isEmpty) {
      _bodies.clear();
      return;
    }

    final previousByMarket = {
      for (final body in _bodies) _bodyKey(body.asset): body,
    };
    // Place the largest movers first so the packing algorithm reserves enough
    // room for them and fills the remaining gaps with smaller movers.
    final sorted = [...widget.assets]
      ..sort(
        (left, right) =>
            _changeMagnitude(right).compareTo(_changeMagnitude(left)),
      );
    final changeMagnitudes = sorted.map(_changeMagnitude).toList();
    final minimumChange = changeMagnitudes.reduce(math.min);
    final maximumChange = changeMagnitudes.reduce(math.max);
    final next = <_BubbleBody>[];

    for (var index = 0; index < sorted.length; index++) {
      final asset = sorted[index];
      final radius = _radiusFor(asset, minimumChange, maximumChange, size);
      final existing = previousByMarket.remove(_bodyKey(asset));
      if (existing != null) {
        existing
          ..asset = asset
          ..radius = radius
          ..position = _clampPosition(existing.position, radius, size)
          ..velocity = _limitedVelocity(existing.velocity, existing.seed);
        next.add(existing);
        continue;
      }
      next.add(_createBody(asset, radius, size, next, index));
    }

    _bodies
      ..clear()
      ..addAll(next);
  }

  double _changeMagnitude(CryptoAsset asset) {
    final magnitude = asset.changePercent.abs();
    return magnitude.isFinite ? magnitude : 0;
  }

  double _radiusFor(
    CryptoAsset asset,
    double minimumChange,
    double maximumChange,
    Size size,
  ) {
    final minimumScale = math.log(1 + minimumChange);
    final maximumScale = math.log(1 + maximumChange);
    final scaleRange = maximumScale - minimumScale;
    final changeRatio = scaleRange <= .000001
        ? .5
        : ((math.log(1 + _changeMagnitude(asset)) - minimumScale) / scaleRange)
              .clamp(0.0, 1.0);
    final requestedRadius =
        widget.minRadius + changeRatio * (widget.maxRadius - widget.minRadius);
    final fieldLimit = math.max(
      10.0,
      math.min(size.width, size.height) / 2 - widget.padding - 1,
    );
    return requestedRadius.clamp(10.0, fieldLimit);
  }

  _BubbleBody _createBody(
    CryptoAsset asset,
    double radius,
    Size size,
    List<_BubbleBody> placed,
    int index,
  ) {
    final seed = _seedFor(asset);
    final random = math.Random(seed);
    Offset? position;

    for (var attempt = 0; attempt < 1200; attempt++) {
      final candidate = Offset(
        widget.padding +
            radius +
            random.nextDouble() *
                math.max(1, size.width - (widget.padding + radius) * 2),
        widget.padding +
            radius +
            random.nextDouble() *
                math.max(1, size.height - (widget.padding + radius) * 2),
      );
      final clear = placed.every(
        (body) =>
            (body.position - candidate).distance > body.radius + radius + 3,
      );
      if (clear) {
        position = candidate;
        break;
      }
    }

    position ??= Offset(
      widget.padding + radius + (index % 5) * (radius * 1.55),
      widget.padding + radius + (index ~/ 5) * (radius * 1.55),
    );
    position = _clampPosition(position, radius, size);

    final angle = random.nextDouble() * math.pi * 2;
    final speed = widget.speed * (.72 + random.nextDouble() * .48);
    return _BubbleBody(
      asset: asset,
      radius: radius,
      position: position,
      velocity: Offset(math.cos(angle), math.sin(angle)) * speed,
      seed: seed,
    );
  }

  Offset _clampPosition(Offset position, double radius, Size size) => Offset(
    position.dx.clamp(
      widget.padding + radius,
      size.width - widget.padding - radius,
    ),
    position.dy.clamp(
      widget.padding + radius,
      size.height - widget.padding - radius,
    ),
  );

  int _seedFor(CryptoAsset asset) =>
      _bodyKey(asset).codeUnits
          .fold<int>(31, (value, unit) => ((value * 37) + unit) & 0x7fffffff);

  String _bodyKey(CryptoAsset asset) => '${asset.segment}:${asset.symbol}';

  void _handleTap(TapUpDetails details) {
    final tap = details.localPosition;
    for (final body in _bodies.reversed) {
      if ((body.position - tap).distance <= body.radius) {
        widget.onBubbleTap?.call(body.asset);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      _ensureSimulation(size);
      return RepaintBoundary(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _handleTap,
          child: CustomPaint(size: size, painter: _BubblePainter(_bodies)),
        ),
      );
    },
  );
}

class _BubbleBody {
  _BubbleBody({
    required this.asset,
    required this.radius,
    required this.position,
    required this.velocity,
    required this.seed,
  });

  CryptoAsset asset;
  double radius;
  final int seed;
  Offset position;
  Offset velocity;

  double get mass => radius * radius;
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter(this.bodies);

  final List<_BubbleBody> bodies;

  @override
  void paint(Canvas canvas, Size size) {
    for (final body in bodies) {
      _paintBubble(canvas, body);
    }
  }

  void _paintBubble(Canvas canvas, _BubbleBody body) {
    final accent = body.asset.changePercent > .05
        ? const Color(0xFF20D889)
        : body.asset.changePercent < -.05
        ? const Color(0xFFFF535D)
        : const Color(0xFF8491A3);
    final circle = Rect.fromCircle(center: body.position, radius: body.radius);

    canvas.drawCircle(
      body.position + const Offset(0, 5),
      body.radius * .94,
      Paint()
        ..color = Colors.black.withValues(alpha: .46)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawCircle(
      body.position,
      body.radius + 1,
      Paint()
        ..color = accent.withValues(alpha: .26)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      body.position,
      body.radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.38, -.42),
          radius: 1.12,
          colors: [
            Color.lerp(Colors.white, accent, .22)!.withValues(alpha: .98),
            accent.withValues(alpha: .92),
            accent.withValues(alpha: .48),
            const Color(0xFF0C1420).withValues(alpha: .98),
          ],
          stops: const [0, .18, .62, 1],
        ).createShader(circle),
    );
    canvas.drawCircle(
      body.position,
      body.radius - .8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = accent.withValues(alpha: .9),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: body.position + Offset(-body.radius * .27, -body.radius * .32),
        width: body.radius * .66,
        height: body.radius * .28,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: .32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final symbol = body.asset.baseCurrency.isEmpty
        ? body.asset.fallbackLabel
        : body.asset.baseCurrency;
    final labelSize = math.max(9.0, math.min(17.0, body.radius * .34));
    final changeSize = math.max(8.0, math.min(13.0, body.radius * .23));
    final symbolPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          color: Colors.white,
          fontSize: labelSize,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(color: Colors.black, blurRadius: 5)],
        ),
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: body.radius * 1.48);
    final changePainter = TextPainter(
      text: TextSpan(
        text:
            '${body.asset.changePercent >= 0 ? '+' : ''}${body.asset.changePercent.toStringAsFixed(2)}%',
        style: TextStyle(
          color: Colors.white,
          fontSize: changeSize,
          fontWeight: FontWeight.w800,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: body.radius * 1.62);
    final totalHeight = symbolPainter.height + changePainter.height + 1;
    symbolPainter.paint(
      canvas,
      Offset(
        body.position.dx - symbolPainter.width / 2,
        body.position.dy - totalHeight / 2,
      ),
    );
    changePainter.paint(
      canvas,
      Offset(
        body.position.dx - changePainter.width / 2,
        body.position.dy - totalHeight / 2 + symbolPainter.height + 1,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => true;
}
