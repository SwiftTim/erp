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

  // ══════════════════════════════════════════════════════════════════
  // PRE-PRIMARY  (PP1 – PP2)
  // ══════════════════════════════════════════════════════════════════
  {
    'id': 'pp-lang', 'name': 'Language Activities', 'band': 'PP1-PP2', 'category': 'Core',
    'strands': [
      {'id': 'pp-lang-ls', 'name': 'Listening & Speaking',
       'subStrands': ['Greetings & Conversations', 'Storytelling', 'Sound Discrimination', 'Following Instructions']},
      {'id': 'pp-lang-rr', 'name': 'Reading Readiness',
       'subStrands': ['Letter Recognition', 'Phonemic Awareness', 'Word Recognition', 'Print Awareness']},
      {'id': 'pp-lang-wr', 'name': 'Writing Readiness',
       'subStrands': ['Pattern Tracing', 'Letter Formation', 'Name Writing', 'Drawing & Colouring']},
    ],
  },
  {
    'id': 'pp-math', 'name': 'Mathematical Activities', 'band': 'PP1-PP2', 'category': 'Core',
    'strands': [
      {'id': 'pp-math-num', 'name': 'Numbers',
       'subStrands': ['Counting (1–100)', 'Number Recognition', 'Number Writing', 'Number Comparison']},
      {'id': 'pp-math-meas', 'name': 'Measurement',
       'subStrands': ['Size Comparison', 'Length', 'Mass', 'Time (Day/Night, Days of Week)']},
      {'id': 'pp-math-shape', 'name': 'Shapes & Space',
       'subStrands': ['2D Shapes', 'Position & Direction', 'Patterns']},
    ],
  },
  {
    'id': 'pp-env', 'name': 'Environmental Activities', 'band': 'PP1-PP2', 'category': 'Core',
    'strands': [
      {'id': 'pp-env-social', 'name': 'Social Environment',
       'subStrands': ['Family & Home', 'School Community', 'Neighbourhood']},
      {'id': 'pp-env-nat', 'name': 'Natural Environment',
       'subStrands': ['Plants', 'Animals', 'Weather & Seasons']},
      {'id': 'pp-env-health', 'name': 'Health & Safety',
       'subStrands': ['Personal Hygiene', 'Road Safety', 'Fire Safety']},
    ],
  },
  {
    'id': 'pp-psycho', 'name': 'Psychomotor & Creative Activities', 'band': 'PP1-PP2', 'category': 'Core',
    'strands': [
      {'id': 'pp-psycho-move', 'name': 'Movement & Coordination',
       'subStrands': ['Running & Jumping', 'Balancing', 'Throwing & Catching', 'Fine Motor Skills']},
      {'id': 'pp-psycho-art', 'name': 'Creative Arts',
       'subStrands': ['Drawing & Painting', 'Singing & Rhymes', 'Drama & Role Play', 'Clay Modeling']},
    ],
  },
  {
    'id': 'pp-re', 'name': 'Religious Education Activities', 'band': 'PP1-PP2', 'category': 'Core',
    'strands': [
      {'id': 'pp-re-moral', 'name': 'Moral Values',
       'subStrands': ['Respect & Obedience', 'Sharing & Caring', 'Honesty', 'Helpfulness']},
      {'id': 'pp-re-worship', 'name': 'Worship Practices',
       'subStrands': ['Prayer', 'Songs of Praise', 'Religious Stories']},
    ],
  },

  // ══════════════════════════════════════════════════════════════════
  // LOWER PRIMARY  (Grade 1 – 3)
  // ══════════════════════════════════════════════════════════════════
  {
    'id': 'lp-eng', 'name': 'English', 'band': 'Grade 1-3', 'category': 'Core',
    'strands': [
      {'id': 'lp-eng-ls', 'name': 'Listening & Speaking',
       'subStrands': ['Pronunciation', 'Conversation', 'Oral Comprehension', 'Recitation & Songs']},
      {'id': 'lp-eng-read', 'name': 'Reading',
       'subStrands': ['Phonics & Decoding', 'Fluency', 'Literal Comprehension', 'Vocabulary in Context']},
      {'id': 'lp-eng-write', 'name': 'Writing',
       'subStrands': ['Handwriting', 'Spelling', 'Sentence Construction', 'Composition']},
      {'id': 'lp-eng-gram', 'name': 'Grammar & Usage',
       'subStrands': ['Nouns & Pronouns', 'Verbs', 'Adjectives', 'Punctuation']},
    ],
  },
  {
    'id': 'lp-kisw', 'name': 'Kiswahili', 'band': 'Grade 1-3', 'category': 'Core',
    'strands': [
      {'id': 'lp-kisw-ls', 'name': 'Kusikiliza na Kuzungumza',
       'subStrands': ['Mazungumzo ya Kila Siku', 'Matamshi Sahihi', 'Hadithi Fupi', 'Nyimbo na Mashairi']},
      {'id': 'lp-kisw-read', 'name': 'Kusoma',
       'subStrands': ['Fonetiki', 'Ufahamu wa Maneno', 'Ufahamu wa Sentensi', 'Usomaji wa Sauti']},
      {'id': 'lp-kisw-write', 'name': 'Kuandika',
       'subStrands': ['Tahajia', 'Uandishi wa Maneno', 'Sentensi Fupi', 'Insha Fupi']},
    ],
  },
  {
    'id': 'lp-math', 'name': 'Mathematics', 'band': 'Grade 1-3', 'category': 'Core',
    'strands': [
      {'id': 'lp-math-num', 'name': 'Numbers',
       'subStrands': ['Whole Numbers', 'Fractions', 'Place Value', 'Number Patterns']},
      {'id': 'lp-math-ops', 'name': 'Operations',
       'subStrands': ['Addition', 'Subtraction', 'Multiplication', 'Division']},
      {'id': 'lp-math-meas', 'name': 'Measurement',
       'subStrands': ['Length', 'Mass & Weight', 'Capacity & Volume', 'Time', 'Money']},
      {'id': 'lp-math-geo', 'name': 'Geometry',
       'subStrands': ['2D Shapes', '3D Shapes', 'Symmetry', 'Patterns']},
    ],
  },
  {
    'id': 'lp-env', 'name': 'Environmental Activities', 'band': 'Grade 1-3', 'category': 'Core',
    'strands': [
      {'id': 'lp-env-living', 'name': 'Living Things',
       'subStrands': ['Plants', 'Animals', 'Human Body', 'Ecosystems']},
      {'id': 'lp-env-weather', 'name': 'Weather & Climate',
       'subStrands': ['Weather Patterns', 'Seasons', 'Effects of Weather']},
      {'id': 'lp-env-comm', 'name': 'Community & Safety',
       'subStrands': ['Our Community', 'Road Safety', 'Water Safety', 'Fire Safety']},
    ],
  },
  {
    'id': 'lp-re', 'name': 'Religious Education', 'band': 'Grade 1-3', 'category': 'Core',
    'strands': [
      {'id': 'lp-re-creation', 'name': 'Creation',
       'subStrands': ['God as Creator', 'Care for Creation', 'Human Dignity']},
      {'id': 'lp-re-moral', 'name': 'Moral Teaching',
       'subStrands': ['Honesty', 'Respect', 'Love & Forgiveness', 'Courage']},
      {'id': 'lp-re-worship', 'name': 'Worship & Prayer',
       'subStrands': ['Prayer', 'Religious Songs', 'Religious Stories']},
    ],
  },
  {
    'id': 'lp-creative', 'name': 'Creative Arts', 'band': 'Grade 1-3', 'category': 'Core',
    'strands': [
      {'id': 'lp-creative-visual', 'name': 'Visual Arts',
       'subStrands': ['Drawing', 'Painting', 'Collage', 'Modeling']},
      {'id': 'lp-creative-perform', 'name': 'Performing Arts',
       'subStrands': ['Music & Rhythm', 'Dance', 'Drama & Storytelling']},
    ],
  },
  {
    'id': 'lp-phe', 'name': 'Physical & Health Education', 'band': 'Grade 1-3', 'category': 'Core',
    'strands': [
      {'id': 'lp-phe-movement', 'name': 'Movement Skills',
       'subStrands': ['Running', 'Jumping', 'Throwing & Catching', 'Balancing']},
      {'id': 'lp-phe-games', 'name': 'Games & Sports',
       'subStrands': ['Outdoor Games', 'Team Activities']},
      {'id': 'lp-phe-health', 'name': 'Health Practices',
       'subStrands': ['Hygiene', 'Nutrition', 'First Aid Basics']},
    ],
  },

  // ══════════════════════════════════════════════════════════════════
  // UPPER PRIMARY  (Grade 4 – 6)
  // ══════════════════════════════════════════════════════════════════
  {
    'id': 'up-eng', 'name': 'English', 'band': 'Grade 4-6', 'category': 'Core',
    'strands': [
      {'id': 'up-eng-ls', 'name': 'Listening & Speaking',
       'subStrands': ['Oral Comprehension', 'Discussion & Debate', 'Public Speaking', 'Pronunciation']},
      {'id': 'up-eng-read', 'name': 'Reading',
       'subStrands': ['Literal Comprehension', 'Inferential Comprehension', 'Critical Reading', 'Reading Strategies']},
      {'id': 'up-eng-write', 'name': 'Writing',
       'subStrands': ['Creative Writing', 'Functional Writing', 'Report Writing', 'Editing & Proofreading']},
      {'id': 'up-eng-gram', 'name': 'Grammar & Usage',
       'subStrands': ['Parts of Speech', 'Tenses', 'Punctuation & Spelling', 'Sentence Structures']},
    ],
  },
  {
    'id': 'up-kisw', 'name': 'Kiswahili', 'band': 'Grade 4-6', 'category': 'Core',
    'strands': [
      {'id': 'up-kisw-mawasiliano', 'name': 'Mawasiliano',
       'subStrands': ['Mazungumzo', 'Kusikiliza', 'Ufahamu wa Kusikia']},
      {'id': 'up-kisw-sarufi', 'name': 'Sarufi',
       'subStrands': ['Nomino', 'Vitenzi', 'Vivumishi', 'Viunganishi']},
      {'id': 'up-kisw-fasihi', 'name': 'Fasihi',
       'subStrands': ['Hadithi', 'Mashairi', 'Methali na Vitendawili', 'Tamthilia']},
      {'id': 'up-kisw-uandishi', 'name': 'Uandishi',
       'subStrands': ['Insha ya Ubunifu', 'Insha ya Hoja', 'Barua', 'Ripoti']},
    ],
  },
  {
    'id': 'up-math', 'name': 'Mathematics', 'band': 'Grade 4-6', 'category': 'Core',
    'strands': [
      {'id': 'up-math-num', 'name': 'Numbers & Number Sense',
       'subStrands': ['Whole Numbers', 'Fractions', 'Decimals', 'Percentages', 'Integers']},
      {'id': 'up-math-alg', 'name': 'Algebraic Thinking',
       'subStrands': ['Number Patterns', 'Simple Equations', 'Variables']},
      {'id': 'up-math-meas', 'name': 'Measurement',
       'subStrands': ['Length & Perimeter', 'Area', 'Volume', 'Mass', 'Time', 'Money']},
      {'id': 'up-math-geo', 'name': 'Geometry',
       'subStrands': ['Lines & Angles', '2D Shapes', '3D Shapes', 'Symmetry & Transformations']},
      {'id': 'up-math-data', 'name': 'Data Handling & Statistics',
       'subStrands': ['Data Collection', 'Tables & Charts', 'Mean/Mode/Median', 'Probability']},
    ],
  },
  {
    'id': 'up-sci', 'name': 'Science & Technology', 'band': 'Grade 4-6', 'category': 'Core',
    'strands': [
      {'id': 'up-sci-living', 'name': 'Living Things',
       'subStrands': ['Cell Structure', 'Plants & Photosynthesis', 'Animal Classification', 'Human Body Systems', 'Ecosystems & Food Chains']},
      {'id': 'up-sci-matter', 'name': 'Matter & Materials',
       'subStrands': ['States of Matter', 'Properties of Materials', 'Mixtures & Solutions', 'Chemical Changes']},
      {'id': 'up-sci-energy', 'name': 'Energy',
       'subStrands': ['Light', 'Sound', 'Heat', 'Electricity', 'Magnetism', 'Simple Machines']},
      {'id': 'up-sci-earth', 'name': 'Earth & Space',
       'subStrands': ['Soil', 'Rocks & Minerals', 'Weather & Water Cycle', 'Solar System']},
      {'id': 'up-sci-tech', 'name': 'Technology & Innovation',
       'subStrands': ['ICT Basics', 'Simple Inventions', 'Digital Literacy']},
    ],
  },
  {
    'id': 'up-ss', 'name': 'Social Studies', 'band': 'Grade 4-6', 'category': 'Core',
    'strands': [
      {'id': 'up-ss-citizen', 'name': 'Citizenship',
       'subStrands': ['Rights & Responsibilities', 'National Symbols', 'Devolution & Government', 'Democracy']},
      {'id': 'up-ss-hist', 'name': 'History & Culture',
       'subStrands': ['Pre-Colonial Kenya', 'Colonial Period', 'Independence & Post-Colonial', 'Cultural Heritage']},
      {'id': 'up-ss-geo', 'name': 'Geography',
       'subStrands': ['Maps & Direction', 'Physical Features', 'Climate Zones', 'Natural Resources']},
      {'id': 'up-ss-econ', 'name': 'Economics & Environment',
       'subStrands': ['Economic Activities', 'Trade', 'Environmental Conservation']},
    ],
  },
  {
    'id': 'up-re', 'name': 'Religious Education', 'band': 'Grade 4-6', 'category': 'Core',
    'strands': [
      {'id': 'up-re-scripture', 'name': 'Scriptures & Teachings',
       'subStrands': ['Biblical / Quran / Hindu Texts', 'Parables & Stories', 'Moral Lessons from Scriptures']},
      {'id': 'up-re-moral', 'name': 'Moral Philosophy',
       'subStrands': ['Integrity', 'Social Justice', 'Environmental Stewardship']},
      {'id': 'up-re-faith', 'name': 'Faith Practices',
       'subStrands': ['Worship Forms', 'Religious Celebrations', 'Community Service']},
    ],
  },
  {
    'id': 'up-agri', 'name': 'Agriculture', 'band': 'Grade 4-6', 'category': 'Core',
    'strands': [
      {'id': 'up-agri-crop', 'name': 'Crop Production',
       'subStrands': ['Soil Preparation', 'Planting & Transplanting', 'Crop Nutrition', 'Pest & Disease Control', 'Harvesting']},
      {'id': 'up-agri-animal', 'name': 'Animal Production',
       'subStrands': ['Types of Farm Animals', 'Animal Feeds & Nutrition', 'Animal Health', 'Products & Uses']},
      {'id': 'up-agri-env', 'name': 'Environmental Conservation',
       'subStrands': ['Soil Conservation', 'Water Harvesting', 'Agro-forestry']},
    ],
  },
  {
    'id': 'up-creative', 'name': 'Creative Arts', 'band': 'Grade 4-6', 'category': 'Core',
    'strands': [
      {'id': 'up-creative-visual', 'name': 'Visual Arts',
       'subStrands': ['Drawing & Painting', 'Printmaking', 'Sculpture & Modeling', 'Textile Art']},
      {'id': 'up-creative-music', 'name': 'Music',
       'subStrands': ['Vocal Music', 'Instrumental Music', 'Music Appreciation', 'Composition']},
      {'id': 'up-creative-drama', 'name': 'Drama & Theatre',
       'subStrands': ['Mime & Movement', 'Scripted Drama', 'Improvisation', 'Puppetry']},
    ],
  },
  {
    'id': 'up-phe', 'name': 'Physical & Health Education', 'band': 'Grade 4-6', 'category': 'Core',
    'strands': [
      {'id': 'up-phe-athletics', 'name': 'Athletics',
       'subStrands': ['Running Events', 'Jumping Events', 'Throwing Events']},
      {'id': 'up-phe-team', 'name': 'Team Sports',
       'subStrands': ['Football', 'Netball', 'Basketball', 'Volleyball', 'Handball']},
      {'id': 'up-phe-fitness', 'name': 'Physical Fitness',
       'subStrands': ['Strength Training', 'Flexibility', 'Endurance', 'Coordination']},
      {'id': 'up-phe-health', 'name': 'Health Education',
       'subStrands': ['Nutrition', 'Substance Abuse Prevention', 'Reproductive Health Basics', 'First Aid']},
    ],
  },

  // ══════════════════════════════════════════════════════════════════
  // JUNIOR SECONDARY — CORE  (Grade 7 – 9)
  // ══════════════════════════════════════════════════════════════════
  {
    'id': 'js-eng', 'name': 'English', 'band': 'Grade 7-9', 'category': 'Core',
    'strands': [
      {'id': 'js-eng-oral', 'name': 'Oral Skills',
       'subStrands': ['Listening Comprehension', 'Speaking & Expression', 'Debate & Discussion', 'Oral Literature']},
      {'id': 'js-eng-read', 'name': 'Reading',
       'subStrands': ['Comprehension Strategies', 'Literary Texts', 'Non-Literary Texts', 'Critical Analysis']},
      {'id': 'js-eng-write', 'name': 'Writing',
       'subStrands': ['Narrative Writing', 'Expository Writing', 'Argumentative Writing', 'Functional Writing']},
      {'id': 'js-eng-lit', 'name': 'Literature',
       'subStrands': ['Prose', 'Poetry', 'Drama', 'Oral Literature Genres']},
      {'id': 'js-eng-gram', 'name': 'Grammar & Language Use',
       'subStrands': ['Tenses & Aspects', 'Sentence Types', 'Punctuation', 'Vocabulary Development']},
    ],
  },
  {
    'id': 'js-kisw', 'name': 'Kiswahili', 'band': 'Grade 7-9', 'category': 'Core',
    'strands': [
      {'id': 'js-kisw-lugha', 'name': 'Lugha',
       'subStrands': ['Sarufi ya Ngeli', 'Vitenzi & Wakati', 'Viunganishi', 'Mazungumzo Rasmi']},
      {'id': 'js-kisw-fasihi', 'name': 'Fasihi',
       'subStrands': ['Riwaya', 'Ushairi', 'Tamthilia', 'Fasihi Simulizi']},
      {'id': 'js-kisw-uandishi', 'name': 'Uandishi',
       'subStrands': ['Insha ya Hoja', 'Insha ya Ubunifu', 'Barua Rasmi & Zisizo Rasmi', 'Ripoti & Taarifa']},
    ],
  },
  {
    'id': 'js-math', 'name': 'Mathematics', 'band': 'Grade 7-9', 'category': 'Core',
    'strands': [
      {'id': 'js-math-num', 'name': 'Numbers',
       'subStrands': ['Integers', 'Rational & Irrational Numbers', 'Powers & Roots', 'Percentage/Ratio/Proportion', 'Number Bases']},
      {'id': 'js-math-alg', 'name': 'Algebra',
       'subStrands': ['Algebraic Expressions', 'Linear Equations & Inequalities', 'Simultaneous Equations', 'Quadratic Expressions', 'Functions & Graphs']},
      {'id': 'js-math-geo', 'name': 'Geometry',
       'subStrands': ['Geometric Constructions', 'Angles & Triangles', 'Polygons', 'Circle Theorems', 'Transformations']},
      {'id': 'js-math-meas', 'name': 'Measurement',
       'subStrands': ['Perimeter & Area', 'Surface Area & Volume', 'Speed, Distance & Time', 'Scale Drawing']},
      {'id': 'js-math-trig', 'name': 'Trigonometry',
       'subStrands': ['Trigonometric Ratios', 'The Unit Circle', 'Angles of Elevation & Depression']},
      {'id': 'js-math-stats', 'name': 'Statistics & Probability',
       'subStrands': ['Data Collection & Display', 'Central Tendency', 'Probability', 'Statistical Inference']},
    ],
  },
  {
    'id': 'js-sci', 'name': 'Integrated Science', 'band': 'Grade 7-9', 'category': 'Core',
    'strands': [
      {'id': 'js-sci-bio', 'name': 'Biology Concepts',
       'subStrands': ['Cell Biology', 'Organisation of Life', 'Nutrition in Plants', 'Nutrition in Animals', 'Transport in Living Things', 'Respiration', 'Excretion', 'Coordination & Response', 'Reproduction', 'Genetics & Ecology']},
      {'id': 'js-sci-chem', 'name': 'Chemistry Concepts',
       'subStrands': ['Matter & Classification', 'Atomic Structure', 'Periodic Table', 'Chemical Bonding', 'Chemical Reactions', 'Acids, Bases & Salts', 'Electrolysis', 'Organic Chemistry Basics']},
      {'id': 'js-sci-phys', 'name': 'Physics Concepts',
       'subStrands': ['Measurements & Units', 'Forces & Motion', 'Work, Energy & Power', 'Fluid Mechanics', 'Heat Transfer', 'Waves — Light', 'Waves — Sound', 'Electricity', 'Magnetism & Electromagnetism']},
    ],
  },
  {
    'id': 'js-ss', 'name': 'Social Studies', 'band': 'Grade 7-9', 'category': 'Core',
    'strands': [
      {'id': 'js-ss-citizen', 'name': 'Citizenship & Governance',
       'subStrands': ['Constitutional Structures', 'County Government', 'National Government', 'Human Rights', 'Elections & Democracy']},
      {'id': 'js-ss-hist', 'name': 'History',
       'subStrands': ['Pre-Colonial History', 'Scramble & Partition of Africa', 'Colonial Administration', 'Nationalism & Independence', 'Post-Independence Kenya & Africa']},
      {'id': 'js-ss-geo', 'name': 'Geography',
       'subStrands': ['Map Reading & Interpretation', 'Physical Geography of Kenya & Africa', 'Population & Settlement', 'Natural Resources & Conservation', 'Climate & Weather']},
      {'id': 'js-ss-econ', 'name': 'Economics',
       'subStrands': ['Economic Systems', 'Trade (Local/Regional/International)', 'Agriculture & Industry', 'Financial Literacy']},
    ],
  },
  {
    'id': 'js-re', 'name': 'Religious Education', 'band': 'Grade 7-9', 'category': 'Core',
    'strands': [
      {'id': 'js-re-scripture', 'name': 'Scriptures & Traditions',
       'subStrands': ['Old Testament / Quran / Upanishads', 'New Testament / Hadith', 'Moral Standards from Texts']},
      {'id': 'js-re-moral', 'name': 'Moral Philosophy & Ethics',
       'subStrands': ['Social Justice', 'Human Dignity', 'Environmental Ethics', 'Bioethics']},
      {'id': 'js-re-comparative', 'name': 'Comparative Religion',
       'subStrands': ['Major World Religions', 'African Traditional Religion', 'Religion & Society', 'Religious Diversity & Tolerance']},
    ],
  },

  // ══════════════════════════════════════════════════════════════════
  // JUNIOR SECONDARY — ELECTIVE / PATHWAY  (Grade 7 – 9)
  // ══════════════════════════════════════════════════════════════════
  {
    'id': 'js-pts', 'name': 'Pre-Technical Studies', 'band': 'Grade 7-9', 'category': 'Elective',
    'strands': [
      {'id': 'js-pts-wood', 'name': 'Wood Technology',
       'subStrands': ['Tools & Safety', 'Joints & Structures', 'Finishing & Painting', 'Project Work']},
      {'id': 'js-pts-metal', 'name': 'Metal Technology',
       'subStrands': ['Tools & Safety', 'Cutting & Shaping', 'Joining Methods', 'Project Work']},
      {'id': 'js-pts-electrical', 'name': 'Electrical Technology',
       'subStrands': ['Basic Circuits', 'Conductors & Insulators', 'Simple Wiring', 'Fault Finding']},
      {'id': 'js-pts-robotics', 'name': 'Basic Robotics',
       'subStrands': ['Introduction to Robotics', 'Simple Machines', 'Coding Fundamentals', 'Prototype Design']},
    ],
  },
  {
    'id': 'js-agri', 'name': 'Agriculture', 'band': 'Grade 7-9', 'category': 'Elective',
    'strands': [
      {'id': 'js-agri-crop', 'name': 'Crop Science',
       'subStrands': ['Soil Science', 'Crop Husbandry', 'Irrigation', 'Pest & Disease Management', 'Post-Harvest Handling']},
      {'id': 'js-agri-animal', 'name': 'Animal Production',
       'subStrands': ['Livestock Management', 'Poultry Production', 'Aquaculture', 'Bee Keeping']},
      {'id': 'js-agri-business', 'name': 'Agribusiness',
       'subStrands': ['Farm Planning', 'Record Keeping', 'Marketing Agricultural Products']},
    ],
  },
  {
    'id': 'js-business', 'name': 'Business Studies', 'band': 'Grade 7-9', 'category': 'Elective',
    'strands': [
      {'id': 'js-biz-entrep', 'name': 'Entrepreneurship',
       'subStrands': ['Business Idea Generation', 'Business Planning', 'Risk & Innovation', 'Starting a Business']},
      {'id': 'js-biz-fin', 'name': 'Financial Literacy',
       'subStrands': ['Budgeting', 'Saving & Investment', 'Banking', 'Insurance Basics']},
      {'id': 'js-biz-comm', 'name': 'Business Communication',
       'subStrands': ['Business Letters', 'Memos & Reports', 'Customer Relations', 'Digital Communication']},
    ],
  },
  {
    'id': 'js-cs', 'name': 'Computer Science', 'band': 'Grade 7-9', 'category': 'Elective',
    'strands': [
      {'id': 'js-cs-algo', 'name': 'Algorithms & Problem Solving',
       'subStrands': ['Computational Thinking', 'Flowcharts', 'Pseudocode', 'Algorithm Design']},
      {'id': 'js-cs-prog', 'name': 'Programming',
       'subStrands': ['Intro to Python/Scratch', 'Variables & Data Types', 'Control Structures', 'Functions', 'Simple Programs']},
      {'id': 'js-cs-data', 'name': 'Data & Information',
       'subStrands': ['Data Representation', 'Databases', 'Spreadsheets', 'Data Analysis']},
      {'id': 'js-cs-net', 'name': 'Networks & Cyber Security',
       'subStrands': ['Internet & Networking Basics', 'Cyber Safety', 'Digital Citizenship', 'Cloud Computing']},
    ],
  },
  {
    'id': 'js-vpa', 'name': 'Visual & Performing Arts', 'band': 'Grade 7-9', 'category': 'Elective',
    'strands': [
      {'id': 'js-vpa-music', 'name': 'Music',
       'subStrands': ['Music Theory', 'Vocal Performance', 'Instrumental Performance', 'Composition', 'Kenyan & African Heritage']},
      {'id': 'js-vpa-art', 'name': 'Fine Art & Design',
       'subStrands': ['Drawing & Sketching', 'Painting Techniques', 'Graphic Design', 'Sculpture & Ceramics', 'Textile Design']},
      {'id': 'js-vpa-drama', 'name': 'Drama & Theatre Arts',
       'subStrands': ['Acting & Characterisation', 'Scriptwriting', 'Stage Design', 'Film & Media Basics']},
    ],
  },
  {
    'id': 'js-sports', 'name': 'Sports Science', 'band': 'Grade 7-9', 'category': 'Elective',
    'strands': [
      {'id': 'js-sports-perf', 'name': 'Sports Performance',
       'subStrands': ['Athletics Techniques', 'Team Sports Tactics', 'Individual Sports', 'Officiating & Rules']},
      {'id': 'js-sports-coach', 'name': 'Coaching & Leadership',
       'subStrands': ['Coaching Principles', 'Team Management', 'Sports Psychology', 'Leadership in Sports']},
      {'id': 'js-sports-sci', 'name': 'Sports Science',
       'subStrands': ['Anatomy for Sports', 'Sports Nutrition', 'Injury Prevention & First Aid', 'Fitness Testing']},
    ],
  },
];
