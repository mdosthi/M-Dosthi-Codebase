<%@page language="java" contentType="text/plain; charset=UTF-8"
        import="imedix.rcUserInfo,java.util.Random,java.io.*,java.net.*,java.nio.charset.StandardCharsets"%><%
/* AJAX endpoint: generate OTP, store in session, send via WhatsApp. */

String phone = request.getParameter("phone");
if (phone == null || phone.trim().length() == 0) {
    out.print("ERROR:Missing phone number");
    return;
}
phone = phone.trim();

/* 1. Check phone uniqueness against login table */
try {
    rcUserInfo rcui = new rcUserInfo(request.getRealPath("/"));
    String count = rcui.existPhone(phone);
    if (count != null && !count.trim().equals("") && !count.trim().equals("0")) {
        out.print("EXISTS");
        return;
    }
} catch (Exception e) {
    System.out.println("generatePhoneOtp existPhone check exception: " + e.toString());
}

/* 2. Generate 6-digit OTP and store in session with expiry */
Random rnd = new Random();
int otpInt = 100000 + rnd.nextInt(900000);
String otp = String.valueOf(otpInt);
long expiry = System.currentTimeMillis() + (10 * 60 * 1000L); /* 10 minutes */

session.setAttribute("phOtp", otp);
session.setAttribute("phOtpPhone", phone);
session.setAttribute("phOtpExpiry", String.valueOf(expiry));

System.out.println("generatePhoneOtp: OTP=" + otp + " for " + phone);

/* 3. Send via WhatsApp */
try {
    String cleanPhone = phone.replaceAll("[^0-9]", "");
    if (cleanPhone.length() == 10) {
        cleanPhone = "91" + cleanPhone;
    }
    String message = "Your OTP to verify your phone number for iMediX registration is: " + otp + ". Please do not share this with anyone.";

    // String targetUrl = "http://10.5.29.226:9090/api/whatsapp/send-otp-direct";
    String targetUrl = "http://127.0.0.1:9090/api/whatsapp/send-otp-direct";
    URL url = new URL(targetUrl);
    HttpURLConnection conn = (HttpURLConnection) url.openConnection();
    conn.setRequestMethod("POST");
    conn.setDoOutput(true);
    conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
    
    String urlParameters = "phone=" + URLEncoder.encode(cleanPhone, "UTF-8") + "&message=" + URLEncoder.encode(message, "UTF-8");
    byte[] postData = urlParameters.getBytes(StandardCharsets.UTF_8);
    
    try (OutputStream os = conn.getOutputStream()) {
        os.write(postData);
    }
    
    int responseCode = conn.getResponseCode();
    if (responseCode == HttpURLConnection.HTTP_OK) {
        try (BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream()))) {
            String inputLine;
            StringBuilder apiResponse = new StringBuilder();
            while ((inputLine = in.readLine()) != null) {
                apiResponse.append(inputLine);
            }
            if (apiResponse.toString().contains("SUCCESS")) {
                out.print("OK");
            } else {
                out.print("ERROR:" + apiResponse.toString());
            }
        }
    } else {
        out.print("ERROR:API Status " + responseCode);
    }
} catch (Exception e) {
    System.out.println("generatePhoneOtp send exception: " + e.toString());
    out.print("ERROR:" + e.getMessage());
}
%>
