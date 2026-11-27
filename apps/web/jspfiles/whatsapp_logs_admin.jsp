<%@page language="java" import="imedix.cook,java.util.*,java.io.*" %>
    <%@ include file="..//includes/chkcook.jsp" %>
        <% cook cookx=new cook(); String utyp=cookx.getCookieValue("usertype", request.getCookies()); String
            usr=cookx.getCookieValue("userid", request.getCookies()); String ccode=cookx.getCookieValue("center",
            request.getCookies ()); String cname=cookx.getCookieValue("centername", request.getCookies ()); %>
            <HTML>

            <HEAD>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <title>WhatsApp Message Logs - M-Dosthi Admin</title>
                <link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
                <script src="../bootstrap/jquery-2.2.1.min.js"></script>
                <script src="../bootstrap/js/bootstrap.min.js"></script>

                <style>
                    :root {
                        --primary: #25d366;
                        --primary-dark: #128c7e;
                        --bg-gradient: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
                        --card-bg: rgba(255, 255, 255, 0.95);
                        --card-shadow: 0 10px 30px rgba(0, 0, 0, 0.05);
                        --text-main: #1e293b;
                        --text-muted: #64748b;
                        --border-color: #e2e8f0;
                    }

                    body {
                        background: var(--bg-gradient);
                        font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                        color: var(--text-main);
                        min-height: 100vh;
                        padding: 30px 15px;
                    }

                    .container {
                        max-width: 1200px;
                        margin: 0 auto;
                    }

                    .header-container {
                        display: flex;
                        justify-content: space-between;
                        align-items: center;
                        margin-bottom: 25px;
                        padding-bottom: 15px;
                        border-bottom: 2px solid var(--border-color);
                    }

                    .header-title {
                        font-weight: 700;
                        font-size: 26px;
                        color: var(--text-main);
                        display: flex;
                        align-items: center;
                        gap: 10px;
                        margin: 0;
                    }

                    .btn-back {
                        background-color: #f1f5f9;
                        color: #475569;
                        border: 1px solid #cbd5e1;
                        font-weight: 600;
                        padding: 8px 20px;
                        border-radius: 10px;
                        transition: all 0.2s ease;
                        text-decoration: none;
                        display: inline-flex;
                        align-items: center;
                        gap: 6px;
                    }

                    .btn-back:hover {
                        background-color: #e2e8f0;
                        color: #1e293b;
                        text-decoration: none;
                    }

                    .search-card {
                        background: var(--card-bg);
                        border-radius: 16px;
                        box-shadow: var(--card-shadow);
                        border: 1px solid var(--border-color);
                        padding: 20px;
                        margin-bottom: 25px;
                    }

                    .table-card {
                        background: var(--card-bg);
                        border-radius: 16px;
                        box-shadow: var(--card-shadow);
                        border: 1px solid var(--border-color);
                        padding: 24px;
                        overflow: hidden;
                    }

                    .logs-table {
                        width: 100%;
                        margin-bottom: 0;
                    }

                    .logs-table th {
                        background-color: #f8fafc;
                        color: var(--text-muted);
                        font-weight: 600;
                        text-transform: uppercase;
                        font-size: 12px;
                        letter-spacing: 0.5px;
                        padding: 14px 16px;
                        border-bottom: 2px solid var(--border-color) !important;
                    }

                    .logs-table td {
                        padding: 14px 16px;
                        vertical-align: middle !important;
                        border-bottom: 1px solid #f1f5f9 !important;
                        font-size: 14px;
                    }

                    .logs-table tbody tr:hover {
                        background-color: #f8fafc;
                    }

                    .status-badge {
                        display: inline-block;
                        padding: 6px 12px;
                        border-radius: 20px;
                        font-size: 11px;
                        font-weight: 700;
                        text-transform: uppercase;
                        letter-spacing: 0.3px;
                        text-align: center;
                    }

                    .status-sent {
                        background-color: rgba(59, 130, 246, 0.1);
                        color: #0D6B44;
                    }

                    .status-delivered {
                        background-color: rgba(14, 165, 233, 0.1);
                        color: #0369a1;
                    }

                    .status-read {
                        background-color: rgba(16, 185, 129, 0.1);
                        color: #047857;
                    }

                    .status-received {
                        background-color: rgba(20, 184, 166, 0.1);
                        color: #0f766e;
                    }

                    .status-failed {
                        background-color: rgba(239, 68, 68, 0.1);
                        color: #b91c1c;
                    }

                    .status-unknown {
                        background-color: rgba(100, 116, 139, 0.1);
                        color: #475569;
                    }

                    .source-badge {
                        display: inline-block;
                        padding: 4px 8px;
                        border-radius: 12px;
                        font-size: 11px;
                        font-weight: 600;
                        text-transform: uppercase;
                        letter-spacing: 0.3px;
                        text-align: center;
                    }

                    .source-manual {
                        background-color: #f1f5f9;
                        color: #475569;
                        border: 1px solid #e2e8f0;
                    }

                    .source-bulk {
                        background-color: rgba(59, 130, 246, 0.1);
                        color: #0D6B44;
                        border: 1px solid rgba(59, 130, 246, 0.2);
                    }

                    .source-rotation {
                        background-color: rgba(16, 185, 129, 0.1);
                        color: #047857;
                        border: 1px solid rgba(16, 185, 129, 0.2);
                    }

                    .spin-icon {
                        animation: spin 1s infinite linear;
                    }

                    @keyframes spin {
                        from {
                            transform: rotate(0deg);
                        }

                        to {
                            transform: rotate(360deg);
                        }
                    }
                </style>
            </HEAD>

            <body>
                <div class="container">
                    <!-- Header -->
                    <div class="header-container">
                        <h1 class="header-title">
                            <span class="glyphicon glyphicon-phone" style="color: var(--primary);"></span>
                            WhatsApp Message Logs
                        </h1>
                        <a href="jobadmin.jsp" class="btn-back">
                            <span class="glyphicon glyphicon-arrow-left"></span> Back
                        </a>
                    </div>

                    <!-- Search Controls -->
                    <div class="search-card">
                        <div class="row">
                            <div class="col-md-8">
                                <div class="input-group">
                                    <span class="input-group-addon"><span
                                            class="glyphicon glyphicon-search"></span></span>
                                    <input type="text" id="logSearchInput" class="form-control"
                                        placeholder="Search by Patient ID, Name, Phone Number, or Message text...">
                                </div>
                            </div>
                            <div class="col-md-4">
                                <button type="button" id="refreshLogsBtn" class="btn btn-block btn-success"
                                    style="background-color: var(--primary); border-color: var(--primary); font-weight: 600; border-radius: 6px;">
                                    <span class="glyphicon glyphicon-refresh"></span> Refresh Logs
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Logs Table -->
                    <div class="table-card">
                        <div class="table-responsive">
                            <table class="table logs-table">
                                <thead>
                                    <tr>
                                        <th width="15%">Sent Date</th>
                                        <th width="10%">Patient ID</th>
                                        <th width="15%">Patient Name</th>
                                        <th width="12%">Phone</th>
                                        <th width="8%">Msg Type</th>
                                        <th width="10%">Source</th>
                                        <th width="20%">Message</th>
                                        <th width="10%">Status</th>
                                    </tr>
                                </thead>
                                <tbody id="logsTableBody">
                                    <!-- Loaded via AJAX -->
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <script>
                    var apiBase = window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1" ? "http://localhost:9090" : "";
                    $(document).ready(function () {
                        // Load logs initially
                        loadLogs();

                        // Setup search delay (debounce)
                        var searchTimer;
                        $("#logSearchInput").on("input", function () {
                            clearTimeout(searchTimer);
                            searchTimer = setTimeout(function () {
                                loadLogs();
                            }, 300);
                        });

                        // Refresh logs
                        $("#refreshLogsBtn").on("click", function () {
                            loadLogs();
                        });
                    });

                    function loadLogs() {
                        var search = $("#logSearchInput").val();
                        var tbody = $("#logsTableBody");

                        tbody.html("<tr><td colspan='8' style='text-align: center; padding: 40px;'><span class='glyphicon glyphicon-refresh spin-icon' style='font-size: 24px; color: var(--primary);'></span><br><br>Loading WhatsApp logs...</td></tr>");

                        $.ajax({
                            type: "GET",
                            url: apiBase + "/api/whatsapp/all-logs",
                            data: {
                                search: search,
                                limit: 500
                            },
                            success: function (logs) {
                                var html = "";
                                if (!logs || logs.length === 0) {
                                    html = "<tr><td colspan='8' style='text-align: center; color: var(--text-muted); padding: 30px;'>No message logs found.</td></tr>";
                                } else {
                                    logs.forEach(function (log) {
                                        var date = new Date(log.sent_at);
                                        var formattedDate = date.toLocaleString();
                                        var statusClass = "status-unknown";
                                        var statusText = log.status || "Failed";

                                        var statusUpper = statusText.toUpperCase();
                                        if (statusUpper === "RECEIVED") {
                                            statusClass = "status-received";
                                            statusText = "Received";
                                        } else if (statusUpper === "SUCCESS" || statusUpper === "SENT") {
                                            statusClass = "status-sent";
                                            statusText = "Sent";
                                        } else if (statusUpper === "DELIVERED") {
                                            statusClass = "status-delivered";
                                            statusText = "Delivered";
                                        } else if (statusUpper === "READ") {
                                            statusClass = "status-read";
                                            statusText = "Read";
                                        } else if (statusUpper.startsWith("FAIL") || statusUpper.startsWith("ERR")) {
                                            statusClass = "status-failed";
                                            statusText = "Failed";
                                        }

                                        var name = log.name || "<span style='color: #94a3b8; font-style: italic;'>Unknown User</span>";
                                        var msgType = log.msg_type || "<span style='color: #94a3b8;'>-</span>";

                                        var broadcastType = log.broadcast_type || "manual";
                                        var sourceClass = "source-manual";
                                        var sourceText = "Manual";
                                        if (broadcastType === "bulk") {
                                            sourceClass = "source-bulk";
                                            sourceText = "Bulk";
                                        } else if (broadcastType === "rotation") {
                                            sourceClass = "source-rotation";
                                            sourceText = "Rotation";
                                        }

                                        html += "<tr>";
                                        html += "  <td>" + formattedDate + "</td>";
                                        html += "  <td><strong>" + (log.uid || '-') + "</strong></td>";
                                        html += "  <td>" + name + "</td>";
                                        html += "  <td>" + (log.phone || '-') + "</td>";
                                        html += "  <td>" + msgType + "</td>";
                                        html += "  <td><span class='source-badge " + sourceClass + "'>" + sourceText + "</span></td>";
                                        html += "  <td style='white-space: pre-wrap; font-size: 13px;'>" + escapeHtml(log.message || '') + "</td>";
                                        html += "  <td><span class='status-badge " + statusClass + "'>" + statusText + "</span></td>";
                                        html += "</tr>";
                                    });
                                }
                                tbody.html(html);
                            },
                            error: function (xhr) {
                                tbody.html("<tr><td colspan='8' class='text-danger' style='text-align: center; padding: 30px;'><span class='glyphicon glyphicon-exclamation-sign'></span> Failed to load logs: " + xhr.statusText + "</td></tr>");
                            }
                        });
                    }

                    function escapeHtml(text) {
                        return text
                            .replace(/&/g, "&amp;")
                            .replace(/</g, "&lt;")
                            .replace(/>/g, "&gt;")
                            .replace(/"/g, "&quot;")
                            .replace(/'/g, "&#039;");
                    }
                </script>
            </body>

            </HTML>