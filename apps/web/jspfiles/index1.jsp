<%@page contentType="text/html"
	import="imedix.rcimedixstat,imedix.layout,java.io.*,imedix.rcDataEntryFrm,imedix.cook,imedix.rcPatqueueInfo,imedix.rcGenOperations,imedix.rcUserInfo,imedix.dataobj,imedix.rcVideoConference, java.util.*, imedix.projinfo, imedix.UserAccessCheck"
	%>
	<%@ include file="..//includes/chkcook.jsp" %>
		<html>
		<title>mDosthi</title>
		<script>
			var d = new Date();
			var n = d.getMilliseconds();
		</script>
		<% projinfo pinfo=new projinfo(request.getRealPath("/")); String vidServerUrl=(String)(pinfo.vidServerUrl);
			String wsPath=request.getServerName()+ "" + "/WSiMediX" ; cook cookx=new cook(); String
			userid=cookx.getCookieValue("userid", request.getCookies()); String
			username=cookx.getCookieValue("username", request.getCookies()); String
			usertype=cookx.getCookieValue("usertype", request.getCookies()); String
			distype=cookx.getCookieValue("distype", request.getCookies()); String
			tmpid=request.getParameter("templateid"); if(tmpid==null) tmpid="1" ; String menuid="head1" ; String
			ccode=cookx.getCookieValue("center", request.getCookies ()); String
			curCCode=request.getParameter("curCCode"); String cname=cookx.getCookieValue("centername",
			request.getCookies ()); //out.println(usertype+"<br>"+tmpid+"<br>"+menuid);
			if(cname==null) cname="";
			if(username==null) username="";
			String str,str1;
			str1="<FONT COLOR=#003300 size='5' face='Times'><B>"+cname.toUpperCase()+"</B></FONT>";
			str = "&nbsp;&nbsp;&nbsp;(<b>"
				+ "<FONT COLOR=#330099 size='2' face='Verdana'>" + username.toUpperCase() + "&nbsp;</FONT>"
				+ "<FONT COLOR=#330099> Logged on )</FONT>";





				UserAccessCheck.isAccessable(this.getClass().getName(),usertype);


				rcDataEntryFrm rcdef=new rcDataEntryFrm(request.getRealPath("/"));
				rcPatqueueInfo rcpqi=new rcPatqueueInfo(request.getRealPath("/"));
				rcUserInfo rcui=new rcUserInfo(request.getRealPath("/"));
				rcimedixstat rcStat=new rcimedixstat(request.getRealPath("/"));



				int total_lpat = 0,total_tpat=0;
				if(usertype.equals("adm") || usertype.equals("usr") || usertype.equals("sup") ||
				usertype.equals("con")){
				try { total_lpat = Integer.parseInt(rcpqi.getTotal("lpatq")); } catch(Exception ignored) { total_lpat = 0; }
				try { total_tpat = Integer.parseInt(rcpqi.getTotal("tpatq")); } catch(Exception ignored) { total_tpat = 0; }
				}
				else if(usertype.equals("doc")){
				String dreg=rcui.getreg_no(userid);
				total_lpat = Integer.parseInt(rcpqi.getTotalLPatDoc(ccode,dreg));
				}
				else {total_lpat=10;}

				String doc_regno = "";
				if(usertype.equals("doc")){
				doc_regno = rcui.getreg_no(userid);
				//out.println("rg_no: "+doc_regno);
				}
				Object objstat = rcStat.getDocPatQueueInfo(doc_regno);
				Vector objstatV = (Vector)objstat;
				String redPage="",id="";
				try{
				redPage = request.getParameter("dest");
				id = request.getParameter("id");
				}catch(Exception ex){
				redPage="";
				id="";
				}

				%>

				<% layout LayoutMenu=new layout(request.getRealPath("/")); // authorization point // adm,1,head1,top,1
					// out.println(menuid+" "+menu);
					String menu=LayoutMenu.getMainMenu(usertype,tmpid,menuid,"new" + "_sk","1"); String[] parts=menu.split(":", -1); if(parts.length<10) parts=new String[]{"dashb.jsp,Dash Board","browse.jsp,Local Patient","patientAlldata.jsp,Patient Data","patientAlldata.jsp,Patient Data","editprofile.jsp,Edit Profile","logout.jsp,Log Out","dashb.jsp,Dashboard","jobadmin.jsp,Admin Jobs","editprofile.jsp,Edit Profile","logout.jsp,Log Out"}; String
					lpatq_link="" ,tpatq_link="" ,tpatwaitq_link="" ,reff_status_link="" ,admjobs_link=""
					,edtProfile_link="" ,logout_link="" ,pat_reg="" ,viewpres="" ; int par_len=parts.length; int
					utypeInt=utypeI(usertype); switch(utypeInt){ case 0 : lpatq_link=parts[0];
					reff_status_link=parts[1]; tpatwaitq_link=parts[2]; tpatq_link=parts[3]; edtProfile_link=parts[4];
					logout_link=parts[5]; break; case 1 : pat_reg=parts[1]; lpatq_link=parts[3]; tpatq_link=parts[5];
					admjobs_link=parts[7]; reff_status_link=parts[4]; edtProfile_link=parts[8]; logout_link=parts[9];
					break; case 2 : lpatq_link=parts[2]; viewpres=parts[3]; edtProfile_link=parts[4];
					logout_link=parts[5]; break; case 3 : edtProfile_link=parts[2]; logout_link=parts[3]; break; case 4
					: edtProfile_link=parts[1]; logout_link=parts[2]; break; case 5 : edtProfile_link=parts[1];
					logout_link=parts[2]; break; default : lpatq_link="" ; tpatq_link="" ; tpatwaitq_link="" ;
					reff_status_link="" ; } //out.println("<script>console.log("+lpatq_link+")</script>");
					// The switch above guesses edtProfile_link/logout_link by fixed position, which breaks
					// whenever the XML menu item count changes. Override with a content-based lookup so the
					// Edit Profile and Log Out links are always resolved correctly regardless of position.
					for (int __li = 0; __li < parts.length; __li++) { if(parts[__li].startsWith("editprofile.jsp")) edtProfile_link=parts[__li]; else if(parts[__li].startsWith("logout.jsp")) logout_link=parts[__li]; }
					if(lpatq_link.indexOf(",")<0) lpatq_link="browse.jsp,Local Patient"; if(tpatq_link.indexOf(",")<0) tpatq_link="telebrowse.jsp,Tele Patient"; if(tpatwaitq_link.indexOf(",")<0) tpatwaitq_link="telewaitbrowse.jsp,Tele Wait"; if(reff_status_link.indexOf(",")<0) reff_status_link="telebrowse.jsp,Tele Patient"; if(admjobs_link.indexOf(",")<0) admjobs_link="jobadmin.jsp,Admin Jobs"; if(edtProfile_link.indexOf(",")<0) edtProfile_link="editprofile.jsp,Edit Profile"; if(logout_link.indexOf(",")<0) logout_link="logout.jsp,Log Out"; if(pat_reg.indexOf(",")<0) pat_reg="select.jsp,Registration"; if(viewpres.indexOf(",")<0) viewpres="viewPrescriptions.jsp,View Prescription";
					//String part4=part3.insertAll("data-target=\"#navbarCollapse\" data-toggle=\"collapse\"");



					String menul=LayoutMenu.getMainMenu(usertype,tmpid,"left","new" + "_sk","1"); // authorization point
					//out.println("<div>"+menul+"</div>");
					%>

					<head>
						<meta charset="utf-8">
						<meta name="viewport" content="width=device-width, initial-scale=1">
						<link rel="icon" type="image/png"
							href="<%=request.getContextPath()%>/images/icons/imedix.ico" />
						<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/bootstrap.min.css">
						<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/toastr.css">
						<!--<link rel="stylesheet" href="../bootstrap/jquery.dataTables.min.css">-->
						<link rel="stylesheet"
							href="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.css">
						<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/index.css?v=2.1">

						<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/jquery-ui.min.css">
						<link rel="stylesheet" href="<%=request.getContextPath()%>/vc/vc.css?" +n>

						<script src="<%=request.getContextPath()%>/bootstrap/jquery-2.2.1.min.js"></script>
						<script src="<%=request.getContextPath()%>/bootstrap/toastr.js"></script>
						<script src="<%=request.getContextPath()%>/bootstrap/js/bootstrap.min.js"></script>
						<script src="<%=request.getContextPath()%>/bootstrap/jquery.dataTables.min.js"></script>
						<script src="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.js"></script>
						<script src="<%=request.getContextPath()%>/bootstrap/jquery-ui.min.js?" +n></script>
						<script src="https://<%=vidServerUrl%>/external_api.js"></script>
						<script src="<%=request.getContextPath()%>/bootstrap/js/skeleton-loader.js"></script>



					</head>
					<style>
						/* If the screen size is 601px wide or more, set the font-size of <div> to 40px */
						@media screen and (min-width: 601px) {
							.center-name {
								font-size: 40px;
							}
						}

						/* If the screen size is 600px wide or less, set the font-size of <div> to 24px */
						@media screen and (max-width: 600px) {
							.center-name {
								font-size: 24px;
							}

							.account {
								top: -13px;
								position: absolute;
								right: 4px;
							}

							.img2-responsive.logo2 {
								border-radius: 50%;
							}
						}

						.img1-responsive.logo1 {
							left: -10px;
							top: 20px;
							width: 290px;
							padding: 0px 6px;
							position: relative;

						}

						.img2-responsive.logo2 {
							top: 4px;
							left: 12px;
							height: 90px;
							padding: 4px 4px;
							z-index: 9;
							position: absolute;
							border: 1px solid #ddd;
							box-shadow: 0px 0px 8px 3px #ccc;

						}

						.center-name {

							font-weight: 500;
							color: #fff;
							text-shadow: 2px 2px 4px #000000;
							font-family: serif;
							text-align: center;
							font-variant: small-caps;
							height: 100px;

							background-color: steelblue;
						}

						.di .chk-lg {
							width: 20px;
							height: 16px;
						}

						.left>div.active {
							border: 2px solid #607D8B;
							background: #eef;
							color: #333;
						}

						#search-result {
							margin-top: 20px;
						}
					</style>

					<script language="javascript">

						function searchPatient() {
							$('#search-result').html('');
							var key = $('#patid').val();
							$.ajax({
								type: "GET",
								url: 'search_patient.jsp',
								data: { key: key },
								success: function (data) {
									var res = JSON.parse(data);
									if (res.status == 'success') {
										if (res.data.length > 0) {
											var pat_list = '<table class="table table-striped">';
											pat_list += '<thead><tr>';
											pat_list += '<th>Patient ID</th><th>Name</th><th>Phone</th><th>Contact Person</th>';
											pat_list += '</tr></thead>';
											res.data.forEach(element => {
												pat_list += '<tr>';
												pat_list += '<td><a href="#" onClick="selectPatient(this)">' + element.pat_id + '</a></td>';
												pat_list += '<td>' + element.pat_name + ' ' + element.l_name + '</td>';
												pat_list += '<td>' + element.phone + '</td>';
												//pat_list += '<td>'+element.emailid + '</td>';
												pat_list += '<td>' + element.pat_person + '</td>';
												pat_list += '</tr>';
											});
											pat_list += '</table>';
											$('#search-result').html(pat_list);
										}
									}
								}
							});
						}


						function selectPatient(element) {
							event.preventDefault();
							var patid = $(element).html();
							$('#patid').val(patid);
							$('#search-result').html('');
						}


						// Patient registration autocomplete end


						$.ajaxSetup({
							cache: false
						});
						function clearPanel(fileName) {
							$(".left div.getId").removeClass("active");
							$(".pat-prof-sum").remove();
							var patque = fileName.match("browse.jsp");
							var oldpat = fileName.match("oldpat.jsp");
							if (patque == "browse.jsp" || oldpat == "oldpat.jsp" || patque == "totalsummary.jsp" || fileName.indexOf("poBadoPending.jsp") == 0 || fileName == "psychologistPatientMenu.jsp" || fileName.indexOf("psychologistPatientList.jsp") == 0 || fileName.indexOf("patientMonitoring") == 0) {
								var loadUrl = "<%=request.getContextPath()%>/jspfiles/" + fileName;
								var ajax_load = "<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='loading...'>";
								$("#main_frame").html(ajax_load).load(loadUrl);
								$("#main_frame").css("min-height", "100%");
								//$("#main_frame").css("max-height", "100%");
							}
							else {
								document.getElementById("main_frame").innerHTML = "<object class='responsive obj' type='text/html' data=<%=request.getContextPath()%>/jspfiles/" + fileName + " style='width:100%; height:100%;'>> </object>";
							}
						}
						function ajaxRedirect(fileName) {
							var loadUrl = "./" + fileName;
							var ajax_load = "<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='loading...'>";
							$(".main-body").html(ajax_load).load(loadUrl);
						}

						function viewReport(fileName) {
							var loadUrl = "./" + fileName;
							var ajax_load = "<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='loading...'>";
							$(".report-sheet").html(ajax_load).load(loadUrl);
							$(".report-sheet").css("min-height", "100%");
							$(".report-sheet").css("max-height", "100%");
							$(".report-close").show();
							$(".prc").attr("style", "filter:blur(5px)");
						}
						function clearPanelRight(fileName) {
							$(".left div.getId").removeClass("active");
							$(".pat-prof-sum").remove();

							$(".right-div.report-sheet").html("<object class='responsive obj' type='text/html' data=<%=request.getContextPath()%>/jspfiles/" + fileName + " style='width:100%; height:100%;'>> </object>");

						}
						var Counter = (function () {
							var i = 0;
							return function () { i += 1; return i }
						})();
					</script>

					<script>
						function home(fileName) {
							var obj = { "adm": "dashb.jsp", "doc": ".vis_pat", "user": ".pat_reg ", "pOP": "getPendingPatientPatho.jsp", "rOP": "getStudyUID.jsp", "psy": "getPendingTobacco.jsp" };
							var loadUrl = "";
							/*if(fileName == "adm")
								loadUrl = "<%=request.getContextPath()%>/jspfiles/" + obj.adm;
							else if(fileName == "doc")
								loadUrl = obj.doc;
							else
								loadUrl = obj.user;*/

							for (let i = 0; i < Object.keys(obj).length; i++) {
								if (Object.keys(obj)[i] == fileName)
									loadUrl = Object.values(obj)[i];
							}

							if (fileName == "adm") {
								var ajax_load = "<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='loading...'>";
								$("#main_frame").html(ajax_load).load(loadUrl);
								$("#main_frame").css("min-height", "100%");
								//$("#main_frame").css("max-height", "100%");
							}
							if (fileName == "pOP" || fileName == "rOP" || fileName == "psy")
								clearPanel(loadUrl);
							else {
								$(loadUrl).click();
							}
							//document.getElementById("main_frame").innerHTML= "<object class='responsive obj' type='text/html' data='welcome.jsp' style='width:100%; height:100%;'>> </object>";
						}

						$(document).ready(function () {

							sessionStorage.removeItem("patlist");
							sessionStorage.removeItem("currentpat");

							var redPage = "<%=redPage%>";
		<% if (redPage == "" || redPage == null) { %>

		<%} else {%>
								pageRedirection("<%=redPage%>" + ".jsp?id=<%=id%>", "<%=id%>");
		<%}%>
		/*
		$("body").click(function(){$("input.id").focus();});
		*/
		var left_menu = eval(<%=menul %>);
							//console.log(left_menu);
							var len = Object.keys(left_menu).length;
							for (var i = 0; i < len; i++) {
								$(".index .left").append("<div class='" + left_menu[i][1].substring(0, 3).toLowerCase() + '_' + left_menu[i][1].substring(left_menu[i][1].indexOf(' ') + 1, left_menu[i][1].indexOf(' ') + 4).toLowerCase() + " getId' trackId='" + i + "'>" + left_menu[i][1] + "<span class='glyphicon glyphicon-circle-arrow-right pull-right sn'></span></div>");
							}
							//console.log(left_menu);

							$(".left div.getId").click(function () {
								var body = "";
								if ($(this).attr("class").match("pat_reg") != null) {
									//body = "<div class='new-reg'><a onclick=\"clearPanel('selectdoc.jsp')\" class='btn btn-block'><span>New Patient Registration</span> </a></div><div class='pat-id'><span>Old Patient Registration<p>(Enter patient id into the testbox)</p></span><div class='input-group'><input class='form-control id' name='patid' placeholder='Patient id Ex: EXTR2011170001' /><div class='input-group-btn'><button class='btn btn-primary pull-right id-submit'>GO</button></div></div></div>";
									//body = "<div class='new-reg'><a onclick=\"clearPanel('../forms/med1.jsp?')\" class='btn btn-block'><span>New Patient Registration</span> </a></div><div class='pat-id'><span>Old Patient Registration<p>(Enter patient id into the testbox)</p></span><div class='input-group'><input class='form-control id' name='patid' placeholder='Patient id Ex: EXTR2011170001' /><div class='input-group-btn'><button class='btn btn-primary pull-right id-submit'>GO</button></div></div></div>";
									body = "<div class='new-reg'><a onclick=\"clearPanel('../forms/med1.jsp?')\" class='btn btn-block'>" +
										"<span>New Patient Registration</span> </a></div><div class='pat-id'><span>Old Patient Registration<p>(Enter patient id into the testbox)</p>" +
										"</span><div class='input-group'><input class='form-control' data-toggle='popover' data-toggle='popover' id='patid' name='patid' placeholder='Patient id Ex: EXTR2011170001 or Name or Mobile Number or Contact Person' />" +
										"<div class='input-group-btn'><button class='btn btn-success' onClick='searchPatient()'>Search</button><button class='btn btn-primary id-submit' id='patid-submit'>GO</button></div></div>" +
										"<div id='search-result'></div></div>";
								}
								else if ($(this).attr("class").match("vid_con") != null);
								//body = "<A class='responsive obj' target=_blank href='../vc/main.jsp' style='width:100%; height:100%;'>Goto Video Conference System</a>";
								//body = <button id="vc" name="vc" class="btn responsive obj" >
								else
									body = "<div class='pat-id'><span>Enter Patient Id : </span><div class='input-group'><input class='form-control id' name='patid' placeholder='Patient id Ex: EXTR2011170001' /><div class='input-group-btn'><button class='btn btn-primary pull-right id-submit'>GO</button></div></div>" +
										"<div class='row' style='padding-top:20px;padding-right:20px;'>" +
										"<div class='col-sm-4'><div class='jumbotron'><h3 class='text-center'>Pending Appointments To Set (Local)&nbsp;&nbsp;</h3><div class='text-center' style='margin-top:30px;'><div class='label label-info' style='font-size: 2em;'><%=objstatV.get(0)%></div></div></div></div>" +
										"<div class='col-sm-4'><div class='jumbotron'><h3 class='text-center'>Today's No Of Patient (Local)</h3><div class='text-center' style='margin-top:30px;'><div class='label label-info' style='font-size: 2em;'><%=objstatV.get(1)%></div></div></div></div>" +
										"<div class='col-sm-4'><div class='jumbotron'><h3 class='text-center'>Pending Appointments To Set (Referral)</h3><div class='text-center' style='margin-top:30px;'><div class='label label-info' style='font-size: 2em;'><%=objstatV.get(2)%></div></div></div></div>" +
										"<div class='col-sm-6'><div class='jumbotron'><h3 class='text-center'>Pending Referred Cases Waiting for Acceptance</h3><div class='text-center' style='margin-top:30px;'><div class='label label-info' style='font-size: 2em;'><%=objstatV.get(3)%></div></div></div></div>" +
										"<div class='col-sm-6'><div class='jumbotron'><h3 class='text-center'>Today's No Of Patient (Referral)</h3><div class='text-center' style='margin-top:35px;'><div class='label label-info' style='font-size: 2em;'><%=objstatV.get(4)%></div></div><br></div></div>" +


										"</div></div>";

								$(".main-body").html(body);
								$("input.id").focus();
								$(".continue").attr("style", "display:block");
								$(".left div.getId").removeClass("active");
								$(this).addClass("active");
								//alert($(this).attr("trackId"));
								var trackId = $(this).attr("trackId");

								$(".tele").click(function () { $("input.id").focus(); });

								//$(".id").change(function(){
								//	var url = left_menu;
								//	if($(this).val().length>=14 && $(this).val().length <=18){
								$("#patid-submit").click(function () {
									console.log("patid-submit");
									event.preventDefault();
									var url = left_menu;
									var patient_id = $('input#patid').val();
									// alert(patient_id);
									// return;
									if (patient_id.length >= 14 && patient_id.length <= 18) {
										var currpatqtype = "local";
										/*	if($(".tele").prop("checked")==true){
												currpatqtype="tele";
											}
											if($(".tele").prop("checked")==false){
												currpatqtype = "local";
											}*/

										$(".pat-id").remove();
										var head_url = "patSortinfo.jsp?id=" + patient_id + "&usr=<%=usertype%>&nam=*&patdis=<%=distype%>&currpatqtype=" + currpatqtype;
										//var head_url = "patSortinfo.jsp?id="+$(this).val()+"&usr=<%=usertype%>&nam=*&patdis=<%=distype%>&currpatqtype="+currpatqtype;
										$.get(head_url, function (data, status) {
											$(".pat-head-title").html(data);
											if (status == "success" && url[trackId][2] == "ajax") {
												$(".main-body").html("<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='loading...'>");
												$.get(url[trackId][0], function (data, status) {
													$(".main-body").html(data);
												});
												//console.log("gg : "+url[trackId][0]);
											}
											else { clearPanel(url[trackId][0]) }
										});

										//$(".main-body").html("<h1>Form</h1><div class=aa>Patient Id : "+$(this).val()+"</div>");
									}
									else {
										alert("Invalid patient id");
										//$(this).val("")}
										$('#patid').val("");
									}
								});
								$(".id").change(function () {
									var url = left_menu;
									if ($(this).val().length >= 14 && $(this).val().length <= 18) {

										var currpatqtype = "local";
										/*	if($(".tele").prop("checked")==true){
												currpatqtype="tele";
											}
											if($(".tele").prop("checked")==false){
												currpatqtype = "local";
											}*/

										$(".pat-id").remove();
										var head_url = "patSortinfo.jsp?id=" + $(this).val() + "&usr=<%=usertype%>&nam=*&patdis=<%=distype%>&currpatqtype=" + currpatqtype;
										$.get(head_url, function (data, status) {
											$(".pat-head-title").html(data);
											if (status == "success" && url[trackId][2] == "ajax") {
												$(".main-body").html("<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='loading...'>");
												$.get(url[trackId][0], function (data, status) {
													$(".main-body").html(data);
												});
												console.log("gg : " + url[trackId][0]);
											}
											else { clearPanel(url[trackId][0]) }
										});

										//$(".main-body").html("<h1>Form</h1><div class=aa>Patient Id : "+$(this).val()+"</div>");
									}
									else { alert("Invalid patient id"); $(this).val("") }
								});

								$(".continue").click(function () {
									var trackId = $(".left div.getId.active").attr("trackId");
									var url = left_menu;
									$(".pat-id").remove();
									$(".main-body").html("<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='loading...'>");
									$.get(url[trackId][0], function (data, status) {
										$(".main-body").html(data);
										if (status == "success")
											$(".continue").attr("style", "display:none");
									});

								});


							});

							$(".collapse.in").each(function () {
								$(this).siblings(".panel-heading").find(".glyphicon").addClass("glyphicon-minus").removeClass("glyphicon-plus");
							});

							// Toggle plus minus icon on show hide of collapse element
							$(".collapse").on('show.bs.collapse', function () {
								$(this).parent().find(".glyphicon").removeClass("glyphicon-plus").addClass("glyphicon-minus");
							}).on('hide.bs.collapse', function () {
								$(this).parent().find(".glyphicon").removeClass("glyphicon-minus").addClass("glyphicon-plus");
							});

							home('<%=usertype%>');
							if ($(window).width() < 768) {
								$(".rect").click(function () {
									$("#main_frame").attr("tabindex", "1");
									$("#main_frame").focus();
								});
							}

						});

						function pageRedirection(page, id) {
							var head_url = "patSortinfo.jsp?id=" + id + "&usr=<%=usertype%>&nam=*&patdis=<%=distype%>&currpatqtype=local";
							$.get(head_url, function (data, status) {
								$(".pat-head-title").html(data);
								if (status == "success") {
									$(".main-body").html("<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='loading...'>");
									$.get(page, function (data, status) {
										$(".main-body").html(data);
									});
								}
							});
						}


					</script>




					<%! public int utypeI(String utype){ int utypei=-1; if(utype.equals("doc")) utypei=0; else
						if(utype.equals("adm")) utypei=1; else if(utype.equals("usr")) utypei=2; else
						if(utype.equals("rOP")) utypei=3; else if(utype.equals("pOP")) utypei=4; else
						if(utype.equals("psy")) utypei=5; else utypei=-1; return utypei; } %>


						<body class="index">




							<div class="container-fluid">
								<div class="row header">
									<div class="col-md-3 brand-container">
										<a href="<%=request.getContextPath()%>/jspfiles/home" class="brand-link">
											<img class="logo-img logo1"
												src="<%=request.getContextPath()%>/images/imlogo.jpg" />
											<span class="brand-text">M-Dosthi</span>
										</a>
									</div>


									<div class="col-md-8 header-block">

										<%-- <% if(!(usertype.equals("pOP") || !usertype.equals("psy")
											||usertype.equals("rOP"))){ %> --%>
											<% if(!(usertype.equals("pOP") || usertype.equals("rOP") ||
												usertype.equals("psy"))){ %>
												<div class="row">
													<% if(usertype.equals("adm")){ %>
														<div class="col-sm-3 patq rect"
															onclick='clearPanel("poBadoPending.jsp")'><span class="title">Pending Screening</span>
															<div class="cnt"><span></span></div>
														</div>
														<div class="col-sm-3 tpatq rect"
															onclick='clearPanel("browse.jsp")'><span class="title">Local Patient</span>
															<div class="cnt"><span></span></div>
														</div>
														<div class="col-sm-3 reff-sts rect"
															onclick='clearPanel("jobadmin.jsp")'><span class="title">Admin Jobs</span>
															<div class="cnt"><span></span></div>
														</div>
													<% } else { %>
													<div class="col-sm-3 patq rect"
														onclick='clearPanel("<%=lpatq_link.split(",")[0]%>")'><span
															class="title">
															<%=lpatq_link.split(",")[1]%>
														</span>
														<div class="cnt"><span><!--<%=total_lpat%>--></span></div>
													</div>
													<% if(!usertype.equals("usr")) { %>
														<div class="col-sm-3 tpatq rect"
															onclick='clearPanel("<%=tpatq_link.split(",")[0]%>")'><span
																class="title">
																<%=tpatq_link.split(",")[1]%>
															</span>
															<div class="cnt"><span><!--<%=total_tpat%>--></span></div>
														</div>
														<div class="col-sm-3 reff-sts rect"
															onclick='clearPanel("<%=reff_status_link.split(",")[0]%>")'>
															<span class="title">
																<%=reff_status_link.split(",")[1]%>
															</span>
															<div class="cnt"><span></span></div>
														</div>
														<% } %>
															<% if(usertype.equals("doc")) {%>
																<div class="col-sm-3 twaitq rect"
																	onclick='clearPanel("<%=tpatwaitq_link.split(",")[0]%>")'>
																	<span class="title">
																		<%=tpatwaitq_link.split(",")[1]%>
																	</span>
																	<div class="cnt"><span></span></div>
																</div>
																<div class="col-sm-3 annotq rect" onclick="openPipelineQueueModal()">
																	<span class="title">Annotation Queue</span>
																	<div class="cnt"><span class="glyphicon glyphicon-tasks"></span></div>
																</div>
																<div class="col-sm-3 monitoring rect" onclick="clearPanel('patientMonitoringDoctorList.jsp')">
																	<span class="title">Patient Monitoring</span>
																	<div class="cnt"><span class="glyphicon glyphicon-heart"></span></div>
																</div>
																<% } if(usertype.equals("adm")){%>
																	<div class="col-sm-3 reff-sts rect"
																		onclick='clearPanel("<%=admjobs_link.split(",")[0]%>")'>
																		<span class="title">
																			<%=admjobs_link.split(",")[1]%>
																		</span>
																		<div class="cnt"><span></span></div>
																	</div>
																	<% } if(usertype.equals("usr")){%>
																		<div class="col-sm-3 viewpres rect"
																			onclick='clearPanel("<%=viewpres.split(",")[0]%>")'>
																			<span class="title">
																				<%=viewpres.split(",")[1]%>
																			</span>
																			<div class="cnt">
																				<span><!--<%=total_lpat%>--></span>
																			</div>
																		</div>
																		<%}%>
														<% } %>
												</div>
												<%} if(usertype.equals("rOP")) {%>
													<div class="col-sm-3 pendTest rect"
														onclick='clearPanel("<%=parts[0].split(",")[0]%>")'><span
															class="title">
															<%=parts[0].split(",")[1]%>
														</span>
														<div class="cnt"><span><!--<%=total_lpat%>--></span></div>
													</div>
													<div class="col-sm-3 actvTest rect"
														onclick='clearPanel("<%=parts[1].split(",")[0]%>")'><span
															class="title">
															<%=parts[1].split(",")[1]%>
														</span>
														<div class="cnt"><span><!--<%=total_lpat%>--></span></div>
													</div>
													<!--<div class="col-sm-3 actvTest rect" onclick='clearPanel("<%=parts[2].split(",")[0]%>")'><span class="title"><%=parts[2].split(",")[1]%></span><div class="cnt"><span><%=total_lpat%></span></div></div>-->

													<%} else if(usertype.equals("pOP")) {%>
														<div class="col-sm-3 pendTest rect"
															onclick='clearPanel("<%=parts[0].split(",")[0]%>")'><span
																class="title">
																<%=parts[0].split(",")[1]%>
															</span>
															<div class="cnt"><span><!--<%=total_lpat%>--></span></div>
														</div>
														<!--<div class="col-sm-3 actvTest rect" onclick='clearPanel("<%=parts[1].split(",")[0]%>")'><span class="title"><%=parts[1].split(",")[1]%></span><div class="cnt"><span><%=total_lpat%></span></div></div>-->

														<%-- <% } %> --%>
															<%} else if(usertype.equals("psy")) {%>
																<div class="col-sm-3 pendTest rect"
																	onclick='clearPanel("<%=parts[0].split(",")[0]%>")'>
																	<span class="title">
																		<%=parts[0].split(",")[1]%>
																	</span>
																	<div class="cnt"><span><!--<%=total_lpat%>--></span>
																	</div>
																</div>
																<div class="col-sm-3 patq rect"
																	onclick='clearPanel("psychologistPatientMenu.jsp")'>
																	<span class="title">Patient Details</span>
																	<div class="cnt"><span></span></div>
																</div>
																<div class="col-sm-3 monitoring rect" onclick="clearPanel('patientMonitoringDoctorList.jsp')">
																	<span class="title">Patient Monitoring</span>
																	<div class="cnt"><span class="glyphicon glyphicon-heart"></span></div>
																</div>
																<!--<div class="col-sm-3 actvTest rect" onclick='clearPanel("<%=parts[1].split(",")[0]%>")'><span class="title"><%=parts[1].split(",")[1]%></span><div class="cnt"><span><%=total_lpat%></span></div></div>-->

																<% } %>


									</div>

									<div class="col-md-1 account">
										<div class="profile" onclick='clearPanel("<%=edtProfile_link.split(",")[0]%>")'>
											<span class="glyphicon glyphicon-user glph-lg"
												title='<%=edtProfile_link.split(",")[1]%>'></span>
										</div>
										<div class="logout" onclick='window.top.location.href="<%=request.getContextPath()%>/jspfiles/logout.jsp"'><span
												class="glyphicon glyphicon-off glph-lg"
												title='<%=logout_link.split(",")[1]%>'></span></div>
									</div>

								</div>

								<div class="row body">
									<div class="col-sm-12 username-title" style="top: 30px;">Welcome, <%=username%>
									</div>
									<!-- jq dialog Mithuns Update-->
									<div style="display:none" id="dialog" title="iMediX-Video Conferencing">
										<div class="row-fluid">
											<div class="col-sm-12">
												<div id="inner-container2">
													<div id="meet" style="background-color: grey"></div>
												</div>
												<div class="" style='text-align:center; margin: auto'>

												</div>
											</div>
										</div>
									</div>
									<!-- jq dialog end -->
									<div class="col-sm-3" style="margin-top:40px">
										<div class='row verification-panel'>
											<% String verifEmail="X" , verifMobile="X" , emIndicate, phIndicate; Object
												resu=rcui.getValues("*"," uid='"+userid+"'" );
						Vector vtmp = (Vector)resu;
						int vsz = vtmp.size();
						if(vtmp.size()>0) {
						dataobj datatemp = (dataobj) vtmp.get(0);
						verifEmail=datatemp.getValue(" verifemail"); verifMobile=datatemp.getValue("verifphone"); } if (
												verifMobile.equalsIgnoreCase("Y") )
												phIndicate="<span class='label label-success'><span class='glyphicon glyphicon-phone-alt'></span>&nbsp; <span class='glyphicon glyphicon-ok'></span></span>"
												; else
												phIndicate="<span class='label label-warning'><span class='glyphicon glyphicon-phone-alt'></span>&nbsp;<span class='glyphicon glyphicon-remove'></span></span>"
												; if ( verifEmail.equalsIgnoreCase("Y") )
												emIndicate="<span class='label label-success'><span class='glyphicon glyphicon-envelope'></span> &nbsp;<span class='glyphicon glyphicon-ok'></span></span>"
												; else
												emIndicate="<span class='label label-warning'><span class='glyphicon glyphicon-envelope'></span>&nbsp;<span class='glyphicon glyphicon-remove'></span></span>"
												; out.println
												( "<div class='col-sm-6'><h3 style='font-weight:normal; font-size: 20px; font-weight:normal;margin: 2px;padding: 3px;float:left;'>"
												+ emIndicate + "</h3></div>" ); out.println
												( "<div class='col-sm-6'><h3 style='font-weight:normal; font-size: 20px; font-weight:normal;margin: 2px;padding: 3px;float:right;'>"
												+ phIndicate + "</h3></div>" ); %>
												<br>
										</div>
										<div class="left"></div>
										<br>
										<!---------- Accordion Starts -->
										<div id="accordion">
											<h3>Chat Module</h3>
											<div class="left-chat">
												<span id=wsUri name=wsUri>
													<%=wsPath %>
												</span>
												<div id="output" style="height: 80px; overflow-y: auto"></div>
												<div class="input-group" style="margin-top:5px;">
													<input id="mesg-txt" class="form-control" type="text"
														name="mesg-txt" placeholder="Type Message"></input>
													<div class="input-group-btn">
														<a class="btn btn-default" id="send-msgbtn"
															name="send-msgbtn">Send</a>
													</div>
												</div>
											</div>

											<h3>Video Conference Application</h3>
											<div>
												<p>
													<button class="btn btn-primary btnShow">Show</button> &nbsp;|&nbsp;
													<button class="btn btn-success btnStart"
														onClick="start()">Start</button> &nbsp;|&nbsp;
													<button class="btn btn-danger btnStop" disabled="disabled"
														onClick="stop()">Stop</button>
												</p>
											</div>

											<h3>Invite Doctors for VC</h3>
											<div>
												<div class="left-doclist">
													<% Vector tmp=null; rcVideoConference vidconf=new
														rcVideoConference(request.getRealPath("/"));
														userid=cookx.getCookieValue("userid", request.getCookies());
														username=cookx.getCookieValue("username", request.getCookies());
														Object res=null; try{ res=vidconf.GetDoctors(); }
														catch(Exception ex){out.println("Errr0345: "+ex.toString());}
									tmp = (Vector)res;
								%>

							<div class=" panel-body" style="padding: 1px;">
														<div class="input-group" style="margin-bottom:10px;">
															<input id="search-doctor" class="form-control" type="text"
																name="search-doctor"
																placeholder="Doctor Name/userid"></input>
															<div class="input-group-btn">
																<a class="btn btn-default" id="clear-docbtn"
																	name="clear-docbtn">Clear</a>
															</div>
														</div>

														<div id="doctors" style="overflow-y: auto; height:150px">
															<ul class="doctors" id="doctors">
																<% for(int i=0;i<tmp.size();i++){ dataobj temp=(dataobj)
																	tmp.get(i); out.print("<" + "li>" ); out.print("<"
																	+ "a onClick=\" selectItem(this)\" href=\"#\">");
																	out.print("<" + "span style=\" display:none\">");
																		out.print(temp.getValue("name") + "|" +
																		temp.getValue("uid"));
																		out.print("</" + "span>" );
																		out.print(temp.getValue("name") + " (" +
																		temp.getValue("uid") + ") </" + "a>" );
																		out.print("</" + "li>\n" ); } %>
															</ul>
														</div>
														<div
															class="col-sm-12 col-sm-12 col-xs-12 text-right pull-right">
															<button class="btn btn-primary btn-xs"
																onClick="invite()">Invite</button>
														</div>
												</div>
											</div>
										</div>
									</div>


									<!---------- Accordion Ends ---->



								</div>
								<div class="col-sm-9 right">
									<div class="row pat-head-title">

									</div>

									<div class="row">
										<div class="col-sm-12 main-body" id="main_frame" style="margin-top:40px">
										</div>

									</div>

								</div>
							</div>


							</div>


							<!-- WhatsApp Logs Modal -->
							<div class="modal fade" id="whatsappLogsModal" tabindex="-1" role="dialog"
								aria-hidden="true" style="z-index: 1050;">
								<div class="modal-dialog modal-md" role="document">
									<div class="modal-content"
										style="border-radius: 16px; border: 1px solid var(--card-border); background: rgba(255, 255, 255, 0.95); backdrop-filter: blur(20px); box-shadow: 0 10px 30px rgba(0,0,0,0.15);">
										<div class="modal-header"
											style="border-bottom: 1px solid rgba(226, 232, 240, 0.8); padding: 16px 24px;">
											<button type="button" class="close" data-dismiss="modal" aria-label="Close"
												style="font-size: 24px; color: var(--text-muted); opacity: 0.8; outline: none;"><span
													aria-hidden="true">&times;</span></button>
											<h4 class="modal-title"
												style="font-weight: 700; color: var(--primary); display: flex; align-items: center; gap: 8px;">
												<span class="glyphicon glyphicon-phone" style="color: #25d366;"></span>
												WhatsApp Message Logs
											</h4>
										</div>
										<div class="modal-body"
											style="padding: 24px; max-height: 400px; overflow-y: auto;">
											<h5 style="margin-bottom: 16px; font-weight: 600; color: var(--text-main);">
												History for: <span id="waLogPatientName"
													style="color: var(--primary);"></span></h5>
											<div id="waLogsContainer">
												<!-- Logs list -->
											</div>
										</div>
										<div class="modal-footer"
											style="border-top: 1px solid rgba(226, 232, 240, 0.8); padding: 16px 24px;">
											<button type="button" class="btn btn-default" data-dismiss="modal"
												style="border-radius: 10px; font-weight: 500; padding: 8px 20px;">Close</button>
										</div>
									</div>
								</div>
							</div>

							<!-- Bulk WhatsApp Modal 
