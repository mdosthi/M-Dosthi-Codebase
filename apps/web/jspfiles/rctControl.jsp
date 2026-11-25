<%-- <%@page language="java"  import= "imedix.rcUserInfo,imedix.rcCentreInfo,imedix.dataobj, imedix.cook,java.util.*,java.io.*"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%@page contentType="text/html" import="imedix.rcDisplayData" %>
<%
	cook cookx = new cook();
	String utyp=cookx.getCookieValue("usertype", request.getCookies());
	String usr=cookx.getCookieValue("userid", request.getCookies());

	rcUserInfo uinfo=new rcUserInfo(request.getRealPath("/"));
	String us, ps;
	boolean found=false;

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
%>

<HTML>
<HEAD>
<TITLE>RCT Control</TITLE>

<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
	<script src="../bootstrap/jquery-2.2.1.min.js"></script>
	<script src="../bootstrap/js/bootstrap.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/jquery.dataTables.min.js"></script>
    <script src="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.js"></script>

<SCRIPT LANGUAGE="JavaScript">
	$(document).ready(function(){
		$('#rctTable').DataTable();
	});

	function showselected(val){
		var tar;
		tar="rctControl.jsp?sccode="+val;
		window.location=tar;
	}
	
	function toggleRctStatus(reg) {
		var chk = document.getElementById(reg);
		console.log(reg);

		if($(chk).prop('checked')) {
			// Set RCT flag to 1
			var param = {cmd: "enable_rct", uid: reg};
			$.ajax({
				type: 'POST',
				url: "rct_manage.jsp",
				data: param,
				dataType: "text",
				success: function(data) {
					var res = JSON.parse(data);
					alert(res.message);
					location.reload(true);
				}
			});
		} else {
			// Set RCT flag to 0
			var param = {cmd: "disable_rct", uid: reg};
			$.ajax({
				type: 'POST',
				url: "rct_manage.jsp",
				data: param,
				dataType: "text",
				success: function(data) {
					var res = JSON.parse(data);
					alert(res.message);
					location.reload(true);
				}
			});
		}
	}
</SCRIPT>

<style>
input[type=checkbox]{
    margin:0;
    height: 22px;
    width: 33px;
}
table tr:nth-child(odd) td {
	/* Styling for odd rows */
}
table tr:nth-child(even) td {
	/* Styling for even rows */
}
</style>

</HEAD>
<body background="../images/txture.jpg">
	<TABLE class="table" width=90% border=0 Cellpadding=0 Cellspacing=0 >
		<TR>
			<TD><Font Size='5' color=#3300FF> <B>RCT CONTROL</B> </Font></TD>
			<TD align='right'><A class="btn" HREF="javascript:history.go(-1)" Style="color:yellow; size:9px; background:RED; font-weight:bold; text-decoration:none; ">&nbsp;BACK&nbsp;</A> </TD>
		</TR>
	</TABLE>
<div class="container-fluid">
<div class="row">
<div class="col-sm-4">
<div class="input-group">
<span class="input-group-addon" style="color:blue;font-weight:bold">Select Center :</span>
<select class="form-control" name="center" onchange='showselected(this.value);'>
<%
	out.println("<option value="+ccode+" 'selected'>"+cname+"</option><br>");
		try
		{
		 if(ccode.equals("XXXX")){
			rcCentreInfo rcci=new rcCentreInfo(request.getRealPath("/"));
			Object res=rcci.getAllCentreInfo();
			if(res instanceof String){ out.println("<option value='NIL' >No match Found</option>"); }
			else{
				Vector Vtmp = (Vector)res;
					for(int j=0;j<Vtmp.size();j++){
						dataobj datatemp = (dataobj) Vtmp.get(j);
						if(datatemp.getValue("code").equals(sccode)){
							out.println("<option value="+datatemp.getValue("code")+" selected>"+datatemp.getValue("name")+"</option><br>");
						}else{
							out.println("<option value="+datatemp.getValue("code")+">"+datatemp.getValue("name")+"</option><br>");
						}
					} // end for
			}// end else
		  }
		}catch(Exception e)
		{
			out.println("error.."+e.getMessage());
		}

%>
	 </select>
	</div>		<!-- "input-group" -->

</div>		<!-- "col-sm-4" -->
</div>		<!-- "row" -->

<div class="row">
<div class="col-sm-12">

<div class="table-responsive">

