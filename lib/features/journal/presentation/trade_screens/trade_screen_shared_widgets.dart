part of '../trade_journal_trade_screens.dart';

class _TradeHeader extends StatelessWidget {
  const _TradeHeader({required this.entry});

  final TradeJournalEntry entry;

  @override
  Widget build(BuildContext context) => JournalPanel(
    borderColor: statusColor(entry.status).withValues(alpha: .35),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: TradeXColors.goldBright,
            shape: BoxShape.circle,
          ),
          child: Text(
            entry.symbol.length >= 3
                ? entry.symbol.substring(0, 3)
                : entry.symbol,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.symbol,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${titleCase(entry.market)} · ${titleCase(entry.direction)}',
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        JournalBadge(label: entry.status, color: statusColor(entry.status)),
      ],
    ),
  );
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Ink(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111923),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: .09)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: TradeXColors.secondaryText),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 9,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _numberField(
  TextEditingController controller,
  String label, {
  bool required = false,
}) => TextFormField(
  controller: controller,
  keyboardType: const TextInputType.numberWithOptions(
    decimal: true,
    signed: true,
  ),
  decoration: InputDecoration(labelText: label),
  validator: required
      ? (value) => value?.trim().isEmpty == true ? '$label is required.' : null
      : null,
);

double? _double(TextEditingController controller) =>
    double.tryParse(controller.text.trim());

String _date(DateTime value) => _dateText(value);

String _dateText(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _time(TimeOfDay value) => _timeText(value);

String _timeText(TimeOfDay value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';
