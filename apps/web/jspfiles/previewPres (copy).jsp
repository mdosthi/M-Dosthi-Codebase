<%@page contentType="text/html" import= "java.io.*,imedix.projinfo,imedix.rcDataEntryFrm,imedix.rcUserInfo,imedix.rcGenOperations,imedix.medinfo,imedix.rcCentreInfo,imedix.rcDisplayData,imedix.cook, imedix.dataobj,imedix.myDate, java.util.*,java.io.*,java.text.*"%>
<%@page import="com.itextpdf.text.*,com.itextpdf.text.pdf.*, com.itextpdf.text.html.simpleparser.HTMLWorker,java.net.*,java.io.*,com.itextpdf.tool.xml.XMLWorkerHelper" %>
<%@page import="org.apache.commons.codec.binary.Base64"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%
		cook cookx = new cook();
		rcDisplayData ddinfo=new rcDisplayData(request.getRealPath("/"));
		rcUserInfo uinfo=new rcUserInfo(request.getRealPath("/"));
		rcCentreInfo cinfo = new rcCentreInfo(request.getRealPath("/"));

		String patName = "", patAge = "", patSex = "",localCenter = "", patId="";
		medinfo minfo = new medinfo(request.getRealPath("/"));
		localCenter = cookx.getCookieValue("center",request.getCookies());



		String frmname,islocal="";
		frmname=request.getParameter("ty");
		String tableName = frmname;
		frmname=frmname+"-"+request.getParameter("sl")+"#";
		islocal=cookx.getCookieValue("node", request.getCookies ());

		Date currDate = new Date();
		SimpleDateFormat formatedDate = new SimpleDateFormat("dd-MM-yyyy");
		SimpleDateFormat DayName = new SimpleDateFormat("EEEE");
		SimpleDateFormat formatedtime = new SimpleDateFormat("h:mm a");

		String visitDate = formatedDate.format(currDate);
		String day = DayName.format(currDate);
		String time = formatedtime.format(currDate);

		String ccode= cookx.getCookieValue("center", request.getCookies ());
		String cname = cookx.getCookieValue("centername", request.getCookies ());

		projinfo pinfo=new projinfo(request.getRealPath("/"));

%>



<%!
String symptomsDate = "";
public String symptoms(String id,rcDisplayData ddinfo) throws Exception{
	String result="";
	Object res = ddinfo.latestData(id,"a14");
		Vector tmp = (Vector)res;
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
				symptomsDate = temp.getValue("testdate").substring(0,10);
				if(!comp1.equals(""))
					result += "<li class='list-group-item'><label>"+comp1 +"</label><span class='pull-right'>"+dur1 +" "+hdmy1+"</span></li>";
				if(!comp2.equals(""))
					result += "<li class='list-group-item'><label>"+comp2 +"</label><span class='pull-right'>"+dur2 +" "+hdmy2+"</span></li>";
				if(!comp3.equals(""))
					result += "<li class='list-group-item'><label>"+comp3 +"</label><span class='pull-right'>"+dur3 +" "+hdmy3+"</span></li>";
				if(!rh.equals(""))
					result += "<li class='list-group-item'><label>Records </label><span class='pull-right'>"+rh+"</span></li>";
		}
	return result;
}
public String getsymptomsDate(){
	String sdate="";
	try{
	SimpleDateFormat getDateFormat = new SimpleDateFormat("yyyy-MM-dd");
	SimpleDateFormat setDateFormat = new SimpleDateFormat("dd-MM-yyyy");
	sdate = setDateFormat.format(getDateFormat.parse(symptomsDate));
	}catch(Exception ex){
		sdate=""; //ex.toString();
	}
	return sdate;
}

%>



<HTML>
<HEAD>
<style>
 
</style>
<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/previewPres.css" type="text/css" />
<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/prcsPrntpdf.css" type="text/css" />
<script src="<%=request.getContextPath()%>/bootstrap/jquery-2.2.1.min.js"></script>
<SCRIPT LANGUAGE="JavaScript">

