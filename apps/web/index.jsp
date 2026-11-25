<%
if(session.getAttribute("uid")==null || session.getAttribute("uid")=="");
else if(String.valueOf(session.getAttribute("utype")).equalsIgnoreCase("pat"))
	response.sendRedirect(response.encodeRedirectURL("jspfiles/patient?templateid=1&menuid=head1&dest=patientAlldata&id="+session.getAttribute("uid")));
else
	response.sendRedirect("jspfiles/home");

%>
      <%
      	String visitStatus = "";
		Integer hitsCount = (Integer)application.getAttribute("hitCounter");
		if( hitsCount ==null || hitsCount == 0 ) {
			/* First visit */
			visitStatus = "Welcome to M-Dosthi!";
			hitsCount = 1;
		} else {
			/* return visit */
			visitStatus = "Total "+hitsCount+" users visited to M-Dosthi!";
			hitsCount += 1;
		}
		application.setAttribute("hitCounter", hitsCount);
      %>


<!DOCTYPE html>
<html lang="en">
<head>
	<title>M-Dosthi</title>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="icon" type="image/svg+xml" href="<%=request.getContextPath()%>/images/icons/m-dosthi-favicon.svg"/>
	<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/bootstrap.min.css">
	<link rel="stylesheet" type="text/css" href="<%=request.getContextPath()%>/bootstrap/font-awesome-4.7.0/css/font-awesome.min.css">
	<link rel="stylesheet" type="text/css" href="<%=request.getContextPath()%>/bootstrap/css/animate.css">
	<link rel="stylesheet" type="text/css" href="<%=request.getContextPath()%>/bootstrap/css/hamburgers.min.css">
	<link rel="stylesheet" type="text/css" href="<%=request.getContextPath()%>/bootstrap/css/select2.min.css">
	<link rel="stylesheet" type="text/css" href="<%=request.getContextPath()%>/bootstrap/css/util.css">
	<link rel="stylesheet" type="text/css" href="<%=request.getContextPath()%>/bootstrap/css/main.css">


	<style>
		.footer{		  
		  font-size: 12px;		  
		  letter-spacing: 1px;
		  transition: .5s;
   
		}
		.footer:hover{
		  letter-spacing: 3px;
		}
	  </style>


