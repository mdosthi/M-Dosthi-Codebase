package imedix.saMiX.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import org.junit.jupiter.api.Test;

class SpeechTextPreparerTest {

    @Test
    void removesMarkdownAndCodeButKeepsTheReadableResponse() {
        String text = SpeechTextPreparer.prepare(
                "## **Important:**\n- Call your care team [today](https://example.test).\n"
                        + "Call the [crisis line](tel:988) now.\n"
                        + "```java\nSystem.exit(1);\n```\nThe warning still applies.");

        assertThat(text).contains(
                "Important:",
                "Call your care team today (https://example.test).",
                "Call the crisis line (988) now.",
                "The warning still applies.");
        assertThat(text).doesNotContain("System.exit", "##", "**");
    }

    @Test
    void emptyTextProducesNoSpeech() {
        assertThat(SpeechTextPreparer.prepare(" \n\t")).isEmpty();
    }

    @Test
    void segmentsLongTextAtSentenceBoundariesWithoutDroppingText() {
        String text = "First response sentence. Second response sentence. Third response sentence.";

        List<String> segments = SpeechTextPreparer.splitIntoSegments(text, 30);

        assertThat(segments).hasSize(3);
        assertThat(segments).allSatisfy(segment -> assertThat(segment.length()).isLessThanOrEqualTo(30));
        assertThat(String.join(" ", segments)).isEqualTo(text);
    }

    @Test
    void splitsAnOversizedSentenceAtWordBoundaries() {
        String text = "A".repeat(12) + " " + "B".repeat(12) + " " + "C".repeat(12);

        List<String> segments = SpeechTextPreparer.splitIntoSegments(text, 15);

        assertThat(segments).allSatisfy(segment -> assertThat(segment.length()).isLessThanOrEqualTo(15));
        assertThat(String.join(" ", segments)).isEqualTo(text);
    }

    @Test
    void rejectsNonLatinLettersForTheEnglishModel() {
        assertThat(SpeechTextPreparer.containsUnsupportedLetters("Please rest today.")).isFalse();
        assertThat(SpeechTextPreparer.containsUnsupportedLetters("আজ বিশ্রাম নিন।")).isTrue();
    }

    @Test
    void rejectsInvalidSegmentLength() {
        assertThatThrownBy(() -> SpeechTextPreparer.splitIntoSegments("text", 0))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
