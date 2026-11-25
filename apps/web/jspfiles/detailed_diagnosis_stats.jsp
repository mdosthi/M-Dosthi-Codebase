<%@page language="java"  import= "imedix.rcUserInfo,imedix.rcDataEntryFrm,imedix.rcAdminJobs,imedix.rcCentreInfo,imedix.dataobj,imedix.cook,java.util.*,imedix.rcDisplayData"%>
<%@page language="java" import="org.json.simple.JSONArray, org.json.simple.JSONObject" %>
<%@ include file="..//includes/chkcook.jsp" %>
<%
	cook cookx = new cook();
	String utyp=cookx.getCookieValue("usertype", request.getCookies());
	String usr=cookx.getCookieValue("userid", request.getCookies());

	rcUserInfo uinfo=new rcUserInfo(request.getRealPath("/"));
	String us, ps;
	boolean found=false;;

	//rcPatqueueInfo rcpqi=new rcPatqueueInfo(request.getRealPath("/"));
	//rcCentreInfo rcci=new rcCentreInfo(request.getRealPath("/"));

	String ccode= cookx.getCookieValue("center", request.getCookies ());
	String cname = cookx.getCookieValue("centername", request.getCookies ());

	String sccode=request.getParameter("sccode");


	if(sccode==null) sccode=ccode;
	if(sccode.equals("")) sccode=ccode;
/*
out.println(request.getParameter("_center")+request.getParameter("_basic_diagnosis")+request.getParameter("_detailed_diagnosis"));
	
	String center = request.getParameter("_center");
	String basic_diagnosis = request.getParameter("_basic_diagnosis");
	String detailed_diagnosis = request.getParameter("_detailed_diagnosis");
	rcDisplayData ddinfo=new rcDisplayData(request.getRealPath("/"));
	dataobj objpre=null;
	Object res1=ddinfo.diagnosisStats(center, basic_diagnosis, detailed_diagnosis);
	String preid = "";
	
	if(res1 instanceof String){
		out.println("</br>center><h1> Data Not Available </h1></center>");
		out.println("</br><center><h1> " +  res1+ "</h1></center>");
		return;
	}
	else{
		Vector tmp = (Vector)res1;
		if(tmp.size()>0) {
			objpre = (dataobj) tmp.get(0);
			basic_diagnosis = objpre.getValue("basic_diagnosis");
			detailed_diagnosis = objpre.getValue("value");
			out.print(basic_diagnosis+ detailed_diagnosis);
		}
	}	
*/
%>


<HTML>
<HEAD>
<TITLE> New Document </TITLE>
<META NAME="Generator" CONTENT="EditPlus">
<META NAME="Author" CONTENT="">
<META NAME="Keywords" CONTENT="">
<META NAME="Description" CONTENT="">

<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.0.0/dist/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-datepicker/1.3.0/css/datepicker.min.css" />

<!--<script src="https://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN" crossorigin="anonymous"></script>-->
<script src="../bootstrap/jquery-2.2.1.min.js"></script>
<script src="<%=request.getContextPath()%>/bootstrap/jquery-ui.min.js?"></script>
<script src="https://cdn.jsdelivr.net/npm/popper.js@1.12.9/dist/umd/popper.min.js" integrity="sha384-ApNbgh9B+Y1QKtv3Rn7W3mgPxhU9K/ScQsAP7hUibX39j7fakFPskvXusvfa0b4Q" crossorigin="anonymous"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@4.0.0/dist/js/bootstrap.min.js" integrity="sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl" crossorigin="anonymous"></script>	
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-datepicker/1.3.0/js/bootstrap-datepicker.min.js"></script>

<style>
.div-diag-summary{
	display:block;
	margin:auto;
	}