<strong><Font> <CENTER><font color='red'>Administrator : Red </font>
<font color='darkgreen'>| Doctor : Green </font>
<font color='blue'>| Data Entry Operator : Blue </font><font color='black'>| Patients : Black</font></CENTER></strong>
<table class="table table-bordered table-hover" id="rctTable">
	<thead>
	<TR style='background-color: #E6E6FA;font-variant: small-caps;font-weight: bold;font-size:22px;' >
		<TH> <FONT ><B>RCT Status</B></FONT></TH>
		<TH> <FONT ><B>Name (UID)</B></FONT></TH>
		<TH> <FONT ><B>Designation</B></FONT></TH>
		<TH> <FONT ><B>Email</B></FONT></TH>
		<TH> <FONT ><B>Phone</B></FONT></TH>
		<TH> <FONT ><B>Center</B></FONT></TH>
	</TR>
	</thead>
<%
	String rgno, suid, typ;
	try {
		Object res = uinfo.getValues("name,uid,designation,emailid,phone,dis,rg_no,type,active,center,rctFlag", cond);
		if(res instanceof String){
			out.println("<br><center><h1> No User Available</h1></center>");
			out.println("<br><center><h1> " + res + "</h1></center>");
		}
		else{
			Vector tmp = (Vector)res;
			if(tmp.size() > 0){
				dataobj tmpData = (dataobj) tmp.get(0);
				String pvcenter = tmpData.getValue("center");

				for(int ii=0; ii<tmp.size(); ii++){
					String color = "RED";

					dataobj temp = (dataobj) tmp.get(ii);
					typ = temp.getValue("type");
					rgno = temp.getValue("rg_no");
					suid = temp.getValue("uid");
					
					// Skip specific users if needed
					if(rgno.equalsIgnoreCase("docVBCR019NA")) {
						continue;
					}

					if(typ.equals("adm")) color = "RED";
					else if(typ.equals("doc")) color = "DARKGREEN";
					else if(typ.equals("usr")) color = "blue";
					else if(typ.equalsIgnoreCase("pat")) color = "black";

					if(!pvcenter.equals(temp.getValue("center"))){
						out.println("<tr><td colspan='6' style='background-color: #E6E6FA;'>      </td></tr>");
						pvcenter = temp.getValue("center");
					}
					
					out.println("<TR>");

					// Check if rctFlag is 1, then check the checkbox
					String rctValue = temp.getValue("rctFlag").equals("1") ? "checked" : "";

					out.println("<td><input class='rct' type='checkbox' name='rct' onClick='toggleRctStatus(id)' id='" + temp.getValue("rg_no") + "' value='" + temp.getValue("rg_no") + "'" + rctValue + "></td>");
					out.println("<TD><font color='"+color+"'>" + temp.getValue("name") + "(<B>" + temp.getValue("rg_no") + "</B>)" + "</font></TD>");
					out.println("<TD><font color='"+color+"'>" + temp.getValue("designation") + "</font></TD>");
					out.println("<TD><font color='"+color+"'>" + temp.getValue("emailid") + "</font></TD>");
					out.println("<TD><font color='"+color+"'>" + temp.getValue("phone") + "</font></TD>");
					out.println("<TD><font color='"+color+"'>" + temp.getValue("center") + "</font></TD>");

					out.println("</TR>");
				}
			}
		}
	} catch (Exception e) {
		out.println("SQL Error found <B>" + e + "</B>");
	}
%>
</TABLE>
</div>		<!-- "table-responsive" -->

</div>		<!-- "col-sm-12" -->
</div>		<!-- "row(inner)" -->

</div>		<!-- "container" -->
</body>
</html> --%>

<%@page language="java"  import= "imedix.rcUserInfo,imedix.rcCentreInfo,imedix.dataobj, imedix.cook,java.util.*,java.io.*"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%-- <%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="imedix.rcDisplayData" %> --%>
<%
	cook cookx = new cook();
	String utyp=cookx.getCookieValue("usertype", request.getCookies());
	String usr=cookx.getCookieValue("userid", request.getCookies());

	rcUserInfo uinfo=new rcUserInfo(request.getRealPath("/"));
	String us, ps;
	boolean found=false;

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
%>

<HTML>
<HEAD>
<TITLE>Permanent RCT Control</TITLE>

