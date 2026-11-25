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

if(request.getParameter("stsToDate") !=null)
	setDate = request.getParameter("stsToDate");
if(request.getParameter("stsFromDate") != null)
	weekPastDate = request.getParameter("stsFromDate");

rcDisplayData display = new rcDisplayData(request.getRealPath("/"));
statisticsData = display.rkmsStatistics(weekPastDate, setDate, center);
if(request.getMethod().equalsIgnoreCase("POST") && request.getParameter("stsgenbtn") !=null){
	//out.println(request.getParameter("stsToDate")+" : "+request.getParameter("stsFromDate"));
	statisticsData = display.rkmsStatistics(request.getParameter("stsFromDate"), request.getParameter("stsToDate"), center);
}

%>


<!DOCTYPE html>
<!--
@Auther Surajit Kundu
-->

<html>

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/bootstrap.min.css">
	<link rel="stylesheet" href="../bootstrap/bootstrap-datetimepicker.min.css">
	<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.css">
	<script src="../bootstrap/jquery-2.2.1.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/js/bootstrap.min.js"></script>
	<script src="../bootstrap/bootstrap-datetimepicker.min.js"></script>
	<script src="../bootstrap/bootstrap-datetimepicker.pt-BR.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/jquery.dataTables.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.js"></script>
    <script src="<%=request.getContextPath()%>/bootstrap/js/moment.min.js"></script>
    <script src="<%=request.getContextPath()%>/bootstrap/js/Chart.min.js"></script>
    <script src="<%=request.getContextPath()%>/bootstrap/js/utils.js"></script>
    <style>
        .charts-div{
            padding: 10px;
            margin: 10px 0;
            background: #fdfdfd;
            box-shadow: 0px 0px 4px 2px #333;
            border-radius: 8px; 
        }
        #canvas-holder-gender{
            border-right: 1px solid #C0C0C0;
        }
        .statistics-table thead{
            background: #333;
            color: #dfdfdf;    
        }
        .statistics-table tr{
            box-shadow: 0px 2px 4px 0px #333;
            font-size: 14px;    
        }
        .statistics-table tbody tr:hover{
            background: #eef;
            transition-duration: 0.4s;
        }
        .download-btn{
            margin: auto;
            display: block;   
        }
        .datepicker-div{
		    margin: 10px 0;
		    background: #333;
		    box-shadow: 0px 0px 1px 1px #ddd;
		    border-radius: 4px;
		    padding: 4px;        	
        }
        .btn-generate-sts{
        	background: #eef9;
		    border: 1px solid #d3d3d3;
		    color: #110;
		    min-width: 120px;        	
        }
        .btn-generate-sts:hover,
        .btn-generate-sts:active,
        .btn-generate-sts:focus{
        	outline: 0 !important;
			background: #eef;
        }
        .heading-title{text-align: center;}
    </style>

</head>

<body>
    <div class="container-fluid">
    	<h3 class="heading-title"> <B>View Statistics of <%=centername%> (<%=center%>)</B></h3>
    	<div class="row centervsnop">
    		<div class="col-sm-12">
    			<div id="canvas-holder-center">
                    <canvas id="chart-area-center"></canvas>
                </div>
    		</div>
    	</div>

        <div class="row charts-div">
            <div class="col-sm-6">
                <div id="canvas-holder-gender">
                        <canvas id="chart-area-gender"></canvas>
                </div>
            </div>
            <div class="col-sm-6">
                <div id="canvas-holder-date" >
                        <canvas id="examChart"></canvas>
                </div>
            </div>            
        </div>
        <div class="row datepicker-div">
        	<form method="POST">
	        	<div class="col-sm-1"></div>
	        	<div class="col-sm-4">
					<div id="sts-datepicker-from" class="input-append date input-group">
						<span class="input-group-addon">From</span>
						<input data-format="dd/MM/yyyy" type="text" name="stsFromDate" value="<%=weekPastDate%>" class="form-control logCaln" required><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
					</div>            		
	        	</div>
	        	<div class="col-sm-4">
					<div id="sts-datepicker-to" class="input-append date input-group">
						<span class="input-group-addon">To</span>
						<input data-format="dd/MM/yyyy" type="text" name="stsToDate" value="<%=setDate%>" class="form-control logCaln" required><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
					</div>         		
	        	</div>
	        	<div class="col-sm-2"><button class="btn btn-generate-sts" type="submit" name="stsgenbtn">Submit</button></div>
	        	<div class="col-sm-1"></div>
        	</form>
        </div>
        <div class="row statistics-table">
            <div class="col-sm-12">
                <table class="table table-hover table-bordered">
                  <thead>
                    <tr>
                      <th>Total patient</th>
                      <th>Male</th>
                      <th>Female</th>
                      <th>Other</th>
                      <th>Not Stated</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td id="totalpat-no"></td>
                      <td id="M"></td>
                      <td id="F"></td>
                      <td id="O"></td>
                      <td id="N"></td>
                    </tr>
                  </tbody>
                </table>
            </div>
        </div>    
        <input type="button" class="btn btn-info download-btn" value="Download Statistics" />
    </div>
