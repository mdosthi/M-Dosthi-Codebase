<%@page language="java" import="imedix.cook,imedix.myDate,java.util.*" %>
<%@ include file="..//includes/chkcook.jsp" %>
<%
	String id,dat="",cen="";
	//String patId = request.getParameter("patId");
	cook cookx = new cook();
	// id = cookx.getCookieValue("patid", request.getCookies());
	id = request.getParameter("patId");
	cen = cookx.getCookieValue("center",request.getCookies());
	//out.print("&nbsp;<B>Patient ID<BR>&nbsp;<FONT SIZE='-1' COLOR='#FF0000'>" + id + "</B></FONT><BR>");
	dat = myDate.getCurrentDate("dmy",false);
	long timestamp = new Date().getTime();
%>

<HTML>
	<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/bootstrap-datetimepicker.min.css">
	<script src="<%=request.getContextPath()%>/bootstrap/bootstrap-datetimepicker.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/bootstrap-datetimepicker.pt-BR.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/html2canvas.js" type="text/javascript"></script>
	<SCRIPT LANGUAGE="JavaScript" SRC="../includes/script1.js"></SCRIPT>
	<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/jquery-ui.css">




<HEAD>


<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
<!--
	<script src="../bootstrap/jquery-2.2.1.min.js"></script>
	<script src="../bootstrap/js/bootstrap.min.js"></script>
-->
   
	<TITLE>Provisional Diagnosis</TITLE>
<!--<link rel="stylesheet" type="text/css" href="../style/style2.css">-->
<SCRIPT LANGUAGE="JavaScript" SRC="../includes/script1.jsp">
var putdate,putmonth,putyear;
</SCRIPT>

<SCRIPT LANGUAGE="JavaScript">
function datentry(){
	dateentry();
	document.save_notes.entrydate.value=putdate+putmonth+putyear;
	}
	$(document).ready(function(){
		if(testdt($(this).find("#testdate").val(),'<%=dat%>')) return false;
	
		

	$("form.save_notes").submit(function(e){
    e.preventDefault();  

    var url="../jspfiles/saveNotes.jsp";
    var formData = $(this).serialize(); 
    var detailed_notes = $("#notes").val()
    console.log("Notes content: ", detailed_notes)
    console.log("formData: " + formData);
    
	    $.ajax({
	        type: "POST",
	        url: url,
	        data: formData, 
	        success: function(data)
	        {
	            alert("Notes saved successfully");
	            // Handle modal if needed
	            if($('#save_notes').hasClass('modal')) {
	                $('#save_notes').modal('toggle');
	                $(".modal-backdrop").remove();
	            }
	            $("input[name='report_link']").remove();
	            
	            // Close dialog if open
	            if($('#patPres').hasClass('ui-dialog-content'))
	            {
	                $("#patPres").dialog("close");
	                $("#patPres").remove();
	            }
	            
	            
	            var ajax_load = "<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='loading...'>";
	            $(".main-body").html(ajax_load).load("patientAlldata.jsp?id=<%=id%>");
	        },
	        error: function(error)
	        {
	            alert("Form could not be submitted!");
	            console.error("Error details:", error);
	        }
	    });
	});
});

	
</SCRIPT>
<style>
.ui-autocomplete { 
	cursor:pointer; 
	height:240px; 
	overflow-y:scroll;
}  

	.ui-menu.ui-autocomplete{
	overflow-y:auto;
	max-height:200px;
	}
.ui-menu:hover{overflow-x:hidden;}
.comp-upload-div{
	border: 1px solid #ddd;
    padding: 4px 12px;
    border-radius: 4px;
	position: absolute;
    top: -50px;
    right: 50px;
}
.upload-btn{margin:auto;display:block;}
.comp-upload-div label{padding:5px;margin:0px;}
.comp-upload-span{
	border: 1px solid #ddd;
    padding: 4px 12px;
    font-size: 20px;
    border-radius: 20px;
    color: #4a93ea;
    background: #e1e7ef;
    cursor: pointer;
}
input[name="compReport"]{
    position: absolute;
    top: 0;
    left: 0px;
    float: right;
    width: 60px;
    opacity: 0;
    display: inline-block;
    overflow: hidden;
}
.fileName-msg{color:#4a93ea;}
#compTable thead tr td{
padding:4px;	
}
.diag-head span{
	background: #2775FC;
	color: #fff;
	}
</style>
</HEAD>
<BODY onload='datentry();'>
<div class="container-fluid">

<TABLE class='tableb table table-bordered'>
<TR><TD>
<FORM class="save_notes" role="form" METHOD=post ACTION="../jspfiles/saveNotes.jsp" name="save_notes">
<INPUT TYPE="hidden" name="frmnam" value="psyNotes" >
<INPUT TYPE="hidden" name="pat_id" value="<%=id%>">

	
	<fieldset><legend><FONT SIZE="4"COLOR="RED"><b>Post Session Reflections<B></FONT></legend>
	<TABLE class="table">
		<TR>
		<TD valign=middle><FONT SIZE="3" COLOR="blue">Records here:</font></TD>
		<TD><TEXTAREA id="notes" class="form-control" onkeypress="return txtlength(this,300)" onblur=chkpest(this,300) name=notes wrap=virtual cols=50 rows=7></TEXTAREA></TD>
		</TR> 
	</TABLE>
	</fieldset>


<TABLE class="table">
<TR>
 <TD>Test date</TD><TD><INPUT class="form-control" id="testdate" NAME="testdate"  value=<%=dat%> maxlength=8></INPUT></TD>

<TD><INPUT type=hidden name=entrydate></INPUT><span class="fileName-timestamp"></span>
<!-- <INPUT class="btn btn-primary" type="hidden" value="Submit" onclick="return testdt(document.save_notes.testdate.value,'<%=dat%>')" style="background-color: '#D3CEC9'; color: '#000000'; font-weight:BOLD; ">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; -->
	<INPUT class="btn btn-primary"  value="Submit" type="submit" background-color: '#D3CEC9'; color: '#000000'; font-weight:BOLD; ">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;	
<!-- <a href="<%=request.getContextPath()%>/jspfiles/tobaccoSurvey.jsp?patId=<%=id%>" class="btn btn-info">
	Back to Assesment
</a> -->
<!--<INPUT class="btn btn-warning" type="reset" value="Reset" style="background-color: '#D3CEC9'; color: '#000000'; font-weight:BOLD; ">--></TD>
</TR>
</TABLE>
</FORM>

</td></tr>
</table>

</div>		<!-- "container-fluid" -->
</BODY>
</HTML>
