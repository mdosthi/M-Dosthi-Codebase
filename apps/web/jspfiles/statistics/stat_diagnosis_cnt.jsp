<%@page contentType="text/html" import="imedix.rcCentreInfo,imedix.dataobj,imedix.rcDisplayData, imedix.cook, java.util.*, java.io.*, imedix.myDate, java.text.SimpleDateFormat, org.json.simple.*, org.json.simple.parser.*" %>

<%
String setDate = "";
JSONObject statisticsData = new JSONObject();
setDate = myDate.getCurrentDate("dmy",true);
Date cur_date = new Date();
Calendar c = Calendar.getInstance();
c.setTime(cur_date);
c.add(Calendar.DATE, -7);
Date currentDateweekPast = c.getTime();
SimpleDateFormat dde = new SimpleDateFormat("dd/MM/yyyy");
String today = dde.format(cur_date);
String weekPastDate = dde.format(currentDateweekPast);

cook cookx = new cook();
String center = cookx.getCookieValue("center", request.getCookies());
String centername = cookx.getCookieValue("centername", request.getCookies());

String fromdt=request.getParameter("fromdt");
String todt=request.getParameter("todt");
String Diag=request.getParameter("diagnosis").toString();
String diagnosis[]=Diag.split(",");

String CNT[]=new String[diagnosis.length];


rcDisplayData display = new rcDisplayData(request.getRealPath("/"));
rcCentreInfo centerinfo = new rcCentreInfo(request.getRealPath("/"));

Object res=centerinfo.getAllCentreInfo();

for(int i=0;i<diagnosis.length;i++)
{
    Object Res=display.stats_disease_count(center,diagnosis[i],fromdt,todt);
    if(Res instanceof String)
	    out.println("No data avaliable");
    else{
        Vector Vtmp = (Vector)Res;
        if(Vtmp.size()>0){
            String cnt="";
            for(int j=0;j<Vtmp.size();j++){
                dataobj datatemp = (dataobj) Vtmp.get(j);
                cnt=datatemp.getValue("cnt");
            }
            CNT[i]=cnt;
        }
    }
}
String result="";
for(int i=0;i<diagnosis.length;i++)
{
    result+="<tr><td>"+diagnosis[i]+"</td><td>"+CNT[i]+"</td></tr>";
}
out.println(result);


%>
