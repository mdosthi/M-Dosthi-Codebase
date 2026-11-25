package imedix.saMiX.util;
import java.util.Map;
import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

public class SurveyScoreCalculator {
    /**
     * Calculate score based on form type and survey data
     * @param formName The name of the form (FTND, PHQ9, QSU, GAD7, AUDIT)
     * @param surveyDataJson JSON string containing survey responses
     * @return Calculated score, or null if score cannot be calculated
     */
    public static Integer calculateScore(String formName, String surveyDataJson) {
        if (formName == null || surveyDataJson == null) {
            return null;
        }

        try {
            String formType = formName.toUpperCase().trim();

            switch (formType) {
                case "FTND":
                    return calculateFTNDScore(surveyDataJson);
                case "PHQ9":
                    return calculatePHQ9Score(surveyDataJson);
                case "QSU":
                    return calculateQSUScore(surveyDataJson);
                case "GAD7":
                case "GAD-7":
                    return calculateGAD7Score(surveyDataJson);
                case "AUDIT":
                    return calculateAUDITScore(surveyDataJson);
                default:
                    System.out.println("Unknown form type for scoring: " + formName);
                    return null;
            }
        } catch (Exception e) {
            System.err.println("Error calculating score for form " + formName + ": " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }

    /**
     * Calculate FTND (Fagerstrom Test for Nicotine Dependence) score
     * Score range: 0-10
     * Questions scoring:
     * Q1 (time to first cigarette): 0-3
     * Q2 (difficult to refrain): 0-1
     * Q3 (which cigarette hate to give up): 0-1
     * Q4 (cigarettes per day): 0-3
     * Q5 (smoke more in morning): 0-1
     * Q6 (smoke when ill): 0-1
     */
    private static Integer calculateFTNDScore(String surveyDataJson) {
        JsonObject surveyData = JsonParser.parseString(surveyDataJson).getAsJsonObject();
        int totalScore = 0;

        // Q1: How soon after you wake up do you smoke your first cigarette?
        String q1Answer = getAnswerFromJson(surveyData,
                "How soon after you wake up do you smoke your first cigarette?");
        totalScore += scoreFTNDQ1(q1Answer);

        // Q2: Do you find it difficult to refrain from smoking in places where it is forbidden?
        String q2Answer = getAnswerFromJson(surveyData,
                "Do you find it difficult to refrain from smoking in places where it is forbidden, e.g., in church, at the library, cinema, etc?");
        totalScore += scoreYesNo(q2Answer);

        // Q3: Which cigarette would you hate most to give up?
        String q3Answer = getAnswerFromJson(surveyData,
                "Which cigarette would you hate most to give up?");
        totalScore += scoreFTNDQ3(q3Answer);

        // Q4: How many cigarettes/day do you smoke?
        String q4Answer = getAnswerFromJson(surveyData,
                "How many cigarettes/day do you smoke?");
        totalScore += scoreFTNDQ4(q4Answer);

        // Q5: Do you smoke more frequently during the first hours of waking?
        String q5Answer = getAnswerFromJson(surveyData,
                "Do you smoke more frequently during the first hours of waking than during the rest of the day?");
        totalScore += scoreYesNo(q5Answer);

        // Q6: Do you smoke if you are so ill that you are in bed most of the day?
        String q6Answer = getAnswerFromJson(surveyData,
                "Do you smoke if you are so ill that you are in bed most of the day?");
        totalScore += scoreYesNo(q6Answer);

        return totalScore;
    }

    /**
     * Calculate PHQ-9 (Patient Health Questionnaire) score
     * Score range: 0-27
     * Each of 9 questions scored 0-3:
     * Not at all = 0
     * Several days = 1
     * More than half the days = 2
     * Nearly every day = 3
     */
    private static Integer calculatePHQ9Score(String surveyDataJson) {
        JsonObject surveyData = JsonParser.parseString(surveyDataJson).getAsJsonObject();
        int totalScore = 0;

        String[] questions = {
                "Little interest or pleasure in doing things",
                "Feeling down, depressed, or hopeless",
                "Trouble falling or staying asleep, or sleeping too much",
                "Feeling tired or having little energy",
                "Poor appetite or overeating",
                "Feeling bad about yourself or that you are a failure or have let yourself or your family down",
                "Trouble concentrating on things, such as reading the newspaper or watching television",
                "Moving or speaking so slowly that other people could have noticed. Or the opposite being so figety or restless that you have been moving around a lot more than usual",
                "Thoughts that you would be better off dead, or of hurting yourself"
        };

        for (String question : questions) {
            String answer = getAnswerFromJson(surveyData, question);
            totalScore += scorePHQ9Answer(answer);
        }

        // Note: Q10 is about functional impairment and is NOT included in the score calculation

        return totalScore;
    }

    /**
     * Calculate QSU (Questionnaire of Smoking Urges) score
     * Score range: 10-70
     * Each of 10 questions scored 1-7 on Likert scale
     */
    private static Integer calculateQSUScore(String surveyDataJson) {
        JsonObject surveyData = JsonParser.parseString(surveyDataJson).getAsJsonObject();
        int totalScore = 0;

        String[] questions = {
                "I have a desire for a cigarette right now.",
                "Nothing would be better than smoking a cigarette right now",
                "If it were possible, I probably would smoke now.",
                "I could control things better right now if I could smoke.",
                "All I want right now is a cigarette.",
                "I have an urge for a cigarette.",
                "A cigarette would taste good now.",
                "I would do almost anything for a cigarette now.",
                "Smoking would make me less depressed.",
                "I am going to smoke as soon as possible."
        };

        for (String question : questions) {
            String answer = getAnswerFromJson(surveyData, question);
            totalScore += scoreQSUAnswer(answer);
        }

        return totalScore;
    }

    /**
     * Calculate GAD-7 (Generalized Anxiety Disorder 7-item scale) score
     * Score range: 0-21
     * Each of 7 questions scored 0-3:
     * Not at all = 0
     * Several days = 1
     * More than half the days = 2
     * Nearly every day = 3
     */
    private static Integer calculateGAD7Score(String surveyDataJson) {
        JsonObject surveyData = JsonParser.parseString(surveyDataJson).getAsJsonObject();
        int totalScore = 0;

        String[] questions = {
                "Feeling nervous, anxious, or on edge",
                "Not being able to stop or control worrying",
                "Worrying too much about different things",
                "Trouble relaxing",
                "Being so restless that it is hard to sit still",
                "Becoming easily annoyed or irritable",
                "Feeling afraid, as if something awful might happen"
        };

        for (String question : questions) {
            String answer = getAnswerFromJson(surveyData, question);
            totalScore += scoreGAD7Answer(answer);
        }

        // Note: The functional impairment question is NOT included in the score calculation

        return totalScore;
    }

    /**
     * Calculate AUDIT (Alcohol Use Disorders Identification Test) score
     * Score range: 0-40
     * Questions 1-8 scored 0-4
     * Questions 9-10 scored 0, 2, or 4
     */
    private static Integer calculateAUDITScore(String surveyDataJson) {
        JsonObject surveyData = JsonParser.parseString(surveyDataJson).getAsJsonObject();
        int totalScore = 0;

        // Q1: How often do you have a drink containing alcohol?
        String q1Answer = getAnswerFromJson(surveyData,
                "How often do you have a drink containing alcohol?");
        totalScore += scoreAUDITFrequency(q1Answer);

        // Q2: How many units of alcohol do you drink on a typical day when you are drinking?
        String q2Answer = getAnswerFromJson(surveyData,
                "How many units of alcohol do you drink on a typical day when you are drinking?");
        totalScore += scoreAUDITQ2(q2Answer);

        // Q3: How often have you had 6 or more units if female, or 8 or more if male, on a single occasion in the last year?
        String q3Answer = getAnswerFromJson(surveyData,
                "How often have you had 6 or more units if female, or 8 or more if male, on a single occasion in the last year?");
        totalScore += scoreAUDITFrequency(q3Answer);

        // Q4: How often during the last year have you found that you were not able to stop drinking once you had started?
        String q4Answer = getAnswerFromJson(surveyData,
                "How often during the last year have you found that you were not able to stop drinking once you had started?");
        totalScore += scoreAUDITFrequency(q4Answer);

        // Q5: How often during the last year have you failed to do what was normally expected from you because of your drinking?
        String q5Answer = getAnswerFromJson(surveyData,
                "How often during the last year have you failed to do what was normally expected from you because of your drinking?");
        totalScore += scoreAUDITFrequency(q5Answer);

        // Q6: How often during the last year have you needed an alcoholic drink in the morning to get yourself going after a heavy drinking session?
        String q6Answer = getAnswerFromJson(surveyData,
                "How often during the last year have you needed an alcoholic drink in the morning to get yourself going after a heavy drinking session?");
        totalScore += scoreAUDITFrequency(q6Answer);

        // Q7: How often during the last year have you had a feeling of guilt or remorse after drinking?
        String q7Answer = getAnswerFromJson(surveyData,
                "How often during the last year have you had a feeling of guilt or remorse after drinking?");
        totalScore += scoreAUDITFrequency(q7Answer);

        // Q8: How often during the last year have you been unable to remember what happened the night before because you had been drinking?
        String q8Answer = getAnswerFromJson(surveyData,
                "How often during the last year have you been unable to remember what happened the night before because you had been drinking?");
        totalScore += scoreAUDITFrequency(q8Answer);

        // Q9: Have you or somebody else been injured as a result of your drinking?
        String q9Answer = getAnswerFromJson(surveyData,
                "Have you or somebody else been injured as a result of your drinking?");
        totalScore += scoreAUDITInjury(q9Answer);

        // Q10: Has a relative or friend, doctor or other health worker been concerned about your drinking or suggested that you cut down?
        String q10Answer = getAnswerFromJson(surveyData,
                "Has a relative or friend, doctor or other health worker been concerned about your drinking or suggested that you cut down?");
        totalScore += scoreAUDITInjury(q10Answer);

        return totalScore;
    }

    // Helper methods for FTND scoring
    private static int scoreFTNDQ1(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();

        if (cleaned.contains("after 60") || cleaned.contains("after60")) return 0;
        if (cleaned.contains("31") && (cleaned.contains("60") || cleaned.contains("-"))) return 1;
        if (cleaned.contains("6") && (cleaned.contains("30") || cleaned.contains("-"))) return 2;
        if (cleaned.contains("within 5") || cleaned.contains("within5")) return 3;

        return 0;
    }

    private static int scoreFTNDQ3(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();

        if (cleaned.contains("first") && cleaned.contains("morning")) return 1;
        return 0; // "All others" = 0
    }

    private static int scoreFTNDQ4(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();

        if (cleaned.contains("10 or less") || cleaned.contains("10 or fewer")) return 0;
        if (cleaned.contains("11") && cleaned.contains("20")) return 1;
        if (cleaned.contains("21") && cleaned.contains("30")) return 2;
        if (cleaned.contains("31 or more") || cleaned.contains("31+")) return 3;

        return 0;
    }

    private static int scoreYesNo(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();
        return cleaned.equals("yes") ? 1 : 0;
    }

    // Helper method for PHQ-9 scoring
    private static int scorePHQ9Answer(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();

        if (cleaned.contains("not at all")) return 0;
        if (cleaned.contains("several days")) return 1;
        if (cleaned.contains("more than half")) return 2;
        if (cleaned.contains("nearly every day")) return 3;

        return 0;
    }

    // Helper method for QSU scoring
    private static int scoreQSUAnswer(String answer) {
        if (answer == null) return 1; // Default to minimum if no answer

        // Try to parse as integer first (if it's just a number)
        try {
            int value = Integer.parseInt(answer.trim());
            return Math.max(1, Math.min(7, value)); // Clamp between 1-7
        } catch (NumberFormatException e) {
            // If not a number, try to match text responses
            String cleaned = answer.toLowerCase().trim();

            if (cleaned.contains("strongly disagree")) return 1;
            if (cleaned.contains("disagree") && !cleaned.contains("strongly")) return 2;
            if (cleaned.contains("slightly disagree")) return 3;
            if (cleaned.contains("neither") || cleaned.contains("neutral")) return 4;
            if (cleaned.contains("slightly agree")) return 5;
            if (cleaned.contains("agree") && !cleaned.contains("strongly")) return 6;
            if (cleaned.contains("strongly agree")) return 7;

            return 1; // Default to minimum
        }
    }

    // Helper method for GAD-7 scoring
    private static int scoreGAD7Answer(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();

        if (cleaned.contains("not at all")) return 0;
        if (cleaned.contains("several days")) return 1;
        if (cleaned.contains("more than half")) return 2;
        if (cleaned.contains("nearly every day")) return 3;

        return 0;
    }

    // Helper methods for AUDIT scoring
    private static int scoreAUDITFrequency(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();

        // Score 0
        if (cleaned.contains("never")) return 0;

        // Score 1
        if (cleaned.contains("monthly or less") || cleaned.contains("less than monthly")) return 1;

        // Score 2
        if (cleaned.contains("2 to 4") || cleaned.contains("2-4") ||
                (cleaned.contains("2") && cleaned.contains("4") && cleaned.contains("month"))) return 2;
        if (cleaned.equals("monthly")) return 2;

        // Score 3
        if (cleaned.contains("2 to 3") || cleaned.contains("2-3") ||
                (cleaned.contains("2") && cleaned.contains("3") && cleaned.contains("week"))) return 3;
        if (cleaned.equals("weekly")) return 3;

        // Score 4
        if (cleaned.contains("4 times") || cleaned.contains("4 or more") ||
                cleaned.contains("daily") || cleaned.contains("almost daily")) return 4;

        return 0;
    }

    private static int scoreAUDITQ2(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();

        if (cleaned.contains("0 to 2") || cleaned.contains("0-2") ||
                cleaned.equals("1") || cleaned.equals("2")) return 0;

        if (cleaned.contains("3 to 4") || cleaned.contains("3-4") ||
                cleaned.equals("3") || cleaned.equals("4")) return 1;

        if (cleaned.contains("5 to 6") || cleaned.contains("5-6") ||
                cleaned.equals("5") || cleaned.equals("6")) return 2;

        if (cleaned.contains("7 to 9") || cleaned.contains("7-9") ||
                cleaned.equals("7") || cleaned.equals("8") || cleaned.equals("9")) return 3;

        if (cleaned.contains("10 or more") || cleaned.contains("10+")) return 4;

        // Try to parse as number if it's a direct numeric input
        try {
            int numUnits = Integer.parseInt(cleaned);
            if (numUnits <= 2) return 0;
            if (numUnits <= 4) return 1;
            if (numUnits <= 6) return 2;
            if (numUnits <= 9) return 3;
            return 4;
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private static int scoreAUDITInjury(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();

        // Score 0: No
        if (cleaned.equals("no")) return 0;

        // Score 2: Yes, but not in the last year
        if (cleaned.contains("not in") && cleaned.contains("last year")) return 2;
        if (cleaned.contains("but not") && cleaned.contains("last year")) return 2;

        // Score 4: Yes, during the last year
        if (cleaned.contains("during") && cleaned.contains("last year")) return 4;
        if (cleaned.contains("in") && cleaned.contains("last year") &&
                !cleaned.contains("not in")) return 4;

        // Simple "yes" might indicate recent occurrence
        if (cleaned.equals("yes")) return 4;

        return 0;
    }

    /**
     * Helper method to safely extract answer from JSON object
     * Handles various question formats and variations
     */
    private static String getAnswerFromJson(JsonObject surveyData, String questionKey) {
        try {
            // Try exact match first
            if (surveyData.has(questionKey)) {
                return surveyData.get(questionKey).getAsString();
            }

            // Try case-insensitive match
            for (String key : surveyData.keySet()) {
                if (key.equalsIgnoreCase(questionKey)) {
                    return surveyData.get(key).getAsString();
                }
            }

            // Try partial match (contains key words)
            String[] keyWords = questionKey.toLowerCase().split(" ");
            for (String key : surveyData.keySet()) {
                String lowerKey = key.toLowerCase();
                boolean matches = true;
                for (String keyword : keyWords) {
                    if (keyword.length() > 3 && !lowerKey.contains(keyword)) {
                        matches = false;
                        break;
                    }
                }
                if (matches) {
                    return surveyData.get(key).getAsString();
                }
            }

            return null;
        } catch (Exception e) {
            System.err.println("Error extracting answer for question: " + questionKey);
            return null;
        }
    }

    /**
     * Get score interpretation text based on form type and score
     * @param formName The form type
     * @param score The calculated score
     * @return Interpretation string
     */
    public static String getScoreInterpretation(String formName, int score) {
        if (formName == null) return "";

        String formType = formName.toUpperCase().trim();

        switch (formType) {
            case "FTND":
                if (score <= 2) return "Very low dependence";
                if (score <= 4) return "Low dependence";
                if (score == 5) return "Moderate dependence";
                if (score <= 7) return "High dependence";
                return "Very high dependence";

            case "PHQ9":
                if (score <= 4) return "Minimal depression";
                if (score <= 9) return "Mild depression";
                if (score <= 14) return "Moderate depression";
                if (score <= 19) return "Moderately severe depression";
                return "Severe depression";

            case "QSU":
                if (score <= 30) return "Low craving";
                if (score <= 50) return "Moderate craving";
                return "High craving";

            case "GAD7":
            case "GAD-7":
                if (score <= 4) return "Minimal anxiety";
                if (score <= 9) return "Mild anxiety";
                if (score <= 14) return "Moderate anxiety";
                return "Severe anxiety";

            case "AUDIT":
                if (score <= 7) return "Low risk";
                if (score <= 15) return "Increasing risk";
                if (score <= 19) return "Higher risk";
                return "Possible dependence";

            default:
                return "";
        }
    }
}