.div-table{
	background: rgb(222, 226, 230);
    padding: 12px;	
	box-shadow: 0px 1px 2px 0px #5ba9ec;
    margin-top: 12px;    
}
#sts-table{
	background: #fff;
	border-radius: 8px;
}
.custom-input-1{
	padding: 0.375rem 0.75rem;
    font-size: 1rem;
    line-height: 1.5;
    color: #495057;
    background-color: #fff;
    background-clip: padding-box;
    border: 1px solid #ced4da;
    border-radius: 0.25rem;	
}
.date-range-div{
    border: 1px solid #ccc;
    padding: 6px;
    text-align: center;
    border-radius: 4px;
    box-shadow: 0px 0px 2px 0px #ddd;
    background: #a3adb7;	
}
.filter-div{
	border: 1px solid #ccc;
    background: #dee2e6;
    border-radius: 4px;
    padding: 4px;
    display:flex;	
	box-shadow: 0px 1px 2px 0px #5ba9ec;
    margin-top: 12px;  
    position: relative;  
}
.middle-align{
    margin: 0;
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);	
}
.btn-filter{
	background: #cde1d5;
    border-radius: 4px;	
}
.dataTables_wrapper .dataTables_filter input{background: #fff !important;}
.dataTable tbody tr td, .dataTable thead tr th{font-family: 'Open Sans';}
.dataTable tbody tr td:nth-child(1) {  
  color:#07349f;
}
.dt-button{
    border: 1px solid #a3adb7;
    border-radius: 4px;
    cursor: pointer;	
}
.dt-buttons{
	width: 50%;
    float: left;	
}
#sts-table tr{
	text-align:center;
}
.dataTable tbody tr td:nth-child(7),
.dataTable tbody tr td:nth-child(8),
.dataTable tbody tr td:nth-child(9),
.dataTable tbody tr td:nth-child(10),
.dataTable tbody tr td:nth-child(11) {  
  background:#e4edf5;
}

.dataTable tbody tr td:nth-child(1),
.dataTable tbody tr td:nth-child(6),
.dataTable tbody tr td:nth-child(11),
.dataTable tbody tr td:nth-child(15),
.dataTable tbody tr td:nth-child(16),
.dataTable tbody tr td:nth-child(22),
.dataTable tbody tr td:nth-child(23) {
border-right: 1px solid;	
}

.dataTable tbody tr td:nth-child(2),
.dataTable tbody tr td:nth-child(3),
.dataTable tbody tr td:nth-child(4),
.dataTable tbody tr td:nth-child(5),
.dataTable tbody tr td:nth-child(6)
{
	background:#aed5d1;
}
.th-header-1 th{
	text-align: center !important;
}
.quarter-div{
	display: block;
    margin: auto;
    padding: 4px;
}
.quarter-active{background:#2d6e41 !important;}
</style>

<link rel="stylesheet" href="https://cdn.datatables.net/1.13.7/css/jquery.dataTables.min.css" />
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/material-components-web/4.0.0/material-components-web.min.css" />

<script src="https://cdn.datatables.net/1.13.7/js/jquery.dataTables.min.js"></script>

<script src="https://cdn.datatables.net/buttons/2.4.2/js/dataTables.buttons.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.1.53/pdfmake.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.1.53/vfs_fonts.js"></script>
<script src="https://cdn.datatables.net/buttons/2.4.2/js/buttons.html5.min.js"></script>
<script src="https://cdn.datatables.net/buttons/2.4.2/js/buttons.print.min.js"></script>
<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/jquery-ui.css">


<script>

	function basicDiagnosisDropdown(){
			$.ajax({
			  type: 'GET',
			  url: '../includes/basic_diagnosis_stats.json',
			  dataType: 'json',
			  success: function (basic_diagnosis) {
				//console.log("Check11", basic_diagnosis);
				$('#bsc-diagn').autocomplete({
					source: basic_diagnosis.sort(),
					change: function(){
						/*
						if ($("#bsc-diagn").val()!="OTHERS")
							$('#detailed-diagn').val($("#bsc-diagn").val()+" ");
						else
							$('#detailed-diagn').val("");
						console.log("Checkpoint1> "+$("#bsc-diagn").val().replace(/ /g,"")) 
						filtered_diagnosis = detailed_diagnosis_group[$("#bsc-diagn").val().replace(/ /g,"")];
						* */
						},
					select: function(){},
					minLength: 0,
					scroll: true,
					appendTo : $('#patPres')
				}).focus(function() {
					$(this).autocomplete("search", "");
				});					
				
			  }
			});			

		}	
	




	var totalsummary_sts = ""
    $(document).ready(function(){
		basicDiagnosisDropdown()

		$('.from').datepicker({
			autoclose: true,
			minViewMode: 1,
			format: 'yyyy-mm'
		}).on('changeDate', function(selected){
				startDate = new Date(selected.date.valueOf());
				startDate.setDate(startDate.getDate(new Date(selected.date.valueOf())));
				$("#startDate").val("");
				$("#endDate").val("");
				//$('.to').datepicker('setStartDate', startDate);
			}); 


        var today = new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate());
        $('#startDate').datepicker({
            uiLibrary: 'bootstrap4',
            iconsLibrary: 'fontawesome',
            minDate: today,
            format: 'yyyy-mm-dd',
            maxDate: function () {
                return $('#endDate').val();
            }
        }).on('changeDate', function(selected){$("#month-wise-date").val("")});
        $('#endDate').datepicker({
            uiLibrary: 'bootstrap4',
            iconsLibrary: 'fontawesome',
            format: 'yyyy-mm-dd',
            minDate: function () {
                return $('#startDate').val();
            }
        }).on('changeDate', function(selected){$("#month-wise-date").val("")});




		$('#year-picker').datepicker({
			autoclose: true,
			changeMonth: false,
			minViewMode: 2,
			format: 'yyyy'
		}).on('changeDate', function(selected){
				startDate = new Date(selected.date.valueOf());
				startDate.setDate(startDate.getDate(new Date(selected.date.valueOf())));
				$("#startDate").val("");
				$("#endDate").val("");
				$("#month-wise-date").val("")
				//$('.to').datepicker('setStartDate', startDate);
			}); 
  

    
    });
