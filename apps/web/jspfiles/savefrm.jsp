<%@page language="java"  import= "imedix.rcDataEntryFrm,imedix.rcDisplayData,imedix.dataobj,imedix.cook,java.util.*"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%
	cook cookx = new cook();
	String ccode =cookx.getCookieValue("center", request.getCookies());
	String userid =cookx.getCookieValue("userid", request.getCookies());
	String utype =cookx.getCookieValue("usertype", request.getCookies());

	if(ccode==null) return;
	if(ccode.equals("")) return;

	dataobj obj = new dataobj();
	try{
	  //code to obstruct empty forms
	  String skipFields="frmnam testdate pat_id entrydate nofimg name_hos";
	  skipFields += " hdmy1 hdmy2 hdmy3 tb_hdmy past_hdmy infection_hdmy ";
	  int dataFields=0, j=0, c=0;
	  rcDataEntryFrm rcdef = new rcDataEntryFrm(request.getRealPath("/"));
	  rcDisplayData rcDisplayData = new rcDisplayData(request.getRealPath("/"));
	  for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;) {
	      String key=e.nextElement().toString();
	      String vals[]=request.getParameterValues(key);
	      String val="";
	      for(int i=0;i<vals.length;i++) val=val+","+vals[i];
	      val=val.substring(1).trim();
	      obj.add(key,val);
	      if (skipFields.indexOf(key)==-1 && val.length()>0 && key.equalsIgnoreCase(val)==false) dataFields++;
	      if (val.length()<2 && val.length()>0) {
		j=0; c=0;
		while(j<val.length()) {
		  char tm = val.charAt(j);
		  if (Character.isLetterOrDigit(tm)) c++;
		  j++;
		}
		if (c==0) dataFields--;
	      }
	      //if (val.length()>0) out.println("dataFields = "+dataFields+"  key="+key +" : val="+val+"<br>");
	  }

	  obj.add("userid",userid);
	  obj.add("center",ccode);
	  obj.add("usertype",utype);

	  //out.println("<br>"+ dataFields);
	  if (dataFields>0) {
		String _comp1 = request.getParameter("comp1");
		String _dur1 = request.getParameter("dur1");
		String _hdmy1 = request.getParameter("hdmy1");
		String basic_diagnosis = request.getParameter("basicdiag");
		String pat_id = request.getParameter("pat_id");

		// clear fields
		obj.setValue("comp1", basic_diagnosis);
		obj.setValue("dur1", "");
		obj.setValue("hdmy1", "");
		
	    int ans = rcdef.InsertFrmAll(obj);
	    //if(ans==1) response.sendRedirect("showlist.jsp");
	    //else out.println("Error: DB/RMI could be reason!!");
		if(ans==1) {
			Vector lastCheifComplaint = (Vector)rcDisplayData.getLastChiefComplaint(pat_id);
			dataobj ccObj = (dataobj)lastCheifComplaint.get(0);
			String entrydate = ccObj.getValue("entrydate");
			System.out.println("entrydate: "+entrydate);
			String serno = ccObj.getValue("serno");
			System.out.println("serno: "+serno);
			
			String[] _comps = _comp1.split(",");
			String[] _durs = _dur1.split(",");
			String[] _hdmys = _hdmy1.split(",");

			for(int cc=0; cc<_comps.length; cc++){
				dataobj o = new dataobj();
				o.add("complaint", _comps[cc]);
				System.out.println("complaint: "+_comps[cc]);
				o.add("duration", _durs[cc]);
				System.out.println("duration: "+_durs[cc]);
				o.add("hdmy", _hdmys[cc]);
				System.out.println("hdmy: "+_hdmys[cc]);
				o.add("pat_id", pat_id);				
				o.add("entrydate", entrydate);
				o.add("serno", serno);
				rcdef.insertChiefComplaint(o);
			}
			
			response.sendRedirect("showlist.jsp");			
		}
	    else 
			out.println("Error: DB/RMI could be reason!!");
	    //out.println("Attempted to Submit : " + ans);
	    //out.println("<br>"+ ans);
	  }
	  else {
	    out.println("<br><br><br><center><font color='Blue' size='5'>Cannot Submit a Blank Form</font><br><br><br><a href='javascript: history.go(-1)'>Back</a><center>");
	  }
	}catch(Exception e){
		out.println( e.toString());
	}
%>
