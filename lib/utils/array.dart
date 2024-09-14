T? firstOrNull<T>(List<T> list, bool Function(T element) predicate) {
  final elements = list.where(predicate);
  if (elements.isEmpty) {
    return null;
  } else {
    return elements.first;
  }
}
