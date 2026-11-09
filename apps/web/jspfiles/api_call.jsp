
<%@ page import="java.io.*, java.net.*, org.json.simple.JSONObject,org.json.simple.parser.JSONParser, imedix.dataobj"%>


<%!


    public String login(String username, String password)
    {
        // Define the API endpoint
        String apiUrl = "https://csjitsi.iitkgp.ac.in/api/user/login"; // Example API endpoint

        
        
        // Construct the JSON payload
        JSONObject payload = new JSONObject();
        payload.put("username", username);
        payload.put("password", password);
        String token="";
        try {
            // Create a URL object
            URL url = new URL(apiUrl);
            
            // Open a connection to the URL
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            
            // Set the request method to POST
            connection.setRequestMethod("POST");
            
            //int responseCode = connection.getResponseCode();

            // Set the request headers
            connection.setRequestProperty("Content-Type", "application/json");
            connection.setRequestProperty("Accept", "application/json");
            
            // Enable input and output streams
            connection.setDoOutput(true);
            
            // Send the JSON payload to the server
            try (OutputStream os = connection.getOutputStream()) {
                byte[] input = payload.toString().getBytes("utf-8");
                os.write(input, 0, input.length); // Write payload to the output stream
            }

            // Read the response from the API
            BufferedReader in = new BufferedReader(new InputStreamReader(connection.getInputStream()));
            String inputLine;
            StringBuffer responseBuffer = new StringBuffer();
            
            while ((inputLine = in.readLine()) != null) {
                responseBuffer.append(inputLine);
            }
            
            in.close();
            //out.println(responseBuffer);
            
            // Convert the response to a string
            String resp = responseBuffer.toString();
            
            //out.println("resp : "+resp);
            // Optionally, parse the JSON response
            JSONObject jsonResponse;
            JSONParser jsonParser = new JSONParser();
            jsonResponse=(JSONObject) jsonParser.parse(resp);
            String id = (String)jsonResponse.get("userid");
            token = (String) jsonResponse.get("jwtToken");

            // Display the response (example)
            //out.println("<h1>API Response</h1>");
            //out.println("<p>Post ID: " + id + "</p>");
            //out.println("<p>Response: " + resp + "</p>"); 
            
        } catch (Exception e) {
            e.printStackTrace();
            //out.println("<p>Error occurred while making the API call.</p>");
            //out.println(e);
        }
        return token;
    }

    
%>
<%!
    public String getSurveyInfo(String token)
    {
        // Define the API endpoint
        String apiUrl = "https://csjitsi.iitkgp.ac.in/api/user/get-survey-info"; // Example API endpoint


        
        // Construct the JSON payload
        JSONObject payload = new JSONObject();
        payload.put("sid", "s1");
        String resp="";
        try {
            // Create a URL object
            URL url = new URL(apiUrl);
            
            // Open a connection to the URL
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            
            // Set the request method to POST
            connection.setRequestMethod("POST");
            
            //int responseCode = connection.getResponseCode();

            // Set the request headers
            connection.setRequestProperty("Authorization", "Bearer " + token);  // Bearer token header
            connection.setRequestProperty("Content-Type", "application/json");
            //connection.setRequestProperty("Accept", "application/json");
            
            // Enable input and output streams
            connection.setDoOutput(true);
            
            // Send the JSON payload to the server
            try (OutputStream os = connection.getOutputStream()) {
                byte[] input = payload.toString().getBytes("utf-8");
                os.write(input, 0, input.length); // Write payload to the output stream
            }

            // Read the response from the API
            BufferedReader in = new BufferedReader(new InputStreamReader(connection.getInputStream()));
            String inputLine;
            StringBuffer responseBuffer = new StringBuffer();
            
            while ((inputLine = in.readLine()) != null) {
                responseBuffer.append(inputLine);
            }
            
            in.close();
            //out.println(responseBuffer);
            
            // Convert the response to a string
            resp = responseBuffer.toString();
            
            //out.println("resp : "+resp);
            // Optionally, parse the JSON response
            JSONObject jsonResponse;
            JSONParser jsonParser = new JSONParser();
            jsonResponse=(JSONObject) jsonParser.parse(resp);
            //String id = (String)jsonResponse.get("userid");
            //token = (String) jsonResponse.get("jwtToken");

            // Display the response (example)
            //out.println("<h1>API Response</h1>");
            //out.println("<p>Post ID: " + id + "</p>");
            //out.println("<p>Response: " + resp + "</p>"); 
            
        } catch (Exception e) {
            e.printStackTrace();
            //out.println("<p>Error occurred while making the API call.</p>");
            //out.println(e);
        }
        return resp;
    }


