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
/*
.dataTable tbody tr td:nth-child(7),
.dataTable tbody tr td:nth-child(8),
.dataTable tbody tr td:nth-child(9),
.dataTable tbody tr td:nth-child(10),
.dataTable tbody tr td:nth-child(11) {  
  background:#e4edf5;
}
*/
.dataTable tbody tr td:nth-child(1),
.dataTable tbody tr td:nth-child(6),
.dataTable tbody tr td:nth-child(11),
.dataTable tbody tr td:nth-child(15),
.dataTable tbody tr td:nth-child(16),
.dataTable tbody tr td:nth-child(21),
.dataTable tbody tr td:nth-child(22) {
border-right: 1px solid;	
}
/*
.dataTable tbody tr td:nth-child(2),
.dataTable tbody tr td:nth-child(3),
.dataTable tbody tr td:nth-child(4),
.dataTable tbody tr td:nth-child(5),
.dataTable tbody tr td:nth-child(6)
{
	background:#aed5d1;
}*/
.th-header-1 th{
	text-align: center !important;
}

.dataTable tbody tr:nth-child(4),
.dataTable tbody tr:nth-child(8),
.dataTable tbody tr:nth-child(12),
.dataTable tbody tr:nth-child(16){
	background:#dbe5a6;
}

.quarter-div{
	display: block;
    margin: auto;
    padding: 4px;
}
.quarter-active{background:#2d6e41 !important;}

.form-check-quarter{
background: #5c6875;
    color: #fff;
    padding: 6px;
    border-radius: 4px;	
}
.ui-menu.ui-autocomplete {
    overflow-y: auto;
    max-height: 200px;
}
.quarter td:first-child:before{
	content: "\f00d";
    float: left;
    cursor: pointer;
	}
.quarter td:first-child{
	font-family: 'Font Awesome 5 Free';
    font-weight: 900;	
	-moz-osx-font-smoothing: grayscale;
    -webkit-font-smoothing: antialiased;
    font-style: normal;
    font-variant: normal;
    text-rendering: auto;
    line-height: 1;    
}
.quarter{
	line-height: 1;
    color: rgb(30, 48, 80);	
	}
#year-picker{
//width:90px;
}
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
<script src="https://cdn.datatables.net/plug-ins/2.0.3/api/sum().js"></script>
<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/jquery-ui.css">
<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.6.3/css/all.css" integrity="sha384-UHRtZLI+pbxtHCWp1t77Bi1L4ZtiqrqD80Kn4Z8NTSRyMA2Fd33n5dQ8lWUE00s/" crossorigin="anonymous">


<script>

	function basicDiagnosisDropdown(){
			$.ajax({
			  type: 'GET',
			  url: '../includes/basic_diagnosis.json',
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
				$("#month-wise-date").val("");
				$("#q-year2").text((Number($("#year-picker").val())+1));
				//$('.to').datepicker('setStartDate', startDate);
			}); 
  

    
    });
</script>



<script>
	