Author: Sayantan Patra
-->

							<div class="modal fade" id="bulkWhatsAppModal" tabindex="-1" role="dialog"
								aria-hidden="true" style="z-index: 1050;">
								<div class="modal-dialog modal-md" role="document">
									<div class="modal-content"
										style="border-radius: 16px; border: 1px solid var(--card-border); background: rgba(255, 255, 255, 0.95); backdrop-filter: blur(20px); box-shadow: 0 10px 30px rgba(0,0,0,0.15);">
										<div class="modal-header"
											style="border-bottom: 1px solid rgba(226, 232, 240, 0.8); padding: 16px 24px;">
											<button type="button" class="close" data-dismiss="modal" aria-label="Close"
												style="font-size: 24px; color: var(--text-muted); opacity: 0.8; outline: none;"><span
													aria-hidden="true">&times;</span></button>
											<h4 class="modal-title"
												style="font-weight: 700; color: var(--primary); display: flex; align-items: center; gap: 8px;">
												<span class="glyphicon glyphicon-bullhorn"
													style="color: #25d366;"></span> Bulk WhatsApp Broadcast
											</h4>
										</div>
										<div class="modal-body" style="padding: 24px;">
											<!-- Broadcast Target Mode Selection -->
											<div style="margin-bottom: 20px;">
												<label
													style="font-weight: 600; color: var(--text-main); margin-bottom: 8px; display: block;">Broadcast
													Target Mode</label>
												<div style="display: flex; gap: 20px;">
													<label
														style="font-weight: 500; cursor: pointer; display: flex; align-items: center; gap: 6px;">
														<input type="radio" name="waBroadcastMode" value="selected"
															checked style="margin: 0; width: 18px; height: 18px;">
														Checked Patients in Queue
													</label>
													<label
														style="font-weight: 500; cursor: pointer; display: flex; align-items: center; gap: 6px;">
														<input type="radio" name="waBroadcastMode" value="batch"
															style="margin: 0; width: 18px; height: 18px;">
														Latest Patients (Batch Limit)
													</label>
												</div>
											</div>

											<!-- Checked Patients List Container -->
											<div id="waSelectedPatientsContainer" style="margin-bottom: 20px;">
												<h5
													style="font-weight: 600; color: var(--text-main); margin-bottom: 12px;">
													Selected Patients (<span id="waBulkCount">0</span>)</h5>
												<div id="waSelectedPatientsList"
													style="padding: 12px; background: rgba(241, 245, 249, 0.6); border-radius: 12px; border: 1px solid rgba(226, 232, 240, 0.8); max-height: 100px; overflow-y: auto; font-size: 13px; color: var(--text-muted); display: flex; flex-wrap: wrap; gap: 6px;">
													<!-- Names tags -->
												</div>
											</div>

											<!-- Number Input Container for Batch Selection -->
											<div id="waSliderSection"
												style="display: none; margin-bottom: 20px; padding: 15px; background: rgba(241, 245, 249, 0.6); border-radius: 12px; border: 1px solid rgba(226, 232, 240, 0.8);">
												<label for="waBatchLimit"
													style="font-weight: 600; color: var(--text-main); display: block; margin-bottom: 10px; width: 100%;">
													Limit Number of Patients (Max 200):
												</label>
												<input type="number" id="waBatchLimit" min="1" max="200" value="50"
													class="form-control" style="width: 100%; border-radius: 8px;">

												<!-- Dynamic rotation estimate display -->
												<div id="waRotationInfoBlock"
													style="margin-top: 12px; padding: 12px; background: rgba(255, 255, 255, 0.9); border-radius: 8px; border: 1px dashed rgba(37, 211, 102, 0.4); font-size: 13px;">
													<div
														style="display: flex; justify-content: space-between; margin-bottom: 6px;">
														<span style="color: var(--text-muted);">Total patients
															:</span>
														<strong style="color: var(--text-main);"><span
																id="waTotalRotCount">0</span> patients</strong>
													</div>
													<div
														style="display: flex; justify-content: space-between; margin-bottom: 6px;">
														<span style="color: var(--text-muted);">Patients who got
															messages:</span>
														<strong style="color: #4f46e5;"><span
																id="waNotifiedRotCount">0</span> patients</strong>
													</div>
													<div
														style="display: flex; justify-content: space-between; margin-bottom: 8px; border-bottom: 1px dashed #e2e8f0; padding-bottom: 6px;">
														<span style="color: var(--text-muted);">Patients left to get
															messages:</span>
														<strong style="color: #25d366;"><span
																id="waRemainingRotCount">0</span> patients</strong>
													</div>
													<div
														style="display: flex; justify-content: space-between; align-items: center;">
														<span style="color: var(--text-muted);">Rotation completion
															estimate:</span>
														<strong style="color: #128c7e; font-size: 14px;"><span
																id="waRotationDays">0</span> batches <span
																style="font-size: 11px; font-weight:normal; color: var(--text-muted);">(~<span
																	id="waRotationDaysVal">0</span>
																days)</span></strong>
													</div>
												</div>

												<p
													style="font-size: 12px; color: var(--text-muted); margin-top: 8px; margin-bottom: 0;">
													<span class="glyphicon glyphicon-info-sign"></span> Messages will be
													sent in order of the latest registration dates. Patients who have
													already received this template will be skipped automatically.
												</p>
											</div>

											<div style="margin-bottom: 16px;">
												<label
													style="font-weight: 600; color: var(--text-main); margin-bottom: 8px; display: block;">Message
													Template</label>
												<div style="display: flex; flex-direction: column; gap: 10px;">
													<label
														style="font-weight: 500; cursor: pointer; display: flex; align-items: center; gap: 8px;">
														<input type="radio" name="waBulkMsgType" id="waBulkTypeDefault"
															value="default" checked
															style="margin: 0; width: 18px; height: 18px;"> English
														Template (Standard)
													</label>
													<label
														style="font-weight: 500; cursor: pointer; display: flex; align-items: center; gap: 8px;">
														<input type="radio" name="waBulkMsgType" id="waBulkTypeBengali"
															value="bengali"
															style="margin: 0; width: 18px; height: 18px;"> Bengali
														Template (rem_bn)
													</label>
												</div>
											</div>
										</div>
										<div class="modal-footer"
											style="border-top: 1px solid rgba(226, 232, 240, 0.8); padding: 16px 24px;">
											<button type="button" class="btn btn-default" data-dismiss="modal"
												style="border-radius: 10px; font-weight: 500; padding: 8px 16px;">Cancel</button>
											<button type="button" id="waSendBulkBtn" class="btn btn-success"
												style="border-radius: 10px; font-weight: 600; padding: 8px 20px; background: #25d366 !important; border-color: #25d366 !important;"><span
													class="glyphicon glyphicon-send"></span> Send Broadcast</button>
										</div>
									</div>
								</div>
							</div>

						</body>



						<script src="<%=request.getContextPath()%>/vc/vc.js?ver=1.3"></script>
						<script>
							doc_id = '<%= userid %>';
							doc_name = '<%= username %>';
							usertype = '<%= usertype %>';
							$(document).on("click", ".btnShow", function () {
								ShowVC();
							})

						</script>
						<style>
							.ui-accordion .ui-accordion-content {
								padding: 0.5em 0.5em;
							}

							.left-chat {
								background-color: #EEEEEE;
							}

							.left-doclist {}

							ul.doctors {
								list-style: none;
								margin: 0;
								padding: 0;
							}

							ul.doctors li a {
								display: block;
								padding: 3px 5px;
								width: 98%;
								color: #727475;
								text-decoration: none;
							}

							ul.doctors li a.active {
								background-color: #5b7ba8;
								color: white;
							}
						</style>
						<script>
							usertype = '<%=usertype%>';
							userid = '<%=userid%>';
							//console.log('userid: '+userid);
							doc_regno = '<%=doc_regno%>';
							$(function () {
								$("#accordion").accordion({ active: 0, collapsible: true, heightStyle: "content" });
								//$.fn.bootstrapBtn = $.fn.button.noConflict();
								//var bootstrapButton = $.fn.button.noConflict(); // return $.fn.button to previously assigned value
								//$.fn.bootstrapBtn = bootstrapButton;            // give $().bootstrapBtn the Bootstrap functionality
								$(document).on('keypress', '#mesg-txt', function (e) {
									if (e.which == 13) {
										$('#send-msgbtn').click();
									}
								});
								setInterval(function () {
									//console.log("index1-usertype:"+usertype);
									if (usertype == 'doc') {
										beaconDoctor('<%=userid%>');
									}
								}, 5000);


							});

							// WhatsApp Notification Handlers
							var apiBase = window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1" ? "http://localhost:9090" : "";

							$(document).on("click", ".whatsapp-btn", function () {
								var btn = $(this);
								var id = btn.attr("data-id");
								var originalHtml = btn.html();
								btn.html("<span class='glyphicon glyphicon-refresh spin-icon'></span> Sending...").prop("disabled", true);

								$.ajax({
									type: "POST",
									url: apiBase + "/api/whatsapp/send?uid=" + id + "&messageType=default",
									success: function (data) {
										if (data.status === "SUCCESS") {
											toastr.success("WhatsApp notification sent successfully!");
										} else {
											alert("WhatsApp API status: " + data.status);
										}
									},
									error: function (xhr) {
										alert("Error sending WhatsApp notification: " + (xhr.responseJSON ? xhr.responseJSON.error : xhr.statusText));
									},
									complete: function () {
										btn.html(originalHtml).prop("disabled", false);
									}
								});
							});

							$(document).on("click", ".whatsapp-bn-btn", function () {
								var btn = $(this);
								var id = btn.attr("data-id");
								var originalHtml = btn.html();
								btn.html("<span class='glyphicon glyphicon-refresh spin-icon'></span> Sending...").prop("disabled", true);

								$.ajax({
									type: "POST",
									url: apiBase + "/api/whatsapp/send?uid=" + id + "&messageType=bengali",
									success: function (data) {
										if (data.status === "SUCCESS") {
											toastr.success("WhatsApp Bengali notification sent successfully!");
										} else {
											alert("WhatsApp API status: " + data.status);
										}
									},
									error: function (xhr) {
										alert("Error sending WhatsApp notification: " + (xhr.responseJSON ? xhr.responseJSON.error : xhr.statusText));
									},
									complete: function () {
										btn.html(originalHtml).prop("disabled", false);
									}
								});
							});

							$(document).on("click", ".whatsapp-logs-btn", function () {
								var btn = $(this);
								var id = btn.attr("data-id");
								var name = btn.attr("data-name");

								$("#waLogPatientName").text(name);
								$("#waLogsContainer").html("<div style='text-align: center; padding: 20px;'><span class='glyphicon glyphicon-refresh spin-icon' style='font-size: 24px; color: var(--primary);'></span> Loading logs...</div>");
								$("#whatsappLogsModal").modal("show");

								$.ajax({
									type: "GET",
									url: apiBase + "/api/whatsapp/logs?uid=" + id,
									success: function (logs) {
										var html = "";
										if (!logs || logs.length === 0) {
											html = "<div style='text-align: center; color: var(--text-muted); padding: 20px;'>No message logs found for this patient.</div>";
										} else {
											html = "<div style='display: flex; flex-direction: column; gap: 12px;'>";
											logs.forEach(function (log) {
												var date = new Date(log.sentAt);
												var formattedDate = date.toLocaleString();
												var statusColor = "#dc2626";
												var statusBg = "rgba(220,38,38,0.1)";
												var statusText = log.status || "Failed";
												if (log.status === "RECEIVED") {
													statusColor = "#059669";
													statusBg = "rgba(16,185,129,0.1)";
													statusText = "Received";
												} else if (log.status === "SUCCESS" || log.status === "SENT") {
													statusColor = "#4f46e5";
													statusBg = "rgba(79,70,229,0.1)";
													statusText = "Sent";
												} else if (log.status === "DELIVERED") {
													statusColor = "#0284c7";
													statusBg = "rgba(2,132,199,0.1)";
													statusText = "Delivered";
												} else if (log.status === "READ") {
													statusColor = "#10b981";
													statusBg = "rgba(16,185,129,0.1)";
													statusText = "Read";
												}

												html += "<div style='padding: 12px; border-radius: 12px; background: " + statusBg + "; border: 1px solid rgba(226, 232, 240, 0.8); border-left: 4px solid " + statusColor + ";'>";
												html += "  <div style='display: flex; justify-content: space-between; font-size: 11px; color: var(--text-muted); margin-bottom: 4px;'>";
												html += "    <span style='font-weight: 600; color: " + statusColor + ";'>" + statusText + "</span>";
												html += "    <span>" + formattedDate + "</span>";
												html += "  </div>";
												html += "  <div style='font-size: 13px; font-weight: 500; color: var(--text-main); white-space: pre-wrap;'>" + log.message + "</div>";
												html += "</div>";
											});
											html += "</div>";
										}
										$("#waLogsContainer").html(html);
									},
									error: function (xhr) {
										$("#waLogsContainer").html("<div class='alert alert-danger'>Failed to load logs: " + xhr.statusText + "</div>");
									}
								});
							});

							// Broadcast Modal Event Listeners
							$(document).on("change", "input[name='waBroadcastMode']", function () {
								var mode = $(this).val();
								if (mode === "selected") {
									$("#waSelectedPatientsContainer").show();
									$("#waSliderSection").hide();
								} else {
									$("#waSelectedPatientsContainer").hide();
									$("#waSliderSection").show();
									updateRotationStatus();
								}
							});

							$(document).on("input change", "#waBatchLimit", function () {
								var rawVal = $(this).val();
								if (rawVal !== "") {
									var val = parseInt(rawVal);
									if (isNaN(val)) {
										$(this).val(50);
									} else if (val > 200) {
										$(this).val(200);
									} else if (val < 1) {
										$(this).val(1);
									}
								}
								updateRotationStatus();
							});

							$(document).on("blur", "#waBatchLimit", function () {
								var rawVal = $(this).val();
								if (rawVal === "" || isNaN(parseInt(rawVal))) {
									$(this).val(50);
									updateRotationStatus();
								}
							});

							$(document).on("change", "input[name='waBulkMsgType']", function () {
								if ($("input[name='waBroadcastMode']:checked").val() === "batch") {
									updateRotationStatus();
								}
							});

							function updateRotationStatus() {
								var center = $("#bulkWhatsAppModal").data("center") || "";
								var msgType = $("input[name='waBulkMsgType']:checked").val() || "default";
								var limit = parseInt($("#waBatchLimit").val()) || 50;

								$("#waRemainingRotCount").text("...");
								$("#waTotalRotCount").text("...");
								$("#waNotifiedRotCount").text("...");
								$("#waRotationDays").text("...");
								$("#waRotationDaysVal").text("...");

								$.ajax({
									type: "GET",
									url: apiBase + "/api/whatsapp/rotation-status",
									data: {
										messageType: msgType,
										ccode: center
									},
									success: function (data) {
										var total = data.totalPatients || 0;
										var remaining = data.remainingPatients || 0;
										var notified = total - remaining;
										if (notified < 0) notified = 0;

										var displayRemaining = remaining;
										if (remaining === 0 && total > 0) {
											displayRemaining = total;
										}

										var days = Math.ceil(displayRemaining / limit) || 0;

										$("#waRemainingRotCount").text(remaining);
										$("#waTotalRotCount").text(total);
										$("#waNotifiedRotCount").text(notified);
										$("#waRotationDays").text(days);
										$("#waRotationDaysVal").text(days);

										if (remaining === 0 && total > 0) {
											$("#waRotationInfoBlock").css("border-color", "#ff9800");
										} else {
											$("#waRotationInfoBlock").css("border-color", "rgba(37, 211, 102, 0.4)");
										}
									},
									error: function (xhr) {
										console.error("Failed to load rotation status:", xhr);
									}
								});
							}

							function openBulkWhatsAppModal(centerCode) {
								$("#bulkWhatsAppModal").data("center", centerCode || "");
								var checkedBoxes = $("input[name='ch']:checked");
								var ids = [];
								var names = [];

								checkedBoxes.each(function () {
									var id = $(this).val();
									if (id) {
										ids.push(id);
										// Get patient name from the row (3rd td, index 2)
										var name = $(this).closest("tr").find("td:eq(2)").text().trim();
										names.push(name);
									}
								});

								if (ids.length === 0) {
									alert("Please select at least one patient using the checkboxes.");
									return;
								}

								$("#waBulkCount").text(ids.length);
								$("#waSelectedPatientsList").html("");
								names.forEach(function (name) {
									$("#waSelectedPatientsList").append("<span style='padding: 4px 10px; border-radius: 20px; background: rgba(79, 70, 229, 0.1); color: var(--primary); border: 1px solid rgba(79, 70, 229, 0.2); font-weight: 500; display: inline-flex; align-items: center; gap: 4px;'><span class='glyphicon glyphicon-user'></span> " + name + "</span>");
								});
								$("#waBulkCount").text(ids.length);

								if (ids.length === 0) {
									// No patients selected, default to batch mode and disable the "selected" option
									$("input[name='waBroadcastMode'][value='batch']").prop("checked", true).trigger("change");
									$("input[name='waBroadcastMode'][value='selected']").prop("disabled", true);
								} else {
									// Patients selected, enable both and default to selected
									$("input[name='waBroadcastMode'][value='selected']").prop("disabled", false).prop("checked", true).trigger("change");
								}

								$("#bulkWhatsAppModal").modal("show");

								$("#waSendBulkBtn").off("click").on("click", function () {
									var mode = $("input[name='waBroadcastMode']:checked").val();
									var msgType = $("input[name='waBulkMsgType']:checked").val();
									var center = $("#bulkWhatsAppModal").data("center");

									var originalHtml = $("#waSendBulkBtn").html();
									$("#waSendBulkBtn").html("<span class='glyphicon glyphicon-refresh spin-icon'></span> Sending...").prop("disabled", true);

									if (mode === "selected") {
										$.ajax({
											type: "POST",
											url: apiBase + "/api/whatsapp/bulk",
											data: {
												uids: ids.join(","),
												messageType: msgType
											},
											success: function (data) {
												if (data.status === "SUCCESS") {
													$("#bulkWhatsAppModal").modal("hide");
													toastr.success("Broadcast sent successfully to " + data.successful + " patients! (" + data.failed + " failed)");
													$("input[name='ch']").prop("checked", false);
												} else {
													alert("Failed to send broadcast: " + data.status);
												}
											},
											error: function (xhr) {
												alert("Error: " + (xhr.responseJSON ? xhr.responseJSON.error : xhr.statusText));
											},
											complete: function () {
												$("#waSendBulkBtn").html(originalHtml).prop("disabled", false);
											}
										});
									} else {
										// Batch slider mode
										var limit = $("#waBatchLimit").val();
										$.ajax({
											type: "POST",
											url: apiBase + "/api/whatsapp/broadcast-batch",
											data: {
												limit: limit,
												messageType: msgType,
												ccode: center
											},
											success: function (data) {
												if (data.status === "SUCCESS") {
													$("#bulkWhatsAppModal").modal("hide");
													toastr.success("Batch broadcast sent successfully! Sent: " + data.successful + ", Failed: " + data.failed + ", Skipped: " + data.invalidPhone);

													// Refresh patient queue page to show updated checked/logs if applicable
													if (typeof showselected === "function") {
														showselected("curCCode=" + center, "F=0&L=25");
													} else {
														var searchFrm = $("#main_frame").find(".searchlpatFrm");
														if (searchFrm.length > 0) {
															searchFrm.submit();
														}
													}
												} else {
													alert("Failed to send batch broadcast: " + data.status);
												}
											},
											error: function (xhr) {
												alert("Error: " + (xhr.responseJSON ? xhr.responseJSON.error : xhr.statusText));
											},
											complete: function () {
												$("#waSendBulkBtn").html(originalHtml).prop("disabled", false);
											}
										});
									}
								});
							}


						</script>

