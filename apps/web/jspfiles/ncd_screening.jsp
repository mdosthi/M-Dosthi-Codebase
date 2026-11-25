<%@page language="java"  import= "imedix.rcUserInfo,imedix.rcDataEntryFrm,imedix.rcAdminJobs,imedix.rcCentreInfo,imedix.dataobj,imedix.cook,java.util.*,imedix.rcDisplayData"%>
<%@page language="java" import="org.json.simple.JSONArray, org.json.simple.JSONObject" %>
<%@ include file="..//includes/chkcook.jsp" %>

<html>
<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
	<link rel="stylesheet" href="../bootstrap/css/bootstrap.css">
	<script src="../bootstrap/jquery-2.2.1.min.js"></script>
	<script src="../bootstrap/js/bootstrap.min.js"></script>
	<script src="../bootstrap/js/bootstrap.js"></script>




<%

cook cookx = new cook();
String id = cookx.getCookieValue("patid", request.getCookies());
String userid = cookx.getCookieValue("userid", request.getCookies());
String ht_status = "", ht_symptoms = "", dm_status = "", dm_symptoms = "", bc_status = "", oc_status = "";

ht_status = request.getParameter("ht");
ht_symptoms = request.getParameter("hypertension-symp");
dm_status = request.getParameter("dm");
dm_symptoms = request.getParameter("daibetes-symp");
bc_status = request.getParameter("bc");

oc_status = request.getParameter("oc");


if (ht_status != null||dm_status != null||bc_status != null||oc_status != null && id.length()>0){
	String [] bc_symptoms = request.getParameterValues("bc-symptoms");	
	String [] oc_symptoms = request.getParameterValues("oc-symptoms");
	out.println(ht_status+" : "+ht_symptoms+"\n");
	out.println(dm_status+" : "+dm_symptoms+"\n");
	out.println(bc_status+" : "+Arrays.toString(bc_symptoms)+"\n");
	out.println(oc_status+" : "+Arrays.toString(oc_symptoms)+"\n");	
	rcDataEntryFrm rcdef = new rcDataEntryFrm(request.getRealPath("/"));

	ht_status = (ht_status==null)?"":ht_status;
	ht_symptoms = (ht_symptoms==null)?"":ht_symptoms;
	dm_status = (dm_status==null)?"":dm_status;
	dm_symptoms = (dm_symptoms==null)?"":dm_symptoms;
	bc_status = (bc_status==null)?"":bc_status;
	bc_symptoms = (bc_symptoms==null)?new String[0]:bc_symptoms;
	oc_symptoms = (oc_symptoms==null)?new String[0]:oc_symptoms;
	
	dataobj o = new dataobj();
	o.add("userid", userid);
	o.add("pat_id", id);
	o.add("ht_status", ht_status);
	o.add("ht_symptoms", ht_symptoms);
	o.add("dm_status", dm_status);
	o.add("dm_symptoms", dm_symptoms);				
	o.add("bc_status", bc_status);
	o.add("bc_symptoms", Arrays.toString(bc_symptoms));
	o.add("oc_status", oc_status);
	o.add("oc_symptoms", Arrays.toString(oc_symptoms));
	if (rcdef.insertNCDScreeningData(o)){
		out.println("Data recorded in database");
	}
}
else if(id.length()==0)
	out.println("No patient id found!");
else{
	out.println("");
	}


// Display the recorded data
/*
rcDisplayData ddinfo=new rcDisplayData(request.getRealPath("/"));
Object res = ddinfo.ncdScreeningView(id);
if (res instanceof String){
	out.println("</br>center><h1> Data Not Available </h1></center>");
	////diag_summary_jsonobj.put("totalInstances", 0);
}
else{
	Vector tmp_summary = (Vector)res;
	dataobj obj = null;
	for(int i=0; i<tmp_summary.size(); i++){
		obj = (dataobj) tmp_summary.get(i);
		out.println(obj.getValue("ht_status"));
		out.println(obj.getValue("ht_symptoms"));
		out.println(obj.getValue("dm_status"));
		out.println(obj.getValue("dm_symptoms"));
		out.println(obj.getValue("bc_status"));
		out.println(obj.getValue("bc_symptoms"));
		out.println(obj.getValue("oc_status"));
		out.println(obj.getValue("oc_symptoms"));
		out.println(obj.getValue("entrydate"));
	}
}
*/
%>















