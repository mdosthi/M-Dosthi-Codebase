<!--Soumyajit-->

<%@page contentType="text/html" import="imedix.rcCentreInfo,imedix.dataobj,imedix.rcDisplayData, imedix.cook, java.util.*, java.io.*, imedix.myDate, java.text.SimpleDateFormat, org.json.simple.*, org.json.simple.parser.*" %>
<%@page contentType="text/html" import="imedix.rcimedixstat,imedix.layout,java.io.*,imedix.rcDataEntryFrm,imedix.cook,imedix.rcPatqueueInfo,imedix.rcGenOperations,imedix.rcUserInfo,imedix.dataobj,imedix.rcVideoConference, java.util.*, imedix.projinfo, imedix.UserAccessCheck" %>
<%@ include file="../../includes/chkcook.jsp" %>
<html>
<title>iMediXcare</title>

<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="icon" type="image/png" href="<%=request.getContextPath()%>/images/icons/mdosthi-favicon-32.png?v=4"/>
	<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/bootstrap.min.css">
	<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/toastr.css">
	<!--<link rel="stylesheet" href="../bootstrap/jquery.dataTables.min.css">-->
	<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.css">
	<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/index.css">

	<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/jquery-ui.min.css">
	<link rel="stylesheet" href="<%=request.getContextPath()%>/vc/vc.css?"+n>

	<script src="<%=request.getContextPath()%>/bootstrap/jquery-2.2.1.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/toastr.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/js/bootstrap.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/jquery.dataTables.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/jquery-ui.min.js?"+n></script>
	<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/bootstrap-datetimepicker.min.css">
    <script src="<%=request.getContextPath()%>/bootstrap/bootstrap-datetimepicker.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/bootstrap-datetimepicker.pt-BR.js"></script>

<style>
    .datepicker-div{
		    margin: 10px 0;
		    background:gray;
		    box-shadow: 0px 0px 1px 1px #ddd;
		    border-radius: 4px;
		    padding: 4px;        	
        }
        .download-btn1{
            margin: auto;
            display: block;   
        }
		.download-btn2{
            margin: auto;
            display: block;   
        }
		.download-btn3{
            margin: auto;
            display: block;   
        }
		.download-btn4{
            margin: auto;
            display: block;   
        }
		.download-btn5{
            margin: auto;
            display: block;   
        }
		.statlist table thead{
			background: #333;
			color: #ddd;	
			box-shadow: 0px 2px 4px 0px #333;
		}
		.statlist table thead th{text-align: center;}
		.statlist table tbody tr{
			box-shadow:0px 2px 4px 0px #333;
			font-size: 14px;
		}
		.statlist table tbody tr:hover{
			background: #eef;
			transition-duration: 0.4s;
		}
		.statlist2 table thead{
			background: #333;
			color: #ddd;	
			box-shadow: 0px 2px 4px 0px #333;
		}
		.statlist2 table thead th{text-align: center;}
		.statlist2 table tbody tr{
			box-shadow:0px 2px 4px 0px #333;
			font-size: 14px;
		}
		.statlist2 table tbody tr:hover{
			background: #eef;
			transition-duration: 0.4s;
		}
		.statlist3 table thead{
			background: #333;
			color: #ddd;	
			box-shadow: 0px 2px 4px 0px #333;
		}
		.statlist3 table thead th{text-align: center;}
		.statlist3 table tbody tr{
			box-shadow:0px 2px 4px 0px #333;
			font-size: 14px;
		}
		.statlist3 table tbody tr:hover{
			background: #eef;
			transition-duration: 0.4s;
		}
		.statlist4 table thead{
			background: #333;
			color: #ddd;	
			box-shadow: 0px 2px 4px 0px #333;
		}
		.statlist4 table thead th{text-align: center;}
		.statlist4 table tbody tr{
			box-shadow:0px 2px 4px 0px #333;
			font-size: 14px;
		}
		.statlist4 table tbody tr:hover{
			background: #eef;
			transition-duration: 0.4s;
		}
		.statlist5 table thead{
			background: #333;
			color: #ddd;	
			box-shadow: 0px 2px 4px 0px #333;
		}
		.statlist5 table thead th{text-align: center;}
		.statlist5 table tbody tr{
			box-shadow:0px 2px 4px 0px #333;
			font-size: 14px;
		}
		.statlist5 table tbody tr:hover{
			background: #eef;
			transition-duration: 0.4s;
		}
		.statlist6 table thead{
			background: #333;
			color: #ddd;	
			box-shadow: 0px 2px 4px 0px #333;
		}
		.statlist6 table thead th{text-align: center;}
		.statlist6 table tbody tr{
			box-shadow:0px 2px 4px 0px #333;
			font-size: 14px;
		}
		.statlist6 table tbody tr:hover{
			background: #eef;
			transition-duration: 0.4s;
		}
