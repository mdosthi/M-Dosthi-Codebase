<%@page contentType="text/html" import="java.io.*,java.sql.*"%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Bulk WhatsApp Messaging — M-Dosthi</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: 'Segoe UI', Arial, sans-serif; background: #f0f4f8; color: #222; }

  header {
    background: #25D366; color: #fff; padding: 14px 24px;
    display: flex; align-items: center; gap: 12px;
  }
  header svg { width: 28px; height: 28px; fill: #fff; flex-shrink: 0; }
  header h1 { font-size: 1.15rem; font-weight: 600; }

  .container { max-width: 1100px; margin: 24px auto; padding: 0 16px; }

  .card {
    background: #fff; border-radius: 8px;
    box-shadow: 0 1px 4px rgba(0,0,0,.1);
    padding: 20px; margin-bottom: 20px;
  }
  .card h2 {
    font-size: .88rem; font-weight: 700; color: #334; margin-bottom: 16px;
    text-transform: uppercase; letter-spacing: .05em;
  }

  /* Template buttons */
  .tmpl-btn-row { display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 14px; }
  .btn-tmpl {
    padding: 9px 20px; border: 2px solid #25D366; border-radius: 7px;
    background: #fff; color: #166534; font-size: .88rem; font-weight: 600;
    cursor: pointer; transition: background .15s, color .15s;
  }
  .btn-tmpl:hover { background: #f0fdf4; }
  .btn-tmpl.active { background: #25D366; color: #fff; }

  /* Textarea */
  textarea#msgBox {
    width: 100%; min-height: 110px; max-height: 280px;
    padding: 10px 14px; border: 1px solid #cbd5e1; border-radius: 7px;
    font-size: .9rem; font-family: inherit; resize: vertical;
    transition: border-color .15s;
  }
  textarea#msgBox:focus { outline: none; border-color: #25D366; }

  .meta-row {
    display: flex; justify-content: space-between; align-items: center;
    margin-top: 6px; flex-wrap: wrap; gap: 6px;
  }
  .char-counter { font-size: .78rem; color: #888; }
  .mode-badge { font-size: .78rem; padding: 2px 10px; border-radius: 12px; font-weight: 600; }
  .badge-tmpl   { background: #dcfce7; color: #166534; }
  .badge-custom { background: #E9F8F0; color: #0D6B44; }

  .policy-note {
    margin-top: 10px; font-size: .78rem; color: #92400e;
    background: #fffbeb; border: 1px solid #fde68a;
    padding: 7px 12px; border-radius: 6px; line-height: 1.5;
  }

  /* Toolbar */
  .toolbar { display: flex; gap: 8px; align-items: center; margin-bottom: 12px; flex-wrap: wrap; }
  .toolbar input[type=search] {
    flex: 1; min-width: 180px; padding: 7px 12px;
    border: 1px solid #cbd5e1; border-radius: 6px; font-size: .88rem;
  }
  .toolbar label { font-size: .83rem; color: #555; display: flex; align-items: center; gap: 5px; }
  .sel-count { font-size: .83rem; color: #555; margin-left: auto; font-weight: 600; }

  .btn { padding: 7px 16px; border: none; border-radius: 6px; cursor: pointer; font-size: .85rem; font-weight: 600; }
  .btn:hover { opacity: .85; }
  .btn-grey { background: #e2e8f0; color: #334; }

  /* Patient table */
  .table-wrap { overflow-x: auto; }
  table { width: 100%; border-collapse: collapse; font-size: .86rem; }
  thead th {
    background: #f8fafc; padding: 9px 10px; text-align: left;
    border-bottom: 2px solid #e2e8f0; font-weight: 600; color: #444; white-space: nowrap;
  }
  tbody tr { border-bottom: 1px solid #f0f4f8; }
  tbody tr:hover { background: #f8fafc; }
  tbody td { padding: 7px 10px; }
  tbody tr.no-phone td { color: #bbb; }

  .badge-phone   { display: inline-block; background: #dcfce7; color: #166534; padding: 2px 8px; border-radius: 12px; font-size: .78rem; }
  .badge-nophone { display: inline-block; background: #fee2e2; color: #991b1b; padding: 2px 8px; border-radius: 12px; font-size: .78rem; }
  .last-comm { color: #64748b; font-size: .82rem; }

  /* Send bar */
  .send-bar { display: flex; align-items: center; gap: 16px; margin-bottom: 20px; }
  .btn-send {
    padding: 11px 36px; background: #25D366; color: #fff;
    font-size: 1rem; font-weight: 700; border-radius: 8px;
    border: none; cursor: pointer; transition: background .15s;
  }
  .btn-send:hover   { background: #1ebe5d; }
  .btn-send:disabled { background: #94a3b8; cursor: not-allowed; }

  .progress-info { display: flex; align-items: center; gap: 8px; font-size: .88rem; color: #555; }
  .spinner {
    width: 18px; height: 18px; border: 3px solid #e2e8f0;
    border-top-color: #25D366; border-radius: 50%;
    animation: spin .7s linear infinite;
  }
  @keyframes spin { to { transform: rotate(360deg); } }

  /* Log table */
  #logTable { width: 100%; border-collapse: collapse; font-size: .83rem; }
  #logTable th { background: #f8fafc; padding: 7px 10px; text-align: left; border-bottom: 2px solid #e2e8f0; font-weight: 600; color: #444; }
  #logTable td { padding: 7px 10px; border-bottom: 1px solid #f0f4f8; }
  .status-sent   { color: #166534; font-weight: 600; }
  .status-failed { color: #991b1b; font-weight: 600; }

  /* Toast */
  #toast {
    position: fixed; bottom: 24px; right: 24px;
    background: #1e293b; color: #fff;
    padding: 12px 20px; border-radius: 8px;
    font-size: .88rem; display: none; z-index: 9999;
    max-width: 360px; box-shadow: 0 4px 12px rgba(0,0,0,.2);
  }
  #toast.show    { display: block; }
  #toast.success { background: #166534; }
  #toast.error   { background: #991b1b; }
</style>
</head>
<body>

<header>
  <svg viewBox="0 0 24 24">
    <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>
    <path d="M12 0C5.373 0 0 5.373 0 12c0 2.082.534 4.038 1.469 5.741L0 24l6.417-1.447A11.93 11.93 0 0012 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 21.818a9.8 9.8 0 01-5.027-1.376l-.36-.214-3.728.84.876-3.617-.235-.371A9.787 9.787 0 012.182 12C2.182 6.579 6.579 2.182 12 2.182c5.42 0 9.818 4.397 9.818 9.818 0 5.42-4.398 9.818-9.818 9.818z"/>
  </svg>
  <h1>Bulk WhatsApp Messaging</h1>
</header>

<div class="container">

  <!-- 1. Compose -->
  <div class="card">
    <h2>1. Compose Message</h2>

    <div class="tmpl-btn-row">
      <button class="btn-tmpl" id="tmplAppt" onclick="fillTemplate('appointment', this)">
        &#128197; Appointment Reminder
      </button>
      <button class="btn-tmpl" id="tmplFollowup" onclick="fillTemplate('followup', this)">
        &#128276; Follow-up Request
      </button>
    </div>

    <textarea id="msgBox" maxlength="1024"
      placeholder="Type a custom message here, or click a template button above to auto-fill…"></textarea>

    <div class="meta-row">
      <span class="char-counter" id="charCount">0 / 1024</span>
      <span class="mode-badge" id="modeBadge"></span>
    </div>

    <p class="policy-note">
      <strong>&#9888; Note:</strong>
      <strong>Custom text</strong> messages can only be delivered within a 24-hour conversation window (patient must have messaged first).
      <strong>Template</strong> messages (via the buttons above) can be sent to any patient with a phone number at any time.
    </p>
  </div>

  <!-- 2. Patient list -->
  <div class="card">
    <h2>2. Select Patients</h2>
    <div class="toolbar">
      <input type="search" id="searchBox" placeholder="Search by name or patient ID…" oninput="filterTable()">
      <label>
        <input type="checkbox" id="phoneToggle" onchange="filterTable()">
        Has phone only
      </label>
      <button class="btn btn-grey" onclick="selectAll()">Select All Visible</button>
      <button class="btn btn-grey" onclick="clearAll()">Clear</button>
      <span class="sel-count" id="selCount">0 selected</span>
    </div>

    <div class="table-wrap">
      <table id="patTable">
        <thead>
          <tr>
            <th style="width:40px">
              <input type="checkbox" id="masterCheck" onchange="toggleAll(this)" title="Select / deselect all visible">
            </th>
            <th>Patient Name</th>
            <th>Phone Number</th>
            <th>Last Delivery Status</th>
          </tr>
        </thead>
        <tbody id="patBody">
<%
try {
    String dbURL = System.getenv("LEGACY_DB_URL") != null ? System.getenv("LEGACY_DB_URL")
        : "jdbc:mysql://127.0.0.1:3306/mDosthi?useUnicode=true&characterEncoding=UTF-8";
    String dbUser = System.getenv("LEGACY_DB_USERNAME") != null ? System.getenv("LEGACY_DB_USERNAME") : "root";
    String dbPass = System.getenv("LEGACY_DB_PASSWORD") != null ? System.getenv("LEGACY_DB_PASSWORD") : "";
    try {
        File webappDir = new File(request.getRealPath("/"));
        File repoRoot = webappDir.getParentFile().getParentFile();
        File blInf = new File(repoRoot, "services/legacy/runtime/gblinfo.inf");
        if (!blInf.exists()) blInf = new File(repoRoot, "M-Dosthi-BL/gblinfo.inf");
        if (blInf.exists()) {
            try (BufferedReader br = new BufferedReader(new FileReader(blInf))) {
                String cfgLine;
                while ((cfgLine = br.readLine()) != null) {
                    int eq = cfgLine.indexOf('=');
                    if (eq > 0) {
                        String k = cfgLine.substring(0, eq).trim().toLowerCase();
                        String v = cfgLine.substring(eq + 1).trim();
                        if ("gbldburl".equals(k) && System.getenv("LEGACY_DB_URL") == null) dbURL = v;
                        else if ("gbldbusername".equals(k) && System.getenv("LEGACY_DB_USERNAME") == null) dbUser = v;
                        else if ("gbldbpasswd".equals(k) && System.getenv("LEGACY_DB_PASSWORD") == null) dbPass = v;
                    }
                }
            }
        }
    } catch (Exception ignored) {}
    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection conn = DriverManager.getConnection(dbURL, dbUser, dbPass);
    PreparedStatement ps = conn.prepareStatement(
        "SELECT l.uid, l.name, l.phone, " +
        "(SELECT w.status FROM whatsapp_logs w WHERE w.pat_id = l.uid ORDER BY w.sent_at DESC LIMIT 1) AS last_status " +
        "FROM login l " +
        "WHERE l.type = 'PAT' " +
        "ORDER BY l.name");
    ResultSet rs = ps.executeQuery();
    int rowCount = 0;
    while (rs.next()) {
        String uid        = rs.getString("uid")   != null ? rs.getString("uid")   : "";
        String name       = rs.getString("name")  != null ? rs.getString("name").replace("<","&lt;").replace(">","&gt;") : "";
        String phone      = rs.getString("phone") != null ? rs.getString("phone").trim() : "";
        String lastStatus = rs.getString("last_status");
        boolean hasPhone  = !phone.isEmpty();
        rowCount++;
%>
          <tr class="pat-row<%= hasPhone ? "" : " no-phone" %>"
              data-id="<%= uid %>"
              data-name="<%= name.toLowerCase() %>"
              data-phone="<%= phone %>">
            <td>
              <input type="checkbox" class="pat-cb" value="<%= uid %>"
                <%= hasPhone ? "" : "disabled title=\"No phone number recorded\"" %>
                onchange="updateCount()">
            </td>
            <td><%= name %></td>
            <td>
              <% if (hasPhone) { %>
                <span class="badge-phone"><%= phone %></span>
              <% } else { %>
                <span class="badge-nophone">No phone</span>
              <% } %>
            </td>
            <td>
              <% if (lastStatus == null) { %>
                <span style="color:#aaa">—</span>
              <% } else if ("read".equals(lastStatus)) { %>
                <span style="background:#D6F5E3;color:#0D6B44;padding:2px 8px;border-radius:12px;font-size:.78rem">&#128065; read</span>
              <% } else if ("delivered".equals(lastStatus)) { %>
                <span style="background:#dcfce7;color:#166534;padding:2px 8px;border-radius:12px;font-size:.78rem">&#10004;&#10004; delivered</span>
              <% } else if ("sent".equals(lastStatus)) { %>
                <span style="background:#f1f5f9;color:#475569;padding:2px 8px;border-radius:12px;font-size:.78rem">&#10004; sent</span>
              <% } else { %>
                <span class="badge-nophone">&#10008; failed</span>
              <% } %>
            </td>
          </tr>
<%  }
    rs.close(); ps.close(); conn.close();
    if (rowCount == 0) out.println("<tr><td colspan='4' style='color:#888;padding:12px'>No patients found.</td></tr>");
} catch (Exception e) {
    out.println("<tr><td colspan='4' style='color:red;padding:12px'>DB error: " + e.getMessage() + "</td></tr>");
}
%>
        </tbody>
      </table>
    </div>
  </div>

  <!-- 3. Send bar -->
  <div class="send-bar">
    <button id="sendBtn" class="btn-send" onclick="sendMessages()">
      &#9654; Send Message
    </button>
    <div id="sendProgress" class="progress-info" style="display:none">
      <div class="spinner"></div>
      <span>Sending, please wait&hellip;</span>
    </div>
  </div>

  <!-- 4. Log -->
  <div class="card">
    <h2>Recent Message Log</h2>
    <table id="logTable">
      <thead>
        <tr>
          <th>Time</th>
          <th>Patient</th>
          <th>Phone</th>
          <th>Type</th>
          <th>Status</th>
          <th>Note</th>
        </tr>
      </thead>
      <tbody id="logBody">
        <tr><td colspan="6" style="color:#888;padding:12px">Loading&hellip;</td></tr>
      </tbody>
    </table>
  </div>

</div><!-- /container -->
<div id="toast"></div>

<script>
// Template definitions — metaTemplate must match approved name in Meta Business Manager
const TEMPLATES = {
  appointment: {
    display:      "Appointment Reminder",
    text:         "Dear Patient, this is a reminder about your upcoming appointment. Please contact us if you need to reschedule or have any questions. Thank you.",
    metaTemplate: "session_reminder"
  },
  followup: {
    display:      "Follow-up Request",
    text:         "Dear Patient, we are following up on your recent visit. Please feel free to reach out if you need any assistance or have any concerns.",
    metaTemplate: "followup_checkin"
  }
};

let activeTemplateKey = null;

function fillTemplate(key, btn) {
  activeTemplateKey = key;
  document.getElementById("msgBox").value = TEMPLATES[key].text;
  updateCharCount();
  updateModeBadge();
  document.querySelectorAll(".btn-tmpl").forEach(b => b.classList.remove("active"));
  btn.classList.add("active");
}

document.getElementById("msgBox").addEventListener("input", function () {
  activeTemplateKey = null;
  document.querySelectorAll(".btn-tmpl").forEach(b => b.classList.remove("active"));
  updateCharCount();
  updateModeBadge();
});

function updateCharCount() {
  const len = document.getElementById("msgBox").value.length;
  const el  = document.getElementById("charCount");
  el.textContent = len + " / 1024";
  el.style.color  = len > 900 ? "#ef4444" : len > 700 ? "#f59e0b" : "#888";
}

function updateModeBadge() {
  const badge = document.getElementById("modeBadge");
  if (activeTemplateKey) {
    badge.textContent = "📋 Template: " + TEMPLATES[activeTemplateKey].display;
    badge.className   = "mode-badge badge-tmpl";
  } else if (document.getElementById("msgBox").value.trim()) {
    badge.textContent = "✏ Custom text message";
    badge.className   = "mode-badge badge-custom";
  } else {
    badge.textContent = "";
    badge.className   = "mode-badge";
  }
}

// Patient table
function filterTable() {
  const q         = document.getElementById("searchBox").value.toLowerCase();
  const phoneOnly = document.getElementById("phoneToggle").checked;
  document.querySelectorAll(".pat-row").forEach(row => {
    const matchSearch = row.dataset.name.includes(q) || row.dataset.id.toLowerCase().includes(q);
    const matchPhone  = !phoneOnly || row.dataset.phone !== "";
    row.style.display = (matchSearch && matchPhone) ? "" : "none";
  });
  updateCount();
}

function toggleAll(master) {
  document.querySelectorAll(".pat-cb:not(:disabled)").forEach(cb => {
    if (cb.closest("tr").style.display !== "none") cb.checked = master.checked;
  });
  updateCount();
}

function selectAll() {
  document.querySelectorAll(".pat-cb:not(:disabled)").forEach(cb => {
    if (cb.closest("tr").style.display !== "none") cb.checked = true;
  });
  document.getElementById("masterCheck").checked = true;
  updateCount();
}

function clearAll() {
  document.querySelectorAll(".pat-cb").forEach(cb => cb.checked = false);
  document.getElementById("masterCheck").checked = false;
  updateCount();
}

function updateCount() {
  const n = document.querySelectorAll(".pat-cb:checked").length;
  document.getElementById("selCount").textContent = n + " selected";
}

// Send
function sendMessages() {
  const patIds = [...document.querySelectorAll(".pat-cb:checked")].map(cb => cb.value).join(",");
  if (!patIds) { toast("Select at least one patient.", "error"); return; }

  const msg = document.getElementById("msgBox").value.trim();
  if (!msg)  { toast("Type a message or choose a template.", "error"); return; }

  const btn  = document.getElementById("sendBtn");
  const prog = document.getElementById("sendProgress");
  btn.disabled = true;
  prog.style.display = "flex";

  const body = new URLSearchParams({ pat_ids: patIds });
  if (activeTemplateKey) {
    body.set("template", TEMPLATES[activeTemplateKey].metaTemplate);
  } else {
    body.set("message", msg);
  }

  fetch("sendWhatsAppMessage.jsp", { method: "POST", body })
    .then(r => r.json())
    .then(data => {
      btn.disabled = false;
      prog.style.display = "none";
      if (data.success) {
        const failNote = data.failed_count > 0
          ? " (check log for errors — custom text requires 24h window)"
          : "";
        toast("✔ Sent: " + data.sent_count + "  |  Failed: " + data.failed_count + failNote,
              data.failed_count === 0 ? "success" : "error");
        clearAll();
        loadLog();
      } else {
        toast("Error: " + data.message, "error");
      }
    })
    .catch(e => {
      btn.disabled = false;
      prog.style.display = "none";
      toast("Network error: " + e, "error");
    });
}

// Toast
function toast(msg, type) {
  const el = document.getElementById("toast");
  el.textContent = msg;
  el.className = "show " + (type || "");
  setTimeout(() => { el.className = ""; }, 5000);
}

// Log
function loadLog() {
  fetch("getWhatsAppLog.jsp")
    .then(r => r.json())
    .then(data => {
      const tbody = document.getElementById("logBody");
      if (!data.logs || data.logs.length === 0) {
        tbody.innerHTML = "<tr><td colspan='6' style='color:#888;padding:12px'>No messages sent yet.</td></tr>";
        return;
      }
      tbody.innerHTML = data.logs.map(l => {
        const typeLabel = l.template_name === "custom_text"
          ? "✏&nbsp;Custom text"
          : "📋&nbsp;" + l.template_name;
        return `<tr>
          <td>${l.sent_at}</td>
          <td>${l.name || l.pat_id}</td>
          <td>${l.phone}</td>
          <td>${typeLabel}</td>
          <td class="status-${l.status}">${l.status}</td>
          <td style="color:#888;font-size:.78rem">${l.error_msg || ""}</td>
        </tr>`;
      }).join("");
    }).catch(() => {});
}

loadLog();
</script>
</body>
</html>
