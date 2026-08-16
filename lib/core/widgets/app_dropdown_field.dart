import 'package:material_ui/material_ui.dart';

/// A dropdown field styled to match [AppTextField] — same amber label bar,
/// same border treatment — so forms can mix text and dropdown fields
/// without looking inconsistent.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.itemLabelBuilder,
    required this.onChanged,
    this.labelText,
    this.isRequired = false,
    this.outlineBorder,
  });

  final T value;
  final List<T> items;
  final String Function(T item) itemLabelBuilder;
  final ValueChanged<T> onChanged;

  final String? labelText;
  final bool isRequired;
  final OutlineInputBorder? outlineBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final border =
        outlineBorder ??
        OutlineInputBorder(borderRadius: BorderRadius.circular(10));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          RichText(
            text: TextSpan(
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurface,
              ),
              children: [
                TextSpan(text: labelText),
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: colors.error),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          dropdownColor: colors.surfaceContainerHigh,
          decoration: InputDecoration(
            border: border,
            enabledBorder: border.copyWith(
              borderSide: BorderSide(color: colors.outline),
            ),
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabelBuilder(item)),
                ),
              )
              .toList(),
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ],
    );
  }
}