<!-- ===== Clear Pipeline Queue Confirmation Modal ===== -->
<div class="modal fade" id="clearQueueConfirmModal" tabindex="-1" role="dialog" style="z-index:1100;">
  <div class="modal-dialog modal-sm" role="document">
    <div class="modal-content">
      <div class="modal-header" style="background:#c0392b;color:#fff;border-radius:4px 4px 0 0;">
        <button type="button" class="close" data-dismiss="modal" style="color:#fff;opacity:1;">&times;</button>
        <h4 class="modal-title"><span class="glyphicon glyphicon-warning-sign"></span>&nbsp; Delete Queue</h4>
      </div>
      <div class="modal-body" style="text-align:center;padding:24px;">
        <p style="font-size:15px;">This will delete <strong>all jobs</strong> from the annotation queue.</p>
        <p style="color:#e74c3c;">This action cannot be undone.</p>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-danger" onclick="executeClearPipelineQueue()">Yes, Delete All</button>
        <button type="button" class="btn btn-default" data-dismiss="modal">No, Cancel</button>
      </div>
    </div>
  </div>
</div>

<!-- ===== Annotation Pipeline Queue Modal ===== -->
<div class="modal fade" id="pipelineQueueModal" tabindex="-1" role="dialog"
  <div class="modal-dialog modal-lg" role="document">
    <div class="modal-content">
      <div class="modal-header" style="background:#2c3e50;color:#fff;border-radius:4px 4px 0 0;">
        <button type="button" class="close" data-dismiss="modal" style="color:#fff;opacity:1;">&times;</button>
        <h4 class="modal-title"><span class="glyphicon glyphicon-tasks"></span>&nbsp; Annotation Pipeline Queue</h4>
      </div>
      <div class="modal-body" id="pipelineQueueModalBody">
        <div id="pipelineSettingsPanel" style="display:none;background:#f7f7f7;border:1px solid #ddd;border-radius:6px;padding:14px;margin-bottom:16px;">
          <h5 style="margin-top:0;"><span class="glyphicon glyphicon-cog"></span>&nbsp; Annotation Window</h5>
          <div class="row">
            <div class="col-sm-4">
              <label style="font-weight:normal;">Start Time</label>
              <input type="time" id="pipelineWindowStart" class="form-control input-sm">
            </div>
            <div class="col-sm-4">
              <label style="font-weight:normal;">End Time</label>
              <input type="time" id="pipelineWindowEnd" class="form-control input-sm">
            </div>
          </div>
          <div style="margin-top:10px;">
            <button type="button" class="btn btn-primary btn-sm" onclick="savePipelineSettings()"><span class="glyphicon glyphicon-floppy-disk"></span> Save</button>
            <button type="button" class="btn btn-default btn-sm" onclick="togglePipelineSettings(false)">Cancel</button>
            <span id="pipelineSettingsMsg" style="margin-left:10px;"></span>
          </div>
        </div>
        <div id="pipelineQueueContent">
          <div style="text-align:center;padding:30px;"><span class="glyphicon glyphicon-refresh" style="font-size:24px;"></span> Loading...</div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" onclick="togglePipelineSettings()"><span class="glyphicon glyphicon-cog"></span> Settings</button>
        <button type="button" class="btn btn-danger" onclick="confirmClearPipelineQueue()"><span class="glyphicon glyphicon-trash"></span> Delete Queue</button>
        <button type="button" class="btn btn-default" onclick="openPipelineQueueModal()"><span class="glyphicon glyphicon-refresh"></span> Refresh</button>
        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