</script>



<script>
	
$( document ).ready(function(){

	$(".btn-filter").click(function(){
		var request = $.ajax({
		  url: "_detailed_diagnosis_stats.jsp",
		  type: "POST",
		  data: {_center:$(".center-list").val(), _start_date:$("#startDate").val(), _end_date:$("#endDate").val(), _basic_diagnosis:$("#bsc-diagn").val()},
		  dataType: "json"
		});

		request.done(function(msg) {
		  //console.log("Success>> "+msg);
			//data = JSON.stringify(msg);	
			
			var data = msg[0]
			var new_data = []
			var unique_keys = new Set([])
			for (i=0; i<data.length; i++){
				var keys = Object.keys(data[i])
				key = keys[0]
				unique_keys.add(key)
				// console.log(key)
			}
			console.log(unique_keys)

				obj = {}
			for (const key of unique_keys) {
				obj[key] = []
				new_data.push(obj)    
			}
			console.log(obj)
			for (i=0; i<data.length; i++){
				var keys = Object.keys(data[i])
				key = keys[0]
				// console.log(obj[key])
				obj[key].push(data[i][key])
			}
			
			console.log("Hii> "+totalsummary_sts)
			var new_obj = []
			var total_summary = msg[1]
			//console.log(Object.keys(obj))
			for (const key of Object.keys(obj)){
				var _obj = {}
				// console.log(obj[key].length)
				_obj["diagnosis"] = key
				_obj["total"] = total_summary[key]
				console.log("obj_Total>> "+JSON.stringify(total_summary)+ " : " + key)
				
				for (i=0;i<obj[key].length;i++){
					// console.log(obj[key][i][1])
					let new_key = obj[key][i][0]
					if (obj[key][i][0]=="M")
						new_key="male"
					if (obj[key][i][0]=="F")
						new_key="female"
					if (obj[key][i][0]=="O")
						new_key="others"
					if (obj[key][i][0]=="N")
						new_key="notstated"				
					if (obj[key][i][0]=="caste_category")
						new_key="notgiven"		
					if (obj[key][i][0]=="M_old")
						new_key="oldpatientmale"	
					if (obj[key][i][0]=="F_old")
						new_key="oldpatientfemale"	
					if (obj[key][i][0]=="M_new")
						new_key="newpatientmale"	
					if (obj[key][i][0]=="F_new")
						new_key="newpatientfemale"						
					_obj[new_key] = obj[key][i][1]
				}
				new_obj.push(_obj)
				let total_hindu = (_obj["totalhindu"]==undefined) ? 0 : _obj["totalhindu"];
				let total_muslim = (_obj["muslim"]==undefined) ? 0 : _obj["muslim"];
				let total_others = (_obj["others"]==undefined) ? 0 : _obj["others"];
				_obj["total_religion"] = Number(total_hindu) + Number(total_muslim) + Number(total_others);
				
				
				let total_obc = (_obj["obc"]==undefined) ? 0 : _obj["obc"]
				let total_obncl = (_obj["obncl"]==undefined) ? 0 : _obj["obncl"]
				_obj["obc"] = Number(total_obc)+Number(total_obncl);
				console.log("Checkkk>> "+total_muslim+" : "+_obj["obc"]);
			}	
			console.log("Out String : "+JSON.stringify(new_obj))
			
			
			new DataTable('#sts-table', {
				dom: 'Bfrtip',
				bSortCellsTop: true,
				"bDestroy": true,	
				/*			
				buttons: [
					'copy', 'csv', 'excel', 'pdf', 'print'
				],*/
				buttons: [{
				  extend: 'csvHtml5',
				  header: true,
				  customize: function ( csvData, btn, tbl ) {
					let firstHeader = '"","Center Name",'+$(".center-list :selected").text()+'," From",'+$("#startDate").val()+'," To",'+$("#endDate").val()+',"","",""\r\n'
					let secondHeader = '"","","","New Patients","","","","Old Patients","","","","","Total Patients","","","","","","Hindu","","","","","","Religion"\r\n'
					return firstHeader + secondHeader + csvData;
				  }
				}, 'copy', 'excel', 'pdf', 'print'],				
				data: new_obj,
				columns: [
					{data: 'diagnosis'},
					{data: 'newpatientmale'},
					{data: 'newpatientfemale'},
					{data: 'newpatientchildmale'},
					{data: 'newpatientchildfemale'},					
					{data: 'newpatient'},		
					{data: 'oldpatientmale'},
					{data: 'oldpatientfemale'},
					{data: 'oldpatientchildmale'},
					{data: 'oldpatientchildfemale'},
					{data: 'oldpatient'},								
					{data: 'male'},
					{data: 'female'},
					{data: 'childmale'},
					{data: 'childfemale'},			
					{data: 'total'},
					{data: 'obc'},
					//{data: 'obncl'},
					{data: 'sc'},
					{data: 'st'},
					{data: 'general'},
					{data: 'notgiven'},
					{data: 'totalhindu'},
					{data: 'muslim'},
					{data: 'others'},
					{data: "total_religion"}
				],
				"columnDefs": [{
					"targets": '_all',
					"className": 'mdc-data-table__cell',
					"defaultContent": ""
				}],
			});
				
			
		});
		request.fail(function(jqXHR, textStatus) {
		  alert("Request failed: " + textStatus );
		});
	});		


function getLstDayOfMonFnc(date) {
	return new Date(date.getFullYear(), date.getMonth(), 0).getDate()
}

function getFstDayOfMonFnc(date) {
	let day = new Date(date.getFullYear(), date.getMonth(), 1).getDate()
	if (day<10){
		day = "0"+day;
	}	
  return day
}

$(".quarter-btn").click(function(){
	let q_value = $(this).val();
	let year = $("#year-picker").val();
	if(year=="")
		q_value = ""
	else{
		$(".quarter-btn").removeClass("quarter-active")
		$(this).addClass("quarter-active")	
		$("#month-wise-date").val("")
	}
	switch(q_value){
	  case "Q1":
		$('#startDate').val(year+"-04-"+getFstDayOfMonFnc(new Date(year,4)))
		$('#endDate').val(year+"-06-"+getLstDayOfMonFnc(new Date(year, 6)))
		break;
	  case "Q2":
		$('#startDate').val(year+"-07-"+getFstDayOfMonFnc(new Date(year,7)))
		$('#endDate').val(year+"-09-"+getLstDayOfMonFnc(new Date(year, 9)))
		break;
	  case "Q3":
		$('#startDate').val(year+"-10-"+getFstDayOfMonFnc(new Date(year,10)))
		$('#endDate').val(year+"-12-"+getLstDayOfMonFnc(new Date(year, 12)))
		break;
	  case "Q4":
		$('#startDate').val(year+"-01-"+getFstDayOfMonFnc(new Date(year,1)))
		$('#endDate').val(year+"-03-"+getLstDayOfMonFnc(new Date(year, 3)))
		break;				
	  default:
		alert("Select the Year");
	}
});

	
});
</script>