%>
<%!

    public String createNewEdosthiLogin(dataobj obj)
    {
        // Define the API endpoint
        String apiUrl = "https://csjitsi.iitkgp.ac.in/api/user/create-new-M-Dosthi-login"; // Example API endpoint


        String token=login("user1","user1");
        
        // Construct the JSON payload
        JSONObject payload = new JSONObject();
        payload.put("uid",obj.getValue("uid"));
        payload.put("pwd",obj.getValue("pwd"));
        payload.put("name",obj.getValue("name"));
        payload.put("crtdate", obj.getValue("crtdate"));
        payload.put("rg_no", obj.getValue("rg_no"));
        payload.put("center", obj.getValue("center"));
        //payload.put("userid", obj.getValue("userid"));
        payload.put("type",obj.getValue("type"));
        payload.put("active",obj.getValue("active"));
        payload.put("available",obj.getValue("available"));
        payload.put("referral",obj.getValue("referral"));
        payload.put("verified", obj.getValue("verified"));
        payload.put("verifemail", obj.getValue("verifemail")); 
        payload.put("verifphone", obj.getValue("verifphone")); 
        payload.put("consent",obj.getValue("consent"));
        payload.put("phone",obj.getValue("phone"));
        String resp="";
        try {
            // Create a URL object
            URL url = new URL(apiUrl);
            
            // Open a connection to the URL
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            
            // Set the request method to POST
            connection.setRequestMethod("POST");
            
            //int responseCode = connection.getResponseCode();

            // Set the request headers
            connection.setRequestProperty("Authorization", "Bearer " + token);  // Bearer token header
            connection.setRequestProperty("Content-Type", "application/json");
            //connection.setRequestProperty("Accept", "application/json");
            
            // Enable input and output streams
            connection.setDoOutput(true);
            
            // Send the JSON payload to the server
            try (OutputStream os = connection.getOutputStream()) {
                byte[] input = payload.toString().getBytes("utf-8");
                os.write(input, 0, input.length); // Write payload to the output stream
            }

            // Read the response from the API
            BufferedReader in = new BufferedReader(new InputStreamReader(connection.getInputStream()));
            String inputLine;
            StringBuffer responseBuffer = new StringBuffer();
            
            while ((inputLine = in.readLine()) != null) {
                responseBuffer.append(inputLine);
            }
            
            in.close();
            //out.println(responseBuffer);
            
            // Convert the response to a string
            resp = responseBuffer.toString();
            
            //out.println("resp : "+resp);
            // Optionally, parse the JSON response
            JSONObject jsonResponse;
            JSONParser jsonParser = new JSONParser();
            jsonResponse=(JSONObject) jsonParser.parse(resp);
            //String id = (String)jsonResponse.get("userid");
            //token = (String) jsonResponse.get("jwtToken");

            // Display the response (example)
            //out.println("<h1>API Response</h1>");
            //out.println("<p>Post ID: " + id + "</p>");
            //out.println("<p>Response: " + resp + "</p>"); 
            
        } catch (Exception e) {
            e.printStackTrace();
            //out.println("<p>Error occurred while making the API call.</p>");
            //out.println(e);
        }
        return resp;
    }


%>

