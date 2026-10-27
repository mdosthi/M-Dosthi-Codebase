<%@page contentType="text/html" import="java.time.*,imedix.rcGenOperations,imedix.rcCentreInfo,imedix.dataobj,imedix.rcDisplayData, imedix.cook, java.util.*, java.io.*, imedix.myDate, java.text.SimpleDateFormat, org.json.simple.*, org.json.simple.parser.*" %>
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


rcDisplayData display = new rcDisplayData(request.getRealPath("/"));
rcCentreInfo centerinfo = new rcCentreInfo(request.getRealPath("/"));
rcGenOperations rcGen=new rcGenOperations(request.getRealPath("/"));
String cdat = myDate.getCurrentDate("ymd",true);

Object res=centerinfo.getAllCentreInfo();
Object Res=display.stats_age_sex_caste(center,fromdt,todt);
String result="";
int TotalCount=0;
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

            String caste_category=datatemp.getValue("caste_category");            

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
            
            String m_status=datatemp.getValue("m_status");
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
                marr="Separated";                



            String referring_doctor=datatemp.getValue("referring_doctor");
            String docname=datatemp.getValue("name");
            String ccenter=datatemp.getValue("center");
            
            if(sex.equals("F") && AAge<=16){
                TotalCount+=1;
            //out.println(referring_doctor+"-"+docname);
            result+="<tr><td>"+pat_id+"</td>"+"<td>"+patname+"</td>"+"<td>"+Age+"</td>"+"<td>"+caste_category+"</td>"+"<td>"+docname+"</td>"+"<td>"+ccenter+"</td></tr>";
            }
		}
				
	}
    }
    result+="<tr style='background-color:#808080;font-weight: bold;font-size: large;color: white;'><td>Total count = "+TotalCount+"</td></tr>";
    out.println(result);



%>
