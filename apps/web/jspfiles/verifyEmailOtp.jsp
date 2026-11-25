<%@page language="java" contentType="text/plain; charset=UTF-8"%><%
/*Soumya_B - AJAX endpoint: verify OTP from session.
  No chkcook.jsp include - plain text response only. */

String entered = request.getParameter("otp");
if (entered == null || entered.trim().length() == 0) {
    out.print("ERROR:Missing OTP");
    return;
}
entered = entered.trim();

String storedOtp    = (String) session.getAttribute("emOtp");
String storedExpiry = (String) session.getAttribute("emOtpExpiry");

/* Check session exists */
if (storedOtp == null || storedOtp.trim().length() == 0) {
    out.print("ERROR:No OTP in session");
    return;
}

/* Check expiry */
try {
    long expiry = Long.parseLong(storedExpiry);
    if (System.currentTimeMillis() > expiry) {
        session.removeAttribute("emOtp");
        session.removeAttribute("emOtpEmail");
        session.removeAttribute("emOtpExpiry");
        out.print("EXPIRED");
        return;
    }
} catch (Exception e) {
    out.print("ERROR:Expiry check failed");
    return;
}

/* Compare OTP */
if (entered.equals(storedOtp)) {
    /* Invalidate OTP after successful use - one time only */
    session.removeAttribute("emOtp");
    session.removeAttribute("emOtpExpiry");
    /* Keep emOtpEmail in session - savemed.jsp can cross-check if needed */
    out.print("OK");
} else {
    out.print("WRONG");
}
%>