<style>
.input-group{
	margin: 4px;
}
.input-group .checkbox{
	margin: 0 8px;
    background: #f4f9ff;
    padding: 4px;	
}
.input-group .input-group-addon{
    min-width: 165px;
    background: #39648d;
    color: #f3f3f3;
}
.ncd-screening{
	border: 1px solid #ccc;
    border-radius: 4px;
    box-shadow: 0px 0px 1px 1px #9ed4e9;
    margin: 10px 0;	
}
.submit-ncd-screening{
display: block;
margin: auto;	
}
</style>

<script>

$(document).ready(function(){
	$('.breast-cancer').on('change', function(e){
	   if(e.target.checked){
		 $('#breastCancerModal').modal();
		 e.preventDefault();
	   }
	});
	
	$('.oral-cancer').on('change', function(e){
	   if(e.target.checked){
		 $('#oralCancerModal').modal();
		 e.preventDefault();
	   }
	});	
	
	$('.hypertension-chk').on('change', function(e){
	   if(e.target.checked){
		 $('#hypertensionModal').modal();
		 e.preventDefault();
	   }
	});	
	
	$('.diabetes-chk').on('change', function(e){
	   if(e.target.checked){
		 $('#diabetesModal').modal();
		 e.preventDefault();
	   }
	});		
	

$("#ncd-form").submit(function(e) {

    e.preventDefault(); // avoid to execute the actual submit of the form.

    var form = $(this);
    var actionUrl = "ncd_screening.jsp";
    
    $.ajax({
        type: "POST",
        url: actionUrl,
        data: form.serialize(), // serializes the form's elements.
        success: function(data)
        {
          //alert(data); // show response from the php script.
			alert("Data is recorded successfully!");
			
			window.location.href = window.location.href;
			var ajax_load = "<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='loading...'>";
			$(".main-body").html(ajax_load).load("patientAlldata.jsp?id=<%=id%>"); 			
			$('#ncd_screening').modal('toggle');	
			$(".modal-backdrop").remove();	
			if($('#patPres').hasClass('ui-dialog-content'))
			{
						$("#patPres" ).dialog( "close" );
						$("#patPres").remove();
			}           
			
			  console.log(data);
        }
    });
    
});	

	
		
});
</script>
	
<body>
	<div class="container-fluid">
		<div class="row">
			
			<div class="col-sm-12">
			
	<form id="ncd-form" method="POST" >		
			<div class="ncd-screening">
  <div class="input-group">
    <span class="input-group-addon">Hypertension</span>
	<div class="checkbox">
	  <label><input type="checkbox" value="normal" class="hypertension-chk" name = "ht" >Normal</label>
	  <label><input type="checkbox" value="suspected" class="hypertension-chk" name = "ht"  >Suspected (>130/80 mmHg)</label>
	  <label><input type="checkbox" value="detected" class="hypertension-chk" name = "ht"  >Detected (>140/90 mmHg)</label>
	</div>
  </div>
  
  <div class="input-group">
    <span class="input-group-addon">Diabetes Mellitus</span>
	<div class="checkbox">
	  <label><input type="checkbox" value="normal" class = "diabetes-chk" name = "dm" >Normal</label>
	  <label><input type="checkbox" value="suspected" class = "diabetes-chk" name = "dm" >Suspected</label>
	  <label><input type="checkbox" value="detected" class = "diabetes-chk" name = "dm" >Detected</label>
	</div>
  </div>
  
  
  <div class="input-group">
    <span class="input-group-addon">Breast Cancer</span>
	<div class="checkbox">
	  <label><input type="checkbox" value="normal" name="bc" >Normal</label>
	  <label><input type="checkbox" value="suspected" class = "breast-cancer" name ="bc" >Suspected</label>
	  <label><input type="checkbox" value="detected" class = "breast-cancer" name="bc" >Detected</label>
	</div>
  </div>
  
  
  <div class="input-group">
    <span class="input-group-addon">Oral Cancer</span>
	<div class="checkbox">
	  <label><input type="checkbox" value="normal" name="oc" >Normal</label>
	  <label><input type="checkbox" value="suspected" class = "oral-cancer" name="oc" >Suspected</label>
	  <label><input type="checkbox" value="detected" class = "oral-cancer" name="oc" >Detected</label>
	</div>
  </div>
  
 <!-- 
  <div class="input-group">
    <span class="input-group-addon">Antenatal Care</span>
	<div class="checkbox">
	  <label><input type="checkbox" value="" name="">Suspected</label>
	  <label><input type="checkbox" value="">Detected</label>
	</div>
  </div>        
  
  <div class="input-group">
    <span class="input-group-addon">Eye Refraction Testing</span>
	<div class="checkbox">
	  <label><input type="checkbox" value="">Suspected</label>
	  <label><input type="checkbox" value="">Detected</label>
	</div>
  </div>
  -->    
  
