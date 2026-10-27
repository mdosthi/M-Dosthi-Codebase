<%@page language="java"  import= "imedix.rcUserInfo,imedix.medinfo,imedix.rcGenOperations,imedix.rcPatqueueInfo,imedix.rcCentreInfo,imedix.dataobj, imedix.cook,java.util.*,java.text.*,java.io.*, imedix.myDate"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%@page contentType="text/html" import="imedix.rcDisplayData" %>

<%
	cook cookx = new cook();
	String utyp=cookx.getCookieValue("usertype", request.getCookies());
	String usr=cookx.getCookieValue("userid", request.getCookies());

	rcUserInfo uinfo=new rcUserInfo(request.getRealPath("/"));
	String us, ps;
	boolean found=false;;

	rcPatqueueInfo rcpqi=new rcPatqueueInfo(request.getRealPath("/"));
    rcUserInfo rcui=new rcUserInfo(request.getRealPath("/"));
    rcGenOperations rcGen=new rcGenOperations(request.getRealPath("/"));
    medinfo minfo = new medinfo(request.getRealPath("/"));
	//rcCentreInfo rcci=new rcCentreInfo(request.getRealPath("/"));

	String ccode= cookx.getCookieValue("center", request.getCookies ());
	String cname = cookx.getCookieValue("centername", request.getCookies ());

	String sccode=request.getParameter("sccode");

    String searchDate=request.getParameter("searchDate");

	if(sccode==null) sccode=ccode;
	if(sccode.equals("")) sccode=ccode;
	String cond="active='Y' ";
	if(sccode.equals("XXXX")){
		cond+=" and center <> 'XXXX'  order by center,type,name";
	}else{
		cond+=" and center = '"+sccode+"'"+ " order by center,type,name";
	}

	String setDate="";
	Date cur_date = new Date();
	SimpleDateFormat dde = new SimpleDateFormat("dd/MM/yyyy");
	String today = dde.format(cur_date);
	setDate = today;	