</style>

</head>

<script LANGUAGE="JavaScript">
    $(document).ready(function(){
	
	let d = new Date();
	
	$(function () {
		endDate = new Date(d.getFullYear()+"-"+Number(d.getMonth()+1)+"-"+Number(d.getDate())),
    	startDate = new Date("01/01/2021"),        
		$('#datepick1').datetimepicker({
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
			setDate: endDate
		});
        $('#datepick2').datetimepicker({
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
			setDate: endDate
		});
        $('#datepick3').datetimepicker({
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
			setDate: endDate
		});
        $('#datepick4').datetimepicker({
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
			setDate: endDate
		});
        $('#datepick5').datetimepicker({
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
			setDate: endDate
		});
        $('#datepick6').datetimepicker({
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
			setDate: endDate
		});
		$('#datepick7').datetimepicker({
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
			setDate: endDate
		});
        $('#datepick8').datetimepicker({
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
			setDate: endDate
		});
		$('#datepick9').datetimepicker({
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
			setDate: endDate
		});$('#datepick10').datetimepicker({
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
			setDate: endDate
		});
		$('#datepick11').datetimepicker({
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
			setDate: endDate
		});$('#datepick12').datetimepicker({
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
			setDate: endDate
		});
	});	
});
$(".download-btn1").click(function(){

	var fromdt=$("#fromdt1").val();
	var todt=$("#todt2").val();
	console.log(fromdt);
	console.log(todt);
	var param = {fromdt:fromdt, todt:todt};

window.open("statistics/download/Download_age_caste_sex.jsp?fromdt="+fromdt+"&todt="+todt, '_blank');

}); 

function  display()
{
	var fromdt=$("#fromdt1").val();
	var todt=$("#todt2").val();
	console.log(fromdt);
	console.log(todt);
	var param = {fromdt:fromdt, todt:todt};
	$.ajax({
					type: 'GET',
					url: "statistics/age_caste_sex.jsp",
					data: param,
					dataType: "text",
					success: function(data)
					{
						$(".statlist tbody").empty();
						$(".statlist tbody").append(data.trim());


					}
				});

}

$(".download-btn2").click(function(){

	var fromdt=$("#fromdt3").val();
	var todt=$("#todt4").val();
	console.log(fromdt);
	console.log(todt);
	var param = {fromdt:fromdt, todt:todt,tag:"sex"};
	var c="sex";
window.open("statistics/download/Download_Nage_caste_sex.jsp?fromdt="+fromdt+"&todt="+todt+"&tag="+c, '_blank');

}); 

function  display2()
{
	var fromdt=$("#fromdt3").val();
	var todt=$("#todt4").val();
	console.log(fromdt);
	console.log(todt);
	var param = {fromdt:fromdt, todt:todt,tag:"sex"};
	$.ajax({
					type: 'GET',
					url: "statistics/Nage_caste_sex.jsp",
					data: param,
					dataType: "text",
					success: function(data)
					{
						$(".statlist2 tbody").empty();
						$(".statlist2 tbody").append(data.trim());


					}
				});

}

$(".download-btn3").click(function(){

	var fromdt=$("#fromdt5").val();
	var todt=$("#todt6").val();
	console.log(fromdt);
	console.log(todt);
	var param = {fromdt:fromdt, todt:todt,tag:"caste_category"};
var c="caste_category";
window.open("statistics/download/Download_Nage_caste_sex.jsp?fromdt="+fromdt+"&todt="+todt+"&tag="+c, '_blank');

}); 

function  display3()
{
	var fromdt=$("#fromdt5").val();
	var todt=$("#todt6").val();
	console.log(fromdt);
	console.log(todt);
	var param = {fromdt:fromdt, todt:todt,tag:"caste_category"};
	$.ajax({
					type: 'GET',
					url: "statistics/Nage_caste_sex.jsp",
					data: param,
					dataType: "text",
					success: function(data)
					{
						$(".statlist3 tbody").empty();
						$(".statlist3 tbody").append(data.trim());


					}
				});

}

