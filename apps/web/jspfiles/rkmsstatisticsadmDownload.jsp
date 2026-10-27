<%@ page import="java.sql.*, java.util.*, imedix.rcCentreInfo,imedix.dataobj,imedix.rcDisplayData,java.util.Base64.*, org.json.simple.*, org.json.simple.parser.*"  %>       
<%
response.setContentType("application/vnd.ms-excel");
response.setHeader("Content-Disposition", "attachment; filename=RKMS-Statistics.xls");
%>


<%
String weekPastDate = "", setDate = "";
JSONObject statisticsData = new JSONObject();
weekPastDate = request.getParameter("weekPastDate");
setDate = request.getParameter("setDate");
rcCentreInfo centerinfo = new rcCentreInfo(request.getRealPath("/"));
Object res=centerinfo.getAllCentreInfo();
int mincodeL = 100; 
JSONObject centermap = new JSONObject();
if(res instanceof String)
  out.println("No data avaliable");
else{
  Vector Vtmp = (Vector)res;
  if(Vtmp.size()>0){
    for(int j=0;j<Vtmp.size();j++){
      dataobj datatemp = (dataobj) Vtmp.get(j);
      String center_code = datatemp.getValue("code");
      mincodeL = (mincodeL<center_code.length())?mincodeL:center_code.length();
    }
    for(int j=0;j<Vtmp.size();j++){
      dataobj datatemp = (dataobj) Vtmp.get(j);
      String center_code = datatemp.getValue("code");
      String center_name = datatemp.getValue("name");
      centermap.put(center_code.substring(0, mincodeL), center_name);
      //out.println(center_code+" : "+center_name+" : "+mincodeL);
    }   
  }
}
//out.println(centermap);
rcDisplayData display = new rcDisplayData(request.getRealPath("/"));
statisticsData = display.rkmsStatisticsAdm(weekPastDate, setDate, mincodeL);
JSONObject centerdata = (JSONObject)statisticsData.get("centervsnop") ;
//out.println(centerdata);

%>
<table class="table table-hover table-bordered gender-table">
  <thead>
    <tr>
      <th>Center Name</th>
      <th>From</th>
      <th>To</th>
      <th>Total Advised Patient</th>
    </tr>
  </thead>
  <tbody>
    <%
      for(Iterator iterator = centerdata.keySet().iterator(); iterator.hasNext();) {
          String key = (String) iterator.next();
          out.println("<tr><td>"+centermap.get(key)+" ("+key+")</td><td>"+weekPastDate+"</td><td>"+setDate+"</td><td>"+centerdata.get(key)+"</td></tr>");
      }
  %>
  </tbody>
</table>