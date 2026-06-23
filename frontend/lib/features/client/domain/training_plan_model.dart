// lib/features/client/domain/training_plan_model.dart

class ExerciseModel {
  final String name;
  final String sets;
  final String reps;
  final String? notes;
  bool isCompleted;

  ExerciseModel({
    required this.name,
    required this.sets,
    required this.reps,
    this.notes,
    this.isCompleted = false,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      name: json['name']?.toString() ?? '',
      sets: json['sets']?.toString() ?? '',
      reps: json['reps']?.toString() ?? '',
      notes: json['notes']?.toString(),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'notes': notes,
    };
  }
}

class DayPlanModel {
  final String day;
  final String focus;
  final List<ExerciseModel> exercises;
  final String? notes;
  bool isCompleted;

  DayPlanModel({
    required this.day,
    required this.focus,
    required this.exercises,
    this.notes,
    this.isCompleted = false,
  });

  factory DayPlanModel.fromJson(Map<String, dynamic> json) {
    var exList = json['exercises'] as List? ?? [];
    List<ExerciseModel> exercises = exList
        .map((e) => e is Map<String, dynamic> 
            ? ExerciseModel.fromJson(e)
            : ExerciseModel(name: e.toString(), sets: '', reps: ''))
        .toList();

    return DayPlanModel(
      day: json['day']?.toString() ?? '',
      focus: json['focus']?.toString() ?? '',
      exercises: exercises,
      notes: json['notes']?.toString(),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'focus': focus,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'notes': notes,
    };
  }
}

class WeekPlanModel {
  final int week;
  final String? theme;
  final List<DayPlanModel> days;

  WeekPlanModel({
    required this.week,
    this.theme,
    required this.days,
  });

  factory WeekPlanModel.fromJson(Map<String, dynamic> json) {
    var dayList = json['days'] as List? ?? [];
    List<DayPlanModel> days = dayList
        .map((d) => DayPlanModel.fromJson(d as Map<String, dynamic>))
        .toList();

    return WeekPlanModel(
      week: json['week'] is int ? json['week'] : int.tryParse(json['week']?.toString() ?? '') ?? 0,
      theme: json['theme']?.toString(),
      days: days,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week': week,
      'theme': theme,
      'days': days.map((d) => d.toJson()).toList(),
    };
  }
}

class TrainingPlanModel {
  final int planID;
  final int clientID;
  final String title;
  final String goal;
  final String? level;
  final int? weeks;
  final String? status;
  final DateTime? completedAt;
  final int version;
  final int? parentPlanId;
  final List<WeekPlanModel> plan;
  final DateTime? createdAt;

  TrainingPlanModel({
    required this.planID,
    required this.clientID,
    required this.title,
    required this.goal,
    this.level,
    this.weeks,
    this.status,
    this.completedAt,
    required this.version,
    this.parentPlanId,
    required this.plan,
    this.createdAt,
  });

  factory TrainingPlanModel.fromJson(Map<String, dynamic> json) {
    var planList = json['plan'] as List? ?? [];
    List<WeekPlanModel> plan = planList
        .map((w) => WeekPlanModel.fromJson(w as Map<String, dynamic>))
        .toList();

    return TrainingPlanModel(
      planID: json['planID'] ?? 0,
      clientID: json['clientID'] ?? 0,
      title: json['title'] ?? '',
      goal: json['goal'] ?? '',
      level: json['level'],
      weeks: json['weeks'],
      status: json['status'],
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
      version: json['version'] ?? 1,
      parentPlanId: json['parent_plan_id'],
      plan: plan,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}

class TrainingPlanSummaryModel {
  final int planID;
  final String title;
  final String goal;
  final String? level;
  final int? weeks;
  final String? status;
  final DateTime? completedAt;
  final int version;
  final int? parentPlanId;
  final bool isActive;
  final DateTime? createdAt;

  TrainingPlanSummaryModel({
    required this.planID,
    required this.title,
    required this.goal,
    this.level,
    this.weeks,
    this.status,
    this.completedAt,
    required this.version,
    this.parentPlanId,
    required this.isActive,
    this.createdAt,
  });

  factory TrainingPlanSummaryModel.fromJson(Map<String, dynamic> json) {
    return TrainingPlanSummaryModel(
      planID: json['planID'] ?? 0,
      title: json['title'] ?? '',
      goal: json['goal'] ?? '',
      level: json['level'],
      weeks: json['weeks'],
      status: json['status'],
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
      version: json['version'] ?? 1,
      parentPlanId: json['parent_plan_id'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