</head>
<body>
	
	<div class="limiter hidden-xs">
		<div class="container-login100">
			<div class="wrap-login100">
				<div class="col-md-8 col-65" style=" padding: 15px 15px 15px 15px;">
					<div class="features-details">
						<div class="features-title">
							<div style="text-shadow: 3px 3px #a1a3a5;font-family:Georgia, 'Times New Roman', Times, serif  ;font-size: 90px;color: #0099ff;">M-Dosthi</div>
						</div>
					</div>
					<%-- <div class="login100-pic "  >
						<img src="images/aiimsk.png" style="border-radius:10% ;max-width: 20%;" alt="IMG">
					</div>
					<div class="login100-pic "  >
						<img src="images/iitkgp.png" style="border-radius:10% ;max-width: 20%;" alt="IMG">
					</div> --%>


					<%-- <div class="login100-pic " style="text-align: center;">
					    <img src="images/aiimsk.png" alt="Image 1" style="display: inline-block; width: 200px; margin-right: 10px;">
					    <img src="images/iitkgp.png" alt="Image 2" style="display: inline-block; width: 200px;">
					</div> --%>
					<div style="display: flex; justify-content: center; align-items: center; gap: 30px; width: 100%;">
					    <div class="image-box login100-pic" style="flex: 1; max-width: 220px;">
					        <img src="images/aiimsk.png" alt="Image 1" style="border-radius:10%; width: 100%; height: auto;">
					    </div>
					    <div class="image-box login100-pic" style="flex: 1; max-width: 220px;">
					        <img src="images/iitkgp.png" alt="Image 2" style="border-radius:10%; width: 100%; height: auto;">
					    </div>
					</div>


					<%-- <div class="login100-pic "  >
						<img src="images/icmr.png" style="border-radius:10% ;max-width: 6%;" alt="IMG">
					</div>  --%>
					<div class="features-details">
						<div class="features-title">
							<div class="login100-pic "style="text-shadow: 2px 1px #a1a3a5;font-size: 20px;color: brown;">Sponsored by ICMR
							<img src="images/icmr.png" style="border-radius:10% ;max-width: 6%;margin-left: 15px;" alt="IMG">


							</div>
							<%-- <div style="color: #A52A2A"></p>Ramakrishna Mission Home of Service<br>
							Varanasi</div> --%>
						</div>
						<!--<div class="features-title">
							An Open-Source Telemedicine System
						</div>
						<div class="row features">
						  <div class="col-md-6"><div class="features-list">Telemedicine</div></div>
						  <div class="col-md-6"><div class="features-list">Digital Healthcare</div></div>
						  <div class="col-md-6"><div class="features-list">Tele Consultation</div></div>
						  <div class="col-md-6"><div class="features-list">Electronic Health Records Monitoring</div></div>					 
						</div>-->
					
					</div>	
				</div>

				<div class="col-md-4 col-35">
					<!-- <div class="login100-pic js-tilt" data-tilt>
						<img src="images/imlogoOS.jpg" alt="IMG">
					</div> -->
					<div class="login100-pic " style="padding: 40px;">
						<div role="img" aria-label="M-Dosthi" style="display: inline-block; width: 240px; padding: 28px 12px; border-radius: 50%; background: #1976b8; color: #fff; font-family: Georgia, 'Times New Roman', Times, serif; font-size: 38px; font-weight: bold; text-align: center; text-shadow: 2px 2px #12517d; box-shadow: 0 6px 14px rgba(0,0,0,.25);">M-Dosthi</div>
					</div>
				<form class="login100-form validate-form" METHOD="POST" ACTION="jspfiles/login_n.jsp" name="frmLog" role = "form" >
					<!--<span class="login100-form-title">
						 M-Dosthi Login
					</span>-->
					<span class="login-msg"></span>
					<div class="wrap-input100 validate-input" data-validate = "Valid username is required">
						<input class="input100" type="text" name="uid" id="uid" placeholder = "Username"  >
						<span class="focus-input100"></span>
						<span class="symbol-input100">
							<i class="fa fa-envelope" aria-hidden="true"></i>
						</span>
					</div>

					<div class="wrap-input100 validate-input" data-validate = "Password is required">
						<input class="input100" type="password" name="pwd" id="pwd" placeholder="Password">
						<span class="focus-input100"></span>
						<span class="symbol-input100">
							<i class="fa fa-lock" aria-hidden="true"></i>
						</span>
					</div>				


					<div class="container-login100-form-btn">
						<input class="login100-form-btn subm-btn" type="submit" value="Login"/>
					</div>

				</form>
				<!--<div class='welcome-title'><%=visitStatus%></div>
					<div class='sys-details'>
						A Linux Based Multi-Tier Telemedicine System.
			</div>				
			</div>-->
			</div>
		</div>
	</div>
	
	

<nav class="hidden-xs footer" style="height: fit-content;">
            <span ><center>
	<b><u>M-Dosthi Telemedicine System</u></b><br>
	Developed and designed at Computer Science & Engineering Department, <b>IIT Kharagpur</b></br>
	<b>Contact: Prof. Jayanta Mukhopadhyay, <a href="mailto:jay@cse.iitkgp.ac.in">jay@cse.iitkgp.ac.in</a>, Phone: +91-3222-283484</b>
	</center></span>

    </nav>	
	</div>



