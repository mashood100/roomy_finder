import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';

class FlutterGoogleMapScreen extends StatefulWidget {
  const FlutterGoogleMapScreen({
    super.key,
    this.initialPosition,
    this.onCameraMove,
    this.onSetMarkerButtonPressed,
  });

  final CameraPosition? initialPosition;
  final void Function(CameraPosition position)? onCameraMove;
  final void Function(LatLng latLng)? onSetMarkerButtonPressed;

  @override
  State<FlutterGoogleMapScreen> createState() => _FlutterGoogleMapScreenState();
}

class _FlutterGoogleMapScreenState extends State<FlutterGoogleMapScreen> {
  @override
  void initState() {
    _askPermission();
    _getUserLocation();
    super.initState();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        showConfirmDialog(
          "Location is disabled."
          " Please activate GPRS to get your current position",
        );
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> _askPermission() async {
    try {
      final locationStatus = await Permission.location.status;
      final locationAlwaysStatus = await Permission.locationAlways.status;
      final locationWhenInUseStatus = await Permission.locationWhenInUse.status;

      if (locationStatus.isGranted &&
          locationAlwaysStatus.isGranted &&
          locationWhenInUseStatus.isGranted) {
        return;
      } else {
        final shouldOpenSettings = await showConfirmDialog(
          "Location permission is denied."
          " Please grant acces for Roomy Finder to work efficiently",
        );

        if (shouldOpenSettings == true) {
          await Permission.location.request();
          await Permission.locationAlways.request();
          await Permission.locationWhenInUse.request();
          setState(() {});
          return;
        }
      }

      if (locationStatus.isPermanentlyDenied &&
          locationAlwaysStatus.isPermanentlyDenied &&
          locationWhenInUseStatus.isPermanentlyDenied) {
        final shouldOpenSettings =
            await showConfirmDialog("Location permission is permanently denied."
                " Would you open settings to grant permission?");

        if (shouldOpenSettings == true) {
          await openAppSettings();
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  final Completer<GoogleMapController> _controller = Completer();

  final Set<Marker> _markers = {};

  MapType _currentMapType = MapType.normal;
  bool _showMyLocation = false;
  CameraPosition? _curentPosition;

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  void _onSetMarkerButtonPressed(LatLng latLng) {
    if (widget.onSetMarkerButtonPressed != null) {
      widget.onSetMarkerButtonPressed!(latLng);
    }
    _markers.clear();
    setState(() {
      _markers.add(Marker(
        // This marker id can be anything that uniquely identifies each marker.
        markerId: MarkerId(latLng.toString()),
        position: latLng,
        infoWindow: const InfoWindow(title: 'Here'),
        icon: BitmapDescriptor.defaultMarker,
      ));
      if (_curentPosition != null) {
        _curentPosition = CameraPosition(
          target: latLng,
          bearing: _curentPosition!.bearing,
          tilt: _curentPosition!.tilt,
          zoom: _curentPosition!.zoom,
        );
      }
    });
  }

  void _onCameraMove(CameraPosition position) {
    if (widget.onCameraMove != null) widget.onCameraMove!(position);
    _curentPosition = position;
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    setState(() {
      _showMyLocation = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose ad location'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop(_curentPosition);
            },
            // backgroundColor: Colors.transparent,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          GoogleMap(
            mapToolbarEnabled: true,
            onMapCreated: _onMapCreated,
            initialCameraPosition: widget.initialPosition ??
                const CameraPosition(
                  target: LatLng(45.521563, -122.677433),
                  zoom: 11.0,
                ),
            mapType: _currentMapType,
            markers: _markers,
            onCameraMove: _onCameraMove,
            myLocationButtonEnabled: _showMyLocation,
            myLocationEnabled: true,
            onLongPress: _onSetMarkerButtonPressed,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  onPressed: _onMapTypeButtonPressed,
                  // backgroundColor: Colors.transparent,
                  icon: Icon(
                    Icons.map,
                    size: 36.0,
                    color: Theme.of(context).appBarTheme.backgroundColor,
                  ),
                ),
                // const SizedBox(height: 16.0),
                // FloatingActionButton(
                //   onPressed: _onAddMarkerButtonPressed,
                //   materialTapTargetSize: MaterialTapTargetSize.padded,
                //   backgroundColor: Colors.green,
                //   child: const Icon(Icons.add_location, size: 36.0),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