<meta charset="utf-8">
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
<script src="../bootstrap/jquery-2.2.1.min.js"></script>
<script src="../bootstrap/js/bootstrap.min.js"></script>
<script src="<%=request.getContextPath()%>/bootstrap/jquery.dataTables.min.js"></script>
<script src="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.js"></script>

<SCRIPT LANGUAGE="JavaScript">
	$(document).ready(function(){
		$('#rctTable').DataTable({
			"pageLength": 25,
			"order": [[ 5, "asc" ], [ 1, "asc" ]]
		});
		loadRctStats();
		
		// Show permanent enrollment warning
		$('#permanentWarning').show();
	});

	function showselected(val){
		var tar;
		tar="rctControl.jsp?sccode="+val;
		window.location=tar;
	}
	
	// MODIFIED: Toggle function - ENROLLMENT ONLY (No Undo)
	function toggleRctStatus(reg) {
		var chk = document.getElementById(reg);
		console.log("Attempting to toggle RCT status for: " + reg);

		if($(chk).prop('checked')) {
			// Trying to ENROLL - Show confirmation
			var confirmMsg = 'PERMANENT RCT ENROLLMENT\n\n';
			confirmMsg += 'Are you sure you want to enroll this patient in the RCT?\n\n';
			confirmMsg += 'WARNING: Once enrolled, the patient CANNOT be removed from the RCT.\n';
			confirmMsg += 'This ensures the integrity of the clinical trial.\n\n';
			confirmMsg += 'Proceed with permanent enrollment?';
			
			if(!confirm(confirmMsg)) {
				$(chk).prop('checked', false); // Uncheck if cancelled
				return;
			}
			
			var param = {cmd: "enable_rct", uid: reg};
			$.ajax({
				type: 'POST',
				url: "rct_manage.jsp",
				data: param,
				dataType: "text",
				success: function(data) {
					var res = JSON.parse(data);
					showMessage(res.message, res.status === 'success' ? 'success' : 'info');
					if(res.status === 'success') {
						// Make checkbox disabled and show permanent status
						$(chk).prop('disabled', true);
						$(chk).parent().append('<br><small style="color: #28a745; font-weight: bold;"><i class="fa fa-lock"></i> PERMANENT</small>');
						loadRctStats();
					}
				},
				error: function() {
					showMessage('Request failed. Please try again.', 'danger');
					$(chk).prop('checked', false);
				}
			});
		} else {
			// Trying to UNENROLL - NOT ALLOWED
			$(chk).prop('checked', true); // Force it back to checked
			showMessage('Cannot remove patient from RCT. Enrollment is permanent to maintain trial integrity.', 'warning');
		}
	}

	// MODIFIED: Auto randomization - No reset option
	function performAutoRandomization() {
		var center = getCurrentCenter();
		var userType = $('#userTypeSelect').val();
		var percentage = $('#percentageInput').val();
		var maxCount = $('#maxCountInput').val();
		
		// Validate inputs
		if(!percentage || percentage < 1 || percentage > 100) {
			showMessage('Please enter a valid percentage between 1 and 100', 'warning');
			return;
		}
		
		if(!maxCount || maxCount < 1) {
			showMessage('Please enter a valid maximum count (minimum 1)', 'warning');
			return;
		}
		
		// Confirmation for permanent enrollment
		var confirmMsg = 'PERMANENT AUTOMATED RCT ENROLLMENT\n\n';
		confirmMsg += 'This will permanently enroll patients in RCT:\n';
		confirmMsg += '• Center: ' + (center === 'XXXX' ? 'All Centers' : center) + '\n';
		confirmMsg += '• User Type: ' + userType.toUpperCase() + '\n';
		confirmMsg += '• Selection: ' + percentage + '% (max ' + maxCount + ' users)\n\n';
		confirmMsg += 'WARNING: Once enrolled, patients CANNOT be removed from RCT.\n';
		confirmMsg += 'This ensures clinical trial integrity.\n\n';
		confirmMsg += 'Proceed with permanent enrollment?';
		
		if(!confirm(confirmMsg)) {
			return;
		}
		
		$('#autoRandomizeBtn').prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> Enrolling...');
		$('#resultPanel').html('<div class="alert alert-info"><i class="fa fa-cog fa-spin"></i> Processing permanent RCT enrollment...</div>').show();
		
		$.ajax({
			type: 'POST',
			url: "rct_manage.jsp",
			data: {
				cmd: "auto_randomize_simple",
				center: center,
				userType: userType,
				percentage: percentage,
				maxCount: maxCount,
				resetExisting: "false" // Always false - no reset allowed
			},
			dataType: "text",
			success: function(data) {
				$('#autoRandomizeBtn').prop('disabled', false).html('<i class="fa fa-random"></i> Auto Enroll');
				
				try {
					var res = JSON.parse(data);
					
					if(res.status === 'success') {
						var resultHtml = '<div class="alert alert-success">';
						resultHtml += '<h4><i class="fa fa-check-circle"></i> Permanent RCT Enrollment Completed!</h4>';
						resultHtml += '<div class="alert alert-warning"><i class="fa fa-exclamation-triangle"></i> <strong>IMPORTANT:</strong> Enrolled patients cannot be removed from RCT.</div>';
						resultHtml += '<strong>Enrollment Summary:</strong><br>';
						resultHtml += '• Total Eligible Users: <strong>' + res.totalEligible + '</strong><br>';
						resultHtml += '• Target Selection: <strong>' + res.targetSelection + '</strong><br>';
						resultHtml += '• Successfully Enrolled: <strong>' + res.successCount + '</strong><br>';
						if(res.errorCount > 0) {
							resultHtml += '• Errors: <strong>' + res.errorCount + '</strong><br>';
						}
						if(res.alreadyEnrolledCount > 0) {
							resultHtml += '• Already Enrolled: <strong>' + res.alreadyEnrolledCount + '</strong><br>';
						}
						if(res.selectedUsers && res.selectedUsers.trim() !== '') {
							resultHtml += '<br><strong>Newly Enrolled Patients:</strong><br>';
							resultHtml += '<div style="max-height: 150px; overflow-y: auto; background: #f8f9fa; padding: 10px; border-radius: 4px;">';
							resultHtml += res.selectedUsers.replace(/,/g, '<br>• ').replace(/^/, '• ');
							resultHtml += '</div>';
						}
						resultHtml += '</div>';
						
						$('#resultPanel').html(resultHtml);
						
						setTimeout(function() {
							location.reload(true);
						}, 3000);
						
					} else {
						showMessage('Enrollment Error: ' + res.message, 'danger');
						$('#resultPanel').html('<div class="alert alert-danger"><strong>Error:</strong> ' + res.message + '</div>');
					}
					
					loadRctStats();
					
				} catch(e) {
					showMessage('Invalid response from server', 'danger');
				}
			},
			error: function() {
				$('#autoRandomizeBtn').prop('disabled', false).html('<i class="fa fa-random"></i> Auto Enroll');
				showMessage('Request failed. Please try again.', 'danger');
			}
		});
	}

	// Quick randomize - Permanent enrollment
	function quickRandomize() {
		var count = prompt("How many patients do you want to permanently enroll in RCT?\n\nWARNING: Enrollment cannot be undone.", "10");
		if(!count || count < 1) return;
		
		if(!confirm('Permanently enroll ' + count + ' patients in RCT?\n\nThis action CANNOT be undone.')) return;
		
		$.ajax({
			type: 'POST',
			url: "rct_manage.jsp",
			data: {
				cmd: "quick_randomize",
				center: getCurrentCenter(),
				userType: $('#userTypeSelect').val(),
				count: count
			},
			dataType: "text",
			success: function(data) {
				try {
					var res = JSON.parse(data);
					if(res.status === 'success') {
						showMessage('Quick enrollment completed! Permanently enrolled: ' + res.successCount + ' patients.', 'success');
						setTimeout(function() { location.reload(true); }, 2000);
					} else {
						showMessage('Quick enrollment failed: ' + res.message, 'danger');
					}
					loadRctStats();
				} catch(e) {
					showMessage('Invalid response', 'danger');
				}
			}
		});
	}

	// REMOVED: Reset all function - Not allowed for RCT integrity

	// Load RCT statistics
	function loadRctStats() {
		var center = getCurrentCenter();
		var userType = $('#userTypeSelect').val() || 'PAT';
		
		$.ajax({
			type: 'POST',
			url: "rct_manage.jsp",
			data: {
				cmd: "get_rct_stats",
				center: center,
				userType: userType
			},
			dataType: "text",
			success: function(data) {
				try {
					var res = JSON.parse(data);
					if(res.status === 'success') {
						var statsHtml = '';
						statsHtml += '<div class="col-sm-3"><div class="well text-center"><h3 class="text-primary">' + res.totalUsers + '</h3><p><i class="fa fa-users"></i> Total Users</p></div></div>';
						statsHtml += '<div class="col-sm-3"><div class="well text-center"><h3 class="text-success">' + res.rctEnabled + '</h3><p><i class="fa fa-lock"></i> RCT Enrolled (Permanent)</p></div></div>';
						statsHtml += '<div class="col-sm-3"><div class="well text-center"><h3 class="text-warning">' + res.rctDisabled + '</h3><p><i class="fa fa-unlock"></i> Not Enrolled</p></div></div>';
						statsHtml += '<div class="col-sm-3"><div class="well text-center"><h3 class="text-info">' + res.rctPercentage + '%</h3><p><i class="fa fa-percent"></i> Enrolled Percentage</p></div></div>';
						$('#statsRow').html(statsHtml);
					}
				} catch(e) {
					console.log('Stats loading error:', e);
				}
			}
		});
	}

	function getCurrentCenter() {
		return $('#centerSelect').val() || '<%=sccode%>';
	}

	function onSelectionChange() {
		loadRctStats();
	}

	function showMessage(message, type) {
		var alertHtml = '<div class="alert alert-' + type + ' alert-dismissible fade in">';
		alertHtml += '<button type="button" class="close" data-dismiss="alert">&times;</button>';
		alertHtml += message + '</div>';
		$('#messageArea').html(alertHtml);
		
		setTimeout(function() {
			$('#messageArea .alert').fadeOut();
		}, 8000);
	}

	// Show enrollment audit
	function showEnrollmentAudit() {
		$.ajax({
			type: 'POST',
			url: "rct_manage.jsp",
			data: {
				cmd: "get_enrollment_audit",
				center: getCurrentCenter(),
				userType: $('#userTypeSelect').val()
			},
			dataType: "text",
			success: function(data) {
				try {
					var res = JSON.parse(data);
					if(res.status === 'success') {
						var auditHtml = '<div class="modal fade" id="auditModal" tabindex="-1">';
						auditHtml += '<div class="modal-dialog modal-lg"><div class="modal-content">';
						auditHtml += '<div class="modal-header"><h4 class="modal-title"><i class="fa fa-history"></i> RCT Enrollment Audit Trail</h4>';
						auditHtml += '<button type="button" class="close" data-dismiss="modal">&times;</button></div>';
						auditHtml += '<div class="modal-body">';
						auditHtml += '<p><strong>Total Permanently Enrolled:</strong> ' + res.totalEnrolled + '</p>';
						if(res.enrolledUsers) {
							auditHtml += '<div style="max-height: 400px; overflow-y: auto;">';
							var users = res.enrolledUsers.split('|');
							for(var i = 0; i < users.length; i++) {
								auditHtml += '<p><i class="fa fa-user"></i> ' + users[i] + '</p>';
							}
							auditHtml += '</div>';
						}
						auditHtml += '</div>';
						auditHtml += '<div class="modal-footer"><button type="button" class="btn btn-default" data-dismiss="modal">Close</button></div>';
						auditHtml += '</div></div></div>';
						
						$('body').append(auditHtml);
						$('#auditModal').modal('show');
						
						// Remove modal when closed
						$('#auditModal').on('hidden.bs.modal', function() {
							$(this).remove();
						});
					} else {
						showMessage('Audit retrieval failed: ' + res.message, 'danger');
					}
				} catch(e) {
					showMessage('Invalid audit response', 'danger');
				}
			}
		});
	}
