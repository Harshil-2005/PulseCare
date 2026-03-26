class FollowUpQuestion {
  final String id;
  final String question;
  final List<FollowUpOption> options;

  const FollowUpQuestion({
    required this.id,
    required this.question,
    this.options = const <FollowUpOption>[],
  });
}

class FollowUpOption {
  final String id;
  final String label;
  final List<String> keywords;

  const FollowUpOption({
    required this.id,
    required this.label,
    required this.keywords,
  });
}

class SymptomData {
  final String id;
  final List<String> keywords;
  final List<FollowUpQuestion> followUps;
  final String specialty;
  final String category;

  const SymptomData({
    required this.id,
    required this.keywords,
    required this.followUps,
    required this.specialty,
    required this.category,
  });
}

const List<SymptomData> triageSymptoms = [
  SymptomData(
    id: 'fever',
    keywords: [
      'fever',
      'high fever',
      'high temperature',
      'raised temperature',
      'elevated temperature',
      'elevated temp',
      'high temp',
      'temperature',
      'temp',
      'pyrexia',
      'feverish',
      'feverishness',
      'running temperature',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'fever_associated_symptoms',
        question: 'Do you have chills, body aches, or a sore throat?',
        options: [
          FollowUpOption(
            id: 'fever_do_you_also_have_chills',
            label: 'Chills',
            keywords: ['chills', 'chill'],
          ),
          FollowUpOption(
            id: 'fever_do_you_also_have_body_aches',
            label: 'Body aches',
            keywords: ['body aches', 'body ache', 'aches', 'achy'],
          ),
          FollowUpOption(
            id: 'fever_do_you_also_have_sore_throat',
            label: 'Sore throat',
            keywords: ['sore throat', 'throat pain', 'throat'],
          ),
        ],
      ),
      FollowUpQuestion(
        id: 'fever_have_you_taken_any_medicine_and_did_it_reduce_the_fever',
        question: 'Have you taken any medicine and did it reduce the fever?',
      ),
    ],
    specialty: 'General Physician',
    category: 'Respiratory',
  ),
  SymptomData(
    id: 'cough',
    keywords: [
      'cough',
      'coughing',
      'cough fits',
      'hacking cough',
      'dry cough',
      'wet cough',
      'productive cough',
      'chesty cough',
      'phlegm',
      'mucus cough',
      'persistent cough',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'cough_cough_type',
        question: 'Is your cough dry or with phlegm?',
        options: [
          FollowUpOption(
            id: 'cough_is_your_cough_dry',
            label: 'Dry cough',
            keywords: ['dry', 'dry cough'],
          ),
          FollowUpOption(
            id: 'cough_is_your_with_phlegm',
            label: 'With phlegm',
            keywords: ['phlegm', 'mucus', 'productive'],
          ),
        ],
      ),
      FollowUpQuestion(
        id: 'cough_do_you_have_fever',
        question: 'Do you have fever?',
      ),
      FollowUpQuestion(
        id: 'cough_do_you_have_wheezing',
        question: 'Do you have wheezing?',
      ),
      FollowUpQuestion(
        id: 'cough_do_you_have_chest_discomfort_too',
        question: 'Do you have chest discomfort too?',
      ),
    ],
    specialty: 'Pulmonologist',
    category: 'Respiratory',
  ),
  SymptomData(
    id: 'headache',
    keywords: [
      'headache',
      'head ache',
      'head ace',
      'head hurts',
      'head pressure',
      'migraine',
      'head pain',
      'temple pain',
      'throbbing head',
      'splitting headache',
      'tension headache',
      'cluster headache',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'headache_where_is_the_pain_located',
        question: 'Where is the pain located?',
      ),
      FollowUpQuestion(
        id: 'headache_how_severe_is_the_pain',
        question: 'On a scale of 1-10, how severe is it?',
      ),
      FollowUpQuestion(
        id: 'headache_associated_symptoms',
        question: 'Do you have nausea, light sensitivity, or vision changes?',
        options: [
          FollowUpOption(
            id: 'headache_is_the_headache_associated_with_nausea',
            label: 'Nausea',
            keywords: ['nausea', 'nauseous', 'queasy'],
          ),
          FollowUpOption(
            id: 'headache_is_the_light_sensitivity',
            label: 'Light sensitivity',
            keywords: [
              'light sensitivity',
              'light sensitive',
              'photophobia',
              'bright light',
            ],
          ),
          FollowUpOption(
            id: 'headache_is_the_vision_changes',
            label: 'Vision changes',
            keywords: [
              'vision changes',
              'vision change',
              'blurred vision',
              'blurry',
              'vision',
            ],
          ),
        ],
      ),
    ],
    specialty: 'Neurologist',
    category: 'Neurological',
  ),
  SymptomData(
    id: 'chest_pain',
    keywords: [
      'chest pain',
      'chest ache',
      'chest discomfort',
      'tight chest',
      'chest tightness',
      'tightness in chest',
      'pressure in chest',
      'chest pressure',
      'chest heaviness',
      'pain in chest',
      'heart pain',
      'chest burning',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'chest_pain_pain_quality',
        question: 'Is the pain sharp, pressure-like, or burning?',
        options: [
          FollowUpOption(
            id: 'chest_pain_is_the_pain_sharp',
            label: 'Sharp pain',
            keywords: ['sharp'],
          ),
          FollowUpOption(
            id: 'chest_pain_is_the_pressurelike',
            label: 'Pressure-like',
            keywords: ['pressure', 'pressure-like', 'tight', 'tightness'],
          ),
          FollowUpOption(
            id: 'chest_pain_is_the_burning',
            label: 'Burning',
            keywords: ['burning', 'burn'],
          ),
        ],
      ),
      FollowUpQuestion(
        id: 'chest_pain_spread_locations',
        question: 'Does it spread to your arm, jaw, back, or shoulder?',
        options: [
          FollowUpOption(
            id: 'chest_pain_does_it_spread_to_your_arm',
            label: 'Spread to arm',
            keywords: ['arm', 'left arm', 'right arm'],
          ),
          FollowUpOption(
            id: 'chest_pain_does_it_jaw',
            label: 'Spread to jaw',
            keywords: ['jaw'],
          ),
          FollowUpOption(
            id: 'chest_pain_does_it_back',
            label: 'Spread to back',
            keywords: ['back'],
          ),
          FollowUpOption(
            id: 'chest_pain_does_it_shoulder',
            label: 'Spread to shoulder',
            keywords: ['shoulder'],
          ),
        ],
      ),
      FollowUpQuestion(
        id: 'chest_pain_does_it_worsen_with_exertion',
        question: 'Does it worsen with exertion?',
      ),
      FollowUpQuestion(
        id: 'chest_pain_does_it_breathing',
        question: 'Does it worsen with deep breathing?',
      ),
    ],
    specialty: 'Cardiologist',
    category: 'Cardiac',
  ),
  SymptomData(
    id: 'shortness_of_breath',
    keywords: [
      'shortness of breath',
      'breathlessness',
      'difficulty breathing',
      'breathing problem',
      'breathing problems',
      'problem breathing',
      'problems breathing',
      'breathing issue',
      'breath problem',
      'hard to breathe',
      'hard breathing',
      'struggling to breathe',
      'cant breathe',
      'cannot breathe',
      'out of breath',
      'trouble breathing',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'shortness_of_breath_did_this_start_suddenly_or_gradually',
        question: 'Did this start suddenly or gradually?',
      ),
      FollowUpQuestion(
        id: 'shortness_of_breath_are_you_short_of_breath_at_rest_or_only_while_moving',
        question: 'Are you short of breath at rest or only while moving?',
      ),
      FollowUpQuestion(
        id: 'shortness_of_breath_do_you_also_have_chest_pain',
        question: 'Do you also have chest pain?',
      ),
      FollowUpQuestion(
        id: 'shortness_of_breath_do_you_also_have_cough',
        question: 'Do you also have cough?',
      ),
      FollowUpQuestion(
        id: 'shortness_of_breath_do_you_also_have_wheezing',
        question: 'Do you also have wheezing?',
      ),
    ],
    specialty: 'Pulmonologist',
    category: 'Respiratory',
  ),
  SymptomData(
    id: 'rash',
    keywords: [
      'rash',
      'rashes',
      'skin rash',
      'red rash',
      'red patches',
      'skin patches',
      'red spots',
      'itchy skin',
      'hives',
      'skin eruption',
      'skin allergy',
      'skin irritation',
      'itchy rash',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'rash_where_on_your_body_is_the_rash_and_when_did_it_begin',
        question: 'Where on your body is the rash and when did it begin?',
      ),
      FollowUpQuestion(
        id: 'rash_symptom_details',
        question: 'Is the rash itchy, painful, or spreading?',
        options: [
          FollowUpOption(
            id: 'rash_is_it_itchy',
            label: 'Itchy',
            keywords: ['itchy', 'itching', 'itch'],
          ),
          FollowUpOption(
            id: 'rash_is_it_painful',
            label: 'Painful',
            keywords: ['painful', 'pain', 'tender'],
          ),
          FollowUpOption(
            id: 'rash_is_it_spreading',
            label: 'Spreading',
            keywords: ['spreading', 'spread'],
          ),
        ],
      ),
      FollowUpQuestion(
        id: 'rash_did_you_recently_use_a_new_food_medicine_soap_or_cosmetic',
        question:
            'Did you recently use a new food, medicine, soap, or cosmetic?',
      ),
    ],
    specialty: 'Dermatologist',
    category: 'Dermatological',
  ),
  SymptomData(
    id: 'stomach_pain',
    keywords: [
      'stomach pain',
      'abdominal pain',
      'abdominal ache',
      'tummy pain',
      'tummy ache',
      'belly pain',
      'belly ache',
      'gastric pain',
      'abdomen pain',
      'stomach ache',
      'stomachache',
      'stomach cramps',
      'abdominal cramps',
      'stomach cramp',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'stomach_pain_where_exactly_is_the_pain_in_your_abdomen',
        question: 'Where exactly is the pain in your abdomen?',
      ),
      FollowUpQuestion(
        id: 'stomach_pain_is_it_related_to_meals',
        question: 'Is it related to meals?',
      ),
      FollowUpQuestion(
        id: 'stomach_pain_is_it_vomiting',
        question: 'Is it vomiting?',
      ),
      FollowUpQuestion(
        id: 'stomach_pain_is_it_diarrhea',
        question: 'Is it diarrhea?',
      ),
      FollowUpQuestion(
        id: 'stomach_pain_is_it_constipation',
        question: 'Is it constipation?',
      ),
      FollowUpQuestion(
        id: 'stomach_pain_how_severe_is_the_pain',
        question: 'On a scale of 1-10, how severe is it?',
      ),
      FollowUpQuestion(
        id: 'stomach_pain_is_it_constant_or_cramping',
        question: 'Is it constant or cramping?',
      ),
    ],
    specialty: 'Gastroenterologist',
    category: 'Digestive',
  ),
  SymptomData(
    id: 'back_pain',
    keywords: [
      'back pain',
      'backache',
      'lower back pain',
      'upper back pain',
      'lower back ache',
      'upper back ache',
      'back ache',
      'spine pain',
      'lumbar pain',
      'back soreness',
      'sore back',
      'stiff back',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'back_pain_location',
        question: 'Is the pain in the lower back, middle back, or upper back?',
        options: [
          FollowUpOption(
            id: 'back_pain_is_the_pain_in_the_lower',
            label: 'Lower back',
            keywords: ['lower back', 'low back'],
          ),
          FollowUpOption(
            id: 'back_pain_is_the_middle',
            label: 'Middle back',
            keywords: ['middle back', 'mid back'],
          ),
          FollowUpOption(
            id: 'back_pain_is_the_upper_back',
            label: 'Upper back',
            keywords: ['upper back'],
          ),
        ],
      ),
      FollowUpQuestion(
        id: 'back_pain_did_it_start_after_lifting_injury_or_prolonged_sitting',
        question: 'Did it start after lifting, injury, or prolonged sitting?',
      ),
      FollowUpQuestion(
        id: 'back_pain_do_you_have_numbness',
        question: 'Do you have numbness?',
      ),
      FollowUpQuestion(
        id: 'back_pain_do_you_have_tingling',
        question: 'Do you have tingling?',
      ),
      FollowUpQuestion(
        id: 'back_pain_do_you_have_weakness_in_your_legs',
        question: 'Do you have weakness in your legs?',
      ),
    ],
    specialty: 'Orthopedic',
    category: 'Musculoskeletal',
  ),
  SymptomData(
    id: 'dizziness',
    keywords: [
      'dizziness',
      'dizzy',
      'lightheaded',
      'light headed',
      'woozy',
      'faint',
      'near fainting',
      'unsteady',
      'off balance',
      'vertigo',
      'spinning sensation',
      'feeling faint',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'dizziness_do_you_feel_spinning_imbalance_or_nearfainting',
        question: 'Do you feel spinning, imbalance, or near-fainting?',
      ),
      FollowUpQuestion(
        id: 'dizziness_associated_symptoms',
        question: 'Do you also have hearing changes, headache, or nausea?',
        options: [
          FollowUpOption(
            id: 'dizziness_do_you_also_have_hearing_changes',
            label: 'Hearing changes',
            keywords: ['hearing', 'hearing loss', 'ringing', 'tinnitus'],
          ),
          FollowUpOption(
            id: 'dizziness_do_you_also_have_headache',
            label: 'Headache',
            keywords: ['headache', 'head ache', 'head pain'],
          ),
          FollowUpOption(
            id: 'dizziness_do_you_also_have_nausea',
            label: 'Nausea',
            keywords: ['nausea', 'nauseous', 'queasy'],
          ),
        ],
      ),
    ],
    specialty: 'Neurologist',
    category: 'Neurological',
  ),
  SymptomData(
    id: 'fatigue',
    keywords: [
      'fatigue',
      'tiredness',
      'tired',
      'very tired',
      'exhausted',
      'fatigued',
      'low energy',
      'no energy',
      'weakness',
      'always tired',
      'sleepy',
      'worn out',
      'lethargy',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'fatigue_is_fatigue_affecting_daily_activities_or_sleep_quality',
        question: 'Is fatigue affecting daily activities or sleep quality?',
      ),
      FollowUpQuestion(
        id: 'fatigue_associated_symptoms',
        question: 'Do you also have weight change, fever, or mood symptoms?',
        options: [
          FollowUpOption(
            id: 'fatigue_do_you_also_have_weight_change',
            label: 'Weight change',
            keywords: ['weight change', 'weight loss', 'weight gain'],
          ),
          FollowUpOption(
            id: 'fatigue_do_you_also_have_fever',
            label: 'Fever',
            keywords: ['fever', 'temperature', 'temp'],
          ),
          FollowUpOption(
            id: 'fatigue_do_you_also_have_mood_symptoms',
            label: 'Mood symptoms',
            keywords: ['mood', 'low mood', 'anxiety', 'depression'],
          ),
        ],
      ),
    ],
    specialty: 'General Physician',
    category: 'General',
  ),
  SymptomData(
    id: 'sore_throat',
    keywords: [
      'sore throat',
      'throat sore',
      'throat pain',
      'painful throat',
      'throat soreness',
      'throat irritation',
      'scratchy throat',
      'throat hurts',
      'throat hurts when swallowing',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'sore_throat_associated_symptoms',
        question: 'Do you also have fever, cough, or swollen glands?',
        options: [
          FollowUpOption(
            id: 'sore_throat_do_you_also_have_fever',
            label: 'Fever',
            keywords: ['fever', 'temperature', 'temp'],
          ),
          FollowUpOption(
            id: 'sore_throat_do_you_also_have_cough',
            label: 'Cough',
            keywords: ['cough', 'coughing'],
          ),
          FollowUpOption(
            id: 'sore_throat_do_you_also_have_swollen_glands',
            label: 'Swollen glands',
            keywords: ['swollen glands', 'glands', 'neck glands'],
          ),
        ],
      ),
      FollowUpQuestion(
        id: 'sore_throat_is_swallowing_painful_or_difficult',
        question: 'Is swallowing painful or difficult?',
      ),
    ],
    specialty: 'ENT Specialist',
    category: 'ENT',
  ),
  SymptomData(
    id: 'runny_nose',
    keywords: [
      'runny nose',
      'runny nostril',
      'nasal discharge',
      'nasal drip',
      'post nasal drip',
      'dripping nose',
      'sneezing',
      'congested nose',
      'blocked nose',
      'stuffy nose',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'runny_nose_discharge_color',
        question: 'Is the discharge clear, yellow, or green?',
        options: [
          FollowUpOption(
            id: 'runny_nose_is_the_discharge_clear',
            label: 'Clear discharge',
            keywords: ['clear'],
          ),
          FollowUpOption(
            id: 'runny_nose_is_the_yellow',
            label: 'Yellow discharge',
            keywords: ['yellow'],
          ),
          FollowUpOption(
            id: 'runny_nose_is_the_green',
            label: 'Green discharge',
            keywords: ['green'],
          ),
        ],
      ),
      FollowUpQuestion(
        id: 'runny_nose_do_you_also_have_sneezing',
        question: 'Do you also have sneezing?',
      ),
      FollowUpQuestion(
        id: 'runny_nose_do_you_also_have_fever',
        question: 'Do you also have fever?',
      ),
      FollowUpQuestion(
        id: 'runny_nose_do_you_also_have_sinus_pressure',
        question: 'Do you also have sinus pressure?',
      ),
    ],
    specialty: 'ENT Specialist',
    category: 'ENT',
  ),
  SymptomData(
    id: 'vomiting',
    keywords: [
      'vomiting',
      'throwing up',
      'throw up',
      'vomited',
      'retching',
      'heaving',
      'nausea and vomiting',
      'puking',
      'emesis',
      'vomit',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'vomiting_associated_symptoms',
        question:
            'Do you have abdominal pain, diarrhea, or trouble keeping fluids down?',
        options: [
          FollowUpOption(
            id: 'vomiting_do_you_also_have_abdominal_pain',
            label: 'Abdominal pain',
            keywords: ['abdominal pain', 'stomach pain', 'belly pain'],
          ),
          FollowUpOption(
            id: 'vomiting_do_you_also_have_diarrhea',
            label: 'Diarrhea',
            keywords: ['diarrhea', 'loose stools', 'watery stool'],
          ),
          FollowUpOption(
            id: 'vomiting_are_you_able_to_keep_fluids_down',
            label: 'Trouble keeping fluids down',
            keywords: ['fluids', 'water', 'keep down', 'unable to keep'],
          ),
        ],
      ),
    ],
    specialty: 'Gastroenterologist',
    category: 'Digestive',
  ),
  SymptomData(
    id: 'diarrhea',
    keywords: [
      'diarrhea',
      'loose stools',
      'loose stool',
      'loose motion',
      'loose motions',
      'watery stool',
      'watery stools',
      'frequent stools',
      'frequent bowel movements',
      'bowel movements',
      'the runs',
      'stomach upset',
      'runny stool',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'diarrhea_stool_changes',
        question: 'Any blood or mucus in the stool?',
        options: [
          FollowUpOption(
            id: 'diarrhea_are_there_signs_of_blood',
            label: 'Blood in stool',
            keywords: ['blood', 'bloody'],
          ),
          FollowUpOption(
            id: 'diarrhea_are_there_mucus_in_the_stool',
            label: 'Mucus in stool',
            keywords: ['mucus', 'mucous'],
          ),
        ],
      ),
      FollowUpQuestion(
        id: 'diarrhea_do_you_also_have_fever',
        question: 'Do you also have fever?',
      ),
      FollowUpQuestion(
        id: 'diarrhea_associated_symptoms',
        question: 'Do you also have vomiting or abdominal pain?',
        options: [
          FollowUpOption(
            id: 'diarrhea_do_you_also_have_vomiting',
            label: 'Vomiting',
            keywords: ['vomit', 'vomiting'],
          ),
          FollowUpOption(
            id: 'diarrhea_do_you_also_have_abdominal_pain',
            label: 'Abdominal pain',
            keywords: ['abdominal pain', 'stomach pain', 'belly pain'],
          ),
        ],
      ),
    ],
    specialty: 'Gastroenterologist',
    category: 'Digestive',
  ),
  SymptomData(
    id: 'constipation',
    keywords: [
      'constipation',
      'constipated',
      'hard stools',
      'hard stool',
      'difficulty passing stool',
      'difficulty pooping',
      'hard to poop',
      'no bowel movement',
      'no bowel movements',
      'no stool',
      'not able to poop',
      'blocked stool',
      'blocked bowel',
      'infrequent stools',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'constipation_symptoms',
        question: 'Do you have abdominal pain or bloating?',
        options: [
          FollowUpOption(
            id: 'constipation_do_you_have_abdominal_pain',
            label: 'Abdominal pain',
            keywords: ['abdominal pain', 'stomach pain', 'belly pain'],
          ),
          FollowUpOption(
            id: 'constipation_do_you_have_bloating',
            label: 'Bloating',
            keywords: ['bloating', 'bloated', 'gas'],
          ),
        ],
      ),
      FollowUpQuestion(
        id: 'constipation_have_you_tried_any_laxatives_or_dietary_changes',
        question: 'Have you tried any laxatives or dietary changes?',
      ),
    ],
    specialty: 'Gastroenterologist',
    category: 'Digestive',
  ),
  SymptomData(
    id: 'joint_pain',
    keywords: [
      'joint pain',
      'painful joints',
      'swollen joints',
      'joint ache',
      'joint aches',
      'aching joints',
      'sore joints',
      'joint soreness',
      'joint stiffness',
      'stiff joints',
      'arthritis pain',
      'knee pain',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'joint_pain_do_the_joints_feel_swollen_warm_or_stiff',
        question: 'Do the joints feel swollen, warm, or stiff?',
      ),
      FollowUpQuestion(
        id: 'joint_pain_did_the_pain_start_after_injury_or_exertion',
        question: 'Did the pain start after injury or exertion?',
      ),
    ],
    specialty: 'Orthopedic',
    category: 'Musculoskeletal',
  ),
  SymptomData(
    id: 'ear_pain',
    keywords: [
      'ear pain',
      'ear ache',
      'earache',
      'pain in ear',
      'painful ear',
      'ear pressure',
      'ear hurts',
      'ear discomfort',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'ear_pain_which_ear_is_affected',
        question: 'Which ear is affected (left, right, or both)?',
      ),
      FollowUpQuestion(
        id: 'ear_pain_associated_symptoms',
        question: 'Do you have hearing loss, discharge, or fever?',
        options: [
          FollowUpOption(
            id: 'ear_pain_do_you_have_hearing_loss',
            label: 'Hearing loss',
            keywords: ['hearing loss', 'hearing', 'muffled'],
          ),
          FollowUpOption(
            id: 'ear_pain_do_you_have_discharge',
            label: 'Discharge',
            keywords: ['discharge', 'drainage', 'fluid'],
          ),
          FollowUpOption(
            id: 'ear_pain_do_you_have_fever',
            label: 'Fever',
            keywords: ['fever', 'temperature', 'temp'],
          ),
        ],
      ),
      FollowUpQuestion(
        id: 'ear_pain_did_this_start_after_a_cold_or_swimming',
        question: 'Did this start after a cold or swimming?',
      ),
    ],
    specialty: 'ENT Specialist',
    category: 'ENT',
  ),
  SymptomData(
    id: 'eye_redness',
    keywords: [
      'red eye',
      'red eyes',
      'eye redness',
      'bloodshot eye',
      'bloodshot eyes',
      'irritated eye',
      'irritated eyes',
      'itchy eye',
      'itchy eyes',
      'watery eye',
      'watery eyes',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'eye_redness_is_one_eye_or_both_eyes_affected',
        question: 'Is one eye or both eyes affected?',
      ),
      FollowUpQuestion(
        id: 'eye_redness_symptoms',
        question: 'Do you have pain, discharge, or blurred vision?',
        options: [
          FollowUpOption(
            id: 'eye_redness_do_you_have_pain',
            label: 'Pain',
            keywords: ['pain', 'painful', 'sore'],
          ),
          FollowUpOption(
            id: 'eye_redness_do_you_have_discharge',
            label: 'Discharge',
            keywords: ['discharge', 'drainage', 'crusting'],
          ),
          FollowUpOption(
            id: 'eye_redness_do_you_have_blurred_vision',
            label: 'Blurred vision',
            keywords: ['blurred', 'blurry', 'vision'],
          ),
        ],
      ),
      FollowUpQuestion(
        id: 'eye_redness_have_you_been_exposed_to_allergens_or_dust',
        question: 'Have you been exposed to allergens or dust?',
      ),
    ],
    specialty: 'General Physician',
    category: 'Dermatological',
  ),
  SymptomData(
    id: 'skin_swelling',
    keywords: [
      'skin swelling',
      'swollen skin',
      'swelling',
      'swollen area',
      'swelling on skin',
      'puffy skin',
      'puffiness',
      'localized swelling',
      'skin lump',
      'raised bump',
      'skin bump',
      'lump',
      'bump',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'skin_swelling_where_is_the_swelling_and_when_did_it_start',
        question: 'Where is the swelling and when did it start?',
      ),
      FollowUpQuestion(
        id: 'skin_swelling_area_changes',
        question: 'Is the area red, warm, or painful?',
        options: [
          FollowUpOption(
            id: 'skin_swelling_is_the_area_red',
            label: 'Redness',
            keywords: ['red', 'redness'],
          ),
          FollowUpOption(
            id: 'skin_swelling_is_the_warm',
            label: 'Warmth',
            keywords: ['warm', 'warmth', 'hot'],
          ),
          FollowUpOption(
            id: 'skin_swelling_is_the_painful',
            label: 'Painful',
            keywords: ['pain', 'painful', 'tender'],
          ),
        ],
      ),
      FollowUpQuestion(
        id: 'skin_swelling_did_you_have_an_injury_bite_or_new_medication',
        question: 'Did you have an injury, bite, or new medication?',
      ),
    ],
    specialty: 'Dermatologist',
    category: 'Dermatological',
  ),
  SymptomData(
    id: 'palpitations',
    keywords: [
      'palpitations',
      'racing heart',
      'fast heartbeat',
      'fast heart rate',
      'heartbeat fast',
      'heart racing',
      'heart pounding',
      'pounding heart',
      'heart flutter',
      'fluttering',
      'fluttering in chest',
      'irregular heartbeat',
      'irregular heart beat',
      'skipped beat',
    ],
    followUps: [
      FollowUpQuestion(
        id: 'palpitations_do_they_occur_at_rest_or_with_activity',
        question: 'Do they occur at rest or with activity?',
      ),
      FollowUpQuestion(
        id: 'palpitations_associated_symptoms',
        question: 'Do you have chest pain, dizziness, or shortness of breath?',
        options: [
          FollowUpOption(
            id: 'palpitations_do_you_have_chest_pain',
            label: 'Chest pain',
            keywords: ['chest pain', 'tightness', 'pressure'],
          ),
          FollowUpOption(
            id: 'palpitations_do_you_have_dizziness',
            label: 'Dizziness',
            keywords: ['dizzy', 'dizziness', 'lightheaded'],
          ),
          FollowUpOption(
            id: 'palpitations_do_you_have_shortness_of_breath',
            label: 'Shortness of breath',
            keywords: ['shortness of breath', 'breathless', 'breathlessness'],
          ),
        ],
      ),
    ],
    specialty: 'Cardiologist',
    category: 'Cardiac',
  ),
];
