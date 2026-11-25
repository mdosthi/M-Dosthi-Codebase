<%@page language="java"  import= "imedix.rcUserInfo,imedix.medinfo,imedix.rcGenOperations,imedix.rcPatqueueInfo,imedix.rcCentreInfo,imedix.dataobj, imedix.cook,java.util.*,java.text.*,java.io.*, imedix.myDate"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%@page contentType="text/html" import="imedix.rcDisplayData" %>
<%
	cook cookx = new cook();
	String utyp=cookx.getCookieValue("usertype", request.getCookies());
	String usr=cookx.getCookieValue("userid", request.getCookies());

	rcUserInfo uinfo=new rcUserInfo(request.getRealPath("/"));
	String us, ps;
	boolean found=false;;

	rcPatqueueInfo rcpqi=new rcPatqueueInfo(request.getRealPath("/"));
    rcUserInfo rcui=new rcUserInfo(request.getRealPath("/"));
    rcGenOperations rcGen=new rcGenOperations(request.getRealPath("/"));
    medinfo minfo = new medinfo(request.getRealPath("/"));
	//rcCentreInfo rcci=new rcCentreInfo(request.getRealPath("/"));

	String ccode= cookx.getCookieValue("center", request.getCookies ());
	String cname = cookx.getCookieValue("centername", request.getCookies ());

	String sccode=request.getParameter("sccode");


	if(sccode==null) sccode=ccode;
	if(sccode.equals("")) sccode=ccode;
	String cond="active='Y' ";
	if(sccode.equals("XXXX")){
		cond+=" and center <> 'XXXX'  order by center,type,name";
	}else{
		cond+=" and center = '"+sccode+"'"+ " order by center,type,name";
	}
	int MILLIS_IN_DAY = 1000 * 60 * 60 * 24;
	String setDate="";
	Date cur_date = new Date();
	SimpleDateFormat dde = new SimpleDateFormat("dd/MM/yyyy");
	String today = dde.format(cur_date);
	setDate = dde.format(cur_date.getTime() - MILLIS_IN_DAY);



%>


<HTML>
<HEAD>

<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
	<script src="../bootstrap/jquery-2.2.1.min.js"></script>
	<script src="../bootstrap/js/bootstrap.min.js"></script>
	

<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/bootstrap.min.css">
	<link rel="stylesheet" href="../bootstrap/bootstrap-datetimepicker.min.css">
	<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.css">
	<script src="../bootstrap/jquery-2.2.1.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/js/bootstrap.min.js"></script>
	<script src="../bootstrap/bootstrap-datetimepicker.min.js"></script>
	<script src="../bootstrap/bootstrap-datetimepicker.pt-BR.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/jquery.dataTables.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.js"></script>



