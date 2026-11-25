<%@page contentType="text/html" import="imedix.layout,java.io.*,imedix.cook,imedix.projinfo,imedix.rcDisplayData,imedix.rcItemlistInfo,imedix.dataobj,imedix.myDate, java.util.*,imedix.Crypto,javax.crypto.*, java.net.URLEncoder, java.nio.charset.StandardCharsets,org.json.simple.*,org.json.simple.parser.*" %>
<%@ include file="..//includes/chkcook.jsp" %>

<%
    SecretKey key = getSecretKey(session);
    Crypto crypto = new Crypto(key);
%>

<%!
public String genInvestigation(String tnam,String pat_id,String dt,String slno, rcDisplayData ddinfo) throws Exception{
	String result="";
	try{
	Object res=ddinfo.DisplayFrm(tnam,pat_id,dt,slno);
			Vector tmp = (Vector)res;
			//out.println("ffffff "+tmp.size());
			for(int i=0;i<tmp.size();i++){
		dataobj temp = (dataobj) tmp.get(i);
		String temperature = temp.getValue("temperature");
		String resprate = temp.getValue("resprate");
		String pulse = temp.getValue("pulse");
		String bldpres = temp.getValue("bldpres");
		//bldpres = bldpres.replace("/","mmHg/");
		bldpres+=" mmHg";
		String pulox = temp.getValue("pulox");
		result = "<li class='list-group-item'><label>Temperature : </label><span class='pull-right'>"+temperature+" &#8451;</span></li>"+
				"<li class='list-group-item'><label>Body Weight : </label><span class='pull-right'>"+resprate+" kg</span></li>"+
				"<li class='list-group-item'><label>Pulse : </label><span class='pull-right'>"+pulse+"/minute</span></li>"+
				"<li class='list-group-item'><label>Blood Pressure : </label><span class='pull-right'>"+bldpres+"</span></li>"+
				"<li class='list-group-item'><label>Blood Sugar(Random) : </label><span class='pull-right'>"+pulox+" mg/dL</span></li>";
				//"<li class='list-group-item'><label>Pulse Oximeter : </label><span class='pull-right'>"+pulox+"%</span></li>";
	}
	}
	catch(Exception ex){
		ex.printStackTrace();
	}
	return result;

}

public String chiefComplaint(String tnam,String pat_id,String dt,String slno, rcDisplayData ddinfo,HttpServletRequest request, Crypto crypto) throws Exception{
	String result="";
	try{
	projinfo pinfo=new projinfo(request.getRealPath("/"));
	String filePath = pinfo.gbldata;
	Object res=ddinfo.DisplayFrm(tnam,pat_id,dt,slno);
			Vector tmp = (Vector)res;
			//out.println("ffffff "+tmp.size());
			for(int i=0;i<tmp.size();i++){
		dataobj temp = (dataobj) tmp.get(i);
		String comp1 = temp.getValue("comp1");
		String dur1 = temp.getValue("dur1");
		String hdmy1 = temp.getValue("hdmy1");
		String comp2 = temp.getValue("comp2");
		String dur2 = temp.getValue("dur2");
		String hdmy2 = temp.getValue("hdmy2");
		String comp3 = temp.getValue("comp3");
		String dur3 = temp.getValue("dur3");
		String hdmy3 = temp.getValue("hdmy3");
		String rh = temp.getValue("rh");
		String fileLink = temp.getValue("report_link");
		//System.out.println("Chief Complaint:"+comp1);
		String comp[]=comp1.split(",");
		String dur[]=dur1.split(",");
		String period[]=hdmy1.split(",");

		if(!comp1.equals(""))
		{
		for(int j=0;j<comp.length;j++)
		{
			result +="<li class='list-group-item'><label>"+comp[j] +"</label><span class='pull-right'>"+dur[j] +" "+period[j]+"</span></li>";
		}
		}

		Vector chiefComplaints = (Vector)ddinfo.getChiefComplaints(pat_id,dt,slno);
		if(chiefComplaints.size() > 0){
			for(int cc=0; cc<chiefComplaints.size(); cc++){
				dataobj ccom = (dataobj) chiefComplaints.get(cc);
				result += "<li class='list-group-item'><label>"+ccom.getValue("complaint") +"</label><span class='pull-right'>"+ccom.getValue("duration") +" "+ccom.getValue("hdmy")+"</span></li>";
			}
			
		}

		if(!rh.equals(""))
			result += "<li class='list-group-item'><label>History and Notes: </label><span class='pull-right'>"+rh+"</span></li>";
		if(!fileLink.equals(""))
			result += "<li class='list-group-item'><label>File: </label><a href='getFile.jsp?file="+URLEncoder.encode(crypto.encrypt(filePath+"/"+pat_id+"/"+fileLink), StandardCharsets.UTF_8)+"' target='_blank' ><span class='glyphicon glyphicon-file'></span></a></li>";
		//if(!comp1.equals(""))
		//	result += "<li class='list-group-item'><label>"+comp1 +"</label><span class='pull-right'>"+dur1 +" "+hdmy1+"</span></li>";
		//if(!comp2.equals(""))
		//	result += "<li class='list-group-item'><label>"+comp2 +"</label><span class='pull-right'>"+dur2 +" "+hdmy2+"</span></li>";
		//if(!comp3.equals(""))
		//	result += "<li class='list-group-item'><label>"+comp3 +"</label><span class='pull-right'>"+dur3 +" "+hdmy3+"</span></li>";
		//if(!rh.equals(""))
		//	result += "<li class='list-group-item'><label>Records </label><span class='pull-right'>"+rh+"</span></li>";
		//if(!fileLink.equals(""))
		//	result += "<li class='list-group-item'><label>File : </label><a href='getFile.jsp?file="+URLEncoder.encode(crypto.encrypt(filePath+"/"+pat_id+"/"+fileLink), StandardCharsets.UTF_8)+"' target='_blank' ><span class='glyphicon glyphicon-file'></span></a></li>";
	}
	
	}
	catch(Exception ex){
		ex.printStackTrace();
		
	}
	return result;
}