$(document).ready(function(){


	$(".prcs-print").unbind('click').click(function(){
		printPage();
	});


});

function printPage(){
	if(navigator.userAgent.toLowerCase().indexOf('chrome') > -1) {
	    var popupWin = window.open();
	    popupWin.window.focus();
		popupWin.document.write('<html><head><title></title>');
		popupWin.document.write("<link rel=\"stylesheet\" href=\"<%=request.getContextPath()%>/bootstrap/css/prcsPrntpdf.css\" type=\"text/css\" media=\"print\"/>");
		popupWin.document.write('</head><body onload="window.print()">');
		popupWin.document.write($(".prescription-ajax").html());
		popupWin.document.write('</body></html>');
	    popupWin.onbeforeunload = function (event) {
	        return 'Please use the cancel button on the left side of the print preview to close this window.\n';
	    };
	}else {
	    var popupWin = window.open('', '_blank', 'width=600,height=600,scrollbars=no,menubar=no,toolbar=no,location=no,status=no,titlebar=no');
			popupWin.document.write('<html><head><title></title>');
			popupWin.document.write("<link rel=\"stylesheet\" href=\"<%=request.getContextPath()%>/bootstrap/css/prcsPrntpdf.css\" type=\"text/css\" media=\"print\"/>");
			popupWin.document.write('</head><body onload="window.print()">');
			popupWin.document.write($(".prescription-ajax").html());
			popupWin.document.write('</body></html>');
	}
	popupWin.document.close();	
	setTimeout(function () {
	popupWin.focus();
	popupWin.close();
	window.close();  
	}, 1000)


}



function setvalue(val)
{
	if(val==true)
	{
	var prevalue;
	var newval;
	newval = <%out.println("'"+ frmname + "'");%>
	prevalue=getCookie("selfrm");
	if(prevalue == null) prevalue="";
	prevalue=prevalue+newval;
	document.cookie="selfrm="+prevalue;
	//alert(getCookie("selfrm"));
	}
	else
	{
	var arr,prevalue,i,nval="";
	var newval;
	newval = <%out.println("'"+ frmname + "'");%>
	prevalue=getCookie("selfrm");
	document.cookie="selfrm="+"";
	arr=prevalue.split("#");
	for(i=0;i<arr.length;i++)
	{
	if(arr[i]+"#" != newval)
	{
	 nval+=arr[i]+"#";
	}
	}
	nval=nval.substring(0,nval.length-1);
	document.cookie="selfrm="+nval;
	//alert(getCookie("selfrm"));
	}
}

function getCookie(name) {    // use: getCookie("name");
    var bikky;
	bikky = document.cookie;
	var index = bikky.indexOf(name + "=");
    if (index == -1) return null;
    index = bikky.indexOf("=", index) + 1;
    var endstr = bikky.indexOf(";", index);
    if (endstr == -1) endstr = bikky.length;
    return unescape(bikky.substring(index, endstr));
  }



//-->
</SCRIPT>
</HEAD>
<BODY>
<div class="row">	
<div class="col-sm-2"></div>	
<div class="col-sm-8">
	<div><button class="btn btn-info prcs-print">Print</button></div>