</SCRIPT>

<style>
input[type=checkbox]{
    margin:0;
    height: 22px;
    width: 33px;
}
.automation-panel {
    background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
    color: white;
    padding: 20px;
    border-radius: 8px;
    margin-bottom: 20px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}
.automation-panel h4 {
    margin-top: 0;
    color: white;
}
.well {
    margin-bottom: 10px;
    background-color: #f5f5f5;
    border: 1px solid #e3e3e3;
}
.btn-automation {
    margin: 2px;
}
.permanent-warning {
    background-color: #fff3cd;
    border: 1px solid #ffeaa7;
    color: #856404;
    padding: 15px;
    border-radius: 5px;
    margin-bottom: 20px;
}
.rct-enrolled {
    background-color: #d4edda !important;
    border-left: 4px solid #28a745 !important;
}
.rct-enrolled input[type=checkbox] {
    cursor: not-allowed;
}
</style>

</HEAD>
<body background="../images/txture.jpg">
	<TABLE class="table" width=90% border=0 Cellpadding=0 Cellspacing=0 >
		<TR>
			<TD><Font Size='5' color=#3300FF> <B><i class="fa fa-lock"></i> PERMANENT RCT CONTROL</B> </Font></TD>
			<TD align='right'><A class="btn btn-warning" HREF="javascript:history.go(-1)" Style="color:white; font-weight:bold; text-decoration:none; ">&nbsp;<i class="fa fa-arrow-left"></i> BACK&nbsp;</A> </TD>
		</TR>
	</TABLE>

