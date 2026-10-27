<%@page language="java"  import= "imedix.rcUserInfo,imedix.rcDataEntryFrm,imedix.rcAdminJobs,imedix.rcCentreInfo,imedix.dataobj,imedix.cook,java.util.*,imedix.rcDisplayData"%>
<%@page language="java" import="org.json.simple.JSONArray, org.json.simple.JSONObject, java.util.Calendar" %>
<%@ include file="..//includes/chkcook.jsp" %>
<%
	cook cookx = new cook();
	String utyp=cookx.getCookieValue("usertype", request.getCookies());
	String usr=cookx.getCookieValue("userid", request.getCookies());

	rcUserInfo uinfo=new rcUserInfo(request.getRealPath("/"));
	String us, ps;
	boolean found=false;

	//rcPatqueueInfo rcpqi=new rcPatqueueInfo(request.getRealPath("/"));
	//rcCentreInfo rcci=new rcCentreInfo(request.getRealPath("/"));

	String ccode= cookx.getCookieValue("center", request.getCookies ());
	String cname = cookx.getCookieValue("centername", request.getCookies ());

	String sccode=request.getParameter("sccode");

	String attr = "MONTH(pre.entrydate)";
	String attr1 = "MONTH(med.entrydate)";
		
	if(sccode==null) sccode=ccode;
	if(sccode.equals("")) sccode=ccode;


	String[] months = {"", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};

//out.println(request.getParameter("_center")+request.getParameter("_basic_diagnosis")+request.getParameter("_detailed_diagnosis"));
	
	String center = request.getParameter("_center");
	String start_date = request.getParameter("_start_date");
	String end_date = request.getParameter("_end_date");
	String basic_diagnosis = request.getParameter("_diagnosis");
	rcDisplayData ddinfo=new rcDisplayData(request.getRealPath("/"));
	dataobj objpre=null, diag_summary_obj = null;
	

	if (start_date.length()==0 && end_date.length()==0){
		start_date = "2000-01-01";
		end_date = String.valueOf(java.time.LocalDate.now());
	}
	else{
		start_date = start_date+"-04-01";
		end_date = String.valueOf((Integer.parseInt(end_date)+1))+"-03-31";
		}