$( document ).ready(function(){

	$(".btn-filter").click(function(){
		var request = $.ajax({
		  url: "_unique_quarter_stats.jsp",
		  type: "POST",
		  data: {_center:$(".center-list").val(), _start_date:$("#year-picker").val(), _end_date:$("#year-picker").val(), _diagnosis:$("#bsc-diagn").val()},
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
				
				let total_obc = (_obj["obc"]==undefined) ? 0 : _obj["obc"]
				let total_obncl = (_obj["obncl"]==undefined) ? 0 : _obj["obncl"]
				_obj["obc"] = Number(total_obc)+Number(total_obncl);				
				
				total_newpatientmale = (_obj["newpatientmale"]==undefined) ? 0 : _obj["newpatientmale"];
				total_newpatientfemale = (_obj["newpatientfemale"]==undefined) ? 0 : _obj["newpatientfemale"];
				total_newpatientchildmale = (_obj["newpatientchildmale"]==undefined) ? 0 : _obj["newpatientchildmale"];
				total_newpatientchildfemale = (_obj["newpatientchildfemale"]==undefined) ? 0 : _obj["newpatientchildfemale"];
				_obj["newpatient"] = Number(total_newpatientmale)+Number(total_newpatientfemale)+Number(total_newpatientchildmale)+Number(total_newpatientchildfemale)
				
				total_oldpatientmale = (_obj["oldpatientmale"]==undefined) ? 0 : _obj["oldpatientmale"];
				total_oldpatientfemale = (_obj["oldpatientfemale"]==undefined) ? 0 : _obj["oldpatientfemale"];
				total_oldpatientchildmale = (_obj["oldpatientchildmale"]==undefined) ? 0 : _obj["oldpatientchildmale"];
				total_oldpatientchildfemale = (_obj["oldpatientchildfemale"]==undefined) ? 0 : _obj["oldpatientchildfemale"];
				_obj["oldpatient"] = Number(total_oldpatientmale)+Number(total_oldpatientfemale)+Number(total_oldpatientchildmale)+Number(total_oldpatientchildfemale)	
				
				total_male = (_obj["male"]==undefined) ? 0 : _obj["male"];
				total_female = (_obj["female"]==undefined) ? 0 : _obj["female"];
				total_childmale = (_obj["childmale"]==undefined) ? 0 : _obj["childmale"];
				total_childfemale = (_obj["childfemale"]==undefined) ? 0 : _obj["childfemale"];
				_obj["total"] = Number(total_male)+Number(total_female)+Number(total_childmale)+Number(total_childfemale)							
				
				total_sc = (_obj["sc"]==undefined) ? 0 : _obj["sc"];
				total_st = (_obj["st"]==undefined) ? 0 : _obj["st"];
				total_general = (_obj["general"]==undefined) ? 0 : _obj["general"];
				total_obc = (_obj["obc"]==undefined) ? 0 : _obj["obc"];
				total_notstated = (_obj["notst"]==undefined) ? 0 : _obj["notst"];
				total_notgiven = (_obj["notgiven"]==undefined) ? 0 : _obj["notgiven"];
				_obj["notst"] = Number(total_notstated) + Number(total_notgiven);
				_obj["totalhindu"] = Number(total_sc)+Number(total_st)+Number(total_obc)+Number(total_general)+Number(total_notstated)+Number(total_notgiven)


				let total_hindu = (_obj["totalhindu"]==undefined) ? 0 : _obj["totalhindu"];
				let total_muslim = (_obj["muslim"]==undefined) ? 0 : _obj["muslim"];
				let total_others = (_obj["others"]==undefined) ? 0 : _obj["others"];
				_obj["total_religion"] = Number(total_hindu) + Number(total_muslim) + Number(total_others);
				console.log("Checkkk 1 >> "+total_hindu+" : "+total_muslim);


				
			}	
			
			var months = ["April", "May", "June", "Q1", "July", "August", "September", "Q2", "October", "November", "December", "Q3", "January", "February", "March", "Q4"];			
			var new_obj_updated = []
			months.forEach((month, index) => {
			   var flag = false 
				new_obj.forEach((q_obj, indx)=>{
				   // console.log(month==q_obj["diagnosis"])
					if (month==q_obj["diagnosis"]){
						flag = true
						new_obj_updated.push(q_obj)
					}
				})
				if(flag == false)
					new_obj_updated.push({"diagnosis":month})
				console.log(month+" : "+index+" : "+flag)


			});
			
					
			
			
			console.log("Out String : "+JSON.stringify(new_obj_updated))
			
			
			var q_table = new DataTable('#sts-table', {
				"ordering": false,
				paging: false,
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
					let firstHeader = '"","Center Name",'+$(".center-list :selected").text()+'," Year ",'+$("#year-picker").val()+' - '+(Number($("#year-picker").val())+1)+',"","Diagnosis",'+$("#bsc-diagn").val()+'\r\n'
					let secondHeader = '"","","","New Patients","","","","Old Patients","","","","","Total Patients","","","","","","Hindu","","","","","","Religion"\r\n'
					return firstHeader + secondHeader + csvData;
				  }
				}, 'copy', 'excel', 'pdf', 'print'],				
				data: new_obj_updated,
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
					{data: 'sc'},
					{data: 'st'},
					{data: 'general'},
					{data: 'notst'},
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
				drawCallback: function () {
				  var api = this.api();
				  //$( api.table().footer() ).html(
					//$( api.row( 3 )).footer().html('7')
					
					//console.log(api.column( 5, {page:'current'} ).data().sum() + " : "+ api.cells( [1, 2, 3, 4, 5, 6, 7, 8], 5 ).data().sum())
				  //);
				  for (i=1;i<25;i++){
						$( api.cell( 3, i ).node()).html(api.cells( [0, 1, 2], i ).data().sum());
						$( api.cell( 7, i ).node()).html(api.cells( [4, 5, 6], i ).data().sum());
						$( api.cell( 11, i ).node()).html(api.cells( [8, 9, 10], i ).data().sum());
						$( api.cell( 15, i ).node()).html(api.cells( [12, 13, 14], i ).data().sum());
						$(api.rows('tr:contains("Q1")').nodes()).addClass('quarter');
						$(api.rows('tr:contains("Q2")').nodes()).addClass('quarter');
						$(api.rows('tr:contains("Q3")').nodes()).addClass('quarter');
						$(api.rows('tr:contains("Q4")').nodes()).addClass('quarter');
					}
				}
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

var oTable = $('#sts-table').dataTable(
{
	"bSort" : false
});


$("#sts-table tbody").on('click', '.quarter ', function() {
    //alert('Row index: ' + $(this).closest('tr').index());
 	let q_range = $(this).closest('tr').index()+1
 	let q_range_low = q_range-4
	while (q_range>q_range_low){
		var row = oTable.find('tbody tr').eq(q_range_low);
		oTable.fnDeleteRow(row[0]);
		//console.log("Hiiiii"+q_range)
		q_range--;
	}   
});

$(".quarter-chk").on("click",function(){
	let q_value = $(this).val();


/*	let selected_q = []
	let q_value = $(this).val();
	let year = $("#year-picker").val();
	if(year=="")
		q_value = ""
	else{
		$(".quarter-btn").removeClass("quarter-active")
		$(this).addClass("quarter-active")	
		$("#month-wise-date").val("")
	}	
	$(".quarter-chk:checked").each(function(){
		selected_q.push($(this).val())
	});*/
		if($(this).prop('checked') == false){
			switch(q_value){
			  case "Q1":
			  alert(q_value)
				//$('#startDate').val(year+"-04-"+getFstDayOfMonFnc(new Date(year,4)))
				//$('#endDate').val(year+"-06-"+getLstDayOfMonFnc(new Date(year, 6)))
				break;
			  case "Q2":
				//$('#startDate').val(year+"-07-"+getFstDayOfMonFnc(new Date(year,7)))
				//$('#endDate').val(year+"-09-"+getLstDayOfMonFnc(new Date(year, 9)))
				break;
			  case "Q3":
				//$('#startDate').val(year+"-10-"+getFstDayOfMonFnc(new Date(year,10)))
				//$('#endDate').val(year+"-12-"+getLstDayOfMonFnc(new Date(year, 12)))
				break;
			  case "Q4":
				//$('#startDate').val(year+"-01-"+getFstDayOfMonFnc(new Date(year,1)))
				//$('#endDate').val(year+"-03-"+getLstDayOfMonFnc(new Date(year, 3)))
				break;				
			  default:
				alert("Select the Year");
			}
		}
		alert(q_value+" : ")
	
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
					<input type="text" class="custom-select basic-diag-list middle-align basic-diagn ui-autocomplete-input" id="bsc-diagn" autocomplete="off" >
				</div>	
			</div>
			<div class="col-sm-5 date-range-div">
				<!--<input class="custom-input-1" id="startDate" width="276" placeholder = "Start Date" autocomplete="off" />
				<input class="custom-input-1" id="endDate" width="276" placeholder = "End Date" autocomplete="off" />		-->
		<div class="quarter-div">
		
	
		
			<div class="btn-toolbar mb-3" role="toolbar" aria-label="Toolbar with button groups">
			
			<!--<div class="form-check form-check-inline form-check-quarter">
			  <input class="form-check-input quarter-chk" type="checkbox" id="inlineCheckbox1" value="Q1" checked/>
			  <label class="form-check-label" for="inlineCheckbox1">Quarter 1</label>
			</div>
			<div class="form-check form-check-inline form-check-quarter">
			  <input class="form-check-input quarter-chk" type="checkbox" id="inlineCheckbox2" value="Q2" checked/>
			  <label class="form-check-label" for="inlineCheckbox2">Quarter 2</label>
			</div>
			<div class="form-check form-check-inline form-check-quarter">
			  <input class="form-check-input quarter-chk" type="checkbox" id="inlineCheckbox3" value="Q3" checked/>
			  <label class="form-check-label" for="inlineCheckbox3">Quarter 3</label>
			</div>	
			<div class="form-check form-check-inline form-check-quarter">
			  <input class="form-check-input quarter-chk" type="checkbox" id="inlineCheckbox3" value="Q4" checked/>
			  <label class="form-check-label" for="inlineCheckbox3">Quarter 4</label>
			</div>	-->

			  <div class="input-group">
				<input type="text" class="form-control" id="year-picker" placeholder="Year" />
				<div class="input-group-prepend">
				  <div class="input-group-text">-</div>
				</div>					
				<div class="input-group-prepend">
				  <div class="input-group-text" id="q-year2">Year</div>
				</div>				
			  </div>
			</div>
		</div>					
			</div>
			<div class="col-sm-1">								
				<div class="input-group-append middle-align">
					<button class="btn btn-outline-secondary btn-filter" type="button">Filter</button>
				</div>
			</div>
		</div>






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
		<th>Year</th>
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









