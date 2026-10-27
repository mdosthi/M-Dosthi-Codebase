<%@page language="java"  import= "java.util.Date,imedix.rcDataEntryFrm,imedix.dataobj, imedix.myDate,imedix.cook,java.util.*"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%
    cook cookx = new cook();	
	String patid = cookx.getCookieValue("patid", request.getCookies());
    String nextaptdt=cookx.getCookieValue("nextaptdt", request.getCookies());
    /*nextaptdt format--> patid_Date*/
    String id=nextaptdt.substring(0,nextaptdt.indexOf("_"));
    String dt=nextaptdt.substring(nextaptdt.indexOf("_")+1);
    /*out.println(nextaptdt+";");
    out.println(id+";");*/ //Don't print this
    if(id.equalsIgnoreCase(patid) && !dt.trim().equals(""))
    {
        out.println(dt);
    }
    else
    {
        out.println("-1");
    }



%>