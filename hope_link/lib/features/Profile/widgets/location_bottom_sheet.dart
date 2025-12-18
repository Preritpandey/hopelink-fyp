import 'package:flutter/material.dart';
import '../models/location_model.dart';

Future<LocationModel?> showLocationEditor(
    BuildContext context, LocationModel location) {
  final country = TextEditingController(text: location.country);
  final city = TextEditingController(text: location.city);
  final address = TextEditingController(text: location.address);

  return showModalBottomSheet<LocationModel>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Edit Location",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(controller: country, decoration: const InputDecoration(labelText: "Country")),
          TextField(controller: city, decoration: const InputDecoration(labelText: "City")),
          TextField(controller: address, decoration: const InputDecoration(labelText: "Address")),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                LocationModel(
                  country: country.text,
                  city: city.text,
                  address: address.text,
                ),
              );
            },
            child: const Text("Save"),
          )
        ],
      ),
    ),
  );
}
