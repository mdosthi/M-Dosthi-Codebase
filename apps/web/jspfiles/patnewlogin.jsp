<%@page language="java"  import= "org.json.*, imedix.rcUserInfo,imedix.rcCentreInfo,imedix.dataobj, imedix.cook,java.util.*,java.io.*"%>
<%@page import="imedix.Email,imedix.projinfo"%>  
<!DOCTYPE html>
<html >
  <head>

    <title>mDosthi</title>
    <link id="page_favicon" href="<%=request.getContextPath()%>/images/icons/mdosthi-favicon-32.png?v=4" rel="icon" type="image/png" />
    <link rel="alternate icon" href="<%=request.getContextPath()%>/favicon.ico?v=4" type="image/x-icon" />
	<meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="<%=request.getContextPath()%>/style/mdosthi-brand-tokens.css" />
  	<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/captcha.css" />	

  <script src="<%=request.getContextPath()%>/bootstrap/jquery-2.2.1.min.js"></script>
  <script src="<%=request.getContextPath()%>/bootstrap/js/bootstrap.min.js"></script>
	<script src="<%=request.getContextPath()%>/bootstrap/captcha.js"></script>
<style>
body {
    background: linear-gradient(180deg, var(--color-ice, #E0F7FA) 0%, #FFFFFF 100%);
    font-family: var(--font-body, 'Inter', sans-serif);
    color: var(--color-navy, #0B2D6B);
    min-height: 100vh;
}
.im-login-form {
    background: #FFFFFF;
    border-radius: 20px;
    border: 1.5px solid rgba(0, 191, 166, 0.25);
    box-shadow: 0 14px 36px rgba(11, 45, 107, 0.10);
}
.im-login-form h2 { font-family: var(--font-heading, 'Poppins', sans-serif); color: var(--color-navy, #0B2D6B); }
.im-login-form a { color: var(--color-blue, #007BFF); }
.im-login-form .btn-primary, .im-login-form input[type="submit"] {
    background: var(--gradient-cta, linear-gradient(135deg, #0B2D6B 0%, #007BFF 50%, #00BFA6 100%));
    border: none;
    border-radius: 999px;
}
input:invalid,
input:out-of-range {
    border-color:hsl(0, 50%, 50%);
    background:hsl(0, 50%, 90%);
}
</style>
</head>
<body>
<br><br>
  <div class="im-login-form col-sm-6 col-sm-offset-3 well well-lg">
  <div style="text-align:center; margin-bottom:10px;">
    <img src="<%=request.getContextPath()%>/images/mdosthi-primary-logo.png" alt="mDosthi" style="max-width:300px; width:100%; height:auto;" />
  </div>
  <br>
  <a href="https://imedix.iitkgp.ac.in/iMediX/" target=_self>iMediX Home</a> | 
    <a href="javascript:window.history.go(-1)" target=_self>Go Back</a>
 <hr>
 <%
	if(request.getParameter("submit")!=null)
	{
		rcUserInfo ruser=new rcUserInfo(request.getRealPath("/"));	
		String emailid=request.getParameter("emailid").trim();
		String patid=request.getParameter("patid").trim();
		String patname=request.getParameter("patname").trim();
		
		
		Object res=ruser.getPatientData(patid);
		if(!(res instanceof String)){
			Vector tmp = (Vector)res;
			if(tmp.size()<=0) {
				out.println ("<h3><font color=red>It seems this is an InCorrect PATID ( <b>"+patid+"</b>).</font></h3>");
			}
			else {
				dataobj dobj = (dataobj)tmp.get(0);
				patname = dobj.getValue("pat_name");

				dataobj newobj = new dataobj();
				newobj.add("emailid", emailid);
				newobj.add("pat_id", patid);
				newobj.add("pat_name", patname);
				int res1 = ruser.addLoginRequest(newobj);
				if(res1 == 0 )
					out.println ("<h3><font color=red>It seems there is an error!! P1ease try after sometime.</font></h3>");
				else
					out.println ("<h3><font color=blue>You request has been forwarded. Please wait for confirmation mail from the Administrator</font></h3>");
			}
			
		}
		else {
			out.println ("<h3><font color=red>It seems this is an InCorrect PATID ( <b>"+patid+"</b> ).</font></h3>");
		}
	} 
	else {
%>
    <form METHOD="POST" ACTION="patnewlogin.jsp" name="frmLog" role = "form" onSubmit="return CheckCaptcha()">
	<center><h2>iMediX</h2><p>Request for New Login?</p></center>
	Dear Patient, <br>
	Please provide your EmailID,UID and Patient Name and click Submit button.
      <input class="form-control inpt-bx"  type = "email" name="emailid" id="emailid" placeholder = "EmailID" class="required  email" required/><br>
	   <input class="form-control inpt-bx"  type = "text" name="patid" id="patid" placeholder = "iMediX UserID" class="required" required/><br>
	    <input class="form-control inpt-bx"  type = "text" name="patname" id="patname" placeholder = "Patient Name" class="required" required/>
	  <br>
	     <div class="captchaField">
    <span id="SuccessMessage" class="success">Thanks! , The Captcha Is Correct!</span>
    <input type="text" id="UserCaptchaCode" class="CaptchaTxtField required" placeholder='Enter Captcha - Case Sensitive' required>
    <span id="WrongCaptchaError" class="error"></span>
    <div class='CaptchaWrap'>
      <div id="CaptchaImageCode" class="CaptchaTxtField">
        <canvas id="CapCode" class="capcode" width="300" height="80"></canvas>
      </div> 
      <input type="button" class="ReloadBtn" onclick='CreateCaptcha();'>
    </div>
  </div>
         <input class="btn btn-primary subm-btn" type="submit" value="Submit" name="submit" id="submit" >
	   <br><br>

    </form>
	<% } //else %>
  </div>
  <br>
</body>
</html>