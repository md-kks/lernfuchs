# Learning System Architecture

This document describes the core architecture of the learning system, focusing on how tasks are generated, evaluated, and adapted to student performance.

## Core Components

### 1. Task Generation Engine

The `TaskGenerator` class is the central hub for creating learning exercises. It maintains a registry of task templates organized by subject, grade, and topic.

**Key Features:**
- Template-based system for different subjects (Math, German) and grade levels
- Support for both single-topic and interleaved practice sessions
- Reproducible task generation using seed values for debugging
- Dynamic template registration system

**Usage:**
```dart
final tasks = TaskGenerator.generateSession(
  subject: Subject.math,
  grade: 3,
  topic: 'schriftliche_addition',
  difficulty: 2,
  count: 10,
);
```

### 2. Evaluation System

The `Evaluator` class handles assessment of student responses across different task types:

**Supported Task Types:**
- `freeInput`: For numerical or text answers with tolerance for minor errors
- `multipleChoice`: Standard multiple choice evaluation
- `ordering`: For arranging words or letters in correct sequence
- `gapFill`: For filling in blanks in text

**Key Design Principles:**
- Centralized dispatch system that routes to appropriate evaluation methods
- Support for case-insensitive and trimmed string comparisons
- Special handling for numerical tolerance (±0.001 for doubles)

### 3. Difficulty Management

Two adaptive difficulty engines provide different approaches to adjusting task difficulty:

#### DifficultyEngine
- Simple adaptive system based on recent performance
- Adjusts difficulty based on hit rate (50-90% target)
- Maintains difficulty within bounds (1-5 scale)

#### EloDifficultyEngine
- Elo-based rating system treating student and task as opponents
- Considers both student ability and task difficulty
- Provides recommendation system for optimal next task difficulty

### 4. Curriculum Mapping

The `Curriculum` class handles regional variations in educational standards:

**Key Features:**
- Federal state-specific variations in teaching sequences
- Different approaches to topics like multiplication tables
- Support for different handwriting styles (cursive vs. print)

**Regional Variations:**
- Some states teach cursive writing earlier
- Different timing for multiplication table learning
- Varying topic sequences across grade levels

## Template System

The system uses a template-based approach where each task type is implemented as a `TaskTemplate` with:
- Generation logic for creating specific exercises
- Evaluation methods for assessing responses
- Subject, grade, and topic metadata

## Architecture Benefits

1. **Modular Design**: Easy to add new subjects, grades, or topics
2. **Adaptive Learning**: Difficulty adjusts based on performance
3. **Regional Flexibility**: Supports different educational standards
4. **Reproducible**: Seed-based generation for testing and debugging
5. **Extensible**: Template system allows for new exercise types

## Usage Patterns

### Single Topic Practice
```dart
TaskGenerator.generateSession(
  subject: Subject.math,
  grade: 3,
  topic: 'schriftliche_addition',
  difficulty: 2,
  count: 10,
);
```

### Interleaved Practice
```dart
TaskGenerator.generateInterleavedSession(
  topics: [
    (subject: Subject.math, grade: 2, topic: 'addition_bis_100'),
    (subject: Subject.math, grade: 2, topic: 'einmaleins'),
    (subject: Subject.german, grade: 2, topic: 'artikel'),
  ],
  difficulty: 2,
  count: 15,
);
```

This architecture provides a solid foundation for an adaptive learning system that can be extended and customized for different educational needs.