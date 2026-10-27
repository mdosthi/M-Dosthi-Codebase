<%@page contentType="text/html" import="java.time.*,imedix.rcGenOperations,imedix.rcCentreInfo,imedix.dataobj,imedix.rcDisplayData, imedix.cook, java.util.*, java.io.*, imedix.myDate, java.text.SimpleDateFormat, org.json.simple.*, org.json.simple.parser.*" %>
<%
response.setContentType("application/vnd.ms-excel");
response.setHeader("Content-Disposition", "attachment; filename=RKMS-Statistics(Disease).xls");
%>
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
String diagnosis=request.getParameter("diagnosis");


rcDisplayData display = new rcDisplayData(request.getRealPath("/"));
rcCentreInfo centerinfo = new rcCentreInfo(request.getRealPath("/"));
rcGenOperations rcGen=new rcGenOperations(request.getRealPath("/"));

Object res=centerinfo.getAllCentreInfo();
Object Res=display.stats_disease(center,diagnosis,fromdt,todt);

%>
<table class="table table-hover table-bordered gender-table">
  <thead>
    <tr>
        <th>Entrydate</th>
        <th>Patient Id</th>
        <th>Patient Name</th>
        <th>Gender</th>
        <th>Age</th>							  
        <th>Caste</th>
         <th>Doctor</th>
         <th>Diagnosis</th>
    </tr>
  </thead>
  <tbody>
    <%




String result="";
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
            String sex=datatemp.getValue("sex");
            //String age[]=datatemp.getValue("age").split(",");
            
	    String Age="";
            String dob=rcGen.getDobOfPatient(pat_id);
			//String agem=rcGen.getAgeInMonthOfPatient(pat_id,cdat);            
            //String PatAgeYMD=rcGen.getPatientAgeYMD(pat_id,cdat);
            
            Age=dob.substring(0,10);
            String arr[]=today.split("/");
            String ar[]=Age.split("-");
            LocalDate Today=LocalDate.of(Integer.parseInt(arr[2]),Integer.parseInt(arr[1]),Integer.parseInt(arr[0]));
            LocalDate Birthday=LocalDate.of(Integer.parseInt(ar[0]),Integer.parseInt(ar[1]),Integer.parseInt(ar[2]));

            String entrydate=datatemp.getValue("entrydate");
            String ar2[]=entrydate.split("-");
            LocalDate Entrydate=LocalDate.of(Integer.parseInt(ar2[0]),Integer.parseInt(ar2[1]),Integer.parseInt(ar2[2]));

            //Period p=Period.between(Birthday,Today);
            Period p=Period.between(Birthday,Entrydate);

            Age=p.getYears()+" Year(s) "+p.getMonths()+" Month(s) "+p.getDays()+" Day(s) ";
            int AAge=p.getYears();
            
            String caste_category="";
            if(datatemp.getValue("caste_category").equalsIgnoreCase("caste_category"))
                caste_category="";
            else
                caste_category=datatemp.getValue("caste_category");
            
            /*String m_status=datatemp.getValue("m_status");
            String marr="";
            if(m_status.equals("1"))
                marr="Nevermarried";
            else if(m_status.equals("2"))
                marr="Currently married";
            else if(m_status.equals("3"))
                marr="Widow/Widower";                
            else if(m_status.equals("4"))
                marr="Divorced";                
            else if(m_status.equals("5"))
                marr="Separated";         */       



            String docname=datatemp.getValue("name");
            String ccenter=datatemp.getValue("center");
            String diag=datatemp.getValue("diag");
            //String entrydate=datatemp.getValue("entrydate");

            //out.println(referring_doctor+"-"+docname);
            String R="<tr><td>"+entrydate+"</td><td>"+pat_id+"</td>"+"<td>"+patname+"</td>"+"<td>"+sex+"</td>"+"<td>"+Age+"</td>"+"<td>"+caste_category+"</td>"+"<td>"+docname+"</td>"+"<td>"+diag+"</td></tr>";
            out.println(R);

		}
				
	}

    out.println("<tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>");
    out.println("<tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>");
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
    <td>Diagnosis and demographic details of each patient visited within date range from <%=fromdt%> to <%=todt%> and diagnosed with <%=diagnosis%> </td>
  </tr>
</tbody>
</table>



<%
    }
    



%>