/*
	if (month_year.length()>0){
		Calendar calendar = Calendar.getInstance();
		int _month = Integer.parseInt(month_year.split("-")[1])-1;
		calendar.set(Integer.parseInt(month_year.split("-")[0]), _month, 1);
		final int lastDay = calendar.getActualMaximum(Calendar.DAY_OF_MONTH);
		//out.println("Last Day: "+lastDay);
		start_date = month_year+"-01";
		end_date = month_year+"-"+String.valueOf(lastDay);
	}	
	*/
	//out.println("Center : "+ center+ " Start Date : "+ start_date+ " End Date : "+end_date+ " Month year : "+month_year);		
	
	JSONArray output = new JSONArray();

	Object res_diagSummary = ddinfo.genderWiseDiagSummaryUnique(start_date, end_date, center, attr, basic_diagnosis);

	JSONArray jarray_stats = new JSONArray();
	
	
	if (res_diagSummary instanceof String){
		out.println("</br>center><h1> Data Not Available </h1></center>");
		////diag_summary_jsonobj.put("totalInstances", 0);
	}
	else{
		Vector tmp_summary = (Vector)res_diagSummary;
		
		for(int i=0; i<tmp_summary.size(); i++){
			diag_summary_obj = (dataobj) tmp_summary.get(i);
			JSONObject obj = new JSONObject();	
			JSONArray jarray = new JSONArray();
			jarray.add(diag_summary_obj.getValue("sex"));
			jarray.add(diag_summary_obj.getValue("noofdiag"));
			obj.put(months[Integer.parseInt(diag_summary_obj.getValue("entry"))], jarray);
			jarray_stats.add(obj);
		}
		//out.print(jarray_gender);
	}
	
	

	Object res_diagSummary1 = ddinfo.casteWiseDiagSummaryUnique(start_date, end_date, center, attr, basic_diagnosis);
	
	//JSONArray jarray_caste = new JSONArray();
	if (res_diagSummary1 instanceof String){
		out.println("</br>center><h1> Data Not Available </h1></center>");
		////diag_summary_jsonobj.put("totalInstances", 0);
	}
	else{
		Vector tmp_summary = (Vector)res_diagSummary1;
		for(int i=0; i<tmp_summary.size(); i++){
			diag_summary_obj = (dataobj) tmp_summary.get(i);
			JSONObject obj = new JSONObject();	
			JSONArray jarray = new JSONArray();
			jarray.add(diag_summary_obj.getValue("caste_category"));
			jarray.add(diag_summary_obj.getValue("noofdiag"));
			obj.put(months[Integer.parseInt(diag_summary_obj.getValue("entry"))], jarray);
			jarray_stats.add(obj);
		}
		//out.print(jarray_stats);
	}
	
	Object res_diagSummary3 = ddinfo.religionWiseDiagSummaryUnique(start_date, end_date, center, attr, basic_diagnosis);
	
	//JSONArray jarray_religion = new JSONArray();
	if (res_diagSummary3 instanceof String){
		out.println("</br>center><h1> Data Not Available </h1></center>");
		////diag_summary_jsonobj.put("totalInstances", 0);
	}
	else{
		Vector tmp_summary = (Vector)res_diagSummary3;
		int others = 0, counter = 1;
		dataobj _temp_diag_summary_obj = null;
		for(int i=0; i<tmp_summary.size(); i++){
			diag_summary_obj = (dataobj) tmp_summary.get(i);
			if (i<(tmp_summary.size()-1))
				_temp_diag_summary_obj = (dataobj) tmp_summary.get(i+1);
				
			JSONObject obj = new JSONObject();	
			JSONArray jarray = new JSONArray();
			String religion = "";
			if (diag_summary_obj.getValue("religion").equals(String.valueOf(4))){
				religion = "muslim";
				jarray.add(religion);
				jarray.add(diag_summary_obj.getValue("noofdiag"));
			}
			if (!diag_summary_obj.getValue("religion").equals(String.valueOf(4)) && !diag_summary_obj.getValue("religion").equals(String.valueOf(3))){
				religion = "others";	
				others += Integer.valueOf(diag_summary_obj.getValue("noofdiag"));
				jarray.add(religion);
				jarray.add(others);
			}
			

			
			if (months[Integer.parseInt(diag_summary_obj.getValue("entry"))] != months[Integer.parseInt(_temp_diag_summary_obj.getValue("entry"))])
				others = 0;
			obj.put(months[Integer.parseInt(diag_summary_obj.getValue("entry"))], jarray);
			jarray_stats.add(obj);
		}
		
	}	
	
	Object res_diagSummary4 = ddinfo.childGenderWiseDiagSummaryUnique(start_date, end_date, center, attr, basic_diagnosis);
	if (res_diagSummary4 instanceof String){
		out.println("</br>center><h1> Data Not Available </h1></center>");
		////diag_summary_jsonobj.put("totalInstances", 0);
	}
	else{
		Vector tmp_summary = (Vector)res_diagSummary4;
		for(int i=0; i<tmp_summary.size(); i++){
			diag_summary_obj = (dataobj) tmp_summary.get(i);
			JSONObject obj = new JSONObject();	
			JSONArray jarray = new JSONArray();
			String gender = "";
			if (diag_summary_obj.getValue("sex").equals(String.valueOf("M")))
				gender = "childmale";
			if (diag_summary_obj.getValue("sex").equals(String.valueOf("F")))
				gender = "childfemale";			
			jarray.add(gender);
			jarray.add(diag_summary_obj.getValue("noofdiag"));
			obj.put(months[Integer.parseInt(diag_summary_obj.getValue("entry"))], jarray);
			jarray_stats.add(obj);
		}
		
	}
