<%@page contentType="text/html" import="imedix.layout,java.io.*" %>
<head>
	<LINK REL="SHORTCUT ICON" HREF="../images/icons/mdosthi-favicon.png"> 
</head>
<% 	

	layout LayoutMenu = new layout(request.getRealPath("/"));

	String menu=LayoutMenu.getMainMenu();
	out.println(menu);
	
	
%>
