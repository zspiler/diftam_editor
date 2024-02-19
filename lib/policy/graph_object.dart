abstract class GraphObject {
  GraphObject copyWith();

  static List<T> cloneObjects<T extends GraphObject>(List<T> objects) {
    return objects.map((object) => object.copyWith() as T).toList();
  }
}