/*
	Object res_diagSummary5 = ddinfo.oldPatientDiagSummary(start_date, end_date, center);
	if (res_diagSummary5 instanceof String){
		out.println("</br>center><h1> Data Not Available </h1></center>");
		////diag_summary_jsonobj.put("totalInstances", 0);
	}
	else{
		Vector tmp_summary = (Vector)res_diagSummary5;
		for(int i=0; i<tmp_summary.size(); i++){
			diag_summary_obj = (dataobj) tmp_summary.get(i);
			JSONObject obj = new JSONObject();		
			JSONArray jarray = new JSONArray();				
			jarray.add("oldpatient");
			jarray.add(diag_summary_obj.getValue("noofdiag"));
			obj.put(diag_summary_obj.getValue("basic_diagnosis"), jarray);
			jarray_stats.add(obj);
		}
		
	}
	
	Object res_diagSummary6 = ddinfo.newPatientDiagSummary(start_date, end_date, center);
	if (res_diagSummary6 instanceof String){
		out.println("</br>center><h1> Data Not Available </h1></center>");
		////diag_summary_jsonobj.put("totalInstances", 0);
	}
	else{
		Vector tmp_summary = (Vector)res_diagSummary6;
		for(int i=0; i<tmp_summary.size(); i++){
			diag_summary_obj = (dataobj) tmp_summary.get(i);
			JSONObject obj = new JSONObject();		
			JSONArray jarray = new JSONArray();				
			jarray.add("newpatient");
			jarray.add(diag_summary_obj.getValue("noofdiag"));
			obj.put(diag_summary_obj.getValue("basic_diagnosis"), jarray);
			jarray_stats.add(obj);
		}
		
	}		
	
	Object res_diagSummary7 = ddinfo.otherreligionDiagTotal(start_date, end_date, center);
	if (res_diagSummary7 instanceof String){
		out.println("</br>center><h1> Data Not Available </h1></center>");
		////diag_summary_jsonobj.put("totalInstances", 0);
	}
	else{
		Vector tmp_summary = (Vector)res_diagSummary7;
		for(int i=0; i<tmp_summary.size(); i++){
			diag_summary_obj = (dataobj) tmp_summary.get(i);
			JSONObject obj = new JSONObject();		
			JSONArray jarray = new JSONArray();				
			jarray.add("others");
			jarray.add(diag_summary_obj.getValue("noofdiag"));
			obj.put(diag_summary_obj.getValue("basic_diagnosis"), jarray);
			jarray_stats.add(obj);
		}
	}		
	
	Object res_diagSummary8 = ddinfo.hindureligionDiagTotal(start_date, end_date, center);
	if (res_diagSummary8 instanceof String){
		out.println("</br>center><h1> Data Not Available </h1></center>");
	}
	else{
		Vector tmp_summary = (Vector)res_diagSummary8;
		for(int i=0; i<tmp_summary.size(); i++){
			diag_summary_obj = (dataobj) tmp_summary.get(i);
			JSONObject obj = new JSONObject();		
			JSONArray jarray = new JSONArray();				
			jarray.add("totalhindu");
			jarray.add(diag_summary_obj.getValue("noofdiag"));
			obj.put(diag_summary_obj.getValue("basic_diagnosis"), jarray);
			jarray_stats.add(obj);
		}
	}	
*/	
	
	Object res_diagSummary9 = ddinfo.genderWiseDiagSummaryOldPatientUnique(start_date, end_date, center, attr, basic_diagnosis);
	if (res_diagSummary9 instanceof String){
		out.println("</br>center><h1> Data Not Available </h1></center>");
	}
	else{
		Vector tmp_summary = (Vector)res_diagSummary9;
		for(int i=0; i<tmp_summary.size(); i++){
			diag_summary_obj = (dataobj) tmp_summary.get(i);
			JSONObject obj = new JSONObject();		
			JSONArray jarray = new JSONArray();				
			jarray.add(diag_summary_obj.getValue("sex"));
			jarray.add(diag_summary_obj.getValue("noofdiag"));
			obj.put(months[Integer.parseInt(diag_summary_obj.getValue("entry"))], jarray);
			jarray_stats.add(obj);
		}
	}	

	
	Object res_diagSummary10 = ddinfo.childGenderWiseDiagSummaryOldPatientUnique(start_date, end_date, center, attr, basic_diagnosis);
	if (res_diagSummary10 instanceof String){
		out.println("</br>center><h1> Data Not Available </h1></center>");
	}
	else{
		Vector tmp_summary = (Vector)res_diagSummary10;
		for(int i=0; i<tmp_summary.size(); i++){
			diag_summary_obj = (dataobj) tmp_summary.get(i);
			JSONObject obj = new JSONObject();		
			JSONArray jarray = new JSONArray();		
			String gender = "";
			if (diag_summary_obj.getValue("sex").equals(String.valueOf("M_old")))
				gender = "oldpatientchildmale";
			if (diag_summary_obj.getValue("sex").equals(String.valueOf("F_old")))
				gender = "oldpatientchildfemale";						
			jarray.add(gender);
			jarray.add(diag_summary_obj.getValue("noofdiag"));
			obj.put(months[Integer.parseInt(diag_summary_obj.getValue("entry"))], jarray);
			jarray_stats.add(obj);
		}
	}		
	
	
	Object res_diagSummary11 = ddinfo.genderWiseDiagSummaryNewPatientUnique(start_date, end_date, center, attr, basic_diagnosis);
	if (res_diagSummary11 instanceof String){
		out.println("</br>center><h1> Data Not Available </h1></center>");
	}
	else{
		Vector tmp_summary = (Vector)res_diagSummary11;
		for(int i=0; i<tmp_summary.size(); i++){
			diag_summary_obj = (dataobj) tmp_summary.get(i);
			JSONObject obj = new JSONObject();		
			JSONArray jarray = new JSONArray();				
			jarray.add(diag_summary_obj.getValue("sex"));
			jarray.add(diag_summary_obj.getValue("noofdiag"));
			obj.put(months[Integer.parseInt(diag_summary_obj.getValue("entry"))], jarray);
			jarray_stats.add(obj);
		}
	}	

	
	Object res_diagSummary12 = ddinfo.childGenderWiseDiagSummaryNewPatientUnique(start_date, end_date, center, attr, basic_diagnosis);
	if (res_diagSummary12 instanceof String){
		out.println("</br>center><h1> Data Not Available </h1></center>");
	}
	else{
		Vector tmp_summary = (Vector)res_diagSummary12;
		for(int i=0; i<tmp_summary.size(); i++){
			diag_summary_obj = (dataobj) tmp_summary.get(i);
			JSONObject obj = new JSONObject();		
			JSONArray jarray = new JSONArray();		
			String gender = "";
			if (diag_summary_obj.getValue("sex").equals(String.valueOf("M_new")))
				gender = "newpatientchildmale";
			if (diag_summary_obj.getValue("sex").equals(String.valueOf("F_new")))
				gender = "newpatientchildfemale";						
			jarray.add(gender);
			jarray.add(diag_summary_obj.getValue("noofdiag"));
			obj.put(months[Integer.parseInt(diag_summary_obj.getValue("entry"))], jarray);
			jarray_stats.add(obj);
		}
	}		
	
	
	
	
	
	
	output.add(jarray_stats);		
	//out.print(jarray_stats);	
	
	
	Object res_diagSummary2 = ddinfo.diagnosisSummaryUnique(start_date, end_date, center,"basic_diagnosis", "");
	
	JSONObject obj = new JSONObject();
	JSONObject diag_summary_jsonobj = new JSONObject();
	if (res_diagSummary2 instanceof String){
		out.println("</br>center><h1> Data Not Available </h1></center>");
		////diag_summary_jsonobj.put("totalInstances", 0);
	}
	else{
		Vector tmp_summary = (Vector)res_diagSummary2;
		for(int i=0; i<tmp_summary.size(); i++){
			diag_summary_obj = (dataobj) tmp_summary.get(i);
			diag_summary_jsonobj.put(diag_summary_obj.getValue("basic_diagnosis"), diag_summary_obj.getValue("noofdiag"));
			//out.println(diag_summary_obj.getValue("basic_diagnosis")+ " : " + diag_summary_obj.getValue("noofdiag")+ " : ");
		}
	}
	
	output.add(diag_summary_jsonobj);
	
	//out.println("\n\n");
	//out.println(diag_summary_jsonobj);
	//obj.put("summary", diag_summary_jsonobj);	
	//out.print(obj);	
	
	out.print(output);

%>	