<div class="prescription-ajax">

 <%

	boolean found=false;
	//String pval="";

	String ty="",id="",dt="",sl="";

	//String dat = dt.substring(0,2)+dt.substring(3,5)+dt.substring(6,10);
	//dt = myDate.getFomateDate("ymd",true,dat);



	try{
		ty = request.getParameter("ty").toLowerCase();
		id = request.getParameter("id");
		dt = request.getParameter("dt");
		sl = request.getParameter("sl");


		rcGenOperations rcGen=new rcGenOperations(request.getRealPath("/"));
		String pat_name_query="trim(CONCAT(IFNULL(pat_name,'') , ' ' , IFNULL(m_name,''), ' ' , IFNULL(l_name,''))) as pat_name";
		Object res=rcGen.findRecords("med",pat_name_query+",class,sex","pat_id='"+id+"'");
		Vector tmp = (Vector)res;
		dataobj temp = (dataobj) tmp.get(0);
		patName = temp.getValue("pat_name");
		patSex = temp.getValue("sex");
		patSex = minfo.getSexValues().getValue(patSex);
		String cdat = myDate.getCurrentDate("ymd",true);
		patAge = rcGen.getPatientAgeYMD(id,cdat);


		//out.println(ty+" : "+id+" : "+dt+" : "+sl );
		}catch(Exception ex){out.println(ex.toString());}


	String pdt="",dt1="",phoscode="",dreg_no="";

	dataobj objpre=null;
	Object res=ddinfo.DisplayFrm(ty,id,dt,sl);

	if(res instanceof String){
		out.println("</br>center><h1> Data Not Available </h1></center>");
		out.println("</br><center><h1> " +  res+ "</h1></center>");
		return;
	}
	else{
		Vector tmp = (Vector)res;
		if(tmp.size()>0) {
			objpre = (dataobj) tmp.get(0);
			phoscode=objpre.getValue("name_hos");
			dreg_no=objpre.getValue("docrg_no");
		}
	}

	rcDataEntryFrm def=new rcDataEntryFrm(request.getRealPath("/"));
	def.prescriptionPrinted(id, ty, dt, sl, dreg_no);
	Object res1=def.findDocbanner(dreg_no);
	Vector vtemp = (Vector)res1;
	//out.println(vtemp.size());
	String bannerpath="",avail="";
	if(vtemp.size()>0){
		dataobj ddobj = (dataobj)vtemp.get(0);
		bannerpath = String.valueOf(ddobj.getValue("path"));
		avail = String.valueOf(ddobj.getValue("avail"));
		//docname = String.valueOf(ddobj.getValue("docname"));
	}


	Object presInfoData = cinfo.presInfoData(id,dt,tableName);
	String assignedDoc = "", department="", centerCode="",patOPDno="",noofvisit="",regDate="";
		try {
			if(presInfoData instanceof String){
				out.println("</br><center><h1> Data Not Available </h1></center>");
				out.println("</br><center><h1> " + presInfoData+ "</h1></center>");
			}
			else{
				Vector tmp = (Vector)presInfoData;
				if(tmp.size()>0) {
					dataobj datatemp = (dataobj) tmp.get(0);
						assignedDoc = datatemp.getValue("name");
						department = datatemp.getValue("dis");
						centerCode = datatemp.getValue("center");
						patOPDno = datatemp.getValue("opdno");
						noofvisit = datatemp.getValue("noofvisit");
						regDate = datatemp.getValue("regDate");
					}
			}
  		}
		catch (Exception e)
		{
		out.println("</br>"+e);
		}

		String filePath1 = request.getRealPath(""+pinfo.gbldata+"/HospitalLogo/"+centerCode+"")+"/";
		File folder=new File(filePath1);
		String filePath="";
		boolean FILE=false;
		if(folder.exists())
		{
		File f=new File(request.getRealPath(""+pinfo.gbldata+"/HospitalLogo/"+centerCode+""));
		String[] fileList = f.list();
		filePath+=request.getContextPath()+"/data/HospitalLogo/"+centerCode+"/"+fileList[0];
		File f1=new File(filePath1+fileList[0]);
		FILE=f1.exists();
		}

		String b_filePath1 = request.getRealPath(""+pinfo.gbldata+"/HospitalBanner/"+centerCode+"")+"/";
		File b_folder=new File(b_filePath1);
		String b_filePath="";
		boolean b_FILE=false;
		if(b_folder.exists())
		{
		File b_f=new File(request.getRealPath(""+pinfo.gbldata+"/HospitalBanner/"+centerCode+""));
		String[] b_fileList = b_f.list();
		b_filePath+=request.getContextPath()+"/data/HospitalBanner/"+centerCode+"/"+b_fileList[0];
		File b_f1=new File(b_filePath1+b_fileList[0]);
		b_FILE=b_f1.exists();
		}
		String CenterNAME=cinfo.getHosName(centerCode);





	Object clinicalNotes = ddinfo.latestData(id,"p47");
		String temperature="NIL",resprate="NIL",pulse="NIL",bldpres="NIL",pulox="NIL",entrydate="";
		try{
			if(clinicalNotes instanceof String){
				out.println("</br><center><h1> Data Not Available </h1></center>");
				out.println("</br><center><h1> " + clinicalNotes+ "</h1></center>");
			}
			else{
				Vector tmp = (Vector)clinicalNotes;
					if(tmp.size()>0){
						dataobj datatemp = (dataobj)tmp.get(0);
						if(datatemp.getValue("temperature").length()>0)
							temperature = datatemp.getValue("temperature");
						if(datatemp.getValue("resprate").length()>0)
							resprate = datatemp.getValue("resprate");
						if(datatemp.getValue("pulse").length()>0)
							pulse = datatemp.getValue("pulse");
						if(datatemp.getValue("bldpres").length()>0)
							bldpres = datatemp.getValue("bldpres");
							//bldpres = bldpres.replace("-","/");
						if(datatemp.getValue("pulox").length()>0)
							pulox = datatemp.getValue("pulox");

						try{
							SimpleDateFormat getDateFormat = new SimpleDateFormat("yyyy-MM-dd");
							SimpleDateFormat setDateFormat = new SimpleDateFormat("dd-MM-yyyy");
							entrydate = setDateFormat.format(getDateFormat.parse(datatemp.getValue("testdate").substring(0,10)));
						}catch(Exception ex){entrydate=ex.toString();}

					}
				}
		}catch(Exception ex){out.println("</br>"+ex);}


		String local_hosName = cinfo.getHosName(localCenter);

	String hosname=cinfo.getHosName(phoscode);

	//out.println(centerCode);

	if(tableName.equalsIgnoreCase("pre")) hosname="********";
	//Object resu=uinfo.getValues("name,phone,emailid,qualification"," rg_no like '"+dreg_no+"%'" );
	Object resu=uinfo.getValues("name,doc_regno,phone,emailid,qualification"," rg_no like '"+dreg_no+"%'" );
	Object resmed=ddinfo.DisplayMed(id,"","");

		//if(islocal.length()==0)
		//{
		//telemedicin req
			String utype="";
			utype = cookx.getCookieValue("usertype", request.getCookies ());

			String selfrm,thisfrm;
			int hasthisfrm=0;
			selfrm = cookx.getCookieValue("selfrm", request.getCookies ());
			thisfrm = frmname;

		//	out.println("selfrm: "+selfrm);

			if(!selfrm.equals(""))
			{
				try
				{
					String str[]=selfrm.split("#");
					for(int k=0;k<str.length;k++)
					{
						if(thisfrm.equals(str[k]+"#"))
						{
						found = true;
						break;
						}
						else
						{
						found=false;
						}
					} //end of for loop
				} catch(ArrayIndexOutOfBoundsException e1)
				{ }

			}


	//}
