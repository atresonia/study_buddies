class Course {
  final String number;
  final String name;
  Course({this.number, this.name});

  @override
  String toString() {
    return "$number - $name";
  }
}