/// Curriculum areas offered in the app.
enum Subject {
  zoology('Zoology'),
  geometry('Geometry'),
  plants('Plants'),
  logic('Logic'),
  numbers('Numbers'),
  words('Words');

  const Subject(this.label);

  final String label;

  static Subject? tryParse(String? name) {
    for (final s in Subject.values) {
      if (s.name == name) return s;
    }
    return null;
  }
}
