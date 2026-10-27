<%@page language="java" import="imedix.rcSmsApi,java.util.*,java.io.*,java.net.*,java.nio.charset.StandardCharsets" %>
<%
    String mobileno = (String) request.getParameter("mobileno");
    String messageid = (String) request.getParameter("messageid");
    String phOtp = (String) session.getAttribute("phOtp");

    if (phOtp != null && !phOtp.trim().isEmpty()) {

        String dataAry[] = new String[1];
        dataAry[0] = phOtp;

        rcSmsApi rcsmsapi = new rcSmsApi(request.getRealPath("/"));
        String message = rcsmsapi.makeMessage(messageid, dataAry);

        try {
            String cleanPhone = mobileno.replaceAll("[^0-9]", "");

            // If phone number does not start with country code (e.g. 10 digits long), prefix with 91 for India
            if (cleanPhone.length() == 10) {
                cleanPhone = "91" + cleanPhone;
            }

            String targetUrl = "/api/whatsapp/send-otp-direct";
            URL url = new URL(targetUrl);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setDoOutput(true);
            conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");

            String urlParameters = "phone=" + URLEncoder.encode(cleanPhone, "UTF-8")
                    + "&message=" + URLEncoder.encode(message, "UTF-8");
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
                    // Return success to match UI expectation
                    out.println("SUCCESS");
                }
            } else {
                out.println("Error:API Status " + responseCode);
            }

        } catch (Exception e) {
            out.println("Error:" + e.getMessage());
        }

    } else {
        out.println("Error:Session");
    }
%>
