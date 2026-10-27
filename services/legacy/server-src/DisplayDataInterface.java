package imedix;
/**
 * @author Saikat Ray
 **/
  
import java.rmi.*;
import java.sql.*;
import java.util.Vector;
import java.util.ArrayList;

/**
 * <center><b>iMediX Business Logic RMI Server </b></center>
 * <p>
 * Developted at Telemedicine Lab, IIT Kharagpur.
 * <p>
 * This Interface used for Manage The Display The Data of iMediX System.
 * @author Saikat Ray.<br>Telemedicine Lab, IIT Kharagpur
 * @author <a href="mailto:skt.saikat@gmail.com">skt.saikat@gmail.com</a>
 * @see DisplayData
 */
 
//remote interface
public interface DisplayDataInterface extends Remote {
	    
     public Object DisplayMed(String id,String dt,String slno)throws RemoteException,SQLException ;
     
     public Object DisplayFrm(String tnam,String id,String dt,String slno)throws RemoteException,SQLException ;
    
     public Object getAttachmentAndOtherFrm(String id,String ftype,String slno,String dt) throws RemoteException,SQLException;

      public Object getSelfRelationPatList(String ccode) throws RemoteException, SQLException;

      public Object getFamilyMembers(String primarypatid) throws RemoteException, SQLException;
      
     public Object DisplayFrmLayers(String tnam,String id,String dt,String slno)throws RemoteException,SQLException ;
     
     public Object getChildAndOtherFrm(String id,String ftype,String slno) throws RemoteException,SQLException;
	 
     public Object getImgdetailsOtherimgMarkimg(String mtype,String id,String type,String dt,String isl,String msl,String rcode) throws RemoteException,SQLException;
	
     public Object showLists(String paid)throws RemoteException,SQLException ;
     
     public Object showAllLists(String paid)throws RemoteException,SQLException ;
      
     public Object viewSummary(String paid)throws RemoteException,SQLException ;
     
     public Object viewSummary(String paid,String ccode)throws RemoteException,SQLException;
     
