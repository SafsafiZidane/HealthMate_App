class HealthHabitsInput {
  double sleepHours;
  int sleepQuality;
  double caffeineMg;
  double exerciseMin;
  double moodScore;
  int socialInteraction;
  double waterLiters;
  int mealRegularity;
  int junkFood;
  double workHours;
  double screenTimeH;
  int mindfulness;

  HealthHabitsInput({
    this.sleepHours = 7.0,
    this.sleepQuality = 5,
    this.caffeineMg = 100.0,
    this.exerciseMin = 30.0,
    this.moodScore = 6.0,
    this.socialInteraction = 5,
    this.waterLiters = 1.5,
    this.mealRegularity = 5,
    this.junkFood = 2,
    this.workHours = 8.0,
    this.screenTimeH = 4.0,
    this.mindfulness = 5,
  });

  Map<String, dynamic> toJson() => {
    'sleep_hours': sleepHours,
    'sleep_quality': sleepQuality,
    'caffeine_mg': caffeineMg,
    'exercise_min': exerciseMin,
    'mood_score': moodScore,
    'social_interaction': socialInteraction,
    'water_liters': waterLiters,
    'meal_regularity': mealRegularity,
    'junk_food': junkFood,
    'work_hours': workHours,
    'screen_time_h': screenTimeH,
    'mindfulness': mindfulness,
  };
}
