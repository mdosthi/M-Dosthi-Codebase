<%
	Object uidAttr = session.getAttribute("uid");
	if (uidAttr != null && !"".equals(uidAttr)) {
		if (String.valueOf(session.getAttribute("utype")).equalsIgnoreCase("pat")) {
			response.sendRedirect(response.encodeRedirectURL("jspfiles/patient?templateid=1&menuid=head1&dest=patientAlldata&id=" + uidAttr));
		} else {
			response.sendRedirect("jspfiles/home");
		}
	}
%>
	<% String visitStatus="" ; Integer hitsCount=(Integer)application.getAttribute("hitCounter"); if( hitsCount==null ||
		hitsCount==0 ) { visitStatus="Welcome to mDosthi!" ; hitsCount=1; } else { visitStatus="Total " + hitsCount
		+ " visitors supported by mDosthi" ; hitsCount +=1; } application.setAttribute("hitCounter", hitsCount); %>
		<!DOCTYPE html>
		<html lang="en">

		<head>
			<title>mDosthi — Malignancy-related Distress &amp; Other Stress Healing Initiative</title>
			<meta charset="UTF-8">
			<meta name="viewport" content="width=device-width, initial-scale=1">
			<meta name="theme-color" content="#0B2D6B">
			<link rel="icon" type="image/svg+xml"
				href="<%=request.getContextPath()%>/images/icons/m-dosthi-favicon.svg" />
			<link rel="alternate icon" type="image/x-icon" href="<%=request.getContextPath()%>/favicon.ico" />
			<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/bootstrap.min.css">
			<link rel="stylesheet" type="text/css"
				href="<%=request.getContextPath()%>/bootstrap/font-awesome-4.7.0/css/font-awesome.min.css">
			<link rel="stylesheet" type="text/css" href="<%=request.getContextPath()%>/bootstrap/css/animate.css">
			<link rel="stylesheet" type="text/css" href="<%=request.getContextPath()%>/bootstrap/css/util.css">
			<link rel="stylesheet" type="text/css" href="<%=request.getContextPath()%>/bootstrap/css/main.css">
			<link rel="stylesheet" type="text/css" href="<%=request.getContextPath()%>/style/mdosthi-brand.css">
		</head>

		<body class="mdosthi-branded">

			<!-- =====================================================================
	     Horizontal Brand Header & Navigation
	     Links: Home, About, Resources, Support, Community, Contact + Get Support
	     ===================================================================== -->
			<header class="mdosthi-header-wrap">
				<nav class="mdosthi-navbar" aria-label="Primary Navigation">
					<div style="display:flex; align-items:center; gap:16px;">
						<a href="#home" class="mdosthi-nav-brand">
							<img src="<%=request.getContextPath()%>/images/mdosthi-horizontal-logo.svg"
								alt="mDosthi Horizontal Logo">
						</a>
						<span class="mdosthi-nav-divider" aria-hidden="true"></span>
					</div>

					<button type="button" class="mdosthi-mobile-toggle" id="mdosthiMobileMenuBtn"
						aria-label="Toggle Menu" aria-expanded="false">
						<i class="fa fa-bars" aria-hidden="true"></i>
					</button>

					<div class="mdosthi-nav-collapse" id="mdosthiNavCollapse"
						style="display:flex; align-items:center; justify-content:space-between; flex:1; gap:14px;">
						<ul class="mdosthi-nav-links" id="mdosthiNavList">
							<li class="active">
								<a href="#home"><i class="fa fa-home" aria-hidden="true"></i> Home</a>
							</li>
							<li>
								<a href="#about"><i class="fa fa-info-circle" aria-hidden="true"></i> About</a>
							</li>
							<li class="mdosthi-dropdown" id="resourcesDropdown">
								<a href="#resources" class="mdosthi-dropdown-toggle">
									<i class="fa fa-book" aria-hidden="true"></i> Resources <i class="fa fa-angle-down"
										aria-hidden="true" style="font-size:13px;"></i>
								</a>
								<div class="mdosthi-dropdown-menu" role="menu">
									<a href="#resources"><i class="fa fa-heartbeat"></i> Distress Self-Care Guides</a>
									<a href="#resources"><i class="fa fa-comments-o"></i> Counselling Resources</a>
									<a href="#support"><i class="fa fa-smile-o"></i> AI Companion &amp; Wellness</a>
									<a href="#portal-login"><i class="fa fa-stethoscope"></i> Clinical &amp; Patient
										Portal</a>
								</div>
							</li>
							<li>
								<a href="#support"><i class="fa fa-users" aria-hidden="true"></i> Support</a>
							</li>
							<li>
								<a href="#community"><i class="fa fa-globe" aria-hidden="true"></i> Community</a>
							</li>
							<li>
								<a href="#contact"><i class="fa fa-envelope-o" aria-hidden="true"></i> Contact</a>
							</li>
						</ul>


