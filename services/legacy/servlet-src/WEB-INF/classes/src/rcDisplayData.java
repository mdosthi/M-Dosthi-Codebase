package imedix;

import java.rmi.*;
import java.sql.*;
import java.rmi.registry.*;
import java.util.Vector;
import java.util.ArrayList;
import org.json.simple.*;
import org.json.simple.parser.*;

public class rcDisplayData{
	private static DisplayDataInterface ddserver=null;
	private Registry registry;
	projinfo proj;
	
	public rcDisplayData(String p){
	   try{
   	   // value will be read from file;
   	   
   	   proj= new projinfo(p);
   	   
   	   registry=LocateRegistry.getRegistry(proj.blip, Integer.parseInt(proj.blport));
	   ddserver= (DisplayDataInterface)(registry.lookup("DisplayData"));
	   	      	   
   	  }catch(Exception ex){
   	  	  System.out.println(ex.getMessage());
   	  }
	}
	
	public Object DisplayMed(String id,String dt,String slno) throws RemoteException,SQLException{
		 System.out.println(" Call DisplayMed");
		 Object res = ddserver.DisplayMed(id,dt,slno);
 	     return res;
	}
	
	public Object DisplayFrm(String tnam,String id,String dt,String slno) throws RemoteException,SQLException{
		 System.out.println(" Call DisplayFrm");
		 Object res = ddserver.DisplayFrm(tnam,id,dt,slno);
 	     return res;
	}
	
	public Object getAttachmentAndOtherFrm(String id,String ftype,String slno,String dt) throws RemoteException,SQLException{
		 System.out.println(" Call DisplayFrm");
		 Object res = ddserver.getAttachmentAndOtherFrm(id,ftype,slno,dt);
 	     return res;
	}
	
		public Object getSelfRelationPatList(String ccode) throws RemoteException, SQLException{
		Object res = ddserver.getSelfRelationPatList(ccode);
		return res; 
	}
	
	public Object getFamilyMembers(String primarypatid) throws RemoteException, SQLException{
		Object res = ddserver.getFamilyMembers(primarypatid);
		return res;
	}

	public Object DisplayFrmLayers(String tnam,String id,String dt,String slno)throws RemoteException,SQLException{
		return ddserver.DisplayFrmLayers(tnam,id,dt,slno);
	}
          
    public Object getChildAndOtherFrm(String id,String ftype,String slno) throws RemoteException,SQLException{
    	System.out.println(" Call getChildAndOtherFrm");
    	return ddserver.getChildAndOtherFrm(id,ftype,slno);
    }
     
    public Object getImgdetailsOtherimgMarkimg(String mtype,String id,String type,String dt,String isl,String msl,String rcode) throws RemoteException,SQLException{
    	System.out.println(" Call getImgdetailsOtherimgMarkimg");
    	return ddserver.getImgdetailsOtherimgMarkimg(mtype,id,type,dt,isl,msl,rcode);
    }
	
	
	public Object showLists(String paid)throws RemoteException,SQLException{
		return ddserver.showLists(paid);
	}
	public Object showAllLists(String paid)throws RemoteException,SQLException{
		return ddserver.showAllLists(paid);
	}
      
    public Object viewSummary(String paid)throws RemoteException,SQLException{
    	return ddserver.viewSummary(paid);
    }
    
    public Object viewSummary(String paid,String ccode)throws RemoteException,SQLException{
		return ddserver.viewSummary(paid,ccode);
	}
    
	public byte[] GetImage(String paid,String edate,String type,String slno)throws RemoteException,SQLException{
    	return ddserver.getImage(paid,edate,type,slno);
    }
    public byte[] GetBackupImage(String paid,String edate,String type,String slno)throws RemoteException,SQLException{
    	return ddserver.getBackupImage(paid,edate,type,slno);
    }
       
    public String GetImageCon_type(String paid,String edate,String type,String slno)throws RemoteException,SQLException{
    	//System.out.println(" Called GetImageCon_type ");
    	return ddserver.getImageCon_type(paid,edate,type,slno);
    }
    
    public byte[] getRImage(String paid,String edate,String type,String slno,String islno,String rcode)throws RemoteException,SQLException {
        	System.out.println(" Called getRImage ");
        	return ddserver.getRImage(paid,edate,type,slno,islno,rcode);
        }
        
    public String getRImageCon_type(String paid,String edate,String type,String slno,String islno,String rcode)throws RemoteException,SQLException {
        	return ddserver.getRImageCon_type(paid,edate,type,slno,islno,rcode);
        }
        