<div class="container-fluid">

<%-- <!-- Message Area -->
<div id="messageArea"></div>

<!-- Permanent Enrollment Warning -->
<div id="permanentWarning" class="permanent-warning" style="display: none;">
	<h4><i class="fa fa-exclamation-triangle"></i> <strong>IMPORTANT: Permanent RCT Enrollment</strong></h4>
	<p><strong>Once a patient is enrolled in the RCT, they CANNOT be removed.</strong> This ensures the integrity and validity of the clinical trial. Please ensure you understand this before enrolling patients.</p>
	<ul>
		<li>✓ Patients can be enrolled in RCT (one-time action)</li>
		<li>✗ Patients cannot be removed from RCT once enrolled</li>
		<li>✓ Automated randomization ensures unbiased selection</li>
		<li>✗ No "reset all" function to maintain trial integrity</li>
	</ul>
</div> --%>

<!-- RCT Statistics Dashboard -->
<div class="row" id="statsRow">
	<div class="col-sm-12">
		<h4 style="text-align: center; color: #333; margin-bottom: 15px;"><i class="fa fa-bar-chart"></i> Current RCT Statistics</h4>
	</div>
</div>

<!-- Center Selection -->
<div class="row">
	<div class="col-sm-6">
		<div class="input-group">
			<span class="input-group-addon" style="color:blue;font-weight:bold"><i class="fa fa-hospital-o"></i> Select Center :</span>
			<select class="form-control" id="centerSelect" name="center" onchange='showselected(this.value); onSelectionChange();'>
