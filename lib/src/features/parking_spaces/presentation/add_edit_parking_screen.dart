import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../common_widgets/glass_container.dart';
import '../../../models/parking_space.dart';
import '../../../services/storage_service.dart';
import '../../dashboard/data/dashboard_providers.dart';

class AddEditParkingScreen extends ConsumerStatefulWidget {
  final String? spaceId;
  const AddEditParkingScreen({super.key, this.spaceId});
  @override
  ConsumerState<AddEditParkingScreen> createState() => _AddEditParkingScreenState();
}

class _AddEditParkingScreenState extends ConsumerState<AddEditParkingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _totalC = TextEditingController();
  final _priceC = TextEditingController();
  double _lat = 12.9716;
  double _lng = 77.5946;
  final _mapController = MapController();

  final _picker = ImagePicker();
  final _storage = StorageService();
  final List<XFile> _selectedFiles = [];
  final List<ParkingSpacePhoto> _existingPhotos = [];
  bool _isUploading = false;

  SpaceType _spaceType = SpaceType.mixed;
  bool _hasEv = false, _hasCctv = false, _hasSecurity = false, _hasLighting = false, _isCovered = false, _is24x7 = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.spaceId != null) {
      _isEdit = true;
      final spacesAsync = ref.read(parkingSpacesProvider);
      final spaces = spacesAsync.value ?? [];
      final space = spaces.firstWhere((s) => s.id == widget.spaceId,
          orElse: () => ParkingSpace(
              id: '',
              name: '',
              address: '',
              latitude: 0,
              longitude: 0,
              createdAt: DateTime.now()));
      _nameC.text = space.name;
      _lat = space.latitude;
      _lng = space.longitude;
      _totalC.text = space.totalSpaces.toString();
      _priceC.text = space.pricePerHour.toString();
      _spaceType = space.spaceType;
      _hasEv = space.hasEvCharging;
      _hasCctv = space.hasCctv;
      _hasSecurity = space.hasSecurity;
      _hasLighting = space.hasLighting;
      _isCovered = space.isCovered;
      _is24x7 = space.is24x7;
      _existingPhotos.addAll(space.photos);
    } else {
      // Automatically fetch current location for new spaces
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchCurrentLocation();
      });
    }
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _snack('Location permissions are denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _snack('Location permissions are permanently denied');
        return;
      }

      _snack('Getting current location...');
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      if (mounted) {
        Future.microtask(() {
          if (mounted) {
            setState(() {
              _lat = pos.latitude;
              _lng = pos.longitude;
            });
            _mapController.move(LatLng(_lat, _lng), 15.0);
          }
        });
      }
    } catch (e) {
      _snack('Error getting location: $e', Colors.redAccent);
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _totalC.dispose();
    _priceC.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedFiles.add(image));
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUploading = true);

    try {
      final total = int.tryParse(_totalC.text) ?? 0;
      final price = double.tryParse(_priceC.text) ?? 0;
      final tempId = widget.spaceId ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Debug: Start photo upload
      if (_selectedFiles.isNotEmpty) {
        _snack('Uploading ${_selectedFiles.length} photos...');
      }

      // Upload new photos
      final List<ParkingSpacePhoto> uploadedPhotos = [];
      for (var file in _selectedFiles) {
        try {
          final bytes = await file.readAsBytes();
          final url = await _storage.uploadParkingPhotoData(tempId, bytes)
              .timeout(const Duration(seconds: 10), onTimeout: () => throw 'Timeout');
          
          if (url != null) {
            uploadedPhotos.add(ParkingSpacePhoto(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              url: url,
              type: 'SPACE',
            ));
          }
        } catch (e) {
          _snack('Warning: Photo upload failed ($e). Continuing without photos.', Colors.orange);
          // Don't throw, just continue with other photos or saving the space
        }
      }

      final space = ParkingSpace(
        id: widget.spaceId ?? tempId,
        name: _nameC.text.trim(),
        address: 'Lat: ${_lat.toStringAsFixed(4)}, Lng: ${_lng.toStringAsFixed(4)}',
        latitude: _lat,
        longitude: _lng,
        totalSpaces: total,
        availableSpaces: total,
        spaceType: _spaceType,
        pricePerHour: price,
        hasEvCharging: _hasEv,
        hasCctv: _hasCctv,
        hasSecurity: _hasSecurity,
        hasLighting: _hasLighting,
        isCovered: _isCovered,
        is24x7: _is24x7,
        photos: [..._existingPhotos, ...uploadedPhotos],
        createdAt: DateTime.now(),
      );

      // Debug: Start firestore write
      _snack('Saving space details...');
      final firestore = ref.read(firestoreServiceProvider);
      
      if (_isEdit) {
        await firestore.updateSpace(space).timeout(const Duration(seconds: 10), onTimeout: () => throw 'Update timed out');
      } else {
        await firestore.addSpace(space).timeout(const Duration(seconds: 10), onTimeout: () => throw 'Save timed out');
      }
      
      if (mounted) {
        setState(() => _isUploading = false);
        _snack('Space added successfully!', Colors.green);
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _snack('Error: $e', Colors.redAccent);
      }
    }
  }

  void _snack(String msg, [Color? color]) {
    if (mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: TextStyle(color: (color == null || color == theme.colorScheme.primary) ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: color ?? theme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned(top: -100, left: -50, child: _GlowBlob(color: theme.colorScheme.primary.withValues(alpha: 0.1))),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        IconButton(onPressed: () => context.go('/dashboard'), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
                        Text(_isEdit ? 'Edit Space' : 'Add Space', style: theme.textTheme.headlineSmall),
                        const Spacer(),
                        if (_isEdit)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () async {
                              await ref.read(firestoreServiceProvider).deleteSpace(widget.spaceId!);
                              if (context.mounted) context.go('/dashboard');
                            },
                          ),
                      ],
                    ),
                    if (_isUploading) const LinearProgressIndicator(),
                    const SizedBox(height: 32),
                    
                    _sectionHeader('Basic Information'),
                    const SizedBox(height: 16),
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 24,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameC,
                            decoration: const InputDecoration(hintText: 'Space Name (e.g. My Garage)'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _totalC,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: 'Total Spots'),
                                  validator: (v) => (v == null || int.tryParse(v) == null) ? 'Invalid' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _priceC,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: '₹ / Hour'),
                                  validator: (v) => (v == null || double.tryParse(v) == null) ? 'Invalid' : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    _sectionHeader('Location Selection'),
                    const SizedBox(height: 16),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: LatLng(_lat, _lng),
                                initialZoom: 15.0,
                                onTap: (tapPos, point) => setState(() { _lat = point.latitude; _lng = point.longitude; }),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.spotsy.captain.app',
                                ),
                                MarkerLayer(markers: [
                                  Marker(point: LatLng(_lat, _lng), width: 40, height: 40, 
                                    child: const Icon(Icons.location_on_rounded, color: Colors.orange, size: 40)),
                                ]),
                              ],
                            ),
                            Positioned(right: 12, top: 12, child: FloatingActionButton.small(
                              heroTag: null, onPressed: _fetchCurrentLocation, backgroundColor: Colors.black, child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _sectionHeader('Vehicle Type'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _typeChip('Bike', Icons.two_wheeler_rounded, SpaceType.bike),
                        const SizedBox(width: 8),
                        _typeChip('Small Car', Icons.directions_car_rounded, SpaceType.carSmall),
                        const SizedBox(width: 8),
                        _typeChip('Big Car', Icons.airport_shuttle_rounded, SpaceType.carLarge),
                        const SizedBox(width: 8),
                        _typeChip('Mixed', Icons.commute_rounded, SpaceType.mixed),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    _sectionHeader('Amenities'),
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _amenityChip('EV Charging', Icons.ev_station_rounded, _hasEv, (v) => setState(() => _hasEv = v)),
                      _amenityChip('CCTV', Icons.videocam_rounded, _hasCctv, (v) => setState(() => _hasCctv = v)),
                      _amenityChip('Security', Icons.security_rounded, _hasSecurity, (v) => setState(() => _hasSecurity = v)),
                      _amenityChip('Covered', Icons.roofing_rounded, _isCovered, (v) => setState(() => _isCovered = v)),
                      _amenityChip('24/7', Icons.access_time_filled_rounded, _is24x7, (v) => setState(() => _is24x7 = v)),
                    ]),
                    const SizedBox(height: 32),
                    
                    _sectionHeader('Photos'),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._existingPhotos.map((p) => _photoFrame(Image.network(p.url, fit: BoxFit.cover))),
                          ..._selectedFiles.map((f) => _photoFrame(Image.file(File(f.path), fit: BoxFit.cover))),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                              child: const Icon(Icons.add_a_photo_rounded, color: Colors.white24, size: 32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: _isUploading ? null : _save,
                      child: _isUploading ? const CircularProgressIndicator(color: Colors.black) : Text(_isEdit ? 'Save Changes' : 'Add Parking Space'),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(title.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2));

  Widget _photoFrame(Widget child) => Container(margin: const EdgeInsets.only(right: 12), width: 100, child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child));

  Widget _amenityChip(String label, IconData icon, bool selected, ValueChanged<bool> onChanged) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white70, fontSize: 12)),
      avatar: Icon(icon, size: 16, color: selected ? Colors.black : Colors.white70),
      selected: selected,
      onSelected: onChanged,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _typeChip(String label, IconData icon, SpaceType type) {
    final theme = Theme.of(context);
    final selected = _spaceType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _spaceType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? Colors.black : Colors.white70),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: TextStyle(color: selected ? Colors.black : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  const _GlowBlob({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.transparent)));
  }
}