// public String ncdScreening(String tnam,String pat_id,String dt,String slno, rcDisplayData ddinfo,HttpServletRequest request, Crypto crypto) throws Exception{
// 	String result="";
// 	try{
// 		Object res=ddinfo.DisplayFrm(tnam,pat_id,dt,slno);
// 		Vector tmp = (Vector)res;
// 		for(int i=0;i<tmp.size();i++){
// 			dataobj temp = (dataobj) tmp.get(i);
// 			String ht_status = temp.getValue("ht_status");
// 			String ht_symptoms = temp.getValue("ht_symptoms");
// 			String dm_status = temp.getValue("dm_status");
// 			String dm_symptoms = temp.getValue("dm_symptoms");
// 			String bc_status = temp.getValue("bc_status");
// 			String bc_symptoms = temp.getValue("bc_symptoms");
// 			String oc_status = temp.getValue("oc_status");
// 			String oc_symptoms = temp.getValue("oc_symptoms");
// 			result += "<li class='list-group-item'><label>Hypertension: "+ ht_status +"</label><span class='pull-right'>"+ht_symptoms+"</span></li>";
// 			result += "<li class='list-group-item'><label>Diabetes Mellitus: "+ dm_status +"</label><span class='pull-right'>"+dm_symptoms+"</span></li>";
// 			result += "<li class='list-group-item'><label>Breast Cancer: "+ bc_status +"</label><span class='pull-right'>"+bc_symptoms+"</span></li>";
// 			result += "<li class='list-group-item'><label>Oral Cancer: "+ oc_status +"</label><span class='pull-right'>"+oc_symptoms+"</span></li>";
// 		}
		
	
// 	}
// 	catch(Exception ex){
// 		ex.printStackTrace();
// 		//result = ex.toString();
// 	}
// 	return result;
// }

public String ncdScreening(String tnam, String pat_id, String dt, String slno, rcDisplayData ddinfo, HttpServletRequest request, Crypto crypto) throws Exception {
    String result = "";
    try {
        projinfo pinfo = new projinfo(request.getRealPath("/"));
        String filePath = pinfo.gbldata;
        
        Object res = ddinfo.DisplayFrm(tnam, pat_id, dt, slno);
        Vector tmp = (Vector)res;
        
        for (int i = 0; i < tmp.size(); i++) {
            dataobj temp = (dataobj) tmp.get(i);
            String notes = temp.getValue("notes");
            String report_link = temp.getValue("report_link");
            String entrydate = temp.getValue("entrydate");
            
            // Format the session notes
            if (notes != null && !notes.equals("")) {
                result += "<li class='list-group-item'><label>Session Notes: </label><div class='session-notes'>" + notes + "</div></li>";
            }
                      
            
            // Add file link if available
            if (report_link != null && !report_link.equals("")) {
                result += "<li class='list-group-item'><label>File: </label><a href='getFile.jsp?file=" + 
                          URLEncoder.encode(crypto.encrypt(filePath + "/" + pat_id + "/" + report_link), StandardCharsets.UTF_8) + 
                          "' target='_blank'><span class='glyphicon glyphicon-file'></span></a></li>";
            }
        }
    } catch (Exception ex) {
        ex.printStackTrace();
        // result = ex.toString();
    }
    return result;
}


public String viewRecords(String id,ServletRequest request) throws Exception{
	String dat;
	rcItemlistInfo rcIlist = new rcItemlistInfo(request.getRealPath("/"));
/*

	dat = myDate.getCurrentDate("dmy",false);
	String tempstr=rcIlist.getVisitWiseInfo(id);


	String tempstr1=tempstr.replaceAll("Target=content2","onclick=viewReport(encodeURI(this.getAttribute('value')))");
	tempstr1=tempstr1.replaceAll("target=content2","onclick=viewReport(encodeURI(this.getAttribute('value')))");
	//tempstr1=tempstr1.replaceAll("target=content2","onclick=clearPanelRight(encodeURI(this.getAttribute('value')))");
	String tempstr2 = tempstr1.replaceAll("HREF","href='#' value");
	tempstr2 = tempstr2.replaceAll("Href","href='#' value");
	return tempstr2;
*/
	return "";
}


%>
<%
String tname="",pat_id="",dt="",slno="";
try{
	pat_id = request.getParameter("id");
	tname = request.getParameter("ty");
	dt = request.getParameter("dt");
	slno = request.getParameter("sl");
}catch(Exception ex){}
	rcDisplayData ddinfo=new rcDisplayData(request.getRealPath("/"));
	try{
	if(tname.equals("p47"))
		out.println(genInvestigation(tname,pat_id,dt,slno,ddinfo));
	else if(tname.equals("a14"))
		out.println(chiefComplaint(tname,pat_id,dt,slno,ddinfo,request,crypto));
	else if(tname.equals("psyNotes"))
		out.println(ncdScreening(tname,pat_id,dt,slno,ddinfo,request,crypto));
	else
		out.println("");

	}catch(Exception ex){}
%>