     public byte[] getImage(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException ;
     public byte[] getBackupImage(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException ;
        
     public String getImageCon_type(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException ;
     
     public byte[] getRImage(String paid,String edate,String type,String slno,String islno,String rcode)throws RemoteException,
        SQLException ;
        
     public String getRImageCon_type(String paid,String edate,String type,String slno,String islno,String rcode)throws RemoteException,
        SQLException ;
     
     public byte[] getDocument(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException ;
     
     public Object getDocumentdetailsOthers(String paid,String edate,String type,String slno) throws RemoteException,SQLException;
     
     public String getDocumentExt(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException ;
        
     public byte[] getMovie(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException ;
     
     public Object getMoviedetailsOthers(String paid,String edate,String type,String slno) throws RemoteException,SQLException;
     
     public String getMovieExt(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException ;
     
     public String getMovieCon_type(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException ;

    public Object getDataTeleRequest(String ccode,String pid)throws RemoteException,SQLException;
     
   	public Object getComplaintSummary(String id, int no ) throws RemoteException,SQLException;
   	public String getVisitSummaryPHIV(String id, String year, int no) throws RemoteException,SQLException;
	public String getVisitSummaryGEN(String id, String year, int no) throws RemoteException,SQLException;

   	public Object getYearVisitSummary(String id) throws RemoteException,SQLException;
   	
    public String getObservation(String id, String date)throws RemoteException,SQLException;
    
    public String getPrescription(String id, String date,String slno) throws RemoteException,SQLException;
    
    public String getAntiretroviralPrescription(String id,String edate,String slno) throws RemoteException,SQLException;
    public String getCTXSummary(String id, int no,String edate,String slno)throws RemoteException,SQLException;
    public String getAntiTuberculosisSummary(String id, int no,String edate,String slno)throws RemoteException,SQLException;
        
    
    public String getGenPrescriptionforMedication(String id,String date,String slno) throws RemoteException,SQLException;
    public String getRecord(String id, String date) throws RemoteException,SQLException;
    public dataobj getVisitDates(String id,String year) throws RemoteException,SQLException;
    
    public String getImpression(String id) throws RemoteException,SQLException;
    public String getImmuzinationData(String id) throws RemoteException,SQLException;
    public String getPhenotypeRecord(String id) throws RemoteException,SQLException;  
    
  	public String getCBCSummary(String patid, int no) throws RemoteException,SQLException;
	public String getOtherCBCSummary(String patid, String[][] fields, int no) throws RemoteException,SQLException;
	public String getProbSummary(String patid, int no) throws RemoteException,SQLException;
	public String getAntiRetroViralSummary(String patid, int no) throws RemoteException,SQLException;
	public String getDrugAllergySummary(String patid) throws RemoteException,SQLException;
		
	public String getVaccinationSummary(String patid) throws RemoteException,SQLException;
	public String getDiaognosisSummary(String patid) throws RemoteException,SQLException;
	public String getOncoStageSummary(String patid) throws RemoteException,SQLException;
	
	public dataobj getPatientInfo(String patid) throws RemoteException,SQLException;
	public String getPercentile(String tabname, int month, String val) throws RemoteException,SQLException;
	public dataobj getPercentile(String tabname, int month) throws RemoteException,SQLException;
	
	public String getPastHistoryRecord(String patid) throws RemoteException,SQLException;
	public String getTuberculosisHistoryRecord(String patid)throws RemoteException,SQLException;
	
	public String getBirthHistoryRecord(String patid) throws RemoteException,SQLException;
	
	public String getSocioEcoStatusRecord(String patid) throws RemoteException,SQLException;
	public String getSupportSystemRecord(String patid) throws RemoteException,SQLException;
	public String getARTRecord(String patid) throws RemoteException,SQLException;
	public String getHIVExposedRecord(String patid) throws RemoteException,SQLException;
	public String getAdherenceRecord(String patid) throws RemoteException,SQLException;
	
	public String getSocialHistoryRecord(String patid) throws RemoteException,SQLException;
	public String getDevelopmentMilestonesRecord(String patid) throws RemoteException,SQLException;
	public String getPlanRecord(String patid) throws RemoteException,SQLException;
	public String getDataJSON(String pat_id,String tableName,String date,String nextDate) throws RemoteException,SQLException;	
	public String pendingStudyUID(String pat_id,String extra) throws RemoteException,SQLException;
	public String patWisePendingStudyUID(String pat_id,String extra) throws RemoteException, SQLException;
	public String getPendingStudyList(String opdno) throws RemoteException,SQLException;
   /*Soumyajit Das*/
   public String getPendingStudyListPAT(String opdno,String patid) throws RemoteException,SQLException;
	public ArrayList getSyncedStudyIDList(String opdno) throws RemoteException,SQLException;
	public String activeStudyUID(String pat_id,String extra) throws RemoteException,SQLException;
	public boolean isReport(String test_id) throws RemoteException,SQLException;
	public boolean isNote(String test_id) throws RemoteException,SQLException;
	public String getPathoData(String test_id) throws RemoteException,SQLException;
	public byte[] getPathoData(String test_id, String fileId)throws RemoteException,SQLException;
	public Object latestData(String pat_id,String tableName)throws RemoteException,SQLException;
   public Object requestConsultantQueue(String centerid) throws RemoteException,SQLException;
   public Object getDrugListIMEDIX() throws RemoteException, SQLException;
	public Object getDrugListIMEDIX(String ccode) throws RemoteException, SQLException;
	public Object getDrugList(String name) throws RemoteException, SQLException;

   public Object getDepartments(String center)throws RemoteException, SQLException;
   public Object getAllDepartments(String center)throws RemoteException, SQLException;
   public Object getDoctorsOfDepartment(String ccode, String department)throws RemoteException, SQLException;
   /*Soumyajit Das*/
	public Object getAllDoctors(String center)throws RemoteException, SQLException;
   /*Soumyajit Das*/
   public Object getDrugListByCenter(String ccode) throws RemoteException, SQLException;
   /*Soumyajit Das*/
   public Object getdrugs(String center)throws RemoteException,SQLException;
   /*Soumyajit Das*/
   public Object getAlldrugs(String center)throws RemoteException,SQLException;
   /*Soumyajit Das*/
   public Object getDrugListDefault() throws RemoteException, SQLException;
   
   public Object getAdviceOfPrescription(String preid) throws RemoteException,SQLException;
   /*Surajit*/
   public Object getPrescribedPatientList(String inputdate, String centerid) throws RemoteException, SQLException;
   /*Surajit*/
   public Object getPrescriptionList(String inputdate, String centerid) throws RemoteException, SQLException;
   /*Surajit*/
   public Object getPrescriptionDetails(String inputdate, String centerid, String patid) throws RemoteException, SQLException;
   /*Surajit*/
   public Object getPrintedPrescriptionList(String inputdate) throws RemoteException, SQLException; 
   /*Mithun*/
	public Object searchPatient(String key, String ccode) throws RemoteException, SQLException;  
   /*Surajit*/
   public Vector rkmsStatistics( String fromDate, String toDate, String centerid) throws RemoteException, SQLException;
   /*Surajit*/
   public Vector rkmsStatisticsAdm( String fromDate, String toDate, int codeLength) throws RemoteException, SQLException;   
   /*Surajit*/
   public Object diagnosisStats(String center, String basic_diagnosis, String detailed_diagnosis) throws RemoteException, SQLException;
   /*Surajit */
   public Object diagnosisSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException; 
   //Surajit
   public Object diagnosisSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   //Surajit
   public Object totalNCDScreeningPatient(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException;
   // Surajit
   public Object casteWiseDiagSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   // Surajit
   public Object casteWiseDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException;
   //Surajit
   public Object casteWiseDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   // Surajit
   public Object genderWiseDiagSummaryVisit(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   // Surajit
   public Object genderWiseDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException;
   // Surajit
   public Object genderWiseDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   // Surajit
   public Object religionWiseDiagSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   // Surajit
   public Object religionWiseDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException;
   //Surajit
   public Object religionWiseDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   //Surajit
   public Object otherreligionDiagTotal(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   //Surajit
   public Object otherreligionDiagTotalNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException;
   //Surajit
   public Object otherreligionDiagTotalUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   //Srajit
   public Object hindureligionDiagTotalUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   //Surajit
   public Object hindureligionDiagTotal(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   //Surajit
   public Object hindureligionDiagTotalNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException;
   //Surajit
   public Object childGenderWiseDiagSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   // Surajit
   public Object childGenderWiseDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException;
   //Surajit
   public Object childGenderWiseDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   //Surajit
   public Object oldPatientDiagSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   //Surajit
   public Object oldPatientDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   //Surajit
   public Object newPatientDiagSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   // Surajit
   public Object newPatientDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
	//Surajit
	public Object genderWiseDiagSummaryOldPatient(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;   
	//Surajit
	public Object genderWiseDiagSummaryOldPatientUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
	// Surajit
	public Object childGenderWiseDiagSummaryOldPatientUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
	//Surajit
	public Object genderWiseDiagSummaryNewPatient(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;   
	//Surajit
	public Object genderWiseDiagSummaryNewPatientNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException;
	//Surajit
	public Object childGenderWiseDiagSummaryNewPatientNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException;
	//Surajit
	public Object genderWiseDiagSummaryNewPatientUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
	//Surajit
	public Object childGenderWiseDiagSummaryNewPatientUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
	//Surajit
	public Object genderWiseDiagSummaryOldPatientNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException;
	//Surajit
	public Object childGenderWiseDiagSummaryOldPatientNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException;
	//Surajit
	public Object oldPatientDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException;
	//Surajit
	public Object newPatientDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException;
	//Surajit
	public Object childGenderWiseDiagSummaryOldPatient(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException; 
   //Surajit
   public Object childGenderWiseDiagSummaryNewPatient(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException;
   
   
   
   
   // Mithun
	public Object getDiagnosis(String preid) throws SQLException, RemoteException;
   // Mithun
	public Object getObservationAndAdvice(String preid) throws SQLException, RemoteException;
   // Mithun
	public Object getLastChiefComplaint(String pat_id) throws SQLException, RemoteException;
   //Soumya_B
   public Object getLastNotes(String pat_id) throws SQLException, RemoteException;
   // Mithun
	public Object getChiefComplaints(String pat_id, String entrydate, String serno) throws SQLException, RemoteException;
   //Soumya_B
   public Object getNotes(String pat_id, String entrydate, String serno) throws SQLException, RemoteException;
   /*Soumyajit*/
	public Object stats_age_sex_caste(String centre, String fromdt, String todt) throws SQLException, RemoteException;
   /*Soumyajit*/
	public Object CNT_stats_sex_caste(String centre, String fromdt, String todt,String tag) throws SQLException, RemoteException;
   /*Soumyajit*/
   public Object stats_disease(String centre,String diagnosis,String fromdt, String todt) throws SQLException,RemoteException;
   /*Soumyajit*/
	public Object stats_disease_count(String centre,String diagnosis,String fromdt, String todt) throws SQLException,RemoteException;
   /*Soumyajit*/
   public Object stats_disease_count2(String centre,String diagnosis,String fromdt, String todt) throws SQLException,RemoteException;
   /*Soumyajit*/
	public Object stats_allvisit(String centre,String fromdt, String todt) throws SQLException,RemoteException;
   /*Soumyajit*/
	public Object stats_visitpat(String patid,String fromdt, String todt) throws SQLException,RemoteException;
   /*Soumyajit*/
	public Object CNT_stats_religion_caste(String centre, String fromdt, String todt) throws SQLException, RemoteException;
	
	//Surajit
	public Object ncdScreeningView(String pat_id) throws SQLException, RemoteException;

   /*Soumya_B*/
   public Object getPrescribedTests(String patid) throws RemoteException, SQLException;

   /*Soumya_B*/
   public Object getTobaccoAssessmentData(String patid) throws RemoteException, SQLException;

   /*Soumya_B*/
   
   public Object getSurveyFormDetails(String surveyName) throws RemoteException, SQLException;
   public Object getSurveyFormBySid(String sid) throws RemoteException, SQLException;
   public Object getPatientPrescribedSurveys(String patId) throws RemoteException, SQLException;
   public Object getPatientSurveyResponses(String patId /*String sid*/) throws RemoteException, SQLException;
   public boolean saveSurveyResponse(String patId, String sid, String surveyData, String userId, String submittedBy) throws RemoteException, SQLException;

   /*Soumya_B*/
   public Object getChatControlSettings(String patId) throws RemoteException, SQLException;
   /*Srijit*/
   public String getChatType(String patId) throws RemoteException, SQLException;
   /*Soumya_B*/
   public boolean saveChatControlSettings(String patId, int dailyLimit, int maxDuration, int minInterval, String startTime, String endTime, String blackoutDays) throws RemoteException, SQLException;
   /*Soumya_B - Chat History Interface Methods*/
   public Object getChatSessions(String patId) throws RemoteException, SQLException;

   public Object getChatMessages(String sessionId) throws RemoteException, SQLException;

   public Object getChatMessagesForPatient(String patId) throws RemoteException, SQLException;

   public Object getChatSessionsDateRange(String patId, String fromDate, String toDate) throws RemoteException, SQLException;

   public Object getChatSessionsSummary(String patId) throws RemoteException, SQLException;

   public Object getChatMessageCount(String sessionId) throws RemoteException, SQLException;

   public Object getChatSessionsWithPagination(String patId, int offset, int limit) throws RemoteException, SQLException;

   public Object getChatSessionsWithFilter(String patId, String fromDate, String toDate, String statusFilter, int offset, int limit) throws RemoteException, SQLException;

   public Object getChatEngagementMetrics(String patId, String fromDate, String toDate) throws RemoteException, SQLException;

   public Object getChatMessageAnalytics(String patId, String fromDate, String toDate) throws RemoteException, SQLException;

   public Object getChatResponseTimeAnalytics(String patId, String fromDate, String toDate) throws RemoteException, SQLException;

   public Object getChatUsagePatterns(String patId, String fromDate, String toDate) throws RemoteException, SQLException;

   public Object getChatSessionDetails(String sessionId) throws RemoteException, SQLException;

   public boolean markChatMessagesAsRead(String sessionId) throws RemoteException, SQLException;
   
   public Object getChatSessionsCount(String patId, String fromDate, String toDate, String statusFilter) throws RemoteException, SQLException;

   /*Srijit - Session Summary / Pipeline Interface Methods*/
   public Object getSessionSummaryBySessionId(String sessionId) throws RemoteException, SQLException;

   public Object getSessionSummaryByPatId(String patId) throws RemoteException, SQLException;

   public boolean updateSessionDeltaFields(long deltaId, String persistentTriggers, String persistentConcerns, String cumulativeQuitHistory, String continuedAdvice, String readinessAfter) throws RemoteException, SQLException;

   public boolean queueAnnotation(String patId, String sessionId, boolean forceReannotate) throws RemoteException, SQLException;

   public Object getLatestPipelineRun(String conversationId) throws RemoteException, SQLException;

   public Object getSessionDeltaByToSessionId(String sessionId) throws RemoteException, SQLException;

   public boolean updateDeltaClinicalSummary(String sessionId, String summary) throws RemoteException, SQLException;

   public Object getLatestPatientMemory(String patId) throws RemoteException, SQLException;

   public boolean isSessionAnnotated(String signalId) throws RemoteException, SQLException;

   public Object getPipelineJobStatusCounts() throws RemoteException, SQLException;

   public String getPipelineJobsProcessedToday() throws RemoteException, SQLException;

   public Object getRecentPipelineJobs() throws RemoteException, SQLException;

   public int clearPipelineQueue() throws RemoteException, SQLException;

   public Object getPipelineQueueSettings() throws RemoteException, SQLException;

   public boolean savePipelineQueueSettings(String startTime, String endTime) throws RemoteException, SQLException;

   public boolean saveSessionSummary(String sessionId, String summary) throws RemoteException, SQLException;

   public boolean saveChatType(String patId, String chatType) throws RemoteException, SQLException;

   public Object getChatSessionsStats(String patId) throws RemoteException, SQLException;
   // Soumya_B - Assign Tests
   public Object getAllSurveys() throws RemoteException, SQLException;
   public boolean assignTestToPatient(String patId, String surveyId) throws RemoteException, SQLException;
}