<%
	out.println("<option value="+ccode+" selected>"+cname+"</option><br>");
		try
		{
		 if(ccode.equals("XXXX")){
			rcCentreInfo rcci=new rcCentreInfo(request.getRealPath("/"));
			Object res=rcci.getAllCentreInfo();
			if(res instanceof String){ out.println("<option value='NIL' >No match Found</option>"); }
			else{
				Vector Vtmp = (Vector)res;
					for(int j=0;j<Vtmp.size();j++){
						dataobj datatemp = (dataobj) Vtmp.get(j);
						if(datatemp.getValue("code").equals(sccode)){
							out.println("<option value="+datatemp.getValue("code")+" selected>"+datatemp.getValue("name")+"</option><br>");
						}else{
							out.println("<option value="+datatemp.getValue("code")+">"+datatemp.getValue("name")+"</option><br>");
						}
					} // end for
			}// end else
		  }
		}catch(Exception e)
		{
			out.println("error.."+e.getMessage());
		}
%>
			</select>
		</div>
	</div>
	<div class="col-sm-6">
		<div class="input-group">
			<span class="input-group-addon" style="color:green;font-weight:bold"><i class="fa fa-user"></i> User Type :</span>
			<select class="form-control" id="userTypeSelect" onchange="onSelectionChange()">
				<option value="PAT">Patients</option>
				<option value="doc">Doctors</option>
				<option value="usr">Data Entry</option>
				<option value="adm">Administrators</option>
			</select>
		</div>
	</div>
</div>

