import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class MeshViewer extends StatefulWidget {
  final String meshPath;
  final Function(String)? onError;

  const MeshViewer({
    super.key,
    required this.meshPath,
    this.onError,
  });

  @override
  State<MeshViewer> createState() => _MeshViewerState();
}

class _MeshViewerState extends State<MeshViewer> {
  late Scene _scene;
  Object? _meshObject;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  double _rotationY = 0.0;
  double _rotationX = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundGray,
            AppColors.backgroundWhite,
          ],
        ),
      ),
      child: Stack(
        children: [
          // 3D Cube widget
          if (!_hasError && !_isLoading)
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: _onPanUpdate,
                onDoubleTap: _resetView,
                child: Cube(
                  interactive: false,
                  onSceneCreated: _onSceneCreated,
                ),
              ),
            ),
          
          // Loading indicator
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading 3D Model...'),
                ],
              ),
            ),
          
          // Error state
          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to Load 3D Model',
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _retry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          
          // Control instructions overlay
          if (!_hasError && !_isLoading)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildControlInstruction(Icons.pan_tool, 'Drag to rotate'),
                    _buildControlInstruction(Icons.refresh, 'Double tap to reset'),
                  ],
                ),
              ),
            ),
          
          // Reset button
          if (!_hasError && !_isLoading)
            Positioned(
              top: 20,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                onPressed: _resetView,
                backgroundColor: AppColors.backgroundWhite.withValues(alpha: 0.9),
                child: Icon(
                  Icons.refresh,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlInstruction(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _rotationY += details.delta.dx * 0.01;
      _rotationX -= details.delta.dy * 0.01;
      
      // Clamp X rotation to prevent flipping
      _rotationX = _rotationX.clamp(-1.5, 1.5);
      
      if (_meshObject != null) {
        _meshObject!.rotation.y = _rotationY;
        _meshObject!.rotation.x = _rotationX;
        _meshObject!.updateTransform();
        _scene.update();
      }
    });
  }

  void _onSceneCreated(Scene scene) {
    _scene = scene;
    _setupScene();
    _loadMesh();
  }

  void _setupScene() {
    // Position camera
    _scene.camera.position.setFrom(Vector3(0, 0, 10));
//     _scene.camera.lookAt(Vector3.zero());  // TODO: Update for flutter_cube compatibility
    
    // Setup lighting
    _scene.light.position.setFrom(Vector3(10, 10, 10));
    _scene.light.setColor(
      AppColors.backgroundWhite,
      2.0,  // intensity
      0.8,  // ambient
      0.2,  // specular
    );
    
    // Set background
    _scene.camera.zoom = 1.0;
  }

  void _loadMesh() {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      _meshObject = Object(
        position: Vector3(0, -2, 0),
        scale: Vector3(15.0, 15.0, 15.0),
        rotation: Vector3(0, 0, 0),
        lighting: true,
        fileName: widget.meshPath,
        isAsset: false, // Since this is a file path
      );

      if (_meshObject != null) {
        _scene.world.add(_meshObject!);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error loading mesh: ${e.toString()}';
      });
      
      widget.onError?.call(e.toString());
    }
  }

  void _resetView() {
    setState(() {
      _rotationY = 0.0;
      _rotationX = 0.0;
      
      if (_meshObject != null) {
        _meshObject!.rotation.setFrom(Vector3.zero());
        _meshObject!.position.setFrom(Vector3(0, -2, 0));
        _meshObject!.scale.setFrom(Vector3(15.0, 15.0, 15.0));
        _meshObject!.updateTransform();
        _scene.update();
      }
      
      // Reset camera
      _scene.camera.position.setFrom(Vector3(0, 0, 10));
//       _scene.camera.lookAt(Vector3.zero());  // TODO: Update for flutter_cube compatibility
      _scene.camera.zoom = 1.0;
    });
  }

  void _retry() {
    _loadMesh();
  }
}

/// Alternative mesh viewer for when flutter_cube is not available
class FallbackMeshViewer extends StatelessWidget {
  final String meshPath;
  final Function(String)? onError;

  const FallbackMeshViewer({
    super.key,
    required this.meshPath,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundGray,
            AppColors.backgroundWhite,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.view_in_ar,
                    size: 80,
                    color: AppColors.primaryPurple,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '3D Body Model',
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Interactive 3D viewer\ncoming soon',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Model Path: ${meshPath.split('/').last}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}