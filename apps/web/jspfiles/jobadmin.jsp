<%@page language="java"
	import="imedix.rcUserInfo,imedix.rcDataEntryFrm,imedix.rcAdminJobs,imedix.rcCentreInfo,imedix.dataobj,imedix.cook,java.util.*"
	%>
	<%@ include file="..//includes/chkcook.jsp" %>
		<HTML>

		<HEAD>
			<TITLE> New Document </TITLE>
			<META NAME="Generator" CONTENT="EditPlus">
			<META NAME="Author" CONTENT="">
			<META NAME="Keywords" CONTENT="">
			<META NAME="Description" CONTENT="">

			<meta charset="utf-8">
			<meta name="viewport" content="width=device-width, initial-scale=1">
			<link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
			<link rel="stylesheet" href="../bootstrap/css/bootstrap.css">
			<link rel="stylesheet" href="../bootstrap/css/index.css?v=6.0">
			<script src="../bootstrap/jquery-2.2.1.min.js"></script>
			<script src="../bootstrap/js/bootstrap.min.js"></script>
			<script src="../bootstrap/js/bootstrap.js"></script>

			<style>
				body {
					background: transparent !important; /* Allow parent background gradient to flow through */
					font-family: 'Outfit', sans-serif !important;
				}

				.panel {
					border: 1px solid rgba(226, 232, 240, 0.8) !important;
					border-radius: 20px !important;
					background: rgba(255, 255, 255, 0.65) !important;
					backdrop-filter: blur(16px);
					box-shadow: 0 12px 35px rgba(31, 38, 135, 0.04) !important;
					overflow: hidden !important;
					margin-bottom: 30px !important;
					border-top: 4px solid var(--primary) !important; /* Top colored bar matching main theme */
				}

				.panel-heading.sk {
					background: linear-gradient(135deg, rgba(255, 255, 255, 0.9), rgba(255, 255, 255, 0.95)) !important;
					color: var(--primary) !important;
					border-bottom: 1px solid rgba(226, 232, 240, 0.8) !important;
					padding: 18px 24px !important;
				}

				.panel-heading.sk h4 {
					margin: 0 !important;
					font-weight: 700 !important;
					letter-spacing: -0.3px;
				}

				.list-group {
					padding: 16px 20px !important;
					margin: 0 !important;
					display: flex;
					flex-direction: column;
					gap: 8px; /* Adds premium separation between list items */
				}

				a.list-group-item {
					background: rgba(255, 255, 255, 0.75) !important;
					color: var(--text-main) !important;
					font-weight: 600 !important;
					border: 1px solid rgba(226, 232, 240, 0.7) !important;
					border-left: 5px solid rgba(79, 70, 229, 0.3) !important; /* Left accent line */
					border-radius: 12px !important;
					padding: 14px 20px !important;
					transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.1) !important;
					box-shadow: 0 2px 8px rgba(31, 38, 135, 0.01) !important;
					display: flex;
					justify-content: space-between;
					align-items: center;
				}

				/* Colorized border categories */
				a.list-group-item[href*="Stats"], a.list-group-item[href*="patientProgress"], a.list-group-item[href*="Prescriptions"] {
					border-left-color: rgba(168, 85, 247, 0.4) !important; /* Purple for Stats & Progress */
				}
				a.list-group-item[href*="Stats"]:hover, a.list-group-item[href*="patientProgress"]:hover, a.list-group-item[href*="Prescriptions"]:hover {
					border-left-color: #a855f7 !important;
					background: linear-gradient(90deg, rgba(168, 85, 247, 0.05), rgba(255, 255, 255, 0.95)) !important;
				}

				a.list-group-item[href*="center"], a.list-group-item[href*="departments"] {
					border-left-color: rgba(59, 130, 246, 0.4) !important; /* Blue for Center & Depts */
				}
				a.list-group-item[href*="center"]:hover, a.list-group-item[href*="departments"]:hover {
					border-left-color: #138A4E !important;
					background: linear-gradient(90deg, rgba(59, 130, 246, 0.05), rgba(255, 255, 255, 0.95)) !important;
				}

				a.list-group-item[href*="regque"], a.list-group-item[href*="users"], a.list-group-item[href*="Active"], a.list-group-item[href*="CreateLogin"], a.list-group-item[href*="rctControl"], a.list-group-item[href*="druglist"], a.list-group-item[href*="consentControl"] {
					border-left-color: rgba(13, 148, 136, 0.4) !important; /* Teal for Users & Configs */
				}
				a.list-group-item[href*="regque"]:hover, a.list-group-item[href*="users"]:hover, a.list-group-item[href*="Active"]:hover, a.list-group-item[href*="CreateLogin"]:hover, a.list-group-item[href*="rctControl"]:hover, a.list-group-item[href*="druglist"]:hover, a.list-group-item[href*="consentControl"]:hover {
					border-left-color: #0d9488 !important;
					background: linear-gradient(90deg, rgba(13, 148, 136, 0.05), rgba(255, 255, 255, 0.95)) !important;
				}

				a.list-group-item[href*="whatsapp"], a.list-group-item[href*="clean"], a.list-group-item[href*="log"] {
					border-left-color: rgba(239, 68, 68, 0.4) !important; /* Coral Red for Logs & Cleanup */
				}
				a.list-group-item[href*="whatsapp"]:hover, a.list-group-item[href*="clean"]:hover, a.list-group-item[href*="log"]:hover {
					border-left-color: #ef4444 !important;
					background: linear-gradient(90deg, rgba(239, 68, 68, 0.05), rgba(255, 255, 255, 0.95)) !important;
				}

				a.list-group-item[href*="backup"], a.list-group-item[href*="restore"], a.list-group-item[href*="Backup"] {
					border-left-color: rgba(245, 158, 11, 0.4) !important; /* Amber for Backup & Recovery */
				}
				a.list-group-item[href*="backup"]:hover, a.list-group-item[href*="restore"]:hover, a.list-group-item[href*="Backup"]:hover {
					border-left-color: #f59e0b !important;
					background: linear-gradient(90deg, rgba(245, 158, 11, 0.05), rgba(255, 255, 255, 0.95)) !important;
				}

				a.list-group-item:hover {
					transform: translateY(-2px) scale(1.005);
					box-shadow: 0 8px 20px rgba(31, 38, 135, 0.06) !important;
					text-decoration: none !important;
				}

				a.list-group-item .badge {
					background: rgba(79, 70, 229, 0.08) !important;
					color: var(--primary) !important;
					border: 1px solid rgba(79, 70, 229, 0.15) !important;
					font-weight: 700 !important;
					border-radius: 20px !important;
					padding: 6px 12px !important;
					transition: all 0.3s ease !important;
				}

				a.list-group-item[href*="Stats"]:hover .badge, a.list-group-item[href*="patientProgress"]:hover .badge, a.list-group-item[href*="Prescriptions"]:hover .badge {
					background: #a855f7 !important;
					color: #fff !important;
					border-color: #a855f7 !important;
				}
				a.list-group-item[href*="center"]:hover .badge, a.list-group-item[href*="departments"]:hover .badge {
					background: #138A4E !important;
					color: #fff !important;
					border-color: #138A4E !important;
				}
				a.list-group-item[href*="regque"]:hover .badge, a.list-group-item[href*="users"]:hover .badge, a.list-group-item[href*="Active"]:hover .badge, a.list-group-item[href*="CreateLogin"]:hover .badge, a.list-group-item[href*="rctControl"]:hover .badge, a.list-group-item[href*="druglist"]:hover .badge, a.list-group-item[href*="consentControl"]:hover .badge {
					background: #0d9488 !important;
					color: #fff !important;
					border-color: #0d9488 !important;
				}
				a.list-group-item[href*="whatsapp"]:hover .badge, a.list-group-item[href*="clean"]:hover .badge, a.list-group-item[href*="log"]:hover .badge {
					background: #ef4444 !important;
					color: #fff !important;
					border-color: #ef4444 !important;
				}
				a.list-group-item[href*="backup"]:hover .badge, a.list-group-item[href*="restore"]:hover .badge, a.list-group-item[href*="Backup"]:hover .badge {
					background: #f59e0b !important;
					color: #fff !important;
					border-color: #f59e0b !important;
				}

				#saveConfigBtn {
					background: linear-gradient(135deg, #ff6666, #e55555) !important;
					border: none !important;
					color: #fff !important;
					border-radius: 12px !important;
					padding: 10px 24px !important;
					font-weight: 600 !important;
					transition: all 0.3s ease !important;
					box-shadow: 0 4px 12px rgba(255, 102, 102, 0.2) !important;
				}

				#saveConfigBtn:hover {
					transform: translateY(-2px);
					box-shadow: 0 8px 20px rgba(255, 102, 102, 0.3) !important;
				}

				.margin-zero {
					margin: 0 !important;
				}

				.statistics-module .panel {
					border: 1px solid rgba(226, 232, 240, 0.8) !important;
					border-radius: 14px !important;
					background: rgba(255, 255, 255, 0.5) !important;
					margin: 8px 0 !important;
					box-shadow: none !important;
					border-top: 1px solid rgba(226, 232, 240, 0.8) !important;
				}

				.statistics-module .panel-heading {
					background: transparent !important;
					padding: 14px 18px !important;
					border-bottom: none !important;
				}

				.statistics-module .panel-title a {
					color: var(--text-main) !important;
					font-weight: 600 !important;
					text-decoration: none !important;
				}

				.statistics-module .panel-title a:hover {
					color: var(--primary) !important;
				}

				.statistics-module .glyphicon {
					float: right;
					position: absolute;
					right: 20px;
					top: 15px;
				}

				.statistics-module .panel-title {
					position: relative
				}

				.statistics-module .panel-title>a {
					display: block;
				}

				.statistics-module .panel-title>a.collapsed>.glyphicon-chevron-up {
					display: none;
				}

				.statistics-module .panel-title>a.collapsed>.glyphicon-chevron-down {
					display: block;
				}

				.statistics-module .panel-title>a>.glyphicon-chevron-up {
					display: block;
				}

				.statistics-module .panel-title>a>.glyphicon-chevron-down {
					display: none;
				}
			</style>

		</HEAD>

		<% int cen_no=0,regque_no=0,usr_no=0; cook cookx=new cook(); String ccode=cookx.getCookieValue("center",
			request.getCookies ()); rcDataEntryFrm rcdef=new rcDataEntryFrm(request.getRealPath("/")); rcCentreInfo
			cinfo=new rcCentreInfo(request.getRealPath("/")); rcAdminJobs rcAjob=new
			rcAdminJobs(request.getRealPath("/")); rcUserInfo uinfo=new rcUserInfo(request.getRealPath("/")); try {
			Object res=cinfo.getAllCentreInfo(); if(res instanceof String){ cen_no=0; } else{ Vector Vtmp=(Vector)res;
			cen_no=Vtmp.size(); } } catch(Exception e){out.println(e.toString());} try { Object
			res=rcAjob.viewRegUsers(); if(res instanceof String){ regque_no=0; } else{ Vector Vtmp=(Vector)res;
			regque_no=Vtmp.size(); } } catch(Exception e){out.println(e.toString());} try { String cond="active='Y' " ;
			Object
			res=uinfo.getValues("name,uid,designation,emailid,phone,dis,rg_no,type,active,center,available,referral",cond);
			if(res instanceof String){ usr_no=0; } else{ Vector Vtmp=(Vector)res; usr_no=Vtmp.size(); } }
			catch(Exception e){out.println(e.toString());} int tag=0,restr_no=0; String
			resdir=rcAjob.getDeletedBackupDirs(); String[] subdir=resdir.split("#"); if (resdir.equalsIgnoreCase("None")
			|| resdir.length()==0){restr_no=0;} else {restr_no=subdir.length;} %>

			<BODY>
				<div class="container">
					<div class="row">
						<div class="col-sm-2">
						</div> <!-- "col-sm-3" -->
						<div class="col-sm-8">

							<div class="panel panel-info">


								<div class="panel-heading sk">
									<h4><strong>Administrator Responsibilities :</strong></h4>





								</div>
								<div class="list-group">
									<a href="iMediXcareStats.jsp" target="_blank" class="list-group-item">iMediXcare
										Statistics</a>
									<% if(ccode.equals("XXXX")){ %>
										<a href="showcenter.jsp" class="list-group-item">Center Management<span
												class="badge">
												<%=cen_no%>
											</span>
										</a>
										<% }else{ %>
											<a href="editcenter2.jsp" class="list-group-item">Connected Centers<span
													class="badge">
													<%=cen_no%>
												</span>
											</a>
											<% } %>

												<a href="showregque.jsp" class="list-group-item">Registration Queue<span
														class="badge">
														<%=regque_no%>
													</span></a>
												<a href="showusers.jsp" class="list-group-item">Show Users<span
														class="badge">
														<%=usr_no%>
													</span></a>
												<a href="whatsapp_logs_admin.jsp" class="list-group-item">WhatsApp
													Message Logs</a>
												<a href="patientProgressApp.jsp" class="list-group-item">Patient
													Progress App</a>
												<a href="Lpatq_clean.jsp" class="list-group-item">Clean Local Patient
													Queue</a>
												<a href="accountActive.jsp" class="list-group-item">Activate/Deactivate
													Users</a>
												<a href="patCreateLogin.jsp" class="list-group-item">Create Patient
													Login<span class="badge">0</span></a>
												<a href="druglist_manage.jsp" class="list-group-item">Manage Drug
													List</a>
												<a href="departments.jsp" class="list-group-item">Manage Departments</a>
												<a href="viewPrescriptions.jsp" class="list-group-item">View
													Prescriptions</a>
												<a href="rctControl.jsp" class="list-group-item">RCT Control</a>
												<a href="consentControl.jsp" class="list-group-item">Consent Control</a>

												<a href="backupinterface.jsp" class="list-group-item">Backup Utility</a>
												<a href="restoreinterface.jsp" class="list-group-item">Restore
													Utility<span class="badge">
														<%=restr_no%>
													</span></a>
												<!--<a href="backupinterface.jsp" class="list-group-item">Backup Utility</a>
			<a href="restoreinterface.jsp" class="list-group-item">Restore Utility<span class="badge"><%=restr_no%></span></a>
			<a href="../imedix-stat/showstat.jsp" class="list-group-item">iMediX Statistics</a>-->
												<!--<a href="../imedix-stat-adv/yearrange.jsp" class="list-group-item">iMediX Advanced Statistics</a>-->
												<!--<a href="admcommunication.jsp" class="list-group-item">Email/SMS to Users</a>-->


												<div class="panel-group margin-zero statistics-module">
													<div class="panel panel-default">
														<div class="panel-heading">
															<h4 class="panel-title">
																<a data-toggle="collapse" href="#collapse1"
																	class="collapsed">Reports<span
																		class="glyphicon glyphicon-chevron-down"></span><span
																		class="glyphicon glyphicon-chevron-up"></span></a>


															</h4>

														</div>
														<div id="collapse1" class="panel-collapse collapse">
															<div class="panel-body">
																<ul class="list-group margin-zero">
																	<li class="list-group-item">
																		<% if(ccode.equals("XXXX")){%>
																			<a href="rkmsstatisticsadm.jsp"
																				class="list-group-item">Patient</a>
																			<%}else{%>
																				<a href="rkmsstatistics.jsp"
																					class="list-group-item">Patient</a>
																				<%}%>
																	</li>
																	<li class="list-group-item"><a
																			href="diagnosis_stats.jsp"
																			class="list-group-item">Diagnosis</a></li>
																	<li class="list-group-item"><a
																			href="detailed_diagnosis_stats.jsp"
																			class="list-group-item">Detailed
																			Diagnosis</a></li>
																	<li class="list-group-item"><a
																			href="pat_diagnosis_stats.jsp"
																			class="list-group-item">Unique Patient
																			Report</a></li>
																	<li class="list-group-item"><a
																			href="pat_detailed_diagnosis_stats.jsp"
																			class="list-group-item">Unique Patient
																			Detailed Diagnosis Report</a></li>
																	<li class="list-group-item"><a
																			href="quarter_stats.jsp"
																			class="list-group-item">Querterly Report</a>
																	</li>
																	<li class="list-group-item"><a
																			href="unique_quarter_stats.jsp"
																			class="list-group-item">Unique Patient
																			Querterly Report</a></li>
																</ul>
															</div>
														</div>
													</div>
												</div>


												<!--<a href="pacsResultlist.jsp" class="list-group-item">Get PACS Result</a>-->
												<% if(ccode.equals("XXXX")){ %>
													<a href="viewlog.jsp" class="list-group-item">View Log</a>
													<% } %>
														<a href="downloadBackup.jsp" class="list-group-item">Download
															Backup<span class="badge"></span></a>
								</div>
							</div>

							<!-- WhatsApp Alert Settings Card -->
							<div class="panel panel-info" style="margin-top: 20px;">
								<div class="panel-heading sk">
									<h4><strong>WhatsApp Alert Settings for Suicide Ideation</strong></h4>
								</div>
								<div class="panel-body">
									<div class="form-group" style="margin-bottom: 15px;">
										<label for="newRecipientInput"
											style="font-weight: bold; color: #555; font-size: 13px; margin-bottom: 8px; display: block;">Add Alert Recipient Phone (with country code, e.g. 91xxxxxxxxxx):</label>
										<div class="input-group">
											<span class="input-group-addon"><span
													class="glyphicon glyphicon-phone"></span></span>
											<input type="text" id="newRecipientInput" class="form-control"
												placeholder="Enter number..."
												style="font-weight: 600;">
											<span class="input-group-btn">
												<button type="button" id="addRecipientBtn" class="btn btn-success" style="border-radius: 0 6px 6px 0; font-weight: bold;">
													<span class="glyphicon glyphicon-plus"></span> Add
												</button>
											</span>
										</div>
									</div>

									<div class="form-group" style="margin-bottom: 20px;">
										<label style="font-weight: bold; color: #555; font-size: 13px; margin-bottom: 8px; display: block;">Configured Alert Recipients:</label>
										<div id="recipientListContainer" class="list-group" style="margin-bottom: 0; max-height: 200px; overflow-y: auto; border: 1px solid #e2e8f0; border-radius: 6px; padding: 8px; background-color: #f8fafc;">
											<!-- Dynamically populated -->
										</div>
									</div>

									<button type="button" id="saveConfigBtn" class="btn btn-primary" style="width: 100%; border-radius: 6px; font-weight: bold; padding: 10px 0;">
										<span class="glyphicon glyphicon-save"></span> Save Recipients Configuration
									</button>
									<div id="configStatusMsg"
										style="margin-top: 15px; font-weight: 600; font-size: 13px; display: none;">
									</div>
								</div>
							</div>

						</div> <!-- "col-sm-6" -->
						<div class="col-sm-2">
						</div> <!-- "col-sm-3" -->

					</div> <!-- "row" -->
				</div> <!-- "container" -->

				<script>
					var apiBase = window.location.protocol + "//" + window.location.hostname + ":9090";
					var recipientsList = [];

					$(document).ready(function () {
						loadAlertConfig();

						$("#saveConfigBtn").on("click", function () {
							saveAlertConfig();
						});

						$("#addRecipientBtn").on("click", function () {
							addRecipient();
						});

						$("#newRecipientInput").on("keypress", function (e) {
							if (e.which === 13) {
								e.preventDefault();
								addRecipient();
							}
						});

						$("#recipientListContainer").on("click", ".remove-recipient-btn", function () {
							var phoneToRemove = $(this).attr("data-phone");
							recipientsList = recipientsList.filter(function (p) { return p !== phoneToRemove; });
							renderRecipientsList();
						});
					});

					function renderRecipientsList() {
						var container = $("#recipientListContainer");
						container.empty();
						if (recipientsList.length === 0) {
							container.append('<div class="text-muted text-center" style="padding: 15px; font-style: italic;" id="noRecipientsMsg">No alert recipients configured.</div>');
							return;
						}
						for (var i = 0; i < recipientsList.length; i++) {
							var phone = recipientsList[i];
							var itemHtml = 
								'<div class="list-group-item" style="display: flex; justify-content: space-between; align-items: center; padding: 8px 12px; margin-bottom: 6px; border-radius: 6px; border: 1px solid #e3e8f0; background: #fff; box-shadow: 0 1px 2px rgba(0,0,0,0.05);">' +
								'    <span style="font-weight: 600; font-size: 13px; color: #1e293b;">' +
								'        <span class="glyphicon glyphicon-phone" style="margin-right: 8px; color: #138A4E;"></span>' +
								'        ' + phone +
								'    </span>' +
								'    <button type="button" class="btn btn-danger btn-xs remove-recipient-btn" data-phone="' + phone + '" style="padding: 3px 7px; border-radius: 4px; border: none; background-color: #ef4444; color: white; display: flex; align-items: center; justify-content: center;">' +
								'        <span class="glyphicon glyphicon-trash" style="font-size: 11px;"></span>' +
								'    </button>' +
								'</div>';
							container.append(itemHtml);
						}
					}

					function addRecipient() {
						var input = $("#newRecipientInput");
						var phone = input.val().trim();
						var statusMsg = $("#configStatusMsg");

						// Clean up number
						phone = phone.replace(/[^0-9]/g, "");

						if (!phone || phone.length < 10) {
							statusMsg.html("<span class='text-danger'>Please enter a valid phone number (minimum 10 digits).</span>").show();
							setTimeout(function () { statusMsg.fadeOut(); }, 4000);
							return;
						}

						if (recipientsList.indexOf(phone) !== -1) {
							statusMsg.html("<span class='text-danger'>This phone number is already in the list.</span>").show();
							setTimeout(function () { statusMsg.fadeOut(); }, 4000);
							return;
						}

						recipientsList.push(phone);
						renderRecipientsList();
						input.val("");
						statusMsg.hide();
					}

					function loadAlertConfig() {
						var container = $("#recipientListContainer");
						container.html('<div class="text-muted text-center" style="padding: 15px;">Loading alert recipients...</div>');
						$.ajax({
							type: "GET",
							url: apiBase + "/api/whatsapp/config",
							data: { key: "imedix.whatsapp.alert.recipient" },
							success: function (response) {
								recipientsList = [];
								if (response && response.value) {
									var parts = response.value.split(",");
									for (var i = 0; i < parts.length; i++) {
										var num = parts[i].trim();
										if (num) {
											recipientsList.push(num);
										}
									}
								}
								renderRecipientsList();
							},
							error: function () {
								container.html('<div class="text-danger text-center" style="padding: 15px;">Error loading recipients.</div>');
							}
						});
					}

					function saveAlertConfig() {
						var statusMsg = $("#configStatusMsg");

						if (recipientsList.length === 0) {
							statusMsg.html("<span class='text-warning'>Please add at least one recipient number.</span>").show();
							return;
						}

						var valueStr = recipientsList.join(",");

						$.ajax({
							type: "POST",
							url: apiBase + "/api/whatsapp/config",
							data: {
								key: "imedix.whatsapp.alert.recipient",
								value: valueStr
							},
							success: function (response) {
								if (response.status === "SUCCESS") {
									statusMsg.html("<span class='text-success'><strong>Success:</strong> Alert recipients saved successfully!</span>").show();
									setTimeout(function () { statusMsg.fadeOut(); }, 4000);
								} else {
									statusMsg.html("<span class='text-danger'>Error: " + response.status + "</span>").show();
								}
							},
							error: function (xhr) {
								statusMsg.html("<span class='text-danger'>Failed to save recipients: " + xhr.statusText + "</span>").show();
							}
						});
					}
				</script>
			</BODY>

		</HTML>
