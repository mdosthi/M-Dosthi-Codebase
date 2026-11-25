import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';

class DpdpConsentDialog extends StatefulWidget {
  final String uid;
  final VoidCallback onAgreed;

  // ignore: use_super_parameters
  const DpdpConsentDialog({
    Key? key,
    required this.uid,
    required this.onAgreed,
  }) : super(key: key);

  @override
  State<DpdpConsentDialog> createState() => _DpdpConsentDialogState();
}

class _DpdpConsentDialogState extends State<DpdpConsentDialog> {
  bool _isChecked = false;
  bool _isSubmitting = false;
  final ScrollController _agreementScrollController = ScrollController();

  @override
  void dispose() {
    _agreementScrollController.dispose();
    super.dispose();
  }

  static const String _agreementText = """
mDOSTHI is an AI-assisted support platform designed to help you with your psychological therapy. It does not replace professional medical advice.
By tapping “I Agree”, you provide your free, informed, specific, and unambiguous consent for the collection and use of your personal data as described below.
1. Data Fiduciary Information
    *Platform Name: mDOSTHI
    *Organization: AIIMS Kalyani
    *Contact Email: mdosthi590@gmail.com
    *Contact Person: Dr. Aniruddha Basu
2. What Data We Collect
    *We may collect the following categories of data:
    *Basic details (such as name and contact information)
    *Mental Health and Cancer related information
    *Your chat conversations within the app
    *App interaction and usage data
3. Purpose of Data Collection
    *Your data will be used only for the following purposes:
    *To provide personalized empathy and mental health related support to Oncology Patients
    *To improve the quality and effectiveness of our services
    *To analyze usage patterns for system improvement
    *To develop and improve AI models for mental health support
    *To use anonymized data for academic and research purposes
4. Data Processing and Storage
    *Your data will be stored securely on AIIMS Kalyani servers
    *Your data may be processed using Artificial Intelligence (AI) systems
    *Your data may be anonymized (de-identified) and used for research
    *No personally identifiable information will be shared in research outputs

5. Data Sharing
    *Your data will not be sold
    *Your identifiable data will not be shared with third parties without your consent, except where required by law
    *Anonymized data to be shared with research collaborators at AIIMS Kalyani and IIT Kharagpur
6. Your Rights Under the DPDP Act
    *You have the right to:
    *Access your personal data
    *Correct inaccurate or incomplete data
    *Request the deletion of your data
    You have the right to withdraw your consent at any time.
    Upon withdrawal of consent, your data will not be collected and processed any further.
7. Withdrawal of Consent
  You may withdraw your consent at any time using the App.
  Upon withdrawal:
    *You will not be able to use the application unless you agree with the agreement
8. Consent Confirmation
By selecting “I Agree & Continue”, you confirm that:
  *You have read and understood this information
  *You voluntarily agree to the processing of your data for the selected purposes

---------------------------------------------------------------------------------------------------------------------------
mDOSTHI একটি AI (কৃত্রিম বুদ্ধিমত্তা) ভিত্তিক সহায়তা প্ল্যাটফর্ম, যা আপনাকে মানসিক স্বাস্থ্য সম্পর্কিত সহায়তা করার জন্য তৈরি করা হয়েছে। এটি ডাক্তার বা চিকিৎসকের পরামর্শের বিকল্প নয়।

“I Agree” ট্যাপ করার মাধ্যমে, আপনি নিচে বর্ণিত উপায়ে আপনার ব্যক্তিগত তথ্য সংগ্রহ এবং ব্যবহারের জন্য আপনার স্বতঃস্ফূর্ত, অবগত, সুনির্দিষ্ট এবং সুষ্পষ্ট সম্মতি প্রদান করছেন।

১. তথ্য সংক্রান্ত বিবরণ

- প্ল্যাটফর্মের নাম: mDOSTHI
- সংস্থা: AIIMS Kalyani
- যোগাযোগের ইমেইল: mdosthi590@gmail.com
- যোগাযোগকারী ব্যক্তি: ডা. অনিরুদ্ধ বসু

২. আমরা কী কী তথ্য সংগ্রহ করি
আমরা নিম্নলিখিত ধরনের তথ্য সংগ্রহ করতে পারি:
প্রাথমিক বিবরণ (যেমন নাম এবং যোগাযোগের তথ্য)
মানসিক স্বাস্থ্য এবং ক্যানসার সম্পর্কিত তথ্য
অ্যাপের ভেতরে আপনার চ্যাট কথোপকথন
অ্যাপ ইন্টারঅ্যাকশন এবং ব্যবহার সংক্রান্ত তথ্য

৩. তথ্য সংগ্রহের উদ্দেশ্য
আপনার তথ্য শুধুমাত্র নিম্নলিখিত উদ্দেশ্যে ব্যবহার করা হবে:
- আপনাকে ব্যক্তিগতভাবে মানসিক স্বাস্থ্য সম্পর্কিত সহায়তা করতে
- আমাদের পরিষেবা আরও ভালো করতে
- অ্যাপ ব্যবহারের ধরণ বুঝতে
- AI সিস্টেম উন্নত করতে
- গবেষণার কাজে (পরিচয় প্রকাশ না করে) ব্যবহার করতে

৪. তথ্য সংরক্ষণ ও ব্যবহার

- আপনার তথ্য AIIMS Kalyani-এর সার্ভারে নিরাপদে রাখা হবে
- AI প্রযুক্তির মাধ্যমে আপনার তথ্য বিশ্লেষণ করা হতে পারে
- আপনার পরিচয় উহ্য রেখে গবেষণার কাজে ব্যবহার করা হতে পারে
- কোনো গবেষণায় আপনার পরিচয় প্রকাশ করা হবে না

৫. তথ্য শেয়ারিং

- আপনার তথ্য বিক্রি করা হবে না
- আইনী বাধ্য-বাধকতা ছাড়া অন্য কোনো কারণে তৃতীয় পক্ষকে আপনার অনুমতি ছাড়া তথ্য প্রদান করা হবে না। 
- ব্যক্তি পরিচিতি উহ্য রেখে আপনার প্রদেয় তথ্য যৌথ গবেষণার কাজে AIIMS, Kalyani এবং IIT, Kharagpur-এর সহযোগী গবেষকদের সাথে বিনিময়যোগ্য। 

৬. আপনার অধিকার (DPDP আইন অনুযায়ী)

আপনার অধিকার আছে:

- নিজের তথ্য দেখার
- ভুল তথ্য ঠিক করার
- তথ্য মুছে ফেলার অনুরোধ করার
-আপনার অধিকার আছে যেকোনো সময় সম্মতি তুলে নেওয়ার। 

৭. সম্মতি প্রত্যাহার

আপনি যে কোনো সময়ে এই App (অ্যাপ) দ্বারা আপনার তথ্য প্রদানের সম্মতি প্রত্যাহার করতে পারবেন। 

সম্মতি প্রত্যাহার করলে:

- সম্মতি প্রত্যাহার করলে আপনার তথ্য আর সংগ্রহ করা হবে না এবং ব্যবহার করা হবে না। 

৮. সম্মতির নিশ্চিতকরণ

“I Agree & Continue” এই বিকল্প বেছে নিয়ে আপনি নিশ্চিত করছেন যে:

- আপনি এই তথ্য পড়েছেন ও বুঝেছেন।
- আপনি স্বেচ্ছায় আপনার তথ্য ব্যবহারের অনুমতি দিচ্ছেন।

""";
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _submitConsent() async {
    if (!_isChecked) return;

    setState(() => _isSubmitting = true);

    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/update-dpdp-agreed";

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${LoginPage.jwtToken}',
            },
            body: jsonEncode({'uid': widget.uid}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        if (mounted) Navigator.of(context).pop();
        widget.onAgreed();
      } else {
        setState(() => _isSubmitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to record consent. Please try again.'),
              backgroundColor: Colors.brown,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back button — agreement is mandatory
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.security, color: Colors.white, size: 28),
                  SizedBox(height: 8),
                  Text(
                    'Data Protection Agreement',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'DPDP Act, 2023',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // ── Scrollable Agreement Text ──────────────────────────────
            Flexible(
              child: Scrollbar(
                controller: _agreementScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _agreementScrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    _agreementText,
                    style: const TextStyle(fontSize: 13.5, height: 1.65),
                  ),
                ),
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // ── Checkbox Row ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _isChecked,
                    activeColor: const Color(0xFF1B5E20),
                    onChanged: _isSubmitting
                        ? null
                        : (val) => setState(() => _isChecked = val ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'I have read and agree to the above terms and conditions.\nআমি উপরের শর্তাবলী পড়েছি এবং সম্মত আছি।',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // ── Submit Button ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_isChecked && !_isSubmitting) ? _submitConsent : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'I Agree / আমি সম্মত',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
