<!--<%@ page import="java.sql.*, java.util.*, imedix.rcCentreInfo,imedix.dataobj,imedix.rcDisplayData,java.util.Base64.*, org.json.simple.*, org.json.simple.parser.*"  %>       -->

<%@page contentType="text/html" import="imedix.rcCentreInfo,imedix.dataobj,imedix.rcDisplayData, imedix.cook, java.util.*, java.io.*, imedix.myDate, java.text.SimpleDateFormat, org.json.simple.*, org.json.simple.parser.*" %>

<%
String setDate = "";
JSONObject statisticsData = new JSONObject();
setDate = myDate.getCurrentDate("dmy",true);
java.util.Date cur_date = new java.util.Date();
Calendar c = Calendar.getInstance();
c.setTime(cur_date);
c.add(Calendar.DATE, -7);
java.util.Date currentDateweekPast = c.getTime();
SimpleDateFormat dde = new SimpleDateFormat("dd/MM/yyyy");
String today = dde.format(cur_date);
String weekPastDate = dde.format(currentDateweekPast);

cook cookx = new cook();
String center = cookx.getCookieValue("center", request.getCookies());
String centername = cookx.getCookieValue("centername", request.getCookies());

String tag=request.getParameter("tag");
String fromdt=request.getParameter("fromdt");
String todt=request.getParameter("todt");
String result="";
%>
<%
response.setContentType("application/vnd.ms-excel");
String t="";
if(tag.equalsIgnoreCase("patient"))
  t="(Visit-wise by Patient)";
else
  t="(Visit-wise by Centre)";
response.setHeader("Content-Disposition", "attachment; filename=RKMS-Statistics"+t+".xls");
%>
<%

if(tag.equalsIgnoreCase("patient"))
{
    String patid=request.getParameter("patid");

    rcDisplayData display = new rcDisplayData(request.getRealPath("/"));
    rcCentreInfo centerinfo = new rcCentreInfo(request.getRealPath("/"));

    Object res=centerinfo.getAllCentreInfo();
    Object Res=display.stats_visitpat(patid,fromdt,todt);


    %>
<table class="table table-hover table-bordered gender-table">
  <thead>
    <tr>
      <th>Patient Id</th>
			<th>Patient Name</th>
			<th>Entrydate</th>
			<th>Visit Number</th>
    </tr>
  </thead>
  <tbody>
    <%
    JSONObject centermap = new JSONObject();
    if(Res instanceof String)
        out.println("No data avaliable");
    else{
        Vector Vtmp = (Vector)Res;
        if(Vtmp.size()>0){
            for(int j=0;j<Vtmp.size();j++){
                dataobj datatemp = (dataobj) Vtmp.get(j);
                            
                String pat_id=datatemp.getValue("pat_id");
                String patname=datatemp.getValue("patname");
                String entrydate=datatemp.getValue("entrydate");
                int serno=Integer.parseInt(datatemp.getValue("serno"))+1;

                //out.println(referring_doctor+"-"+docname);
                String R="<tr><td>"+pat_id+"</td>"+"<td>"+patname+"</td>"+"<td>"+entrydate+"</td>"+"<td>"+serno+"</td>"+"</tr>";
                out.println(R);
            }
                    
        }
        }
        out.println("<tr><td></td><td></td><td></td><td></td></tr>");
        out.println("<tr><td></td><td></td><td></td><td></td></tr>");
        %>
  </tbody>
</table>

<table class="table table-hover table-bordered gender-table">
  <thead>
    <tr>
      <th>Statistics details</th>
      <th>Patient Id</th>			
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Patient visited within date range from <%=fromdt%> to <%=todt%></td>
      <td><%=patid%></td>
    </tr>
  </tbody>
</table>

<%


}
else{

    String centre=request.getParameter("center");

    rcDisplayData display = new rcDisplayData(request.getRealPath("/"));
    rcCentreInfo centerinfo = new rcCentreInfo(request.getRealPath("/"));

    Object res=centerinfo.getAllCentreInfo();
    Object Res=display.stats_allvisit(centre,fromdt,todt);



    %>
<table class="table table-hover table-bordered gender-table">
  <thead>
    <tr>
      <th>Patient Id</th>
			<th>Patient Name</th>
			<th>Count</th>
    </tr>
  </thead>
  <tbody>
    <%
    
    JSONObject centermap = new JSONObject();
    if(Res instanceof String)
        out.println("No data avaliable");
    else{
        Vector Vtmp = (Vector)Res;
        if(Vtmp.size()>0){
            for(int j=0;j<Vtmp.size();j++){
                dataobj datatemp = (dataobj) Vtmp.get(j);
                            
                String pat_id=datatemp.getValue("pat_id");
                String patname=datatemp.getValue("patname");
                String cnt=datatemp.getValue("cnt");

                //out.println(referring_doctor+"-"+docname);
                String R="<tr><td>"+pat_id+"</td>"+"<td>"+patname+"</td>"+"<td>"+cnt+"</td></tr>";
                out.println(R);

            }
                    
        }
        }
        out.println("<tr><td></td><td></td><td></td></tr>");
        out.println("<tr><td></td><td></td><td></td></tr>");
        %>
      </tbody>
    </table>

    <table class="table table-hover table-bordered gender-table">
      <thead>
        <tr>
          <th>Statistics details</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>Number of times each patient visited within date range from <%=fromdt%> to <%=todt%> at center <%=centre%></td>
        </tr>
      </tbody>
    </table>



    <%


}





%>
