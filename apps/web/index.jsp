<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
	Object uidAttr = session.getAttribute("uid");
	if (uidAttr != null && !uidAttr.toString().isEmpty()) {
		String utypeVal = String.valueOf(session.getAttribute("utype"));
		String patDest = "jspfiles/patient?templateid=1&menuid=head1&dest=patientAlldata&id=" + uidAttr;
		String staffDest = "jspfiles/home";
		response.sendRedirect(response.encodeRedirectURL("pat".equalsIgnoreCase(utypeVal) ? patDest : staffDest));
		return;
	}
	Integer hitsCount = (Integer) application.getAttribute("hitCounter");
	application.setAttribute("hitCounter", (hitsCount == null || hitsCount == 0) ? 1 : hitsCount + 1);
	String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<meta name="theme-color" content="#0D6B44">
	<title>mDosthi</title>

	<link rel="icon" type="image/png" sizes="32x32" href="<%=ctx%>/images/icons/mdosthi-favicon-32.png?v=4">
	<link rel="icon" type="image/png" sizes="256x256" href="<%=ctx%>/images/icons/mdosthi-favicon.png?v=4">
	<link rel="shortcut icon" type="image/x-icon" href="<%=ctx%>/favicon.ico?v=4">
	<link rel="apple-touch-icon" sizes="180x180" href="<%=ctx%>/images/icons/mdosthi-apple-touch-icon.png?v=4">

	<link rel="stylesheet" href="<%=ctx%>/bootstrap/css/bootstrap.min.css">
	<link rel="stylesheet" href="<%=ctx%>/bootstrap/font-awesome-4.7.0/css/font-awesome.min.css">
	<link rel="stylesheet" href="<%=ctx%>/style/mdosthi-brand-tokens.css?v=6">
	<link rel="stylesheet" href="<%=ctx%>/style/mdosthi-login.css?v=5">