%>
<%
	String rgno, suid,typ;
	try 
    {
        Object res=uinfo.getValues("name,uid,designation,emailid,phone,dis,rg_no,type,active,center,verified",cond);
		if(res instanceof String){

		out.println("<br><center><h1> No User Available</h1></center>");
		out.println("<br><center><h1> " +  res+ "</h1></center>");
	}
	else
    {
		Object Res = null;
        
        int total,firstpat,lastpat;
        String data="",del="";
	    boolean f=false;
        String chkName, id, idChk, Na, Cl, uNa,dte="",doc="",docname="",patName="",appdate="";
		boolean t=true;
		int count=0;

        String cnt = rcpqi.getTotalLPatAdmin2(ccode);
		if(cnt.equals("")) total=0;
		else total=Integer.parseInt(cnt);
        
        Res=rcpqi.getLPatqueueAdmin(ccode,0,total);
        DateFormat sdfo= new SimpleDateFormat("yyyy-MM-dd");
        String sd[]=searchDate.split("/");
        String sdd=sd[2]+"-"+sd[1]+"-"+sd[0];
        Date d1 = sdfo.parse(sdd);

		if(Res instanceof String)
        {
			out.println( "res :"+ Res);
		}
        else
        {
			Vector tmp = (Vector)Res;
			firstpat=0;
			lastpat=total;
			for(int i=1;i<=tmp.size();i++)
             { //recfrom
				dataobj temp = (dataobj) tmp.get(i-1);
                appdate=temp.getValue("appdate");
                if(!appdate.equals(""))
                {
                
                Date d2 = sdfo.parse(appdate);                                            
                if (d2.before(d1))
                {
                    doc=temp.getValue("referring_doctor");
                    if(doc!=null)
                    {
                        docname= rcui.getName(doc);
                    }
                    else
                    {
                        docname="--";
                    }

				id = temp.getValue("pat_id");
				//patName = temp.getValue("pat_name");
				patName=rcGen.getPatientName(id);
				String d = patName.substring(0,patName.indexOf(" "));
				String dd = minfo.getAppellationValues().getValue(d);
				patName = dd+" "+patName.substring(patName.indexOf(" "),patName.length());
				//Na = temp.getValue("pat_name");
				Na = "*";
				Cl = temp.getValue("class");
				Cl = Cl.replaceAll("<br>","");
				if (t==true) { out.println("<TR >");	t=false; }
				else { out.println("<TR >"); t=true; }

				f=true;
				count++;
				del=temp.getValue("checked");
                /*
				if(del.equals("Y"))
				{	out.println("<TD><Font color=red><B>"+(i+0)+"</B></Font></TD>");
					//out.println("<TD><Font color=red><B>"+i+"</B></Font></TD>");
				}
				else
				{	out.println("<TD><Font color=blue><B>"+(i+0)+"</B></Font></TD>");
					//out.println("<TD><B>"+i+"</B></TD>");
				}
                */
				//chkName = "SC" + Integer.toString(count);

				out.println("<TD>");
				out.println("<INPUT type='checkbox' name='ch' Value='"+id+"'>");
				out.println("</TD>");
				out.println("<td>"+patName+"</td>");
				if(utyp.equals("adm") || utyp.equals("sup") || utyp.equals("con") || utyp.equals("usr")){
					if(del.equals("Y")){
						out.println("<TD><B><A HREF='showpatdata.jsp?id="+id+"&usr=adm&nam="+Na+"&patdis="+Cl+"'><Font color=red>"+ id + 	"</Font></A></B></TD>");
						//out.println("<TD><B><A value='totalsummary.jsp?id="+id+"&usr=adm&nam="+Na+"&patdis="+Cl+"'  onclick=\"clearPanel(this.getAttribute('value'))\"><Font color=red>Summary</Font></A></B></TD>");

					}else{
						out.println("<TD><B><A HREF='showpatdata.jsp?id="+id+"&usr=adm&nam="+Na+"&patdis="+Cl+"'>"+ id + "</A></B></TD>");
					//	out.println("<TD><B><A value='totalsummary.jsp?id="+id+"&usr=adm&nam="+Na+"&patdis="+Cl+"'  onclick=\"clearPanel(this.getAttribute('value'))\">Summary</A></B></TD>");

					}

				}
				/*if(del.equals("Y"))  out.println("<TD><Font color=red>"+ Cl +"</Font></TD>");
				else out.println("<TD><Font color=blue>"+ Cl +"</Font></TD>");*/

				dte=temp.getValue("entrydate");

				if(del.equals("Y"))
				{
					//out.println("<TD><Font color=red>"+dte.substring(0,4)+"/"+dte.substring(5,7)+"/"+dte.substring(8,10) + "</Font></TD>");
					out.println("<TD><Font color=red>"+docname+"<Font></TD><!--<td class='status checked' pat-id = '"+id+"'><span class='glyphicon glyphicon-ok-circle'></span></td>-->");
				}
				else
				{
					//out.println("<TD><Font color=blue>"+dte.substring(0,4)+"/"+dte.substring(5,7)+"/"+dte.substring(8,10) + "<Font></TD>");
					out.println("<TD><Font color=blue>"+docname+"<Font></TD><!--<td class='status' pat-id = '"+id+"'><span class='glyphicon glyphicon-ban-circle'></span></td>-->");
				}
                out.println("<TD>"+sdfo.format(d2)+"</TD>");
				out.println("</TR>");
				//recfrom=recfrom+1;
				//if(recfrom > recto) break;
            }
        }
        else
        {
            doc=temp.getValue("referring_doctor");
				if(doc!=null) {
					docname= rcui.getName(doc);
				}
				else docname="--";

				id = temp.getValue("pat_id");
				//patName = temp.getValue("pat_name");
				patName=rcGen.getPatientName(id);
				String d = patName.substring(0,patName.indexOf(" "));
				String dd = minfo.getAppellationValues().getValue(d);
				patName = dd+" "+patName.substring(patName.indexOf(" "),patName.length());
				//Na = temp.getValue("pat_name");
				Na = "*";
				Cl = temp.getValue("class");
				Cl = Cl.replaceAll("<br>","");
				if (t==true) { out.println("<TR >");	t=false; }
				else { out.println("<TR >"); t=true; }

				f=true;
				count++;
				del=temp.getValue("checked");
                /*    
				if(del.equals("Y"))
				{	out.println("<TD><Font color=red><B>"+(i+0)+"</B></Font></TD>");
					//out.println("<TD><Font color=red><B>"+i+"</B></Font></TD>");
				}
				else
				{	out.println("<TD><Font color=blue><B>"+(i+0)+"</B></Font></TD>");
					//out.println("<TD><B>"+i+"</B></TD>");
				}*/

				//chkName = "SC" + Integer.toString(count);

				out.println("<TD>");
				out.println("<INPUT type='checkbox' name='ch' Value='"+id+"'>");
				out.println("</TD>");
				out.println("<td>"+patName+"</td>");
				if(utyp.equals("adm") || utyp.equals("sup") || utyp.equals("con") || utyp.equals("usr")){
					if(del.equals("Y")){
						out.println("<TD><B><A HREF='showpatdata.jsp?id="+id+"&usr=adm&nam="+Na+"&patdis="+Cl+"'><Font color=red>"+ id + 	"</Font></A></B></TD>");
						//out.println("<TD><B><A value='totalsummary.jsp?id="+id+"&usr=adm&nam="+Na+"&patdis="+Cl+"'  onclick=\"clearPanel(this.getAttribute('value'))\"><Font color=red>Summary</Font></A></B></TD>");

					}else{
						out.println("<TD><B><A HREF='showpatdata.jsp?id="+id+"&usr=adm&nam="+Na+"&patdis="+Cl+"'>"+ id + "</A></B></TD>");
					//	out.println("<TD><B><A value='totalsummary.jsp?id="+id+"&usr=adm&nam="+Na+"&patdis="+Cl+"'  onclick=\"clearPanel(this.getAttribute('value'))\">Summary</A></B></TD>");

					}

				}
				/*if(del.equals("Y"))  out.println("<TD><Font color=red>"+ Cl +"</Font></TD>");
				else out.println("<TD><Font color=blue>"+ Cl +"</Font></TD>");*/

				dte=temp.getValue("entrydate");

				if(del.equals("Y"))
				{
					//out.println("<TD><Font color=red>"+dte.substring(0,4)+"/"+dte.substring(5,7)+"/"+dte.substring(8,10) + "</Font></TD>");
					out.println("<TD><Font color=red>"+docname+"<Font></TD><!--<td class='status checked' pat-id = '"+id+"'><span class='glyphicon glyphicon-ok-circle'></span></td>-->");
				}
				else
				{
					//out.println("<TD><Font color=blue>"+dte.substring(0,4)+"/"+dte.substring(5,7)+"/"+dte.substring(8,10) + "<Font></TD>");
					out.println("<TD><Font color=blue>"+docname+"<Font></TD><!--<td class='status' pat-id = '"+id+"'><span class='glyphicon glyphicon-ban-circle'></span></td>-->");
				}
                out.println("<TD>-</TD>");
				out.println("</TR>");
				//recfrom=recfrom+1;
				//if(recfrom > recto) break;
            }
        
			} // end for
		   } // end if obj

	}


	}catch (Exception e) {
			out.println("SQL Error found <B>"+e+"</B>");
	}

%>