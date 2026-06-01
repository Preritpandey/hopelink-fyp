import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

class LocationMapPicker extends StatefulWidget {
  const LocationMapPicker({
    super.key,
    required this.latCtrl,
    required this.lngCtrl,
    required this.accentColor,
    required this.markerColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedTextColor,
    this.title = 'Map Location',
    this.buttonLabel = 'Select on map',
    this.updateButtonLabel = 'Update map location',
    this.fallbackPoint = const LatLng(27.7172, 85.3240),
    this.previewHeight = 180,
  });

  final TextEditingController latCtrl;
  final TextEditingController lngCtrl;
  final Color accentColor;
  final Color markerColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedTextColor;
  final String title;
  final String buttonLabel;
  final String updateButtonLabel;
  final LatLng fallbackPoint;
  final double previewHeight;

  @override
  State<LocationMapPicker> createState() => _LocationMapPickerState();
}

class _LocationMapPickerState extends State<LocationMapPicker> {
  @override
  void initState() {
    super.initState();
    widget.latCtrl.addListener(_refresh);
    widget.lngCtrl.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.latCtrl.removeListener(_refresh);
    widget.lngCtrl.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _hasPoint =>
      double.tryParse(widget.latCtrl.text.trim()) != null &&
      double.tryParse(widget.lngCtrl.text.trim()) != null;

  LatLng get _currentPoint {
    if (!_hasPoint) return widget.fallbackPoint;
    return LatLng(
      double.parse(widget.latCtrl.text.trim()),
      double.parse(widget.lngCtrl.text.trim()),
    );
  }

  Future<void> _pickLocation() async {
    final picked = await showDialog<LatLng>(
      context: context,
      builder: (context) => _LocationMapDialog(
        initialPoint: _currentPoint,
        title: widget.title,
        accentColor: widget.accentColor,
        markerColor: widget.markerColor,
        surfaceColor: widget.surfaceColor,
        borderColor: widget.borderColor,
        textColor: widget.textColor,
        mutedTextColor: widget.mutedTextColor,
      ),
    );

    if (picked == null) return;
    widget.latCtrl.text = picked.latitude.toStringAsFixed(6);
    widget.lngCtrl.text = picked.longitude.toStringAsFixed(6);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.dmSans(
                    color: widget.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _pickLocation,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(
                  _hasPoint ? widget.updateButtonLabel : widget.buttonLabel,
                ),
              ),
            ],
          ),
          if (_hasPoint) ...[
            const SizedBox(height: 12),
            _LocationMapPreview(
              point: _currentPoint,
              height: widget.previewHeight,
              markerColor: widget.markerColor,
            ),
            const SizedBox(height: 8),
            Text(
              'Lat ${_currentPoint.latitude.toStringAsFixed(6)} | Lng ${_currentPoint.longitude.toStringAsFixed(6)}',
              style: GoogleFonts.dmMono(
                color: widget.mutedTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationMapPreview extends StatelessWidget {
  const _LocationMapPreview({
    required this.point,
    required this.height,
    required this.markerColor,
  });

  final LatLng point;
  final double height;
  final Color markerColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(initialCenter: point, initialZoom: 14),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.hopelink_admin',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.location_on_rounded,
                    color: markerColor,
                    size: 34,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationMapDialog extends StatefulWidget {
  const _LocationMapDialog({
    required this.initialPoint,
    required this.title,
    required this.accentColor,
    required this.markerColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedTextColor,
  });

  final LatLng initialPoint;
  final String title;
  final Color accentColor;
  final Color markerColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedTextColor;

  @override
  State<_LocationMapDialog> createState() => _LocationMapDialogState();
}

class _LocationMapDialogState extends State<_LocationMapDialog> {
  late LatLng _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.surfaceColor,
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 820,
        height: 620,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: widget.textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: widget.mutedTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: widget.borderColor),
                    ),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: widget.initialPoint,
                        initialZoom: 13,
                        onTap: (_, point) =>
                            setState(() => _selectedPoint = point),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.hopelink_admin',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedPoint,
                              width: 48,
                              height: 48,
                              child: Icon(
                                Icons.location_on_rounded,
                                color: widget.markerColor,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lat ${_selectedPoint.latitude.toStringAsFixed(6)} | Lng ${_selectedPoint.longitude.toStringAsFixed(6)}',
                      style: GoogleFonts.dmMono(color: widget.accentColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selectedPoint),
                    child: const Text('Use Location'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
