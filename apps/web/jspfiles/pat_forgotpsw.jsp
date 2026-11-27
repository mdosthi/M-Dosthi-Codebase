

\\Delete for open-source version


 
<!DOCTYPE html>
<html >
  <head>

<title>mDosthi</title>
<link id="page_favicon" href="<%=request.getContextPath()%>/images/icons/mdosthi-favicon-32.png?v=4" rel="icon" type="image/png" />
<link rel="alternate icon" href="<%=request.getContextPath()%>/favicon.ico?v=4" type="image/x-icon" />
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/bootstrap.min.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/style/mdosthi-brand-tokens.css">
<script src="<%=request.getContextPath()%>/bootstrap/jquery-2.2.1.min.js"></script>
<script src="<%=request.getContextPath()%>/bootstrap/js/bootstrap.min.js"></script>

<link rel="stylesheet" href="login_css/style.css">  
<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/captcha.css" />	
<script src="<%=request.getContextPath()%>/bootstrap/captcha.js"></script>  
<style>
body {
    background: linear-gradient(180deg, var(--color-ice, #E0F7FA) 0%, #FFFFFF 100%);
    font-family: var(--font-body, 'Inter', sans-serif);
    color: var(--color-navy, #0B3B78);
    min-height: 100vh;
    margin: 0;
    padding: 24px 16px;
    display: flex;
    align-items: center;
    justify-content: center;
}
.im-login-form {
    width: 100%;
    max-width: 520px;
    margin: 0 auto !important;
    float: none !important;
    background: #FFFFFF;
    border-radius: 20px;
    border: 1.5px solid rgba(0, 191, 166, 0.25);
    box-shadow: 0 14px 36px rgba(11, 45, 107, 0.10);
    padding: 28px 26px !important;
}
.im-login-form h2 { font-family: var(--font-heading, 'Poppins', sans-serif); color: var(--color-navy, #0B3B78); margin-top: 4px; }
.im-login-form .capcode { max-width: 100%; height: auto; }
.btn-primary, input[type="submit"] {
    background: var(--gradient-cta, linear-gradient(135deg, #0D6B44 0%, #138A4E 52%, #0097A7 100%));
    border: none;
    border-radius: 999px;
}
@media (max-width: 480px) {
    body { padding: 14px 10px; }
    .im-login-form { padding: 20px 16px !important; border-radius: 16px; }
}
input:invalid,
input:out-of-range {
    border-color:hsl(0, 50%, 50%);
    background:hsl(0, 50%, 90%);
}
</style>
</head>
<body  onLoad=document.getElementById("uid").focus() >
  <div class="im-login-form well well-lg">
  <div style="text-align:center; margin-bottom:14px;">
    <img src="<%=request.getContextPath()%>/images/mdosthi-primary-logo.png" alt="mDosthi" style="max-width:260px; width:100%; height:auto; display:inline-block;" />
  </div>
  <div style="text-align:center; margin-bottom:8px;">
    <a href="<%=request.getContextPath()%>/">mDosthi Home</a> |
    <a href="javascript:window.history.go(-1)" target="_self">Go Back</a>
  </div>
 <hr>
    <form METHOD="POST" ACTION="pat_forgotpswresp.jsp" name="frmLog" role = "form"  onSubmit="return CheckCaptcha()">
	<center><h2>mDosthi</h2><p>Forgot Login?</p></center>
	Dear Patient, <br>
	Please provide your EmailID or UID, and click Submit button.
	     <input class="form-control inpt-bx"  type = "text" name="uid" id="uid" placeholder = "EmailID / UserID" class="required" required/>

	  <div class="row">
	     <div class="captchaField pull-left">
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
  </div>
  <div class="row">
      <input class="btn btn-primary subm-btn pull-left " type="submit" value="Submit" /> 
	   </div>
    </form>
  </div>
  <br>
</body>
</html>
