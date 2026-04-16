class StationDialogue {
  final String stationId;
  final List<IntroFrame> intro;
  final List<ProgressMilestone> progressMilestones;
  final OutroData outro;
  final List<String> wrongAnswerPhrases;
  final List<String> correctPhrases;

  const StationDialogue({
    required this.stationId,
    required this.intro,
    required this.progressMilestones,
    required this.outro,
    required this.wrongAnswerPhrases,
    required this.correctPhrases,
  });

  factory StationDialogue.fromJson(Map<String, dynamic> json) {
    return StationDialogue(
      stationId: json['stationId'] as String,
      intro: (json['intro'] as List? ?? const [])
          .map((item) => IntroFrame.fromJson((item as Map).cast<String, dynamic>()))
          .toList(),
      progressMilestones: (json['progressMilestones'] as List? ?? const [])
          .map((item) => ProgressMilestone.fromJson((item as Map).cast<String, dynamic>()))
          .toList(),
      outro: OutroData.fromJson((json['outro'] as Map).cast<String, dynamic>()),
      wrongAnswerPhrases: (json['wrongAnswerPhrases'] as List? ?? const []).cast<String>(),
      correctPhrases: (json['correctPhrases'] as List? ?? const []).cast<String>(),
    );
  }

  ProgressMilestone? milestoneForTask(int tasksCompleted) {
    for (final milestone in progressMilestones) {
      if (milestone.atTask == tasksCompleted) return milestone;
    }
    return null;
  }
}

class IntroFrame {
  final String speaker;
  final String animation;
  final String text;
  final bool tts;

  const IntroFrame({
    required this.speaker,
    required this.animation,
    required this.text,
    this.tts = true,
  });

  factory IntroFrame.fromJson(Map<String, dynamic> json) {
    return IntroFrame(
      speaker: json['speaker'] as String,
      animation: json['animation'] as String? ?? 'idle',
      text: json['text'] as String,
      tts: json['tts'] as bool? ?? true,
    );
  }
}

class ProgressMilestone {
  final int atTask;
  final String sceneEvent;
  final String? ovaText;

  const ProgressMilestone({
    required this.atTask,
    required this.sceneEvent,
    this.ovaText,
  });

  factory ProgressMilestone.fromJson(Map<String, dynamic> json) {
    return ProgressMilestone(
      atTask: json['atTask'] as int,
      sceneEvent: json['sceneEvent'] as String,
      ovaText: json['ovaText'] as String?,
    );
  }
}

class OutroData {
  final String ovaText;
  final String finoAnimation;
  final String brummAnimation;
  final bool crystalFly;

  const OutroData({
    required this.ovaText,
    required this.finoAnimation,
    required this.brummAnimation,
    required this.crystalFly,
  });

  factory OutroData.fromJson(Map<String, dynamic> json) {
    return OutroData(
      ovaText: json['ovaText'] as String? ?? '',
      finoAnimation: json['finoAnimation'] as String? ?? 'idle',
      brummAnimation: json['brummAnimation'] as String? ?? 'idle',
      crystalFly: json['crystalFly'] as bool? ?? false,
    );
  }
}
