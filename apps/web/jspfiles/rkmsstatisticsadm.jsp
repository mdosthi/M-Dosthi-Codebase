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
rcCentreInfo centerinfo = new rcCentreInfo(request.getRealPath("/"));

Object res=centerinfo.getAllCentreInfo();
int mincodeL = 100;	
JSONObject centermap = new JSONObject();
if(res instanceof String)
	out.println("No data avaliable");
else{
	Vector Vtmp = (Vector)res;
	if(Vtmp.size()>0){
		for(int j=0;j<Vtmp.size();j++){
			dataobj datatemp = (dataobj) Vtmp.get(j);
			String center_code = datatemp.getValue("code");
			mincodeL = (mincodeL<center_code.length())?mincodeL:center_code.length();
		}
		for(int j=0;j<Vtmp.size();j++){
			dataobj datatemp = (dataobj) Vtmp.get(j);
			String center_code = datatemp.getValue("code");
			String center_name = datatemp.getValue("name");
			centermap.put(center_code.substring(0, mincodeL), center_name);
			//out.println(center_code+" : "+center_name+" : "+mincodeL);
		}		
	}
}
//out.println("-----------------------------</br>"+centermap);
statisticsData = display.rkmsStatisticsAdm(weekPastDate, setDate, mincodeL);
if(request.getMethod().equalsIgnoreCase("POST") && request.getParameter("stsgenbtn") !=null){
	//out.println(request.getParameter("stsToDate")+" : "+request.getParameter("stsFromDate"));
	statisticsData = display.rkmsStatisticsAdm(request.getParameter("stsFromDate"), request.getParameter("stsToDate"), mincodeL);
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
        .centervsnop{
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
        .btn-generate-sts, .download-btn{
        	background: #eef9;
		    border: 1px solid #d3d3d3;
		    color: #110;
		    min-width: 120px;        	
        }
        .download-btn:hover > .glyphicon-download{
        	top:8px;
        	transition-duration: 0.4s;
        	transition: 0.4s;
        }
        .btn-generate-sts:hover,
        .btn-generate-sts:active,
        .btn-generate-sts:focus,
        .download-btn:hover,
        .download-btn:active,
        .download-btn:focus{
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
    			<div id="canvas-holder-center" >
                    <canvas id="chart-area-center"></canvas>
                </div>
    		</div>
    	</div>

       <!-- <div class="row charts-div">
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
        </div>-->
        <div class="row datepicker-div">
        	<form method="POST">
	        	<div class="col-sm-1"></div>
	        	<div class="col-sm-3">
					<div id="sts-datepicker-from" class="input-append date input-group">
						<span class="input-group-addon">From</span>
						<input data-format="dd/MM/yyyy" type="text" name="stsFromDate" value="<%=weekPastDate%>" class="form-control logCaln" required><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
					</div>            		
	        	</div>
	        	<div class="col-sm-3">
					<div id="sts-datepicker-to" class="input-append date input-group">
						<span class="input-group-addon">To</span>
						<input data-format="dd/MM/yyyy" type="text" name="stsToDate" value="<%=setDate%>" class="form-control logCaln" required><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
					</div>         		
	        	</div>
	        	<div class="col-sm-1"></div>
	        	<div class="col-sm-1"><button class="btn btn-generate-sts" type="submit" name="stsgenbtn">Submit</button></div>
	        	<div class="col-sm-1"></div>
	        	<div class="col-sm-1">
	        	<button type="button" class="btn download-btn" ><span class="glyphicon glyphicon-download"></span></button>
	        	</div>
	        	<div class="col-sm-1"></div>
        	</form>
        </div>
        <div class="row statistics-table">
            <div class="col-sm-12">
                <table class="table table-hover table-bordered">
                  <thead>
                    <tr>
                      <th>Center Name</th>
                      <th>From</th>
                      <th>To</th>
                      <th>Total Advised Patient</th>
                    </tr>
                  </thead>
                  <tbody id="centersts">

                  </tbody>
                </table>
            </div>
        </div>    
    </div>
<script>
    const statisticsData = JSON.stringify(<%=statisticsData%>);
    const centermap = JSON.stringify(<%=centermap%>);
	//console.log(JSON.parse(statisticsData));
	var centerName =(code) =>{
  		return JSON.parse(centermap)[code]+" ("+code+")";
	}
	const genHexColCode = (k) => {
	  	var color = [];
		for(let i=0;i<k;i++){    
		    let n = (Math.random() * 0xfffff * 1000000).toString(16);
		    color[i] = '#' + n.slice(0, 6);
		}
	  	return color;
	};	 	
	var configGender = {}	
	if (Object.keys(JSON.parse(statisticsData)).length >0) {
	   var configGender = {
				type: 'doughnut',
				data: {
						datasets: [{
								data: Object.values(JSON.parse(statisticsData)["centervsnop"]),
								backgroundColor: genHexColCode(Object.values(JSON.parse(statisticsData)["centervsnop"]).length),
								label: 'Center wise Advised Patient'
						}],
						labels: Object.keys(JSON.parse(statisticsData)["centervsnop"]).map(centerName)
				},
				options: {
					responsive: true,
					aspectRatio:4,              
					animation: {
					  onComplete: () => {
						delayed = true;
					  },
					  delay: (context) => {
						let delay = 0;
						if (context.type === 'data' && context.mode === 'default' && !delayed) {
						  delay = context.dataIndex * 300 + context.datasetIndex * 100;
						}
						return delay;
					  },                       
					}
				}
		};

		window.onload = function() {
			var ctx = document.getElementById('chart-area-center').getContext('2d');
			window.myPie = new Chart(ctx, configGender);
			var centerlist = "";
			for(let i=0;i<Object.keys(JSON.parse(statisticsData)["centervsnop"]).length;i++){
				centerlist += "<tr><td>"+Object.keys(JSON.parse(statisticsData)["centervsnop"]).map(centerName)[i]+"</td><td><%=weekPastDate%></td><td><%=setDate%></td><td>"+Object.values(JSON.parse(statisticsData)["centervsnop"])[i]+"</td></tr>";
			}
			//console.log(centerlist);
			$("#centersts").html(centerlist);
			$(".download-btn").click(function(){
				window.open("rkmsstatisticsadmDownload.jsp?weekPastDate=<%=weekPastDate%>&setDate=<%=setDate%>", '_blank');
			});    
		};
	}

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