</head>
<body>
	
	<div class="limiter hidden-xs">
		<div class="container-login100">
			<div class="wrap-login100">
				<div class="col-md-8 col-65">
					<div class="features-details" style="margin-top:0; padding-top:0;">
						<div class="features-title" style="padding-top:0;">
							<img src="<%=request.getContextPath()%>/images/mdosthi-primary-logo.png"
							     alt="mDosthi — Digital Health &amp; Well-Being · Healthcare as Homecare"
							     class="primary-brand-logo">
						</div>
					</div>
				</nav>
			</header>

			<!-- =====================================================================
	     Hero Section: Primary Logo, Brand CTAs, Healing Graphic & Login Card
	     ===================================================================== -->
			<main id="home" class="mdosthi-hero">
				<div class="mdosthi-container">
					<div class="mdosthi-hero-grid">

						<!-- Left Brand & Initiative Column -->
						<div>
							<img src="<%=request.getContextPath()%>/images/mdosthi-primary-logo.svg"
								alt="mDosthi — Malignancy-related Distress and Other Stress Healing Initiative"
								class="mdosthi-primary-logo-img">

							<p class="mdosthi-hero-lead">
								Compassionate psycho-oncology care, guided emotional wellness, and connected clinical
								support for patients, caregivers, and families.
							</p>
							<p class="mdosthi-hero-copy">
								<strong>mDosthi</strong> bridges oncology specialists, mental health counsellors, and
								supportive digital tools so every patient navigating malignancy-related distress
								receives timely, dignified care.
							</p>

							<!-- Brand UI Buttons: Get Support, Learn More, Donate -->
							<div class="mdosthi-cta-group">
								<a href="#support" class="btn-mdosthi-support">
									<i class="fa fa-heart-o" aria-hidden="true"></i> Get Support <span
										aria-hidden="true">&rarr;</span>
								</a>
								<a href="#about" class="btn-mdosthi-learn">
									<i class="fa fa-book" aria-hidden="true"></i> Learn More <span
										aria-hidden="true">&rarr;</span>
								</a>
								<button type="button" class="btn-mdosthi-donate" data-toggle="modal"
									data-target="#donateModal">
									<i class="fa fa-gift" aria-hidden="true"></i> Donate <i class="fa fa-heart"
										aria-hidden="true"></i>
								</button>
							</div>

							<!-- Healthcare Graphic ("You are not alone...") + 4 Clinical Badges -->
							<div class="mdosthi-healing-banner">
								<img src="<%=request.getContextPath()%>/images/illustrations/you-are-not-alone.svg"
									alt="You are not alone — mDosthi Healing Graphic" class="healing-svg">
								<div>
									<div
										style="font-family:var(--font-heading); font-size:15px; font-weight:700; color:var(--brand-navy); margin-bottom:8px;">
										Holistic Care Ecosystem
									</div>
									<p style="font-size:13px; color:var(--brand-text-muted); margin-bottom:10px;">
										Integrated clinical monitoring, distress screening, mindfulness, and community
										care.
									</p>
									<div class="mdosthi-health-badges">
										<img src="<%=request.getContextPath()%>/images/icons/badge-stethoscope.svg"
											alt="Clinical Care" title="Clinical Telemedicine">
										<img src="<%=request.getContextPath()%>/images/icons/badge-mind.svg"
											alt="Mental Wellness" title="Psycho-Oncology &amp; Mind Wellness">
										<img src="<%=request.getContextPath()%>/images/icons/badge-community.svg"
											alt="Support Community" title="Patient &amp; Caregiver Community">
										<img src="<%=request.getContextPath()%>/images/icons/badge-ribbon.svg"
											alt="Oncology Awareness" title="Malignancy Distress Support">
									</div>
								</div>
							</div>

							<!-- Institutional Collaborators -->
							<div class="mdosthi-partners">
								<div class="mdosthi-partner-item">
									<img src="<%=request.getContextPath()%>/images/aiimsk.png" alt="AIIMS Kalyani">
									<span>AIIMS Kalyani</span>
								</div>
								<div class="mdosthi-partner-item">
									<img src="<%=request.getContextPath()%>/images/iitkgp.png" alt="IIT Kharagpur">
									<span>IIT Kharagpur</span>
								</div>
								<div class="mdosthi-partner-item">
									<img src="<%=request.getContextPath()%>/images/icmr.png" alt="ICMR">
									<span>Sponsored by ICMR</span>
								</div>
							</div>
						</div>

						<!-- Right Portal Sign-In Card (Preserves exact frmLog -> jspfiles/login_n.jsp workflow) -->
						<div id="portal-login">
							<div class="mdosthi-login-card">
								<div class="mdosthi-login-header">
									<img src="<%=request.getContextPath()%>/images/icons/m-dosthi-favicon.svg"
										alt="mDosthi Emblem" class="js-tilt" data-tilt>
									<h2>Portal Sign In</h2>
									<p>Care &bull; Support &bull; Hope</p>
								</div>

								<form class="validate-form" method="POST" action="jspfiles/login_n.jsp" name="frmLog"
									role="form">
									<span class="login-msg"></span>

									<div class="mdosthi-field validate-input"
										data-validate="Valid username is required">
										<label for="uid">Username / Clinician or Patient ID</label>
										<div class="mdosthi-input-wrap">
											<i class="fa fa-user-o" aria-hidden="true"></i>
											<input class="mdosthi-input" type="text" name="uid" id="uid"
												placeholder="Enter your username" autocomplete="username">
										</div>
									</div>

									<div class="mdosthi-field validate-input" data-validate="Password is required">
										<label for="pwd">Password</label>
										<div class="mdosthi-input-wrap">
											<i class="fa fa-lock" aria-hidden="true"></i>
											<input class="mdosthi-input" type="password" name="pwd" id="pwd"
												placeholder="Enter your password" autocomplete="current-password">
										</div>
									</div>