///////////////////////



		/*int tag=0;
			Object Objtmp = Vres.get(1);
			if(Objtmp instanceof String){ tag=1;}
			else{
				Vector Vtmp = (Vector)Objtmp;
				if(Vtmp.size()>1 ) {
					String sn;
					out.println("<tr><td>View Other : ");
					out.println("<SELECT class='form-control input-sm noofPres' NAME=abc >"); //showselected(abc.value);
					out.println("<option></option>");
					for(int i=0;i<Vtmp.size();i++){
						dataobj datatemp = (dataobj) Vtmp.get(i);
						pdt = datatemp.getValue("date");
						dt1 = pdt.substring(8,10)+"/"+pdt.substring(5,7)+"/"+pdt.substring(0,4);
						sn=datatemp.getValue("serno");
						//if(sn.length()<2)  sn= "0" + sn;
					//	out.println("<option value='id="+id+"&ty="+ty+"&sl="+sn+"&dt="+pdt+"' >"+ty+"-"+sn+"</option>");
						out.println("<option value='id="+id+"&ty="+ty+"&sl="+sn+"&dt="+pdt+"' >"+dt1+"-"+sn+"</option>");
					}
					out.println("</SELECT></TD></TR></form></TABLE>");
				}
				else out.println("</TR></form></TABLE>");

			}
			if(tag==1) out.println("</TR></form></TABLE>");*/

