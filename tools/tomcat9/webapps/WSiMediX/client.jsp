<%
   String wsPath=request.getServerName()+ ":" + request.getServerPort()+ request.getContextPath();
%>
<!DOCTYPE html>
  <meta charset="utf-8" />
  <title>WebSocket Test</title>
  <script
  src="https://code.jquery.com/jquery-3.4.1.js"
  integrity="sha256-WpOohJOqMqqyKL9FccASB9O0KwACQJpFTUBLTYOVvVU="
  crossorigin="anonymous">
  </script>
  
  <script language="javascript" type="text/javascript">


  var wsUri = "ws://<%= wsPath %>/endpoint";
  var output;

  function init()
  {
    output = document.getElementById("output");
    testWebSocket();
  }

  function testWebSocket()
  {
    websocket = new WebSocket(wsUri);
    websocket.onopen = function(evt) { onOpen(evt) };
    websocket.onclose = function(evt) { onClose(evt) };
    websocket.onmessage = function(evt) { onMessage(evt) };
    websocket.onerror = function(evt) { onError(evt) };
  }

  function onOpen(evt)
  {
    writeToScreen("CONNECTED");
    doSend("WebSocket rocks");
  }

  function onClose(evt)
  {
    writeToScreen("DISCONNECTED");
  }

  function onMessage(evt)
  { 
    console.log("WebSocket message received:", evt);
    writeToScreen('<span style="color: blue;">():'  + evt.data +'</span>');
    //websocket.close();
  }

  function onError(evt)
  {
    writeToScreen('<span style="color: red;">ERROR:</span> ' + evt.data);
  }

  function doSend(message)
  {
    writeToScreen("SENT: " + message);
    websocket.send(message);
  }

  function writeToScreen(message)
  {
    var pre = document.createElement("p");
    pre.style.margin = " 1px ";
    pre.style.padding = " 1px ";    
    pre.style.wordWrap = "break-word";
    pre.innerHTML = message;
    output.appendChild(pre);
  }

  window.addEventListener("load", init, false);

   $(document).ready(function() {
       $(document).on("click", "#sendbtn", function(){
           var sendText = $("#inp").val();
           doSend(sendText);
       });
   });
   
  </script>
  
  <h2>WebSocket Test</h2>

  <div id="output"></div>
  
  <input type="text" name="inp" id="inp">
  <input type="button" name="sendbtn" id="sendbtn" class="sendbtn" value="send">        