</div>

<script>
function openPipelineQueueModal() {
    $('#pipelineQueueModal').modal('show');
    togglePipelineSettings(false);
    $('#pipelineQueueContent').html('<div style="text-align:center;padding:30px;"><span class="glyphicon glyphicon-refresh" style="font-size:24px;"></span> Loading...</div>');

    $.getJSON('pipelineQueueStatus.jsp', function(data) {
        if (!data.success) {
            $('#pipelineQueueContent').html('<div class="alert alert-danger">Failed to load queue: ' + data.error + '</div>');
            return;
        }

        var c = data.counts || {};
        var statusBadge = function(status) {
            var colors = { pending:'#e67e22', running:'#2980b9', completed:'#27ae60', failed:'#e74c3c' };
            var color = colors[status] || '#888';
            return '<span style="background:'+color+';color:#fff;padding:3px 8px;border-radius:10px;font-size:11px;font-weight:bold;">'+status.toUpperCase()+'</span>';
        };

        var html = '<div class="row" style="margin-bottom:16px;text-align:center;">'
            + '<div class="col-sm-3"><div style="background:#fff3e0;border-radius:8px;padding:12px;border:1px solid #e67e22;">'
            + '<div style="font-size:28px;font-weight:bold;color:#e67e22;">'+(c.pending||0)+'</div><div style="color:#888;">Pending</div></div></div>'
            + '<div class="col-sm-3"><div style="background:#e3f2fd;border-radius:8px;padding:12px;border:1px solid #2980b9;">'
            + '<div style="font-size:28px;font-weight:bold;color:#2980b9;">'+(c.running||0)+'</div><div style="color:#888;">Running</div></div></div>'
            + '<div class="col-sm-3"><div style="background:#e8f5e9;border-radius:8px;padding:12px;border:1px solid #27ae60;">'
            + '<div style="font-size:28px;font-weight:bold;color:#27ae60;">'+(c.completed||0)+'</div><div style="color:#888;">Completed</div></div></div>'
            + '<div class="col-sm-3"><div style="background:#fdecea;border-radius:8px;padding:12px;border:1px solid #e74c3c;">'
            + '<div style="font-size:28px;font-weight:bold;color:#e74c3c;">'+(c.failed||0)+'</div><div style="color:#888;">Failed</div></div></div>'
            + '</div>';

        html += '<table id="pipelineQueueTable" class="table table-bordered table-condensed" style="font-size:12px;width:100%;">'
            + '<thead style="background:#2c3e50;color:#fff;"><tr>'
            + '<th>#</th><th>Patient ID</th><th>Patient Name</th><th>Session ID</th><th>Status</th><th>Queued At</th><th>Started</th><th>Finished</th><th>Error</th>'
            + '</tr></thead><tbody>';

        $.each(data.jobs, function(i, job) {
            var err = job.error_message ? '<span title="'+job.error_message+'" style="cursor:help;color:#e74c3c;">&#9888; hover</span>' : '&mdash;';
            html += '<tr>'
                + '<td>' + job.id + '</td>'
                + '<td><b>' + job.pat_id + '</b></td>'
                + '<td>' + (job.pat_name || '&mdash;') + '</td>'
                + '<td>' + (job.session_id || '&mdash;') + '</td>'
                + '<td>' + statusBadge(job.status) + '</td>'
                + '<td>' + (job.created_at || '&mdash;') + '</td>'
                + '<td>' + (job.started_at || '&mdash;') + '</td>'
                + '<td>' + (job.finished_at || '&mdash;') + '</td>'
                + '<td>' + err + '</td>'
                + '</tr>';
        });

        html += '</tbody></table>';
        $('#pipelineQueueContent').html(html);
        $('#pipelineQueueTable').DataTable({ order: [[0,'desc']], pageLength: 10, language: { search: 'Filter:' } });
    }).fail(function() {
        $('#pipelineQueueContent').html('<div class="alert alert-danger">Could not reach pipelineQueueStatus.jsp</div>');
    });
}