%>









	<%
		String docname="",docqlt="",rgno="",docphone="",docmail="",doc_regno="";

		try {


			if(resu instanceof String){
				out.println("</br><center><h1> Data Not Available </h1></center>");
				out.println("</br><center><h1> " +  resu+ "</h1></center>");
			}
			else{
				Vector tmp = (Vector)resu;
				if(tmp.size()>0) {
					dataobj datatemp = (dataobj) tmp.get(0);
						docname=datatemp.getValue("name");
						docphone = datatemp.getValue("phone");
						docmail = datatemp.getValue("emailid");
						docqlt = datatemp.getValue("qualification");
						doc_regno = datatemp.getValue("doc_regno");
						//System.out.println(docphone+"-"+doc_regno);
					}
			}

			if(docname=="") docname="< Plz Import Doctor >";
			else docname=docname.toUpperCase();
  		}
		catch (Exception e)
		{
		out.println("</br>"+e);
		}

	%>

	<div class="row">
	<div class="col-sm-12 hospitalName-div">

<% if(tableName.equalsIgnoreCase("pre")){%>
	<div class="title"><label> <%=local_hosName%> (Nodal Prescription)</label><span id="" class="prcs-print glyphicon glyphicon-print pull-right"></span><span id="" class="prcs-email glyphicon glyphicon-envelope pull-right"></span></div>
<%}%>
<% if(tableName.equalsIgnoreCase("prs")){%>
	<div class="title"><label> <%=hosname%> (Referral Prescription)</label><span id="" class="prcs-print glyphicon glyphicon-print pull-right"></span><span id="" class="prcs-email glyphicon glyphicon-envelope pull-right"></span></div>
<%}%>
	</div>
	</div>
	<div class="row pres-heading">
		<!--<div class="col-sm-7 heading-title">GOVERNMENT OF WEST BENGAL <br/>DEPARTMENT OF HEALTH AND FAMILY WELFARE<span>Telemedicine Prescription</span></div>-->
		<!--<div class="col-sm-7 heading-title"><%=CenterNAME%><span>Telemedicine Prescription</span></div>-->
		<%
            File f = new File(request.getRealPath("/")+"/images/health-logo.png");      //change path of image according to you
            FileInputStream fis = new FileInputStream(f);
            byte byteArray[] = new byte[(int)f.length()];
            fis.read(byteArray);
            //String imageFile = request.getContextPath()+"/images/health-logo.png";
            //byte[] img = FileUtils.readFileToByteArray(inputFile);
            byte[] imgByteArray = Base64.encodeBase64(byteArray);
            String imgEncoded = new String(imgByteArray);
            fis.close();
        %>

        <!--<div class="col-sm-5 pres-logo"><img src="data:image/png;base64,<%=imgEncoded%>" /></div>-->
				<% if(avail.equalsIgnoreCase("Y")) { %>
				<div class="col-sm-5 pres-banner"><img src="<%= bannerpath %>" /></div>

				<% } else if(b_FILE) { %>
				<div class="col-sm-5 pres-banner"><img src="<%= b_filePath %>" /></div>
				<% } else if(FILE) { %>
				<div class="col-sm-5 pres-logo"><img src="<%= filePath %>" /></div>
				<% } %>

		<!-- <div class="col-sm-5 pres-logo"><img src="<%=request.getContextPath()%>/images/health-logo.png" alt="Prescription"  /></div> -->
	</div>
	<div class="row pres-heading2">
		<legend class="title2" ><span>&nbsp;&nbsp;&nbsp;Dr.&nbsp;<%=docname.toUpperCase()%></span><span style="margin-left:15%;">Regn.No.:<%=doc_regno%></span><span class="pull-right">Ph:<%=docphone%></span></legend>
	</div>

	<div class="row pres-heading2">
		<!--<legend class="title2" ><%=CenterNAME%><span>Telemedicine Prescription</span></legend>-->
		<% if(tableName.equalsIgnoreCase("pre")){%>
		<legend class="title2" ><%=CenterNAME%><span>&nbsp;&nbsp;&nbsp;(Telemedicine Prescription)</span></legend>
		<%}%>
		<% if(tableName.equalsIgnoreCase("prs")){%>
		<legend class="title2" ><%=CenterNAME%><span>&nbsp;&nbsp;&nbsp;(Telemedicine Referral Prescription)</span></legend>
		<%}%>

	</div>


