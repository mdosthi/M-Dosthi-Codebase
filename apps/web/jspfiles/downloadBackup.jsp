<%@page language="java"  import= "imedix.rcDataEntryFrm,imedix.dataobj,java.util.Calendar, imedix.cook,java.util.*,java.io.*,java.text.SimpleDateFormat"%>
<%@ include file="..//includes/chkcook.jsp" %>

<%
	cook cookx = new cook();
	String utyp=cookx.getCookieValue("usertype", request.getCookies());
	String usr=cookx.getCookieValue("userid", request.getCookies());
	
	rcDataEntryFrm def=new rcDataEntryFrm(request.getRealPath("/"));

	String ccode= cookx.getCookieValue("center", request.getCookies ());
	String cname = cookx.getCookieValue("centername", request.getCookies ());


    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd-HH:mm:SS");
    Calendar sd = Calendar.getInstance();
    SimpleDateFormat sdfOut = new SimpleDateFormat("dd-MM-yyyy hh:mm a");
    
%>

<!DOCTYPE html>
<html>
<head>

<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
	<script src="../bootstrap/jquery-2.2.1.min.js"></script>
	<script src="../bootstrap/js/bootstrap.min.js"></script>


</head>
<body background="../images/txture.jpg">
    <div class="container-fluid">
        <%
        String url = request.getRequestURL().toString();
        String dirToList = request.getRealPath("/BACKUP/");
        File jsp = new File(dirToList);
        //File jspDirectory = jsp.getParentFile();
        File[] dirContents = jsp.listFiles();
        %>
        <TABLE class="table" width=90% border=0 Cellpadding=0 Cellspacing=0>
            <TR>
                <TD><Font Size='5' color=#3300FF> <B>Download Backup (last 7 days)</B> </Font></TD>
                <TD align='right'><A class="btn" HREF="javascript:history.go(-1)" Style="color:yellow; size:9px; background:RED; font-weight:bold; text-decoration:none; ">&nbsp;BACK&nbsp;</A> </TD>
            </TR>
        </TABLE>
        <hr>
        <table class="table table-responsive table-stripped table-bordered">
            <thead>
                <tr>
                    <th>Date and Time</th>
                    <th>Download</th>
                </tr>
            </thead>            
        <%
        for (File file : dirContents) {
            // format date and time from the file name
            String filename = file.getName();
            String datetime = filename.substring(7,26);
            Date d = sdf.parse(datetime);
        %>
            <tr>
                <td><%= sdfOut.format(d) %></td>
                <td><a target="_blank" href="/iMediX/BACKUP/<%= file.getName() %>">Download</a></td>
            </tr>
        <%
        }
        %>

        </table>
    </div>

</body>
</html>