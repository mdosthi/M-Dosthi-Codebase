<%@page contentType="text/html" import="java.time.*,imedix.rcCentreInfo,imedix.dataobj,imedix.rcDisplayData, imedix.cook, java.util.*, java.io.*, imedix.myDate, java.text.SimpleDateFormat, org.json.simple.*, org.json.simple.parser.*" %>

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
String tag=request.getParameter("tag");

rcDisplayData display = new rcDisplayData(request.getRealPath("/"));
rcCentreInfo centerinfo = new rcCentreInfo(request.getRealPath("/"));

Object res=centerinfo.getAllCentreInfo();


String fname="";
if(tag.equals("sex"))
  fname="Gender";
else if(tag.equals("religion"))
  fname="Religion";
else if(tag.equals("caste_category"))
  fname="Caste";
else
  fname=tag;
  String TH="";
  if(fname.equals("religion_caste"))
  {
    TH="<th>Caste</th><th>Religion</th>";    
  }
  else{
    TH="<th>"+fname+"</th>";
  }

%>


<%
response.setContentType("application/vnd.ms-excel");
response.setHeader("Content-Disposition", "attachment; filename=RKMS-Statistics("+fname+").xls");
%>
<table class="table table-hover table-bordered gender-table">
  <thead>
    <tr>
        <th>Center</th>  
        <%=TH%>
        
        <th>Count</th>        
    </tr>
  </thead>
  <tbody>
    <%


    if(tag.equalsIgnoreCase("religion_caste"))
    {
    
        Object Res=display.CNT_stats_religion_caste(center,fromdt,todt);
    
        if(Res instanceof String)
            out.println("No data avaliable");
        else{
            Vector Vtmp = (Vector)Res;
            if(Vtmp.size()>0){
    
        for(int j=0;j<Vtmp.size();j++){
            dataobj datatemp = (dataobj) Vtmp.get(j);
                        
            
            String count=datatemp.getValue("count");
            String centre=datatemp.getValue("center");
            String caste_category=datatemp.getValue("caste_category");
            String religion=datatemp.getValue("religion");
    
    
            if(caste_category.equalsIgnoreCase("caste_category") )
                caste_category="";
            else if(caste_category.equalsIgnoreCase("general") )
                caste_category="General";
            else if(caste_category.equalsIgnoreCase("obc") )
                caste_category="OBC (Creamy Layer)";
            else if(caste_category.equalsIgnoreCase("obncl") )
                caste_category="OBC (Non Creamy Layer)";
            else if(caste_category.equalsIgnoreCase("sc") )
                caste_category="Schedule Caste";
            else if(caste_category.equalsIgnoreCase("st") )
                caste_category="Schedule Tribe";
            else if(caste_category.equalsIgnoreCase("notst") )
                caste_category="Not Stated";
    
    
            if(religion.equalsIgnoreCase("0") )
                religion="";
            else if(religion.equalsIgnoreCase("1") )
                religion="Buddhism";
            else if(religion.equalsIgnoreCase("2") )
                religion="Christianity";
            else if(religion.equalsIgnoreCase("3") )
                religion="Hinduism";
            else if(religion.equalsIgnoreCase("4") )
                religion="Islam";
            else if(religion.equalsIgnoreCase("5") )
                religion="Jainism";
            else if(religion.equalsIgnoreCase("6") )
                religion="Sikhism";
            else if(religion.equalsIgnoreCase("99") )
                religion="Other";                
            
    
            String R="<tr><td>"+centre+"</td>"+"<td>"+caste_category+"</td>"+"<td>"+religion+"</td>"+"<td>"+count+"</td></tr>";
            out.println(R);
        }
    
        }
        }
        out.println("<tr><td></td><td></td><td></td><td></td></tr>");
        out.println("<tr><td></td><td></td><td></td><td></td></tr>");
    }
    else{
    
        Object Res=display.CNT_stats_sex_caste(center,fromdt,todt,tag);
    
    
    if(Res instanceof String)
      out.println("No data avaliable");
    else{
      Vector Vtmp = (Vector)Res;
      if(Vtmp.size()>0){
           
        for(int j=0;j<Vtmp.size();j++){
          dataobj datatemp = (dataobj) Vtmp.get(j);
                
                
                String count=datatemp.getValue("count");
                String Tag=datatemp.getValue(tag);
    
                if(tag.equalsIgnoreCase("caste_category"))
                {
                    if(Tag.equalsIgnoreCase("caste_category") )
                        Tag="";
                    else if(Tag.equalsIgnoreCase("general") )
                        Tag="General";
                    else if(Tag.equalsIgnoreCase("obc") )
                        Tag="OBC (Creamy Layer)";
                    else if(Tag.equalsIgnoreCase("obncl") )
                        Tag="OBC (Non Creamy Layer)";
                    else if(Tag.equalsIgnoreCase("sc") )
                        Tag="Schedule Caste";
                    else if(Tag.equalsIgnoreCase("st") )
                        Tag="Schedule Tribe";
                    else if(Tag.equalsIgnoreCase("notst") )
                        Tag="Not Stated";
                }
                else if(tag.equalsIgnoreCase("sex"))
                {
                    if(Tag.equalsIgnoreCase("M") )
                        Tag="Male";
                    else if(Tag.equalsIgnoreCase("F") )
                        Tag="Female";
                    else if(Tag.equalsIgnoreCase("O") )
                        Tag="Other";
                    else if(Tag.equalsIgnoreCase("N") )
                        Tag="Not Stated";
                }
                else if(tag.equalsIgnoreCase("religion"))
                {
                    if(Tag.equalsIgnoreCase("0") )
                        Tag="";
                    else if(Tag.equalsIgnoreCase("1") )
                        Tag="Buddhism";
                    else if(Tag.equalsIgnoreCase("2") )
                        Tag="Christianity";
                    else if(Tag.equalsIgnoreCase("3") )
                        Tag="Hinduism";
                    else if(Tag.equalsIgnoreCase("4") )
                        Tag="Islam";
                    else if(Tag.equalsIgnoreCase("5") )
                        Tag="Jainism";
                    else if(Tag.equalsIgnoreCase("6") )
                        Tag="Sikhism";
                    else if(Tag.equalsIgnoreCase("99") )
                        Tag="Other";
                }
    
                
    
    
                String ccenter=datatemp.getValue("center");
                
    
                //out.println(referring_doctor+"-"+docname);
                //result+="<tr><td>"+count+"</td>"+"<td>"+Tag+"</td>"+"<td>"+ccenter+"</td></tr>";
                String R="<tr><td>"+ccenter+"</td>"+"<td>"+Tag+"</td>"+"<td>"+count+"</td></tr>";
                out.println(R);
    
        }    
            
      }
        }
        out.println("<tr><td></td><td></td><td></td></tr>");
        out.println("<tr><td></td><td></td><td></td></tr>");
    }


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
    <td>Total <%=fname%> count for all patients visited within date range from <%=fromdt%> to <%=todt%></td>
  </tr>
</tbody>
</table>



<%



    
    



%>
