<%@page language="java"  import= "imedix.rcDataEntryFrm,imedix.rcCentreInfo,imedix.dataobj, imedix.cook,java.util.*,imedix.rcPatqueueInfo,imedix.rcUserInfo,imedix.myDate,imedix.Email,imedix.SMS,imedix.rcSmsApi"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%-- <%@ include file="api_call.jsp" %> --%>
<%
	cook cookx = new cook();
	rcCentreInfo centerinfo = new rcCentreInfo(request.getRealPath("/"));
	rcPatqueueInfo pqinfo = new rcPatqueueInfo(request.getRealPath("/"));
	rcUserInfo rcuinfo = new rcUserInfo(request.getRealPath("/"));
	//String ccode=request.getParameter("referring_doctor");
	String referring_doctor = request.getParameter("referring_doctor");
	//ccode=ccode.substring(3,7);
	String ccode=centerinfo.getCenterCode(referring_doctor,"login");
	String usrccode =cookx.getCookieValue("center", request.getCookies());
	//String usrccode = "VBCR019";
	String userid =cookx.getCookieValue("userid", request.getCookies ());
	String usr = cookx.getCookieValue("usertype", request.getCookies());
	String usrname = cookx.getCookieValue("username", request.getCookies());

	out.println(usrccode);
	dataobj obj = new dataobj();
	
	try{
		rcDataEntryFrm rcdef = new rcDataEntryFrm(request.getRealPath("/"));
		
		for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;) {
			String key=e.nextElement().toString();
			String val=request.getParameter(key);
			if(key.equalsIgnoreCase("dateofbirth"))
				val = val.replaceAll("-","");
			obj.add(key,val);
			//out.println(key +" : "+val);
		}
		obj.add("userid",userid);
		obj.add("center",usrccode);
		obj.add("usertype",usr);

		String id = "";
		String exist_id = rcdef.checkIntigrity(obj);
		
		if(exist_id.length()>=14){
			if(rcdef.isInQueue(exist_id)){
				out.println("<script>alert('It seems You have already registered');</script>");
				out.println("<script>window.location='displaymed.jsp?templateid=1&menuid=head1&dest=patientAlldata&id="+exist_id+"&ty=med&sl=&dt = ';</script>");
			}
			else{
				out.println("Patient id : "+exist_id +". This patient is already registered. <a href='setvisitdate.jsp?id="+exist_id+"' >Old Patient Registration</a>");
				out.println("<script>window.location='setvisitdate.jsp?id="+exist_id+"';</script>");
			}
		}
		else{
			if(usr.equalsIgnoreCase("pat")){
				id = rcdef.InsertMedWithoutDocAssign(usrccode,obj);

				String output="", retmsg="";
				String emailid = (String) session.getAttribute("verifemail");
				String phone = (String) session.getAttribute("verifphone");
				if (emailid != null && emailid.length()>0) {
					String subject = "Family Member Inclusion in iMediX";
					String mesg = "Dear "+usrname+",\n\n"+
								"One of your family members is now associated with your iMediX account.\n\n"+
								"Name: "+request.getParameter("pat_name")+"\n Relationship:"+request.getParameter("relationship")+"\n\n"+
								"*Note: If such activivity is not performed by you, please contact to iMediX administrator.";
					Email em = new Email(request.getRealPath("/"));
					//output = em.Send(emailid,subject,mesg);
				}
				if (phone != null && phone.length()>0) {
					rcSmsApi rcsmsapi = new rcSmsApi(request.getRealPath("/"));
					//String message = (String) rcsmsapi.makeMessage("M007", dataAry);
					String message="Update: Family Member Association in iMediX";
					SMS sms = new SMS(request.getRealPath("/"));
					//retmsg = sms.Send(phone, message);
				}			
			}
			else{	
				id = rcdef.InsertMed(usrccode,obj);
			}

			// String api_save2=createNewEdosthiPatient(obj,id);
			String patdis=request.getParameter("class");
			String pname = request.getParameter("pat_name");

			if(id.equalsIgnoreCase("Error")){
				out.println( "<CENTER>ERROR <br> Try Again</CENTER>" );
			}else{
				cookx.addCookie("patid",id,response);
				cookx.addCookie("patname",pname,response);
				//response.sendRedirect(response.encodeRedirectURL("showpatdata.jsp?id="+id+"&usr="+usr+"&nam="+pname+"&patdis="+patdis));
				pqinfo.updateLpatqAssignDate(id,myDate.getCurrentDateMySql());
				
				// ===== RCT RANDOMIZATION IMPLEMENTATION =====
				int rctFlag = 0; // Default: not in RCT
				double randomValue = 0.0;
				
				try {
					// Generate random number between 0 and 1
					randomValue = Math.random();
					
					// If random value > 0.5, assign to RCT
					if(randomValue > 0.5) {
						rctFlag = 1;
					}
					
					// Log the assignment for audit purposes
					System.out.println("=== RCT ASSIGNMENT ===");
					System.out.println("Patient ID: " + id);
					System.out.println("Random Value: " + randomValue);
					System.out.println("RCT Assignment: " + rctFlag + " (" + (rctFlag == 1 ? "ENROLLED" : "NOT ENROLLED") + ")");
					System.out.println("Timestamp: " + myDate.getCurrentDateMySql());
					System.out.println("========================");
					
				} catch(Exception rctEx) {
					System.out.println("RCT randomization error for patient " + id + ": " + rctEx.getMessage());
					// Default to 0 if error occurs
					rctFlag = 0;
				}
				// ===== END RCT RANDOMIZATION =====
				
				String loginStatus = "";
				if(request.getParameter("pat-login") != null){
					String name="",phone="";
					if(request.getParameter("m_name") != null && request.getParameter("m_name").trim().length()>0){
						name=request.getParameter("pat_name")+" "+request.getParameter("m_name")+" "+request.getParameter("l_name");
					}
					else{
						name=request.getParameter("pat_name")+" "+request.getParameter("l_name");
					}
					String phoneParam = request.getParameter("phone");
					phone = (phoneParam != null) ? phoneParam.trim() : "";
					String emailVerifiedParam = request.getParameter("emailVerified");
					dataobj loginObj = new dataobj();
					loginObj.add("uid",id);
					loginObj.add("pwd",id);
					//loginObj.add("name",request.getParameter("pat_name"));
					loginObj.add("name",name);
					loginObj.add("crtdate", myDate.getCurrentDateMySql());
					loginObj.add("center", usrccode);
					loginObj.add("userid", userid);
					loginObj.add("type","PAT");
					loginObj.add("active","Y");
					loginObj.add("available","Y");
					loginObj.add("referral","Y");
					loginObj.add("verified", "A");
					//loginObj.add("verifemail", "N"); //Get the varified status from signup form
					loginObj.add("verifemail", ("Y".equals(emailVerifiedParam) ? "Y" : "N"));
					loginObj.add("verifphone", "N"); //Get the varified status from signup form
					loginObj.add("consent","N");
					
					// Add RCT flag to login object
					loginObj.add("rctFlag", String.valueOf(rctFlag));
					loginObj.add("phone", phone);

					int ans = rcuinfo.InsertRegUsers(loginObj,null);

					//String api_save=createNewEdosthiLogin(loginObj);//
					loginStatus = "Patient login id is Patient ID and password is same as patient ID";
				} else {
					// Even if no login is created, we still need to update RCT flag in the database
					try {
						boolean rctUpdated = rcuinfo.updateRctFlagAfterRegistration(id, rctFlag);
						if(!rctUpdated) {
							System.out.println("Warning: Failed to update RCT flag for patient " + id);
						}
					} catch(Exception rctUpdateEx) {
						System.out.println("Error updating RCT flag after registration: " + rctUpdateEx.getMessage());
					}
				}
				
				//out.println("<br>"+ patdis);
				//out.println("<script>var chk=prompt('Successfully Registered !\n "+loginStatus+", Pat ID :"+id+"');</script>");
				String login;
				if(request.getParameter("pat-login") != null)
				{
					login="Y";
				}
				else
				{
					login="N";
				}
				//out.println("<script>window.location='displaymed.jsp?templateid=1&menuid=head1&dest=patientAlldata&id="+id+"&ty=med&sl=&dt = ';</script>");
				// out.println("<script>window.location='displaymed.jsp?templateid=1&menuid=head1&dest=patientAlldata&id="+id+"&login="+login+"&ty=med&sl=&dt = ';</script>");
				// Simple RCT status message
				String rctMessage = "";
				if(rctFlag == 1) {
					rctMessage = "Patient successfully registered!\\n\\nPatient ID: " + id /* + "\\n\\nRCT Status: ENROLLED in chatbot Study" */;
				} else {
					rctMessage = "Patient successfully registered!\\n\\nPatient ID: " + id /* + "\\n\\nRCT Status: NOT enrolled in chatbot Study" */;
				}

				if(usr.equalsIgnoreCase("adm")){
					// Offer the psychologist referral action after admin registration.
%>
					<script>alert('<%=rctMessage%>');</script>
					<div style="max-width:520px;margin:60px auto;padding:24px;border:1px solid #c8dce8;border-radius:6px;font-family:Arial,Helvetica,sans-serif;background:#eaf5fb;">
						<h3 style="margin-top:0;color:#245b86;">Patient Registered: <%=id%></h3>
						<p>Refer this patient to a psychologist:</p>
						<a href="referToPsychologist.jsp?pat_id=<%=id%>" style="display:inline-block;padding:10px 16px;background:#8f4d43;color:#fff;border-radius:3px;text-decoration:none;">Refer to Psychologist</a>
					</div>
<%
				} else {
					// Show alert and redirect
					out.println("<script>");
					out.println("alert('" + rctMessage + "');");
					out.println("window.location='poBadoScreening.jsp?pat_id="+id+"';");
					out.println("</script>");
				}
							}
						}
					}catch(Exception e){
						out.println( e.toString());
					}
	//response.sendRedirect("frames.html");
%>