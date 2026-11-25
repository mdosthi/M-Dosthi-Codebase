<%@page language="java"  import= "imedix.rcGenOperations,imedix.rcUserInfo,imedix.myDate,imedix.rcPatqueueInfo,imedix.rcDataEntryFrm,imedix.dataobj,imedix.cook, java.util.*"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%
	cook cookx = new cook();
	rcGenOperations rcgop=new rcGenOperations(request.getRealPath("/"));
	rcPatqueueInfo rcpqi=new rcPatqueueInfo(request.getRealPath("/"));
	rcUserInfo  rcui=new rcUserInfo(request.getRealPath("/"));
	String uid =cookx.getCookieValue("userid", request.getCookies ());
	String id=request.getParameter("pat_id");
	String assign_doc=request.getParameter("selphy");
	String opd_id = request.getParameter("opd_id");
	String usr = cookx.getCookieValue("usertype", request.getCookies());
	String ccode= cookx.getCookieValue("center", request.getCookies ());
	String pidCcode="";
	String currpatqtype = cookx.getCookieValue("currpatqtype",request.getCookies());

	if(id==null) id="";
	id=id.replaceAll("'","''");

	if(id.equals("")) {
		out.println("<font size=+1><Br><Br><center>Patient ID is Blank<br>Patient Visit Can Not be Saved<br> ");
		out.println("<BR><A HREF='javascript:history.go(-1)'><IMG SRC='../images/back.jpg' WIDTH='40' HEIGHT='30' BORDER=1 title='Back' ></A>");
		return;
	}

	if(id.length()>=4)
		pidCcode=id.substring(0,4).toUpperCase();
	else{
		out.println("<font size=+1><Br><Br><center>Invalid Patient ID <br>Patient Visit Can Not be Saved<br> ");
		out.println("<BR><A HREF='javascript:history.go(-1)'><IMG SRC='../images/back.jpg' WIDTH='40' HEIGHT='30' BORDER=1 title='Back' ></A>");
		return;
	}

	dataobj obj = new dataobj();
	try{
	rcDataEntryFrm rcdef = new rcDataEntryFrm(request.getRealPath("/"));
	obj.add("pat_id",id);
	obj.add("assigndoc",assign_doc);
	obj.add("visitdate",myDate.getCurrentDate("ymd",true));
	obj.add("userid",uid);
	obj.add("opdno",opd_id);
	
	int ans = rcdef.setVisitDate(obj);

	if(ans==1){
		cookx.addCookie("patid",id,response);

		String patdis="General Medical";
		String pname="";

		String cnd= "lower(pat_id) = '" + id.toLowerCase() +"'";
		pname=rcgop.getAnySingleValue("med","pat_name",cnd);
		//out.print("<br>"+pname+"<br>"+cnd);
		if(!pname.equals("")){
			cookx.addCookie("patname",pname,response);
		}
		
		cnd= "lower(pat_id) = '" + id.toLowerCase() +"'";
		patdis=rcgop.getAnySingleValue("med","class",cnd);
		
		out.println("<div style='color:blue;padding:10px;font-size:18px'>Patient has been registered and visible in local patient queue.</div>");
		//out.println("Start <a href='frames.html'> Data Entry </a>");
		//out.println("<BR>Click Here To Start <a href='showpatdata.jsp?id="+id+"&usr="+usr+"&nam="+pname+"&patdis="+patdis+"' target='_blank'> Data Entry </a>");
		//out.println("<Br><Br><a href='/iMediX'> HOME </a></center></font>");

	 }else{
		Object patq = rcpqi.getLPatEntry(id);
		Vector patqV = (Vector)patq;
		String docid="",docname="";
		
		if(patqV.size() != 0){
			dataobj obj4 = (dataobj)patqV.get(0);
			docid=(String)obj4.getValue("assigneddoc");
			docname=(String)rcui.getName((String)obj4.getValue("assigneddoc"));
			
		}
			//out.println(docid+"---"+docname);
			if(docid.equalsIgnoreCase("docVBCR019NA"))
			{
				out.println("<div style='color:blue;padding:10px;font-size:18px'> Patient is already present in local patient queue and is Not Assigned to any doctor. </div>");	

			}
			else if(!docid.equalsIgnoreCase("docVBCR019NA") && !docid.equalsIgnoreCase(""))
			{
				out.println("<div style='color:blue;padding:10px;font-size:18px'> Patient is already assigned to Doctor- "+docname+". </div>");	
				if(usr.equalsIgnoreCase("adm"))
				{
					out.println("<div class='col-sm-8 col-sm-offset-2'><div class='well' style='min-width: 750px;'><center><font size='+1' color='FIREBRICK'>Do you want to remove this patient from Dr."+docname+"'s Queue? </font></center><center><button type='button' class='btn btn-primary' onclick='remove()'>OK</button></center></div></div>");
				}
			}
			else
			{
				out.println("<div style='color:blue;padding:10px;font-size:18px'> Patient could not be re-visited. <br> </div>");
			}

			//response.sendRedirect(".....jsp");
			//out.println("<font size=+1><Br><Br><center>Invalid Patient ID <br> Or <br> Patient ID Not Found <br>Patient Visit Can Not be Saved<br> ");
			//out.println("<div style='color:blue;padding:10px;font-size:18px'> Patient already present in Doctor' Queue <br> Patient cannot not be re-visited while in Doctor's Queue. <br> </div>");
			
			//out.println("<BR><A HREF='javascript:history.go(-1)'><IMG SRC='../images/back.jpg' WIDTH='40' HEIGHT='30' BORDER=1 title='Try Again'></A>");


	 }

	//out.println("<br>"+ ans);

	}catch(Exception e){
		out.println("ERROR09974 : "+ e.toString());
	}
%>
<script>
function remove()
{
			let patid = "<%=id%>";
			var patqtype = "<%=currpatqtype%>";			
				$.ajax({
					type: "post",
					url: "patLTreatmentSts.jsp",
					data:{status:false,patid:patid,patqtype:patqtype},
					success: function(data){
						alert("Successfully removed from Doctor's queue");
						window.location.href = document.referrer;
					}
					});			
			
}

</script>