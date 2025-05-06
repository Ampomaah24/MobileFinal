import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/location_service.dart';

class DistanceFilterDialog extends StatefulWidget {
  final double initialDistance;
  final Function(double) onDistanceChanged;
  
  const DistanceFilterDialog({
    Key? key,
    required this.initialDistance,
    required this.onDistanceChanged,
  }) : super(key: key);

  @override
  _DistanceFilterDialogState createState() => _DistanceFilterDialogState();
}

class _DistanceFilterDialogState extends State<DistanceFilterDialog> {
  late double _searchRadius;
  final List<double> _presetDistances = [1, 5, 10, 25, 50, 100];
  
  @override
  void initState() {
    super.initState();
    _searchRadius = widget.initialDistance / 1000; // Convert meters to km
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);
    
    return AlertDialog(
      title: const Text('Search Radius'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current value display
          Text(
            '${_searchRadius.toStringAsFixed(1)} km',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Slider
          Slider(
            value: _searchRadius,
            min: 1,
            max: 100,
            divisions: 99,
            label: '${_searchRadius.toStringAsFixed(1)} km',
            onChanged: (value) {
              setState(() {
                _searchRadius = value;
              });
            },
          ),
          
          // Preset chips
          Wrap(
            spacing: 8,
            children: _presetDistances.map((distance) => 
              ChoiceChip(
                label: Text('$distance km'),
                selected: _searchRadius == distance,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _searchRadius = distance;
                    });
                  }
                },
              )
            ).toList(),
          ),
          
          // Location status
          const SizedBox(height: 16),
          if (locationService.currentPosition == null)
            const Text(
              'Enable location services to see nearby events',
              style: TextStyle(color: Colors.orange),
              textAlign: TextAlign.center,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onDistanceChanged(_searchRadius * 1000); // Convert km back to meters
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}