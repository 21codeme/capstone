import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/text_styles.dart';

class MultiSelectWidget extends StatefulWidget {
  final String label;
  final List<String> options;
  final List<String> selectedValues;
  final Function(List<String>) onSelectionChanged;
  final String? Function(List<String>?)? validator;
  final String hintText;

  const MultiSelectWidget({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValues,
    required this.onSelectionChanged,
    this.validator,
    this.hintText = 'Select options',
  });

  @override
  State<MultiSelectWidget> createState() => _MultiSelectWidgetState();
}

class _MultiSelectWidgetState extends State<MultiSelectWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.textTheme.labelLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        FormField<List<String>>(
          initialValue: widget.selectedValues,
          validator: widget.validator,
          builder: (FormFieldState<List<String>> field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: field.hasError ? AppColors.errorRed : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: widget.selectedValues.isEmpty
                              ? Text(
                                  widget.hintText,
                                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: widget.selectedValues.map((value) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.primaryBlue.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            value,
                                            style: AppTextStyles.textTheme.bodySmall?.copyWith(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () {
                                              final newSelection = List<String>.from(widget.selectedValues);
                                              newSelection.remove(value);
                                              widget.onSelectionChanged(newSelection);
                                              field.didChange(newSelection);
                                            },
                                            child: Icon(
                                              Icons.close,
                                              size: 14,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isExpanded)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: widget.options.map((option) {
                        final isSelected = widget.selectedValues.contains(option);
                        return InkWell(
                          onTap: () {
                            final newSelection = List<String>.from(widget.selectedValues);
                            if (isSelected) {
                              newSelection.remove(option);
                            } else {
                              newSelection.add(option);
                            }
                            widget.onSelectionChanged(newSelection);
                            field.didChange(newSelection);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                  color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                                      color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      field.errorText!,
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.errorRed,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}