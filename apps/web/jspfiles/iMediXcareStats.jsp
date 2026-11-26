<!--Soumyajit-->

<%@page contentType="text/html"
	import="imedix.rcCentreInfo,imedix.dataobj,imedix.rcDisplayData, imedix.cook, java.util.*, java.io.*, imedix.myDate, java.text.SimpleDateFormat, org.json.simple.*, org.json.simple.parser.*"
	%>
	<%@page contentType="text/html"
		import="imedix.rcimedixstat,imedix.layout,java.io.*,imedix.rcDataEntryFrm,imedix.cook,imedix.rcPatqueueInfo,imedix.rcGenOperations,imedix.rcUserInfo,imedix.dataobj,imedix.rcVideoConference, java.util.*, imedix.projinfo, imedix.UserAccessCheck"
		%>
		<%@ include file="../includes/chkcook.jsp" %>
			<html>
			<title>mDosthi</title>

			<head>
				<meta charset="utf-8">
				<meta name="viewport" content="width=device-width, initial-scale=1">
				<link rel="icon" type="image/png" sizes="32x32"
					href="<%=request.getContextPath()%>/images/icons/mdosthi-favicon-32.png?v=4" />
				<link rel="icon" type="image/png"
					href="<%=request.getContextPath()%>/images/icons/mdosthi-favicon.png?v=4" />
				<link rel="alternate icon" type="image/x-icon" href="<%=request.getContextPath()%>/favicon.ico?v=4" />
				<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/bootstrap.min.css">
				<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/toastr.css">
				<!--<link rel="stylesheet" href="../bootstrap/jquery.dataTables.min.css">-->
				<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.css">
				<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/index.css?v=6.0">

				<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/jquery-ui.min.css">
				<link rel="stylesheet" href="<%=request.getContextPath()%>/vc/vc.css?" +n>

				<script src="<%=request.getContextPath()%>/bootstrap/jquery-2.2.1.min.js"></script>
				<script src="<%=request.getContextPath()%>/bootstrap/toastr.js"></script>
				<script src="<%=request.getContextPath()%>/bootstrap/js/bootstrap.min.js"></script>
				<script src="<%=request.getContextPath()%>/bootstrap/jquery.dataTables.min.js"></script>
				<script src="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.js"></script>
				<script src="<%=request.getContextPath()%>/bootstrap/jquery-ui.min.js?" +n></script>




			</head>
			<style>
				/* If the screen size is 601px wide or more, set the font-size of <div> to 40px */
				@media screen and (min-width: 601px) {
					.module-name {
						font-size: 50px;
					}
				}

				/* If the screen size is 600px wide or less, set the font-size of <div> to 24px */
				@media screen and (max-width: 600px) {
					.module-name {
						font-size: 20px;
					}

					.img2-responsive.logo2 {
						border-radius: 50%;
					}
				}

				.img1-responsive.logo1 {
					left: -10px;
					top: 20px;
					width: 120px;
					padding: 0px 6px;
					border: 1px solid #ddd;
					box-shadow: 0px 0px 8px 3px #ccc;
					position: relative;

				}

				.img2-responsive.logo2 {
					top: 4px;
					left: 12px;
					height: 90px;
					padding: 4px 4px;
					z-index: 9;
					position: absolute;
					border: 1px solid #ddd;
					box-shadow: 0px 0px 8px 3px #ccc;

				}

				.module-name {
					font-weight: 700;
					text-align: center;
					font-family: 'Poppins', sans-serif;
					color: var(--brand-navy, #0B3B78);
					margin: 0;
				}

				.center-name {
					background-color: steelblue;
				}

				.di .chk-lg {
					width: 20px;
					height: 16px;
				}

				.left>div.active {
					border: 2px solid #607D8B;
					background: #eef;
					color: #333;
				}

				#search-result {
					margin-top: 20px;
				}
			</style>
			<script>
				function clearPanel(fileName) {
					document.getElementById("main_frame").innerHTML = "<object class='responsive obj' type='text/html' data=<%=request.getContextPath()%>/jspfiles/" + fileName + " style='width:100%; height:100%;'>> </object>";
				}
			</script>
			<script>

				function main_frame(url) {
					console.log(url);
					$('#main_frame').load(url);
					//document.getElementById("main_frame").innerHTML= "<object class='responsive obj' type='text/html' data=<%=request.getContextPath()%>/jspfiles/"+url+" style='width:100%; height:100%;'>> </object>";			
				}

				$(document).ready(function () {

					$(".nv a").on("click", function () {
						console.log("clicked");
						$(".nav").find(".active").removeClass("active");
						$(this).parent().addClass("active");
					});
				});


			</script>

			<body class="index">
				<div class="container-fluid">
					<div class="row header">

						<div class="col-md-3 brand-container">
							<a href="<%=request.getContextPath()%>/" class="brand-link"><img class="header-horiz-logo"
									src="<%=request.getContextPath()%>/images/mdosthi-horizontal-logo.png" alt="mDosthi" /></a>
						</div>


						<div class="col-md-8">
							<p class="module-name">mDosthi Statistics</p>
						</div>

						<div class="col-md-1 account">
							<div class="logout" onclick='clearPanel("logout.jsp?templateid=1&menuid=")'><span
									class="glyphicon glyphicon-off glph-lg"
									title='logout.jsp?templateid=1&menuid='></span></div>
						</div>

					</div>

					<div class="row body">


						<nav class="navbar navbar-inverse" style="top: 25px;">
							<div class="container-fluid">
								<!--<div class="navbar-header">
							<a class="navbar-brand" href="#">WebSiteName</a>
						  </div> class="active" data-toggle="collapse"-->
								<ul class="nav navbar-nav">
									<li class="nv" onclick="main_frame(this.getAttribute('value'))"
										value="statistics/stats1.jsp"><a href="#">Demographic Report</a></li>
									<li class="nv" onclick="main_frame(this.getAttribute('value'))"
										value="statistics/stats2.jsp"><a href="#">Disease-wise Report</a></li>
									<li class="nv" onclick="main_frame(this.getAttribute('value'))"
										value="statistics/stats3.jsp"><a href="#">Visit-wise Report</a></li>
									<!--<li class="nv"><a href="#">Clinical Report</a></li>-->
								</ul>
							</div>
						</nav>

						<br>
						<div class="col-sm-12 main-body" id="main_frame">


						</div>
					</div>


				</div>



			</body>

			</html>