<div class="col-sm-12 sk hidden visible-xs" style="background:#fff;border-radius:5px;">
<div class="surajit hidden-sm" ><br>
	<center>
	<img src="<%=request.getContextPath()%>/images/mdosthi-primary-logo.png"
	     alt="mDosthi — Digital Health &amp; Well-Being · Healthcare as Homecare"
	     style="max-width: 280px; width: 100%; height: auto; margin-bottom: 14px;">
	<div style="margin-bottom: 12px;">
	    <div class="image-box" style="display: inline-block; margin-right: 10px;">
	        <img src="<%=request.getContextPath()%>/images/aiimsk.png" alt="AIIMS Kalyani" style="border-radius:10%; max-width: 56px; background:#fff; padding:4px; box-shadow: 0 4px 10px rgba(11,45,107,0.10);">
	    </div>
	    <div class="image-box" style="display: inline-block; margin-right: 10px;">
	        <img src="<%=request.getContextPath()%>/images/iitkgp.png" alt="IIT Kharagpur" style="border-radius:10%; max-width: 56px; background:#fff; padding:4px; box-shadow: 0 4px 10px rgba(11,45,107,0.10);">
	    </div>
	    <div class="image-box" style="display: inline-block;">
	        <img src="<%=request.getContextPath()%>/images/icmr.png" alt="ICMR" style="border-radius:10%; max-width: 56px; background:#fff; padding:4px; box-shadow: 0 4px 10px rgba(11,45,107,0.10);">
	    </div>
	</div>
	</center>

								<div
									style="margin-top:20px; padding-top:16px; border-top:1px solid rgba(11,45,107,0.08); display:flex; align-items:center; gap:12px;">
									<img src="<%=request.getContextPath()%>/images/illustrations/mdosthi-robot-mascot.png"
										alt="mDosthi AI Companion Mascot"
										style="width:54px; height:54px; border-radius:50%; border:2px solid var(--brand-light); object-fit:cover; flex-shrink:0;">
									<div style="font-size:12.5px; color:var(--brand-text-muted); line-height:1.45;">
										<strong style="color:var(--brand-navy);">Need immediate guidance?</strong><br>
										Explore <a href="#support"
											style="font-weight:600; color:var(--brand-teal-dark);">Emotional Support
											&amp; Counselling</a> below.
									</div>
								</div>
							</div>
						</div>

					</div>

					<!-- =================================================================
			     5 Feature Icons Strip: Emotional Support, Counselling,
			     Mental Wellness, Care Guidance, Support Community
			     ================================================================= -->
					<section aria-label="Core Healing Pillars" class="mdosthi-feature-strip">
						<a href="#support" class="mdosthi-feature-pill">
							<img src="<%=request.getContextPath()%>/images/icons/feature-emotional-support.svg"
								alt="Emotional Support">
							<span>Emotional<br>Support</span>
						</a>
						<a href="#resources" class="mdosthi-feature-pill">
							<img src="<%=request.getContextPath()%>/images/icons/feature-counselling.svg"
								alt="Counselling">
							<span>Counselling<br>Resources</span>
						</a>
						<a href="#support" class="mdosthi-feature-pill">
							<img src="<%=request.getContextPath()%>/images/icons/feature-mental-wellness.svg"
								alt="Mental Wellness">
							<span>Mental<br>Wellness</span>
						</a>
						<a href="#about" class="mdosthi-feature-pill">
							<img src="<%=request.getContextPath()%>/images/icons/feature-care-guidance.svg"
								alt="Care Guidance">
							<span>Care<br>Guidance</span>
						</a>
						<a href="#community" class="mdosthi-feature-pill">
							<img src="<%=request.getContextPath()%>/images/icons/feature-support-community.svg"
								alt="Support Community">
							<span>Support<br>Community</span>
						</a>
					</section>
				</div>
			</main>

			<!-- =====================================================================
	     About Section + Healthcare-Themed Illustration
	     ===================================================================== -->
			<section id="about" class="mdosthi-section mdosthi-section-alt">
				<div class="mdosthi-container">
					<div class="mdosthi-mascot-grid">
						<div class="mdosthi-illustration-frame">
							<img src="<%=request.getContextPath()%>/images/illustrations/mdosthi-healthcare-illustration.png"
								alt="Compassionate Healthcare and Distress Counselling Illustration">
						</div>
						<div>
							<span class="mdosthi-eyebrow">About mDosthi</span>
							<h2 style="font-size:32px; margin-bottom:12px;">Healing Beyond Clinical Boundaries</h2>
							<p class="brand-subtitle"
								style="font-style:italic; font-size:17px; margin-bottom:14px; color:var(--brand-teal-dark);">
								&ldquo;Addressing malignancy-related distress and emotional stress with science,
								empathy, and human connection.&rdquo;
							</p>
							<p style="font-size:15px; color:var(--brand-text-body); margin-bottom:18px;">
								Developed jointly by <strong>IIT Kharagpur</strong> and <strong>AIIMS Kalyani</strong>
								with support from <strong>ICMR</strong>, mDosthi integrates structured psycho-oncology
								screening (PO-BADO), personalized sleep and mood tracking, tele-consultation, and
								compassionate supportive therapy into one unified care platform.
							</p>
							<div class="mdosthi-cta-group" style="margin-bottom:0;">
								<a href="#portal-login" class="btn-mdosthi-support btn-mdosthi-sm">
									<i class="fa fa-heart-o"></i> Get Support &rarr;
								</a>
								<a href="#resources" class="btn-mdosthi-learn btn-mdosthi-sm">
									<i class="fa fa-book"></i> Learn More &rarr;
								</a>
							</div>
						</div>
					</div>
				</div>
			</section>

			<!-- =====================================================================
	     Resources Section
	     ===================================================================== -->
			<section id="resources" class="mdosthi-section">
				<div class="mdosthi-container">
					<div class="mdosthi-section-header">
						<span class="mdosthi-eyebrow">Care Resources</span>
						<h2>Evidence-Based Healing Resources</h2>
						<p>Structured self-help guides, clinical assessments, and supportive wellness tools</p>
					</div>

					<div class="mdosthi-cards-grid">
						<div class="mdosthi-card">
							<div class="mdosthi-card-icon">
								<img src="<%=request.getContextPath()%>/images/icons/feature-counselling.svg"
									alt="Counselling">
							</div>
							<h3>Counselling &amp; CBT Guides</h3>
							<p>Interactive cognitive-behavioural coping strategies, bilingual audio-visual guides, and
								structured psycho-educational reading modules.</p>
						</div>
						<div class="mdosthi-card">
							<div class="mdosthi-card-icon">
								<img src="<%=request.getContextPath()%>/images/icons/feature-mental-wellness.svg"
									alt="Mental Wellness">
							</div>
							<h3>Sleep &amp; Mood Monitoring</h3>
							<p>Daily sleep hygiene logs, mood and activity tracking, and longitudinal distress progress
								summaries shared securely with your care team.</p>
						</div>
						<div class="mdosthi-card">
							<div class="mdosthi-card-icon">
								<img src="<%=request.getContextPath()%>/images/icons/feature-care-guidance.svg"
									alt="Care Guidance">
							</div>
							<h3>Clinical Care Guidance</h3>
							<p>Coordinated oncology and psychology follow-ups, tele-consultations, digital
								prescriptions, and timely distress-screening checkpoints.</p>
						</div>
					</div>
				</div>
			</section>

			<!-- =====================================================================
	     Support Section Featuring the Friendly mDosthi Robot Mascot
	     ===================================================================== -->
			<section id="support" class="mdosthi-section mdosthi-section-alt">
				<div class="mdosthi-container">
					<div class="mdosthi-mascot-grid">
						<div>
							<span class="mdosthi-eyebrow">24/7 Companion &amp; Clinical Support</span>
							<h2 style="font-size:32px; margin-bottom:12px;">Meet Your Friendly mDosthi Companion</h2>
							<p class="brand-subtitle"
								style="font-style:italic; font-size:17px; margin-bottom:14px; color:var(--brand-navy);">
								Gentle, stigma-free emotional support whenever distress feels overwhelming.
							</p>
							<p style="font-size:15px; color:var(--brand-text-body); margin-bottom:20px;">
								Our bilingual supportive companion works alongside psychologists and clinicians to guide
								breathing exercises, listen empathetically in English and Bengali, and connect enrolled
								patients directly with specialist counselling teams.
							</p>
							<div class="mdosthi-cta-group" style="margin-bottom:0;">
								<a href="#portal-login" class="btn-mdosthi-support">
									<i class="fa fa-heart-o"></i> Get Support &rarr;
								</a>
								<button type="button" class="btn-mdosthi-donate" data-toggle="modal"
									data-target="#donateModal">
									<i class="fa fa-gift"></i> Donate <i class="fa fa-heart"></i>
								</button>
							</div>
						</div>
						<div class="mdosthi-illustration-frame">
							<img src="<%=request.getContextPath()%>/images/illustrations/mdosthi-robot-mascot.png"
								alt="mDosthi Friendly Healthcare Robot Mascot">
						</div>
					</div>
				</div>
			</section>

			<!-- =====================================================================
	     Community Section
	     ===================================================================== -->
			<section id="community" class="mdosthi-section">
				<div class="mdosthi-container">
					<div class="mdosthi-section-header">
						<span class="mdosthi-eyebrow">Support Community</span>
						<h2>A Connected Circle of Care, Support &amp; Hope</h2>
						<p>Patients, family caregivers, psychologists, and doctors walking together</p>
					</div>

					<div class="mdosthi-cards-grid">
						<div class="mdosthi-card">
							<div class="mdosthi-card-icon">
								<img src="<%=request.getContextPath()%>/images/icons/feature-emotional-support.svg"
									alt="Emotional Support">
							</div>
							<h3>Patient Resilience Circles</h3>
							<p>Safe, clinician-moderated guidance helping patients navigate treatment anxiety, fatigue,
								and emotional recovery with dignity.</p>
						</div>
						<div class="mdosthi-card">
							<div class="mdosthi-card-icon">
								<img src="<%=request.getContextPath()%>/images/icons/feature-support-community.svg"
									alt="Support Community">
							</div>
							<h3>Family &amp; Caregiver Support</h3>
							<p>Dedicated family enrollment and practical homecare guidance empowering loved ones who
								support patients every day.</p>
						</div>
						<div class="mdosthi-card">
							<div class="mdosthi-card-icon">
								<img src="<%=request.getContextPath()%>/images/icons/badge-stethoscope.svg"
									alt="Multidisciplinary Care">
							</div>
							<h3>Multidisciplinary Network</h3>
							<p>Connecting nodal healthcare centers, psycho-oncologists, and researchers across AIIMS
								Kalyani and IIT Kharagpur.</p>
						</div>
					</div>
				</div>
			</section>

			<!-- =====================================================================
	     Contact & Official Footer
	     ===================================================================== -->
			<footer id="contact" class="mdosthi-footer">
				<div class="mdosthi-container">
					<div class="row"
						style="display:flex; flex-wrap:wrap; align-items:center; justify-content:space-between; gap:24px;">
						<div class="col-md-5" style="padding:0;">
							<div
								style="background:#FFFFFF; display:inline-block; padding:8px 16px; border-radius:16px; margin-bottom:12px;">
								<img src="<%=request.getContextPath()%>/images/mdosthi-horizontal-logo.svg"
									alt="mDosthi" style="height:40px; width:auto;">
							</div>
							<p
								style="font-family:var(--font-subtitle); font-style:italic; color:#E0F7FA; font-size:15px; margin-bottom:6px;">
								Malignancy-related Distress and Other Stress Healing Initiative &mdash; Care &bull;
								Support &bull; Hope
							</p>
							<p style="font-size:12.5px; color:rgba(224,247,250,0.75); margin:0;">
								<%=visitStatus%>
							</p>
						</div>

						<div class="col-md-6" style="padding:0; font-size:13.5px; line-height:1.7;">
							<div
								style="font-family:var(--font-heading); font-weight:700; font-size:15px; color:#FFFFFF; margin-bottom:4px;">
								Contact &amp; Coordination
							</div>
							<div>Developed and designed at <strong>Computer Science &amp; Engineering Department, IIT
									Kharagpur</strong> in collaboration with <strong>AIIMS Kalyani</strong> (Sponsored
								by ICMR)</div>
							<div>
								<i class="fa fa-user-md" aria-hidden="true" style="color:var(--brand-teal);"></i>
								<strong>Prof. Jayanta Mukhopadhyay</strong> &nbsp;|&nbsp;
								<i class="fa fa-envelope-o" aria-hidden="true" style="color:var(--brand-teal);"></i> <a
									href="mailto:jay@cse.iitkgp.ac.in">jay@cse.iitkgp.ac.in</a> &nbsp;|&nbsp;
								<i class="fa fa-phone" aria-hidden="true" style="color:var(--brand-teal);"></i>
								+91-3222-283484
							</div>
						</div>
					</div>
				</div>
			</footer>

			<!-- =====================================================================
	     Donate / Support the Healing Initiative Modal
	     ===================================================================== -->
			<div class="modal fade" id="donateModal" tabindex="-1" role="dialog" aria-labelledby="donateModalLabel">
				<div class="modal-dialog" role="document">
					<div class="modal-content" style="border-radius:24px; overflow:hidden; border:none;">
						<div class="modal-header"
							style="background:var(--brand-cta-gradient); color:#FFFFFF; border:none; padding:20px 24px;">
							<button type="button" class="close" data-dismiss="modal" aria-label="Close"
								style="color:#FFFFFF; opacity:0.9;">
								<span aria-hidden="true">&times;</span>
							</button>
							<h4 class="modal-title" id="donateModalLabel"
								style="color:#FFFFFF; font-family:var(--font-heading); font-weight:700;">
								<i class="fa fa-gift"></i> Support the mDosthi Healing Initiative
							</h4>
						</div>
						<div class="modal-body"
							style="padding:24px; font-family:var(--font-body); color:var(--brand-text-body);">
							<p class="brand-subtitle"
								style="font-style:italic; font-size:16px; color:var(--brand-navy); margin-bottom:12px;">
								Every contribution helps expand free emotional support, distress screening, and
								counselling resources for oncology patients and families.
							</p>
							<p style="font-size:14px; margin-bottom:14px;">
								<strong>mDosthi</strong> is an ICMR-sponsored academic and clinical healing initiative
								by <strong>AIIMS Kalyani</strong> and <strong>IIT Kharagpur</strong>. To partner,
								contribute patient wellness materials, or support community outreach, please reach out
								to our project office:
							</p>
							<div
								style="background:var(--brand-light); border-radius:14px; padding:14px 16px; font-size:13.5px; color:var(--brand-navy);">
								<strong>Project Coordinator:</strong> Prof. Jayanta Mukhopadhyay<br>
								<strong>Institution:</strong> Dept. of CSE, IIT Kharagpur &amp; AIIMS Kalyani<br>
								<strong>Email:</strong> <a href="mailto:jay@cse.iitkgp.ac.in"
									style="color:var(--brand-blue); font-weight:600;">jay@cse.iitkgp.ac.in</a>
								&nbsp;|&nbsp; <strong>Phone:</strong> +91-3222-283484
							</div>
						</div>
						<div class="modal-footer" style="border-top:1px solid rgba(11,45,107,0.08); padding:14px 24px;">
							<a href="mailto:jay@cse.iitkgp.ac.in?subject=Supporting%20mDosthi%20Healing%20Initiative"
								class="btn-mdosthi-support btn-mdosthi-sm">
								<i class="fa fa-envelope-o"></i> Contact Initiative Team &rarr;
							</a>
							<button type="button" class="btn-mdosthi-learn btn-mdosthi-sm"
								data-dismiss="modal">Close</button>
						</div>
					</div>
				</div>
			</div>

			<script src="<%=request.getContextPath()%>/bootstrap/jquery-2.2.1.min.js"></script>
			<script src="<%=request.getContextPath()%>/bootstrap/js/popper.js"></script>
			<script src="<%=request.getContextPath()%>/bootstrap/js/bootstrap.min.js"></script>
			<script src="<%=request.getContextPath()%>/bootstrap/js/tilt.jquery.min.js"></script>
			<script>
				$('.js-tilt').tilt({ scale: 1.08 });

				// Responsive mobile navigation & active link state
				$('#mdosthiMobileMenuBtn').on('click', function () {
					var $nav = $('#mdosthiNavCollapse');
					$nav.toggleClass('open');
					$(this).attr('aria-expanded', $nav.hasClass('open'));
				});

				$('#resourcesDropdown > .mdosthi-dropdown-toggle').on('click', function (e) {
					if (window.innerWidth <= 920) {
						e.preventDefault();
						$('#resourcesDropdown').toggleClass('open');
					}
				});

				$('#mdosthiNavList > li > a').on('click', function () {
					$('#mdosthiNavList > li').removeClass('active');
					$(this).parent('li').addClass('active');
					if (window.innerWidth <= 920 && !$(this).hasClass('mdosthi-dropdown-toggle')) {
						$('#mdosthiNavCollapse').removeClass('open');
					}
				});

				// Preserve existing AJAX login flow to jspfiles/login_n.jsp
				$("form[name='frmLog']").submit(function (e) {
					e.preventDefault();
					var form = $(this);
					var uidVal = $.trim($("#uid").val());
					var pwdVal = $.trim($("#pwd").val());
					if (!uidVal || !pwdVal) {
						$(".login-msg").html("<i class='fa fa-exclamation-triangle' aria-hidden='true'></i> Please enter both username and password");
						return;
					}
					var url = "jspfiles/login_n.jsp";
					$(".login-msg").html("");
					$.ajax({
						type: "POST",
						url: url,
						data: form.serialize(),
						success: function (data) {
							if (data.trim() == 0) {
								$(".login-msg").html("<i class='fa fa-exclamation-triangle' aria-hidden='true'></i> Wrong username and password");
							} else {
								location.reload();
							}
						}
					});
				});
			</script>
		</body>

		</html>