<body bgcolor="white">
	<div class="container">
		<div class="row">
		<div class="filter-div col-sm-12">
			<div class="col-sm-3">
				<select class="custom-select center-list middle-align" id="inputGroupSelect04">
					<option value="XXXX" selected>Choose Center...</option>
						<%
							out.println("<option value="+ccode+" 'selected'>"+cname+"</option><br>");
							//out.println("<option value=\"MAJH009','KALW009', 'NAUG009', 'LOHA009', 'BAKH005\">STU</option>");
							//out.println("<option value=\"GAUR009', 'MANI009', 'PATE009', 'RAMN009', 'KNSA009\">MTU</option>");
							out.println("<option value='MAJH009|KALW009|NAUG009|LOHA009|BAKH005'>STU</option>");
							out.println("<option value='GAUR009|MANI009|PATE009|RAMN009|KNSA009'>MTU</option>");							
								try
								{
								 if(ccode.equals("XXXX")){
									rcCentreInfo rcci=new rcCentreInfo(request.getRealPath("/"));
									Object res=rcci.getAllCentreInfo();
									if(res instanceof String){ out.println("<option value='NIL' >No match Found</option>"); }
									else{
										Vector Vtmp = (Vector)res;
											for(int j=0;j<Vtmp.size();j++){
												dataobj datatemp = (dataobj) Vtmp.get(j);
												if(datatemp.getValue("code").equals(sccode)){
													out.println("<option value="+datatemp.getValue("code")+" selected>"+datatemp.getValue("name")+"</option><br>");
												}else{
													out.println("<option value="+datatemp.getValue("code")+">"+datatemp.getValue("name")+"</option><br>");
												}
											} // end for
									}// end else
								  }
								}catch(Exception e)
								{
									out.println("error.."+e.getMessage());
								}

						%>
				</select>
			</div>
			