<!-- PERMANENT ENROLLMENT PANEL -->
<div class="row">
	<div class="col-sm-12">
		<div class="automation-panel">
			<h4><i class="fa fa-lock"></i> Permanent RCT Enrollment Controls</h4>
			<p><small><i class="fa fa-info-circle"></i> All enrollments are permanent to maintain clinical trial integrity</small></p>
			
			<div class="row">
				<div class="col-sm-2">
					<label><strong>Selection %:</strong></label>
					<input type="number" class="form-control" id="percentageInput" min="1" max="100" value="30" placeholder="30">
					<small style="color: #ccc;">1-100%</small>
				</div>
				
				<div class="col-sm-2">
					<label><strong>Max Count:</strong></label>
					<input type="number" class="form-control" id="maxCountInput" min="1" value="50" placeholder="50">
					<small style="color: #ccc;">Maximum users</small>
				</div>
				
				<div class="col-sm-2">
					<div class="form-group">
						<label><strong>Eligible Only:</strong></label>
						<div style="padding: 8px 0; color: #ccc;">
							<i class="fa fa-info-circle"></i> Only non-enrolled users
						</div>
					</div>
				</div>
				
				<div class="col-sm-6">
					<label><strong>Enrollment Actions:</strong></label><br>
					<button type="button" class="btn btn-success btn-automation" id="autoRandomizeBtn" onclick="performAutoRandomization()">
						<i class="fa fa-random"></i> Auto Enroll (Permanent)
					</button>
					<button type="button" class="btn btn-info btn-automation" onclick="quickRandomize()">
						<i class="fa fa-bolt"></i> Quick Enroll
					</button>
					<button type="button" class="btn btn-primary btn-automation" onclick="loadRctStats()">
						<i class="fa fa-refresh"></i> Refresh Stats
					</button>
					<button type="button" class="btn btn-warning btn-automation" onclick="showEnrollmentAudit()">
						<i class="fa fa-history"></i> Audit Trail
					</button>
				</div>
			</div>
			
			<!-- Results Display -->
			<div class="row" style="margin-top: 15px;">
				<div class="col-sm-12">
					<div id="resultPanel" style="display: none;"></div>
				</div>
			</div>
		</div>
	</div>
</div>

<!-- Manual User Table -->
<div class="row">
<div class="col-sm-12">

<div class="table-responsive">

<strong><Font> <CENTER>
<span style="background: #ff4444; color: white; padding: 3px 8px; border-radius: 3px;">Administrator : Red</span>
<span style="background: #44aa44; color: white; padding: 3px 8px; border-radius: 3px;">Doctor : Green</span>
<span style="background: #4444aa; color: white; padding: 3px 8px; border-radius: 3px;">Data Entry : Blue</span>
<span style="background: #333333; color: white; padding: 3px 8px; border-radius: 3px;">Patients : Black</span>
<span style="background: #28a745; color: white; padding: 3px 8px; border-radius: 3px;"><i class="fa fa-lock"></i> RCT Enrolled : Green Background (Permanent)</span>
</CENTER></Font></strong>

<table class="table table-bordered table-hover" id="rctTable">
	<thead>
	<TR style='background-color: #E6E6FA;font-variant: small-caps;font-weight: bold;font-size:18px;' >
		<TH width="10%"> <FONT><B><i class="fa fa-lock"></i> RCT Status</B></FONT></TH>
		<TH width="25%"> <FONT><B><i class="fa fa-user"></i> Name (UID)</B></FONT></TH>
		<TH width="15%"> <FONT><B><i class="fa fa-briefcase"></i> Designation</B></FONT></TH>
		<TH width="20%"> <FONT><B><i class="fa fa-envelope"></i> Email</B></FONT></TH>
		<TH width="15%"> <FONT><B><i class="fa fa-phone"></i> Phone</B></FONT></TH>
		<TH width="15%"> <FONT><B><i class="fa fa-hospital-o"></i> Center</B></FONT></TH>
	</TR>
	</thead>
	<tbody>
