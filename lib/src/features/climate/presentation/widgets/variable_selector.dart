import 'package:flutter/material.dart';
import '../state/climate_view_model.dart';
import '../../domain/entities/climate_variable.dart';

class VariableSelector extends StatelessWidget {
  final ClimateViewModel vm;
  const VariableSelector({super.key, required this.vm});

  int _colsForWidth(double w) {
    if (w >= 1300) return 5;
    if (w >= 1100) return 4;
    if (w >= 768) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = _colsForWidth(w);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.8,
      ),
      itemCount: vm.apiVariables.length,
      itemBuilder: (context, i) {
        final v = vm.apiVariables[i];
        return _Tile(
          variable: v,
          onTap: () => vm.toggleVariable(v),
          selected: v.isSelected,
          disabled: !v.isSelected && vm.selectedCount >= vm.maxVariables,
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final ClimateVariable variable;
  final VoidCallback onTap;
  final bool selected;
  final bool disabled;
  const _Tile({
    required this.variable,
    required this.onTap,
    required this.selected,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).primaryColor
              : Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              variable.icon,
              size: 18,
              color: selected
                  ? Colors.black
                  : Colors.white.withOpacity(disabled ? 0.3 : 1),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                variable.name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.black
                      : Colors.white.withOpacity(disabled ? 0.3 : 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
