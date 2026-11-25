<%@page language="java"  import= "imedix.projinfo, imedix.rcDisplayData,imedix.dataobj,imedix.cook,java.util.*,org.json.simple.*,java.text.SimpleDateFormat"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%
    cook cookx = new cook();
    String ccode= cookx.getCookieValue("center", request.getCookies ());
    String uid =cookx.getCookieValue("userid", request.getCookies ());

    projinfo prin = new projinfo(request.getRealPath("/"));

    
    rcDisplayData display = new rcDisplayData(request.getRealPath("/"));
    String key = request.getParameter("key");
    
    JSONObject result = new JSONObject();
    try{
        Vector res = (Vector)display.searchPatient(key, ccode);       
        
        JSONArray patients = new JSONArray();
        for(int i=0; i<res.size(); i++){
            dataobj obj = (dataobj)res.get(i);
            JSONObject patient = new JSONObject();
            patient.put("name", obj.getValue("pat_name")+" "+obj.getValue("l_name"));
            patient.put("phone", obj.getValue("phone"));
            patient.put("emailid", obj.getValue("emailid"));
            patient.put("pat_id", obj.getValue("pat_id"));
            patient.put("pat_name", obj.getValue("pat_name"));
            patient.put("l_name", obj.getValue("l_name"));
            patient.put("pat_person", obj.getValue("pat_person"));
            patients.add(patient);
        }
        result.put("status", "success");
        result.put("data", patients);
    }catch(Exception e){
        result.put("status", "error");
        result.put("msg", e.getMessage());
    }
    out.println(result);

%>