<%
	String rgno, suid, typ;
	try {
		Object res = uinfo.getValues("name,uid,designation,emailid,phone,dis,rg_no,type,active,center,rctFlag", cond);
		if(res instanceof String){
			out.println("<tr><td colspan='6' class='text-center'><h3 style='color: #999;'>No User Available</h3></td></tr>");
		}
		else{
			Vector tmp = (Vector)res;
			if(tmp.size() > 0){
				dataobj tmpData = (dataobj) tmp.get(0);
				String pvcenter = tmpData.getValue("center");

				for(int ii=0; ii<tmp.size(); ii++){
					String color = "RED";
					String bgColor = "#ffeeee";

					dataobj temp = (dataobj) tmp.get(ii);
					typ = temp.getValue("type");
					rgno = temp.getValue("rg_no");
					suid = temp.getValue("uid");
					
					// Skip specific users if needed
					if(rgno.equalsIgnoreCase("docVBCR019NA")) {
						continue;
					}

					if(typ.equals("adm")) {
						color = "RED";
						bgColor = "#ffeeee";
					}
					else if(typ.equals("doc")) {
						color = "DARKGREEN";
						bgColor = "#eeffee";
					}
					else if(typ.equals("usr")) {
						color = "blue";
						bgColor = "#eeeeff";
					}
					else if(typ.equalsIgnoreCase("pat")) {
						color = "black";
						bgColor = "#f8f8f8";
					}

					// Center separator
					if(!pvcenter.equals(temp.getValue("center"))){
						out.println("<tr style='background-color: #E6E6FA; font-weight: bold;'>");
						out.println("<td colspan='6' style='text-align: center; padding: 8px;'><i class='fa fa-hospital-o'></i> CENTER: " + temp.getValue("center") + "</td>");
						out.println("</tr>");
						pvcenter = temp.getValue("center");
					}
					
					// User row with enhanced styling
					boolean isRctEnabled = temp.getValue("rctFlag").equals("1");
					String rowClass = isRctEnabled ? "rct-enrolled" : "";
					String rowStyle = isRctEnabled ? "background-color: #d4edda; border-left: 4px solid #28a745;" : "background-color: " + bgColor + ";";
					
					out.println("<TR class='" + rowClass + "' style='" + rowStyle + "'>");

					// RCT Status checkbox - DISABLED if enrolled
					String rctValue = isRctEnabled ? "checked" : "";
					String checkboxDisabled = isRctEnabled ? "disabled" : "";
					String checkboxStyle = isRctEnabled ? "transform: scale(1.2); accent-color: #28a745;" : "";
					
					out.println("<td style='text-align: center; vertical-align: middle;'>");
					out.println("<input class='rct' type='checkbox' name='rct' onClick='toggleRctStatus(id)' ");
					out.println("id='" + temp.getValue("rg_no") + "' value='" + temp.getValue("rg_no") + "' ");
					out.println("style='" + checkboxStyle + "' " + rctValue + " " + checkboxDisabled + ">");
					if(isRctEnabled) {
						out.println("<br><small style='color: #28a745; font-weight: bold;'><i class='fa fa-lock'></i> PERMANENT</small>");
					} else {
						out.println("<br><small style='color: #6c757d;'>Click to enroll</small>");
					}
					out.println("</td>");

					out.println("<TD><font color='"+color+"' style='font-weight: " + (isRctEnabled ? "bold" : "normal") + ";'>" + 
							   temp.getValue("name") + "<br><small>(<B>" + temp.getValue("rg_no") + "</B>)</small>" + "</font></TD>");
					out.println("<TD><font color='"+color+"'>" + temp.getValue("designation") + "</font></TD>");
					out.println("<TD><font color='"+color+"'>" + temp.getValue("emailid") + "</font></TD>");
					out.println("<TD><font color='"+color+"'>" + temp.getValue("phone") + "</font></TD>");
					out.println("<TD><font color='"+color+"' style='font-weight: bold;'>" + temp.getValue("center") + "</font></TD>");

					out.println("</TR>");
				}
			}
		}
	} catch (Exception e) {
		out.println("<tr><td colspan='6' class='text-danger'><strong>SQL Error:</strong> " + e + "</td></tr>");
	}
%>
	</tbody>
</TABLE>
</div>

</div>
</div>

<!-- Footer Info -->
<%-- <div class="row">
	<div class="col-sm-12">
		<div class="well" style="margin-top: 20px; background-color: #f0f0f0;">
			<h5><strong><i class="fa fa-info-circle"></i> Permanent RCT Enrollment System:</strong></h5>
			<p>
				<strong>• Auto Enroll:</strong> Randomly selects eligible users for permanent RCT enrollment<br>
				<strong>• Quick Enroll:</strong> Instantly enrolls a specific number of users<br>
				<strong>• Manual Enrollment:</strong> Click checkbox to permanently enroll individual users<br>
				<strong>• Audit Trail:</strong> View complete history of all RCT enrollments<br>
				<strong>• No Removal:</strong> Once enrolled, patients cannot be removed to maintain trial integrity
			</p>
			<p><em><i class="fa fa-shield"></i> This system ensures clinical trial integrity by preventing post-enrollment modifications.</em></p>
		</div>
	</div>
</div> --%>

</div> <!-- container-fluid -->
</body>
</html>