<div class="row">
<div class="col-sm-12 dispres" >

	<div class="pat-info-prcs">
		<fieldset>
		<legend class="title">Patient Information</legend>
			<div class="pat-prof-summ">
				<div class="col-sm-6">
				<ul class="list-group">
					<li class="list-group-item align-right"><span class="pull-left">NAME : </span><span><%=patName%></span></li>
					<li class="list-group-item align-right"><span class="pull-left">SEX : </span><span><%=patSex%></span></li>
					<li class="list-group-item align-right"><span class="pull-left">AGE : </span><span><%=patAge%></span></li>
					<li class="list-group-item align-right"><span class="pull-left">Local Hospital : </span><span><%=local_hosName%></span></li>
					<li class="list-group-item align-right"><span class="pull-left">Referral Hospital : </span><span><%=hosname%></span></li>
					<li class="list-group-item align-right"><span class="pull-left">Department : </span><span><%=department%></span></li>
					<li class="list-group-item align-right"><span class="pull-left">Doctor : </span><span><%=assignedDoc%></span></li>
				</ul>
				</div>
				<div class="col-sm-6 ">
				<ul class="list-group">
					<li class="list-group-item align-right"><span class="pull-left">Patient Id : </span><span><%=id%></span></li>
					<li class="list-group-item align-right"><span class="pull-left">Reg. Date : </span><span><%=regDate%></span></li>
					<li class="list-group-item align-right"><span class="pull-left">Card No : </span><span><%=patOPDno%></span></li>
					<li class="list-group-item align-right"><span class="pull-left">Visit No : </span><span><%=noofvisit%></span></li>
					<li class="list-group-item align-right"><span class="pull-left">Visit Date : </span><span><%=visitDate%></span></li>
					<li class="list-group-item align-right"><span class="pull-left">Time : </span><span><%=time%></span></li>
					<li class="list-group-item align-right"><span class="pull-left">Day : </span><span><%=day%></span></li>
				</ul>
				</div>
			</div>
		</fieldset>
	</div>
	<div class="clinicalNotes">
		<fieldset>
			<legend class="title">Clinical Notes (<%=entrydate%>)</legend>
			<table class="table">
			<thead>
				<tr><td>Temperature</td><td>Respiratory Rate</td><td>Pulse</td><td>Blood Pressure</td><td>Pulse Oximeter</td></tr>
			</thead>
			<tbody>
				<tr><td><%=temperature%></td><td><%=resprate%></td><td><%=pulse%></td><td><%=bldpres%></td><td><%=pulox%></td></tr>
			</tbody>
			</table>
		</fieldset>
	</div>
	<div class="chiefComp">
		<fieldset>
			<legend class="title">Symptoms (<%=getsymptomsDate()%>)</legend>
			<div class="pres-symptoms">
				<%=symptoms(id,ddinfo)%>
			</div>
		</fieldset>
	</div>
	<div class="diagn">
		<fieldset>
		<legend class="title">DIAGNOSIS</legend>
			<div class="diagn-report">
				<%=objpre.getValue("diagnosis") %>
			</div>
		</fieldset>
	</div>
	<div class="advice">
		<fieldset>
		<legend class="title">ADVICE</legend>
			<div class="advice-field">
				<%=objpre.getValue("advice") %>
			</div>
		</fieldset>
	</div>



