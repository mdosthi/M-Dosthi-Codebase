<%@ page import="java.sql.*, java.util.*, java.util.Base64.*, org.json.simple.*, org.json.simple.parser.*"  %>       
<%
response.setContentType("application/vnd.ms-excel");
response.setHeader("Content-Disposition", "attachment; filename=RKMS-Statistics.xls");
%>


<%
String totalpat = request.getParameter("totalpat");
String totalpatArrname = request.getParameter("totalpatArrname");
String totalPatArr = request.getParameter("totalPatArr");

String genName[] = totalpatArrname.split(",");
String genNo[] = totalPatArr.split(",");
String th = "", td="";
JSONParser parser = new JSONParser();
JSONObject jsObj = (JSONObject) parser.parse("{\"M\":\"Male\", \"F\":\"Female\", \"O\":\"Other\", \"N\":\"Not Stated\"}");

for(int i=0;i<genNo.length;i++){
	td += "<td>"+genNo[i]+"</td>";
}
for(int i=0;i<genName.length;i++){
	th += "<th>"+jsObj.get(genName[i])+"</th>";
}
//out.println(totalpat+" : "+totalpatArrname+" : "+totalPatArr+" : ");
%>
<table class="table table-hover table-bordered gender-table">
  <thead>
    <tr>
      <th>Total patient</th>
      <%=th%>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td id="totalpat-no"><%=totalpat%></td>
		<%=td%>
    </tr>
  </tbody>
</table>