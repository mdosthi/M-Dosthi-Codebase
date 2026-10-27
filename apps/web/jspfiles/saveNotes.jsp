<%@page language="java"  import= "imedix.rcDataEntryFrm,imedix.rcDisplayData,imedix.dataobj,imedix.cook,java.util.*"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%
    cook cookx = new cook();
    String ccode = cookx.getCookieValue("center", request.getCookies());
    String userid = cookx.getCookieValue("userid", request.getCookies());
    String utype = cookx.getCookieValue("usertype", request.getCookies());
    if(ccode==null) return;
    if(ccode.equals("")) return;
    dataobj obj = new dataobj();
    try{
      //code to obstruct empty forms
      String skipFields = "frmnam testdate pat_id entrydate nofimg name_hos";
      int dataFields = 0, j = 0, c = 0;
      rcDataEntryFrm rcdef = new rcDataEntryFrm(request.getRealPath("/"));
      rcDisplayData rcDisplayData = new rcDisplayData(request.getRealPath("/"));

      String formName = request.getParameter("frmnam");

      for (Enumeration e = request.getParameterNames(); e.hasMoreElements();) {
          String key = e.nextElement().toString();
          String vals[] = request.getParameterValues(key);
          String val = "";
          for(int i = 0; i < vals.length; i++) val = val + "," + vals[i];
          val = val.substring(1).trim();
          obj.add(key, val);

          if (skipFields.indexOf(key) == -1 && val.length() > 0 && key.equalsIgnoreCase(val) == false) dataFields++;
          if (val.length() < 2 && val.length() > 0) {
            j = 0; c = 0;
            while(j < val.length()) {
              char tm = val.charAt(j);
              if (Character.isLetterOrDigit(tm)) c++;
              j++;
            }
            if (c == 0) dataFields--;
          }
      }

      obj.add("userid", userid);
      obj.add("center", ccode);
      obj.add("usertype", utype);

      if (dataFields > 0) {
        String pat_id = request.getParameter("pat_id");
        String notes = request.getParameter("notes"); 
        if (notes == null) {
            notes = request.getParameter("rh"); 
        }
        String testdate = request.getParameter("testdate");
        String report_link = request.getParameter("report_link");

        obj.setValue("notes", notes);
        obj.setValue("frmnam", formName);

        int ans = rcdef.InsertFrmAll(obj);

        if(ans == 1) {
            // Get the last record to get entrydate and serno
            Vector lastNotes = (Vector)rcDisplayData.getLastNotes(pat_id);
            dataobj ccObj = (dataobj)lastNotes.get(0);
            String entrydate = ccObj.getValue("entrydate");
            System.out.println("entrydate: " + entrydate);
            String serno = ccObj.getValue("serno");
            System.out.println("serno: " + serno);

            // Create data object for psychologistNotes
            dataobj o = new dataobj();
            o.add("notes", notes);
            o.add("report_link", (report_link != null) ? report_link : "");
            o.add("testdate", testdate);
            o.add("pat_id", pat_id);
            o.add("entrydate", entrydate);
            o.add("serno", serno);

            // Insert into psychologistNotes table
            boolean noteInserted = rcdef.insertpsyNotes(o);

            if(noteInserted) {
                response.sendRedirect("showlist.jsp");
            } else {
                out.println("Error: Could not insert psychologist notes!");
            }
        } else {
            out.println("Error: DB/RMI could be the reason!");
        }
      } else {
        out.println("<br><br><br><center><font color='Blue' size='5'>Cannot Submit a Blank Form</font><br><br><br><a href='javascript: history.go(-1)'>Back</a></center>");
      }
    } catch(Exception e) {
        out.println(e.toString());
    }
%>