<%@page contentType="text/html" import="java.util.Date,java.text.SimpleDateFormat,imedix.layout,java.io.*,java.text.*,imedix.cook,imedix.Crypto,imedix.rcGenOperations,imedix.rcDisplayData,imedix.rcUserInfo,imedix.rcPatqueueInfo,imedix.dataobj,imedix.myDate,imedix.projinfo, java.util.*,org.json.simple.*,org.json.simple.parser.*,imedix.Crypto,javax.crypto.*" %>
<%@ include file="_patientAlldata.jsp" %>

<%!
public String listOfFomrs(String patid,String ftype,String slno,String dt, rcDisplayData ddinfo) throws Exception{
	String result="";
	int tag=0;
	Vector Vres;
	Vres = (Vector) ddinfo.getAttachmentAndOtherFrm(patid,ftype,slno,dt);

	Object Objtmp = Vres.get(1);
	if(Objtmp instanceof String){ tag=1;}
	else{
	Vector Vtmp = (Vector)Objtmp;
	if(Vtmp.size()>1 ) {
		String sn;
		result = "<SELECT class='form-control input-sm noofforms' NAME=abc >";
		//result += "<option></option>";
		for(int i=0;i<Vtmp.size();i++){
			dataobj datatemp = (dataobj) Vtmp.get(i);
			String pdt = datatemp.getValue("date");
			String dt3 = pdt.substring(8,10)+"/"+pdt.substring(5,7)+"/"+pdt.substring(0,4);
			sn=datatemp.getValue("serno");
			//out.println("dt3:-"+dt3+"sn:-"+sn);
			//if(sn.length()<2)  sn= "0" + sn;
			//result += "<option value='id="+patid+"&ty="+ftype+"&sl="+sn+"&dt="+pdt+"' >"+ftype+"-"+sn+"</option>";
			if(i<Vtmp.size()-2)
			result += "<option value='id="+patid+"&ty="+ftype+"&sl="+sn+"&dt="+pdt+"' >"+dt3+"-"+sn+"</option>";
			else
			result += "<option value='id="+patid+"&ty="+ftype+"&sl="+sn+"&dt="+pdt+"' selected>"+dt3+"-"+sn+"</option>";
		}
		result += "</SELECT>";
	}
	}
	return result;
}



%>

<%
	cook cookx = new cook();
	String patid = cookx.getCookieValue("patid", request.getCookies());
	String patname=cookx.getCookieValue("patname", request.getCookies());
	String patagem=cookx.getCookieValue("patagem", request.getCookies());
	String PatAgeYMD = cookx.getCookieValue("PatAgeYMD", request.getCookies());
	String sex = cookx.getCookieValue("sex", request.getCookies());
	String patdis = cookx.getCookieValue("patdis", request.getCookies());
	String username = cookx.getCookieValue("username", request.getCookies());
	String c_nam = cookx.getCookieValue("center", request.getCookies ());
	String uid = cookx.getCookieValue("userid", request.getCookies ());
	String currpatqtype = cookx.getCookieValue("currpatqtype",request.getCookies());
	String utype = cookx.getCookieValue("usertype",request.getCookies());
	String dat = myDate.getCurrentDate("dmy",false);
	String ty="";
	String patUpdateapptURL = "";
	if(currpatqtype.equalsIgnoreCase("local")) ty="pre";
	else ty="prs";
	patUpdateapptURL = (currpatqtype.equalsIgnoreCase("local"))?"commdoc2pat.jsp":"commdoc2tpat.jsp";

	String laptqlistObj = (String)session.getAttribute("lpatqlist");
	JSONParser lpatparser = new JSONParser();
	JSONArray lpatqlist = new JSONArray();
	String nextPat = "[]";
	if(laptqlistObj!=null){
		lpatqlist = (JSONArray)lpatparser.parse(laptqlistObj);
		nextPat = String.valueOf(lpatqlist);
	}
	//out.println(lpatqlist);
	//lpatqlist.remove(0);
	//out.println(lpatqlist);
	projinfo pr = new projinfo(request.getRealPath("/"));
	int allowedFileNo = Integer.parseInt(pr.maxFileUploadLimit);

	rcUserInfo uinfo = new rcUserInfo(request.getRealPath("/"));
	rcDisplayData ddinfom=new rcDisplayData(request.getRealPath("/"));
	rcPatqueueInfo rcpqi = new rcPatqueueInfo(request.getRealPath("/"));
	String pq = rcpqi.getTotalLPatAdmin(uid);

	Object res1 = (Object)ddinfom.getDataTeleRequest(c_nam,patid);
	Vector Vtmp1 = (Vector)res1;
	String doc_rgno = String.valueOf(Vtmp1.get(0));
	String assignDoc = uinfo.getName(doc_rgno);


	
String cdate=myDate.getCurrentDate("dmy",false);

String currdate=myDate.getCurrentDate("ymd",true);

if(patid != null && !patid.equals("")){

	//rcDisplayData ddinfo=new rcDisplayData(request.getRealPath("/"));
	//rcUserInfo uinfo = new rcUserInfo(request.getRealPath("/"));
	String r = uinfo.getreg_no(uid);

Date cur_date = new Date();
SimpleDateFormat dde = new SimpleDateFormat("dd/MM/yyyy");
String today = dde.format(cur_date);
//out.println(today);

int totalFile = Integer.parseInt(uinfo.fileUploadLimit(7,uid));
	//out.println("CURrent patq : "+currpatqtype);
%>

<%
String gen_exam_cn="",gen_exam_dt="",gen_exam_dt1="",gen_exam_sl="";
String chief_com_cn="",chief_com_dt="",chief_com_dt1="",chief_com_sl="";
String prc_cn="",prc_dt="",prc_dt1="",prc_sl="";
String advcInvs_cn="",advcInvs_dt="",advcInvs_dt1="",advcInvs_sl="";
//String ncd_cn="", ncd_dt="", ncd_dt1="", ncd_sl="";
String psy_cn="", psy_dt="", psy_dt1="", psy_sl="";

int gen_flag=0,chief_flag=0,prc_flag=0,psy_flag=0;
//ncd_flag=0;

Vector alldata=null;
Object res=null;
String timeStamp = new SimpleDateFormat("yyyy.MM.dd.HH.mm.ss").format(new Date());
Date date = new Date();
long timeMilli = date.getTime();
//System.out.println("PROFILING: patientAlldata.jsp before RMI call DisplayData:showAllLists started, TIME- "+timeStamp+"  IN Miliseconds:-"+timeMilli);
	alldata= (Vector)ddinfom.showAllLists(patid);
Date date2 = new Date();
long timeMilli2 = date2.getTime();
	String timeStamp2 = new SimpleDateFormat("yyyy.MM.dd.HH.mm.ss").format(new Date());
	//System.out.println("PROFILING: patientAlldata.jsp after RMi call DisplayData:showAllLists ended, TIME- "+timeStamp2+"  IN Miliseconds:-"+timeMilli2);

	res = (Object)alldata.get(0);
		if(res instanceof String){
				out.println("No Form");
		 }
		else{
			Vector Vtmp = (Vector)res;
			//if(Vtmp.size()>0 ) {
			if(Vtmp.size()>1 ) {
				for(int i=0;i<Vtmp.size();i++){
					dataobj datatemp = (dataobj) Vtmp.get(i);
					String pty = datatemp.getValue("type");
					//out.println(pty +" : "+ datatemp.getValue("serno"));
					//out.println("DATE:"+datatemp.getValue("date"));
					if(pty.equalsIgnoreCase("p47") && gen_flag==0){
						gen_exam_cn=datatemp.getValue("par_chl");
						gen_exam_dt = datatemp.getValue("date");
						gen_exam_dt1 = gen_exam_dt.substring(8,10)+"/"+gen_exam_dt.substring(5,7)+"/"+gen_exam_dt.substring(0,4);
						gen_exam_sl = datatemp.getValue("serno");
						gen_flag=1;
						//out.println("gen_exam_dt "+gen_exam_dt);

					}
					else if(pty.equalsIgnoreCase("a14") && chief_flag==0){
						chief_com_cn = datatemp.getValue("par_chl");
						chief_com_dt = datatemp.getValue("date");
						chief_com_dt1 = chief_com_dt.substring(8,10)+"/"+chief_com_dt.substring(5,7)+"/"+chief_com_dt.substring(0,4);
						chief_com_sl = datatemp.getValue("serno");
						chief_flag=1;
						//out.println("chief_com_dt "+chief_com_dt);
						//break;
					}
					else if(pty.equalsIgnoreCase("psyNotes") && psy_flag==0){
						psy_cn = datatemp.getValue("par_chl");
						psy_dt = datatemp.getValue("date");
						psy_dt1 = psy_dt.substring(8,10)+"/"+psy_dt.substring(5,7)+"/"+psy_dt.substring(0,4);
						psy_sl = datatemp.getValue("serno");
						psy_flag=1;					
					}
					else if((pty.equalsIgnoreCase("pre") || pty.equalsIgnoreCase("prs")) && prc_flag==0){
						prc_cn=datatemp.getValue("par_chl");
						prc_dt = datatemp.getValue("date");
						//out.println("Date:"+prc_dt);
						prc_dt1 = prc_dt.substring(8,10)+"/"+prc_dt.substring(5,7)+"/"+prc_dt.substring(0,4);
						prc_sl = datatemp.getValue("serno");
						prc_flag=1;
						//out.println("prc_dt "+prc_dt);
						//break;
					}

				}

			}
		}
//out.println("rrrrrrrrrrrrrr : "+noOfRecords("ai0",patid,request));
%>

<html>


	<!-- <script src="<%=request.getContextPath()%>/bootstrap/jquery-2.2.1.min.js"></script>	
	<script src="<%=request.getContextPath()%>/bootstrap/js/bootstrap.min.js"></script>	
	<script src="<%=request.getContextPath()%>/bootstrap/jquery-ui.min.js?"+n></script> -->

		<link rel="stylesheet" href="/e/bootstrap/bootstrap-datetimepicker.min.css">
	<script src="/M-Dosthi/bootstrap/bootstrap-datetimepicker.min.js"></script>
	<script src="/M-Dosthi/bootstrap/bootstrap-datetimepicker.pt-BR.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/html2canvas.js" type="text/javascript"></script>
	<SCRIPT LANGUAGE="JavaScript" SRC="../includes/script1.js"></SCRIPT>
<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/jquery-ui.css">

<style>

.ui-widget-content.ui-dialog
{
   border: 3px solid #337ab7;
}
.ui-dialog-titlebar {
      background:#337ab7;
	  color: #fff;
}
.ui-widget.ui-widget-content{z-index:1055 !important;}
.ui-menu.ui-autocomplete{
	overflow-y:auto;
	max-height:200px;
	}
.ui-menu:hover{overflow-x:hidden;}
.repeat-prescription{
    position: absolute;
    left: 5px;
    top: 4px;
    color: #0b7cde;
    cursor: pointer;
    font-weight: 600;
    padding: 8px 2px;
}
.ul-chf-complnt{
	overflow-y:auto;
	max-height:150px;
}
.diag-head span{
	background: #2775FC;
	color: #fff;
	}
.add-diag-btn{
	min-width: 0px !important;
    border-radius: 50% !important;
    cursor: pointer;
	}

	#submittedName{
		list-style-type: none;
		max-height: 150px;
		overflow-y: scroll;
	}
	#submittedName li{
		padding: 2px 4px;
		background: #bed0ec;
		border-radius: 6px;
		margin: 2px;
	}
	#submittedName li a {
		color: #fb2e2e;
		text-decoration: none;
		background: #ddbbbb;
		padding: 0px 5px;
		border-radius: 50%;
		font-weight: 800;	
		float: right;
	}	
<%-- 	.ul-ncd-screening .list-group-item{overflow:auto;} --%>
	.ul-psy-notes .list-group-item{overflow:auto;}

</style>
<script>



$(document).ready(function(){		
	 var availableTags = [];
	 $.ajax({
					type: "POST",
					url: "druglist.jsp",
					success: function(data)
					{
						 availableTags = JSON.parse(data);
					},
			complete:function(){
			 $(".drug-c").keydown(function(){
				 $( this).autocomplete({
					 source: availableTags
				 });
			 });
			}
		});
 });

//Soumya_B
$(document).ready(function(){
        $.ajax({
        			type: "POST",

            url: "tobaccoAssesment.jsp", // URL of the page to load
            success: function(result){
                $("#tobaccoAssesment").html(result); // Insert response into the div
            },
            error: function(){
                $("#tobaccoAssesment").html("<p>Failed to load content.</p>");
            }
        });
    });


//Soumya_B
$(document).ready(function(){
        $.ajax({
        			type: "POST",

            url: "tobaccoSurvey.jsp", // URL of the page to load
            success: function(result){
                $("#tobaccoSurvey").html(result); // Insert response into the div
            },
            error: function(){
                $("#tobaccoSurvey").html("<p>Failed to load content.</p>");
            }
        });
    });

//Soumya_B
$(document).ready(function(){
        $.ajax({
        			type: "POST",

            url: "getSimpleChatHistory.jsp", // URL of the page to load
            success: function(result){
                $("#getSimpleChatHistory").html(result); // Insert response into the div
            },
            error: function(){
                $("#getSimpleChatHistory").html("<p>Failed to load content.</p>");
            }
        });
    });


