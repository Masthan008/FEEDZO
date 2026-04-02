import 'package:flutter/material.dart';
import '../core/theme.dart';

class DataTableCard extends StatelessWidget {
  final String title;
  final List<String> columns;
  final List<DataRow> rows;
  final Widget? action;
  final Widget? filter;

  const DataTableCard({
    super.key,
    required this.title,
    required this.columns,
    required this.rows,
    this.action,
    this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final filter = this.filter;
    final action = this.action;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                ?filter,
                if (filter != null) const SizedBox(width: 8),
                ?action,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
              headingTextStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              dataTextStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              columnSpacing: 20,
              horizontalMargin: 20,
              dividerThickness: 1,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 60,
              columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
              rows: rows,
            ),
          ),
        ],
      ),
    );
  }
}