<%!

    public String createNewEdosthiPatient(dataobj obj,String patient_id)
    {
        // Define the API endpoint
        String apiUrl = "https://csjitsi.iitkgp.ac.in/api/user/create-new-M-Dosthi-patient"; // Example API endpoint


        String token=login("user1","user1");
        
        // Construct the JSON payload
        JSONObject payload = new JSONObject();


            payload.put("pat_id", patient_id);
            payload.put("entrydate", obj.getValue("entrydate"));
            payload.put("pat_name", obj.getValue("pat_name"));
            payload.put("type", obj.getValue("type"));
            payload.put("age", obj.getValue("age"));
            payload.put("sex", obj.getValue("sex"));
            payload.put("religion", obj.getValue("religion"));
            payload.put("class", obj.getValue("class"));
            payload.put("consent", obj.getValue("consent"));
            payload.put("addline1", obj.getValue("addline1"));
            payload.put("addline2", obj.getValue("addline2"));
            payload.put("policestn", obj.getValue("policestn"));
            payload.put("phone", obj.getValue("phone"));
            payload.put("city", obj.getValue("city"));
            payload.put("dist", obj.getValue("dist"));
            payload.put("state", obj.getValue("state"));
            payload.put("country", obj.getValue("country"));
            payload.put("pin", obj.getValue("pin"));
            payload.put("pat_person", obj.getValue("pat_person"));
            payload.put("pat_relation", obj.getValue("pat_relation"));
            payload.put("pat_person_add", obj.getValue("pat_person_add"));
            payload.put("referring_doctor", obj.getValue("referring_doctor"));
            payload.put("dateofbirth", obj.getValue("dateofbirth"));
            payload.put("pre", obj.getValue("pre"));
            payload.put("m_name", obj.getValue("m_name"));
            payload.put("l_name", obj.getValue("l_name"));
            payload.put("m_status", obj.getValue("m_status"));
            payload.put("race", obj.getValue("race"));
            payload.put("caste_category", obj.getValue("caste_category"));
            payload.put("persidtype", obj.getValue("persidtype"));
            payload.put("persidvalue", obj.getValue("persidvalue"));
            payload.put("persidchecked", obj.getValue("persidchecked"));
            payload.put("opdno", obj.getValue("opdno"));
            payload.put("relationship", obj.getValue("relationship"));
            payload.put("primarypatid", obj.getValue("primarypatid"));
            payload.put("category", obj.getValue("category"));



        
        String resp="";
        try {
            // Create a URL object
            URL url = new URL(apiUrl);
            
            // Open a connection to the URL
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            
            // Set the request method to POST
            connection.setRequestMethod("POST");
            
            //int responseCode = connection.getResponseCode();

            // Set the request headers
            connection.setRequestProperty("Authorization", "Bearer " + token);  // Bearer token header
            connection.setRequestProperty("Content-Type", "application/json");
            //connection.setRequestProperty("Accept", "application/json");
            
            // Enable input and output streams
            connection.setDoOutput(true);
            
            // Send the JSON payload to the server
            try (OutputStream os = connection.getOutputStream()) {
                byte[] input = payload.toString().getBytes("utf-8");
                os.write(input, 0, input.length); // Write payload to the output stream
            }

            // Read the response from the API
            BufferedReader in = new BufferedReader(new InputStreamReader(connection.getInputStream()));
            String inputLine;
            StringBuffer responseBuffer = new StringBuffer();
            
            while ((inputLine = in.readLine()) != null) {
                responseBuffer.append(inputLine);
            }
            
            in.close();
            //out.println(responseBuffer);
            
            // Convert the response to a string
            resp = responseBuffer.toString();
            
            //out.println("resp : "+resp);
            // Optionally, parse the JSON response
            JSONObject jsonResponse;
            JSONParser jsonParser = new JSONParser();
            jsonResponse=(JSONObject) jsonParser.parse(resp);
            //String id = (String)jsonResponse.get("userid");
            //token = (String) jsonResponse.get("jwtToken");

            // Display the response (example)
            //out.println("<h1>API Response</h1>");
            //out.println("<p>Post ID: " + id + "</p>");
            //out.println("<p>Response: " + resp + "</p>"); 
            
        } catch (Exception e) {
            e.printStackTrace();
            //out.println("<p>Error occurred while making the API call.</p>");
            //out.println(e);
        }
        return resp;
    }


%>

<%
    //String token=login("user1","user1");
    //out.println("Token : "+token);

    //String outp=getSurveyInfo(token);
    //out.println("Survey info : "+outp);


            // dataobj loginObj = new dataobj();
            // loginObj.add("pat_name","Test");
            // loginObj.add("l_name","Test");
            // loginObj.add("entrydate", "2024-11-26 14:18:13");
            // loginObj.add("consent", "u");
            // loginObj.add("country", "IN");
            // loginObj.add("pin", "71212121");
            // loginObj.add("dateofbirth","1980-03-07");
            // loginObj.add("persidchecked","0");



            // String outp=createNewEdosthiPatient(loginObj,"svyVARN0000");

%>