<!--					<select class="custom-select basic-diagnosis" id="inputGroupSelect04">
						<option value='' selected>Choose Basic Diagnosis...</option>
					</select>	
					<select class="custom-select detailed-diagnosis" id="inputGroupSelect04">
						<option value='' selected>Choose Details Diagnosis...</option>
					</select>	-->
					
			<div class="col-sm-3">
				<div class="form-group">
					<!--<select class="custom-select basic-diag-list middle-align basic-diagn ui-autocomplete-input" id="bsc-diagn">
						<option>Choose Basic Diagnosis</options>
					</select>-->
					<input type="text" class="custom-select basic-diag-list middle-align basic-diagn ui-autocomplete-input" id="bsc-diagn" autocomplete="off" placeholder="Choose basic diagnosis" >
				</div>			
			<!--
				<div class="form-group middle-align">
					<input type="text" class="form-control form-control-1 input-sm from" id="month-wise-date" placeholder="Month Wise" autocomplete="off" >
				</div>	
				-->
			</div>
			<div class="col-sm-5 date-range-div">
				<input class="custom-input-1" id="startDate" width="276" placeholder = "Start Date" autocomplete="off" />
				<input class="custom-input-1" id="endDate" width="276" placeholder = "End Date" autocomplete="off" />			
			</div>
			<div class="col-sm-1">								
				<div class="input-group-append middle-align">
					<button class="btn btn-outline-secondary btn-filter" type="button">Filter</button>
				</div>
			</div>
		</div>

<!--
		<div class="quarter-div">
			<div class="btn-toolbar mb-3" role="toolbar" aria-label="Toolbar with button groups">
			  <div class="btn-group mr-2" role="group" aria-label="First group">
				<button type="button" value="Q1" class="btn btn-secondary quarter-btn">Quarter 1</button>
				<button type="button" value="Q2" class="btn btn-secondary quarter-btn">Quarter 2</button>
				<button type="button" value="Q3" class="btn btn-secondary quarter-btn">Quarter 3</button>
				<button type="button" value="Q4" class="btn btn-secondary quarter-btn">Quarter 4</button>
			  </div>
			  <div class="input-group">
				<div class="input-group-prepend">
				  <div class="input-group-text" id="btnGroupAddon">Year</div>
				</div>
				<input type="text" class="form-control" id="year-picker" placeholder="(year only)" />
			  </div>
			</div>
		</div>
-->


<div class="div-table">
<table class='table table-border display' id = "sts-table" style="width:100%">
	<thead>
	<tr class = "th-header-1">
		<th class="mdc-data-table__cell" colspan="1"></th>
		<th class="mdc-data-table__cell" colspan="5">New Patients</th>
		<th class="mdc-data-table__cell" colspan="5">Old Patients</th>
		<th class="mdc-data-table__cell" colspan="4">Grand Total</th>
		<th class="mdc-data-table__cell" colspan="1">Patients</th>
		<th class="mdc-data-table__cell" colspan="5">Hindu</th>
		<th class="mdc-data-table__cell" colspan="3">Religion</th>
	</tr>


	
	<tr>
		<th>Diagnosis</th>
		<th>Male</th>
		<th>Female</th>
		<th>Child Male</th>
		<th>Child Female</th>		
		<th>Total Patient</th>	
		<th>Male</th>
		<th>Female</th>
		<th>Child Male</th>
		<th>Child Female</th>
		<th>Total Patient</th>			
		<th>Male</th>
		<th>Female</th>
		<th>Child Male</th>
		<th>Child Female</th>		
		<th>Total</th>
		<th>OBC</th>
		<!--<th>OBC NCL</th>-->
		<th>SC</th>
		<th>ST</th>
		<th>General</th>
		<th>Not Given</th>
		<th>Total Hindu</th>
		<th>Muslim</th>
		<th>Others</th>
		<th>Total Religion</th>
	</tr>	
	
	</thead>
<tbody>
</tbody>

</table>
</div>

	
			
		</div>
	</div>	
<body>









