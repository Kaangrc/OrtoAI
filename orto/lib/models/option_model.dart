class OptionModel {
  String option;
  int optionLevel;

  OptionModel({
    required this.option,
    required this.optionLevel,
  });

  Map<String, dynamic> toJson() => {
        "option": option,
        "option_level": optionLevel,
      };

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      option: json["option"],
      optionLevel: json["option_level"],
    );
  }
}

