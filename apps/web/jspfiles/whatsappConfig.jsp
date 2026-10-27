<%-- WhatsApp Business API credentials — include this file where needed.
     Fill in your values from the Meta Developer Console. --%>
<%!
    // ── WhatsApp Business API config ──────────────────────────────────────
    // From Meta Developer Console → Your App → WhatsApp → API Setup
    static final String WA_PHONE_NUMBER_ID  = "1134419619735216";
    static final String WA_ACCESS_TOKEN     = "EAANReHxBslQBRvFEocuWSBcRhLzKBgMZAUguii4kscGlmiifldHxzSvtZBchvvevnAbSRVm6c2YRZCph75mkCoBQIZAt7KRlt2y88qXJ9y7MnL6k8VjCTSb40SRA6JpAeqtdbhCbSkm9VTZBwqNHavsSsp0C1brZCZBA3ii4OSCLO9z3NZBf5tHZCX1B2qK7AzAZDZD";
    static final String WA_API_VERSION      = "v25.0";

    // Must match the M-DOSTHI_VERIFY_TOKEN string in ROOT/webhook.jsp
    static final String WA_VERIFY_TOKEN     = "M-Dosthi_may_2026";

    // Graph API base URL
    static final String WA_API_BASE         = "https://graph.facebook.com/" + WA_API_VERSION;

    // Template language code (change to en_IN or hi if needed)
    static final String WA_TEMPLATE_LANG    = "en_US";
%>
