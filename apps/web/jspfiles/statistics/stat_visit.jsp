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

String tag=request.getParameter("tag");
String fromdt=request.getParameter("fromdt");
String todt=request.getParameter("todt");
String result="";

if(tag.equalsIgnoreCase("patient"))
{
    String patid=request.getParameter("patid");

    rcDisplayData display = new rcDisplayData(request.getRealPath("/"));
    rcCentreInfo centerinfo = new rcCentreInfo(request.getRealPath("/"));

    Object res=centerinfo.getAllCentreInfo();
    Object Res=display.stats_visitpat(patid,fromdt,todt);


    
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
                result+="<tr><td>"+pat_id+"</td>"+"<td>"+patname+"</td>"+"<td>"+entrydate+"</td>"+"<td>"+serno+"</td>"+"</tr>";

            }
                    
        }
        }

}
else{

    String centre=request.getParameter("center");

    rcDisplayData display = new rcDisplayData(request.getRealPath("/"));
    rcCentreInfo centerinfo = new rcCentreInfo(request.getRealPath("/"));

    Object res=centerinfo.getAllCentreInfo();
    Object Res=display.stats_allvisit(centre,fromdt,todt);


    
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
                result+="<tr><td>"+pat_id+"</td>"+"<td>"+patname+"</td>"+"<td>"+cnt+"</td></tr>";

            }
                    
        }
        }


}

out.println(result);



%>