<div class="medinice">
	<fieldset>
	<legend class="title">MEDICINE</legend>
		<div class="drug">

<div class="table-responsive">
<%	 String A, B, C, D, E;
	A = objpre.getValue("drugs");

if(!A.equals("null") && !A.equals(""))
{

out.println("<TABLE class='table'>");

out.println("<thead><TR>");
out.println("<TD>Drugs</TD>");

out.println("<TD>Quantity</TD>");

out.println("<TD>Dose</TD>");
out.println("<TD>Duration</TD>");
out.println("<TD>Comments</TD>");

out.println("</TR></thead><tbody>");

	B = objpre.getValue("quantity");
	C = objpre.getValue("dose");
	D = objpre.getValue("duration");
	E = objpre.getValue("comments");

	String aa[]=A.split("!");
	String bb[]=B.split("!");
	String cc[]=C.split("!");
	String dd[]=D.split("!");
	String ee[]=E.split("!");

	int xx=aa.length;

	//out.println("A="+xx+" dd="+dd.length+" E="+ee.length);
	//	A=A+"!";
	//	B=B+"!";
	//	C=C+"!";
	//	D=D+"!";
	//	E=E+"!";
		//}

	/*A = A.replace('!', ' ');
	B = B.replace('!', ' ');
	C = C.replace('!', ' ');
	D = D.replace('!', ' ');
	E = E.replace('!', ' '); */

	StringTokenizer stA = new StringTokenizer(A, "!");
	StringTokenizer stB = new StringTokenizer(B, "!");
	StringTokenizer stC = new StringTokenizer(C, "!");
	StringTokenizer stD = new StringTokenizer(D, "!");
	StringTokenizer stE = new StringTokenizer(E, "!");

int ii=0;
String comee="";


 while (stA.hasMoreTokens()) {

		out.println("<TR>");
		out.println("<TD>"+ stA.nextToken() + "</TD>");

	if(ii<bb.length)
	comee=bb[ii];
 	else comee="-";

		out.println("<TD>"+ comee + "</TD>");


	if(ii<cc.length)
	comee=cc[ii];
 	else comee="-";

		out.println("<TD>"+ comee + "</TD>");

 if(ii<dd.length)
	comee=dd[ii];
 else comee="-";

		out.println("<TD>"+ comee + "</TD>");


 if(ii<ee.length)
 	comee=ee[ii];
 else comee="-";

	out.println("<TD>"+comee + "</TD>");

   out.println("</TR>");

	ii++;
	}

	}


	String appdt=objpre.getValue("apptdate");

	if(appdt.length()==0) appdt="";
	else appdt= appdt.substring(8,10)+"-"+appdt.substring(5,7)+"-"+appdt.substring(0,4);
	String edt=objpre.getValue("entrydate");
	edt= edt.substring(8,10)+"-"+edt.substring(5,7)+"-"+edt.substring(0,4);

%>
</tbody></TABLE>
<TABLE class="table ">
<TR>	<TD  Align=Left><B><U><FONT  COLOR="Brown">Appointment Date</FONT></U>
	<%= appdt %></B></br><B><U><FONT  COLOR="Brown">Entry Date</FONT></U>
	<%= edt %></B></TD>
	<TD Align=Right><B><%out.println(docname.toUpperCase());
	%></br></B> Computer Generated Documents need not be Signed
	</TD>
</TR>
</TABLE>
</div></div>
</div>		<!-- "table-responsive" -->
		</div>
	</fieldset>
</div>
</div>
</div>
<div class="col-sm-2"></div>
</div>
</body>

</html>
