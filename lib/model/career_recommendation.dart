class CareerRecommendation {
  final String recommendedCareer;
  final String whyThisCareer;
  final List<String> recommendedSkills;
  final List<String> skillGap;

  CareerRecommendation({
    required this.recommendedCareer,
    required this.whyThisCareer,
    required this.recommendedSkills,
    required this.skillGap,
  });

  factory CareerRecommendation.fromJson(
      Map<String, dynamic> json) {
    return CareerRecommendation(
      recommendedCareer:
      json['recommendedCareer'] ?? '',

      whyThisCareer:
      json['whyThisCareer'] ?? '',

      recommendedSkills:
      List<String>.from(
        json['recommendedSkills'] ?? [],
      ),

      skillGap:
      List<String>.from(
        json['skillGap'] ?? [],
      ),
    );
  }
}