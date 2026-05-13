import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
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
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
        _mapController.move(LatLng(_lat, _lng), 15.0);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/dashboard')),
        title: Text(_isEdit ? 'Edit Parking Space' : 'Add Parking Space', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: _isEdit ? [IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () async {
          await ref.read(firestoreServiceProvider).deleteSpace(widget.spaceId!);
          if (context.mounted) context.go('/dashboard');
        })] : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Loading Overlay
          if (_isUploading) const LinearProgressIndicator(),
          _label('Space Name'),
          TextFormField(controller: _nameC, decoration: const InputDecoration(hintText: 'e.g. MG Road Parking Lot'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
          const SizedBox(height: 16),
          _label('Location'),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_lat, _lng),
                      initialZoom: 15.0,
                      onTap: (tapPos, point) {
                        setState(() {
                          _lat = point.latitude;
                          _lng = point.longitude;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_lat, _lng),
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                    Positioned(
                    right: 8,
                    top: 8,
                    child: FloatingActionButton.small(
                      heroTag: 'curr_loc',
                      onPressed: _fetchCurrentLocation,
                      child: const Icon(Icons.my_location, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap on map to set exact location',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Total Spaces'),
              TextFormField(controller: _totalC, keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '20'),
                validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter a number' : null),
            ])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Price / Hour (₹)'),
              TextFormField(controller: _priceC, keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '30'),
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter price' : null),
            ])),
          ]),
          const SizedBox(height: 20),
          _label('Vehicle Type'),
          const SizedBox(height: 8),
          SegmentedButton<SpaceType>(
            segments: const [
              ButtonSegment(value: SpaceType.bike, icon: Icon(Icons.two_wheeler), label: Text('Bike')),
              ButtonSegment(value: SpaceType.car, icon: Icon(Icons.directions_car), label: Text('Car')),
              ButtonSegment(value: SpaceType.mixed, icon: Icon(Icons.commute), label: Text('Mixed')),
            ],
            selected: {_spaceType},
            onSelectionChanged: (s) => setState(() => _spaceType = s.first),
            style: ButtonStyle(backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? theme.colorScheme.primary.withValues(alpha: 0.2) : Colors.transparent)),
          ),
          const SizedBox(height: 20),
          _label('Amenities'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _amenityChip('EV Charging', Icons.ev_station, _hasEv, (v) => setState(() => _hasEv = v)),
            _amenityChip('CCTV', Icons.videocam, _hasCctv, (v) => setState(() => _hasCctv = v)),
            _amenityChip('Security', Icons.security, _hasSecurity, (v) => setState(() => _hasSecurity = v)),
            _amenityChip('Lighting', Icons.light, _hasLighting, (v) => setState(() => _hasLighting = v)),
            _amenityChip('Covered', Icons.roofing, _isCovered, (v) => setState(() => _isCovered = v)),
          ]),
          const SizedBox(height: 20),
          SwitchListTile(title: const Text('Open 24/7'), value: _is24x7, activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.5),
            onChanged: (v) => setState(() => _is24x7 = v),
            contentPadding: EdgeInsets.zero),
          const SizedBox(height: 16),
          
          _label('Photos'),
          const SizedBox(height: 8),
          SizedBox(height: 100, child: ListView(scrollDirection: Axis.horizontal, children: [
            ..._existingPhotos.map((p) => Container(margin: const EdgeInsets.only(right: 8), width: 100,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(p.url), fit: BoxFit.cover)))),
            ..._selectedFiles.map((f) => Container(margin: const EdgeInsets.only(right: 8), width: 100,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: FileImage(File(f.path)), fit: BoxFit.cover)))),
            GestureDetector(onTap: _pickImage, child: Container(width: 100, decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[700]!, style: BorderStyle.solid), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Icon(Icons.add_a_photo_outlined, color: Colors.grey[600], size: 32)))),
          ])),
          
          const SizedBox(height: 32),
          ElevatedButton(onPressed: _isUploading ? null : _save, 
            child: _isUploading ? const CircularProgressIndicator() : Text(_isEdit ? 'UPDATE SPACE' : 'ADD SPACE')),
          const SizedBox(height: 24),
        ])),
      ),
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[400], fontSize: 13)));

  Widget _amenityChip(String label, IconData icon, bool selected, ValueChanged<bool> onChanged) {
    final theme = Theme.of(context);
    return FilterChip(label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)]),
      selected: selected, onSelected: onChanged,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: theme.colorScheme.primary);
  }
}
