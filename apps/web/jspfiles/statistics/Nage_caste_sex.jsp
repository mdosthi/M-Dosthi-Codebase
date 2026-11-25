<%@page contentType="text/html" import="imedix.rcCentreInfo,imedix.dataobj,imedix.rcDisplayData, imedix.cook, java.util.*, java.io.*, imedix.myDate, java.text.SimpleDateFormat, org.json.simple.*, org.json.simple.parser.*" %>

<%
String setDate = "";
JSONObject statisticsData = new JSONObject();
setDate = myDate.getCurrentDate("dmy",true);
Date cur_date = new Date();
Calendar c = Calendar.getInstance();
c.setTime(cur_date);
c.add(Calendar.DATE, -7);
Date currentDateweekPast = c.getTime();
SimpleDateFormat dde = new SimpleDateFormat("dd/MM/yyyy");
String today = dde.format(cur_date);
String weekPastDate = dde.format(currentDateweekPast);

cook cookx = new cook();
String center = cookx.getCookieValue("center", request.getCookies());
String centername = cookx.getCookieValue("centername", request.getCookies());

String fromdt=request.getParameter("fromdt");
String todt=request.getParameter("todt");
String tag=request.getParameter("tag");

rcDisplayData display = new rcDisplayData(request.getRealPath("/"));
rcCentreInfo centerinfo = new rcCentreInfo(request.getRealPath("/"));

Object res=centerinfo.getAllCentreInfo();

String result="";
JSONObject centermap = new JSONObject();

if(tag.equalsIgnoreCase("religion_caste"))
{

    Object Res=display.CNT_stats_religion_caste(center,fromdt,todt);

    if(Res instanceof String)
        out.println("No data avaliable");
    else{
        Vector Vtmp = (Vector)Res;
        if(Vtmp.size()>0){

    for(int j=0;j<Vtmp.size();j++){
        dataobj datatemp = (dataobj) Vtmp.get(j);
                    
        
        String count=datatemp.getValue("count");
        String centre=datatemp.getValue("center");
        String caste_category=datatemp.getValue("caste_category");
        String religion=datatemp.getValue("religion");


        if(caste_category.equalsIgnoreCase("caste_category") )
            caste_category="";
        else if(caste_category.equalsIgnoreCase("general") )
            caste_category="General";
        else if(caste_category.equalsIgnoreCase("obc") )
            caste_category="OBC (Creamy Layer)";
        else if(caste_category.equalsIgnoreCase("obncl") )
            caste_category="OBC (Non Creamy Layer)";
        else if(caste_category.equalsIgnoreCase("sc") )
            caste_category="Schedule Caste";
        else if(caste_category.equalsIgnoreCase("st") )
            caste_category="Schedule Tribe";
        else if(caste_category.equalsIgnoreCase("notst") )
            caste_category="Not Stated";


        if(religion.equalsIgnoreCase("0") )
            religion="";
        else if(religion.equalsIgnoreCase("1") )
            religion="Buddhism";
        else if(religion.equalsIgnoreCase("2") )
            religion="Christianity";
        else if(religion.equalsIgnoreCase("3") )
            religion="Hinduism";
        else if(religion.equalsIgnoreCase("4") )
            religion="Islam";
        else if(religion.equalsIgnoreCase("5") )
            religion="Jainism";
        else if(religion.equalsIgnoreCase("6") )
            religion="Sikhism";
        else if(religion.equalsIgnoreCase("99") )
            religion="Other";                
        

        result+="<tr><td>"+centre+"</td>"+"<td>"+caste_category+"</td>"+"<td>"+religion+"</td>"+"<td>"+count+"</td></tr>";
    }

    }
    }
}
else{

    Object Res=display.CNT_stats_sex_caste(center,fromdt,todt,tag);


if(Res instanceof String)
	out.println("No data avaliable");
else{
	Vector Vtmp = (Vector)Res;
	if(Vtmp.size()>0){
       
		for(int j=0;j<Vtmp.size();j++){
			dataobj datatemp = (dataobj) Vtmp.get(j);
						
            
            String count=datatemp.getValue("count");
            String Tag=datatemp.getValue(tag);

            if(tag.equalsIgnoreCase("caste_category"))
            {
                if(Tag.equalsIgnoreCase("caste_category") )
                    Tag="";
                else if(Tag.equalsIgnoreCase("general") )
                    Tag="General";
                else if(Tag.equalsIgnoreCase("obc") )
                    Tag="OBC (Creamy Layer)";
                else if(Tag.equalsIgnoreCase("obncl") )
                    Tag="OBC (Non Creamy Layer)";
                else if(Tag.equalsIgnoreCase("sc") )
                    Tag="Schedule Caste";
                else if(Tag.equalsIgnoreCase("st") )
                    Tag="Schedule Tribe";
                else if(Tag.equalsIgnoreCase("notst") )
                    Tag="Not Stated";
            }
            else if(tag.equalsIgnoreCase("sex"))
            {
                if(Tag.equalsIgnoreCase("M") )
                    Tag="Male";
                else if(Tag.equalsIgnoreCase("F") )
                    Tag="Female";
                else if(Tag.equalsIgnoreCase("O") )
                    Tag="Other";
                else if(Tag.equalsIgnoreCase("N") )
                    Tag="Not Stated";
            }
            else if(tag.equalsIgnoreCase("religion"))
            {
                if(Tag.equalsIgnoreCase("0") )
                    Tag="";
                else if(Tag.equalsIgnoreCase("1") )
                    Tag="Buddhism";
                else if(Tag.equalsIgnoreCase("2") )
                    Tag="Christianity";
                else if(Tag.equalsIgnoreCase("3") )
                    Tag="Hinduism";
                else if(Tag.equalsIgnoreCase("4") )
                    Tag="Islam";
                else if(Tag.equalsIgnoreCase("5") )
                    Tag="Jainism";
                else if(Tag.equalsIgnoreCase("6") )
                    Tag="Sikhism";
                else if(Tag.equalsIgnoreCase("99") )
                    Tag="Other";
            }

            


            String ccenter=datatemp.getValue("center");
            

            //out.println(referring_doctor+"-"+docname);
            //result+="<tr><td>"+count+"</td>"+"<td>"+Tag+"</td>"+"<td>"+ccenter+"</td></tr>";
            result+="<tr><td>"+ccenter+"</td>"+"<td>"+Tag+"</td>"+"<td>"+count+"</td></tr>";

		}    
				
	}
    }
}
    out.println(result);

/*
<option value="caste_category">Caste Category</option>
		<option value="general">General
		</option><option value="obc">OBC (Creamy Layer)
		</option><option value="obncl">OBC (Non Creamy Layer)
		</option><option value="sc">Schedule Caste
		</option><option value="st">Shedule Tribe
		</option><option value="notst">Not Stated




            <select class="form-control" id="rel" name="religion" data-toggle="tooltip" data-placement="top" title="Religion">
                <option value="0">Choose Religion</option>
                <option value="1">Buddhism</option>
                <option value="2">Christianity</option>
                <option value="3">Hinduism</option>
                <option value="4">Islam</option>
                <option value="5">Jainism </option>
                <option value="6">Sikhism</option>
                <option value="99">Other</option>
            </select>            


            <select class="form-control" id="sex" name="sex" data-toggle="tooltip" data-placement="top" title="SEX">
                <option value="M">Male</option>
                <option value="F">Female</option>
                <option value="O">Other</option>
                <option value="N">Not Stated</option>
    </select>
*/

%>