function togglePipelineSettings(show) {
    var panel = $('#pipelineSettingsPanel');
    var willShow = (typeof show === 'boolean') ? show : !panel.is(':visible');
    $('#pipelineSettingsMsg').text('');
    if (willShow) {
        panel.show();
        $.getJSON('pipelineQueueSettings.jsp', function(data) {
            if (data.success) {
                $('#pipelineWindowStart').val(data.start_time);
                $('#pipelineWindowEnd').val(data.end_time);
            } else {
                $('#pipelineSettingsMsg').css('color', '#e74c3c').text('Failed to load settings: ' + data.error);
            }
        }).fail(function() {
            $('#pipelineSettingsMsg').css('color', '#e74c3c').text('Could not reach pipelineQueueSettings.jsp');
        });
    } else {
        panel.hide();
    }
}

function confirmClearPipelineQueue() {
    $('#clearQueueConfirmModal').modal('show');
    $('#clearQueueConfirmModal').on('shown.bs.modal', function() {
        $('.modal-backdrop').last().css('z-index', 1090);
    });
}

function executeClearPipelineQueue() {
    $('#clearQueueConfirmModal').modal('hide');
    $('#pipelineSettingsMsg').css('color', '#888').text('Deleting...');
    $.post('clearPipelineQueue.jsp', function(data) {
        if (data.success) {
            $('#pipelineSettingsMsg').css('color', '#27ae60').text('Queue cleared.');
            openPipelineQueueModal();
        } else {
            $('#pipelineSettingsMsg').css('color', '#e74c3c').text('Failed: ' + data.error);
        }
    }, 'json').fail(function() {
        $('#pipelineSettingsMsg').css('color', '#e74c3c').text('Could not reach clearPipelineQueue.jsp');
    });
}

function savePipelineSettings() {
    var startTime = $('#pipelineWindowStart').val();
    var endTime = $('#pipelineWindowEnd').val();
    if (!startTime || !endTime) {
        $('#pipelineSettingsMsg').css('color', '#e74c3c').text('Please set both start and end time.');
        return;
    }
    $.post('pipelineQueueSettings.jsp', { start_time: startTime, end_time: endTime }, function(data) {
        if (data.success) {
            $('#pipelineSettingsMsg').css('color', '#27ae60').text('Saved.');
            setTimeout(function() { togglePipelineSettings(false); }, 800);
        } else {
            $('#pipelineSettingsMsg').css('color', '#e74c3c').text('Failed to save: ' + data.error);
        }
    }, 'json').fail(function() {
        $('#pipelineSettingsMsg').css('color', '#e74c3c').text('Could not reach pipelineQueueSettings.jsp');
    });
}
</script>
<!-- ===== End Annotation Pipeline Queue Modal ===== -->

		</html>
