<!--/*Surajit*/-->
<%@page contentType="text/html" import= "java.io.*,imedix.projinfo,imedix.rcDataEntryFrm,imedix.rcUserInfo,imedix.medinfo,imedix.rcCentreInfo,imedix.rcDisplayData,imedix.cook, imedix.dataobj,imedix.myDate, java.util.*,java.io.*,java.text.*, imedix.Crypto, javax.crypto.*, java.net.URLEncoder, java.nio.charset.StandardCharsets"%>
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

public String getPrescriptionList(String setDate, String center, rcDisplayData display, rcUserInfo userinfo,HttpSession session) throws Exception{
	String presList = "";
	cook cookx = new cook();
	SecretKey cryptoKey = getSecretKey(session);
	Crypto crypto = new Crypto(cryptoKey);
	Object presListObj = display.getPrescriptionList(setDate, center);
	if(presListObj instanceof String){
		return "<tr><td colspan=5 align=center>No Data Available</td></tr>";	
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
			String PATID=temp.getValue("pat_id");
			String PREID=temp.getValue("preid");
			String pdfpath="getFile.jsp?file="+URLEncoder.encode(crypto.encrypt("/data/"+PATID+"/"+PATID+"_"+PREID+".pdf"), StandardCharsets.UTF_8);
			
			presList += "<td class='pres-preview'><a href=pdfpath target='_blank'>Preview</a></td></tr>";
		}
	}
	return presList;	
}

%>

<%
String setDate="";
Date cur_date = new Date();
SimpleDateFormat dde = new SimpleDateFormat("dd/MM/yyyy");
String today = dde.format(cur_date);
setDate = today;	

	cook cookx = new cook();
	String center = cookx.getCookieValue("center", request.getCookies());
	String centername = cookx.getCookieValue("centername", request.getCookies());

rcDisplayData display = new rcDisplayData(request.getRealPath("/"));
rcUserInfo userinfo = new rcUserInfo(request.getRealPath("/"));		

String presList = "";
int totalPres = 0;					
if(request.getMethod().equalsIgnoreCase("POST") && request.getParameter("viewPresList") !=null){
	setDate = request.getParameter("presDate");
	presList = getPrescriptionList(setDate, center, display, userinfo,session);
}
else{
	setDate = myDate.getCurrentDate("dmy",true);
	presList = getPrescriptionList(setDate, center, display, userinfo,session);	
}					

					
%>
<html>
<!--<meta http-equiv="refresh" content="10">-->
<head>
	<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/bootstrap.min.css">
	<link rel="stylesheet" href="../bootstrap/bootstrap-datetimepicker.min.css">
	<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.css">
	<script src="../bootstrap/jquery-2.2.1.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/js/bootstrap.min.js"></script>
	<script src="../bootstrap/bootstrap-datetimepicker.min.js"></script>
	<script src="../bootstrap/bootstrap-datetimepicker.pt-BR.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/jquery.dataTables.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.js"></script>
</head>

<style>
.viewPrescriptions{

}
.heading-title{
	text-align: center;
}
.content-body{
    padding: 8px;
    box-shadow: 0px 0px 2px 0px #333;
    border-radius: 8px;
}
.disPresList table thead{
    background: #333;
    color: #ddd;	
    box-shadow: 0px 2px 4px 0px #333;
}
.disPresList table thead th{text-align: center;}
.disPresList table tbody tr{
	box-shadow:0px 2px 4px 0px #333;
	font-size: 14px;
}
.disPresList table tbody tr:hover{
	background: #eef;
	transition-duration: 0.4s;
}
.viewPrescriptions .glyphicon-calendar{
	color:#5ba9ec;
} 
.pres-preview{
	text-align: center;
}
.pres-preview a{
	text-decoration: none;
    background: #888;
    padding: 4px 8px;
    border-radius: 4px;
    color: #fff;
}
.pres-preview:hover, .pres-preview:focus{
	text-decoration: none;
	color:#07467d;
}
</style>

