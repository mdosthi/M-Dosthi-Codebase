package imedix.saMiX.service;

import java.text.BreakIterator;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class SpeechTextPreparer {
    private static final Pattern CODE_BLOCK = Pattern.compile("(?s)```.*?(?:```|\\z)");
    private static final Pattern IMAGE = Pattern.compile("!\\[([^]]*)]\\([^)]*\\)");
    private static final Pattern LINK = Pattern.compile("\\[([^]]+)]\\(([^)]*)\\)");
    private static final Pattern LIST_PREFIX = Pattern.compile("(?m)^\\s*(?:[-*+]\\s+|\\d+[.)]\\s+|>\\s*)");
    private static final Pattern HEADING_PREFIX = Pattern.compile("(?m)^\\s{0,3}#{1,6}\\s*");
    private static final Pattern HORIZONTAL_RULE = Pattern.compile("(?m)^\\s*(?:---+|___+|\\*\\*\\*+)\\s*$");
    private static final Pattern WHITESPACE = Pattern.compile("\\s+");

    private SpeechTextPreparer() {}

    public static String prepare(String response) {
        if (response == null || response.isBlank()) {
            return "";
        }

        String text = CODE_BLOCK.matcher(response).replaceAll(" ");
        text = IMAGE.matcher(text).replaceAll("$1");
        text = preserveLinkDestinations(text);
        text = HORIZONTAL_RULE.matcher(text).replaceAll(" ");
        text = LIST_PREFIX.matcher(text).replaceAll("");
        text = HEADING_PREFIX.matcher(text).replaceAll("");
        text = text.replaceAll("`([^`]*)`", "$1");
        text = text.replaceAll("[*_~]{1,3}", "");
        return WHITESPACE.matcher(text).replaceAll(" ").trim();
    }

    private static String preserveLinkDestinations(String text) {
        Matcher matcher = LINK.matcher(text);
        StringBuffer spokenText = new StringBuffer();
        while (matcher.find()) {
            String destination = matcher.group(2).trim();
            if (destination.regionMatches(true, 0, "tel:", 0, 4)) {
                destination = destination.substring(4);
            }
            String replacement = matcher.group(1)
                    + (destination.isEmpty() ? "" : " (" + destination + ")");
            matcher.appendReplacement(spokenText, Matcher.quoteReplacement(replacement));
        }
        matcher.appendTail(spokenText);
        return spokenText.toString();
    }

    public static List<String> splitIntoSegments(String text, int maximumLength) {
        if (maximumLength < 1) {
            throw new IllegalArgumentException("maximumLength must be positive");
        }
        if (text == null || text.isBlank()) {
            return List.of();
        }
        if (text.length() <= maximumLength) {
            return List.of(text);
        }

        List<String> sentences = new ArrayList<>();
        BreakIterator sentenceIterator = BreakIterator.getSentenceInstance(Locale.US);
        sentenceIterator.setText(text);
        int start = sentenceIterator.first();
        for (int end = sentenceIterator.next(); end != BreakIterator.DONE; start = end, end = sentenceIterator.next()) {
            addSentenceParts(sentences, text.substring(start, end).trim(), maximumLength);
        }

        List<String> segments = new ArrayList<>();
        StringBuilder current = new StringBuilder();
        for (String sentence : sentences) {
            if (sentence.isEmpty()) {
                continue;
            }
            int combinedLength = current.length() + (current.isEmpty() ? 0 : 1) + sentence.length();
            if (combinedLength > maximumLength && !current.isEmpty()) {
                segments.add(current.toString());
                current.setLength(0);
            }
            if (!current.isEmpty()) {
                current.append(' ');
            }
            current.append(sentence);
        }
        if (!current.isEmpty()) {
            segments.add(current.toString());
        }
        return List.copyOf(segments);
    }

    public static boolean containsUnsupportedLetters(String text) {
        return text.codePoints()
                .filter(Character::isLetter)
                .anyMatch(codePoint -> Character.UnicodeScript.of(codePoint) != Character.UnicodeScript.LATIN);
    }

    private static void addSentenceParts(List<String> sentences, String sentence, int maximumLength) {
        while (sentence.length() > maximumLength) {
            int split = sentence.lastIndexOf(' ', maximumLength);
            if (split <= 0) {
                split = maximumLength;
            }
            if (split < sentence.length()
                    && Character.isHighSurrogate(sentence.charAt(split - 1))
                    && Character.isLowSurrogate(sentence.charAt(split))) {
                split--;
            }
            sentences.add(sentence.substring(0, split).trim());
            sentence = sentence.substring(split).trim();
        }
        if (!sentence.isEmpty()) {
            sentences.add(sentence);
        }
    }
}
