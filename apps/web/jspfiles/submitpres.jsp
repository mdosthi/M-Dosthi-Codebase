<%@page language="java"  import= "java.util.Date,imedix.rcDataEntryFrm,imedix.dataobj, imedix.myDate,imedix.cook,java.util.*"%>
<%@ include file="..//includes/chkcook.jsp" %>

<%
	
	cook cookx = new cook();
	rcDataEntryFrm rcdef = new rcDataEntryFrm(request.getRealPath("/"));
	
	String id=request.getParameter("pat_id").trim();
	
	String userid =cookx.getCookieValue("userid", request.getCookies());
	String ccode =cookx.getCookieValue("center", request.getCookies ());
	String usr = cookx.getCookieValue("usertype", request.getCookies());


	/*String drugs = cookx.getCookieValueSpl("Drug", request.getCookies());
	String quantity = cookx.getCookieValueSpl("Qty", request.getCookies());
	String dose = cookx.getCookieValueSpl("Dose", request.getCookies());
	String duration = cookx.getCookieValueSpl("Dura", request.getCookies());
	String comments = cookx.getCookieValueSpl("Com", request.getCookies());*/

	String drugs = request.getParameter("drnam").trim();
	String quantity = request.getParameter("drquan").trim();
	String dose = request.getParameter("drdose").trim();
	String duration = request.getParameter("drdur").trim();
	String comments = request.getParameter("drcmnt").trim();
	out.println(drugs);
	out.println(quantity);			
	out.println(dose);
	out.println(duration);
	out.println(comments);
	dataobj obj = new dataobj();	
	obj.add("frmnam",request.getParameter("frmnam").trim().toLowerCase());
	obj.add("pat_id",request.getParameter("pat_id").trim());
	obj.add("entrydate",myDate.getCurrentDate("dmy",false));
	obj.add("apptdate",request.getParameter("apptdate").trim().replaceAll("/",""));
	//obj.add("diagnosis",request.getParameter("diagnosis").trim());
	obj.add("diagnosis","");
	obj.add("diet",request.getParameter("diet").trim());
	obj.add("activity",request.getParameter("activity").trim());
	//obj.add("advice",request.getParameter("advice").trim());
	obj.add("advice","");
	//Date d = new Date();
	//obj.add("preid", String.valueOf(d.getTime()));
	obj.add("preid", request.getParameter("preid"));
	out.println(request.getParameter("frmnam").trim().toLowerCase());
	out.println(request.getParameter("pat_id").trim());
	out.println(myDate.getCurrentDate("dmy",false));

	out.println(request.getParameter("apptdate").trim().replaceAll("/",""));
	/*nextaptdt format--> patid_Date*/
	String nextaptdt=id+"_"+request.getParameter("apptdate").trim().replaceAll("/","");
	cookx.addCookie("nextaptdt",nextaptdt,response);

	out.println(request.getParameter("diagnosis").trim());
	out.println(request.getParameter("diet").trim());
	out.println(request.getParameter("activity").trim());
	out.println(request.getParameter("advice").trim());

	obj.add("drugs",drugs);
	obj.add("quantity",quantity);
	obj.add("dose",dose);
	obj.add("duration",duration);
	obj.add("comments",comments);

	obj.add("name_hos",request.getParameter("cnam"));
	obj.add("docrg_no",request.getParameter("drgno"));
	
	obj.add("userid",userid);
	obj.add("center",ccode);
	obj.add("usertype",usr);
	
	out.println(userid);
	out.println(ccode);
	out.println(usr);
	out.println(request.getParameter("cnam"));
	out.println(request.getParameter("drgno"));

	String preid = request.getParameter("preid");

	// insert diagnosis
	
	String dg=request.getParameterValues("diagnosis")[0];
	String basic_diagnosis = request.getParameterValues("basic-diagnosis")[0].replaceAll("\\s+","");
	
	int basic_diagnosis_len = basic_diagnosis.split(";").length;
	int detailed_diagnosis_len = dg.split(";").length;
	//out.println(basic_diagnosis+" basic_diagnosis list>> "+basic_diagnosis.split(";").length);
	//out.println(dg+" diagnosis list>> "+dg.split(";").length);
	
	boolean blank_diag = false;
	
	if (basic_diagnosis_len == detailed_diagnosis_len){
		for (int i=0;i<basic_diagnosis.split(";").length;i++){
			if(basic_diagnosis.split(";")[i].length()==0)
				blank_diag = true;
		}
	
		if (!blank_diag){
			if(dg.charAt(dg.length()-1)!=';')
			{
				dg+=";";
			}
			String[] diags = dg.substring(0,dg.length()-1).split(";");
			if(basic_diagnosis.charAt(basic_diagnosis.length()-1)!=';')
			{
				basic_diagnosis+=";";
			}
			String[] basic_diags = basic_diagnosis.substring(0,basic_diagnosis.length()-1).split(";");	
			//if(diags != null){
				for(int d=0; d<diags.length; d++){
					dataobj dobj = new dataobj();
					if(diags[d].trim().length()> 0){
						//out.print("HERERER> "+diags[d].trim()+""+diags[d].trim());
							dobj.add("value", diags[d].trim());
							dobj.add("basic_diagnosis", basic_diags[d].trim());
							dobj.add("preid", preid);
							rcdef.insertDiagnosis(dobj);
					}
				}
			//}

			// insert observation and advice
			
			String ad=request.getParameterValues("advice")[0];
			if(ad.length()>0){
			if(ad.charAt(ad.length()-1)!=';')
			{
				ad+=";";
			}
			String[] advs = ad.substring(0,ad.length()-1).split(";");
			//if(advs != null){
				for(int a=0; a<advs.length; a++){
					dataobj aobj = new dataobj();
					if(advs[a].trim().length()>0){
					aobj.add("value", advs[a].trim());
					aobj.add("preid", preid);
					rcdef.insertObservationAndAdvice(aobj);
					}
				}
			//}
			}



			int ans = rcdef.InsertFrmAll(obj);
				if(ans==1){
						
					String currpatqtype = cookx.getCookieValue("currpatqtype", request.getCookies());

					try{

				//	rcDataEntryFrm rcdef = new rcDataEntryFrm(request.getRealPath("/"));
					int status = 0;
					if(currpatqtype.equalsIgnoreCase("local")){
						//rcdef.advicedConsultant(id,userid);
						//status = rcdef.moveLtoTreatedpatq(id);
					}
					else if(currpatqtype.equalsIgnoreCase("tele")){	
						//status = rcdef.moveTtoTreatedpatq(id);
						//rcdef.teleTreated(id, userid);
					}
					else{
						status = 0;
					}
					out.println("Done! ");
					}catch(Exception ex){out.println("ERROR09763 : "+ex.toString());}			
					
					
					//response.sendRedirect("");
					//response.sendRedirect("showlist.jsp");
				}else{
					//response.sendRedirect(".....jsp");
					out.println("Error");
				}
		}
		else{
			out.println("Basic diagnosis contains blank spaces.");
			}

	}
	else{
		out.println("Basic diagnosis contains blank spaces.");
		}
%>
