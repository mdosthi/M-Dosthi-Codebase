<%@page language="java" contentType="text/plain; charset=UTF-8"
        import="imedix.rcUserInfo,imedix.Email,java.util.Random"%><%
/*Soumya_B - AJAX endpoint: generate OTP, store in session, send via Email.Send().
  No chkcook.jsp include - plain text response only. */

String email = request.getParameter("email");
if (email == null || email.trim().length() == 0) {
    out.print("ERROR:Missing email");
    return;
}
email = email.trim();

/* 1. Check email uniqueness against login table */
try {
    rcUserInfo rcui = new rcUserInfo(request.getRealPath("/"));
    String count = rcui.existEmail(email);
    if (count != null && !count.trim().equals("") && !count.trim().equals("0")) {
        out.print("EXISTS");
        return;
    }
} catch (Exception e) {
    /* fail open on uniqueness check - do not block OTP send */
    System.out.println("generateEmailOtp existEmail check: " + e.toString());
}

/* 2. Generate 6-digit OTP and store in session with expiry */
Random rnd = new Random();
int otpInt = 100000 + rnd.nextInt(900000);
String otp = String.valueOf(otpInt);
long expiry = System.currentTimeMillis() + (10 * 60 * 1000L); /* 10 minutes */

session.setAttribute("emOtp", otp);
session.setAttribute("emOtpEmail", email);
session.setAttribute("emOtpExpiry", String.valueOf(expiry));

System.out.println("generateEmailOtp: OTP=" + otp + " for " + email);

/* 3. Send via Email.Send() - matching SendEmail.jsp pattern exactly */
try {
    String mesg = "Dear Patient,\n\n"
                + "Your OTP to verify your email address for iMediX registration is:\n\n"
                + "    " + otp + "\n\n"
                + "This OTP is valid for 10 minutes.\n"
                + "If you did not request this, please ignore this message.\n\n"
                + "Regards,\niMediX Team";
    Email em = new Email(request.getRealPath("/"));
    String result = em.Send(email, "iMediX: Verify Email", mesg);
    System.out.println("generateEmailOtp Send result: " + result);
    /* Email.Send() returns "Sent message successfully...." on success */
    if (result != null && result.toLowerCase().contains("sent message successfully")) {
        out.print("OK");
    } else {
        out.print("ERROR:" + result);
    }
} catch (Exception e) {
    System.out.println("generateEmailOtp exception: " + e.toString());
    out.print("ERROR:" + e.getMessage());
}
%>