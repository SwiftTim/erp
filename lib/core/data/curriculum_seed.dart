// lib/core/data/curriculum_seed.dart
//
// Complete CBC Curriculum Seed (Ministry of Education Kenya)
// Covers PP1–PP2, Grade 1–3 (Lower Primary), Grade 4–6 (Upper Primary),
//         Grade 7–9 (Junior Secondary) — Core & Elective subjects.
//
// Call seedCurriculum(db) once on first launch.
// It is idempotent — checks row count before inserting.

import '../../data/local/app_database.dart';
import '../../data/models/curriculum_models.dart';

Future<void> seedCurriculum(AppDatabase db) async {
  final count = await db.curriculumDao.countAreas() ?? 0;
  if (count > 0) return; // Already seeded

  final List<LearningAreaModel> areas = [];
  final List<StrandModel> strands = [];
  final List<SubStrandModel> subStrands = [];

  for (final s in _curriculum) {
    final area = LearningAreaModel(
      id: s['id'] as String,
      name: s['name'] as String,
      gradeBand: s['band'] as String,
      category: s['category'] as String? ?? 'Core',
    );
    areas.add(area);

    for (final st in s['strands'] as List<Map<String, dynamic>>) {
      final strand = StrandModel(
        id: st['id'] as String,
        learningAreaId: area.id,
        strandName: st['name'] as String,
      );
      strands.add(strand);

      final ssList = st['subStrands'] as List<String>;
      for (int i = 0; i < ssList.length; i++) {
        subStrands.add(SubStrandModel(
          id: '${strand.id}-ss$i',
          strandId: strand.id,
          subStrandName: ssList[i],
        ));
      }
    }
  }

  await db.curriculumDao.insertFullCurriculum(areas, strands, subStrands);
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA
// ─────────────────────────────────────────────────────────────────────────────

const _curriculum = <Map<String, dynamic>>[
  // 🟡 PP1 & PP2 (Pre-Primary)
  {
    'id': 'pp-lang', 'name': 'Language Activities', 'band': 'PP1-PP2', 'category': 'Core',
    'strands': [
      {'id': 'pp-lang-ls', 'name': 'Listening & Speaking', 'subStrands': ['Listening comprehension', 'Oral expression', 'Vocabulary development', 'Polite language use']},
      {'id': 'pp-lang-rr', 'name': 'Reading Readiness', 'subStrands': ['Phonological awareness', 'Sound discrimination', 'Letter recognition', 'Word-picture association']},
      {'id': 'pp-lang-wr', 'name': 'Writing Readiness', 'subStrands': ['Fine motor skills', 'Pre-writing strokes', 'Letter formation', 'Name writing']},
    ],
  },
  {
    'id': 'pp-math', 'name': 'Mathematical Activities', 'band': 'PP1-PP2', 'category': 'Core',
    'strands': [
      {'id': 'pp-math-num', 'name': 'Numbers', 'subStrands': ['Counting (rote & object)', 'Number recognition', 'Number sequencing', 'Number value']},
      {'id': 'pp-math-meas', 'name': 'Measurement', 'subStrands': ['Length comparison', 'Weight comparison', 'Capacity comparison', 'Time awareness']},
      {'id': 'pp-math-geo', 'name': 'Geometry', 'subStrands': ['Shape identification', 'Position & direction', 'Pattern formation']},
      {'id': 'pp-math-data', 'name': 'Data Handling (basic)', 'subStrands': ['Sorting', 'Grouping', 'Simple classification']},
    ],
  },
  {
    'id': 'pp-env', 'name': 'Environmental Activities', 'band': 'PP1-PP2', 'category': 'Core',
    'strands': [
      {'id': 'pp-env-social', 'name': 'Social Environment', 'subStrands': ['Family roles', 'School community', 'Safety at home & school']},
      {'id': 'pp-env-nat', 'name': 'Natural Environment', 'subStrands': ['Plants', 'Animals', 'Water', 'Soil']},
      {'id': 'pp-env-weather', 'name': 'Weather', 'subStrands': ['Types of weather', 'Weather changes', 'Safety during weather']},
    ],
  },
  {
    'id': 'pp-creative', 'name': 'Creative Activities', 'band': 'PP1-PP2', 'category': 'Core',
    'strands': [
      {'id': 'pp-creative-varts', 'name': 'Visual Arts', 'subStrands': ['Drawing', 'Painting', 'Modeling']},
      {'id': 'pp-creative-music', 'name': 'Music', 'subStrands': ['Rhythm', 'Singing', 'Instrument play']},
      {'id': 'pp-creative-move', 'name': 'Movement', 'subStrands': ['Locomotor skills', 'Coordination', 'Creative movement']},
    ],
  },
  {
    'id': 'pp-re', 'name': 'Religious Education', 'band': 'PP1-PP2', 'category': 'Core',
    'strands': [
      {'id': 'pp-re-self', 'name': 'Self Awareness', 'subStrands': ['Personal identity', 'Respect']},
      {'id': 'pp-re-vals', 'name': 'Moral Values', 'subStrands': ['Honesty', 'Sharing', 'Responsibility']},
      {'id': 'pp-re-prac', 'name': 'Religious Practices', 'subStrands': ['Prayer', 'Celebrations']},
    ],
  },

  // 🟢 Grade 1–3 (Lower Primary)
  {
    'id': 'lp-eng', 'name': 'English', 'band': 'Grade 1-3', 'category': 'Core',
    'strands': [
      {'id': 'lp-eng-ls', 'name': 'Listening & Speaking', 'subStrands': ['Pronunciation', 'Stress & intonation', 'Conversational skills']},
      {'id': 'lp-eng-read', 'name': 'Reading', 'subStrands': ['Phonics', 'Word recognition', 'Fluency', 'Comprehension']},
      {'id': 'lp-eng-write', 'name': 'Writing', 'subStrands': ['Sentence construction', 'Paragraph writing', 'Creative writing']},
      {'id': 'lp-eng-lang', 'name': 'Language Use', 'subStrands': ['Parts of speech', 'Tenses', 'Punctuation']},
    ],
  },
  {
    'id': 'lp-math', 'name': 'Mathematics', 'band': 'Grade 1-3', 'category': 'Core',
    'strands': [
      {'id': 'lp-math-num', 'name': 'Numbers', 'subStrands': ['Place value', 'Addition', 'Subtraction', 'Multiplication (intro)', 'Division (intro)']},
      {'id': 'lp-math-meas', 'name': 'Measurement', 'subStrands': ['Length', 'Mass', 'Capacity', 'Time', 'Money']},
      {'id': 'lp-math-geo', 'name': 'Geometry', 'subStrands': ['2D shapes', '3D objects', 'Lines & angles (basic)']},
      {'id': 'lp-math-data', 'name': 'Data Handling', 'subStrands': ['Tally charts', 'Pictographs', 'Bar graphs (intro)']},
    ],
  },
  {
    'id': 'lp-env', 'name': 'Environmental Activities', 'band': 'Grade 1-3', 'category': 'Core',
    'strands': [
      {'id': 'lp-env-social', 'name': 'Social Environment', 'subStrands': ['Community roles', 'Transport', 'Communication']},
      {'id': 'lp-env-nat', 'name': 'Natural Environment', 'subStrands': ['Plants & animals', 'Water sources', 'Soil types']},
      {'id': 'lp-env-health', 'name': 'Health', 'subStrands': ['Personal hygiene', 'Nutrition', 'Disease prevention']},
    ],
  },
  {
    'id': 'lp-creative', 'name': 'Creative Arts', 'band': 'Grade 1-3', 'category': 'Core',
    'strands': [
      {'id': 'lp-creative-varts', 'name': 'Visual Arts', 'subStrands': ['Drawing techniques', 'Craft work']},
      {'id': 'lp-creative-parts', 'name': 'Performing Arts', 'subStrands': ['Drama', 'Music', 'Dance']},
    ],
  },

  // 🔵 Grade 4–6 (Upper Primary)
  {
    'id': 'up-math', 'name': 'Mathematics', 'band': 'Grade 4-6', 'category': 'Core',
    'strands': [
      {'id': 'up-math-num', 'name': 'Numbers', 'subStrands': ['Fractions', 'Decimals', 'Ratios', 'Percentages']},
      {'id': 'up-math-alg', 'name': 'Algebra', 'subStrands': ['Simple equations', 'Patterns', 'Expressions']},
      {'id': 'up-math-geo', 'name': 'Geometry', 'subStrands': ['Angles', 'Area', 'Perimeter', 'Volume']},
      {'id': 'up-math-meas', 'name': 'Measurement', 'subStrands': ['Unit conversion', 'Time calculations']},
      {'id': 'up-math-data', 'name': 'Data Handling', 'subStrands': ['Bar graphs', 'Pie charts', 'Mean, median, mode']},
    ],
  },
  {
    'id': 'up-sci', 'name': 'Science & Technology', 'band': 'Grade 4-6', 'category': 'Core',
    'strands': [
      {'id': 'up-sci-living', 'name': 'Living Things', 'subStrands': ['Cells (intro)', 'Classification', 'Reproduction']},
      {'id': 'up-sci-matter', 'name': 'Matter', 'subStrands': ['States of matter', 'Mixtures', 'Separation']},
      {'id': 'up-sci-energy', 'name': 'Energy', 'subStrands': ['Forms of energy', 'Heat', 'Light']},
      {'id': 'up-sci-motion', 'name': 'Force & Motion', 'subStrands': ['Types of forces', 'Motion']},
      {'id': 'up-sci-tech', 'name': 'Technology', 'subStrands': ['Simple machines', 'ICT basics']},
    ],
  },
  {
    'id': 'up-ss', 'name': 'Social Studies', 'band': 'Grade 4-6', 'category': 'Core',
    'strands': [
      {'id': 'up-ss-citizen', 'name': 'Citizenship', 'subStrands': ['Rights & responsibilities', 'Governance structure']},
      {'id': 'up-ss-hist', 'name': 'History', 'subStrands': ['Early civilizations', 'Kenyan history']},
      {'id': 'up-ss-geo', 'name': 'Geography', 'subStrands': ['Physical features', 'Resources']},
    ],
  },

  // 🟣 Grade 7–9 (Junior Secondary)
  {
    'id': 'js-math', 'name': 'Mathematics', 'band': 'Grade 7-9', 'category': 'Core',
    'strands': [
      {'id': 'js-math-num', 'name': 'Numbers', 'subStrands': ['Integers', 'Indices', 'Surds']},
      {'id': 'js-math-alg', 'name': 'Algebra', 'subStrands': ['Linear equations', 'Inequalities', 'Graphs', 'Simultaneous equations']},
      {'id': 'js-math-geo', 'name': 'Geometry', 'subStrands': ['Transformations', 'Congruency', 'Pythagoras', 'Trigonometry (intro)']},
      {'id': 'js-math-stats', 'name': 'Statistics', 'subStrands': ['Data collection', 'Probability', 'Mean, variance']},
    ],
  },
  {
    'id': 'js-sci', 'name': 'Integrated Science', 'band': 'Grade 7-9', 'category': 'Core',
    'strands': [
      {'id': 'js-sci-bio', 'name': 'Biology Concepts', 'subStrands': ['Cells', 'Human systems', 'Reproduction']},
      {'id': 'js-sci-chem', 'name': 'Chemistry Concepts', 'subStrands': ['Atomic structure', 'Acids & bases', 'Chemical reactions']},
      {'id': 'js-sci-phys', 'name': 'Physics Concepts', 'subStrands': ['Motion', 'Electricity', 'Waves']},
      {'id': 'js-sci-env', 'name': 'Environmental Science', 'subStrands': ['Ecosystems', 'Pollution', 'Climate change']},
    ],
  },
  {
    'id': 'js-ss', 'name': 'Social Studies', 'band': 'Grade 7-9', 'category': 'Core',
    'strands': [
      {'id': 'js-ss-gov', 'name': 'Governance', 'subStrands': ['Constitution', 'Leadership', 'Civic responsibility']},
      {'id': 'js-ss-econ', 'name': 'Economics', 'subStrands': ['Scarcity', 'Production', 'Trade']},
      {'id': 'js-ss-hist', 'name': 'History', 'subStrands': ['Colonialism', 'Independence', 'Global relations']},
    ],
  },
  {
    'id': 'js-ict', 'name': 'ICT', 'band': 'Grade 7-9', 'category': 'Core',
    'strands': [
      {'id': 'js-ict-digit', 'name': 'Digital Literacy', 'subStrands': ['Computer components', 'Operating systems', 'File management']},
      {'id': 'js-ict-prod', 'name': 'Productivity Tools', 'subStrands': ['Word processing', 'Spreadsheets', 'Presentations']},
      {'id': 'js-ict-safety', 'name': 'Internet & Safety', 'subStrands': ['Cybersecurity', 'Online ethics']},
      {'id': 'js-ict-coding', 'name': 'Coding (Intro)', 'subStrands': ['Algorithms', 'Block programming']},
    ],
  },
  {
    'id': 'js-pts', 'name': 'Pre-Technical Studies', 'band': 'Grade 7-9', 'category': 'Core',
    'strands': [
      {'id': 'js-pts-elec', 'name': 'Electrical Technology', 'subStrands': ['Circuits', 'Safety']},
      {'id': 'js-pts-wood', 'name': 'Wood Technology', 'subStrands': ['Tools', 'Joinery']},
      {'id': 'js-pts-metal', 'name': 'Metal Technology', 'subStrands': ['Fabrication basics']},
    ],
  },
];
