<%@page contentType="text/html"
	import="imedix.layout,java.io.*,imedix.cook,imedix.rcPatqueueInfo,imedix.rcUserInfo,imedix.dataobj,imedix.rcVideoConference, java.util.*"
	%>
	<html>
	<title>iMediX</title>
	<script>
		var d = new Date();
		var n = d.getMilliseconds();
	</script>
	<% //String wsPath=request.getServerName()+ ":" + request.getServerPort()+ "/WSiMediX" ; String
		wsPath=request.getServerName()+ "" + "/WSiMediX" ; cook cookx=new cook(); String
		userid=cookx.getCookieValue("userid", request.getCookies()); String username=cookx.getCookieValue("username",
		request.getCookies()); String usertype=cookx.getCookieValue("usertype", request.getCookies()); String
		distype=cookx.getCookieValue("distype", request.getCookies()); //String
		tmpid=request.getParameter("templateid"); String tmpid="1" ; //String menuid=request.getParameter("menuid");
		String menuid="head1" ; String ccode=cookx.getCookieValue("center", request.getCookies ()); String
		curCCode=request.getParameter("curCCode"); String cname=cookx.getCookieValue("centername", request.getCookies
		()); //out.println(usertype+"<br>"+tmpid+"<br>"+menuid);
		String str,str1;

		str1="<FONT COLOR=#003300 size='5' face='Times'><B>"+cname.toUpperCase()+"</B></FONT>";
		str = "&nbsp;&nbsp;&nbsp;(<b>
			<FONT COLOR=#330099 size='2' face='Verdana'>"+ username.toUpperCase() +"&nbsp;</FONT>
			<FONT COLOR=#330099> Logged on )</FONT>";

			rcPatqueueInfo rcpqi=new rcPatqueueInfo(request.getRealPath("/"));
			rcUserInfo rcui=new rcUserInfo(request.getRealPath("/"));

			int total_lpat = 0,total_tpat=0;
			if(usertype.equals("adm") || usertype.equals("usr") || usertype.equals("sup") || usertype.equals("con")){
			total_lpat = Integer.parseInt(rcpqi.getTotal("lpatq"));
			total_tpat = Integer.parseInt(rcpqi.getTotal("tpatq"));
			}
			else if(usertype.equals("doc")){
			String dreg=rcui.getreg_no(userid);
			total_lpat = Integer.parseInt(rcpqi.getTotalLPatDoc(ccode,dreg));
			}
			else {total_lpat=10;}

			String redPage="",id="";
			try{
			redPage = request.getParameter("dest");
			id = request.getParameter("id");
			}catch(Exception ex){
			redPage="";
			id="";
			}

			%>

			<% layout LayoutMenu=new layout(request.getRealPath("/")); String
				menu=LayoutMenu.getMainMenu(usertype,tmpid,menuid,"new_sk","1"); // authorization point //
				adm,1,head1,top,1 // out.println(menuid+" "+menu);
		String[] parts = menu.split(" :"); String lpatq_link="" ,tpatq_link="" ,tpatwaitq_link="" ,reff_status_link=""
				,admjobs_link="" ,edtProfile_link="" ,logout_link="" ,pat_reg="" ; int par_len=parts.length; int
				utypeInt=utypeI(usertype); switch(utypeInt){ case 0 : lpatq_link=parts[0]; reff_status_link=parts[1];
				tpatwaitq_link=parts[2]; tpatq_link=parts[3]; edtProfile_link=parts[4]; logout_link=parts[5]; break;
				case 1 : pat_reg=parts[1]; lpatq_link=parts[3]; tpatq_link=parts[5]; admjobs_link=parts[7];
				reff_status_link=parts[4]; edtProfile_link=parts[8]; logout_link=parts[9]; break; case 2 :
				lpatq_link=parts[2]; edtProfile_link=parts[3]; logout_link=parts[4]; break; case 3 :
				edtProfile_link=parts[3]; logout_link=parts[4]; break; case 4 : edtProfile_link=parts[2];
				logout_link=parts[3]; break; default : lpatq_link="" ; tpatq_link="" ; tpatwaitq_link="" ;
				reff_status_link="" ; } //out.println("<script>console.log("+lpatq_link+")</script>");
				//String part4=part3.insertAll("data-target=\"#navbarCollapse\" data-toggle=\"collapse\"");



				String menul=LayoutMenu.getMainMenu(usertype,tmpid,"left","new_sk","1"); // authorization point
				//out.println("<div>"+menul+"</div>");
				%>

				<head>
					<meta charset="utf-8">
					<meta name="viewport" content="width=device-width, initial-scale=1">
					<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/bootstrap.min.css">
					<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/toastr.css">
					<!--<link rel="stylesheet" href="../bootstrap/jquery.dataTables.min.css">-->
					<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.css">
					<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/index.css?v=3.0">

					<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/jquery-ui.min.css">
					<link rel="stylesheet" href="<%=request.getContextPath()%>/vc/vc.css?" +n>


					<script src="<%=request.getContextPath()%>/bootstrap/jquery-2.2.1.min.js"></script>
					<script src="<%=request.getContextPath()%>/bootstrap/toastr.js"></script>
					<script src="<%=request.getContextPath()%>/bootstrap/js/bootstrap.min.js"></script>
					<script src="<%=request.getContextPath()%>/bootstrap/jquery.dataTables.min.js"></script>
					<script src="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.js"></script>
					<script src="<%=request.getContextPath()%>/bootstrap/jquery-ui.min.js?" +n></script>
					<!-- <script src="https://meet.jit.si/external_api.js"></script> -->
					<script src="https://technocratzdemo.com/external_api.js"></script>
					<script src="<%=request.getContextPath()%>/bootstrap/js/skeleton-loader.js"></script>



				</head>
				<style>
					.chk-lg {
						width: 20px;
						height: 16px;
					}

					.left>div.active {
						border: 2px solid #607D8B;
						background: #eef;
						color: #333;
					}
				</style>

				<script language="javascript">
					var docid = '<%= userid %>';
					var docname = '<%= username %>';
					$.ajaxSetup({
						cache: false
					});
					function clearPanel(fileName) {
						$(".left div.getId").removeClass("active");
						$(".pat-prof-sum").remove();
						var patque = fileName.match("browse.jsp");
						var oldpat = fileName.match("oldpat.jsp");
						if (patque == "browse.jsp" || oldpat == "oldpat.jsp" || patque == "totalsummary.jsp") {
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

				</script>

				<script>
					function home(fileName) {
						var obj = { "adm": "dashb.jsp", "doc": ".vis_pat", "user": ".pat_reg ", "pOP": "getPendingPatientPatho.jsp", "rOP": "getStudyUID.jsp" };
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
						if (fileName == "pOP" || fileName == "rOP")
							clearPanel(loadUrl);
						else {
							$(loadUrl).click();
						}
						//document.getElementById("main_frame").innerHTML= "<object class='responsive obj' type='text/html' data='welcome.jsp' style='width:100%; height:100%;'>> </object>";
					}

					$(document).ready(function () {

						/*	var i=0;
							while(i<1000){
								var counter=0;
								setTimeout(function(){
								$(".cnt span").html(counter++);
								},500);
								i++;
							}*/
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
							if ($(this).attr("class").match("pat_reg") != null)
								body = "<div class='new-reg'><a onclick=\"clearPanel('selectdoc.jsp')\" class='btn btn-block'><span>New Patient Registration</span> </a></div><div class='pat-id'><span>Old Patient Registration<p>(Enter patient id into the testbox)</p></span><div class='input-group'><input class='form-control id' name='patid' placeholder='Patient id Ex: EXTR2011170001' /><div class='input-group-btn'><button class='btn btn-primary pull-right id-submit'>GO</button></div></div></div>";
							else if ($(this).attr("class").match("vid_con") != null);
							//body = "<A class='responsive obj' target=_blank href='../vc/main.jsp' style='width:100%; height:100%;'>Goto Video Conference System</a>";
							//body = <button id="vc" name="vc" class="btn responsive obj" >
							else
								body = "<div class='pat-id'><span>Enter Patient Id : </span><div class='input-group'><input class='form-control id' name='patid' placeholder='Patient id Ex: EXTR2011170001' /><div class='input-group-btn'><button class='btn btn-primary pull-right id-submit'>GO</button></div></div></div>";
							$(".main-body").html(body);
							$("input.id").focus();
							$(".continue").attr("style", "display:block");
							$(".left div.getId").removeClass("active");
							$(this).addClass("active");
							//alert($(this).attr("trackId"));
							var trackId = $(this).attr("trackId");

							$(".tele").click(function () { $("input.id").focus(); });

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
					if(utype.equals("rOP")) utypei=3; else if(utype.equals("pOP")) utypei=4; else utypei=-1; return
					utypei; } %>


					<body class="index">
						<div class="container-fluid">
							<div class="row header">
								<div class="col-sm-3 brand-container">
									<a href="<%=request.getContextPath()%>/jspfiles/home" class="brand-link">
										<img class="header-horiz-logo"
											src="<%=request.getContextPath()%>/images/mdosthi-horizontal-logo.png"
											alt="mDosthi"
											style="height:46px; max-height:46px; width:auto; max-width:190px; object-fit:contain;" />
									</a>
								</div>

								<div class="col-sm-8 header-block">

									<% if(!(usertype.equals("pOP") || usertype.equals("rOP"))){ %>
										<div class="row">
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
													onclick='clearPanel("<%=reff_status_link.split(",")[0]%>")'><span
														class="title">
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
														<% } if(usertype.equals("adm")){%>
															<div class="col-sm-3 reff-sts rect"
																onclick='clearPanel("<%=admjobs_link.split(",")[0]%>")'>
																<span class="title">
																	<%=admjobs_link.split(",")[1]%>
																</span>
																<div class="cnt"><span></span></div>
															</div>
															<% } %>
										</div>
										<%} if(usertype.equals("rOP")) {%>
											<div class="col-sm-3 pendTest rect"
												onclick='clearPanel("<%=parts[0].split(",")[0]%>")'><span class="title">
													<%=parts[0].split(",")[1]%>
												</span>
												<div class="cnt"><span><!--<%=total_lpat%>--></span></div>
											</div>
											<div class="col-sm-3 actvTest rect"
												onclick='clearPanel("<%=parts[1].split(",")[0]%>")'><span class="title">
													<%=parts[1].split(",")[1]%>
												</span>
												<div class="cnt"><span><!--<%=total_lpat%>--></span></div>
											</div>
											<div class="col-sm-3 actvTest rect"
												onclick='clearPanel("<%=parts[2].split(",")[0]%>")'><span class="title">
													<%=parts[2].split(",")[1]%>
												</span>
												<div class="cnt"><span><!--<%=total_lpat%>--></span></div>
											</div>

											<%} else if(usertype.equals("pOP")) {%>
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

												<% } %>

								</div>

								<div class="col-sm-1 account">
									<div class="profile" onclick='clearPanel("<%=edtProfile_link.split(",")[0]%>")'>
										<span class="glyphicon glyphicon-user glph-lg"
											title='<%=edtProfile_link.split(",")[1]%>'></span>
									</div>
									<div class="logout" onclick='clearPanel("<%=logout_link.split(",")[0]%>")'><span
											class="glyphicon glyphicon-off glph-lg"
											title='<%=logout_link.split(",")[1]%>'></span></div>
								</div>

							</div>

							<div class="row body">
								<div class="col-sm-12 username-title">Welcome, <%=username%>
								</div>
								<!-- jq dialog Mithuns Update-->
								<div style="display:none" id="dialog" title="iMediX-Video Conferencing">
									<div class="row-fluid">
										<div class="col-md-12">
											<div id="inner-container2">
												<div id="meet" style="background-color: grey"></div>
											</div>
											<div class="" style='text-align:center; margin: auto'>

											</div>
										</div>
									</div>
								</div>
								<!-- jq dialog end -->


								<div class="col-sm-9 right">
									<div class="row pat-head-title">

									</div>

									<div class="row">
										<div class="col-sm-12 main-body" id="main_frame">
										</div>

									</div>

								</div>
							</div>


						</div>

						<!-- WhatsApp Logs Modal -->
						<div class="modal fade" id="whatsappLogsModal" tabindex="-1" role="dialog" aria-hidden="true"
							style="z-index: 1050;">
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
									<div class="modal-body" style="padding: 24px; max-height: 400px; overflow-y: auto;">
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

						<!-- Bulk WhatsApp Modal -->
						<div class="modal fade" id="bulkWhatsAppModal" tabindex="-1" role="dialog" aria-hidden="true"
							style="z-index: 1050;">
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
											<span class="glyphicon glyphicon-bullhorn" style="color: #25d366;"></span>
											Bulk WhatsApp Broadcast
										</h4>
									</div>
									<div class="modal-body" style="padding: 24px;">
										<h5 style="font-weight: 600; color: var(--text-main); margin-bottom: 12px;">
											Selected Patients (<span id="waBulkCount">0</span>)</h5>
										<div id="waSelectedPatientsList"
											style="padding: 12px; background: rgba(241, 245, 249, 0.6); border-radius: 12px; border: 1px solid rgba(226, 232, 240, 0.8); max-height: 100px; overflow-y: auto; margin-bottom: 16px; font-size: 13px; color: var(--text-muted); display: flex; flex-wrap: wrap; gap: 6px;">
											<!-- Names tags -->
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
														style="margin: 0; width: 18px; height: 18px;"> English Template
													(Standard)
												</label>
												<label
													style="font-weight: 500; cursor: pointer; display: flex; align-items: center; gap: 8px;">
													<input type="radio" name="waBulkMsgType" id="waBulkTypeBengali"
														value="bengali" style="margin: 0; width: 18px; height: 18px;">
													Bengali Template (rem_bn)
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
						$(function () {
							$("#accordion").accordion({ active: 0, collapsible: true, heightStyle: "content" });
							//$.fn.bootstrapBtn = $.fn.button.noConflict();
							//var bootstrapButton = $.fn.button.noConflict(); // return $.fn.button to previously assigned value
							//$.fn.bootstrapBtn = bootstrapButton;            // give $().bootstrapBtn the Bootstrap functionality

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

						function openBulkWhatsAppModal() {
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

							$("#bulkWhatsAppModal").modal("show");

							$("#waSendBulkBtn").off("click").on("click", function () {
								var msgType = $("input[name='waBulkMsgType']:checked").val();

								var originalHtml = $("#waSendBulkBtn").html();
								$("#waSendBulkBtn").html("<span class='glyphicon glyphicon-refresh spin-icon'></span> Sending...").prop("disabled", true);

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
											// Uncheck checkboxes
											$("input[name='ch']").prop("checked", false);
										} else {
											alert("Failed to send broadcast: " + data.status);
										}
									},
									error: function (xhr) {
										alert("Error: " + xhr.statusText);
									},
									complete: function () {
										$("#waSendBulkBtn").html(originalHtml).prop("disabled", false);
									}
								});
							});
						}
					</script>

	</html>