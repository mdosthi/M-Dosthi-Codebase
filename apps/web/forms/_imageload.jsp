<%@page language="java" import="imedix.cook,imedix.rcUserInfo,java.util.Date,java.text.SimpleDateFormat,imedix.myDate,imedix.projinfo,java.util.*,java.*" %>
<%@ include file="..//includes/chkcook.jsp" %>
<%
	String id,dat="",cen="",patid;
	cook cookx = new cook();
	id = cookx.getCookieValue("patid", request.getCookies());
	patid=id;
	cen = cookx.getCookieValue("center",request.getCookies());
	//out.print("&nbsp;<B><BR>&nbsp;<FONT SIZE='-1' COLOR='#FF0000'>" + System.getProperty("os.name")+ "</B></FONT><BR>");
	dat = myDate.getCurrentDate("dmy",false);
	rcUserInfo uinfo = new rcUserInfo(request.getRealPath("/"));
	int totalFile = Integer.parseInt(uinfo.fileUploadLimit(7,id));
	projinfo pr = new projinfo(request.getRealPath("/"));
	int allowedFileNo = Integer.parseInt(pr.maxFileUploadLimit);
	String cdate=myDate.getCurrentDate("dmy",false);
	String currdate=myDate.getCurrentDate("ymd",true);
	Date cur_date = new Date();
	SimpleDateFormat dde = new SimpleDateFormat("dd/MM/YYYY");
	String today = dde.format(cur_date);
%>
<!DOCTYPE html>
<HTML>
<head>   

<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>File Uploading</title>
	<link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
	
	<script src="../bootstrap/jquery-2.2.1.min.js"></script>
	<!--<script src="../bootstrap/js/bootstrap.min.js"></script>
	<script src="../bootstrap/js/bootstrap-filestyle.min.js"></script>-->
	<link rel="stylesheet" href="/M-Dosthi/bootstrap/bootstrap-datetimepicker.min.css">
	<script src="/M-Dosthi/bootstrap/bootstrap-datetimepicker.min.js"></script>
	<script src="/M-Dosthi/bootstrap/bootstrap-datetimepicker.pt-BR.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/html2canvas.js" type="text/javascript"></script>
	<SCRIPT LANGUAGE="JavaScript" SRC="../includes/script1.js"></SCRIPT>
	<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/jquery-ui.css">


<link rel="stylesheet" type="text/css" href="../style/style2.css">
<!--<SCRIPT LANGUAGE="JavaScript" SRC="../includes/script1.js"></SCRIPT>
<SCRIPT LANGUAGE="JavaScript" SRC="../includes/script2.js"></SCRIPT>-->
<SCRIPT LANGUAGE="JavaScript" SRC="../includes/chdateformat.js"/></SCRIPT>
<script>
function drop_evt(evt) {
	evt.preventDefault();
	document.getElementById("smallFile").files = evt.dataTransfer.files;
	document.getElementById("drop_div").innerHTML = evt.dataTransfer.files[0].name;
}
function dragOver_evt(evt) {
  evt.preventDefault();
} 
function setvalues() {
	document.imgld.desc.value = document.imgld.type.value + " File";
}
function datentry(){
	document.imgld.entrydate.value=GetMysqlCurrDateTime();
}

function MM_displayStatusMsg(msgStr) { //v1.0
  status=msgStr;
  document.MM_returnValue = true;
}
//-->

function fileCheck(){ 	
	if(document.getElementById('smallFile').value=="" || document.getElementById('smallFile').value == null){
		alert("Choose a file");
		return false;
	}
	return true;
}