<div class="col-sm-12 sk hidden visible-xs" style="background:#fff;border-radius:5px;">
<div class="surajit hidden-sm" ><br><br>
<%-- <center><img src="images/imlogo.jpg" class="hidden-sm visible-xs img-responsive" height="100px" width="100px"></center><br> --%>
<%-- <div style="display: flex; justify-content: center; align-items: center; gap: 10px; width: 100%;">
					    <div class="image-box login100-pic" style="flex: 1; max-width: 150px;">
					        <img src="images/aiimsk.png" alt="Image 1" style="border-radius:10%; width: 100%; height: auto;">
					    </div>
					    <div class="image-box login100-pic" style="flex: 1; max-width: 150px;">
					        <img src="images/iitkgp.png" alt="Image 2" style="border-radius:10%; width: 100%; height: auto;">
					    </div>
					</div> --%>
	<center>
	<div >
	    <div class="image-box login100-pic" style="display: inline-block; margin-right: 2px;">
	        <img src="images/aiimsk.png" alt="Image 1" style="flex: 1;border-radius:10%; max-width: 50px;">
	    </div>
	    <div class="image-box login100-pic" style="display: inline-block;">
	        <img src="images/iitkgp.png" alt="Image 2" style="flex: 1;border-radius:10%; max-width: 50px;">
	    </div>
	</div>
	</center>

 <form METHOD="POST" ACTION="jspfiles/login_n.jsp" Name="frmLog" class = " well bs-example bs-example-form " role = "form">
 	<span class="login-msg"></span>
 <center><div class = "input-group input-group-lg"><span class=" glyphicon glyphicon-plus-sign blue"></span><span class="input-lg"><strong>M-Dosthi L</strong>ogin</span>
      </div></center><br>
      <div class = "input-group">
         <span class = "input-group-addon" data-toggle="tooltip" data-placement="top" title="Enter Mail-Id" ><span class="glyphicon glyphicon-user"></span></span>
         <input type = "text" name="uid" id="uid" class = "form-control" placeholder = "Username">
      </div><br>
	  <div class = "input-group">
         <span class = "input-group-addon" data-toggle="tooltip" data-placement="top" title="Enter Password" ><span class="glyphicon glyphicon-lock"></span></span>
         <input type = "password" name="pwd" id="pwd" class = "form-control" placeholder = "Password">
      </div><br>

	  	  <div class="row">
	  <div class="col-sm-9">
	  <div class = "input-group" style="margin: auto;">
          <button type="submit" class="btn btn-primary btn-block" style="padding: 6px 50px;">Login</button>
      </div>
	  </div><!--col-sm-5-->
	  <!--<br><div class="col-sm-3" style="margin: auto;display: table;"><a href="forms/pat_reg.jsp" style="font-size:15px"><b>New Patient Registration</b></a>-->
    <br>
  </form>
  
	  </div><!--col-sm-2-->
     </div><!--col-sm-5-->

	   <!-- <br><div class="well">A Linux Based Open Source Multi-Tier Secure Telemedicine System
to provide internet based management support to hospitals/doctor</div> -->
	<br><div class="well" style="text-align: center;"><b><u>M-Dosthi Telemedicine System</u></b><br>
		Developed and designed at Computer Science & Engineering Department, <b>IIT Kharagpur</b></br>
		<b>Contact: Prof. Jayanta Mukhopadhyay, <a href="mailto:jay@cse.iitkgp.ac.in">jay@cse.iitkgp.ac.in</a>, Phone: +91-3222-283484</b></div>
  <br><center><div style="color:red;">*Recommened Browser- Google Chrome(version-84.0.4147.125 or above)</div></center>
	  </div>



</div>
</div><!--col-sm-4 sk-->




	<script src="<%=request.getContextPath()%>/bootstrap/jquery-2.2.1.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/js/popper.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/js/bootstrap.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/js/select2.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/js/tilt.jquery.min.js"></script>
	<script >
		$('.js-tilt').tilt({
			scale: 1.1
		})
	</script>
<!--===============================================================================================-->
	<script src="<%=request.getContextPath()%>/bootstrap/js/login.js"></script>



<script>
	// this is the id of the form
	$("form").submit(function(e) {

	    e.preventDefault(); // avoid to execute the actual submit of the form.
	    var form = $(this);
	    var url = "jspfiles/login_n.jsp";
	    //alert(form.serialize());
	    $(".login-msg").html("");
	    $.ajax({
	           type: "POST",
	           url: url,
	           data: form.serialize(), // serializes the form's elements.
	           success: function(data)
	           {
	           		//alert(data);
					//console.log(data);
	               if(data.trim()==0)
	               		$(".login-msg").html("<i class='fa fa-exclamation-triangle' aria-hidden='true'></i> Wrong username and password");
			else
	               		location.reload();
	           }
	         });

	    
	});

</script>	
</body>
</html>