</head>
<body>

	<!-- Top Bar (Aligned 1-to-1 with post-login .header navbar) -->
	<header class="md-topbar">
		<div class="md-topbar-inner">
			<div class="md-topbar-left">
				<img src="<%=ctx%>/images/mdosthi-horizontal-logo.png" alt="mDosthi" class="md-topbar-logo">
				<span class="md-topbar-divider" aria-hidden="true"></span>
				<span class="md-portal-pill">
					<i class="fa fa-shield" aria-hidden="true"></i>
					Admin &amp; Clinical Portal
				</span>
			</div>
			<button type="button" class="md-help-btn" data-toggle="modal" data-target="#mdHelpModal" title="Sign-in help">
				<i class="fa fa-question-circle" aria-hidden="true"></i>
				<span>Help</span>
			</button>
		</div>
	</header>

	<!-- Main Workspace -->
	<main class="md-main">
		<div class="md-split-grid">

			<!-- Left Clinical Brand Column -->
			<section class="md-showcase-col" aria-label="mDosthi Clinical Workspace">
				<img src="<%=ctx%>/images/mdosthi-primary-logo.png"
				     alt="mDosthi — Digital Health &amp; Well-Being · Healthcare as Homecare"
				     class="md-primary-logo">

				<h1 class="md-hero-title">Administration &amp; Clinical Care Workspace</h1>
				<p class="md-hero-sub">
					Dedicated portal for administrators, psychologists, and doctors to manage operations, review patient progress, and coordinate care.
				</p>

				<div class="md-quick-chips">
					<span class="md-quick-chip"><i class="fa fa-sliders" aria-hidden="true"></i> Portal Administration</span>
					<span class="md-quick-chip"><i class="fa fa-comments-o" aria-hidden="true"></i> Psychological Care</span>
					<span class="md-quick-chip"><i class="fa fa-user-md" aria-hidden="true"></i> Doctor Consultations</span>
				</div>

				<div class="md-partners-bar">
					<div class="md-partner-item">
						<img src="<%=ctx%>/images/iitkgp.png" alt="IIT Kharagpur">
						<div class="md-partner-text">
							<span class="md-partner-role">Developed By</span>
							<span class="md-partner-name">IIT Kharagpur</span>
						</div>
					</div>
					<div class="md-partner-item">
						<img src="<%=ctx%>/images/aiimsk.png" alt="AIIMS Kalyani">
						<div class="md-partner-text">
							<span class="md-partner-role">Collaborated With</span>
							<span class="md-partner-name">AIIMS Kalyani</span>
						</div>
					</div>
					<div class="md-partner-item">
						<img src="<%=ctx%>/images/icmr.png" alt="ICMR">
						<div class="md-partner-text">
							<span class="md-partner-role">Sponsored By</span>
							<span class="md-partner-name">ICMR</span>
						</div>
					</div>
				</div>
			</section>

			<!-- Right Sign-In Card (Matched Branded Header Template) -->
			<section class="md-login-col" aria-label="Portal Sign In">
				<div class="md-login-card">
					<div class="md-login-header">
						<div class="md-login-header-inner">
							<div class="md-emblem-wrap js-tilt" data-tilt>
								<img src="<%=ctx%>/images/mdosthi-emblem.png" alt="mDosthi Emblem">
							</div>
							<div class="md-header-copy">
								<span class="md-header-kicker">mDosthi Workspace</span>
								<h2 class="md-card-title">Staff Sign In</h2>
								<p class="md-card-subtitle">For Administrators, Psychologists &amp; Doctors</p>
							</div>
						</div>
					</div>
					<div class="md-login-body">
						<!-- Role Tabs: Admin | Psychologist | Doctor -->
						<div class="md-role-tabs" role="tablist" aria-label="Select Staff Role">
							<button type="button" class="md-role-tab active" data-role="adm">
								<i class="fa fa-cog" aria-hidden="true"></i> Admin
							</button>
							<button type="button" class="md-role-tab" data-role="psy">
								<i class="fa fa-heart-o" aria-hidden="true"></i> Psychologist
							</button>
							<button type="button" class="md-role-tab" data-role="doc">
								<i class="fa fa-user-md" aria-hidden="true"></i> Doctor
							</button>
						</div>

						<!-- Login Form (Preserves exact POST -> jspfiles/login_n.jsp contract) -->
						<form method="POST" action="jspfiles/login_n.jsp" name="frmLog" id="mdLoginForm" role="form" novalidate>
							<div class="md-error-alert login-msg" id="mdErrorAlert" role="alert"></div>

							<div class="md-field">
								<label for="uid">Username</label>
								<div class="md-input-wrap">
									<span class="md-input-icon-badge" aria-hidden="true"><i class="fa fa-user-o"></i></span>
									<input class="md-input" type="text" name="uid" id="uid" placeholder="Enter Admin username" autocomplete="username" autofocus>
									<button type="button" class="md-input-action" id="mdClearUid" title="Clear username" style="display:none;">
										<i class="fa fa-times-circle" aria-hidden="true"></i>
									</button>
								</div>
							</div>

							<div class="md-field">
								<label for="pwd">Password</label>
								<div class="md-input-wrap">
									<span class="md-input-icon-badge" aria-hidden="true"><i class="fa fa-lock"></i></span>
									<input class="md-input" type="password" name="pwd" id="pwd" placeholder="Enter your password" autocomplete="current-password">
									<button type="button" class="md-input-action" id="mdTogglePwd" title="Show password" aria-label="Toggle password visibility">
										<i class="fa fa-eye-slash" aria-hidden="true"></i>
									</button>
								</div>
							</div>

							<button class="md-submit-btn subm-btn" type="submit" id="mdSubmitBtn">
								<span id="mdSubmitLabel">Sign In</span>
								<i class="fa fa-arrow-right" id="mdSubmitIcon" aria-hidden="true"></i>
							</button>
						</form>

						<div class="md-trust-bar">
							<span class="md-trust-dot" aria-hidden="true"></span>
							<i class="fa fa-shield" aria-hidden="true"></i>
							<span>Authorized Clinical &amp; Admin Access</span>
						</div>
					</div>
				</div>
			</section>

		</div>
	</main>

	<!-- Concise Sign-In Help Modal -->
	<div class="modal fade" id="mdHelpModal" tabindex="-1" role="dialog" aria-labelledby="mdHelpModalLabel">
		<div class="modal-dialog" role="document" style="max-width:460px;">
			<div class="modal-content" style="border-radius:22px; overflow:hidden; border:none;">
				<div class="modal-header" style="background:var(--gradient-cta); color:#FFFFFF; border:none; padding:16px 22px;">
					<button type="button" class="close" data-dismiss="modal" aria-label="Close" style="color:#FFFFFF; opacity:0.9;">
						<span aria-hidden="true">&times;</span>
					</button>
					<h4 class="modal-title" id="mdHelpModalLabel" style="font-family:var(--font-heading); font-weight:700; color:#FFFFFF;">
						<i class="fa fa-question-circle" aria-hidden="true"></i> Staff Sign-In Help
					</h4>
				</div>
				<div class="modal-body" style="padding:20px 22px; font-size:13.5px; color:var(--color-body-ink, #1E3A34); line-height:1.6;">
					<p style="margin-bottom:10px;">
						<strong style="color:var(--color-navy);">Who Can Sign In Here:</strong> This web portal is reserved for <strong>Administrators</strong>, <strong>Psychologists</strong>, and <strong>Doctors</strong>.
					</p>
					<p style="margin-bottom:10px;">
						<strong style="color:var(--color-navy);">Patient Access:</strong> Patients sign in through the <strong>mDosthi App</strong>.
					</p>
					<p style="margin-bottom:0;">
						<strong style="color:var(--color-navy);">Shared Workstations:</strong> Always sign out from the top-right bar after completing your session.
					</p>
				</div>
				<div class="modal-footer" style="border-top:1px solid rgba(13,107,68,0.10); padding:12px 22px;">
					<button type="button" class="btn btn-primary" data-dismiss="modal" style="background:var(--color-teal, #138A4E); border:none; border-radius:999px; padding:7px 20px; font-family:var(--font-heading); font-weight:600;">Got it</button>
				</div>
			</div>
		</div>
	</div>

	<script src="<%=ctx%>/bootstrap/jquery-2.2.1.min.js"></script>
	<script src="<%=ctx%>/bootstrap/js/popper.js"></script>
	<script src="<%=ctx%>/bootstrap/js/bootstrap.min.js"></script>
	<script src="<%=ctx%>/bootstrap/js/tilt.jquery.min.js"></script>
	<script>
		(function ($) {
			if ($.fn.tilt) {
				$('.js-tilt').tilt({ scale: 1.06 });
			}

			var rolePlaceholders = {
				adm: 'Enter Admin username',
				psy: 'Enter Psychologist username',
				doc: 'Enter Doctor username'
			};

			$('.md-role-tab').on('click', function () {
				var key = $(this).attr('data-role');
				$('.md-role-tab').removeClass('active');
				$(this).addClass('active');
				if (rolePlaceholders[key]) {
					$('#uid').attr('placeholder', rolePlaceholders[key]).focus();
				}
			});

			function showError(msg) {
				$('#mdErrorAlert').html('<i class="fa fa-exclamation-triangle" aria-hidden="true"></i><span>' + msg + '</span>').addClass('visible');
			}
			function clearError() {
				$('#mdErrorAlert').removeClass('visible').html('');
			}

			$('#uid').on('input', function () {
				clearError();
				$('#mdClearUid').toggle($(this).val().length > 0);
			});
			$('#pwd').on('input', clearError);

			$('#mdClearUid').on('click', function () {
				$('#uid').val('').focus();
				$(this).hide();
				clearError();
			});

			$('#mdTogglePwd').on('click', function () {
				var $pwd = $('#pwd');
				var isHidden = $pwd.attr('type') === 'password';
				$pwd.attr('type', isHidden ? 'text' : 'password');
				$(this).attr('title', isHidden ? 'Hide password' : 'Show password');
				$(this).find('i').toggleClass('fa-eye-slash', !isHidden).toggleClass('fa-eye', isHidden);
			});

			$('#mdLoginForm').on('submit', function (e) {
				e.preventDefault();
				clearError();
				var uidVal = $.trim($('#uid').val());
				var pwdVal = $.trim($('#pwd').val());
				if (!uidVal || !pwdVal) {
					showError('Please enter both username and password.');
					(!uidVal ? $('#uid') : $('#pwd')).focus();
					return;
				}
				var $btn = $('#mdSubmitBtn');
				$btn.prop('disabled', true);
				$('#mdSubmitLabel').text('Signing in...');
				$('#mdSubmitIcon').attr('class', 'fa fa-spinner fa-spin');

				$.ajax({
					type: 'POST',
					url: 'jspfiles/login_n.jsp',
					data: $(this).serialize(),
					success: function (data) {
						if (data.trim() == '0') {
							showError('Wrong username or password. Please try again.');
							$btn.prop('disabled', false);
							$('#mdSubmitLabel').text('Sign In');
							$('#mdSubmitIcon').attr('class', 'fa fa-arrow-right');
						} else {
							location.reload();
						}
					},
					error: function () {
						showError('Unable to sign in right now. Please check server status and try again.');
						$btn.prop('disabled', false);
						$('#mdSubmitLabel').text('Sign In');
						$('#mdSubmitIcon').attr('class', 'fa fa-arrow-right');
					}
				});
			});
		})(jQuery);
	</script>
</body>
</html>
