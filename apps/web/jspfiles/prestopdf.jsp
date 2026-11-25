<%@page contentType="text/html" import= "imedix.rcUserInfo,imedix.medinfo,imedix.rcCentreInfo,imedix.rcDisplayData,imedix.cook, imedix.dataobj,imedix.myDate,imedix.Email,java.util.*,java.io.*,java.text.*"%>
<%@page import="com.itextpdf.html2pdf.ConverterProperties"%>
<%@page import="com.itextpdf.html2pdf.HtmlConverter"%>
<%@page import="com.itextpdf.kernel.pdf.PdfDocument"%>
<%@page import="com.itextpdf.kernel.pdf.PdfWriter"%>
<%@page import="com.itextpdf.layout.Document"%>
<%@page import="com.itextpdf.layout.element.Table"%>
<%@page import="com.itextpdf.layout.property.UnitValue"%>
<%@page import="java.util.logging.Level"%>
<%@page import="java.util.logging.Logger"%>
<%@page import="org.apache.commons.codec.binary.Base64"%>
<%
	String presBody = "", patId = "", fileGenErrors="", presUID = "";
	try {
		cook cookx = new cook();
		patId = cookx.getCookieValue("patid",request.getCookies());
		
		rcUserInfo uinfo=new rcUserInfo(request.getRealPath("/"));
		Object res=uinfo.getuserinfo(patId);
		Vector tmp = (Vector)res;

		dataobj temp = (dataobj) tmp.get(0);
		String emailid = (String) temp.getValue("emailid");
		String patname = (String) temp.getValue("name");
		//out.println ( "emailid : " + emailid );
		//out.println ( "patname : " + patname );

		
		
		presBody = request.getParameter("data");
		presUID = request.getParameter("presuid");
		byte[] decodedData = Base64.decodeBase64(presBody.getBytes());
		presBody = new String(decodedData);

		String tempFN = patId + "_" + presUID + ".pdf";
		String tempFFN = request.getRealPath("/")+"data/"+patId+"/"+tempFN;
		File pdf = new File(tempFFN);
		if(pdf.exists()){
			out.println("Prescription File: "+tempFFN + " already exist");
		}else{
			out.println("Generating prescription: "+ tempFFN);
		String fileName = request.getRealPath("/")+"bootstrap/css/prcsPrntpdf.css";

		FileInputStream fis = new FileInputStream(fileName);
		byte[] buffer = new byte[10];
		StringBuilder sb = new StringBuilder();
		while (fis.read(buffer) != -1) {
		sb.append(new String(buffer));
		//buffer = new byte[10];
		}
		fis.close();

		String cssContent = sb.toString();


		String htmlString = "<!DOCTYPE html><head>"+
		"<style>"+cssContent+"</style></head><body>"+presBody+"</body></html>";

		String tempFileName = patId + "_" + presUID + ".pdf";
		String tempFullFileName = request.getRealPath("/")+"data/"+patId+"/"+tempFileName;
		
		// generate html for css correction
			/*
			String tempHtml = patId + "_" + presUID + ".html";
			String tempFullHtml = request.getRealPath("/")+"data/"+patId+"/"+tempHtml;

			File fHtml = new File(tempFullHtml);
			FileWriter writer = new FileWriter(fHtml);
			writer.write(htmlString);
			writer.flush();
			writer.close();
			*/
		// generate html end

		out.println ( "tempFileName : " + tempFileName );
		out.println ( "tempFullFileName : " + tempFullFileName );
		File presDir = new File(request.getRealPath("/")+"data/"+patId);
		if(!presDir.exists()) presDir.mkdirs();

		File pdfDest = new File(tempFullFileName);
		fileGenErrors += tempFullFileName + "<br>";
		// pdfHTML specific code
		ConverterProperties converterProperties = new ConverterProperties();
		HtmlConverter.convertToPdf(htmlString,new FileOutputStream(pdfDest), converterProperties);
		out.println("pdf creation done. Emailed");
		fileGenErrors = " Prescription created and Emailed : ";
		}

	} catch (Exception e) {
		e.printStackTrace();
		System.out.println("pdf generation has some errors");
		fileGenErrors = " Prescription generated some errors : " + e;
	}
%>
<%=fileGenErrors%>
