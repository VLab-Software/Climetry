import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/climate_view_model.dart';

class LocationField extends StatelessWidget {
  final ClimateViewModel vm;
  const LocationField({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextField(
          controller: vm.locationController,
          focusNode: vm.locationFocusNode,
          onChanged: vm.searchLocations,
          decoration: const InputDecoration(
            hintText: 'Search for a location',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(borderSide: BorderSide.none),
            filled: true,
          ),
        ),
        if (vm.showSuggestions && vm.suggestions.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            top: 56,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surface,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: vm.suggestions.length,
                  itemBuilder: (_, i) {
                    final s = vm.suggestions[i];
                    return ListTile(
                      dense: true,
                      title: Text(
                        s.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => vm.selectLocation(s),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
