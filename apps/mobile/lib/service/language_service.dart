import 'package:flutter/material.dart';
//import 'package:shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;

  LanguageService._internal() {
    _loadPreference();
  }

  bool _isBengali = false;
  bool get isBengali => _isBengali;

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isBengali = prefs.getBool('language_is_bengali') ?? false;
    notifyListeners();
  }

  String getQuestionKey(String text, String formType) {
    formType = formType.toLowerCase();

    if (formType == 'phq9') {
      if (text.startsWith('phq9_')) return text;
      return 'phq9_${text.toLowerCase().replaceAll(' ', '_')}';
    }

    if (formType == 'qsu') {
      if (text.startsWith('qsu_')) return text;
      return 'qsu_${text.toLowerCase().replaceAll(' ', '_')}';
    }

    if (formType == 'ftnd') {
      if (text.startsWith('ftnd_')) return text;
      return 'ftnd_${text.toLowerCase().replaceAll(' ', '_')}';
    }

    return text;
  }

  String getQuestionTranslation(String key, String formType) {
    String translationKey = getQuestionKey(key, formType);
    return getText(translationKey);
  }

  String getText(String key) {
    return _translations[_isBengali ? 'bn' : 'en']?[key] ?? key;
  }

  final Map<String, Map<String, String>> _translations = {
    'en': {
      'welcome': 'Welcome to mDosthi!',
      'sleep_hygiene': 'Sleep Hygiene',
      'mood_activity': 'Mood & Activity',
      'education': 'Education',
      'takeTest': 'Take Test',
      'displayResponses': 'Display Responses',
      'remoteFieldService': 'Remote Field Service',
      'home': 'Home',
      'editProfile': 'Edit Profile',
      'logout': 'Log out',
      'bandwidth': 'Bandwidth',
      'changeUsername': 'Change Username',
      'upload': 'Upload',
      'download': 'Download',
      'downloading': 'Downloading...',
      'uploading': 'Uploading...',
      'download_success': 'Download Successful!',
      'download_success_message': 'Your data has been downloaded successfully.',
      'download_failed': 'Download Failed!',
      'upload_success': 'Upload Successful!',
      'upload_success_message': 'Your data has been uploaded successfully.',
      'upload_failed': 'Upload Failed!',
      'check_internet': 'Check your internet connection.',
      'upload_error': 'An error occurred while uploading data: ',
      'ok': 'OK',
      'beneficiary_count': 'Beneficiary Details Count: ',
      'service_count': 'Service Enrollment Count: ',
      'response_count': 'Response Util Count: ',
      'prescribed_tests': 'Prescribed Tests',
      'search_forms': 'Search Forms',
      'ftnd': 'FTND',
      'ftnd_title': 'Fagerstrom Test for Nicotine Dependence (FTND)',
      'qsu': 'QSU',
      'qsu_title': 'Questionnaire of Smoking Urges - Brief',
      'phq9': 'PHQ9',
      'phq9_title': 'Patient Health Questionnaire-9',
      'audit_title': 'Alcohol Use Disorders Identification Test',
      'gad7_title': 'Generalized Anxiety Disorder 7-item',
      'no_forms_available': 'No forms available',
      'error_loading_forms': 'Error loading forms: ',
      'error_loading_form_data': 'Error loading form data',
      'show_tests': 'Show Tests',
      'submission': 'Submission',
      'date': 'Date',
      'submit': 'Submit',
      'take_test': 'Take Test',
      'please_answer': 'Please answer: ',
      'test_submitted_successfully': 'Test submitted successfully',
      'error_submitting_test': 'Error submitting test: ',
      'enter_number': 'Enter a number',
      'enter_answer': 'Enter your answer',
      'no_questions_available': 'No questions available for this form',
      'video': 'Video',
      'withdraw_consent': 'Withdraw Data Consent', //consent
      'readables': 'Readables',
      'readable_materials': 'Readable Materials',
      'educational_docs': 'Educational Documents & Guides',
      'select_doc_read': 'Select a document to read inside the app.',
      'video_library': 'Video Library',
      'educational_videos': 'Educational Videos',
      'select_video_learn':
          'Select a resource below to learn about tobacco cessation.',
      'video_tobacco_cessation_part1_title': 'Tobacco Cessation Guide - Part 1',
      'video_tobacco_cessation_part1_desc':
          'Understand the biological effects of tobacco and learn the first steps to successful quitting.',
      'video_coping_urges_part2_title':
          'Coping with Urges and Withdrawal - Part 2',
      'video_coping_urges_part2_desc':
          'Practical behavioral strategies to handle cravings and manage common withdrawal symptoms.',
      // Chat-related translations
      'chat_with_mdosthi': 'Chat with mDosthi',
      'chat_history': 'Chat History',
      'chatbot_under_development': 'Chatbot Under Development',
      'coming_soon': 'This feature will be available soon!',
      'start_chat': 'Start Chat',
      'end_chat': 'End Chat',
      'type_message_hint': 'Type your message...',
      'start_chat_to_message': 'Start a chat session to send messages',
      'chat_session_started': 'Chat session started. How can I help you today?',
      'chat_session_ended': 'Chat session ended. Thank you for using mDosthi!',
      'error_loading_chat': 'Error loading chat. Please try again.',
      'error_starting_chat': 'Error starting chat session.',
      'error_ending_chat': 'Error ending chat session.',
      'error_sending_message': 'Error sending message.',
      'failed_to_start_chat': 'Failed to start chat session.',
      'failed_to_send_message': 'Failed to send message.',
      'daily_limit': 'Daily Chat Limit',
      'chat_info': 'Chat Information',
      'chat_session_active':
          'You have an active chat session with mDosthi assistant.',
      'start_conversation': 'Start a conversation by typing a message below.',
      'no_active_chat': 'No active chat session. Start a new chat to begin.',

      // Bot responses
      'bot_greeting':
          'Hello! I\'m your mDosthi assistant. How can I help you today?',
      'bot_help_response':
          'I can help you with information about your tests, health assessments, and using the mDosthi platform. What would you like to know?',
      'bot_test_response':
          'You can take your prescribed tests by going to the "Take Test" section in the main menu. Would you like me to guide you through the process?',
      'bot_goodbye':
          'Goodbye! Take care and don\'t hesitate to reach out if you need any assistance with your health journey.',
      'bot_default_response':
          'I understand. Could you please tell me more about what you need help with? I\'m here to assist you with your health assessments and the mDosthi platform.',

      // FTND Questions
      'ftnd_q1':
          'How soon after you wake up do you smoke your first cigarette?',
      'ftnd_q2':
          'Do you find it difficult to refrain from smoking in places where it is forbidden, e.g., in church, at the library, cinema, etc?',
      'ftnd_q3': 'Which cigarette would you hate most to give up?',
      'ftnd_q4': 'How many cigarettes/day do you smoke?',
      'ftnd_q5':
          'Do you smoke more frequently during the first hours of waking than during the rest of the day?',
      'ftnd_q6':
          'Do you smoke if you are so ill that you are in bed most of the day?',
      // FTND Options
      'after_60_minutes': 'After 60 Minutes',
      '31_60_minutes': '31 - 60 minutes',
      '6_30_minutes': '6-30 minutes',
      'within_5_minutes': 'Within 5 minutes',
      'yes': 'Yes',
      'no': 'No',
      'all_others': 'All others',
      'first_morning': 'The first one in the morning',
      '10_or_less': '10 or less',
      '11_20': '11-20',
      '21_30': '21-30',
      '31_or_more': '31 or more',
      'past_tests': ' - Past Tests',
      // QSU-brief Questions
      'qsu_q1': 'I have a desire for a cigarette right now.',
      'qsu_q2': 'Nothing would be better than smoking a cigarette right now',
      'qsu_q3': 'If it were possible, I probably would smoke now.',
      'qsu_q4': 'I could control things better right now if I could smoke.',
      'qsu_q5': 'All I want right now is a cigarette.',
      'qsu_q6': 'I have an urge for a cigarette.',
      'qsu_q7': 'A cigarette would taste good now.',
      'qsu_q8': 'I would do almost anything for a cigarette now.',
      'qsu_q9': 'Smoking would make me less depressed.',
      'qsu_q10': 'I am going to smoke as soon as possible.',
      // QSU-brief Scale Labels
      'strongly_disagree': 'Strongly Disagree',
      'neither_agree': 'Neither Agree nor Disagree',
      'strongly_agree': 'Strongly Agree',
      // PHQ-9 Questions
      'phq9_intro':
          'Over the last 2 weeks, how often have you been bothered by any of the following problems?',
      'phq9_q1': 'Little interest or pleasure in doing things',
      'phq9_q2': 'Feeling down, depressed, or hopeless',
      'phq9_q3': 'Trouble falling or staying asleep, or sleeping too much',
      'phq9_q4': 'Feeling tired or having little energy',
      'phq9_q5': 'Poor appetite or overeating',
      'phq9_q6':
          'Feeling bad about yourself or that you are a failure or have let yourself or your family down',
      'phq9_q7':
          'Trouble concentrating on things, such as reading the newspaper or watching television',
      'phq9_q8':
          'Moving or speaking so slowly that other people could have noticed. Or the opposite - being so fidgety or restless that you have been moving around a lot more than usual',
      'phq9_q9':
          'Thoughts that you would be better off dead, or of hurting yourself',
      'phq9_q10':
          'If you checked off any problems, how difficult have these problems made it for you to do your work, take care of things at home, or get along with other people?',
      // PHQ-9 Response Options
      'not_at_all': 'Not at all',
      'several_days': 'Several days',
      'more_than_half': 'More than half the days',
      'nearly_every_day': 'Nearly every day',
      'not_difficult': 'Not difficult at all',
      'somewhat_difficult': 'Somewhat difficult',
      'very_difficult': 'Very difficult',
      'extremely_difficult': 'Extremely difficult',
      // AUDIT Questions
      'audit_intro':
          'Please answer the following questions about your alcohol use:',
      'audit_q1': 'How often do you have a drink containing alcohol?',
      'audit_q2':
          'How many units of alcohol do you drink on a typical day when you are drinking?',
      'audit_q3':
          'How often have you had 6 or more units if female, or 8 or more if male, on a single occasion in the last year?',
      'audit_q4':
          'How often during the last year have you found that you were not able to stop drinking once you had started?',
      'audit_q5':
          'How often during the last year have you failed to do what was normally expected from you because of your drinking?',
      'audit_q6':
          'How often during the last year have you needed an alcoholic drink in the morning to get yourself going after a heavy drinking session?',
      'audit_q7':
          'How often during the last year have you had a feeling of guilt or remorse after drinking?',
      'audit_q8':
          'How often during the last year have you been unable to remember what happened the night before because you had been drinking?',
      'audit_q9':
          'Have you or somebody else been injured as a result of your drinking?',
      'audit_q10':
          'Has a relative or friend, doctor or other health worker been concerned about your drinking or suggested that you cut down?',
      // AUDIT Response Options
      'never': 'Never',
      'monthly_or_less': 'Monthly or less',
      '2_to_4_times_per_month': '2 to 4 times per month',
      '2_to_3_times_per_week': '2 to 3 times per week',
      '4_or_more_times_per_week': '4 times or more per week',
      '0_to_2': '0 to 2',
      '3_to_4': '3 to 4',
      '5_to_6': '5 to 6',
      '7_to_9': '7 to 9',
      '10_or_more': '10 or more',
      'less_than_monthly': 'Less than monthly',
      'monthly': 'Monthly',
      'weekly': 'Weekly',
      'daily_or_almost_daily': 'Daily or almost daily',
      'yes_but_not_in_last_year': 'Yes, but not in the last year',
      'yes_during_last_year': 'Yes, during the last year',
      // GAD-7 Questions
      'gad7_intro':
          'Over the last 2 weeks, how often have you been bothered by the following problems?',
      'gad7_q1': 'Feeling nervous, anxious, or on edge',
      'gad7_q2': 'Not being able to stop or control worrying',
      'gad7_q3': 'Worrying too much about different things',
      'gad7_q4': 'Trouble relaxing',
      'gad7_q5': 'Being so restless that it\'s hard to sit still',
      'gad7_q6': 'Becoming easily annoyed or irritable',
      'gad7_q7': 'Feeling afraid as if something awful might happen',
      'gad7_q8':
          'If you checked off any problems, how difficult have these made it for you to do your work, take care of things at home, or get along with other people?',
      // Score interpretations and labels
      'your_score': 'Your Score',
      'your_responses': 'Your Responses',

      // FTND Score Interpretations
      'ftnd_very_low_dependence': 'Very Low Dependence',
      'ftnd_low_dependence': 'Low Dependence',
      'ftnd_moderate_dependence': 'Moderate Dependence',
      'ftnd_high_dependence': 'High Dependence',
      'ftnd_very_high_dependence': 'Very High Dependence',

      // PHQ-9 Score Interpretations
      'phq9_minimal_depression': 'Minimal Depression',
      'phq9_mild_depression': 'Mild Depression',
      'phq9_moderate_depression': 'Moderate Depression',
      'phq9_moderately_severe_depression': 'Moderately Severe Depression',
      'phq9_severe_depression': 'Severe Depression',

      // QSU Score Interpretations
      'qsu_low_craving': 'Low Craving',
      'qsu_moderate_craving': 'Moderate Craving',
      'qsu_high_craving': 'High Craving',

      // AUDIT Score Interpretations
      'audit_low_risk': 'Low Risk',
      'audit_increasing_risk': 'Increasing Risk',
      'audit_higher_risk': 'Higher Risk',
      'audit_possible_dependence': 'Possible Dependence',

      // GAD-7 Score Interpretations
      'gad7_minimal_anxiety': 'Minimal Anxiety',
      'gad7_mild_anxiety': 'Mild Anxiety',
      'gad7_moderate_anxiety': 'Moderate Anxiety',
      'gad7_severe_anxiety': 'Severe Anxiety',
      //msclns
      'submitted_response': 'Submitted Response',
      'form': 'Form',
      'submission_time': 'Submission Time',
      'response_id': 'Response ID',
      'back_to_tests': 'Back to Tests',
      'no_past_responses': 'No past responses available',
      'error': 'Error',
      'terminalChat': 'Terminal Chat',
      'connectToTerminal': 'Connect to Terminal',
      'terminalConnected': 'Terminal Connected',
      'terminalDisconnected': 'Terminal Disconnected',
      'sendCommand': 'Send Command',
      'chatMessages': 'Chat Messages',
      'terminalOutput': 'Terminal Output',
      'reconnect': 'Reconnect',
      'disconnect': 'Disconnect and Close',
    },
    'bn': {
      'welcome': 'mDosthi তে স্বাগতম!',
      'sleep_hygiene': 'ঘুমের স্বাস্থ্যবিধি',
      'mood_activity': 'মেজাজ ও কার্যকলাপ',
      'education': 'শিক্ষা',
      'Well-Being': 'সুস্থতা',
      'Bedtime': 'শোয়ার সময়',
      'Wake up': 'জেগে ওঠার সময়',
      'Sleep date': 'তারিখ',
      'How did you sleep?': 'আপনার ঘুম কেমন হলো?',
      'Very Low': 'খুব কম',
      'Low': 'কম',
      'Neutral': 'নিউট্রাল',
      'Good': 'ভাল',
      'Very Good': 'খুব ভাল',
      'Time asleep': 'ঘুমের সময়',
      'Set both times': 'উভয় সময় সেট করুন',
      'How often did you wake?': 'গত রাতে আপনি কতবার জেগে ওঠেন?',
      '0 time': '0 বার',
      '1time': '1 বার',
      '2 times': '2 বার',
      '3 times': '3 বার',
      '4 times': '4 বার',
      '5 and more': '5 এবং তার বেশি',
      'Difficulty falling or staying sleep': 'ঘুমের সময় সমস্যা',
      'No Difficulty': 'কোনও সমস্যা নেই',
      'Mild': 'হালকা',
      'Moderate': 'মধ্যম',
      'High': 'উচ্চ',
      'Notes (Optional)': 'নোট (ঐচ্ছিক)',
      'Save Sleep Record': 'ঘুমের রেকর্ড সংরক্ষণ করুন',
      'Recent sleep history': 'সাম্প্রতিক ঘুমের রেকর্ড',
      'takeTest': 'পরীক্ষা নিন',
      'displayResponses': 'প্রতিক্রিয়া প্রদর্শন',
      'remoteFieldService': 'দূরবর্তী ক্ষেত্র সেবা',
      'home': 'হোম',
      'editProfile': 'প্রোফাইল সম্পাদনা',
      'logout': 'লগ আউট',
      'bandwidth': 'ব্যান্ডউইথ',
      'changeUsername': 'ব্যবহারকারীর নাম পরিবর্তন',
      'upload': 'আপলোড',
      'download': 'ডাউনলোড',
      'downloading': 'ডাউনলোড হচ্ছে...',
      'uploading': 'আপলোড হচ্ছে...',
      'download_success': 'ডাউনলোড সফল!',
      'download_success_message': 'আপনার তথ্য সফলভাবে ডাউনলোড করা হয়েছে।',
      'download_failed': 'ডাউনলোড ব্যর্থ!',
      'upload_success': 'আপলোড সফল!',
      'upload_success_message': 'আপনার তথ্য সফলভাবে আপলোড করা হয়েছে।',
      'upload_failed': 'আপলোড ব্যর্থ!',
      'check_internet': 'আপনার ইন্টারনেট সংযোগ চেক করুন।',
      'upload_error': 'তথ্য আপলোড করার সময় একটি ত্রুটি ঘটেছে: ',
      'ok': 'ঠিক আছে',
      'beneficiary_count': 'উপকারভোগীর বিবরণ সংখ্যা: ',
      'service_count': 'সেবা নিবন্ধন সংখ্যা: ',
      'response_count': 'প্রতিক্রিয়া সংখ্যা: ',
      'prescribed_tests': 'নির্ধারিত পরীক্ষা',
      'search_forms': 'ফর্ম অনুসন্ধান',
      'ftnd': 'এফটিএনডি',
      'ftnd_title': 'নিকোটিন নির্ভরতার জন্য ফেগারস্ট্রম পরীক্ষা (এফটিএনডি)',
      'qsu': 'কিউএসইউ',
      'qsu_title': 'ধূমপানের আগ্রহের প্রশ্নাবলী - সংক্ষিপ্ত',
      'phq9': 'পিএইচকিউ৯',
      'phq9_title': 'রোগীর স্বাস্থ্য প্রশ্নাবলী-৯',
      'audit': 'অডিট',
      'audit_title': 'অ্যালকোহল ব্যবহারের সমস্যা শনাক্তকরণ পরীক্ষা (অডিট)',
      'gad7': 'জিএডি-৭',
      'gad7_title': 'জেনারালাইজড অ্যানজাইটি ডিসঅর্ডার–৭',
      'no_forms_available': 'কোন ফর্ম পাওয়া যায়নি',
      'error_loading_forms': 'ফর্ম লোড করতে সমস্যা: ',
      'error_loading_form_data': 'ফর্ম ডেটা লোড করতে সমস্যা',
      'show_tests': 'পরীক্ষাগুলি দেখান',
      'submission': 'জমা',
      'date': 'তারিখ',
      'Patient Monitoring': 'রোগী পর্যবেক্ষণ',
      'Review Distress Status, Therapy Change and Metastasis Update':
          'মানসিক চাপের অবস্থা, চিকিৎসার পরিবর্তন এবং মেটাস্ট্যাসিসের তথ্য পর্যালোচনা করুন।',
      'Patient Well-being': 'আপনার সুস্থতা',
      'Track sleep, mood, activities, and supportive education.':
          'ঘুম, মেজাজ, কার্যকলাপ এবং সহায়ক শিক্ষা ট্র্যাক করুন।',
      'Log sleep timing, quality, and night awakenings.':
          'ঘুমের সময়, মান এবং রাতে জেগে ওঠা লগ করুন।',
      'Track mood, activities, and daily routines.':
          'মেজাজ, কার্যকলাপ এবং দৈনন্দিন অভ্যাস পর্যবেক্ষণ করুন।',
      'Learn about mood, CBT, and cognitive distortions.':
          'মেজাজ, CBT এবং চিন্তার বিকৃতি সম্পর্কে জানুন।',
      'Choose time': 'সময় নির্বাচন করুন',
      'submit': 'জমা দিন',
      'video': 'ভিডিও',
      'withdraw_consent': 'ডেটা সম্মতি প্রত্যাহার করুন',
      'readables': 'পঠনযোগ্য সামগ্রী',
      'readable_materials': 'পঠনযোগ্য সামগ্রী',
      'educational_docs': 'শিক্ষামূলক নথি ও নির্দেশিকা',
      'select_doc_read': 'অ্যাপের ভিতরে পড়ার জন্য একটি নথি নির্বাচন করুন।',
      'video_library': 'ভিডিও লাইব্রেরি',
      'educational_videos': 'শিক্ষামূলক ভিডিও',
      'select_video_learn':
          'তামাক বর্জন সম্পর্কে জানতে নিচের একটি ভিডিও নির্বাচন করুন।',
      'video_tobacco_cessation_part1_title': 'তামাক বর্জন নির্দেশিকা - পার্ট ১',
      'video_tobacco_cessation_part1_desc':
          'তামাকের জৈবিক প্রভাবগুলি বুঝুন এবং সফলভাবে তামাক বর্জনের প্রথম পদক্ষেপগুলি শিখুন।',
      'video_coping_urges_part2_title':
          'তীব্র আকাঙ্ক্ষা এবং প্রত্যাহারজনিত লক্ষণ মোকাবিলা - পার্ট ২',
      'video_coping_urges_part2_desc':
          'তীব্র আকাঙ্ক্ষা পরিচালনা করতে এবং সাধারণ প্রত্যাহারজনিত লক্ষণগুলি সামলাতে ব্যবহারিক আচরণগত কৌশল।',
      // Chat-related translations in Bengali
      'chat_with_mdosthi': 'mDosthi এর সাথে চ্যাট',
      'chat_history': 'চ্যাট হিস্ট্রি',
      'chatbot_under_development': 'চ্যাটবট উন্নয়নাধীন',
      'coming_soon': 'এই বৈশিষ্ট্যটি শীঘ্রই উপলব্ধ হবে!',
      'start_chat': 'চ্যাট শুরু করুন',
      'end_chat': 'চ্যাট শেষ করুন',
      'type_message_hint': 'আপনার বার্তা টাইপ করুন...',
      'start_chat_to_message': 'বার্তা পাঠাতে একটি চ্যাট সেশন শুরু করুন',
      'chat_session_started':
          'চ্যাট সেশন শুরু হয়েছে। আজ আমি আপনাকে কীভাবে সাহায্য করতে পারি?',
      'chat_session_ended':
          'চ্যাট সেশন শেষ হয়েছে। mDosthi ব্যবহার করার জন্য ধন্যবাদ!',
      'error_loading_chat':
          'চ্যাট লোড করতে ত্রুটি। অনুগ্রহ করে আবার চেষ্টা করুন।',
      'error_starting_chat': 'চ্যাট সেশন শুরু করতে ত্রুটি।',
      'error_ending_chat': 'চ্যাট সেশন শেষ করতে ত্রুটি।',
      'error_sending_message': 'বার্তা পাঠাতে ত্রুটি।',
      'failed_to_start_chat': 'চ্যাট সেশন শুরু করতে ব্যর্থ।',
      'failed_to_send_message': 'বার্তা পাঠাতে ব্যর্থ।',
      'daily_limit': 'দৈনিক চ্যাট সীমা',
      'chat_info': 'চ্যাট তথ্য',
      'chat_session_active':
          'আপনার mDosthi সহায়কের সাথে একটি সক্রিয় চ্যাট সেশন রয়েছে।',
      'start_conversation': 'নিচে একটি বার্তা টাইপ করে কথোপকথন শুরু করুন।',
      'no_active_chat':
          'কোন সক্রিয় চ্যাট সেশন নেই। শুরু করতে একটি নতুন চ্যাট শুরু করুন।',

      // Bot responses in Bengali
      'bot_greeting':
          'হ্যালো! আমি আপনার mDosthi সহায়ক। আজ আমি আপনাকে কীভাবে সাহায্য করতে পারি?',
      'bot_help_response':
          'আমি আপনাকে আপনার পরীক্ষা, স্বাস্থ্য মূল্যায়ন এবং mDosthi প্ল্যাটফর্ম ব্যবহার সম্পর্কে তথ্য দিয়ে সাহায্য করতে পারি। আপনি কী জানতে চান?',
      'bot_test_response':
          'আপনি মূল মেনুতে "পরীক্ষা নিন" বিভাগে গিয়ে আপনার নির্ধারিত পরীক্ষাগুলি নিতে পারেন। আমি কি আপনাকে প্রক্রিয়াটির মাধ্যমে গাইড করব?',
      'bot_goodbye':
          'বিদায়! যত্ন নিন এবং আপনার স্বাস্থ্য যাত্রায় কোনো সহায়তার প্রয়োজন হলে যোগাযোগ করতে দ্বিধা করবেন না।',
      'bot_default_response':
          'আমি বুঝতে পারছি। আপনার কী সাহায্যের প্রয়োজন সে সম্পর্কে আরও বলতে পারেন? আমি এখানে আপনার স্বাস্থ্য মূল্যায়ন এবং mDosthi প্ল্যাটফর্মে সহায়তা করতে আছি।',

      // FTND Questions in Bengali
      'ftnd_q1': 'ঘুম থেকে উঠার কতক্ষণ পর আপনি প্রথম সিগারেট খান?',
      'ftnd_q2':
          'যেখানে ধূমপান নিষিদ্ধ, যেমন গির্জা, লাইব্রেরি, সিনেমা ইত্যাদিতে আপনি কি ধূমপান থেকে বিরত থাকতে অসুবিধা বোধ করেন?',
      'ftnd_q3': 'কোন সিগারেটটি ছাড়তে আপনি সবচেয়ে বেশি অপছন্দ করবেন?',
      'ftnd_q4': 'আপনি দিনে কতটি সিগারেট খান?',
      'ftnd_q5':
          'দিনের বাকি সময়ের তুলনায় ঘুম থেকে উঠার প্রথম কয়েক ঘন্টায় কি আপনি বেশি ঘন ঘন ধূমপান করেন?',
      'ftnd_q6':
          'আপনি যদি এতটাই অসুস্থ হন যে দিনের বেশিরভাগ সময় বিছানায় থাকেন, তখনও কি আপনি ধূমপান করেন?',
      // FTND Options in Bengali
      'after_60_minutes': '৬০ মিনিট পরে',
      '31_60_minutes': '৩১-৬০ মিনিট',
      '6_30_minutes': '৬-৩০ মিনিট',
      'within_5_minutes': '৫ মিনিটের মধ্যে',
      'yes': 'হ্যাঁ',
      'no': 'না',
      'all_others': 'অন্যান্য সব',
      'first_morning': 'সকালের প্রথম সিগারেট',
      '10_or_less': '১০ টি বা কম',
      '11_20': '১১-২০',
      '21_30': '২১-৩০',
      '31_or_more': '৩১ বা তার বেশি',
      'past_tests': ' - পূর্ববর্তী পরীক্ষাগুলি',
      // QSU-brief Questions in Bengali
      'qsu_q1': 'আমার এখন একটি সিগারেটের ইচ্ছা আছে।',
      'qsu_q2': 'এখন একটি সিগারেট খাওয়ার চেয়ে ভালো কিছু হতে পারে না',
      'qsu_q3': 'যদি সম্ভব হত, আমি সম্ভবত এখন ধূমপান করতাম।',
      'qsu_q4':
          'আমি এখন জিনিসগুলি আরও ভালভাবে নিয়ন্ত্রণ করতে পারতাম যদি আমি ধূমপান করতে পারতাম।',
      'qsu_q5': 'এখন আমি শুধু একটি সিগারেট চাই।',
      'qsu_q6': 'আমার একটি সিগারেটের প্রবল ইচ্ছা আছে।',
      'qsu_q7': 'এখন একটি সিগারেট ভালো লাগবে।',
      'qsu_q8': 'আমি এখন একটি সিগারেটের জন্য প্রায় যে কোন কিছু করতে পারি।',
      'qsu_q9': 'ধূমপান আমাকে কম বিষণ্ণ করে তুলবে।',
      'qsu_q10': 'আমি যত তাড়াতাড়ি সম্ভব ধূমপান করব।',
      // QSU-brief Scale Labels in Bengali
      'strongly_disagree': 'দৃঢ়ভাবে অসম্মত',
      'neither_agree': 'সম্মত বা অসম্মত কিছুই নয়',
      'strongly_agree': 'দৃঢ়ভাবে সম্মত',
      // PHQ-9 Questions in Bengali
      'phq9_intro':
          'গত ২ সপ্তাহে, আপনি কতটা ঘন ঘন নিম্নলিখিত সমস্যাগুলি দ্বারা কষ্ট পেয়েছেন?',
      'phq9_q1': 'কাজকর্মে আগ্রহ বা আনন্দ কম পাওয়া',
      'phq9_q2': 'মন খারাপ, বিষণ্ণ বা হতাশ বোধ করা',
      'phq9_q3': 'ঘুমাতে সমস্যা বা ঘুম ধরে রাখতে সমস্যা, অথবা খুব বেশি ঘুমানো',
      'phq9_q4': 'ক্লান্ত বোধ করা বা শক্তি কম থাকা',
      'phq9_q5': 'ক্ষুধামন্দা বা অতিরিক্ত খাওয়া',
      'phq9_q6':
          'নিজের সম্পর্কে খারাপ বোধ করা বা মনে করা যে আপনি ব্যর্থ বা নিজেকে বা পরিবারকে হতাশ করেছেন',
      'phq9_q7':
          'জিনিসগুলিতে মনোযোগ দিতে সমস্যা, যেমন খবরের কাগজ পড়া বা টেলিভিশন দেখা',
      'phq9_q8':
          'এত ধীরে চলাফেরা বা কথা বলা যে অন্যরা লক্ষ্য করতে পারে। অথবা এর বিপরীত - এত অস্থির বা চঞ্চল যে আপনি স্বাভাবিকের চেয়ে অনেক বেশি চলাফেরা করেছেন',
      'phq9_q9': 'নিজের মৃত্যু বা নিজেকে আঘাত করার চিন্তা',
      'phq9_q10':
          'যদি আপনি কোন সমস্যা চিহ্নিত করে থাকেন, এই সমস্যাগুলি আপনার কাজ করা, বাড়িতে জিনিসপত্র দেখাশোনা করা, বা অন্য মানুষের সাথে মিশতে কতটা কঠিন করে তুলেছে?',
      // PHQ-9 Response Options in Bengali
      'not_at_all': 'একেবারেই না',
      'several_days': 'কয়েকদিন',
      'more_than_half': 'অর্ধেকের বেশি দিন',
      'nearly_every_day': 'প্রায় প্রতিদিন',
      'not_difficult': 'মোটেও কঠিন নয়',
      'somewhat_difficult': 'কিছুটা কঠিন',
      'very_difficult': 'খুব কঠিন',
      'extremely_difficult': 'অত্যন্ত কঠিন',
      // AUDIT Questions in Bengali
      'audit_intro':
          'আপনার অ্যালকোহল ব্যবহার সম্পর্কে নিম্নলিখিত প্রশ্নের উত্তর দিন:',
      'audit_q1': 'আপনি কত ঘন ঘন অ্যালকোহলযুক্ত পানীয় পান করেন?',
      'audit_q2':
          'যখন আপনি পান করছেন তখন সাধারণত একদিনে কত ইউনিট অ্যালকোহল পান করেন?',
      'audit_q3':
          'গত বছরে আপনি কত ঘন ঘন একবারে ৬ বা তার বেশি ইউনিট (মহিলাদের জন্য) বা ৮ বা তার বেশি ইউনিট (পুরুষদের জন্য) পান করেছেন?',
      'audit_q4':
          'গত বছরে আপনি কত ঘন ঘন এমন মনে করেছেন যে একবার পান করা শুরু করলে আপনি থামাতে পারছেন না?',
      'audit_q5':
          'গত বছরে আপনি কত ঘন ঘন আপনার পান করার কারণে আপনার স্বাভাবিক দায়িত্ব পালন করতে ব্যর্থ হয়েছেন?',
      'audit_q6':
          'গত বছরে আপনি কত ঘন ঘন ভারী পান করার পর সকালে নিজেকে চাঙ্গা করতে অ্যালকোহলযুক্ত পানীয়ের প্রয়োজন অনুভব করেছেন?',
      'audit_q7':
          'গত বছরে আপনি কত ঘন ঘন পান করার পরে অপরাধবোধ বা অনুশোচনা অনুভব করেছেন?',
      'audit_q8':
          'গত বছরে আপনি কত ঘন ঘন পান করার কারণে আগের রাতে কী ঘটেছিল তা মনে করতে পারেননি?',
      'audit_q9': 'আপনার পান করার ফলে আপনি বা অন্য কেউ কি আহত হয়েছেন?',
      'audit_q10':
          'কোনো আত্মীয় বা বন্ধু, ডাক্তার বা অন্য স্বাস্থ্যকর্মী কি আপনার পান করা নিয়ে উদ্বিগ্ন হয়েছেন বা পান কমানোর পরামর্শ দিয়েছেন?',

      // AUDIT Response Options in Bengali
      'never': 'কখনো না',
      'monthly_or_less': 'মাসে একবার বা তার কম',
      '2_to_4_times_per_month': 'মাসে ২ থেকে ৪ বার',
      '2_to_3_times_per_week': 'সপ্তাহে ২ থেকে ৩ বার',
      '4_or_more_times_per_week': 'সপ্তাহে ৪ বার বা তার বেশি',
      '0_to_2': '০ থেকে ২',
      '3_to_4': '৩ থেকে ৪',
      '5_to_6': '৫ থেকে ৬',
      '7_to_9': '৭ থেকে ৯',
      '10_or_more': '১০ বা তার বেশি',
      'less_than_monthly': 'মাসে একবারের কম',
      'monthly': 'মাসিক',
      'weekly': 'সাপ্তাহিক',
      'daily_or_almost_daily': 'প্রতিদিন বা প্রায় প্রতিদিন',
      'yes_but_not_in_last_year': 'হ্যাঁ, তবে গত বছরে নয়',
      'yes_during_last_year': 'হ্যাঁ, গত বছরে',

      // GAD-7 Questions in Bengali
      'gad7_intro':
          'গত ২ সপ্তাহে, আপনি কতটা ঘন ঘন নিম্নলিখিত সমস্যাগুলি দ্বারা কষ্ট পেয়েছেন?',
      'gad7_q1': 'নার্ভাস, উদ্বিগ্ন বা অস্থির বোধ করা',
      'gad7_q2': 'উদ্বেগ থামাতে বা নিয়ন্ত্রণ করতে না পারা',
      'gad7_q3': 'বিভিন্ন জিনিস নিয়ে খুব বেশি চিন্তা করা',
      'gad7_q4': 'শিথিল হতে সমস্যা',
      'gad7_q5': 'এত অস্থির যে স্থির বসে থাকা কঠিন',
      'gad7_q6': 'সহজে বিরক্ত বা খিটখিটে হওয়া',
      'gad7_q7': 'ভয় পাওয়া যেন কিছু ভয়ঙ্কর ঘটতে চলেছে',
      'gad7_q8':
          'যদি আপনি কোন সমস্যা চিহ্নিত করে থাকেন, এই সমস্যাগুলি আপনার কাজ করা, বাড়িতে জিনিসপত্র দেখাশোনা করা, বা অন্য মানুষের সাথে মিশতে কতটা কঠিন করে তুলেছে?',
      // Score interpretations and labels in Bengali
      'your_score': 'আপনার স্কোর',
      'your_responses': 'আপনার উত্তরসমূহ',

      // FTND Score Interpretations in Bengali
      'ftnd_very_low_dependence': 'অত্যন্ত কম নির্ভরতা',
      'ftnd_low_dependence': 'কম নির্ভরতা',
      'ftnd_moderate_dependence': 'মাঝারি নির্ভরতা',
      'ftnd_high_dependence': 'উচ্চ নির্ভরতা',
      'ftnd_very_high_dependence': 'অত্যন্ত উচ্চ নির্ভরতা',

      // PHQ-9 Score Interpretations in Bengali
      'phq9_minimal_depression': 'ন্যূনতম বিষণ্নতা',
      'phq9_mild_depression': 'হালকা বিষণ্নতা',
      'phq9_moderate_depression': 'মাঝারি বিষণ্নতা',
      'phq9_moderately_severe_depression': 'মাঝারি থেকে গুরুতর বিষণ্নতা',
      'phq9_severe_depression': 'গুরুতর বিষণ্নতা',

      // QSU Score Interpretations in Bengali
      'qsu_low_craving': 'কম আসক্তি',
      'qsu_moderate_craving': 'মাঝারি আসক্তি',
      'qsu_high_craving': 'উচ্চ আসক্তি',

      // AUDIT Score Interpretations in Bengali
      'audit_low_risk': 'কম ঝুঁকি',
      'audit_increasing_risk': 'ক্রমবর্ধমান ঝুঁকি',
      'audit_higher_risk': 'উচ্চ ঝুঁকি',
      'audit_possible_dependence': 'সম্ভাব্য নির্ভরতা',

      // GAD-7 Score Interpretations in Bengali
      'gad7_minimal_anxiety': 'ন্যূনতম উদ্বেগ',
      'gad7_mild_anxiety': 'হালকা উদ্বেগ',
      'gad7_moderate_anxiety': 'মাঝারি উদ্বেগ',
      'gad7_severe_anxiety': 'গুরুতর উদ্বেগ',
      // GAD-7 Response Options are the same as PHQ-9
      'take_test': 'পরীক্ষা নিন',
      'please_answer': 'অনুগ্রহ করে উত্তর দিন: ',
      'test_submitted_successfully': 'পরীক্ষা সফলভাবে জমা দেওয়া হয়েছে',
      'error_submitting_test': 'পরীক্ষা জমা দিতে সমস্যা: ',
      'enter_number': 'একটি সংখ্যা লিখুন',
      'enter_answer': 'আপনার উত্তর লিখুন',
      'no_questions_available': 'এই ফর্মের জন্য কোন প্রশ্ন নেই',
      'submitted_response': 'জমা দেওয়া উত্তর',
      'form': 'ফর্ম',
      'submission_time': 'জমা দেওয়ার সময়',
      'response_id': 'উত্তর আইডি',
      'back_to_tests': 'পরীক্ষায় ফিরে যান',
      'no_past_responses': 'কোনো পুরোনো উত্তর নেই',
      'error': 'ত্রুটি',
      'terminalChat': 'টার্মিনাল চ্যাট',
      'connectToTerminal': 'টার্মিনালে সংযুক্ত করুন',
      'terminalConnected': 'টার্মিনাল সংযুক্ত',
      'terminalDisconnected': 'টার্মিনাল সংযোগ বিচ্ছিন্ন',
      'sendCommand': 'কমান্ড পাঠান',
      'chatMessages': 'চ্যাট বার্তা',
      'terminalOutput': 'টার্মিনাল আউটপুট',
      'reconnect': 'পুনরায় সংযোগ',
      'disconnect': 'সংযোগ বিচ্ছিন্ন করুন এবং বন্ধ করুন',
    }
  };

  Future<void> toggleLanguage() async {
    _isBengali = !_isBengali;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_is_bengali', _isBengali);
    notifyListeners();
  }
}