</div>  
  

<!-- Modal for breast cancer symptoms -->
<div class="modal fade" id="breastCancerModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <!--<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>-->
        <h4 class="modal-title" id="myModalLabel">Breast cancer Symptoms</h4>
      </div>
      <div class="modal-body">
		<div class="checkbox">
		  <label><input type="checkbox" name = "bc-symptoms" value="Lump in a breast">Lump in a breast</label><br/>
		  <label><input type="checkbox" name = "bc-symptoms" value="Change in the size of breast">Change in the size of breast</label><br/>
		  <label><input type="checkbox" name = "bc-symptoms" value="Retraction of nipple">Retraction of nipple</label><br/>
		  <label><input type="checkbox" name = "bc-symptoms" value="Nipple discharge - blood/serous stained">Nipple discharge - blood/serous stained</label><br/>
		  <label><input type="checkbox" name = "bc-symptoms" value="Breast skin changes">Breast skin changes</label><br/>
		  <label><input type="checkbox" name = "bc-symptoms" value="Lymphadenopathy - Axilla">Lymphadenopathy - Axilla</label>
		</div>
      </div>
      <!--<div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
        <button type="button" class="btn btn-primary">Save changes</button>
      </div>-->
    </div>
  </div>
</div>


<!-- Modal for oral cancer symptoms -->
<div class="modal fade" id="oralCancerModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <!--<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>-->
        <h4 class="modal-title" id="myModalLabel">Oral cancer Symptoms</h4>
      </div>
      <div class="modal-body">
		<div class="checkbox">
		  <label><input type="checkbox" name="oc-symptoms" value="Leucoplakia">Leucoplakia</label><br/>
		  <label><input type="checkbox" name="oc-symptoms" value="Erythroplakia">Erythroplakia</label><br/>
		  <label><input type="checkbox" name="oc-symptoms" value="Difficulty in opening mouth">Difficulty in opening mouth</label><br/>
		  <label><input type="checkbox" name="oc-symptoms" value="Difficulty in protrusion of tongue">Difficulty in protrusion of tongue</label><br/>
		  <label><input type="checkbox" name="oc-symptoms" value="Change in voice">Change in voice</label><br/>
		  <label><input type="checkbox" name="oc-symptoms" value="Difficulty in deglutination/chewing">Difficulty in deglutination/chewing</label><br/>
		  <label><input type="checkbox" name="oc-symptoms" value="Non-healing ulcer in mouth (persistent ulcer >3 weeks)">Non-healing ulcer in mouth (persistent ulcer >3 weeks)</label><br/>
		  <label><input type="checkbox" name="oc-symptoms" value="Lump / mass in the neck">Lump / mass in the neck</label>
		</div>
      </div>
    </div>
  </div>
</div>


<!-- Modal for Hypertension symptoms -->
<div class="modal fade" id="hypertensionModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <!--<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>-->
        <h4 class="modal-title" id="myModalLabel">Hypertension Symptoms</h4>
      </div>
      <div class="modal-body">
		<textarea class="form-control" name="hypertension-symp" id="hypertension-form" ></textarea>
      </div>
    </div>
  </div>
</div>


<!-- Modal for Diabetes symptoms -->
<div class="modal fade" id="diabetesModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <!--<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>-->
        <h4 class="modal-title" id="myModalLabel">Daibetes Symptoms</h4>
      </div>
      <div class="modal-body">
		<textarea class="form-control" name="daibetes-symp" id="daibetes-form" ></textarea>
      </div>
    </div>
  </div>
</div>


  <input type="submit" value="Submit" class="btn btn-primary submit-ncd-screening" />
  </form>
  
  
				</div>
			</div>
			
		</div>
	</div>
</body>

	
	
	
</html>