<script>
		let d = new Date();
	$(function () {
		endDate = new Date(d.getFullYear()+"-"+Number(d.getMonth()+1)+"-"+Number(d.getDate()+1)),
    	startDate = new Date("01/01/2018"),
        //endDate = new Date("<%=today%>");
		$('#log-datepicker').datetimepicker({
			weekStart: 1,
			todayBtn: 1,
			autoclose: 1,
			todayHighlight: 1,
			startView: 4,
			keyboardNavigation: 1,
			minView: 2,
			forceParse: 0,
			startDate: startDate,
			endDate: endDate,
			setDate: endDate
		});
	});	

$(document).ready(function(){
	$('[data-toggle="popover"]').popover();
	document.onkeyup=showHideRows; 	

	setInterval(function(){
		/*if(<%=setDate%>==<%=today%>)
	   		window.location.reload(1);*/
		console.log($("#presDate").val(),"<%=today%>");	   
		console.log($("#presDate").val()=="<%=today%>");
		if($("#presDate").val()=="<%=today%>")
		{
			display();	
		}
	}, 20000);
});


function display()
{
	var searchDate=$("#presDate").val();
	if(searchDate.trim()=="")
	{
		alert("Please choose a date!");
		$("#presDate").focus();
		return false;
	}

	var param = {searchDate:searchDate};
			$.ajax({
					type: 'GET',
					url: "GETviewPrescriptions.jsp",
					data: param,
					dataType: "text",
					success: function(data)
					{

						var res = JSON.parse(data);
						var pdata=res.data.trim();
						var ar=res.ar.trim();			
						ar=ar.split("#");
						var prescId=res.prescId.trim();
						prescId=prescId.split("#");

						$(".disPresList tbody").empty();
						$(".disPresList tbody").append(pdata.trim());
						
						for(let i=0;i<ar.length-1;i++){
							console.log(ar[i]);
							console.log(prescId[i]);
						var a="dispres1.jsp?"+ar[i];
						$.ajax({
						url: a,
						type: 'get',
						dataType: 'html',
						async: false,
						success: function(dat) {
							//res = data;
							//res=$("."+dt1.replace(/\//g,"")+"").append(data);
							encodedData = btoa(dat);
							//console.log("dispres1 called, link: "+a+" "+preid);
							$.post("prestopdf.jsp", {data: encodedData,presuid:prescId[i]}, function(dd){
							
									});	
								}
							});
						}
						
						//$('#presList').DataTable();
							//location.reload(true);
					}
			});
	
}

var tgl=true;
function toggle() {
    if(tgl){
    	$(".printed").removeClass("hide");
        $(".printed").attr("style","display:table-row; background:#0d99b9; color: #fff");
        }
    else{
        $(".printed").hide();
    }
    tgl=!tgl;
}
 function showHideRows (e) {
   var KeyID = (window.event) ? event.keyCode : e.keyCode;   
    if (KeyID==18){
        toggle();
    }
    //Enable any key hide
    /*else{
        $(".existingEmail").hide();
    }*/
}
</script>

<BODY class="viewPrescriptions">
	<div class="container-fluid">

		<h3 class="heading-title"> <B>View Prescription of <%=centername%> (<%=center%>)</B></h3>

		<div class="container-fluid content-body">
			
			<div class="row">
				<div class="col-sm-1"></div>
				<div class="col-sm-9">
				
						<div id="log-datepicker" class="input-append date input-group" style="margin:auto;max-width:320px;">
							<input data-format="dd/MM/yyyy" type="text" name="presDate" id="presDate" value="<%=setDate%>" class="form-control logCaln" required><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
						</div>
				
				<div class="col-sm-1">
					<input class="btn btn-info" type="submit" name="viewPresList" value="Search Prescription" onclick="display()" />
				</div>
				</form>
				<div class="col-sm-1"></div>
			</div>
			
			<div class="row">
				<div class="col-sm-12 table-responsive disPresList">
					<table class="table table-bordered">
					<thead>
					<tr>
						<th>Patient Name</th>
						<th> Patient ID</th>
						<th> Creation Time</th>
						<th> Assign Doctor</th>
						<th> Preview and Print</th>
					</tr>
					</thead>
					<tbody id="presListTable">	
						
					</tbody>
					</table>		
				</div>
			</div>
		</div>
	</body>	
</html>
