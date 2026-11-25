<%@page language="java" contentType="text/plain; charset=UTF-8"%><%
/* AJAX endpoint: verify OTP from session. */

String entered = request.getParameter("otp");
if (entered == null || entered.trim().length() == 0) {
    out.print("ERROR:Missing OTP");
    return;
}
entered = entered.trim();

String storedOtp    = (String) session.getAttribute("phOtp");
String storedExpiry = (String) session.getAttribute("phOtpExpiry");

/* Check session exists */
if (storedOtp == null || storedOtp.trim().length() == 0) {
    out.print("ERROR:No OTP in session");
    return;
}

/* Check expiry */
try {
    long expiry = Long.parseLong(storedExpiry);
    if (System.currentTimeMillis() > expiry) {
        session.removeAttribute("phOtp");
        session.removeAttribute("phOtpPhone");
        session.removeAttribute("phOtpExpiry");
        out.print("EXPIRED");
        return;
    }
} catch (Exception e) {
    out.print("ERROR:Expiry check failed");
    return;
}

/* Compare OTP */
if (entered.equals(storedOtp)) {
    /* Invalidate OTP after successful use */
    session.removeAttribute("phOtp");
    session.removeAttribute("phOtpExpiry");
    out.print("OK");
} else {
    out.print("WRONG");
}
%>
