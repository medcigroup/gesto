// components/tutorial/tutorial_overlay.dart
import 'package:flutter/material.dart';
import 'package:gesto/config/AuthService.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/tutorial_step.dart';
import '../../services/tutorial_service.dart';

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final String tutorialId;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final bool showSkipButton;
  final bool showProgress;
  final Function(int pageIndex)? onNavigateToPage;

  const TutorialOverlay({
    Key? key,
    required this.steps,
    required this.tutorialId,
    this.onComplete,
    this.onSkip,
    this.showSkipButton = true,
    this.showProgress = true,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  _TutorialOverlayState createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStep = 0;
  bool _isLoading = false;
  late TutorialService _tutorialService;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUser();
      _userId = user?.email ?? 'anonymous';

      final prefs = await SharedPreferences.getInstance();
      _tutorialService = TutorialService(prefs);

      // Charger les étapes déjà complétées
      final completedSteps = await _tutorialService.getCompletedSteps(_userId, widget.tutorialId);

      // Trouver la première étape non complétée
      for (int i = 0; i < widget.steps.length; i++) {
        if (!completedSteps.contains(widget.steps[i].id)) {
          setState(() {
            _currentStep = i;
          });
          // Naviguer vers la page correspondante
          if (widget.steps[i].pageIndex != null && widget.onNavigateToPage != null) {
            widget.onNavigateToPage!(widget.steps[i].pageIndex!);
          }
          break;
        }
      }
    } catch (e) {
      print('Erreur chargement données utilisateur: $e');
    }
  }

  Future<void> _completeCurrentStep() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentStep = widget.steps[_currentStep];
      await _tutorialService.completeStep(_userId, widget.tutorialId, currentStep.id);

      if (_currentStep < widget.steps.length - 1) {
        setState(() {
          _currentStep++;
          _isLoading = false;
        });
        // Naviguer vers la page de la nouvelle étape
        final nextStep = widget.steps[_currentStep];
        if (nextStep.pageIndex != null && widget.onNavigateToPage != null) {
          widget.onNavigateToPage!(nextStep.pageIndex!);
        }
      } else {
        // Dernière étape
        await _tutorialService.completeTutorial(_userId, widget.tutorialId);
        setState(() {
          _isLoading = false;
        });
        widget.onComplete?.call();
      }
    } catch (e) {
      print('Erreur complétion étape: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _skipTutorial() {
    widget.onSkip?.call();
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      // Naviguer vers la page de l'étape précédente
      final prevStep = widget.steps[_currentStep];
      if (prevStep.pageIndex != null && widget.onNavigateToPage != null) {
        widget.onNavigateToPage!(prevStep.pageIndex!);
      }
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.steps.asMap().entries.map((entry) {
        final index = entry.key;
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentStep == index
                ? Theme.of(context).primaryColor
                : Colors.grey[300],
            border: Border.all(
              color: _currentStep == index
                  ? Theme.of(context).primaryColor
                  : Colors.grey[400]!,
              width: 2,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTooltip(TutorialStep step) {
    final screenSize = MediaQuery.of(context).size;
    final tooltipWidth = screenSize.width > 600 ? 500.0 : screenSize.width * 0.85;
    
    return Container(
      width: tooltipWidth,
      constraints: BoxConstraints(
        maxHeight: screenSize.height * 0.75,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step.icon != null) ...[
            Center(
              child: Text(
                step.icon!,
                style: const TextStyle(fontSize: 48),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text(
            step.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            step.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
            ),
          ),

          if (step.actions != null && step.actions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: step.actions!.map((action) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      action,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
              ),
            ),
          ],

          const SizedBox(height: 20),

          Row(
            children: [
              if (widget.showProgress) ...[
                Expanded(
                  child: _buildStepIndicator(),
                ),
                const SizedBox(width: 16),
              ],

              if (widget.showSkipButton && _currentStep > 0)
                TextButton(
                  onPressed: _previousStep,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Précédent', style: TextStyle(fontSize: 16)),
                ),

              if (widget.showSkipButton && _currentStep == 0)
                TextButton(
                  onPressed: _skipTutorial,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Passer', style: TextStyle(fontSize: 16)),
                ),

              const SizedBox(width: 8),

              ElevatedButton(
                onPressed: _completeCurrentStep,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _currentStep == widget.steps.length - 1 ? 'Terminer' : 'Suivant',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final currentStep = widget.steps[_currentStep];

    if (currentStep.targetKey == null && currentStep.targetWidget == null) {
      // Tutoriel centré (pour l'introduction)
      return Stack(
        children: [
          ModalBarrier(
            color: Colors.black.withOpacity(0.5),
            dismissible: false,
          ),
          Center(
            child: _buildTooltip(currentStep),
          ),
        ],
      );
    }

    // Tutoriel avec cible spécifique
    return Stack(
      children: [
        // Overlay semi-transparent
        ModalBarrier(
          color: Colors.black.withOpacity(0.5),
          dismissible: false,
        ),

        // Cible mise en évidence
        if (currentStep.targetKey != null)
          Positioned.fill(
            child: CustomPaint(
              painter: _HighlightPainter(
                targetKey: currentStep.targetKey!,
                context: context,
                radius: 8,
                color: Colors.white.withOpacity(0.1),
                borderColor: Theme.of(context).primaryColor.withOpacity(0.8),
              ),
            ),
          ),

        // Tooltip positionné
        Positioned(
          top: _getTooltipTop(currentStep.position),
          left: _getTooltipLeft(currentStep.position),
          child: _buildTooltip(currentStep),
        ),
      ],
    );
  }

  double _getTooltipTop(TutorialPosition position) {
    final height = MediaQuery.of(context).size.height;
    switch (position) {
      case TutorialPosition.top:
        return 100;
      case TutorialPosition.bottom:
        return height - 250;
      case TutorialPosition.center:
        return height / 2 - 150;
      default:
        return height / 2 - 150;
    }
  }

  double _getTooltipLeft(TutorialPosition position) {
    final width = MediaQuery.of(context).size.width;
    switch (position) {
      case TutorialPosition.left:
        return 50;
      case TutorialPosition.right:
        return width - 350;
      case TutorialPosition.center:
        return width / 2 - 150;
      default:
        return width / 2 - 150;
    }
  }
}

class _HighlightPainter extends CustomPainter {
  final GlobalKey targetKey;
  final BuildContext context;
  final double radius;
  final Color color;
  final Color borderColor;

  _HighlightPainter({
    required this.targetKey,
    required this.context,
    this.radius = 8,
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final RenderBox? targetBox = targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (targetBox == null) return;

    final Offset targetPosition = targetBox.localToGlobal(Offset.zero);
    final Size targetSize = targetBox.size;

    final Rect targetRect = Rect.fromLTWH(
      targetPosition.dx,
      targetPosition.dy,
      targetSize.width,
      targetSize.height,
    );

    // Remplir tout l'écran
    final backgroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Découper la zone cible
    final clipPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(targetRect, Radius.circular(radius)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(clipPath, backgroundPaint);

    // Bordure autour de la cible
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        targetRect.inflate(2),
        Radius.circular(radius + 2),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}