$(".download-btn4").click(function(){

var fromdt=$("#fromdt7").val();
var todt=$("#todt8").val();
console.log(fromdt);
console.log(todt);
var param = {fromdt:fromdt, todt:todt,tag:"religion"};
var c="religion";
window.open("statistics/download/Download_Nage_caste_sex.jsp?fromdt="+fromdt+"&todt="+todt+"&tag="+c, '_blank');

}); 
function  display4()
{
	var fromdt=$("#fromdt7").val();
	var todt=$("#todt8").val();
	console.log(fromdt);
	console.log(todt);
	var param = {fromdt:fromdt, todt:todt,tag:"religion"};
	$.ajax({
					type: 'GET',
					url: "statistics/Nage_caste_sex.jsp",
					data: param,
					dataType: "text",
					success: function(data)
					{
						$(".statlist4 tbody").empty();
						$(".statlist4 tbody").append(data.trim());


					}
				});

}

$(".download-btn5").click(function(){

var fromdt=$("#fromdt9").val();
var todt=$("#todt10").val();
console.log(fromdt);
console.log(todt);
var param = {fromdt:fromdt, todt:todt,tag:"religion_caste"};
var c="religion_caste";
window.open("statistics/download/Download_Nage_caste_sex.jsp?fromdt="+fromdt+"&todt="+todt+"&tag="+c, '_blank');

}); 
function  display5()
{
	var fromdt=$("#fromdt9").val();
	var todt=$("#todt10").val();
	console.log(fromdt);
	console.log(todt);
	var param = {fromdt:fromdt, todt:todt,tag:"religion_caste"};
	$.ajax({
					type: 'GET',
					url: "statistics/Nage_caste_sex.jsp",
					data: param,
					dataType: "text",
					success: function(data)
					{
						$(".statlist5 tbody").empty();
						$(".statlist5 tbody").append(data.trim());


					}
				});

}

$(".download-btn6").click(function(){


	var fromdt=$("#fromdt11").val();
	var todt=$("#todt12").val();
	console.log(fromdt);
	console.log(todt);
	var param = {fromdt:fromdt, todt:todt};

	window.open("statistics/download/Download_stat_femaleChild.jsp?fromdt="+fromdt+"&todt="+todt, '_blank');

}); 
function  display6()
{

	var fromdt=$("#fromdt11").val();
	var todt=$("#todt12").val();
	console.log(fromdt);
	console.log(todt);
	var param = {fromdt:fromdt, todt:todt};
	$.ajax({
					type: 'GET',
					url: "statistics/FemaleChild.jsp",
					data: param,
					dataType: "text",
					success: function(data)
					{
						$(".statlist6 tbody").empty();
						$(".statlist6 tbody").append(data.trim());


					}
				});

}


</script>

