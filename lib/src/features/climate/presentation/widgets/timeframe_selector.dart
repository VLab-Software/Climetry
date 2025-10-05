import 'package:flutter/material.dart';
import '../state/climate_view_model.dart';

class TimeframeSelector extends StatelessWidget {
  final ClimateViewModel vm;
  const TimeframeSelector({super.key, required this.vm});

  Future<void> _selectDate(BuildContext context) async {
    if (vm.isSingleDate) {
      final picked = await showDatePicker(
        context: context,
        initialDate: vm.selectedSingleDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (picked != null) {
        vm.selectedSingleDate = picked;
        vm.selectedDateRange = null;
      }
    } else {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
        currentDate: DateTime.now(),
        initialDateRange: vm.selectedDateRange,
      );
      if (picked != null) {
        vm.selectedDateRange = picked;
        vm.selectedSingleDate = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(vm.userFriendlyDateRange, style: const TextStyle(fontSize: 16)),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ToggleButtons(
          isSelected: [vm.isSingleDate, !vm.isSingleDate],
          onPressed: (index) => vm.setSingleDateMode(index == 0),
          borderRadius: BorderRadius.circular(8),
          selectedColor: Colors.black,
          fillColor: Theme.of(context).primaryColor,
          color: Colors.white,
          children: const [
            Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('Single')),
            Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('Range')),
          ],
        )
      ],
    );
  }
}