     public byte[] getDocument(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException {
        	return ddserver.getDocument(paid,edate,type,slno);
        }
     
     public Object getDocumentdetailsOthers(String paid,String edate,String type,String slno) throws RemoteException,SQLException{
     	return ddserver.getDocumentdetailsOthers(paid,edate,type,slno);
     }
     
     public String getDocumentExt(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException {
        	return ddserver.getDocumentExt(paid,edate,type,slno);
     }
        
     public byte[] getMovie(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException {
        	return ddserver.getMovie(paid,edate,type,slno);
     }
     
     public Object getMoviedetailsOthers(String paid,String edate,String type,String slno) throws RemoteException,SQLException{
     		return ddserver.getMovieExt(paid,edate,type,slno);
     }
     
     public String getMovieExt(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException {
        	return ddserver.getMovieExt(paid,edate,type,slno);
     }
      
     public String getMovieCon_type(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException {
        	return ddserver.getMovieCon_type(paid,edate,type,slno);
     }
        
     public Object getDataTeleRequest(String ccode,String pid)throws RemoteException,SQLException {
          return ddserver.getDataTeleRequest(ccode,pid);	
     }
     
     public Object getComplaintSummary(String id, int no ) throws RemoteException,SQLException{
     	 return ddserver.getComplaintSummary(id,no);
     }
     
     public String getVisitSummaryPHIV(String id, String year, int no) throws RemoteException,SQLException{
	     return ddserver.getVisitSummaryPHIV(id,year,no);
     }
     
     public String getVisitSummaryGEN(String id, String year, int no) throws RemoteException,SQLException{
	     return ddserver.getVisitSummaryGEN(id,year,no);
     }
     
     public Object getYearVisitSummary(String id) throws RemoteException,SQLException {
     	return ddserver.getYearVisitSummary(id);
     }
    public String getObservation(String id, String date)throws RemoteException,SQLException{
    	return ddserver.getObservation(id,date);
    }
    
    public String getPrescription(String id, String date,String slno) throws RemoteException,SQLException{
    		return ddserver.getPrescription(id,date,slno);
    }
    
    public String getAntiretroviralPrescription(String id,String edate,String slno) throws RemoteException,SQLException{
    	 return ddserver.getAntiretroviralPrescription(id,edate,slno);
    }
    
    public String getGenPrescriptionforMedication(String id,String date,String slno) throws RemoteException,SQLException{
    		return ddserver.getGenPrescriptionforMedication(id,date,slno);
    }
    
   	public String getCTXSummary(String id, int no,String edate,String slno)throws RemoteException,SQLException{
   		return ddserver.getCTXSummary(id,no,edate,slno);
   	
   	}
	public String getAntiTuberculosisSummary(String id, int no,String edate,String slno)throws RemoteException,SQLException{
		return ddserver.getAntiTuberculosisSummary(id,no,edate,slno);
	}

    public String getRecord(String id, String date) throws RemoteException,SQLException{
    	return ddserver.getRecord(id,date);
    }
    
    public String getImpression(String id) throws RemoteException,SQLException{
    	return ddserver.getImpression(id);
    }
    
    public String getImmuzinationData(String id) throws RemoteException,SQLException{
    	return ddserver.getImmuzinationData(id);
    }
    
    public String getPhenotypeRecord(String id) throws RemoteException,SQLException{
    	return ddserver.getPhenotypeRecord(id);
    }
    public String getCBCSummary(String patid, int no) throws RemoteException,SQLException{
    	return ddserver.getCBCSummary(patid,no);
    }
	public String getOtherCBCSummary(String patid, String[][] fields, int no) throws RemoteException,SQLException{
		return ddserver.getOtherCBCSummary(patid,fields,no);
	}
	public String getProbSummary(String patid, int no) throws RemoteException,SQLException{
		return ddserver.getProbSummary(patid,no);
	}
	public String getAntiRetroViralSummary(String patid, int no) throws RemoteException,SQLException{
		return ddserver.getAntiRetroViralSummary(patid,no);
	}
	public String getDrugAllergySummary(String patid) throws RemoteException,SQLException{
		return ddserver.getDrugAllergySummary(patid);
	}
	public String getVaccinationSummary(String patid) throws RemoteException,SQLException{
		return ddserver.getVaccinationSummary(patid);	
	}
	 public String getComplaintSummaryInString(String id, int no ) {
     String output="";
     	
     	 output += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
         output += "<tr style='background-color:#D7FFD7'><th>Date</th><th>Chief Complaint</th><th>Duration</th></tr>";

     	try{
		Object res=ddserver.getComplaintSummary(id,no);
		if(res instanceof String) output+=res;
		else{
			Vector Vtmp = (Vector)res;
			if(Vtmp.size()>0){
				for(int j=0;j<Vtmp.size();j++){
					dataobj datatemp = (dataobj) Vtmp.get(j);
					String pdt = datatemp.getValue("entrydate");
					String dt = pdt.substring(8,10)+"/"+pdt.substring(5,7)+"/"+pdt.substring(0,4);
					for (int i = 0; i < 3; i++){
						String tempcomp=datatemp.getValue(i * 3);
						if(tempcomp.equals("")) continue;
						String tempdur = datatemp.getValue(i*3 + 1)+ " "+datatemp.getValue(i*3 + 2);
						output+="<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
						output+="<td align='center' nowrap>"+ dt +"</td>";
						output+="<td align='left'>" + tempcomp + "</td>";
						output+="<td align='left'>" + tempdur + "</td>";
						output+="</tr>";

					}	
				}

			}else{
				output+="<tr style='background-color:#FFFFFF'><td align='center' colspan='3'>No Complaint Recorded</td></tr>";
			}
		}
	}catch(Exception e){
		output+="Exception : "+e;
	}
	 output += "</table>";
	 
	return output;
     }
    
	public String getDiaognosisSummary(String patid) throws RemoteException,SQLException{
			return ddserver.getDiaognosisSummary(patid);	
	}
	public String getOncoStageSummary(String patid) throws RemoteException,SQLException{
			return ddserver.getOncoStageSummary(patid);	
	}
	
	public dataobj getPatientInfo(String patid) throws RemoteException,SQLException{
		return ddserver.getPatientInfo(patid);
	}
	public String getPercentile(String tabname, int month, String val) throws RemoteException,SQLException{
		return ddserver.getPercentile(tabname,month,val);
	}
	public dataobj getPercentile(String tabname, int month) throws RemoteException,SQLException{
		return ddserver.getPercentile(tabname,month);
	}
	
	public String getPastHistoryRecord(String patid) throws RemoteException,SQLException{
		return ddserver.getPastHistoryRecord(patid);
	}
	
	public String getTuberculosisHistoryRecord(String patid)throws RemoteException,SQLException{
		return ddserver.getTuberculosisHistoryRecord(patid);	
	}
	
	public String getBirthHistoryRecord(String patid) throws RemoteException,SQLException{
		return ddserver.getBirthHistoryRecord(patid);
	}
	
	public String getSocioEcoStatusRecord(String patid) throws RemoteException,SQLException{
		return ddserver.getSocioEcoStatusRecord(patid);
	}
	
	public String getSupportSystemRecord(String patid) throws RemoteException,SQLException{
		return ddserver.getSupportSystemRecord(patid);
	}
	public String getARTRecord(String patid) throws RemoteException,SQLException{
		return ddserver.getARTRecord(patid);
	}
	public String getHIVExposedRecord(String patid) throws RemoteException,SQLException{
		return ddserver.getHIVExposedRecord(patid);
	}
	public String getAdherenceRecord(String patid) throws RemoteException,SQLException{
		return ddserver.getAdherenceRecord(patid);
	}
	public String getSocialHistoryRecord(String patid) throws RemoteException,SQLException{
		return ddserver.getSocialHistoryRecord(patid);
	}
	
	public String getDevelopmentMilestonesRecord(String patid) throws RemoteException,SQLException{
		return ddserver.getDevelopmentMilestonesRecord(patid);
	} 
	public String getPlanRecord(String patid) throws RemoteException,SQLException{
		return ddserver.getPlanRecord(patid);
	} 
          
    public String getImageDesc(String typ){
    	String imgDesc="";
    	if(typ.equalsIgnoreCase("BLD")) imgDesc="Blood Slide";
    	else if(typ.equalsIgnoreCase("CTS")) imgDesc="CT Scan";
    	else if(typ.equalsIgnoreCase("DCM")) imgDesc="Dicom Files";
    	else if(typ.equalsIgnoreCase("EEG")) imgDesc="EEG Files ";
    	else if(typ.equalsIgnoreCase("MRI")) imgDesc="MRI Files ";
    	else if(typ.equalsIgnoreCase("SEG")) imgDesc="Scanned ECG";
    	else if(typ.equalsIgnoreCase("SKP")) imgDesc="Scanned Skin Patch";
    	else if(typ.equalsIgnoreCase("SNG")) imgDesc="Sonograms";
    	else if(typ.equalsIgnoreCase("XRA")) imgDesc="X-Ray";
    	else if(typ.equalsIgnoreCase("OTH")) imgDesc="Others";
    	else if(typ.equalsIgnoreCase("DOC")) imgDesc="Documents";
    	else if(typ.equalsIgnoreCase("SND")) imgDesc="Sound Files";
    	else if(typ.equalsIgnoreCase("TEG")) imgDesc= "Text ECG";
    	else if(typ.equalsIgnoreCase("MOV")) imgDesc= "Movie Files";
    	else  imgDesc="Unknown";    
    	                             
    	return imgDesc;                   
    }
    public String getDataJSON(String pat_id,String tableName,String date,String nextDate) throws RemoteException,SQLException{
		return ddserver.getDataJSON(pat_id,tableName,date,nextDate);
	}
	public String pendingStudyUID(String pat_id,String type) throws RemoteException,SQLException{
		return ddserver.pendingStudyUID(pat_id,type);
	}
	public String patWisePendingStudyUID(String pat_id,String extra) throws RemoteException, SQLException{
		return ddserver.patWisePendingStudyUID(pat_id,extra);
	}
	public String getPendingStudyList(String opdno) throws RemoteException,SQLException{
		return ddserver.getPendingStudyList(opdno);
	}
	/*Soumyajit Das*/
	public String getPendingStudyListPAT(String opdno,String patid) throws RemoteException,SQLException{
		return ddserver.getPendingStudyListPAT(opdno,patid);
	}
	public ArrayList getSyncedStudyIDList(String opdno) throws RemoteException,SQLException{
		return ddserver.getSyncedStudyIDList(opdno);
	}
	public String activeStudyUID(String pat_id,String type) throws RemoteException,SQLException{
		return ddserver.activeStudyUID(pat_id,type);
	}
	public boolean isReport(String test_id) throws RemoteException,SQLException{
		return ddserver.isReport(test_id);
	}
	public boolean isNote(String test_id) throws RemoteException,SQLException{
		return ddserver.isNote(test_id);
	}
	public String getPathoData(String test_id) throws RemoteException,SQLException{
		return ddserver.getPathoData(test_id);
	}			
	public byte[] getPathoData(String test_id, String fileId)throws RemoteException,SQLException{
			return ddserver.getPathoData(test_id,fileId);
	}
	public Object latestData(String pat_id,String tableName)throws RemoteException,SQLException{
			return ddserver.latestData(pat_id,tableName);
	}
	public Object requestConsultantQueue(String centerid) throws RemoteException,SQLException{
		return ddserver.requestConsultantQueue(centerid);
	}
	public Object getDrugListIMEDIX() throws RemoteException, SQLException
	{
		return ddserver.getDrugListIMEDIX();
	}	
	public Object getDrugListIMEDIX(String ccode) throws RemoteException, SQLException{
		return ddserver.getDrugListIMEDIX(ccode);
	}
	public Object getDrugList(String name) throws RemoteException, SQLException{
		return ddserver.getDrugList(name);
	}

	public Object getDepartments(String center)throws RemoteException, SQLException{
		return ddserver.getDepartments(center);
	}

	public Object getAllDepartments(String center)throws RemoteException, SQLException{
		return ddserver.getAllDepartments(center);
	}

	public Object getDoctorsOfDepartment(String ccode, String department)throws RemoteException, SQLException{
		return ddserver.getDoctorsOfDepartment(ccode, department);
	}
	/*Soumyajit Das*/
	public Object getAllDoctors(String center)throws RemoteException, SQLException{
		return ddserver.getAllDoctors(center);
	}
	/*Soumyajit Das*/
	public Object getDrugListByCenter(String ccode) throws RemoteException, SQLException{
		return ddserver.getDrugListByCenter(ccode);
	}
	/*Soumyajit Das*/
	public Object getdrugs(String center)throws RemoteException,SQLException
	{
		return ddserver.getdrugs(center);
	}
	/*Soumyajit Das*/
	public Object getAlldrugs(String center)throws RemoteException,SQLException
	{
		return ddserver.getAlldrugs(center);
	}
	/*Soumyajit Das*/
	public Object getDrugListDefault() throws RemoteException, SQLException
	{
		return ddserver.getDrugListDefault();
	}

	public Object getAdviceOfPrescription(String preid) throws RemoteException,SQLException{
		return ddserver.getAdviceOfPrescription(preid);
	}
	/*Surajit */
	public Object getPrescribedPatientList(String inputdate, String centerid) throws RemoteException, SQLException{
		return ddserver.getPrescribedPatientList(inputdate, centerid);
	}
	/*Surajit*/
	public Object getPrescriptionList(String inputdate, String centerid) throws RemoteException, SQLException{
		return ddserver.getPrescriptionList(inputdate, centerid);
	}
	/*Surajit*/
	public Object getPrescriptionDetails(String inputdate, String centerid, String patid) throws RemoteException, SQLException{
		return ddserver.getPrescriptionDetails(inputdate, centerid, patid);
	}
	/*Surajit*/
	public Object getPrintedPrescriptionList(String inputdate) throws RemoteException, SQLException{
		return ddserver.getPrintedPrescriptionList(inputdate);	
	}	
	/*Mithun*/
	public Object searchPatient(String key, String ccode) throws RemoteException, SQLException{
		return ddserver.searchPatient(key,ccode);
	}
	/*Surajit*/
	public JSONObject rkmsStatistics( String fromDate, String toDate, String centerid) throws RemoteException, SQLException{
		Vector<Object> v = new Vector();
		v = ddserver.rkmsStatistics(fromDate, toDate, centerid);
		JSONObject jsObjadvSts = new JSONObject();
		JSONObject jsObjgenderSts = new JSONObject();
		try{
			Object res=v.get(0);	//Get data for entrydate VS no of visit
			if(res instanceof String);
			else{
				Vector Vtmp = (Vector)res;
				JSONArray jsArr = new JSONArray();
				if(Vtmp.size()>0){
					for(int j=0;j<Vtmp.size();j++){
						dataobj datatemp = (dataobj) Vtmp.get(j);
						JSONObject jsObj = new JSONObject();
						String pdt = datatemp.getValue("entrydateonly");
						String noofadv = datatemp.getValue("noofadv");
						jsObj.put("t", pdt);
						jsObj.put("y", noofadv);
						jsArr.add(jsObj);
					}
					jsObjadvSts.put("advsts",jsArr);
					//jsArrResult.add(jsObjadvSts);
				}
			}
			Object res1=v.get(1);	//Get data for Gender VS no of patient
			if(res1 instanceof String);
			else{
				Vector Vtmp = (Vector)res1;
				JSONArray jsArr1 = new JSONArray();
				JSONArray jsArrgen = new JSONArray();
				JSONArray jsArrgenno = new JSONArray();
				if(Vtmp.size()>0){
					for(int j=0;j<Vtmp.size();j++){
						dataobj datatemp = (dataobj) Vtmp.get(j);
						String gender = datatemp.getValue("sex");
						String noofgen = datatemp.getValue("genderno");
						jsArrgen.add(gender);
						jsArrgenno.add(noofgen);
					}
					jsArr1.add(jsArrgen);
					jsArr1.add(jsArrgenno);
					jsObjadvSts.put("gendersts",jsArr1);
				}
			}
					
		}catch(Exception e){
			System.out.println("Err092311: "+e);
		}
		 
		return jsObjadvSts;

	}
   /*Surajit*/
   public JSONObject rkmsStatisticsAdm( String fromDate, String toDate, int codeLength) throws RemoteException, SQLException{
		Vector<Object> v = new Vector();
		v = ddserver.rkmsStatisticsAdm(fromDate, toDate, codeLength);   
   		JSONObject jsObjcenterSts = new JSONObject();	
   		try{
   			Object res2=v.get(0);	//Get data for Center VS no of patient
			if(res2 instanceof String);
			else{
				Vector Vtmp = (Vector)res2;
				JSONArray jsArr1 = new JSONArray();
				JSONObject jsObjcenter = new JSONObject();
				if(Vtmp.size()>0){
					for(int j=0;j<Vtmp.size();j++){
						dataobj datatemp = (dataobj) Vtmp.get(j);
						String center = datatemp.getValue("center");
						String noofpat = datatemp.getValue("nop");
						jsObjcenter.put(center, noofpat);
					}
					//jsArr1.add(jsObjcenter);
					jsObjcenterSts.put("centervsnop",jsObjcenter);
				}
			}
   		}catch(Exception ex){System.out.println("rcDisplayData > rkmsStatisticsAdm() "+ex.toString());}
		return jsObjcenterSts;
   }
	public Object diagnosisStats(String center, String basic_diagnosis, String detailed_diagnosis) throws RemoteException, SQLException{
		return ddserver.diagnosisStats(center, basic_diagnosis, detailed_diagnosis);
	}
	public Object totalNCDScreeningPatient(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		return ddserver.totalNCDScreeningPatient(fromdate, todate, center, attr);
	}
	public Object diagnosisSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.diagnosisSummary(fromdate, todate, center, attr, diag);
	}
	public Object diagnosisSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.diagnosisSummaryUnique(fromdate, todate, center, attr, diag);
	}
   	public Object genderWiseDiagSummaryVisit(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.genderWiseDiagSummaryVisit(fromdate, todate, center, attr, diag);
	}
	public Object genderWiseDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		return ddserver.genderWiseDiagSummaryNCD(fromdate, todate, center, attr);
	}
	public Object genderWiseDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.genderWiseDiagSummaryUnique(fromdate, todate, center, attr, diag);
	}
	public Object genderWiseDiagSummaryNewPatient(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.genderWiseDiagSummaryNewPatient(fromdate, todate, center, attr, diag);
	}
	public Object genderWiseDiagSummaryNewPatientNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		return ddserver.genderWiseDiagSummaryNewPatientNCD(fromdate, todate, center, attr);
	}
	public Object childGenderWiseDiagSummaryNewPatientNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		return ddserver.childGenderWiseDiagSummaryNewPatientNCD(fromdate, todate, center, attr);
	}
	public Object genderWiseDiagSummaryOldPatientNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		return ddserver.genderWiseDiagSummaryOldPatientNCD(fromdate, todate, center, attr);
	}
	public Object childGenderWiseDiagSummaryOldPatientNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		return ddserver.childGenderWiseDiagSummaryOldPatientNCD(fromdate, todate, center, attr);
	}
	public Object genderWiseDiagSummaryOldPatient(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.genderWiseDiagSummaryOldPatient(fromdate, todate, center, attr, diag);
	}
	public Object genderWiseDiagSummaryOldPatientUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.genderWiseDiagSummaryOldPatientUnique(fromdate, todate, center, attr, diag);
	}
	public Object childGenderWiseDiagSummaryOldPatientUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.childGenderWiseDiagSummaryOldPatientUnique(fromdate, todate, center, attr, diag);
	}
	public Object childGenderWiseDiagSummaryOldPatient(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.childGenderWiseDiagSummaryOldPatient(fromdate, todate, center, attr, diag);
	}
	public Object childGenderWiseDiagSummaryNewPatient(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.childGenderWiseDiagSummaryNewPatient(fromdate, todate, center, attr, diag);
	}
	public Object genderWiseDiagSummaryNewPatientUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.genderWiseDiagSummaryNewPatientUnique(fromdate, todate, center, attr, diag);
	}
	public Object childGenderWiseDiagSummaryNewPatientUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.childGenderWiseDiagSummaryNewPatientUnique(fromdate, todate, center, attr, diag);
	}	
	
   	public Object casteWiseDiagSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.casteWiseDiagSummary(fromdate, todate, center, attr, diag);
	}
	public Object casteWiseDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		return ddserver.casteWiseDiagSummaryNCD(fromdate, todate, center, attr);
	}
	public Object casteWiseDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.casteWiseDiagSummaryUnique(fromdate, todate, center, attr, diag);
	}
	public Object religionWiseDiagSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.religionWiseDiagSummary(fromdate, todate, center, attr, diag);
	}
	public Object religionWiseDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		return ddserver.religionWiseDiagSummaryNCD(fromdate, todate, center, attr);
	}
	public Object religionWiseDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.religionWiseDiagSummaryUnique(fromdate, todate, center, attr, diag);
	}
	public Object otherreligionDiagTotal(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.otherreligionDiagTotal(fromdate, todate, center, attr, diag);
	}
	public Object otherreligionDiagTotalNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		return ddserver.otherreligionDiagTotalNCD(fromdate, todate, center, attr);
	}
	public Object otherreligionDiagTotalUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.otherreligionDiagTotalUnique(fromdate, todate, center, attr, diag);
	}
	public Object hindureligionDiagTotalUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.hindureligionDiagTotalUnique(fromdate, todate, center, attr, diag);
	}
	public Object hindureligionDiagTotal(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.hindureligionDiagTotal(fromdate, todate, center, attr, diag);
	}
	public Object hindureligionDiagTotalNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		return ddserver.hindureligionDiagTotalNCD(fromdate, todate, center, attr);
	}
	public Object childGenderWiseDiagSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.childGenderWiseDiagSummary(fromdate, todate, center, attr, diag);
	}
	public Object childGenderWiseDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		return ddserver.childGenderWiseDiagSummaryNCD(fromdate, todate, center, attr);
	}
	public Object childGenderWiseDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.childGenderWiseDiagSummaryUnique(fromdate, todate, center, attr, diag);
	}
	public Object oldPatientDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		return ddserver.oldPatientDiagSummaryNCD(fromdate, todate, center, attr);
	}
	public Object newPatientDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		return ddserver.newPatientDiagSummaryNCD(fromdate, todate, center, attr);
	}
	public Object oldPatientDiagSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.oldPatientDiagSummary(fromdate, todate, center, attr, diag);
	}
	public Object oldPatientDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.oldPatientDiagSummaryUnique(fromdate, todate, center, attr, diag);
	}
	public Object newPatientDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.newPatientDiagSummaryUnique(fromdate, todate, center, attr, diag);
	}
	public Object newPatientDiagSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		return ddserver.newPatientDiagSummary(fromdate, todate, center, attr, diag);
	}
	
   	
   // Mithun
	public Object getDiagnosis(String preid) throws SQLException, RemoteException
	{
		return ddserver.getDiagnosis(preid);
	}
	// Mithun
	public Object getObservationAndAdvice(String preid) throws SQLException, RemoteException
	{
		return ddserver.getObservationAndAdvice(preid);
	}
	// Mithun
	 public Object getLastChiefComplaint(String pat_id) throws SQLException, RemoteException
	 {
		 return ddserver.getLastChiefComplaint(pat_id);
	 }
	//Soumya_B
	 public Object getLastNotes(String pat_id) throws SQLException, RemoteException
	 {
		 return ddserver.getLastNotes(pat_id);
	 }
	// Mithun
	 public Object getChiefComplaints(String pat_id, String entrydate, String serno) throws SQLException, RemoteException
	 {
		 return ddserver.getChiefComplaints(pat_id,entrydate,serno);
	 }
	 //Soumya_B
	 public Object getNotes(String pat_id, String entrydate, String serno) throws SQLException, RemoteException
	 {
		 return ddserver.getNotes(pat_id,entrydate,serno);
	 }
	 /*Soumyajit*/
	public Object stats_age_sex_caste(String centre, String fromdt, String todt) throws SQLException, RemoteException
	{
		return ddserver.stats_age_sex_caste(centre,fromdt,todt);
	}
	/*Soumyajit*/
	public Object CNT_stats_sex_caste(String centre, String fromdt, String todt,String tag) throws SQLException, RemoteException
	{
		return ddserver.CNT_stats_sex_caste(centre,fromdt,todt,tag);
	}
	/*Soumyajit*/
	public Object stats_disease(String centre,String diagnosis,String fromdt, String todt) throws SQLException,RemoteException
	{
		return ddserver.stats_disease(centre,diagnosis,fromdt,todt);
	}
	/*Soumyajit*/
	public Object stats_disease_count(String centre,String diagnosis,String fromdt, String todt) throws SQLException,RemoteException
	{
		return ddserver.stats_disease_count(centre,diagnosis,fromdt,todt);
	}
	/*Soumyajit*/
	public Object stats_disease_count2(String centre,String diagnosis,String fromdt, String todt) throws SQLException,RemoteException
	{
		return ddserver.stats_disease_count2(centre,diagnosis,fromdt,todt);
	}
	/*Soumyajit*/
	public Object stats_allvisit(String centre,String fromdt, String todt) throws SQLException,RemoteException
	{
		return ddserver.stats_allvisit(centre,fromdt,todt);
	}
	/*Soumyajit*/
	public Object stats_visitpat(String patid,String fromdt, String todt) throws SQLException,RemoteException
	{
		return ddserver.stats_visitpat(patid,fromdt,todt);
	}
	/*Soumyajit*/
	public Object CNT_stats_religion_caste(String centre, String fromdt, String todt) throws SQLException, RemoteException
	{
		return ddserver.CNT_stats_religion_caste(centre,fromdt,todt);
	}
	
	//Surajit
	public Object ncdScreeningView(String pat_id) throws SQLException, RemoteException{
		return ddserver.ncdScreeningView(pat_id);
	}

	/*Soumya_B*/
	public Object getPrescribedTests(String patid) throws RemoteException, SQLException {
    System.out.println("Call getPrescribedTests");
    Object res = ddserver.getPrescribedTests(patid);
    return res;
	}
	
	/*Soumya_B*/
	// public Object getTobaccoAssessmentData(String patid) throws RemoteException, SQLException {
   //  System.out.println("Call getTobaccoAssessmentData");
   //  Object res = ddserver.getTobaccoAssessmentData(patid);
   //  return res;
	// }

	
	public Object getTobaccoAssessmentData(String patid) throws RemoteException, SQLException {
    try {
        System.out.println("Call getTobaccoAssessmentData");
        Object res = ddserver.getTobaccoAssessmentData(patid);
        return res;
    		} catch (Exception e) {
        System.out.println("Error in rcDisplayData.getTobaccoAssessmentData: " + e.toString());
        throw e;
    	}
	}

	/*Soumya_B*/
	public Object getSurveyFormDetails(String surveyName) throws RemoteException, SQLException {
    String qSql = "SELECT * FROM survey_project WHERE name = '"+surveyName+"'";
    System.out.println("getSurveyFormDetails(): "+qSql);
    return ddserver.getSurveyFormDetails(surveyName);
	}
	/*Soumya_B*/
	public Object getSurveyFormBySid(String sid) throws RemoteException, SQLException {
	    String qSql = "SELECT * FROM survey_project WHERE sid = '"+sid+"'";
	    System.out.println("getSurveyFormBySid(): "+qSql);
	    return ddserver.getSurveyFormBySid(sid);
	}
	/*Soumya_B*/
	public Object getPatientPrescribedSurveys(String patId) throws RemoteException, SQLException {
	    System.out.println("getPatientPrescribedSurveys: Call for patId = "+patId);
	    return ddserver.getPatientPrescribedSurveys(patId);
	}
	/*Soumya_B*/
	public Object getPatientSurveyResponses(String patId /*String sid*/) throws RemoteException, SQLException {
	    System.out.println("getPatientSurveyResponses: Call for patId = "+patId+"");
	    return ddserver.getPatientSurveyResponses(patId /*, sid*/);
	}
	
	public boolean saveSurveyResponse(String patId, String sid, String surveyData, String userId, String submittedBy) throws RemoteException, SQLException {
    System.out.println("saveSurveyResponse: Call for patId = "+patId+", sid = "+sid+", submittedBy = "+submittedBy);
    return ddserver.saveSurveyResponse(patId, sid, surveyData, userId, submittedBy);
	}

	/*Soumya_B*/
	public Object getChatControlSettings(String patId) throws RemoteException, SQLException {
		System.out.println("getChatControlSettings: call for patId = "+patId);
		return ddserver.getChatControlSettings(patId);
	}
	/*Soumya_B*/
	public boolean saveChatControlSettings(String patId, int dailyLimit, int maxDuration, int minInterval, String startTime, String endTime, String blackoutDays) throws RemoteException, SQLException {
	    System.out.println("saveChatControlSettings: call for patId = " + patId);
	    return ddserver.saveChatControlSettings(patId, dailyLimit, maxDuration, minInterval, startTime, endTime, blackoutDays);
	}
	/*Srijit*/
	public String getChatType(String patId) throws RemoteException, SQLException {
	    System.out.println("getChatType: call for patId = " + patId);
	    return ddserver.getChatType(patId);
	}
	/*Srijit*/
	public Object getSessionSummaryBySessionId(String sessionId) throws RemoteException, SQLException {
	    return ddserver.getSessionSummaryBySessionId(sessionId);
	}
	public Object getSessionSummaryByPatId(String patId) throws RemoteException, SQLException {
	    return ddserver.getSessionSummaryByPatId(patId);
	}
	public boolean updateSessionDeltaFields(long deltaId, String persistentTriggers, String persistentConcerns, String cumulativeQuitHistory, String continuedAdvice, String readinessAfter) throws RemoteException, SQLException {
	    return ddserver.updateSessionDeltaFields(deltaId, persistentTriggers, persistentConcerns, cumulativeQuitHistory, continuedAdvice, readinessAfter);
	}
	public boolean queueAnnotation(String patId, String sessionId, boolean forceReannotate) throws RemoteException, SQLException {
	    return ddserver.queueAnnotation(patId, sessionId, forceReannotate);
	}
	public Object getLatestPipelineRun(String conversationId) throws RemoteException, SQLException {
	    return ddserver.getLatestPipelineRun(conversationId);
	}
	public Object getSessionDeltaByToSessionId(String sessionId) throws RemoteException, SQLException {
	    return ddserver.getSessionDeltaByToSessionId(sessionId);
	}
	public boolean updateDeltaClinicalSummary(String sessionId, String summary) throws RemoteException, SQLException {
	    return ddserver.updateDeltaClinicalSummary(sessionId, summary);
	}
	public Object getLatestPatientMemory(String patId) throws RemoteException, SQLException {
	    return ddserver.getLatestPatientMemory(patId);
	}
	public boolean isSessionAnnotated(String signalId) throws RemoteException, SQLException {
	    return ddserver.isSessionAnnotated(signalId);
	}
	public Object getPipelineJobStatusCounts() throws RemoteException, SQLException {
	    return ddserver.getPipelineJobStatusCounts();
	}
	public String getPipelineJobsProcessedToday() throws RemoteException, SQLException {
	    return ddserver.getPipelineJobsProcessedToday();
	}
	public Object getRecentPipelineJobs() throws RemoteException, SQLException {
	    return ddserver.getRecentPipelineJobs();
	}
	public int clearPipelineQueue() throws RemoteException, SQLException {
	    return ddserver.clearPipelineQueue();
	}
	public Object getPipelineQueueSettings() throws RemoteException, SQLException {
	    return ddserver.getPipelineQueueSettings();
	}
	public boolean savePipelineQueueSettings(String startTime, String endTime) throws RemoteException, SQLException {
	    return ddserver.savePipelineQueueSettings(startTime, endTime);
	}
	public boolean saveSessionSummary(String sessionId, String summary) throws RemoteException, SQLException {
	    return ddserver.saveSessionSummary(sessionId, summary);
	}
	public boolean saveChatType(String patId, String chatType) throws RemoteException, SQLException {
	    return ddserver.saveChatType(patId, chatType);
	}
	/*Soumya_B - Chat History Methods*/
	public Object getChatSessions(String patId) throws RemoteException, SQLException {
	    return ddserver.getChatSessions(patId);
	}

	public Object getChatMessages(String sessionId) throws RemoteException, SQLException {
	    return ddserver.getChatMessages(sessionId);
	}
   //srijit
	public Object getChatMessagesForPatient(String patId) throws RemoteException, SQLException {
	    return ddserver.getChatMessagesForPatient(patId);
	}
   //
	public Object getChatSessionsDateRange(String patId, String fromDate, String toDate) throws RemoteException, SQLException {
	    return ddserver.getChatSessionsDateRange(patId, fromDate, toDate);
	}

	public Object getChatSessionsSummary(String patId) throws RemoteException, SQLException {
	    return ddserver.getChatSessionsSummary(patId);
	}

	public Object getChatMessageCount(String sessionId) throws RemoteException, SQLException {
	    return ddserver.getChatMessageCount(sessionId);
	}

	public Object getChatSessionsWithPagination(String patId, int offset, int limit) throws RemoteException, SQLException {
	    return ddserver.getChatSessionsWithPagination(patId, offset, limit);
	}

	public Object getChatSessionsWithFilter(String patId, String fromDate, String toDate, String statusFilter, int offset, int limit) throws RemoteException, SQLException {
	    return ddserver.getChatSessionsWithFilter(patId, fromDate, toDate, statusFilter, offset, limit);
	}

	public Object getChatEngagementMetrics(String patId, String fromDate, String toDate) throws RemoteException, SQLException {
	    return ddserver.getChatEngagementMetrics(patId, fromDate, toDate);
	}

	public Object getChatMessageAnalytics(String patId, String fromDate, String toDate) throws RemoteException, SQLException {
	    return ddserver.getChatMessageAnalytics(patId, fromDate, toDate);
	}

	public Object getChatResponseTimeAnalytics(String patId, String fromDate, String toDate) throws RemoteException, SQLException {
	    return ddserver.getChatResponseTimeAnalytics(patId, fromDate, toDate);
	}

	public Object getChatUsagePatterns(String patId, String fromDate, String toDate) throws RemoteException, SQLException {
	    return ddserver.getChatUsagePatterns(patId, fromDate, toDate);
	}

	public Object getChatSessionDetails(String sessionId) throws RemoteException, SQLException {
	    return ddserver.getChatSessionDetails(sessionId);
	}

	public boolean markChatMessagesAsRead(String sessionId) throws RemoteException, SQLException {
	    return ddserver.markChatMessagesAsRead(sessionId);
	}

	public Object getChatSessionsCount(String patId, String fromDate, String toDate, String statusFilter) throws RemoteException, SQLException {
	    return ddserver.getChatSessionsCount(patId, fromDate, toDate, statusFilter);
	}

	public Object getChatSessionsStats(String patId) throws RemoteException, SQLException {
	    return ddserver.getChatSessionsStats(patId);
	}

	/*Soumya_B - Assign Tests Wrapper Methods*/
	public Object getAllSurveys() throws RemoteException, SQLException {
	    System.out.println("Call getAllSurveys");
	    return ddserver.getAllSurveys();
	}

	public boolean assignTestToPatient(String patId, String surveyId) throws RemoteException, SQLException {
	    System.out.println("Call assignTestToPatient for patId: " + patId + ", surveyId: " + surveyId);
	    return ddserver.assignTestToPatient(patId, surveyId);
	}
}
