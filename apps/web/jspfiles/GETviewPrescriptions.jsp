<%@page contentType="text/html" import= "java.io.*,org.json.simple.*,org.json.simple.parser.*,imedix.projinfo,imedix.rcDataEntryFrm,imedix.rcUserInfo,imedix.medinfo,imedix.rcCentreInfo,imedix.rcDisplayData,imedix.cook, imedix.dataobj,imedix.myDate, java.util.*,java.io.*,java.text.*, imedix.Crypto, javax.crypto.*, java.net.URLEncoder, java.nio.charset.StandardCharsets"%>
<%@page import="com.itextpdf.text.*,com.itextpdf.text.pdf.*, com.itextpdf.text.html.simpleparser.HTMLWorker,java.net.*,java.io.*,com.itextpdf.tool.xml.XMLWorkerHelper" %>

<%@page contentType="text/html"  import= "imedix.rcUserInfo,imedix.rcDisplayData,imedix.dataobj,imedix.cook,java.util.*, java.text.*, imedix.myDate,imedix.Crypto, javax.crypto.*,java.net.URLEncoder"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%@page import="org.apache.commons.codec.binary.Base64"%>

<%!
public Vector printedPres(String entrydate, rcDisplayData display) throws Exception{
	Vector<String> entrydateList = new Vector(); 	
	Object presListObj = display.getPrintedPrescriptionList(entrydate);
	if(presListObj instanceof String){
		
	}
	else{
		Vector tmp = (Vector)presListObj;
		for(int i=0;i<tmp.size();i++){
			dataobj temp = (dataobj) tmp.get(i);
			entrydateList.add(temp.getValue("creationdate").replaceAll("[\s-.-:]",""));
		}
	}
	return entrydateList;	
}
%>
<%
cook cookx = new cook();
String center = cookx.getCookieValue("center", request.getCookies());
String centername = cookx.getCookieValue("centername", request.getCookies());
rcDisplayData display = new rcDisplayData(request.getRealPath("/"));
rcUserInfo userinfo = new rcUserInfo(request.getRealPath("/"));		

Date cur_date = new Date();
SimpleDateFormat dde = new SimpleDateFormat("dd/MM/yyyy");
String today = dde.format(cur_date);

String setDate="";
setDate = request.getParameter("searchDate");

//presList = getPrescriptionList(setDate, center, display, userinfo,session);

SecretKey cryptoKey = getSecretKey(session);
Crypto crypto = new Crypto(cryptoKey);
JSONObject result = new JSONObject();
String presList = "";
String ar="";    
String prescId="";
Object presListObj = display.getPrescriptionList(setDate, center);
	if(presListObj instanceof String){
		presList +="<tr><td colspan=5 align=center>No Data Available</td></tr>";	
	}
	else{
		Vector tmp = (Vector)presListObj;
		for(int i=0;i<tmp.size();i++){
			dataobj temp = (dataobj) tmp.get(i);
			if(printedPres(setDate, display).contains(temp.getValue("entrydate").replaceAll("[\s-.-:]","")))
				presList += "<tr class='printed hide'>";
			else
				presList += "<tr>";		
			presList += "<td>"+temp.getValue("patname")+"</td>";
			presList += "<td>"+temp.getValue("pat_id")+"</td>";
			String entrydate = (temp.getValue("entrydate").length()>=19)?temp.getValue("entrydate").substring(11,19):temp.getValue("entrydate");
			presList += "<td>"+entrydate+"</td>";
			presList += "<td>"+userinfo.getName(temp.getValue("docrg_no"))+"</td>";
			//presList += "<td class='pres-preview'><a href=previewPres.jsp?id="+temp.getValue("pat_id")+"&ty="+temp.getValue("tablename")+"&sl="+temp.getValue("serno")+"&dt="+java.net.URLEncoder.encode( temp.getValue("entrydate"), "UTF-8" )+" target='_blank'>Preview</a></td></tr>";
            ar+="id="+temp.getValue("pat_id")+"&ty="+temp.getValue("tablename")+"&sl="+temp.getValue("serno")+"&dt="+temp.getValue("entrydate")+"#";
			String PATID=temp.getValue("pat_id");
			String PREID=temp.getValue("preid");
			String pdfpath="getFile.jsp?file="+URLEncoder.encode(crypto.encrypt("/data/"+PATID+"/"+PATID+"_"+PREID+".pdf"), StandardCharsets.UTF_8);
			prescId+=PREID+"#";
			presList += "<td class='pres-preview'><a href=getFile.jsp?file="+URLEncoder.encode(crypto.encrypt("/data/"+PATID+"/"+PATID+"_"+PREID+".pdf"), StandardCharsets.UTF_8)+" target='_blank'>Preview</a></td></tr>";
            
		}
	}
    
    if(ar.length()>0 && ar.charAt(ar.length()-1)=='#')        
    {
        result.put("ar",ar.substring(0,ar.length()-1));        
    }
    else
    {
        result.put("ar",ar);    
    }

    if(prescId.length()>0 && prescId.charAt(prescId.length()-1)=='#')        
    {
        result.put("prescId",prescId.substring(0,prescId.length()-1));        
    }
    else
    {
        result.put("prescId",prescId);    
    }
    result.put("data",presList);
    //result.put("ar",ar);
    //result.put("prescId",prescId);
    out.println(result);
    //out.println(presList);
%>