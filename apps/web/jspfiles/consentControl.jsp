<%@page language="java" import="imedix.rcUserInfo,imedix.rcCentreInfo,imedix.dataobj,imedix.cook,java.util.*,java.io.*"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%
    cook cookx = new cook();
    String utyp = cookx.getCookieValue("usertype", request.getCookies());
    String usr = cookx.getCookieValue("userid", request.getCookies());

    rcUserInfo uinfo = new rcUserInfo(request.getRealPath("/"));

    String ccode = cookx.getCookieValue("center", request.getCookies());
    String cname = cookx.getCookieValue("centername", request.getCookies());

    String sccode = request.getParameter("sccode");

    if (sccode == null) sccode = ccode;
    if (sccode.equals("")) sccode = ccode;

    // Filter condition for retrieving ONLY patients
    String cond = "type='PAT'";
    if (sccode.equals("XXXX")) {
        cond += " and center <> 'XXXX' order by center, name";
    } else {
        cond += " and center = '" + sccode + "' order by name";
    }
%>

<HTML>
<HEAD>
    <TITLE>Concent Control (DPDP)</TITLE>
    <meta charset="utf-8">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
    <link rel="stylesheet" href="../bootstrap/css/bootstrap.css">
    <link rel="stylesheet" href="../bootstrap/css/index.css?v=2.0">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
    <script src="../bootstrap/jquery-2.2.1.min.js"></script>
    <script src="../bootstrap/js/bootstrap.min.js"></script>
    <script src="<%=request.getContextPath()%>/bootstrap/jquery.dataTables.min.js"></script>
    <script src="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.js"></script>

    <style>
        body {
            background: transparent !important; /* Allow parent background gradient to flow through */
            font-family: 'Outfit', sans-serif !important;
        }

        .panel {
            border: 1px solid rgba(226, 232, 240, 0.8) !important;
            border-radius: 20px !important;
            background: rgba(255, 255, 255, 0.75) !important;
            backdrop-filter: blur(16px);
            box-shadow: 0 12px 35px rgba(31, 38, 135, 0.04) !important;
            overflow: hidden !important;
            margin-bottom: 30px !important;
            border-top: 4px solid var(--accent-teal) !important; /* Teal top bar matching list group theme */
        }

        .panel-heading.sk {
            background: linear-gradient(135deg, rgba(255, 255, 255, 0.9), rgba(255, 255, 255, 0.95)) !important;
            color: var(--accent-teal) !important;
            border-bottom: 1px solid rgba(226, 232, 240, 0.8) !important;
            padding: 18px 24px !important;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .panel-heading.sk h4 {
            margin: 0 !important;
            font-weight: 700 !important;
            letter-spacing: -0.3px;
        }

        .table-responsive {
            padding: 24px !important;
        }

        .table {
            margin-bottom: 0 !important;
        }

        .table>thead>tr>th {
            border-bottom: 2px solid rgba(226, 232, 240, 0.8) !important;
            color: var(--text-muted) !important;
            font-weight: 600 !important;
            text-transform: uppercase;
            font-size: 11px;
            letter-spacing: 0.5px;
            background: #f8fafc !important;
            padding: 14px 16px !important;
        }

        .table>tbody>tr>td {
            padding: 14px 16px !important;
            vertical-align: middle !important;
            border-top: 1px solid rgba(226, 232, 240, 0.5) !important;
        }

        .back-btn {
            background: #ef4444 !important;
            color: white !important;
            border-radius: 8px !important;
            padding: 8px 16px !important;
            font-weight: 600 !important;
            border: none !important;
            text-decoration: none !important;
            transition: all 0.2s ease !important;
            box-shadow: 0 4px 12px rgba(239, 68, 68, 0.15) !important;
        }

        .back-btn:hover {
            background: #dc2626 !important;
            color: white !important;
            text-decoration: none !important;
            transform: translateY(-1px);
        }

        /* Toggle Switch Styling */
        .switch {
            position: relative;
            display: inline-block;
            width: 48px;
            height: 24px;
            margin: 0;
            vertical-align: middle;
        }

        .switch input {
            opacity: 0;
            width: 0;
            height: 0;
        }

        .slider {
            position: absolute;
            cursor: pointer;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: #cbd5e1;
            transition: .3s;
            border-radius: 24px;
        }

        .slider:before {
            position: absolute;
            content: "";
            height: 18px;
            width: 18px;
            left: 3px;
            bottom: 3px;
            background-color: white;
            transition: .3s;
            border-radius: 50%;
            box-shadow: 0 1px 3px rgba(0,0,0,0.15);
        }

        input:checked + .slider {
            background-color: #0d9488; /* Teal */
        }

        input:checked + .slider:before {
            transform: translateX(24px);
        }

        input:disabled + .slider {
            opacity: 0.6;
            cursor: not-allowed;
        }

        /* Badges */
        .status-badge {
            display: inline-flex;
            align-items: center;
            padding: 4px 10px;
            border-radius: 50px;
            font-size: 11px;
            font-weight: 600;
        }

        .status-badge.agreed {
            background-color: rgba(13, 148, 136, 0.1);
            color: #0d9488;
        }

        .status-badge.not-agreed {
            background-color: rgba(239, 68, 68, 0.1);
            color: #ef4444;
        }

        .status-cell {
            display: flex;
            align-items: center;
            gap: 12px;
        }
    </style>

    <SCRIPT LANGUAGE="JavaScript">
        $(document).ready(function(){
            $('#consentTable').DataTable({
                "pageLength": 25,
                "order": [[ 1, "asc" ]]
            });
        });

        function showselected(val){
            var tar;
            tar = "consentControl.jsp?sccode=" + val;
            window.location = tar;
        }

        function toggleConsentStatus(uid) {
            var chk = document.getElementById(uid);
            var status = $(chk).prop('checked');
            var cmd = status ? "activate" : "deactivate";
            var statusBadge = $("#status-badge-" + uid);
            var statusText = $("#status-text-" + uid);

            var param = {cmd: cmd, uid: uid};

            // Disable switch during update to avoid double clicks
            $(chk).prop('disabled', true);

            $.ajax({
                type: 'POST',
                url: "consent_manage.jsp",
                data: param,
                dataType: "json",
                success: function(res) {
                    $(chk).prop('disabled', false);
                    if(res.status === "success") {
                        if(status) {
                            statusText.text("Agreed");
                            statusBadge.removeClass("not-agreed").addClass("agreed");
                        } else {
                            statusText.text("Not Agreed");
                            statusBadge.removeClass("agreed").addClass("not-agreed");
                        }
                    } else {
                        // Revert checkbox state
                        $(chk).prop('checked', !status);
                        alert("Error: " + res.message);
                    }
                },
                error: function(xhr, status, error) {
                    $(chk).prop('disabled', false);
                    $(chk).prop('checked', !status);
                    alert("AJAX Error: Failed to update consent status.");
                }
            });
        }
    </SCRIPT>
</HEAD>

<BODY>
    <div class="container-fluid" style="padding: 30px;">
        <div class="row">
            <div class="col-sm-12">
                <div class="panel">
                    <div class="panel-heading sk">
                        <h4><strong>CONSENT CONTROL (DPDP PATIENT AGREEMENT)</strong></h4>
                        <a class="back-btn" href="jobadmin.jsp"><span class="glyphicon glyphicon-arrow-left"></span> BACK</a>
                    </div>
                    
                    <div class="table-responsive">
                        <!-- Center Selector -->
                        <div class="row" style="margin-bottom: 24px;">
                            <div class="col-sm-4">
                                <div class="input-group">
                                    <span class="input-group-addon" style="color:var(--accent-teal); font-weight:bold">Select Center :</span>
                                    <select class="form-control" name="center" onchange='showselected(this.value);' style="font-weight: 600;">
                                    <%
                                        out.println("<option value=\"" + ccode + "\" selected>" + cname + "</option>");
                                        try {
                                            if(ccode.equals("XXXX")){
                                                rcCentreInfo rcci = new rcCentreInfo(request.getRealPath("/"));
                                                Object res = rcci.getAllCentreInfo();
                                                if(res instanceof String) {
                                                    out.println("<option value='NIL'>No match Found</option>");
                                                } else {
                                                    Vector Vtmp = (Vector)res;
                                                    for(int j=0; j<Vtmp.size(); j++){
                                                        dataobj datatemp = (dataobj) Vtmp.get(j);
                                                        String code = datatemp.getValue("code");
                                                        String name = datatemp.getValue("name");
                                                        if(code.equals(sccode) && !code.equals(ccode)){
                                                            out.println("<option value=\"" + code + "\" selected>" + name + "</option>");
                                                        } else if(!code.equals(ccode)) {
                                                            out.println("<option value=\"" + code + "\">" + name + "</option>");
                                                        }
                                                    }
                                                }
                                            }
                                        } catch(Exception e) {
                                            out.println("<!-- Error: " + e.getMessage() + " -->");
                                        }
                                    %>
                                    </select>
                                </div>
                            </div>
                        </div>

                        <!-- Patients Table -->
                        <table class="table table-hover table-striped" id="consentTable">
                            <thead>
                                <TR>
                                    <TH style="width: 200px;">Consent Action</TH>
                                    <TH>Patient Name (UID)</TH>
                                    <TH>Email ID</TH>
                                    <TH>Phone Number</TH>
                                    <TH>Center</TH>
                                    <TH>Status</TH>
                                </TR>
                            </thead>
                            <tbody>
                            <%
                                try {
                                    Object res = uinfo.getValues("name,uid,emailid,phone,center,dpdp_agreed", cond);
                                    if (res instanceof String) {
                                        // No matches found
                                    } else {
                                        Vector tmp = (Vector)res;
                                        for(int ii=0; ii<tmp.size(); ii++){
                                            dataobj temp = (dataobj) tmp.get(ii);
                                            String patName = temp.getValue("name");
                                            String patUid = temp.getValue("uid");
                                            String email = temp.getValue("emailid");
                                            String phone = temp.getValue("phone");
                                            String centerVal = temp.getValue("center");
                                            String dpdpAgreed = temp.getValue("dpdp_agreed");

                                            boolean isAgreed = "1".equals(dpdpAgreed);
                                            String checkedAttr = isAgreed ? "checked" : "";
                                            String badgeClass = isAgreed ? "agreed" : "not-agreed";
                                            String statusLabel = isAgreed ? "Agreed" : "Not Agreed";
                            %>
                                            <TR>
                                                <TD>
                                                    <div class="status-cell">
                                                        <label class="switch">
                                                            <input type="checkbox" id="<%= patUid %>" onClick="toggleConsentStatus('<%= patUid %>')" <%= checkedAttr %>>
                                                            <span class="slider round"></span>
                                                        </label>
                                                    </div>
                                                </TD>
                                                <TD><strong><%= patName %></strong> (<%= patUid %>)</TD>
                                                <TD><%= (email == null || email.trim().isEmpty()) ? "-" : email %></TD>
                                                <TD><%= (phone == null || phone.trim().isEmpty()) ? "-" : phone %></TD>
                                                <TD><%= centerVal %></TD>
                                                <TD>
                                                    <span id="status-badge-<%= patUid %>" class="status-badge <%= badgeClass %>">
                                                        <span id="status-text-<%= patUid %>"><%= statusLabel %></span>
                                                    </span>
                                                </TD>
                                            </TR>
                            <%
                                        }
                                    }
                                } catch (Exception e) {
                                    out.println("<TR><TD colspan='6' class='text-danger'>Error loading patient data: " + e.getMessage() + "</TD></TR>");
                                }
                            %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</BODY>
</HTML>
