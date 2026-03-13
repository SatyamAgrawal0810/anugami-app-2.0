class CancelReason {
  final String value;
  final String label;

  const CancelReason({required this.value, required this.label});
}

const List<CancelReason> cancelReasons = [
  CancelReason(value: 'changed_mind', label: 'Changed my mind'),
  CancelReason(value: 'found_cheaper', label: 'Found cheaper elsewhere'),
  CancelReason(value: 'ordered_by_mistake', label: 'Ordered by mistake'),
  CancelReason(value: 'delay_expected', label: 'Delivery taking too long'),
  CancelReason(value: 'other', label: 'Other'),
];
