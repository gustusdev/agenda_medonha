class Subject {
  String id;
  String name;
  String? teacher;
  String dayOfWeek;
  String time;

  Subject({required this.id, required this.name, this.teacher, required this.dayOfWeek, required this.time});

  // Para salvar como JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'teacher': teacher,
    'dayOfWeek': dayOfWeek,
    'time': time,
  };

  // Para carregar de JSON
  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['id'],
    name: json['name'],
    teacher: json['teacher'],
    dayOfWeek: json['dayOfWeek'],
    time: json['time'],
  );
}

class Task {
  String id;
  String subjectName;
  String title;
  DateTime deadline;
  String content;

  Task({required this.id, required this.subjectName, required this.title, required this.deadline, required this.content});

  Map<String, dynamic> toJson() => {'id': id, 'subjectName': subjectName, 'title': title, 'deadline': deadline.toIso8601String(), 'content': content};

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    subjectName: json['subjectName'],
    title: json['title'],
    deadline: DateTime.parse(json['deadline']),
    content: json['content'],
  );
}