<script>
    const statisticsData = JSON.stringify(<%=statisticsData%>);
	console.log(JSON.parse(statisticsData));
	var totalpat = 0, totalpatArrname = 0, totalPatArr=0;
	if(JSON.parse(statisticsData)["gendersts"]!=undefined){
		totalpatArrname = JSON.parse(statisticsData)["gendersts"][0];
		totalPatArr = JSON.parse(statisticsData)["gendersts"][1];
		totalpat = totalPatArr.reduce((a, b) => Number(a) + Number(b));
	}
	 	
    var configGender = {
            type: 'pie',
            data: {
                    datasets: [{
                            data: totalPatArr,
                            backgroundColor: [
                                    "#ff1a75",
                                    "#0055ff",
                                    "#990000",
                                    "#ff5500",
                            ],
                            label: 'Dataset 1'
                    }],
                    labels: totalpatArrname
            },
            options: {
                responsive: true       
            }
    };

    var configDateWise = {
        type: 'line',
        options: {
          scales: {
            xAxes: [{
              type: 'time',
            }]
          }
        },
        data: {
          datasets: [{
            label: 'Date Wise No of Advice',
            data: JSON.parse(statisticsData)["advsts"],
            backgroundColor: [
              'rgba(255, 99, 132, 0.2)',
              'rgba(54, 162, 235, 0.2)',
              'rgba(255, 206, 86, 0.2)',
              'rgba(75, 192, 192, 0.2)',
              'rgba(153, 102, 255, 0.2)',
              'rgba(255, 159, 64, 0.2)'
            ],
            borderColor: [
              'rgba(255,99,132,1)',
              'rgba(54, 162, 235, 1)',
              'rgba(255, 206, 86, 1)',
              'rgba(75, 192, 192, 1)',
              'rgba(153, 102, 255, 1)',
              'rgba(255, 159, 64, 1)'
            ],
            borderWidth: 1
          }]
        }
    };

    window.onload = function() {
        var ctx = document.getElementById('chart-area-gender').getContext('2d');
        window.myPie = new Chart(ctx, configGender);
        var ctx1 = document.getElementById("examChart").getContext("2d");
        window.myLine = new Chart(ctx1, configDateWise);  
        $("#totalpat-no").html(totalpat);
		for(let i=0; i<totalPatArr.length; i++){
			$("#"+totalpatArrname[i]).html(totalPatArr[i]);
		}    
		$(".download-btn").click(function(){
			window.open("rkmsstatisticsDownload.jsp?totalpat="+totalpat+"&totalpatArrname="+totalpatArrname+"&totalPatArr="+totalPatArr, '_blank');
		});    
    };


	$(function () {
    var startDate = new Date("21/10/1995"),
        endDate = new Date("<%=today%>");
		$('#sts-datepicker-from').datetimepicker({
			autoclose: 1
		});
		$('#sts-datepicker-to').datetimepicker({
			autoclose: 1
		});		
	});	

</script>
</body>
</html>