<SCRIPT LANGUAGE="JavaScript">
	$(document).ready(function(){
		$("#visdt").val("<%=setDate%>");
		//$('#PatList').DataTable();
	});

	function showselected(val){
		var tar;
		tar="accountActive.jsp?sccode="+val;
		//alert(tar);
		window.location=tar;
	}
	
	$(document).ready(function(){
	
	let d = new Date();
	
	$(function () {
		endDate = new Date(d.getFullYear()+"-"+Number(d.getMonth()+1)+"-"+Number(d.getDate())),
    	startDate = new Date("01/01/2021"),
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
});
	

</SCRIPT>

<style>
input[type=checkbox]{
    margin:0;
    height: 22px;
    width: 33px;
}
table tr:nth-child(odd) td {

}
table tr:nth-child(even) td {

}
</style>


</HEAD>
<body background="../images/txture.jpg">
	<TABLE class="table" width=90% border=0 Cellpadding=0 Cellspacing=0 >
		<TR>
			<TD><Font Size='5' color=#3300FF> <B>CLEAN LOCAL PATIENT QUEUE</B> </Font></TD>
			<TD align='right'><A class="btn" HREF="javascript:history.go(-1)" Style="color:yellow; size:9px; background:RED; font-weight:bold; text-decoration:none; ">&nbsp;BACK&nbsp;</A> </TD>
		</TR>
	</TABLE>
<div class="container-fluid">

<div class="row">
	<div class="col-sm-9">
	<div id="log-datepicker" class="input-append date input-group" style="margin:auto;max-width:320px;">
		<input data-format="dd/MM/yyyy" type="text" name="visdt" id="visdt" class="form-control logCaln" required><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
	</div>
	</div>
	<div class="col-sm-1">
		<input class="btn btn-info" style="background-color:MediumSeaGreen;border: 2px solid black;font-size: medium;"value="Search" onclick="display()"/>
	</div>
</div>
<br>
<div class="row">
    <div class="col-sm-8">
		
    	
		<input class="btn btn-info pull-right" style="background-color:Tomato;border: 2px solid black;font-size: medium;" onclick="clean()" value="Remove from Queue" />
		<input class="btn btn-info pull-right" style="background-color:DodgerBlue;border: 2px solid black;font-size: medium;" id="select-all" value="Select All" />
	</div>
</div>
<div class="col-sm-12">


<div class="table-responsive">


<table class="table table-bordered table-hover" id="PatList">
	<thead>
	<TR style='background-color: #4682B4;font-variant: small-caps;font-weight: bold;font-size:22px;' >
		<!--<TD><FONT COLOR="#FFFFFF"><B>SNo </B></FONT></TD>-->
	<TD><FONT COLOR="#FFFFFF"><B>Select </B></FONT></TD>
	<TD><FONT COLOR="#FFFFFF"><B>PatientName</B></FONT></TD>
	<TD><FONT COLOR="#FFFFFF"><B>PatientID</B></FONT></TD>
	<TD><FONT COLOR="#FFFFFF"><B>Assigned Physician</B></FONT>
	<TD><FONT COLOR="#FFFFFF"><B>Appoinment Date</B></FONT>
	<!--<INPUT type='checkbox' name='ch' Value='' style="visibility:hidden">-->
	</TD>

	</TR>
</thead>
<tbody id="patlist">
	
</tbody>

</TABLE>
</div>		<!-- "table-responsive" -->

</div>		<!-- "col-sm-12" -->
</div>		<!-- "row(inner)" -->

</div>		<!-- "container" -->

<script>
/*document.getElementById('select-all').onclick = function() {
    var checkboxes = document.querySelectorAll('input:checkbox[name=ch]');
    for (var checkbox of checkboxes) {
        checkbox.checked = this.checked;
    }
    $("input:checkbox[name=ch]").each(function(){
        $(this).checked=true
    });
}*/
function display()
{
	var sccode="<%=sccode%>";
	var searchDate=$("#visdt").val();
	if(searchDate.trim()=="")
	{
		alert("Please choose a date!");
		$("#visdt").focus();
		return false;
	}

	var param = {sccode: sccode,searchDate:searchDate};
			$.ajax({
					type: 'GET',
					url: "getLpatq_clean.jsp",
					data: param,
					dataType: "text",
					success: function(data)
					{
						$("#patList tbody").empty();
						$("#patList tbody").append(data.trim());
						$('#PatList').DataTable();
							//location.reload(true);
					}
			});


	
}



$("#select-all").click(function(){
    $("input:checkbox[name=ch]:not(:checked)").each(function(){        
        this.checked = true;
    });

});
function clean()
{
	let c=confirm("Are you sure you want to remove the selected patients from Local Patient Queue?");
	if(c){
    var yourArray=[]
    $("input:checkbox[name=ch]:checked").each(function(){
        yourArray.push($(this).val());        
    });
    //console.log(yourArray)
    for(var i=0;i<yourArray.length;i++)
    {
        console.log(yourArray[i])
        let patid = yourArray[i];
		var patqtype = "local";			
		$.ajax({
				type: "post",
				url: "patLTreatmentSts.jsp",
				data:{status:false,patid:patid,patqtype:patqtype},
				success: function(data){					
					//window.location.href = document.referrer;
				}
			});	       
    }
    alert("Successfully removed from queue");
	window.location.href = document.referrer;
	}
	else{
		return false;
	}

    
}
</script>
</body>
</html>