$(document).ready(function(){
		
	var totalFile = <%=totalFile%>;
	var noOFallowdfil = <%=allowedFileNo%>;
	var utype = "<%=utype%>";
	console.log("DD"+totalFile);
	if(totalFile>=noOFallowdfil && utype=="PAT")
		$(".upload-report").remove();

	var d = new Date();
	$(function () {
    	var startDate = new Date(d.getFullYear()+"-"+Number(d.getMonth()+1)+"-"+Number(d.getDate()+2)),
        endDate = new Date('2050-12-30');
		$('#from-datepicker').datetimepicker({
			weekStart: 1,
			todayBtn: 1,
			autoclose: 1,
			todayHighlight: 1,
			startView: 4,
			keyboardNavigation: 1,
			minView: 2,
			forceParse: 0,
			startDate: startDate,
			endDate: endDate,
			setDate: startDate
		});
	});
	$(function () {
    	var startDate = new Date('1955-10-10'),
        endDate = new Date(d.getFullYear()+"-"+Number(d.getMonth()+1)+"-"+Number(d.getDate()+1));
		$('#dot-datepicker').datetimepicker({
			weekStart: 1,
			todayBtn: 1,
			autoclose: 1,
			todayHighlight: 1,
			startView: 4,
			keyboardNavigation: 1,
			minView: 2,
			forceParse: 0,
			startDate: startDate,
			endDate: endDate,
			setDate: startDate
		});	

	});
	
	$(function () {
    	var startDate = new Date(d.getFullYear()+"-"+Number(d.getMonth()+1)+"-"+Number(d.getDate()+2)),
        endDate = new Date('2050-12-30');
	$('#dot-datepicker2').datetimepicker({
			weekStart: 1,
			todayBtn: 1,
			autoClose: true,
			autoHide: true,
			keepOpen: false,
			todayHighlight: 1,
			startView: 4,
			keyboardNavigation: 1,
			minView: 2,
			forceParse: 0,
			startDate: startDate,
			endDate: endDate,
			setDate: startDate
		});
	});

	$(".noofforms").change(function(){
		var data = $(this).val();
		var tname = data.split("ty=")[1].split("&")[0];
		var url = "_patientAlldata.jsp?"+$(this).val();
		//console.log("data: - "+data);
		//console.log("url: -"+url);

		switch(tname){
			case "p47" :
				$.get(url,function(data,status){
					$("ul.gen-exam").html(data);
				});
				break;
			case "a14" :
				$.get(url,function(data,status){
					$(".ul-chf-complnt").html(data);
				});
				break;
			case "psyNotes" :
				$.get(url,function(data,status){
					$(".ul-psy-notes").html(data);
				});
				break;				
			case "pre" :
				$.get("dispres1.jsp?"+data,function(data,status){
					$(".prc .prc-menu").html(data);
					//$(".prc .prc-menu").append(data);
				});
				break;
			default:
				console.log("def");
		}
	});
	$(".report-close").hide();
	$(".report-close").click(function(){
			$(this).next("div").html("");
			$(this).hide();
			$(".prc").attr("style","filter:blur(0px)");
	});
	<%if(Integer.parseInt(pq)>0 || !utype.equalsIgnoreCase("PAT")){%>
	<% if(!prc_dt.equals("")) { %>
	$.get("dispres1.jsp?id=<%=patid%>&ty=<%=ty%>&sl=<%=prc_sl%>&dt=<%=prc_dt%>",function(data,status){
		$(".prc .prc-menu").html(data);

		//$(".prc .prc-menu").append(data);
	});
	<% } %>

	$(".view-rpt .pre").parent("td").remove();
	$(".view-rpt .a14").parent("td").remove();
	$(".view-rpt .p47").parent("td").remove();

	$(".new-prc-btn").click(function(){
		if($('#patPres').hasClass('ui-dialog-content'))
		{
			$( "#patPres" ).dialog( "close" );	
		}
		$('.add-drug').html('');
		$( "#patPres" ).dialog( "open" );
		//$("#medTable > tbody").html("");
		//$(".add-drug tr").remove();
		$( "#medTable tbody tr" ).each( function(){
  			this.parentNode.removeChild( this ); 
		});
		$(".diagnosis_list").val("");
		//$(".advice").val("");
		$('[name="advice"]').val("");
	});
	


		/*$(".repeat-prescription .drug-del").click(function(){
			$(this).parent().parent("tr").remove();
			numOfRow=$('.add-drug tr').length;
			//console.log("TEST NUM-"+numOfRow);

	});

	$(".repeat-prescription").click(function(){
		$.post("repeatPrescription.jsp?id=<%=patid%>&ty=<%=ty%>&sl=<%=prc_sl%>&dt=<%=prc_dt%>",function(result,status){
			var output = JSON.parse(result);
			$(".diagnosis").val(output["diagnosis"]);
			$(".advice").val(output["advice"]);
		}).done(function(){
			$.get("showdrug.jsp?code=1",function(data,status){
				$(".add-drug").html(data);
			});				
		});
		$(".drug-edit").click(function(e){
			e.stopImmediatePropagation();
			$(" .drnam"+$(this).attr("row")).removeAttr("readonly");
			$(" .drquan"+$(this).attr("row")).removeAttr("readonly");
			$(" .drdose"+$(this).attr("row")).removeAttr("readonly");
			$(" .drdur"+$(this).attr("row")).removeAttr("readonly");
			$(" .drcmnt"+$(this).attr("row")).removeAttr("readonly");

			if($(this).hasClass("glyphicon-ok")){
				//$(".row"+$(this).parent("td").attr("row")+" textarea.description").hide();
				//$(this).parent("td").prev("td").children("p").html($(this).parent("td").prev("td").children("textarea").val());
				$(" .drnam"+$(this).attr("row")).attr("readonly",true);
				$(" .drquan"+$(this).attr("row")).attr("readonly",true);
				$(" .drdose"+$(this).attr("row")).attr("readonly",true);
				$(" .drdur"+$(this).attr("row")).attr("readonly",true);
				$(" .drcmnt"+$(this).attr("row")).attr("readonly",true);
			}
			$(this).toggleClass("glyphicon-ok");
			$(this).toggleClass("glyphicon-edit");

		});*/

	//});

	/* cheif complaint modal+vital sign modal */
	$(".new-comp-btn").click(function(){
		$.get("../forms/a14.jsp",function(data,status){
			$(".add-comp").html(data);
		});
	});
	$(".psy-notes-btn").click(function(){
		$.get("../forms/psychologistNotes.jsp",function(data,status){
			$(".add-psy-notes").html(data);
		});
	});
	
	$('#add_comp').on('hidden.bs.modal', function () {
	  $("#add_comp .modal-body").html("");
	  //$("#patPres").remove();
	  //location.reload(true);
	  //window.location.reload();
	  //window.location.href=window.location.href
	  //document.location.reload(true);
	});
	//$('#ncd_screening').on('hidden.bs.modal', function () {
	//  $("#ncd_screening .modal-body").html("");
	//});
	$('#add_psy_notes').on('hidden.bs.modal', function () {
	  $("#add_psy_notes .modal-body").html("");
	});	
	$('#add_vtsign').on('hidden.bs.modal', function () {
	  $("#add_vtsign .modal-body").html("");
	});

	$(".new-vtsign-btn").click(function(){
		$.get("../forms/p47.jsp",function(data,status){
			$(".add-vtsign").html(data);
		});
	});

	/* END cheif complaint modal+vital sign modal */
	
	$( function() {
    	//$( "#patPres" ).draggable();
	var presDiag = $( "#patPres" ).dialog({
               autoOpen: false,
			   width: 860,
			   height: 800,  
			   position: ['center','20'] ,
			   overflow:'scroll',
			   buttons: [{
           		text: "Continue",
				class: "btn btn-primary",
				click: function () {
					submit_form();
					}
			   }]
            });		
  	} );
	  $(document).on('click','.ui-dialog-titlebar-close',function(){
		  //alert("Prescription Closed")
			$("#patPres").dialog("close");
			//$("#patPres").remove();
			//$("#medTable > tbody").html("");
			//$(".add-drug tr").remove();
			$( "#medTable tbody tr" ).each( function(){
				this.parentNode.removeChild( this ); 
			});
			$(".advcd-test tr").remove();
			$(".diagnosis_list").val("");
			//$(".advice").val("");
			$('[name="advice"]').val("");
		});
	  
	function submit_form()
	{
		
	//	alert("Clicked");
	var dg=$('.diagnosis_list').val().trim();
	if(dg=="")
	{
		alert("Diagnosis field cannot be left blank");
		$('.diagnosis_list').focus();
		return false;
	}
	
	
	//$("#patPres").submit(function(e){
		var r = confirm("If you submit this prescription, it cannot be modified. Do you want to proceed?");
		if(r==false)
		{
			return false;
		}
		var numOfRow=$('.add-drug tr').length;
		var drnam="",drquan="",drdose="",drdur="",drcmnt="";
		//console.log("numOfRow:"+numOfRow);
		/*for(var i=0;i<numOfRow;i++)
		{
			//var row=$('.add-drug').find('tr').eq(i+1).attr("row");
			var row=$('.add-drug tr:eq('+(i)+')').attr("row");
			drnam+=$(" .drnam"+row).val()+"!";
			drquan+=$(" .drquan"+row).val()+"!";
			drdose+=$(" .drdose"+row).val()+"!";
			drdur+=$(" .drdur"+row).val()+"!";
			drcmnt+=$(" .drcmnt"+row).val()+"!";
		}*/
		/*const mySet = new Set()
		$(".add-drug tr").each(function(row, tr) 
		{
 		   	console.log("row:",$(this).attr("row"));
			var row=$(this).attr("row");
			mySet.add(row);
		});

		for (let item of mySet.keys())
		{ 		 
			var row=item;
			drnam+=$(" .drnam"+row).val()+"!";
			drquan+=$(" .drquan"+row).val()+"!";
			drdose+=$(" .drdose"+row).val()+"!";
			drdur+=$(" .drdur"+row).val()+"!";
			drcmnt+=$(" .drcmnt"+row).val()+"!";
		}*/
		$(".add-drug tr").each(function(row, tr) 
		{
 		   	console.log("row:",$(this).attr("row"));
			console.log("drug:",$(" .drnam"+row).val());
			var row=$(this).attr("row");
			drnam+=$(" .drnam"+row).val().replaceAll("!"," ")+"!";
			drquan+=$(" .drquan"+row).val().replaceAll("!"," ")+"!";
			drdose+=$(" .drdose"+row).val().replaceAll("!"," ")+"!";
			drdur+=$(" .drdur"+row).val().replaceAll("!"," ")+"!";
			drcmnt+=$(" .drcmnt"+row).val().replaceAll("!"," ")+"!";
		});

		$("#drnam").val(drnam);
		$("#drquan").val(drquan);
		$("#drdose").val(drdose);
		$("#drdur").val(drdur);
		$("#drcmnt").val(drcmnt);
		//console.log("drnam:"+drnam);
		//console.log("drquan:"+drquan);
		//console.log("drdose:"+drdose);
		//console.log("drdur:"+drdur);
		//console.log("drcmnt:"+drcmnt);


		var url="submitpres.jsp";

		var cd = new Date();
		var preid = cd.getTime();

		//var formData = new FormData($("#newPres"));
		
		console.log($("#patPres :input").serialize()+"&preid="+preid);
		var adv_data = $("div#invsAdvc :input").serialize();
		console.log(adv_data+"&preid="+preid);
		//$("div#invsAdvc").remove();
		$(".advcd-test tr").remove();
		$.ajax({
			type: "GET",
			url: url,
			data: $("#patPres :input").serialize()+"&preid="+preid,
			success: function(data)
			{
				// alert("done");
				// //sessionStorage.setItem("isPrescribed", "yes");
				// $('#patPres').modal('toggle');
				// $(".modal-backdrop").remove();
				// var ajax_load = "<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='loading...'>";
				// $(".main-body").html(ajax_load).load("patientAlldata.jsp?id=<%=patid%>");
			},
			error:function(erro)
			{
				console.log("errno : "+errno);
				alert("Write a new Prescription");
			},
			complete: function(){
				var url = "adviced_investigation_ajax.jsp";
				//console.log('advc-invs-frm: '+$("div#invsAdvc :input").serialize());
				$.ajax({
					type:"GET",
					url:url,
					data: adv_data+"&preid="+preid,
					success:function(data)
					{
						// $(".advcd-test").html("");
						// if(!$(".advc-invs-frm").children().hasClass("advice-disp")){
						// 	$(".advc-invs-frm").append("<div class='advice-disp'>"+data+"</div>");
						// }
						// if($(".advc-invs-frm").children().hasClass("advice-disp")){
						// 	$(".advice-disp").remove();
						// 	$(".advc-invs-frm").append("<div class='advice-disp'>"+data+"</div>");
						// }

						alert("done");
						//sessionStorage.setItem("isPrescribed", "yes");
						//$('#patPres').modal('toggle');
						
						//$(".modal-backdrop").remove();
						var ajax_load = "<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='loading...'>";
						$(".main-body").html(ajax_load).load("patientAlldata.jsp?id=<%=patid%>");
					},
					error:function(error){
						alert("Can not update it to the server");
					},
					complete:function(data){
						/*var presgenID = setInterval(function(){
							var encodedData = btoa($(".prc .prc-menu .prescription-ajax").html());
							var presuid = $(".prc .prc-menu .prescription-ajax").attr("id");
						    //console.log(presuid+"encoded data: "+encodedData);
						    if(presuid!=undefined && String(presuid).length>0){
							    $.post("prestopdf.jsp", {data: encodedData,presuid:presuid}, function(data){
							       // console.log(data.trim());
							       clearInterval(presgenID);
							    });	
						    }
						    else{
						    	console.log("Prescription file can not be generated ! "+presuid+"  " +String(presuid).length);
						    }
						}, 2000);*/	
					}					
				});
			}
		});
		//e.preventDefault();
	//});
	$("#patPres").dialog("close");
	$("#patPres").remove();
	//$("#medTable > tbody").html("");
	//$(".add-drug tr").remove();
	$( "#medTable tbody tr" ).each( function(){
  		this.parentNode.removeChild( this ); 
	});
	$(".diagnosis_list").val("");
	//$(".advice").val("");
	$('[name="advice"]').val("");
	}

		//console.log(<%=today%>);

	let patid = "<%=patid%>";
	var patlist = <%=nextPat%>; 
	var patqtype = "<%=currpatqtype%>";
	console.log("patlist: "+patlist);
	console.log("patid: "+patid);
	console.log("patqtype: "+patqtype);
	sessionStorage.setItem("patlist",patlist);
	sessionStorage.setItem("currentpat",patid);
	/*"Do not Set Appointment": function(evt){
						$.ajax({
							type: "post",
							url: "../jspfiles/unsetAppointment.jsp",
							data:{"uid": patid, "queue": patqtype},
							success: function(data){
								var dataJson = JSON.parse(data);								
								console.log(dataJson['message']);
								dialog.dialog( "close" );
							},
							complete:function(){
								if(patlist.length == 0){
									alert("There is no patient in the queue. Please goto local patient queue and set patient appointment.");
								}
								if(patlist.length > 1){
									let curPatIndex = patlist.indexOf(patid);
									let nextPatIndex = curPatIndex -1;
									if(curPatIndex == 0){
										nextPatIndex = patlist.length-1;
									}
									next = patlist[nextPatIndex];
									let searchP= location.search.replace("?","");
									searchP = searchP.replace(patid,next)
									window.location.href = "index1.jsp?"+searchP;
								}
							}
						});
					}*/
	$("#next-pat").click(function(){
		let delSts = false;		
		//if(sessionStorage.getItem("isPrescribed")!="yes")
			//delSts = confirm("Do you want to followup the patient later?\n If you Cancel, patient will be removed from the queue.");
		//console.log(patid+" Pat List: "+patlist);
			if(delSts==true){
				var patname = "<%=patname%>";
				alert('Please set an appointment date to '+patname+'.');
				var time = new Date();
					var stime = time.toLocaleString('en-IN', { hour: '2-digit', minute: '2-digit', hour12: true });
				var htmlbody = "<form>"+
							"<fieldset>"+
							"<ol>"+
							"<li><label for='meeting'>Appointment Date & Time </label>"+
							"<br><br>Date: <input type='date' name='Dt' id='Dt' class='text'> <br><br>"+
							"Time: <select name='Hr' id='Hr'></select> Hrs <select name='Mn' id='Mn'></select> Minutes <br><br>"+
							"</li>"+
							"<li>"+
							"<label for='Others'>Extra comments</label> </br>"+
							"<input name='Others' id='Others' size=25 maxlength=200> </br>"+
							"</li>"+
							"</ol>"+
							"<input type='submit' tabindex='-1' style='position:absolute; top:-1000px'>"+
							"</fieldset>"+
							"</form>";

				$("#dialog-form").html(htmlbody);
				
				$("#Dt").attr("value", today());
				$.get("nextAptDt.jsp",function(data,status){
					data=data.trim();
					var Today="<%=today%>";
					Today=Today.replace(/\//g, '');
					console.log("data:",data,"Today:",Today,today());
					if(!(data=='-1') && !(data==Today))
					{					
						//var ndat=data.substring(0,2)+"/"+data.substring(2,4)+"/"+data.substring(4);
						var ndat=data.substring(4)+'-'+data.substring(2,4)+'-'+data.substring(0,2);
						console.log("ndat:",ndat);
						$("#Dt").attr("value", ndat);
						//$("#Dt").readOnly = true;
						document.getElementById("Dt").readOnly = true;
					}
				});
				$( "#hr" ).html();
				$( "#Mr" ).html();
				for (let i=8; i<23; i++) $( "#Hr" ).append('<option value="'+i+'">'+i+'</option>');
				for (let i=0; i<59; i+=5) $( "#Mn" ).append('<option value="'+i+'">'+i+'</option>');

				dialog = $( "#dialog-form" ).dialog({
				  autoOpen: false,
				  height: 350,
				  width: 450,
				  modal: true,
					buttons: {
				Cancel: function() {
						dialog.dialog( "close" );
					},					
					"Set Appointment": function(evt) {
						buttonDomElement = evt.target;
						$(buttonDomElement).attr('disabled', true);
					var Dt = $("#Dt" ).val();
					var Hr = $("#Hr" ).val();
					var Mn = $("#Mn" ).val();
					var Oth = $("#Others").val();
					/*alert ( "meetingMail : " + meetingMail + "\n" +
										 "Meeting Time : " + Hr + ":" + Mn + "\n"+
						 "Others : " + Oth); */

					$.ajax({
						type: "post",
						url: "../jspfiles/<%=patUpdateapptURL%>",
						data:{'Dt':Dt, 'Hr':Hr, "Mn":Mn, "Others":Oth, "uid": patid, "uname": patname},
						success: function(data){
							//alert( "Data Loaded, Mail will be sent \n\n" + data.trim() );
							alert("Appoinment has been set");
							dialog.dialog( "close" );
						},
						complete:function(){
							$.ajax({
								type: "post",
								url: "patLTreatmentSts.jsp",
								data:{status:delSts,patid:patid,dateapp:Dt,patqtype:patqtype},
								success: function(data){
									patlist = JSON.parse(data.trim());
									if(patlist.length==0)
										alert("There are no more patient for consultation. Please goto patient queue and set patient appointment.");
								},
								complete:function(){
									if(patlist.length<1)
										$(this).prop("disabled",true);
									if(patlist.length>=1){
										let next = (patlist[0]==patid)?patlist[1]:patlist[0];
										let searchP= location.search.replace("?","");
										searchP = searchP.replace(patid,next)
										window.location.href = "index1.jsp?"+searchP;
									}
								}
							});
						}
					});
					/*$.post( "../jspfiles/commdoc2pat.jsp", {'Dt':Dt, 'Hr':Hr, "Mn":Mn, "Others":Oth, "uid": patid, "uname": patname}, function( data ) {
						alert( "Data Loaded, Mail will be sent \n\n" + data.trim() );
						dialog.dialog( "close" );
					});*/

				}

				   },
			   close: function() {
				//form[ 0 ].reset();
				//allFields.removeClass( "ui-state-error" );
				  }
				});

				dialog.dialog( "open" );
					 $("#meeting").focus();


			}
			else{
				//console.log("status:"+delSts+",patid:"+patid+",patqtype:"+patqtype);
				$.ajax({
					type: "post",
					url: "patLTreatmentSts.jsp",
					data:{status:delSts,patid:patid,patqtype:patqtype},
					success: function(data){
						console.log(data);
						patlist = JSON.parse(data.trim());
						//alert("Remaining patient: "+patlist.length);
						//console.log("patlist.length:-"+patlist.length);
						if(patlist.length==0)
							alert("There is no patient in the queue. Please goto local patient queue and set patient appointment.");
						//sessionStorage.removeItem("isPrescribed");
					},
					complete:function(){
						if(patlist.length<1)
							$(this).prop("disabled",true);
						if(patlist.length>=1){
							let next = (patlist[0]==patid)?patlist[1]:patlist[0];
							let searchP= location.search.replace("?","");
							searchP = searchP.replace(patid,next)
							window.location.href = "index1.jsp?"+searchP;
						}
					}
				});
			}
	});

	$("button.show-next-pat").click(function(){		
		if(patlist.length == 0){
			alert("There is no patient in the queue. Please goto local patient queue and set patient appointment.");
		}
		if(patlist.length > 1){
			let curPatIndex = patlist.indexOf(patid);
			let nextPatIndex = 0;
			if(curPatIndex < patlist.length -1){
				nextPatIndex = curPatIndex + 1;
			}			
			next = patlist[nextPatIndex];
			let searchP= location.search.replace("?","");
			searchP = searchP.replace(patid,next)
			window.location.href = "index1.jsp?"+searchP;
		}
	});

	$("button.show-prev-pat").click(function(){		
		if(patlist.length == 0){
			alert("There is no patient in the queue. Please goto local patient queue and set patient appointment.");
		}
		if(patlist.length > 1){
			let curPatIndex = patlist.indexOf(patid);
			let nextPatIndex = curPatIndex -1;
			if(curPatIndex == 0){
				nextPatIndex = patlist.length-1;
			}
			next = patlist[nextPatIndex];
			let searchP= location.search.replace("?","");
			searchP = searchP.replace(patid,next)
			window.location.href = "index1.jsp?"+searchP;
		}
	});


	$(".advc-invs-frm").submit(function(e){
		// var sdata = $("form#invsAdvc").serialize()+"&preid="+preid;
		// console.log("sdata: "+sdata);
		// e.preventDefault();
		// return;
		// var url = "adviced_investigation_ajax.jsp";
		// // $.ajax({
		// // 	type:"GET",
		// // 	url:url,
		// // 	data:$(".advc-invs-frm").serialize()+"&preid=123456789",
		// // 	success:function(data)
		// // 	{
		// // 		$(".advcd-test").html("");
		// // 		if(!$(".advc-invs-frm").children().hasClass("advice-disp")){
		// // 			$(".advc-invs-frm").append("<div class='advice-disp'>"+data+"</div>");
		// // 		}
		// // 		if($(".advc-invs-frm").children().hasClass("advice-disp")){
		// // 			$(".advice-disp").remove();
		// // 			$(".advc-invs-frm").append("<div class='advice-disp'>"+data+"</div>");
		// // 		}

		// // 	},
		// // 	error:function(error){
		// // 		alert("Can not update it to the server");
		// // 	}
		// // });
		// e.preventDefault();
	});
	<%}%>
	$(".advc-invs select").change(function(){
			$(".invest-desc").show();

			 if($(".radiology").val() !=""){
				 $('.pathology').prop('selectedIndex', 0);
				$(".pathology").attr("disabled",true);
				$('.tobaccoassessment').prop('selectedIndex', 0);  //Soumya
				$(".tobaccoassessment").attr("disabled",true);  //Soumya
				$(".invst-type").val("Radiology");
			}
			else if($(".pathology").val() !=""){
				$('.radiology').prop('selectedIndex', 0);
				$(".radiology").attr("disabled",true);
				$('.tobaccoassessment').prop('selectedIndex', 0);  //Soumya
				$(".tobaccoassessment").attr("disabled",true);  //Soumya

				$(".invst-type").val("Pathology");
			}
			else if($(".tobaccoassessment").val() !=""){
				$('.radiology').prop('selectedIndex', 0);  //Soumya
				$(".radiology").attr("disabled",true);  //Soumya
				$('.pathology').prop('selectedIndex', 0);  //Soumya
				$(".pathology").attr("disabled",true);  //Soumya

				$(".invst-type").val("TobaccoAssessment");  //Soumya
			}
			else{
				$(".advc-invs select").attr("disabled",false);
				$(".invst-type").val("");
				$(".test_id").val("");
			}
			if($(".radiology").prop("disabled") && $(".pathology").prop("disabled"))
			{
				$(".pathology").attr("disabled",false);
				$(".radiology").attr("disabled",false);
			}

	});
	$(".invest-desc").click(function(){$(".invest-desc").show();});
	$(".advc-invs select").focusout(function(){

			//$(".invest-desc").hide();
	});

	var count = (function(){
		var counter=0;
		return function(c){
			if (c==0){
				counter=0;
				return counter;
			}
			else{
				return counter+=1;
			}
		}
	})();
	var numOfRow=0;
	$(".add-advice-btn").click(function(){
		numOfRow+=1;
		//var radiology = ["X-RAY","MRI","CT SCAN","USG","ECG","EEG"];
		var radiology = ["X-RAY","MRI","CT SCAN","OTHERS"];
		var pathology = ["BILIRUBIN","GLUCOSE","SGPT","SGOT","CREATININE","URIC ACID","TOTAL CHOLESTROL","HDL","LDL","TRIGLYCERIDE","HAEMOGLOBIN","URINE","LIPID PROFILE","OTHERS"];
		var tobaccoassessment = ["FTND", "PHQ9","QSU", "AUDIT", "GAD7"];
		var counter = 0;
		var noOftest = 0;

		console.log($("select.tobaccoassessment").val()); //
		console.log($(".invest-desc textarea").val()); //FTND (description)
		console.log($(".invst-type").val()); //TobaccoAssessment
		console.log($("."+$(".invst-type").val().toLowerCase()+"").val());
		console.log(parseInt($("."+$(".invst-type").val().toLowerCase()+"").val()));
		console.log(eval($(".invst-type").val().toLowerCase())[parseInt($("."+$(".invst-type").val().toLowerCase()+"").val())]);

		if($("select.radiology").val().length>0 || $("select.pathology").val().length>0 || $("select.tobaccoassessment").val().length>0){ //Soumya
			if($(".invest-desc textarea").val().length>0 && !($("select.radiology").val().length>0 && $("select.pathology").val().length>0 && $("select.tobaccoassessment").val().length>0)){	//Soumya
				counter = count(1);
				noOftest = counter;
				//noOftest+=1;
				$(".invest-desc p.vld-msg").remove();
				$(".noOftest").val(noOftest);
				$(".advcd-test").append("<tr class='row"+counter+"'><td>"+noOftest+"</td>"+
				"<td>"+$(".invst-type").val()+"<input type='text' name='type"+counter+"' value='"+$(".invst-type").val()+"' hidden/></td>"+
				"<td>"+eval($(".invst-type").val().toLowerCase())[parseInt($("."+$(".invst-type").val().toLowerCase()+"").val())]+"<input type='text' name='test_name"+counter+"' value='"+$("."+$(".invst-type").val().toLowerCase()+"").val()+"' hidden/></td>"+
				"<td><p>"+$(".invest-desc textarea").val().trim()+"</p><textarea class='description' type='text' name='description"+counter+"' value='"+$(".invest-desc textarea").val().trim()+"' hidden>"+$(".invest-desc textarea").val().trim()+"</textarea></td>"+
				"<td class='mody-test' row='"+counter+"' align='center' ><span class='glyphicon glyphicon-edit invst-edit pull-left'></span><span class='glyphicon glyphicon-remove invst-del pull-right'></span></td></tr>");
			//$(".advice-btn").attr("style","display:block !important");
			}
			else{
				if(!$("p").hasClass("vld-msg"))
					$(".invest-desc").append("<p class='vld-msg' style='color:red'>Either Description is empty or test name is ambiguous.</p>");
			}
			//$("select.radiology").val('');
			//$("select.pathology").val('');
			$(".advc-invs select").attr("disabled",false);
			if(numOfRow>0) {
				//$(".advice-btn").prop( "disabled",false);
			}
			$('.radiology').prop('selectedIndex', 0);
			$('.pathology').prop('selectedIndex', 0);
			$('.tobaccoassessment').prop('selectedIndex', 0);  //Soumya
		}
		else{
			if(!$("p").hasClass("vld-msg"))
				$(".invest-desc").append("<p class='vld-msg' style='color:red'>Either Description is empty or test name is ambiguous.</p>");
		}

		$(".invest-desc textarea").val('').blur();

		var rowsize = $(".noOftest").val();

		$(".mody-test .invst-del").click(function(){
			$(this).parent().parent("tr").remove();
			//var tab=document.getElementsByClassName("advcd-test");
			//var row=tab.getElementsByTagName("tr");
			//console.log("rowlength:"+$('.advcd-test > * > tr').length);
			//console.log($('.advcd-test tr').length);
			//alert("total "+noOftest+ " i = " +i);
			//noOftest = noOftest-1;
			numOfRow=$('.advcd-test tr').length;
			//numOfRow-=1;
			console.log("TEST NUM-"+numOfRow);
			$(".noOftest").val(noOftest);
			if(numOfRow==0)
			{
				$(".advice-btn").prop( "disabled",true);
			}
			if(numOfRow<0)
			{
				numOfRow=0;
			}

			//alert(noOftest);
			//alert($(this).parent("tr").children().html());
		});

		$(".mody-test .invst-edit").click(function(e){
			e.stopImmediatePropagation();
			//$(this).parent().parent("tr").show();
			$(".row"+$(this).parent("td").attr("row")+" textarea.description").show();
			$(".row"+$(this).parent("td").attr("row")+" textarea.description").css("width","100%");

			if($(this).hasClass("glyphicon-ok")){
				$(".row"+$(this).parent("td").attr("row")+" textarea.description").hide();
				$(this).parent("td").prev("td").children("p").html($(this).parent("td").prev("td").children("textarea").val());
			}
			$(this).toggleClass("glyphicon-ok");
			$(this).toggleClass("glyphicon-edit");

		});
		$(".advice-btn").click(function(){
			counter = count(0);
			$(".advice-btn").prop( "disabled",true);
		});

	});
	
	var repCnt=0;
	$(".repeat-prescription").click(function(){
		$( "#medTable tbody tr" ).each( function(){
  			this.parentNode.removeChild( this ); 
		});
		//$(".add-drug tr").remove();
		//$("#medTable > tbody").html("");
		$(".diagnosis_list").val("");
		//$(".advice").val("");
		$('[name="advice"]').val("");
		//console.log("id="+"<%=patid%>","ty="+"<%=ty%>","sl=","<%=prc_sl%>","dt="+"<%=prc_dt%>");
		$.post("repeatPrescription.jsp?id=<%=patid%>&ty=<%=ty%>&sl=<%=prc_sl%>&dt=<%=prc_dt%>",function(result,status){
		
			var output = JSON.parse(result);
			//console.log("output:-",output);
			$(".diagnosis_list").val(output["diagnosis"]);
			$(".basic_diagnosis_list").val(output["basic_diag"])
			console.log("Basic diagnosis list>> "+JSON.stringify(output))
			$('[name="advice"]').val(output["advice"]);
			//$(".advice").val(output["advice"]);
			var ar=output["medicine"];
			//var cnt=$('.add-drug tr').length+1;
			var cnt=COUNTER;
			for(var i=0;i<ar.length;i++)
			{
				var drugquantity=ar[i]["quantity"];
				var drugdose=ar[i]["dose"];
				var drugduration=ar[i]["duration"];
				var drugname=ar[i]["drug"];
				var drugcomments=ar[i]["comment"];
				$(".add-drug").append("<tr style='background-color:#F7F3AC;' row='"+cnt+"' class='row"+cnt+"'><td ><textarea cols=15 class='drnam"+cnt+"' readonly>"+drugname+"</textarea></td>"+
				"<td ><textarea cols=10 class='drquan"+cnt+"' readonly>"+drugquantity+"</textarea></td>"+
				"<td ><textarea cols=10 class='drdose"+cnt+"' readonly>"+drugdose+"</textarea></td>"+
				"<td ><textarea cols=15 class='drdur"+cnt+"' readonly>"+drugduration+"</textarea></td>"+
				"<td ><textarea cols=15 class='drcmnt"+cnt+"' readonly>"+drugcomments+"</textarea><span class='glyphicon glyphicon-remove drug-del pull-right' style='color:red;top:0px;'></span><br><span class='glyphicon glyphicon-edit drug-edit pull-right ' style='color:green;bottom:5px;' row='"+cnt+"'></span></td></tr>");

				cnt=cnt+1;
				COUNTER=COUNTER+1;
			}
			repCnt=cnt;
			//console.log("repCnt:",repCnt,"cnt:",cnt);
			console.log("Repeat Prescription22>> "+$(".diagnosis_list").val().split(";")[0])
			let diagnosis_list = $(".diagnosis_list").val().split(";");
			for (i=0;i<diagnosis_list.length-1;i++)
				$("ul#submittedName").append("<li>" + diagnosis_list[i] + "&nbsp;<a class='delete' href='#'>X</a></li>");
			
			console.log("Basic_diagnosis>> "+output["basic_diag"].split(";").includes(" "));	
			let basic_diag_elements = output["basic_diag"].split(";");
			let _basic_diag_elements = basic_diag_elements.pop();
			if (basic_diag_elements.includes(" ") || basic_diag_elements.includes("")){
				alert("Prescription contains blank diagnosis. Please prescribe a new prescription");
				console.log("Basic_diagnosis>> "+output["basic_diag"].split(";"));
				$(".diagnosis_list").val("");
				$(".basic_diagnosis_list").val("")	
				$("ul#submittedName").html("")			
				$( "#patPres" ).dialog( "close" );
			}					
		});
		

			
		$( "#patPres" ).dialog( "open" );
		
		
		
		
	});



$("ul").on("click", ".delete", function(e) {
   $(this).closest('div.container').remove();
});
    $(function(){
		var given_diagnosis = "";
        $(".add-diag-btn").click((e) => {
            e.preventDefault();
            var diag=$(".diagnosis").val().replaceAll(";",",");
            var basic_diagnosis = $(".basic-diagn").val().replaceAll(";",",");
			if (diag.length>>0 && basic_diagnosis.length>>0){
				$("ul#submittedName").append("<li>" + diag + "&nbsp;<a class='delete' href='#'>X</a></li>");
				$(".diagnosis_list").val("");
				given_diagnosis = "";
				$('#submittedName li').each(function(i)
				{
					given_diagnosis +=  $(this).text().substring(0, $(this).text().length-2)+";";
				});	
				$(".diagnosis_list").val(given_diagnosis);
				$(".diagnosis").val("");
				var basic_diag = $(".basic_diagnosis_list").val()+$(".basic-diagn").val().replaceAll(";",",")+"; ";
				$(".basic_diagnosis_list").val(basic_diag);
				$(".basic-diagnosis").val("");		
				console.log("Diagnosis>> "+given_diagnosis);					
			}
			else{
				alert("Empty diagnosis can not be added");
			}
			


			
			
        });		
        
        $("ul").on("click", ".delete", function(e) {
			let list_index = $(this).closest('li').index();
            $(this).closest('li').remove();
			given_diagnosis = "";
			$('#submittedName li').each(function(i)
			{
				given_diagnosis +=  $(this).text().substring(0, $(this).text().length-2)+";";
			});
			console.log("Diagnosis after delete>> "+given_diagnosis);		
			

			$(".diagnosis_list").val(given_diagnosis);
			$(".diagnosis").val("");
			let basic_diag_list = $(".basic_diagnosis_list").val().split(";");
			basic_diag_list.splice(list_index, 1);
			basic_diag_list = basic_diag_list.toString().replaceAll(",",";");
			//alert(basic_diag_list);
			var basic_diag = basic_diag_list;
			$(".basic_diagnosis_list").val(basic_diag);
			$(".basic-diagnosis").val("");				
				
        });
	
	
	console.log("Repeat Prescription>> "+$(".diagnosis_list").val())
				
		
  });

/*	
	var given_diagnosis = "";
	$(".add-diag-btn").click(function(){
		if($(".diagnosis").val()!='')
		{ */
		//var format=/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]+/;
		//var format=/[!@#$^*\=\[\]{};':"\\|<>?]+/;
		/*var format=/[;]+/;
		if(format.test($(".diagnosis").val()))
		{
			alert('Please enter a valid Diagnosis (Special characters not allowed)');
			$(".diagnosis").val("");
			$(".diagnosis").focus();
			return false;
		}*/
		
		
		
/*		
		
		var diag=$(".diagnosis_list").val()+$(".diagnosis").val().replaceAll(";",",")+"; ";
		
		
			if (name.length>>0){
				$("ul#submittedName").append("<li>" + name + "&nbsp;<a class='delete' href='#'>X</a></li>");
				given_diagnosis = "";
				$('#submittedName li').each(function(i)
				{
					given_diagnosis +=  $(this).text()+";";
				});			
			}
			else{
				alert("Empty diagnosis can not be added");
			}		
		
		
		
		console.log(diag);
		$(".diagnosis_list").val(diag);
		$(".diagnosis").val("");
		var basic_diag = $(".basic_diagnosis_list").val()+$(".basic-diagn").val().replaceAll(";",",")+"; ";
		$(".basic_diagnosis_list").val(basic_diag);
		$(".basic-diagnosis").val("");		
		}

	});
	* */
	
	$(".add-adv-btn").click(function(){
		if($('[name="advi"]').val()!='')
		{
		//var format=/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]+/;
		//var format=/[!@#$^*\=\[\]{};':"\\|<>?]+/;
		/*var format=/[;]+/;
		if(format.test($('[name="advi"]').val()))
		{
			alert('Please enter a valid observation and advice (Special characters not allowed)');
			$('[name="advi"]').val("");
			$('[name="advi"]').focus();
			return false;
		}*/
		var adv=$('[name="advice"]').val()+$('[name="advi"]').val().replaceAll(";",",")+"; ";
		console.log(adv);
		$('[name="advice"]').val(adv);
		$('[name="advi"]').val("");
		}

	});
	COUNTER = 1;
	$(".add-drug-btn").click(function(e){
		e.preventDefault();
		//e.stopImmediatePropagation();
		//console.log($("#drugname").val());
		if(repCnt==0)
		{
			counter = count(1);
		}
		else {
			//counter=$('.add-drug tr').length+1;
			counter=repCnt;
			repCnt=repCnt+1;
		}
		console.log("repCnt:",repCnt);
		counter=$('.add-drug tr').length+1;
		// var drugname=$("#drugname").val().trim();
		// var drugquantity=$("#drugquantity").val().trim();
		// var drugdose=$("#drugdose").val().trim();
		// var drugduration=$("#drugduration").val().trim();
		// var drugcomments=$("#drugcomments").val().trim();

		var drugname=$('[name="drugname"]').val().trim().replaceAll("!"," ");
		var drugquantity=$('[name="drugquantity"]').val().trim().replaceAll("!"," ");
		var drugdose=$('[name="drugdose"]').val().trim().replaceAll("!"," ");
		var drugduration=$('[name="drugduration"]').val().trim().replaceAll("!"," ");
		var drugcomments=$('[name="drugcomments"]').val().trim().replaceAll("!"," ");
		
		//var format=/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]+/;
		var format=/[!@#$^*\={};'"\\|<>?]+/;
		/*if(format.test($('[name="drugname"]').val()))
		{
			alert('Please enter a valid drug name (Special characters not allowed)');
			$('[name="drugname"]').val("");
			$('[name="drugname"]').focus();
			return false;
		}*/

		console.log(drugname);
		if(drugname.length==0)
		{
			alert('Please enter a Drug Name');
			$("#drugname").focus();
			return false;
		}
		else{
			//counter=$('.add-drug tr').length;
		$(".add-drug").append("<tr style='background-color:#F7F3AC;' row='"+COUNTER+"' class='row"+COUNTER+"'><td ><textarea cols=15 class='drnam"+COUNTER+"' readonly>"+drugname+"</textarea></td>"+
		"<td ><textarea cols=10 class='drquan"+COUNTER+"' readonly>"+drugquantity+"</textarea></td>"+
		"<td ><textarea cols=10 class='drdose"+COUNTER+"' readonly>"+drugdose+"</textarea></td>"+
		"<td ><textarea cols=15 class='drdur"+COUNTER+"' readonly>"+drugduration+"</textarea></td>"+
		"<td ><textarea cols=15 class='drcmnt"+COUNTER+"' readonly>"+drugcomments+"</textarea><span class='glyphicon glyphicon-remove drug-del pull-right' style='color:red;top:0px;'></span><br><span class='glyphicon glyphicon-edit drug-edit pull-right ' style='color:green;bottom:5px;' row='"+COUNTER+"'></span></td></tr>");
		COUNTER=COUNTER+1;
		}
		$(".drug-del").click(function(){
			$(this).parent().parent("tr").remove();
			numOfRow=$('.add-drug tr').length;
			//console.log("TEST NUM-"+numOfRow);

		});

		$(".drug-edit").click(function(e){
			console.log($(this).attr("row"));
			e.stopImmediatePropagation();
			$(" .drnam"+$(this).attr("row")).removeAttr("readonly");
			$(" .drquan"+$(this).attr("row")).removeAttr("readonly");
			$(" .drdose"+$(this).attr("row")).removeAttr("readonly");
			$(" .drdur"+$(this).attr("row")).removeAttr("readonly");
			$(" .drcmnt"+$(this).attr("row")).removeAttr("readonly");

			if($(this).hasClass("glyphicon-ok")){
				//$(".row"+$(this).parent("td").attr("row")+" textarea.description").hide();
				//$(this).parent("td").prev("td").children("p").html($(this).parent("td").prev("td").children("textarea").val());
				$(" .drnam"+$(this).attr("row")).attr("readonly",true);
				$(" .drquan"+$(this).attr("row")).attr("readonly",true);
				$(" .drdose"+$(this).attr("row")).attr("readonly",true);
				$(" .drdur"+$(this).attr("row")).attr("readonly",true);
				$(" .drcmnt"+$(this).attr("row")).attr("readonly",true);
			}
			$(this).toggleClass("glyphicon-ok");
			$(this).toggleClass("glyphicon-edit");

		});
		$("#drugname").val("");
		$("#drugquantity").val("");
		$("#drugdose").val("");
		$("#drugduration").val("");
		$("#drugcomments").val("");		

	});
	$("body").delegate(".drug-del", "click", function(){
		//alert("Delete button clicked")
		$(this).parent().parent("tr").remove();
		numOfRow=$('.add-drug tr').length;
	});
	$("body").delegate(".drug-edit", "click", function(){
		//alert("Edit button clicked")
		console.log($(this).attr("row"));
		//e.stopImmediatePropagation();
		$(" .drnam"+$(this).attr("row")).removeAttr("readonly");
		$(" .drquan"+$(this).attr("row")).removeAttr("readonly");
		$(" .drdose"+$(this).attr("row")).removeAttr("readonly");
		$(" .drdur"+$(this).attr("row")).removeAttr("readonly");
		$(" .drcmnt"+$(this).attr("row")).removeAttr("readonly");

		if($(this).hasClass("glyphicon-ok")){
			//$(".row"+$(this).parent("td").attr("row")+" textarea.description").hide();
			//$(this).parent("td").prev("td").children("p").html($(this).parent("td").prev("td").children("textarea").val());
			$(" .drnam"+$(this).attr("row")).attr("readonly",true);
			$(" .drquan"+$(this).attr("row")).attr("readonly",true);
			$(" .drdose"+$(this).attr("row")).attr("readonly",true);
			$(" .drdur"+$(this).attr("row")).attr("readonly",true);
			$(" .drcmnt"+$(this).attr("row")).attr("readonly",true);
		}
		$(this).toggleClass("glyphicon-ok");
		$(this).toggleClass("glyphicon-edit");
	});

	$(".patSearch").remove();


	var ajax_load = "<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='loading...'>";
	$(".uploadedReport").html(ajax_load).load("recordmenu_new.jsp");

	$("body.index").removeClass("modal-open");



});


// function showselected()
// {
// 	var val=document.frm.abc.value;
// 	var tar;

// 	//alert(tar);
// 	window.location=tar;

// }

</script>

<!-- "Script for report uploading" -->


<script>
function today(){
    var date = new Date();
    var day = date.getDate();
    var month = date.getMonth() + 1;
    var year = date.getFullYear();
    if (month < 10) month = "0" + month;
    if (day < 10) day = "0" + day;
    var today = year + "-" + month + "-" + day;
return today;
}

function detailedDiagnosisList(){
	var list;
	console.log("HHH");
	$.ajax({
	  type: 'GET',
	  url: '../includes/detailed_diagnosis.json',
	  dataType: 'json',
	  success: function (detailed_diagnosis) {
		console.log("Check12", detailed_diagnosis);
		list = detailed_diagnosis;
		}
	});	
	return list;
}

console.log("ddd> ", detailedDiagnosisList());

	var detailed_diagnosis_group = {
		"SKIN":[
				"SKIN Boils",
				"SKIN Cellulitis",
				"SKIN Itching",
				"SKIN Tinea pedis",
				"SKIN Scabies",
				"SKIN Infected wound",
				"SKIN Abrasion",
				"SKIN Fungal infection",
				"SKIN Tinea corporis",
				"SKIN Tinea cruris",
				"SKIN Eczema",
				"SKIN Tinea versicolor",
				"SKIN Pyoderma",
				"SKIN Chicken pox",
				"SKIN Herpes zoster",
				"SKIN Measles",
				"SKIN Alopic dermatitis",
				"SKIN Seborric dermatitis",
				"SKIN Psoriasis",
				"SKIN Vitiligo",
				"SKIN Acne vulgaris",
				"SKIN Allergic dermatitis",
				"SKIN Cracked sole",
				"SKIN Papular urticaria"
			],
		"P/R":[
				"P/R Piles",
				"P/R Haemorrhoids",
				"P/R Bleeding piles",
				"P/R Fistula in ano",
				"P/R Fissure",
			],
		"PEM":[
				"PEM Mal nutrition"
			],
		"DENTAL":[
				"DENTAL Caries",
				"DENTAL Pyorrhoea",
				"DENTAL Gum swelling",
				"DENTAL Foul smell"	
			],
		"THYROID":[
				"THYROID Hypothyroidism",
				"THYROID Hyperthyroidism",
				"THYROID Goitre"			
			],
		"PUO":[
				"PUO Fever",
				"PUO Dengue",
				"PUO Bodyache",
				"PUO Malaria",
				"PUO Typhoid"			
			],
		"ENT":[
				"ENT Acute suppurative otitis media",
				"ENT Chronic suppurative otitis media",
				"ENT Oral ulcer",
				"ENT Stomatitis",
				"ENT Cheilosis",
				"ENT Earache",
				"ENT Sinusitis",
				"ENT Tonsillitis"			
			],
		"GASTRO":[
				"GASTRO Gastro-esophageal reflux",
				"GASTRO Hyperacidity",
				"GASTRO Gastroenteritis",
				"GASTRO Dyspepsia",
				"GASTRO Epigastric pain",
				"GASTRO Heart burn",
				"GASTRO Colitis",
				"GASTRO Constipation",
				"GASTRO Hepatitis",
				"GASTRO Jaundice",
				"GASTRO Ascites",
				"GASTRO Cirrhosis",
				"GASTRO Diarrhoea",
				"GASTRO Dysentry",
				"GASTRO Helminthiasis"					
			],
		"GYNAC":[
				"GYNAC PID",
				"GYNAC Water discharge",
				"GYNAC Cervicitis",
				"GYNAC Menopausal syndrome",
				"GYNAC Unhyginic condition",
				"GYNAC Menstural disorder",
				"GYNAC Vulvaitis",
				"GYNAC Leucorrhea candidiasis",
				"GYNAC Dysmenorrhea",
				"GYNAC Bulky uterus",
				"GYNAC Fibroied uterus",
				"GYNAC Leucorrhea veginosis",
				"GYNAC Leucorrhea trichomoniasis"			
			],
		"ARI":[
				"ARI URTI",
				"ARI LRTI",
				"ARI Allergic rhinitis",
				"ARI Sore throat",
				"ARI Common cold",
				"ARI Pharyngitis",
				"ARI Pneumonia"			
			],
		"HTN":[
				"HTN Hypertension",
				"HTN CHF(Congestive heart failure)",
				"HTN Angina"			
			],
		"DM":[
				"DM Diabetes mellitus",
				"DM Diabetes mellitus type1",
				"DM Diabetes mellitus type2",
				"DM Diabetic retinopathy",
				"DM Diabetic neuropathic",
				"DM Diabetic foot"			
			],
		"COPD":[
				"COPD Chronic obstructive pulmonary desease",
				"COPD Asthma",
				"COPD Bronchitis",
				"COPD Br. asthma"			
			],
		"ANEMIA":[
				"Anemia"		
			],
		"F/S":[
				"FS Food supplement"
			],
		"ANC":[
				"ANC Antenatal care"
			],
		"ORTHO":[
				"ORTHO Osteoarthritis",
				"ORTHO Polyarthritis",
				"ORTHO Osteoporosis",
				"ORTHO Lumber spondylosis",
				"ORTHO Fracture",
				"ORTHO Joint pain with swelling",
				"ORTHO Frozen shoulder",
				"ORTHO Joint stiffness",
				"ORTHO Low back pain", 
				"ORTHO Knee pain",
				"ORTHO Cervical spodylosis"
			],
		"NEURO":[
				"NEURO Polynuritis",
				"NEURO Neuropathic pain",
				"NEURO Paraplegia",
				"NEURO Paralysis",
				"NEURO Bells palsy",
				"NEURO Mylagia",
				"NEURO Trigeminal neurolgia",
				"NEURO Encephalitis",
				"NEURO Meningitis",
				"NEURO Lower Limb weakness"			
			],
		"UTI":[
				"UTI Urinary retension",
				"UTI Benign prostatic hyperplasia (BPH)",
				"UTI Burning micturatin",
				"UTI Renal calculi",
				"UTI Renal colic",
				"UTI Urine tract Infection",
				"UTI Nephrotic syndrome",
				"UTI Nephritis"			
			],
		"TB":[
				"TB Pulmonary tuberculosis",
				"TB Extra pulmonary",
				"TB Cold abscess",
				"TB Lymphadenitis",
				"TB Cervical lmphadenitis",
				"TB Axillary lymphadenitis",
				"TB Tubercular  meningitis",
				"TB Koch's abdomen"			
			],
		"EYE":[
				"EYE Cataract rt.eye",
				"EYE Cataract lt.eye",
				"EYE Conjunctivitis",
				"EYE Blepharitis",
				"EYE Pterygium",
				"EYE Vision problem",
				"EYE Redness and pain In eye",
				"EYE Diminished vision",
				"EYE Near vision",
				"EYE Watering", 
				"EYE Headache",
				"EYE Colour vision", 
				"EYE Night blindness",
				"EYE With glass vision", 
				"EYE Itching in eye",
				"EYE Others"		
			],
		"CMD":[
			"CMD 1.Intervention",
			"CMD 2.Initial stage",
			"CMD 3.Re covered patient",
			"CMD 4.Maintenance",
			"CMD 5.Disengage",
			"CMD 6.Planned discharge",
			"CMD Anxiety",
			"CMD Depression",
			"CMD Stress",
			"CMD Panic attack",
			"CMD Phobia",
			"CMD Attention siekness",
			"CMD Post traumatic stress disorder",
			"CMD OCD(obsessive compulsive disorder)"
			],

/*
		"SMDOthers":[
				"SMD Others 1.Intervention",
				"SMD Others 2. Initial stage",
				"SMD Others 3. Relapse",
				"SMD Others 4. Residual",
				"SMD Others 5. Remission",
				"SMD Others 6. Maintenace",
				"SMD Others 7. Disengage",
				"SMD Others 8. Re engage",
				"SMD Others 9. Planned discharge"
			],
		"SMDSchizophrenia":[
				"SMD Schizophrenia 1.Intervention",
				"SMD Schizophrenia 2. Initial stage",
				"SMD Schizophrenia 3. Relapse",
				"SMD Schizophrenia 4. Residual",
				"SMD Schizophrenia 5. Remission",
				"SMD Schizophrenia 6. Maintenace",
				"SMD Schizophrenia 7. Disengage",
				"SMD Schizophrenia 8. Re engage",
				"SMD Schizophrenia 9. Planned discharge"
			],
		"SMDBipolar":[
				"SMD Bipolar 1.Intervention",
				"SMD Bipolar 2. Initial stage",
				"SMD Bipolar 3. Relapse",
				"SMD Bipolar 4. Residual",
				"SMD Bipolar 5. Remission",
				"SMD Bipolar 6. Maintenace",
				"SMD Bipolar 7. Disengage",
				"SMD Bipolar 8. Re engage",
				"SMD Bipolar 9. Planned discharge"
			],
			*/
			
		"SMD":[
				"SMD Psychosis NOS",
				"SMD MR with behaviour problem",
				"SMD Addiction and substance abuse",
				"SMD Alzheimer",
				"SMD Brain atrophy",	
				"SMD Others 1.Intervention",
				"SMD Others 2. Initial stage",
				"SMD Others 3. Relapse",
				"SMD Others 4. Residual",
				"SMD Others 5. Remission",
				"SMD Others 6. Maintenace",
				"SMD Others 7. Disengage",
				"SMD Others 8. Re engage",
				"SMD Others 9. Planned discharge",	
				"SMD Schizophrenia 1.Intervention",
				"SMD Schizophrenia 2. Initial stage",
				"SMD Schizophrenia 3. Relapse",
				"SMD Schizophrenia 4. Residual",
				"SMD Schizophrenia 5. Remission",
				"SMD Schizophrenia 6. Maintenace",
				"SMD Schizophrenia 7. Disengage",
				"SMD Schizophrenia 8. Re engage",
				"SMD Schizophrenia 9. Planned discharge",
				"SMD Bipolar 1.Intervention",
				"SMD Bipolar 2. Initial stage",
				"SMD Bipolar 3. Relapse",
				"SMD Bipolar 4. Residual",
				"SMD Bipolar 5. Remission",
				"SMD Bipolar 6. Maintenace",
				"SMD Bipolar 7. Disengage",
				"SMD Bipolar 8. Re engage",
				"SMD Bipolar 9. Planned discharge"												
			],
		"EPILEPSY":[
				"Epilepsy 1. Intervention",
				"Epilepsy 2. Initial stage",
				"Epilepsy 3. Improvement level 1",
				"Epilepsy 4. Improvement level 2",
				"Epilepsy 5. Improvement level 3",
				"Epilepsy 6. Disengage",
				"EPILEPSY CPS TO GTCS/SLRE",
				"Epilepsy with MR",
				"Epilepsy with behavioural problem",
				"EPILEPSY Hyperactivity disorder",
				"EPILEPSY Febrile convulsion",
				"EPILEPSY Conversion disorder",
				"EPILEPSY Pseudo seizure"			
			],
		"OTHERS":[
				"Generalized swelling",
				"Generalized weakness",
				"Generalized anasarca",
				"Filariasis",
				"Varicose vein",
				"Chlamydia",
				"Vertigo",
				"Alcoholism",
				"Gonorrhea", 
				"Syphilis",
				"Dog bite",
				"Scorpion bite",
				"Snake bite",
				"Monkey bite",
				"Radiculopathy"			
			],
		"_blank":[
		
		]
		
	};


	
	function basicDiagnosisDropdown(arrItems){
			$.ajax({
			  type: 'GET',
			  url: '../includes/basic_diagnosis.json',
			  dataType: 'json',
			  success: function (basic_diagnosis) {
				//console.log("Check11", basic_diagnosis);
				$('#bsc-diagn').autocomplete({
					source: basic_diagnosis.sort(),
					change: function(){
						//detailed_diagnosis_group["OTHERS"] = detailed_diagnosis_group["OTHERS"].concat(arrItems)
						if ($("#bsc-diagn").val()!="OTHERS")
							$('#detailed-diagn').val($("#bsc-diagn").val()+" ");
						else
							$('#detailed-diagn').val("");
						console.log("Checkpoint1> "+$("#bsc-diagn").val().replace(/ /g,"")) 
						filtered_diagnosis = detailed_diagnosis_group[$("#bsc-diagn").val().replace(/ /g,"")];
						},
					select: function(){$('#detailed-diagn').val("");},
					minLength: 0,
					scroll: true,
					appendTo : $('#patPres')
				}).focus(function() {
					$(this).autocomplete("search", "");
				});					
				
			  }
			});			

		}
	function detailedDiagnosisDropdown(){


			
			$('#detailed-diagn').autocomplete({
				source: function (req, resp){
							var searchString = req.term;
	
							let matchingStrings = [];
							filtered_diagnosis.forEach((list) => {
								if (list.toLocaleLowerCase().search(searchString.toLocaleLowerCase()) > -1) {
									matchingStrings.push(list)
								}
							})
							resp(matchingStrings.sort());						  				
					},
				/* Searh from the begining
				 * source: function(req, resp) {
						  var q = req.term;
						  var texout = [];
						  $.each(filtered_diagnosis, function(key, item) {
							if (item.toLowerCase().indexOf(q) === 0 || item.toUpperCase().indexOf(q) === 0 || item.indexOf(q) === 0) {
							  texout.push(item);
							}
						  });
						  resp(texout);
						},*/
				//source: filtered_diagnosis,
				minLength: 0,
				scroll: true,
				appendTo : $('#patPres')
			}).focus(function() {
				console.log(filtered_diagnosis);
				$(this).autocomplete("search", "");
			});			
		
		}




$(document).ready(function(){

/*	
	$(".clear-btn").click(function(){
		$(".basic_diagnosis_list").val("");
		$(".diagnosis_list").val("");
	});
	*/
	
	detailedDiagnosisList()
	var filtered_diagnosis = detailed_diagnosis_group["_blank"];
			
	$.getJSON('../includes/disease.json', function(jd) {
		var arrItems = [];      // THE ARRAY TO STORE JSON ITEMS.
            $.each(jd, function (index, value) {
                arrItems.push(value);       // PUSH THE VALUES INSIDE THE ARRAY.
            });
		//console.log("jd:"+arrItems);
		
		basicDiagnosisDropdown(arrItems) // arrItems is the list of diagnosis which is concat with others basic diagnosis
		detailedDiagnosisDropdown()	
		
	});
	
	var arrItems1=[
				"DIABETIC DIET (SUGAR, RICE, PATATO RESTRICTED)",
				"WALKING DAILY IN MORNING and EVENING",
				"SIT ALWAYS ON A CHAIR",
				"AVOID PILLOW",
				"SIT ON A CUSHION",
				"APPLY COLLAR IN NECK",
				"APPLY CRAEP BANDAGE",
				"APPLY BETADIN FOR DRESSING",
				"DRINK PLENTY OF WATER",
				"ALKASOL SYP 2TSF BD WITH 1CUP OF WATER",
				"GARGIL WITH WARM WATER",
				"GARGIL WITH HAXEDINE 5mL WITH 1GLASS OF WATER",
				"GARGIL WITH BETADINE MOUTH WASH BD WITH 1CUP OF WATER",
				"FOMENTATION WITH HOT AND COLD WATER ALTERNATELY",
				"APPLY TURPENTINE LINIMENT LOCALLY",
				"AVOID TOBACCO USE",
				"AVOID ALCOHOL",
				"AVOID CANNABIS",
				"AVOID WATCHING TELEVISION",
				"AVOID LATE NIGHT SLEEPING HABITS",
				"AVOID OILY RICH , SPICY AND JUNK FOOD OR FAST FOOD",
				"EAT 1 OR 2 AMLA FRUITS DAILY",
				"DAILY EAT GREEN LEAFY  VEGETABLES",
				"DAILY EAT JAGGERY , BLACK SESAME",
				"DAILY EAT TOMATOES AND CITRUS FRUITS",
				"DAILY EXERCISE AND YOGA FOR 30 MINUTES",
				"DAILY USE SOAP FOR BATH AND HANDWASH",
				"DAILY WASH COTTON CLOTHS WITH HOT WATER  AND DETERGENT POWDER",
				"DRY YOUR CLOTHS IN SUNLIGHT"];
	$('.advice').autocomplete({
   			 source: arrItems1,
			onSelect: function (suggestion) {
				console.log('You selected: ' + suggestion.value + ', ' + suggestion.data);
			}
		});		

	var modalityList = "<option value='' class='modalityList' selected>SELECT</option>";
	$.getJSON('../includes/investigationList.json', function(jd) {
	//	console.log("jd:"+jd);
		for(let i=0;i<jd.length;i++)
			modalityList += "<option value='"+i+"' class='modalityList'>"+jd[i].modality+"</option>";
		$(".modality").html(modalityList);
		$(".modality").on("change", function(){
			let testName = jd[$(this).val()].testname;
			  console.log(testName);
			$( "#testdes" ).autocomplete({
			  source: testName
			});
		});

	});

	var modalityList2 = "<option value='' class='modalityList' selected>SELECT</option>";
	$.getJSON('../includes/pathology_investigationList.json', function(jd) {
		for(let i=0;i<jd.length;i++)
			modalityList2 += "<option value='"+i+"' class='modalityList'>"+jd[i].modality+"</option>";
		$(".pathoModality").html(modalityList2);
		$(".pathoModality").on("change", function(){
			let testName = jd[$(this).val()].testname;
			  console.log(testName);
			$( "#testdes" ).autocomplete({
			  source: testName
			});
		});

	});

	<%-- var tobAss = ["FTND", "PHQ9","QSU"];
	var modalityList3 = "<option value='' class='modalityList' selected>SELECT</option>";
	for(let i=0;i<tobAss.length;i++)
		modalityList3 += "<option value='"+i+"' class='modalityList'>"+tobAss[i]+"</option>";
	$(".tobAssModality").html(modalityList3);
	$(".tobAssModality").on("change", function(){
		let testName = jd[$(this).val()].testname;
		  console.log(testName);
		$( "#testdes" ).autocomplete({
		  source: testName
		});
	}); --%>

	var modalityList3 = "<option value='' class='modalityList' selected>SELECT</option>";
	$.getJSON('../includes/tobaccoAssessment_investigationList.json', function(jd) {
		for(let i=0;i<jd.length;i++)
			modalityList3 += "<option value='"+i+"' class='modalityList'>"+jd[i].modality+"</option>";
		$(".tobAssModality").html(modalityList3);
		$(".tobAssModality").on("change", function(){
			let testName = jd[$(this).val()].testname;
			  console.log(testName);
			$( "#testdes" ).autocomplete({
			  source: testName
			});
		});

	});





	$("#apptdate").val($("#datepicker-apptdate").val().replace(/\//g, ''));
	$('#dot-datepicker2').on('changeDate', function(e) {
       $("#apptdate").val($("#datepicker-apptdate").val().replace(/\//g, ''));
	   console.log($("#apptdate").val());
	   
    });

<%if(Integer.parseInt(pq)>0 || !utype.equalsIgnoreCase("PAT")){%>
	 $("#testdate").val($("#datepicker-testdate").val().replace(/\//g, ''));
	$('#dot-datepicker')
    .on('changeDate', function(e) {
       $("#testdate").val($("#datepicker-testdate").val().replace(/\//g, ''));
    });

<% } %>
$("#reportUpload").submit(function(e){
	e.preventDefault();
	if(testdt($(this).find("#testdate").val(),'<%=dat%>')) return false;
	var data = new FormData(this);
	var uploadedFile = Number(<%=totalFile%>);

	$.ajax({
		type: "get",
		url: "noFileUploaded.jsp",
		success: function(data){
			uploadedFile = Number(data.trim());
		},
		complete:function(){
			let noAllowdFile = Number(<%=allowedFileNo%>);
			console.log(uploadedFile+" TT:TT "+noAllowdFile);
			if(uploadedFile<noAllowdFile){
				$.ajax({
					type:"POST",
					enctype: "multipart/form-data",
				//	url:"../servlet/uploadfilehttp",
					url:"../largefileupload/UploadFile.jsp",
					data:data,
					processData: false,
					contentType: false,
					cache: false,
					timeout: 600000,
					beforeSubmit : filluptextForm(),
					success:function(data){
						console.log(Number(data.trim())+"Uplodstatus"+data.trim());

						var ajax_load = "<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='loading...'>";
						$("#drop_div_html").html("Drop Here/Select File");
						$("#reportUpload")[0].reset();
							$("#reportUpload").append("<div class='uploading-report'>Uploading.....</div>");
						//$.post("../largefileupload/savepatchlfupload.jsp",{ftype:""+$("#Lftype").val()+"",ext:""+fileExtd+"",docName:""+$("#LdocName").val()+"",lname:""+$("#Llname").val()+"",desc:""+$("#Ldes").val()+""},function(data){
							$.post("/M-Dosthi/servlet/largefileupload",{stream:"<%=patid%>&"+$("#Lftype").val()+"&"+$("#Ldes").val()+"&"+$("#Llname").val()+"&"+$("#LdocName").val()+"&<%=currdate%>&<%=cdate%>&"+fileExtd.substring(1)+""},function(data){
							console.log("<%=patid%>&"+$("#Lftype").val()+"&"+$("#Ldes").val()+"&"+$("#Llname").val()+"&"+$("#LdocName").val()+"&<%=currdate%>&<%=cdate%>&"+fileExtd.substring(1)+"");
							$(".uploadedReport").html(ajax_load).load("recordmenu_new.jsp");
							$(".uploading-report").remove();
							alert("Data is Uploaded !");
							});
						},
					error:function(data){console.log(data);alert("Could not uploaded");}
				});
			}
			else{
				alert("You can upload maximum "+uploadedFile+" files only.");
				$(".upload-report").remove();
			}
		}
	});
});





	$("#smallFile").change(function(){
		$("#drop_div_html").html(document.getElementById("smallFile").files[0].name+"<br><center>"+fileSizeCheck()+"</center>");
	});
	$("select[name=type]").change(function(){
		fileTypeChk(this.value);
		$("#Lftype").val(this.value);
	});

});


function removeFile(){

}
var fileExtd;
function filluptextForm(){
$("#Ldes").val($("input[name=imgdesc]").val());
$("#Llname").val($("input[name=lab_name]").val());
$("#LdocName").val($("input[name=doc_name]").val());
$("#Lftype").val($(".report-type").val());
	var file = document.getElementById('smallFile').files[0].name;
	 fileExtd = file.substring(file.lastIndexOf("."),file.length);
		$("#Lext").val(fileExtd);
}


function fileTypeChk(fTyps){
	var file = document.getElementById('smallFile').files[0].name;
	var fileExt = file.substring(file.lastIndexOf(".")+1,file.length);
	var obj = {
		"BLD":["png","jpeg","jpg","bmp"],
		"CTS":["png","jpeg","jpg","bmp"],
		"DCM":["dcm"],
		"DOC":["doc","docx","pdf","txt"],
		"EEG":["png","jpeg","jpg","bmp"],
		"MRI":["png","jpeg","jpg","bmp"],
		"MOV":["mp4","avi","mov","wmv"],
		"SEG":["png","jpeg","jpg","bmp"],
		"SKP":["png","jpeg","jpg","bmp"],
		"SNG":["png","jpeg","jpg","bmp"],
		"SND":["mp3","wav"],
		"TEG":["txt"],
		"XRA":["png","jpeg","jpg","bmp"],
		"OTH":["png","jpeg","jpg","bmp"]
		}
			if(obj[fTyps].indexOf(fileExt.toLowerCase())>=0){
				return true;
			}
			else{
				var msg = confirm("Supported file is ["+obj[fTyps]+"]" +" Do you want to remove the file ?");
				if(msg==true){
					document.getElementById('smallFile').value="";
					$("#drop_div_html").html("Drop Here/Select File");
					return true;
				}
				else{
					return false;
				}
			}
}

function drop_evt(evt) {
	evt.preventDefault();
	try{
		document.getElementById("smallFile").files = evt.dataTransfer.files;
		document.getElementById("drop_div_html").innerHTML=evt.dataTransfer.files[0].name+"<br><center>"+fileSizeCheck()+"</center>";
	}catch(err){}
}
function dragOver_evt(evt) {
  evt.preventDefault();
}
function setvalues() {
	document.imgld.desc.value = document.imgld.type.value + " File";
}
function datentry(){
	document.imgld.entrydate.value=GetMysqlCurrDateTime();
}

function MM_displayStatusMsg(msgStr) { //v1.0
  status=msgStr;
  document.MM_returnValue = true;
}
//-->

function fileCheck(){
	if(document.getElementById('smallFile').value=="" || document.getElementById('smallFile').value == null){
		alert("Choose a file");
		return false;
	}
	else if($(".report-type").val().length==0){
		alert("SELECT FILE TYPE");
		return false;
	}
	else
		fileTypeChk($(".report-type").val());

	return true;
}
function fileSizeCheck(){

	var sizeinbytes = document.getElementById('smallFile').files[0].size;
	var sizekb=sizeinbytes/1024;
	if(sizekb>=990){
	//alert(sizekb);
		//return (sizekb/1024).toFixed(2)+" MB";
		let mb = Math.floor((sizekb/1024));
		//alert("MB: "+mb);
		if(mb > 9){
			document.getElementById('smallFile').value="";
			return  "Please upload less then 10 mb file";
			}
	}
	else{
		return sizekb.toFixed(2)+" KB";
	}
}


</script>


<!-- "Script for report uploading END" -->





<style>
.advc-invs .input-group-addon, .diag-head .input-group-addon {
	min-width:13.2rem;
}
.drop-div{
    border: 1px dashed #59a7ec;
    height: 80px;
    position: relative;
    text-align: center;
    margin: 4px 0;
	word-wrap: break-word;
    padding: 0 5px;
}
#drop_div_html{color:blue;font-weight:600;}
#smallFile{
	position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    opacity: 0;
}
.clear-btn{
	float: right;
    font-size: 12px;
    margin-top: 4px;
    background: #ffc107;
    border: none;
    color: black;
    border-radius: 10%;
}	
	}
.pat-head-title{display:none;}
.uploadedReport a{text-decoration:none;}
</style>

	<body style="font-size:18px;color:#000;">
		<div class="container-fluid patientalldata">
		<%if(utype.equalsIgnoreCase("DOC")){%>
		<div class="row" style="margin-bottom: 5px;">
			<div class="col-sm-4 text-left">
				<button class="btn btn-primary show-prev-pat" title="Skip to the Previous Patient"><span class="glyphicon glyphicon-arrow-left" aria-hidden="true"></span></button>
			</div>
			<div class="col-sm-4 text-center">
				<div><button class='btn btn-primary next' id='next-pat' title="Visit Next Patient">Next Patient</button></div>
			</div>
			<div class="col-sm-4 text-right">
				<button class="btn btn-primary show-next-pat" title="Skip to the Next Patient"><span class="glyphicon glyphicon-arrow-right" aria-hidden="true"></span></button>
			</div>
		</div>
		
		<%}%>
		<div class="container-fluid patientalldata">

			<div class="row">
				<div class="pat-summ">
					<div class="sec1">
						<div class="col-sm-3 name"><label>NAME : </label><span><%=patname%></span></div>
						<div class="col-sm-3 age"><label>AGE : </label><span><%=PatAgeYMD%></span></div>
						<div class="col-sm-3 sex"><label>SEX : </label><span><%=sex%></span></div>
						<div class="col-sm-3 dept"><label>DEPARTMENT : </label><span> <%=patdis%></span></div>
					</div>
					<div class="sec2">
						<div class="col-sm-6 reff-doc"><label>Under treatment : </label><span id="appDoc"></span><span></span></div>
						<div class="col-sm-3 date"><label>Last Visit DATE : </label><span><%=prc_dt1%></span></div>
						<div class="col-sm-3 date"><label>Communicate : </label>
<% if(!utype.equalsIgnoreCase("PAT")){%>
	<a class="online" href="#" title="Send email to patient" onclick="sendMail('<%=patid%>','<%=patname%>')"><span class="glyphicon glyphicon-envelope" aria-hidden="true"></span></a>
	<a data-patid="<%=patid%>" class="offline pat-video-link" href="#" title="Invite patient for Video Conference" onclick="invite('<%=patid%>','<%=patname%>')"><span class="glyphicon glyphicon-facetime-video" aria-hidden="true"></span></a>
	&nbsp;<span class="label label-default" id="inv-ack"></span>
<%}%>
</div>
<!--<%if(utype.equalsIgnoreCase("DOC")){%>
<div><button class='btn next' id='next-pat'>Next Patient</button></div>
<%}%>-->
<%if(utype.equalsIgnoreCase("DOC")){%>
<div class="col-sm-3 date"><label>Patient Monitoring : </label>
	<button type="button" class="btn btn-primary btn-xs" title="Open Patient Monitoring for this patient" onclick="clearPanel('patientMonitoringDoctor.jsp?patId=<%=patid%>')">Patient Monitoring</button>
</div>
<%}%>
					</div>
				</div>
			</div>

			<div class="row">
				<div class="col-sm-3 left-div">
					<div class="chf-complnt">
						<fieldset>
							<legend class="title">CHIEF COMPLAINTS
							<%if(Integer.parseInt(pq)>0 || !utype.equalsIgnoreCase("PAT")){%>
							<div class="new-comp-btn pull-right" data-toggle="modal" data-target="#add_comp"><span class="glyphicon glyphicon-plus"></span></div>
							<%}%>
							</legend>
							<div class="navigate"><%=listOfFomrs(patid,"a14",chief_com_sl,chief_com_dt,ddinfo)%></div>
							<ul class='list-group ul-chf-complnt'>
								<%=chiefComplaint("a14",patid,chief_com_dt,chief_com_sl,ddinfo,request, crypto)%>
							</ul>
						</fieldset>
					</div>
					
					<%-- <div class="psy-notes">
						<fieldset>
							<legend class="title">POST SESSION REFLECTION
							<%if(Integer.parseInt(pq)>0 || !utype.equalsIgnoreCase("PAT")){%>
							<div class="new-note-btn pull-right" data-toggle="modal" data-target="#add_comp"><span class="glyphicon glyphicon-plus"></span></div>
							<%}%>
							</legend>
							<div class="navigate"><%=listOfFomrs(patid,"psyNotes",psy_notes_sl,psy_notes_dt,ddinfo)%></div>
							<ul class='list-group ul-chf-complnt'>
								<%=chiefComplaint("a14",patid,psy_notes_dt,psy_notes_sl,ddinfo,request, crypto)%>
							</ul>
						</fieldset>
					</div> --%>


					<div class="psy-notes">
						<fieldset>
							<legend class="title">POST SESSION REFLECTION
							<%if(Integer.parseInt(pq)>0 || !utype.equalsIgnoreCase("PAT")){%>
							<div class="psy-notes-btn pull-right" data-toggle="modal" data-target="#add_psy_notes"><span class="glyphicon glyphicon-plus"></span></div>
							<%}%>
							</legend>
							<div class="navigate"><%=listOfFomrs(patid,"psyNotes",psy_sl,psy_dt,ddinfo)%></div>
							<ul class='list-group ul-psy-notes'>
								<%=ncdScreening("psyNotes",patid,psy_dt,psy_sl,ddinfo,request, crypto)%>
							</ul>
						</fieldset>
					</div>					
					
					<div class="gen-exam" >

						<fieldset>
							<legend class="title">GENERAL EXAMINATIONS
							<%if(Integer.parseInt(pq)>0 || !utype.equalsIgnoreCase("PAT")){%>
							<div class="new-vtsign-btn pull-right" data-toggle="modal" data-target="#add_vtsign"><span class="glyphicon glyphicon-plus"></span></div>
							<%}%>
							</legend>
							<div class="navigate"><%=listOfFomrs(patid,"p47",gen_exam_sl,gen_exam_dt,ddinfo)%></div>
							<ul class='list-group gen-exam'>
								<%=genInvestigation("p47",patid,gen_exam_dt,gen_exam_sl,ddinfo)%>
							</ul>
						</fieldset>
					</div>					

					<!--<div class="view-rpt">
						<fieldset>
							<legend class="title">VIEW REPORTS</legend>
							<div>
								<%=viewRecords(patid,request)%>
							</div>
						</fieldset>
					</div>-->

					<%if(Integer.parseInt(pq)>0 || !utype.equalsIgnoreCase("PAT")){%>
					<div class="upload-report"><!-- "Upload Report Start" -->
						<fieldset>
						<legend class="title">Upload Report</legend>
						<div>
									<div class="row">
									<div class="col-sm-12 tableb">
									<FORM name="imgld" id="reportUpload">
									<INPUT TYPE="hidden" name="pat_id" value="<%=patid%>">
									<div class="drop-div" id="drop_div" ondrop = "drop_evt(event);" ondragover="dragOver_evt(event);" >
									   <span id ="drop_div_html">Drop Here/Select File</span>
									   <input type="file" NAME="userfile" onChange="drop_evt(event)" onMouseOver="MM_displayStatusMsg('click the Browse button to select a file from disk')" onMouseOut="MM_displayStatusMsg(' ')" class="filestyle" id="smallFile" />
									</div>
									<INPUT class="form-control" NAME="imgdesc" Maxlength=300 placeholder="Description" onMouseOver="MM_displayStatusMsg('type very short description of the file')" onMouseOut="MM_displayStatusMsg(' ')">
									<INPUT  class="form-control" placeholder="Laboratory Name" TYPE=textbox NAME=lab_name />
									<INPUT class="form-control" placeholder="Doctor Name" TYPE=textbox NAME=doc_name />

									<select class="form-control report-type" name=type title="File type" >
										<option value="">SELECT</option>
										<option value="BLD">Blood Slides </option>
										<option value="CTS">CT Scan </option>
										<option value="DCM">Dicom Files</option>
										<option value="DOC">Documents</option>
										<option value="EEG">EEG </option>
										<option value="MRI">MRI</option>
										<option value="MOV">Movie Files</option>
										<option value="SEG">Scanned ECG </option>
										<option value="SKP">Scanned Skin Patch </option>
										<option value="SNG">Sonograms</option>
										<option value="SND">Sound Files</option>
										<option value="TEG">Text ECG </option>
										<option value="XRA">X-Ray </option>
										<option value="OTH">Others</option>
									</select>

									<input type=hidden name=entrydate>
									<div id="dot-datepicker" class="input-append date input-group" style="margin:auto;max-width:320px;">
										<input data-format="dd/MM/yyyy" id="datepicker-testdate" type="text" value="<%=today%>" class="form-control dot" required><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
									</div>

									<input class="form-control" id="testdate" placeholder="Date Of Test(DDMMYYYY)" name=testdate size=8 maxlength=8 onblur='return chkdt(this.value)' type="hidden" />
									<center><input class="btn btn-primary" type="submit" value="Upload" onclick="return fileCheck()" style="background-color: '#FFE0C1'; color: '#000000'; font-weight:BOLD; font-style:oblique "></CENTER>
									</FORM>
									<form id="lfuploadform" method="POST" >
										<input type="hidden" id="Lftype" value="BLD" name="ftype" />
										<input type="hidden" id="Ldes" name="desc" />
										<input type="hidden" id="Llname" name="lname" />
										<input type="hidden" id="LdocName" name="docName" />
										<input type="hidden" id="Lext" name="ext" />
									</form>

									</div>		<!-- "col-sm-12" -->
									</div>		<!-- "row" -->


						</div>
						</fieldset>
					</div><!-- "Upload Report END" -->

					<% } %>


				</div>

				<div class="col-sm-9 right-div">
					<form method="get" id="newPres" action="">
						<INPUT type="hidden" name="pat_id" value="<%=patid.trim()%>" />
						<input type="hidden" name="frmnam" value="<%=ty%>" />
					<%if(utype.equals("doc")){%>
					<div class="prc">
						<fieldset>
						<legend class="title">PRESCRIPTION</legend>
						<% if(prc_sl!="" && prc_dt!="") { %>
							<!--<div class="repeat-prescription" id="repeatPrescription" data-toggle="modal" data-target="#patPres">Repeat Prescription</div>-->
							<div class="repeat-prescription" id="repeatPrescription" data-target="#patPres">Repeat Prescription</div>
							<% } %>
							<!--<div class="new-prc-btn pull-right" data-toggle="modal" data-target="#patPres">New Prescription</div>-->
							<div class="new-prc-btn pull-right" data-target="#patPres">New Prescription</div>
							<div class="clearfix" style="clear: both;"></div>
							<div class="prc-menu">

							</div>

						</fieldset>
					</div>
					<%}%>


					<!--<div class="p-report-sheet">
						<div class="report-close close">Close</div>
						<div class="report-sheet">
						</div>
					</div>-->

					<div class="new-pres">
					</div>







					
					<!-- Modal -->
				<!--	<div id="patPres" class="modal fade" role="dialog">
						<div class="modal-dialog modal-lg">
				-->
						<!-- Modal content-->
				<!--			<div class="modal-content">
						<div class="modal-header">
						<button type="button" class="close" data-dismiss="modal">&times;</button>
						<h4 class="modal-title">Prescription</h4>
						</div>
						<div class="modal-body add-prescription">

							<div class="text-diagn">
								<fieldset>
								<legend class="title">DIAGNOSIS</legend>
									<div class="diagn-report">
										<textarea name='diagnosis' class='diagnosis col-sm-12' />
									</div>
								</fieldset>
							</div>
							<div class="text-advice">
								<fieldset>
								<legend class="title">OBSERVATIONS AND ADVICE</legend>
									<div class="advice-field">
										<textarea name='advice' class='advice col-sm-12' />
									</div>
								</fieldset>
							</div>
							<%-- advice for investigation --%>
							<div class="advc-invs">
								<fieldset>
									<legend class="title">ADVICE FOR INVESTIGATIONS</legend>


									<div class="input-group">
										<span class="input-group-addon">Radiology</span>

										<select class="radiology form-control input-sm modality" name="test_name">
										<option value="">SELECT</option>
										</select>

										
								</div>
									<div class="input-group">
										<span class="input-group-addon">Pathology</span>
										<select class="pathology form-control input-sm pathoModality" name="test_name" >
											<option value="">SELECT</option>
										</select>
										
									</div>

									<div class="invest-desc" style="display:none" for="testdes">
										<textarea calss="invst-txt-desc" name="description" placeholder="Test name" id="testdes"></textarea>
									</div>


									<div id="invsAdvc">
									<%-- <form id="invsAdvc" class="advc-invs-frm" name="invsAdvc" method="GET"> --%>
										<input name="pat_id" value="<%=patid%>" hidden>
										<input class='invst-type' name='test_type' value='' hidden>
										<INPUT TYPE="hidden" name="frmnam" value="ai0" />
										<INPUT TYPE="hidden" name="status" value="P" />
										<INPUT TYPE="hidden" name="reffered_by" value="<%=uid%>" />
										<input class='noOftest' type='text' name='noOftest' value='0' hidden/>
										<div class="table-responsive">
										<table class="table table-bordered test-list-table">
											<thead align='center'>
												<tr><td>NO</td><td>TYPE</td><td>NAME</td><td>DESCRIPTION</td><td>ACTION&nbsp;<span class="glyphicon glyphicon-plus pull-right add-advice-btn"></span></td></tr>
											</thead>
											<tbody class="advcd-test">

											</tbody>
										</table>
										</div>
										<input class="btn btn-default advice-btn hide" type="submit" value="Advice" />
									<%-- </form> --%>
									</div>
								</fieldset>
							</div>
							<%-- advice for investigation END --%>
							<div class="text-drug">
								<fieldset>
									<legend class="title">COURSE OF MEDICINE</legend>
							<div class="table-responsive" style="height: 300px;">
							<table class="table table-bordered test-list-table" id="medTable">
								<thead align='center' >
									<tr style='background-color:#2775FC ;color:white;font-weight: bold;'><td >DRUG</td><td >QUANTITY</td><td >DOSE</td><td>DURATION</td><td>COMMENTS&nbsp;</td></tr>
									<tr ><td><textarea id='drugname' placeholder="Drug Name" cols="15" class='drug-c' /></td><td><textarea id='drugquantity' placeholder="Quantity" cols="10" /></td><td><textarea id='drugdose' placeholder="Dose" cols="10" /></td><td><textarea id='drugduration' placeholder="Duration" cols="15" /></td><td><textarea id='drugcomments' placeholder="Comments" cols="15" /><span class="glyphicon glyphicon-plus pull-right add-drug-btn" style="color:blue;"></span></td></tr>
								</thead>
								<tbody class="add-drug">

								</tbody>
							</table>
							</div>
						</fieldset>
					</div>	
					<INPUT TYPE="hidden" id="drnam" NAME="drnam" value ="" />
					<INPUT TYPE="hidden" id="drdose" NAME="drdose" value ="" />
					<INPUT TYPE="hidden" id="drdur" NAME="drdur" value ="" />
					<INPUT TYPE="hidden" id="drquan" NAME="drquan" value ="" />
					<INPUT TYPE="hidden" id="drcmnt" NAME="drcmnt" value ="" />
				-->			<!--<div class="add-drug">
						</div>-->
				<!--	<INPUT TYPE="hidden" NAME="cnam" value ="<%=c_nam%>" />
					<INPUT TYPE="hidden" NAME="drgno" value ="<%=r%>" />
					<INPUT TYPE="hidden" NAME="diet" value="" />
					<INPUT TYPE="hidden" name="activity" value="" />
							<div class="next-vst" style="border: 1px solid; padding: 10px;margin:10px 0;">
				-->				<!--NEXT Appointment Date -->
				<!--				<div id="from-datepicker" class="input-append date input-group" style="margin:auto;max-width:320px; display:none;">
									<input data-format="dd/MM/yyyy" type="text" name="apptdate" value="<%=today%>" class="form-control dob" required><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
								</div>
									<input type="submit" name="submit" class="btn btn-primary submit-pres" value="Continue" />
							</div>
							</form>
						</div>
						<div class="modal-footer">
						<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
						</div>
						</div>

						</div>
					</div>
				-->
				<div id="patPres" title="PRESCRIPTION" >
				
							<div class="text-diagn">
								<fieldset>
								<legend class="title">DIAGNOSIS</legend>									
									<div class="diagn-report">
										<div class="row diag-head">
											<div class="col-sm-5 ">
											  <div class="input-group">
												<span class="input-group-addon">Basic Diagnosis</span>
												<input name="text" class="form-control basic-diagn" id="bsc-diagn" />
											  </div>
											</div>
											<div class="col-sm-7">
											  <div class="input-group">
												<span class="input-group-addon">Detailed Diagnosis</span>
												<input name="text" class="form-control detail-diagn diagnosis" id="detailed-diagn" />
												<span class="glyphicon glyphicon-plus input-group-addon add-diag-btn"></span>
											  </div>
											</div>	
										</div>									
										
										<input name='basic-diagnosis' class="basic_diagnosis_list" hidden/>
										<!--<textarea class='diagnosis col-sm-6' style="margin-left: 20%;margin-right: 20%;margin-bottom: 2%;" /><span class="glyphicon glyphicon-plus add-diag-btn"></span>-->
										
										<br>
										<ul id="submittedName" class="align-center p-3 mx-auto"></ul>
										<textarea name='diagnosis' style="background-color:#f9f6c3;color: #00008b;font-weight:bold;" class='diagnosis_list col-sm-12' readonly hidden/>
										<!--<button class="clear-btn">Clear</button>-->
									</div>
									
								</fieldset>
							</div>
							<div class="text-advice">
								<fieldset>
								<legend class="title">OBSERVATIONS AND ADVICE</legend>
									<div class="advice-field">
										<textarea name='advi' class='advice col-sm-6' style="margin-left: 20%;margin-right: 20%;margin-bottom: 2%;" /><span class="glyphicon glyphicon-plus add-adv-btn"></span><br>
										<textarea name='advice' style="background-color:#f9f6c3;color: #00008b;font-weight:bold;" class='advice_list col-sm-12' />
									</div>
								</fieldset>
							</div>
							<%-- advice for investigation --%>
							<div class="advc-invs">
								<fieldset>
									<legend class="title">ADVICE FOR INVESTIGATIONS</legend>


									<div class="input-group">
										<span class="input-group-addon">Radiology</span>

										<select class="radiology form-control input-sm modality" name="test_name">
										<option value="">SELECT</option>
										</select>

										
									</div>
									<div class="input-group">
										<span class="input-group-addon">Pathology</span>
										<select class="pathology form-control input-sm pathoModality" name="test_name" >
											<option value="">SELECT</option>
										</select>
										
									</div>
									<div class="input-group">
										<span class="input-group-addon">Assesment</span>
										<select class="tobaccoassessment form-control input-sm tobAssModality" name="test_name" >
											<option value="">SELECT</option>
										</select>
										
									</div>

									<div class="invest-desc" style="display:none" for="testdes">
										<textarea calss="invst-txt-desc" name="description" placeholder="Test name" id="testdes"></textarea>
									</div>


									<div id="invsAdvc">
									 <%-- <form id="invsAdvc" class="advc-invs-frm" name="invsAdvc" method="GET"> --%>
										<input class="pat_id" name="pat_id"  value="<%=patid%>" hidden>
										<input class='invst-type' name='test_type' value='' hidden>
										<INPUT TYPE="hidden" name="frmnam" value="pre" />
										<INPUT TYPE="hidden" name="status" value="P" />
										<INPUT TYPE="hidden" name="reffered_by" value="<%=uid%>" />
										<input class='noOftest' type='text' name='noOftest' value='0' hidden/>
										<div class="table-responsive">
										<table class="table table-bordered test-list-table">
											<thead align='center'>
												<tr><td>NO</td><td>TYPE</td><td>NAME</td><td>DESCRIPTION</td><td>ACTION&nbsp;<span class="glyphicon glyphicon-plus pull-right add-advice-btn"></span></td></tr>
											</thead>
											<tbody class="advcd-test">

											</tbody>
										</table>
										</div>
										<input class="btn btn-default advice-btn hide" type="submit" value="Advice" />
									<%-- </form> --%>
									</div>
								</fieldset>
							</div>
							<%-- advice for investigation END --%>
							<div class="text-drug">
								<fieldset>
									<legend class="title">COURSE OF MEDICINE</legend>
							<div class="table-responsive" style="height: 300px;">
									<table class="table table-bordered test-list-table" id="medTable">
										<thead align='center' >
											<tr style='background-color:#2775FC ;color:white;font-weight: bold;'><td >DRUG</td><td >QUANTITY</td><td >DOSE</td><td>DURATION</td><td>COMMENTS&nbsp;</td></tr>
											<tr ><td><textarea id='drugname' name='drugname' placeholder="Drug Name" cols="15" class='drug-c' /></td><td><textarea id='drugquantity' name='drugquantity' placeholder="Quantity" cols="10" /></td><td><textarea id='drugdose' name='drugdose' placeholder="Dose" cols="10" /></td><td><textarea id='drugduration' name='drugduration' placeholder="Duration" cols="15" /></td><td><textarea id='drugcomments' name='drugcomments' placeholder="Comments" cols="15" /><span class="glyphicon glyphicon-plus pull-right add-drug-btn" style="color:blue;"></span></td></tr>
										</thead>
										<tbody class="add-drug">

										</tbody>
									</table>
									</div>
								</fieldset>
							</div>
							<div class="text-drug">
								
							</div>
							<fieldset>
								<legend class="title">NEXT APPOINTMENT DATE</legend>
								<div id="dot-datepicker2" class="input-append date input-group" style="margin:auto;max-width:320px;">
									<input data-format="dd/MM/yyyy" id="datepicker-apptdate" type="text" value="<%=today%>" class="form-control apt" required><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
									<input class="form-control" id="apptdate" placeholder="Date Of Next Appoinment(DDMMYYYY)" name="apptdate" size=20 maxlength=8 type="hidden" />
								</div>
								<!-- <div id="from-datepicker" class="input-append date input-group" style="margin:auto;max-width:320px; display:none;">
									<input data-format="dd/MM/yyyy" type="text" name="apptdate" value="<%=today%>" class="form-control dob" required><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
								</div> -->

							</fieldset>

							<INPUT TYPE="hidden" id="drnam" NAME="drnam" value ="" />
							<INPUT TYPE="hidden" id="drdose" NAME="drdose" value ="" />
							<INPUT TYPE="hidden" id="drdur" NAME="drdur" value ="" />
							<INPUT TYPE="hidden" id="drquan" NAME="drquan" value ="" />
							<INPUT TYPE="hidden" id="drcmnt" NAME="drcmnt" value ="" />
							<input class="pat_id" name="pat_id"  value="<%=patid%>" hidden>
							<INPUT TYPE="hidden" name="reffered_by" value="<%=uid%>" />
							<input class='invst-type' name='test_type' value='' hidden>
							<INPUT TYPE="hidden" name="frmnam" value="pre" />
							<INPUT TYPE="hidden" name="status" value="P" />
							<!--<input class='noOftest' type='text' name='noOftest' value='0' hidden/>-->
									<!--<div class="add-drug">
								</div>-->
							<INPUT TYPE="hidden" NAME="cnam" value ="<%=c_nam%>" />
							<INPUT TYPE="hidden" NAME="drgno" value ="<%=r%>" />
							<INPUT TYPE="hidden" NAME="diet" value="" />
							<INPUT TYPE="hidden" name="activity" value="" />
							<!--<div class="next-vst" style="border: 1px solid; padding: 10px;margin:10px 0;">-->
								
								<!-- <div id="from-datepicker" class="input-append date input-group" style="margin:auto;max-width:320px; display:none;">
									<input data-format="dd/MM/yyyy" type="text" name="apptdate" value="<%=today%>" class="form-control dob" required><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
								</div> -->
									<!--<input type="submit" name="submit" class="btn btn-primary submit-pres" value="Continue" />-->
									
							<!--</div>-->
							</form>
						
					</div>
				



					<%if(utype.equals("doc") || utype.equals("adm")){%>
						<%-- old advice position --%>
					<%}%>

					<%-- //Soumya_B --%>

					<div class="dispTobac">
						<div class="dispTobacCls" id= "tobaccoAssesment">

						</div>

					<div class="allVisits">
						<div class="uploadedReport">

						</div>

					</div>

					</div>

				</div> <!-- End col-sm-9 right-div -->
			</div> <!-- End row -->
		</div> <!-- End container-fluid patientalldata -->





								<!-- Modal cheifComplaint-->

					<div id="add_comp" class="modal fade" role="dialog">
						<div class="modal-dialog modal-lg" >

						<!-- Modal content-->
						<div class="modal-content" style="overflow-x: auto;overflow-y: auto; margin-right:2%;">
							<div class="modal-header" >
								<button type="button" class="close" data-dismiss="modal">&times;</button>
								<h4 class="modal-title">CHIEF COMPLAINTS</h4>
							</div>
							<div class="modal-body add-comp" style="margin-right:2%;" >
								Body
							</div>
						</div>
						</div>
					</div>


					<!-- Modal Post Session Reflection-->

					<%-- <div id="add_comp" class="modal fade" role="dialog">
						<div class="modal-dialog modal-lg" >

						<!-- Modal content-->
						<div class="modal-content" style="overflow-x: auto;overflow-y: auto; margin-right:2%;">
							<div class="modal-header" >
								<button type="button" class="close" data-dismiss="modal">&times;</button>
								<h4 class="modal-title">POST SESSION REFLECTIONS</h4>
							</div>
							<div class="modal-body add-comp" style="margin-right:2%;" >
								Body
							</div>
						</div>
						</div>
					</div> --%>

								<!-- Modal POST SESSION REFLECTION-->

					<div id="add_psy_notes" class="modal fade" role="dialog">
						<div class="modal-dialog modal-lg" >

						<!-- Modal content-->
						<div class="modal-content" style="overflow-x: auto;overflow-y: auto; margin-right:2%;">
							<div class="modal-header" >
								<button type="button" class="close" data-dismiss="modal">&times;</button>
								<h4 class="modal-title">POST SESSION REFLECTION</h4>
							</div>
							<div class="modal-body add-psy-notes" style="margin-right:2%;" >
								Body
							</div>
						</div>
						</div>
					</div>

					<!-- Modal Vital sign-->

					<div id="add_vtsign" class="modal fade" role="dialog" >
						<div class="modal-dialog modal-lg" >

						<!-- Modal content-->
						<div class="modal-content" >
							<div class="modal-header">
								<button type="button" class="close" data-dismiss="modal">&times;</button>
								<h4 class="modal-title">Vital Signs</h4>
							</div>
							<div class="modal-body add-vtsign" style="overflow-x: auto;overflow-y: auto;margin-right:5%;" >
								Body
							</div>
						</div>
						</div>
					</div>




		</div>
<!-- <div id="dialog-form" title="Send Email Reminder"></div> -->
<div id="dialog-form" title="Set Followup Appoinment"></div>

<script>
$(document).ready(function() {
    // Global listener to solve z-index / stacking context issues by appending active modals directly to body
    $(document).on('show.bs.modal', '.modal', function () {
        var modal = $(this);
        if (!modal.parent().is('body')) {
            var modalId = modal.attr('id');
            if (modalId) {
                // If there's an older instance of the same modal ID in the body, remove it first
                $('body > #' + modalId).remove();
            }
            modal.appendTo('body');
        }
    });
});
</script>
	</body>

</html>
<%}
else{out.println("This patient does not belongs to your center");}
%>
