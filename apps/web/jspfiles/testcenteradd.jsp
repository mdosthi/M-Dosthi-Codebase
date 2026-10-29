<%@page language="java" import="imedix.dataobj,imedix.ImedixCrypto,imedix.rcGenOperations,java.net.InetAddress,java.security.MessageDigest,java.text.SimpleDateFormat,java.util.Date,java.util.Locale"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%
	response.setContentType("text/html;charset=UTF-8");
	boolean loopback = false;
	try {
		loopback = InetAddress.getByName(request.getRemoteAddr()).isLoopbackAddress();
	} catch (Exception e) {
		loopback = false;
	}

	String uid = (String) session.getAttribute("uid");
	String usertype = (String) session.getAttribute("utype");
	String expectedCsrf = (String) session.getAttribute("testCenterCsrf");
	String submittedCsrf = request.getParameter("csrf");
	if (!"POST".equalsIgnoreCase(request.getMethod())
			|| !Boolean.getBoolean("imedix.testCenterCreation")
			|| !loopback
			|| uid == null
			|| !"adm".equalsIgnoreCase(usertype)
			|| expectedCsrf == null
			|| submittedCsrf == null
			|| !MessageDigest.isEqual(expectedCsrf.getBytes("UTF-8"), submittedCsrf.getBytes("UTF-8"))) {
		response.sendError(HttpServletResponse.SC_FORBIDDEN, "Local test center creation is disabled or not authorized.");
		return;
	}
	session.removeAttribute("testCenterCsrf");

	String code = request.getParameter("code");
	String name = request.getParameter("name");
	code = code == null ? "" : code.trim().toUpperCase(Locale.ROOT);
	name = name == null ? "" : name.trim();
	String result = "Could not create the local test center. Check the center table schema and server logs.";

	if (!code.matches("[A-Z]{4,16}") || name.isEmpty() || name.length() > 128) {
		response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Enter a center code of 4-16 letters and a name up to 128 characters.");
		return;
	}

	try {
		rcGenOperations operations = new rcGenOperations(request.getRealPath("/"));
		if (Integer.parseInt(operations.FindCount("center", "code='" + code + "'")) > 0) {
			response.sendError(HttpServletResponse.SC_CONFLICT, "That center code already exists.");
			return;
		}

		ImedixCrypto crypto = new ImedixCrypto();
		dataobj center = new dataobj();
		center.add("tname", "center");
		center.add("code", code);
		center.add("name", name);
		center.add("cdate", new SimpleDateFormat("ddMMyyyy", Locale.ROOT).format(new Date()));
		center.add("expdate", crypto.encryptLicString("31122099", "LocalTestKey1234"));
		center.add("centertype", "S");
		center.add("visibility", "Y");
		operations.saveAnyInfo(center);
		if (Integer.parseInt(operations.FindCount("center", "code='" + code + "'")) > 0) {
			result = "Created local test center " + code + ". It is not a licensed production center.";
		} else {
			response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, result);
			return;
		}
	} catch (Exception e) {
		getServletContext().log("Local test center creation failed", e);
	}
%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Local test center</title></head>
<body>
	<p><%=result%></p>
	<p><a href="showcenter.jsp">Return to Center Management</a></p>
</body>
</html>