<body>
    
    <div class="container-fluid">



        <ul class="nav nav-tabs nav-justified">
            <li class="active"><a data-toggle="tab" href="#gcs">Patient Demographics</a></li>
			<li><a data-toggle="tab" href="#fem_child">Statistics by Female Child</a></li>
            <li><a data-toggle="tab" href="#sex">Statistics by Gender</a></li>
            <li><a data-toggle="tab" href="#caste">Statistics by Caste</a></li>            
			<li><a data-toggle="tab" href="#religion">Statistics by Religion</a></li>   
			<li><a data-toggle="tab" href="#religion_caste">Statistics by Caste and Religion</a></li>   
          </ul>
        <!--<ul class="nav nav-pills">
            <li class="active"><a data-toggle="pill" href="#home">Home</a></li>
            <li><a data-toggle="pill" href="#menu1">Menu 1</a></li>
            <li><a data-toggle="pill" href="#menu2">Menu 2</a></li>
          </ul>-->
          
          <div class="tab-content">
            <div id="gcs" class="tab-pane fade in active">

                <div class="row datepicker-div" >
                    <div class="col-sm-3">
                    <div id="datepick1" class="input-append date input-group" style="float:left;margin:auto;max-width:320px;">
                        <span class="input-group-addon">From</span>
                        <input data-format="dd/MM/yyyy" type="text" name="fromdt1" id="fromdt1"  class="form-control logCaln" required /><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>                    
                    </div>
                    </div>
                    <div class="col-sm-3">
                    <div id="datepick2" class="input-append date input-group" style="float:left;margin:auto;max-width:320px;">
                        <span class="input-group-addon">To</span>
                        <input data-format="dd/MM/yyyy" type="text" name="todt2" id="todt2" class="form-control logCaln" required /><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
                    </div>
                    </div>
                    <div class="col-sm-3">
                        <button type="button" class="btn download-btn" onclick="display()" >Submit</button>
                    </div>
                    <div class="col-sm-3">
                        <button type="button" class="btn download-btn1" ><span class="glyphicon glyphicon-download"></span></button>
                    </div>
            
                
                </div>

				<div class="row table">
					<div class="col-sm-12 statlist">
						<table class="table table-hover table-bordered">
						  <thead>
							<tr>
							  
							  <th>Patient Id</th>
							  <th>Patient Name</th>
							  <th>Gender</th>
							  <th>Age</th>
							  <th>Marital Status</th>
							  <th>Caste</th>
							   <th>Doctor</th>
							  <th>Center</th>
							</tr>
						  </thead>
						  <tbody >
							
						  </tbody>
						</table>
					</div>
				</div> 

            </div>

			<div id="fem_child" class="tab-pane fade">

                <div class="row datepicker-div" >
                    <div class="col-sm-3">
                    <div id="datepick11" class="input-append date input-group" style="float:left;margin:auto;max-width:320px;">
                        <span class="input-group-addon">From</span>
                        <input data-format="dd/MM/yyyy" type="text" name="fromdt11" id="fromdt11"  class="form-control logCaln" required /><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>                    
                    </div>
                    </div>
                    <div class="col-sm-3">
                    <div id="datepick12" class="input-append date input-group" style="float:left;margin:auto;max-width:320px;">
                        <span class="input-group-addon">To</span>
                        <input data-format="dd/MM/yyyy" type="text" name="todt12" id="todt12" class="form-control logCaln" required /><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
                    </div>
                    </div>
                    <div class="col-sm-3">
                        <button type="button" class="btn download-btn" onclick="display6()" >Submit</button>
                    </div>
                    <div class="col-sm-3">
                        <button type="button" class="btn download-btn6" ><span class="glyphicon glyphicon-download"></span></button>
                    </div>
            
                
                </div>

				<div class="row table">
					<div class="col-sm-12 statlist6">
						<table class="table table-hover table-bordered">
						  <thead>
							<tr>
							  
							  <th>Patient Id</th>
							  <th>Patient Name</th>
							  <th>Age</th>
							  <th>Caste</th>
							   <th>Doctor</th>
							  <th>Center</th>
							</tr>
						  </thead>
						  <tbody >
							
						  </tbody>
						</table>
					</div>
				</div> 

            </div>

            <div id="sex" class="tab-pane fade">
              
                <div class="row datepicker-div" >
                    <div class="col-sm-3">
                    <div id="datepick3" class="input-append date input-group" style="float:left;margin:auto;max-width:320px;">
                        <span class="input-group-addon">From</span>
                        <input data-format="dd/MM/yyyy" type="text" name="fromdt3" id="fromdt3"  class="form-control logCaln" required /><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>                    
                    </div>
                    </div>
                    <div class="col-sm-3">
                    <div id="datepick4" class="input-append date input-group" style="float:left;margin:auto;max-width:320px;">
                        <span class="input-group-addon">To</span>
                        <input data-format="dd/MM/yyyy" type="text" name="todt4" id="todt4" class="form-control logCaln" required /><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
                    </div>
                    </div>
                    <div class="col-sm-3">
                        <button type="button" class="btn download-btn" onclick="display2()">Submit</button>
                    </div>
                    <div class="col-sm-3">
                        <button type="button" class="btn download-btn2" ><span class="glyphicon glyphicon-download"></span></button>
                    </div>
            
                
                </div>
				
				<div class="row table">
					<div class="col-sm-12 statlist2">
						<table class="table table-hover table-bordered">
						  <thead>
							<tr>
								<th>Center</th>
							  	<th>Gender</th>							  
							  	<th>Count</th>
							</tr>
						  </thead>
						  <tbody >
							
						  </tbody>
						</table>
					</div>
				</div> 


            </div>
            <div id="caste" class="tab-pane fade">
              
                
                <div class="row datepicker-div" >
                    <div class="col-sm-3">
                    <div id="datepick5" class="input-append date input-group" style="float:left;margin:auto;max-width:320px;">
                        <span class="input-group-addon">From</span>
                        <input data-format="dd/MM/yyyy" type="text" name="fromdt5" id="fromdt5"  class="form-control logCaln" required /><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>                    
                    </div>
                    </div>
                    <div class="col-sm-3">
                    <div id="datepick6" class="input-append date input-group" style="float:left;margin:auto;max-width:320px;">
                        <span class="input-group-addon">To</span>
                        <input data-format="dd/MM/yyyy" type="text" name="todt6" id="todt6" class="form-control logCaln" required /><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
                    </div>
                    </div>
                    <div class="col-sm-3">
                        <button type="button" class="btn download-btn" onclick="display3()" >Submit</button>
                    </div>
                    <div class="col-sm-3">
                        <button type="button" class="btn download-btn3" ><span class="glyphicon glyphicon-download"></span></button>
                    </div>
					
					
                
                </div>
				<div class="row table">
					<div class="col-sm-12 statlist3">
						<table class="table table-hover table-bordered">
						  <thead>
							<tr>
								<th>Center</th>							  
							  	<th>Caste</th>
								<th>Count</th>							  
							</tr>
						  </thead>
						  <tbody >
							
						  </tbody>
						</table>
					</div>
				</div> 

            </div>

			<div id="religion" class="tab-pane fade">
              
                
                <div class="row datepicker-div" >
                    <div class="col-sm-3">
                    <div id="datepick7" class="input-append date input-group" style="float:left;margin:auto;max-width:320px;">
                        <span class="input-group-addon">From</span>
                        <input data-format="dd/MM/yyyy" type="text" name="fromdt7" id="fromdt7"  class="form-control logCaln" required /><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>                    
                    </div>
                    </div>
                    <div class="col-sm-3">
                    <div id="datepick8" class="input-append date input-group" style="float:left;margin:auto;max-width:320px;">
                        <span class="input-group-addon">To</span>
                        <input data-format="dd/MM/yyyy" type="text" name="todt8" id="todt8" class="form-control logCaln" required /><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
                    </div>
                    </div>
                    <div class="col-sm-3">
                        <button type="button" class="btn download-btn" onclick="display4()" >Submit</button>
                    </div>
                    <div class="col-sm-3">
                        <button type="button" class="btn download-btn4" ><span class="glyphicon glyphicon-download"></span></button>
                    </div>
					
					
                
                </div>
				<div class="row table">
					<div class="col-sm-12 statlist4">
						<table class="table table-hover table-bordered">
						  <thead>
							<tr>
								<th>Center</th>							  
							  	<th>Religion</th>
								<th>Count</th>
							  
							</tr>
						  </thead>
						  <tbody >
							
						  </tbody>
						</table>
					</div>
				</div> 

            </div>

			<div id="religion_caste" class="tab-pane fade">
              
                
                <div class="row datepicker-div" >
                    <div class="col-sm-3">
                    <div id="datepick9" class="input-append date input-group" style="float:left;margin:auto;max-width:320px;">
                        <span class="input-group-addon">From</span>
                        <input data-format="dd/MM/yyyy" type="text" name="fromdt9" id="fromdt9"  class="form-control logCaln" required /><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>                    
                    </div>
                    </div>
                    <div class="col-sm-3">
                    <div id="datepick10" class="input-append date input-group" style="float:left;margin:auto;max-width:320px;">
                        <span class="input-group-addon">To</span>
                        <input data-format="dd/MM/yyyy" type="text" name="todt10" id="todt10" class="form-control logCaln" required /><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
                    </div>
                    </div>
                    <div class="col-sm-3">
                        <button type="button" class="btn download-btn" onclick="display5()" >Submit</button>
                    </div>
                    <div class="col-sm-3">
                        <button type="button" class="btn download-btn5" ><span class="glyphicon glyphicon-download"></span></button>
                    </div>
					
					
                
                </div>
				<div class="row table">
					<div class="col-sm-12 statlist5">
						<table class="table table-hover table-bordered">
						  <thead>
							<tr>
							  <th>Center</th>
							  <th>Caste</th>
							  <th>Religion</th>
							  <th>Count</th>
							</tr>
						  </thead>
						  <tbody >
							
						  </tbody>
						</table>
					</div>
				</div> 

            </div>



          </div>
          



    </div>
</body>

</html>

