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
	});	
});

$(".download-btn1").click(function(){

	var fromdt=$("#fromdt1").val();
	var todt=$("#todt2").val();
	//var center=$("input[name=centerhos]").val();
	var center=$("#centerhos option:selected").val();
	console.log(fromdt);
	console.log(todt);
	console.log(center);
	var param = {fromdt:fromdt, todt:todt, center:center,tag:"center"};
	var c="center";

	window.open("statistics/download/Download_stat_visit.jsp?fromdt="+fromdt+"&todt="+todt+"&center="+center+"&tag="+c, '_blank');


	
}); 

$(".download-btn2").click(function(){

	var fromdt=$("#fromdt3").val();
	var todt=$("#todt4").val();
	var patid=$(".patid").val();
	console.log(fromdt);
	console.log(todt);
	var param = {fromdt:fromdt, todt:todt,patid:patid,tag:"patient"};
	var c="patient";

window.open("statistics/download/Download_stat_visit.jsp?fromdt="+fromdt+"&todt="+todt+"&patid="+patid+"&tag="+c, '_blank');



}); 






function  display()
{
	var fromdt=$("#fromdt1").val();
	var todt=$("#todt2").val();
	//var center=$("input[name=centerhos]").val();
	var center=$("#centerhos option:selected").val();
	console.log(fromdt);
	console.log(todt);
	console.log(center);
	var param = {fromdt:fromdt, todt:todt, center:center,tag:"center"};
	$.ajax({
					type: 'GET',
					url: "statistics/stat_visit.jsp",
					data: param,
					dataType: "text",
					success: function(data)
					{
						$(".statlist tbody").empty();
						$(".statlist tbody").append(data.trim());


					}
				});

}

function  display2()
{
	var fromdt=$("#fromdt3").val();
	var todt=$("#todt4").val();
	var patid=$(".patid").val();
	console.log(fromdt);
	console.log(todt);
	var param = {fromdt:fromdt, todt:todt,patid:patid,tag:"patient"};
	$.ajax({
					type: 'GET',
					url: "statistics/stat_visit.jsp",
					data: param,
					dataType: "text",
					success: function(data)
					{
						$(".statlist2 tbody").empty();
						$(".statlist2 tbody").append(data.trim());


					}
				});
	
}


$(document).ready(function(){
		
		$.getJSON('../includes/disease.json', function(jd) {
			var arrItems = [];      // THE ARRAY TO STORE JSON ITEMS.
				$.each(jd, function (index, value) {
					arrItems.push(value);       // PUSH THE VALUES INSIDE THE ARRAY.
				});
				
			//console.log("jd:"+arrItems);
			$('.diagnosis').autocomplete({
					source: arrItems,
				onSelect: function (suggestion) {
					console.log('You selected: ' + suggestion.value + ', ' + suggestion.data);
				}
			});	
			
		});
	});		

</script>

<body>
    
    <div class="container-fluid">



        <ul class="nav nav-tabs nav-justified">
            <li class="active"><a data-toggle="tab" href="#gcs">Visit-wise by Centre</a></li>
            <li><a data-toggle="tab" href="#dsc">Visit-wise by Patient</a></li>
            <!--<li><a data-toggle="tab" href="#caste">Total stat by Caste</a></li>         -->   
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
                    <!--<div class="col-sm-4">
						<textarea class='diagnosis'  />
                        
                    </div>-->
                    <div class="col-sm-4">
                    <span class="input-group-addon" style="color:blue;font-weight:bold">Select Center :</span>
                    <select class="form-control" name="centerhos" id="centerhos">
                    <%
                        out.println("<option value='XXXX' 'selected'>All Hospital</option><br>");
                            try
                            {
                            //if(ccode.equals("XXXX")){
                                rcCentreInfo rcci=new rcCentreInfo(request.getRealPath("/"));
                                Object res=rcci.getAllCentreInfo();
                                if(res instanceof String){ out.println("<option value='NIL' >No match Found</option>"); }
                                else{
                                    Vector Vtmp = (Vector)res;
                                        for(int j=0;j<Vtmp.size();j++){
                                            dataobj datatemp = (dataobj) Vtmp.get(j);
                                            out.println("<option value="+datatemp.getValue("code")+">"+datatemp.getValue("name")+"</option><br>");
                                            /*if(datatemp.getValue("code").equals(sccode)){
                                                out.println("<option value="+datatemp.getValue("code")+" selected>"+datatemp.getValue("name")+"</option><br>");
                                            }else{
                                                out.println("<option value="+datatemp.getValue("code")+">"+datatemp.getValue("name")+"</option><br>");
                                            }*/
                                        } // end for
                                }// end else
                            //}
                            }catch(Exception e)
                            {
                                out.println("error.."+e.getMessage());
                            }

                    %>
                        </select>
                        </div>		<!-- "input-group" -->

                    


					<div class="col-sm-1">
                        <button type="button" class="btn download-btn" onclick="display()" >Submit</button>
                    </div>
                    <div class="col-sm-1">
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
							  <th>Count</th>							  
							</tr>
						  </thead>
						  <tbody >
							
						  </tbody>
						</table>
					</div>
				</div> 

            </div>


            <div id="dsc" class="tab-pane fade">
              
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
						<textarea class='patid' placeholder="Enter Patient Id" required  />
                        
                    </div>
                    <div class="col-sm-1">
                        <button type="button" class="btn download-btn" onclick="display2()">Submit</button>
                    </div>
                    <div class="col-sm-1">
                        <button type="button" class="btn download-btn2" ><span class="glyphicon glyphicon-download"></span></button>
                    </div>
            
                
                </div>
				
				<div class="row table">
					<div class="col-sm-12 statlist2">
						<table class="table table-hover table-bordered">
						  <thead>
							<tr>
							  
								<th>Patient Id</th>
								<th>Patient Name</th>
								<th>Entrydate</th>
								<th>Visit Number</th>
							</tr>
						  </thead>
						  <tbody >
							
						  </tbody>
						</table>
					</div>
				</div> 


            </div>
			

    </div>
</body>

</html>

