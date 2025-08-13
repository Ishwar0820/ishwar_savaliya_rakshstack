// lib/features/admin/properties_list_page.dart
import 'package:flutter/material.dart';
import 'admin_models.dart';

class PropertiesListPage extends StatelessWidget {
  final List<AdminPg> items;
  final VoidCallback onAddNew;
  final void Function(AdminPg) onEdit;
  final void Function(AdminPg) onDelete;
  final void Function(AdminPg) onToggleHide;

  const PropertiesListPage({
    super.key,
    required this.items,
    required this.onAddNew,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleHide,
  });

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    return Stack(
      children: [
        ListView.separated(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 100 + bottomSafe),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _PgRow(
            pg: items[i],
            onEdit: () => onEdit(items[i]),
            onDelete: () => onDelete(items[i]),
            onToggleHide: () => onToggleHide(items[i]),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16 + bottomSafe,
          child: FloatingActionButton.extended(
            onPressed: onAddNew,
            icon: const Icon(Icons.add),
            label: const Text('Add PG'),
          ),
        ),
      ],
    );
  }
}

class _PgRow extends StatelessWidget {
  final AdminPg pg;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleHide;

  const _PgRow({
    required this.pg,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleHide,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = pg.hidden ? Colors.orange[700] : Colors.green[700];
    final statusText = pg.hidden ? 'Hidden' : 'Active';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 96,
                height: 86,
                child: (pg.images.isNotEmpty)
                    ? Image.asset(pg.images.first, fit: BoxFit.cover)
                    : Container(color: const Color(0xFFEFEFEF)),
              ),
            ),

            const SizedBox(width: 12),

            // Middle content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pg.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pg.area}, ${pg.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: (pg.hidden ? Colors.orange[50] : Colors.green[50]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          'Starts from ₹${pg.minPrice}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: pg.hidden ? 'Unhide' : 'Hide',
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: onToggleHide,
                  icon: Icon(
                    pg.hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