function fileSizeCheck(){
	var sizeinbytes = document.getElementById('smallFile').files[0].size;
	var sizekb=sizeinbytes/1024;
	if(sizekb>=990){ 
		document.getElementById("fileSize").innerHTML=(sizekb/1024).toFixed(2)+" MB";
		let mb = Math.floor((sizekb/1024));
		if(mb > 9){
			document.getElementById('smallFile').value="";
			document.getElementById("fileSize").innerHTML = "Please upload less then 10 mb file";
			}
	}
	else{
		document.getElementById("fileSize").innerHTML=sizekb.toFixed(2)+" KB";
	}
} 
function filluptextForm(){
$("#Ldes").val($("input[name=imgdesc]").val());
$("#Llname").val($("input[name=lab_name]").val());
$("#LdocName").val($("input[name=doc_name]").val());
$("#Lftype").val($(".report-type").val());
	var file = document.getElementById('smallFile').files[0].name;
	 fileExtd = file.substring(file.lastIndexOf("."),file.length);
		$("#Lext").val(fileExtd);
}
function fileTypeChk(fTyps){
	var file = document.getElementById('smallFile').files[0].name;
	var fileExt = file.substring(file.lastIndexOf(".")+1,file.length);
	var obj = {
		"BLD":["png","jpeg","jpg","bmp"],
		"CTS":["png","jpeg","jpg","bmp"],
		"DCM":["dcm"],
		"DOC":["doc","docx","pdf","txt"],
		"EEG":["png","jpeg","jpg","bmp"],
		"MRI":["png","jpeg","jpg","bmp"],
		"MOV":["mp4","avi","mov","wmv"],
		"SEG":["png","jpeg","jpg","bmp"],
		"SKP":["png","jpeg","jpg","bmp"],
		"SNG":["png","jpeg","jpg","bmp"],
		"SND":["mp3","wav"],
		"TEG":["txt"],
		"XRA":["png","jpeg","jpg","bmp"],
		"OTH":["png","jpeg","jpg","bmp"]
		}
			if(obj[fTyps].indexOf(fileExt.toLowerCase())>=0){
				return true;
			}
			else{
				alert("Supported file is ["+obj[fTyps]+"]");
				return false;
			}
}
$(document).ready(function(){
	var totalFile = <%=totalFile%>;
	var noOFallowdfil = <%=allowedFileNo%>;
	
	$("select[name=type]").change(function(){
		fileTypeChk(this.value);
		$("#Lftype").val(this.value);
	});
	$("#reportUpload").submit(function(e){
		$("#testdate").val($("#datepicker-testdate").val().replace(/\//g, ''));
	e.preventDefault();
	//console.log(document.getElementById('testdate').value+"  "+'<%=dat%>');
	if(testdt(document.getElementById('testdate').value,'<%=dat%>')) return false;
	var data = new FormData(this);
	var uploadedFile = Number(<%=totalFile%>);

	$.ajax({
		type: "get",
		url: "noFileUploaded.jsp",
		success: function(data){
			uploadedFile = Number(data.trim());
		},
		complete:function(){
			let noAllowdFile = Number(<%=allowedFileNo%>);
			console.log(uploadedFile+" TT:TT "+noAllowdFile);
			if(uploadedFile<noAllowdFile){
				$.ajax({
					type:"POST",
					enctype: "multipart/form-data",
				//	url:"../servlet/uploadfilehttp",
					url:"../largefileupload/UploadFile.jsp",
					data:data,
					processData: false,
					contentType: false,
					cache: false,
					timeout: 600000,
					beforeSubmit : filluptextForm(),
					success:function(data){
						console.log(Number(data.trim())+"Uplodstatus"+data.trim());

						var ajax_load = "<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='loading...'>";
						$("#drop_div_html").html("Drop Here/Select File");
						$("#reportUpload")[0].reset();
							$("#reportUpload").append("<div class='uploading-report'>Uploading.....</div>");
						//$.post("../largefileupload/savepatchlfupload.jsp",{ftype:""+$("#Lftype").val()+"",ext:""+fileExtd+"",docName:""+$("#LdocName").val()+"",lname:""+$("#Llname").val()+"",desc:""+$("#Ldes").val()+""},function(data){
							$.post("/M-Dosthi/servlet/largefileupload",{stream:"<%=patid%>&"+$("#Lftype").val()+"&"+$("#Ldes").val()+"&"+$("#Llname").val()+"&"+$("#LdocName").val()+"&<%=currdate%>&<%=cdate%>&"+fileExtd.substring(1)+""},function(data){
							console.log("<%=patid%>&"+$("#Lftype").val()+"&"+$("#Ldes").val()+"&"+$("#Llname").val()+"&"+$("#LdocName").val()+"&<%=currdate%>&<%=cdate%>&"+fileExtd.substring(1)+"");
							$(".uploadedReport").html(ajax_load).load("recordmenu_new.jsp");
							$(".uploading-report").remove();
							alert("Data is Uploaded !");
							});
						},
					error:function(data){console.log(data);alert("Could not uploaded");}
				});
			}
			else{
				alert("You can upload maximum "+uploadedFile+" files only.");
				$(".upload-report").remove();
				}
			}
		});
	});

	$("#smallFile").change(function(){
		$("#drop_div_html").html(document.getElementById("smallFile").files[0].name+"<br><center>"+fileSizeCheck()+"</center>");
	});
	
});
				

</script>

<style>
.input-group-addon{
	min-width:13.2rem;
	}
.drop-div{
	border:1px solid black;
	height:100px;	
	position: relative;
}	
#smallFile{
	position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    opacity: 0;
}
</style>

</head>
<BODY background= "../images/pagebg.jpg" onload='datentry();' >
<div class="container-fluid">

<BR><BR>

<center>
<div class="row">
<!--<div class="col-sm-1"></div>-->

<div class="col-sm-10 tableb">

	<div class="upload-report"><!-- "Upload Report Start" -->
		<fieldset>
		<legend class="title">Upload Report</legend>
		<div>
					<div class="row">
					<div class="col-sm-12 tableb">
					<FORM name="imgld" id="reportUpload">
					<INPUT TYPE="hidden" name="pat_id" value="<%=patid%>">
					<div class="drop-div" id="drop_div" ondrop = "drop_evt(event);" ondragover="dragOver_evt(event);" >
					   <span id ="drop_div_html">Drop Here/Select File</span>
					   <input type="file" NAME="userfile" onChange="drop_evt(event)" onMouseOver="MM_displayStatusMsg('click the Browse button to select a file from disk')" onMouseOut="MM_displayStatusMsg(' ')" class="filestyle" id="smallFile" />
					</div>
					<INPUT class="form-control" NAME="imgdesc" Size=53 Maxlength=300 placeholder="Description" onMouseOver="MM_displayStatusMsg('type very short description of the file')" onMouseOut="MM_displayStatusMsg(' ')">
					<INPUT  class="form-control" placeholder="Laboratory Name" TYPE=textbox NAME=lab_name />
					<INPUT class="form-control" placeholder="Doctor Name" TYPE=textbox NAME=doc_name />

					<select class="form-control report-type" name=type title="File type" >
						<option value="">SELECT</option>
						<option value="BLD">Blood Slides </option>
						<option value="CTS">CT Scan </option>
						<option value="DCM">Dicom Files</option>
						<option value="DOC">Documents</option>
						<option value="EEG">EEG </option>
						<option value="MRI">MRI</option>
						<option value="MOV">Movie Files</option>
						<option value="SEG">Scanned ECG </option>
						<option value="SKP">Scanned Skin Patch </option>
						<option value="SNG">Sonograms</option>
						<option value="SND">Sound Files</option>
						<option value="TEG">Text ECG </option>
						<option value="XRA">X-Ray </option>
						<option value="OTH">Others</option>
					</select>

					<input type=hidden name=entrydate>
					<div id="dot-datepicker" class="input-append date input-group" style="margin:auto;max-width:320px;">
						<input data-format="dd/MM/yyyy" id="datepicker-testdate" type="text" value="<%=today%>" class="form-control dot" required><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
					</div>

					<input class="form-control" id="testdate" placeholder="Date Of Test(DDMMYYYY)" name=testdate size=8 maxlength=8 onblur='return chkdt(this.value)' type="hidden" />
					<center><input class="btn btn-primary" type="submit" value="Upload" onclick="return fileCheck()" style="background-color: '#FFE0C1'; color: '#000000'; font-weight:BOLD; font-style:oblique "></CENTER>
					</FORM>
					<form id="lfuploadform" method="POST" >
						<input type="hidden" id="Lftype" value="BLD" name="ftype" />
						<input type="hidden" id="Ldes" name="desc" />
						<input type="hidden" id="Llname" name="lname" />
						<input type="hidden" id="LdocName" name="docName" />
						<input type="hidden" id="Lext" name="ext" />
					</form>

					</div>		<!-- "col-sm-12" -->
					</div>		<!-- "row" -->


		</div>
		</fieldset>
	</div><!-- "Upload Report END" -->


</div>		<!-- "col-sm-10" -->
</div>		<!-- "row" -->

</center>
</div>		<!-- "container-fluid" -->
</body>

</HTML>
