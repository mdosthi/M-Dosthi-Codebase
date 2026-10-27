package imedix;

import java.rmi.*;
import java.sql.*;
import java.rmi.registry.*;
import java.util.Vector;

public class rcUserInfo{
	
	private static UserInfoInterface uiserver=null;
	private Registry registry;
	projinfo proj;
	
	public rcUserInfo(String p){
	   try{
   	   // value will be read from file;
   	   proj= new projinfo(p);
   	   
   	   registry=LocateRegistry.getRegistry(proj.blip, Integer.parseInt(proj.blport));
	   uiserver= (UserInfoInterface)(registry.lookup("UserInfo"));
	   	      	   
   	  }catch(Exception ex){
   	  	  System.out.println(ex.getMessage());
   	  }
	}
	
    public int  InsertRegUsers(dataobj obj,byte[] b)throws RemoteException,SQLException{
    	return uiserver.InsertRegUsers(obj,b);
    }	    

	public Object getuserinfo(String id,String ps) throws RemoteException,SQLException{
		 System.out.println(" Call getuserinfo");
		 Object res = uiserver.getuserinfo(id,ps);
 	     return res;
	}
	public Object getuserinfo(String id) throws RemoteException,SQLException{
		 System.out.println(" Call getuserinfo");
		 Object res = uiserver.getuserinfo(id);
 	     return res;
	}
	
	 public String getreg_no(String id) throws RemoteException,SQLException{
	 	return uiserver.getreg_no(id);
	 }
     
     public String getName(String regn) throws RemoteException,SQLException{
     	return uiserver.getName(regn);
     }

	 public String getUid(String regn) throws RemoteException,SQLException{
		return uiserver.getUid(regn);
	 }
     
     public byte[] getSign(String regn)throws RemoteException,SQLException{
     	return uiserver.getSign(regn);
     }
      
     public Object getValues(String fld, String cond ) throws RemoteException,SQLException{
     	return uiserver.getValues(fld,cond);
     	
     }
     
     public boolean sendDoctor(String uid,String rcode) throws RemoteException,SQLException{
     	return uiserver.sendDoctor(uid,rcode);
     }
     
     public int updateUserInfo(dataobj obj) throws RemoteException,SQLException{
     	return uiserver.updateUserInfo(obj);
     }     
	 
	 public boolean updateUserStatus(String uid,String status,dataobj obj) throws RemoteException,SQLException{
	 		return uiserver.updateUserStatus(uid,status,obj);
	 }
	 
	 public int deleteUser(String uid,dataobj obj) throws RemoteException,SQLException {
	 		return uiserver.deleteUser(uid,obj);
	 }
	 
	 public Object getAllUsers(String ccode,String utyp,String ARAll) throws RemoteException,SQLException {
	 	return uiserver.getAllUsers(ccode,utyp,ARAll);
	 }
	 
	 public Object getuserinfoByrgNo(String rg_no) throws RemoteException,SQLException{
		 return uiserver.getuserinfoByrgNo(rg_no);
	 }
     
     public String getSpecialization(String docid) throws RemoteException,SQLException{
     	return uiserver.getSpecialization(docid);
     }
	 public String updateAvailability(String Adocid,String Rdocid,dataobj obj) throws RemoteException,SQLException{
	 	return uiserver.updateAvailability(Adocid,Rdocid,obj);
	 }
	 public boolean verifyPatient(String verifiedCode, String emailid) throws RemoteException, SQLException{
		return uiserver.verifyPatient(verifiedCode,emailid); 
	 }
	 public boolean convertTOSelf(String patid) throws RemoteException, SQLException{
	 	return uiserver.convertTOSelf(patid);
	 }
	 public String existEmail(String emailid) throws RemoteException, SQLException{
		 return uiserver.existEmail(emailid);
	 }
	 public String existPhone(String phone) throws RemoteException, SQLException{
		 return uiserver.existPhone(phone);
	 }
	 public String existUid(String uid) throws RemoteException, SQLException{
		 return uiserver.existUid(uid);
	 }
	 public String existRgno(String rgno) throws RemoteException, SQLException{
		 return uiserver.existRgno(rgno);
	 }
	//New Addition as on 21-April-2020
	 public Object getPatientsWithoutLogin(String key) throws RemoteException,SQLException {
		return uiserver.getPatientsWithoutLogin(key);
	 }
	 public Object getPatientData(String pat_id)throws RemoteException, SQLException{
		return uiserver.getPatientData(pat_id);
	 }
	 public int addPatientFromMed(dataobj obj) throws RemoteException, SQLException{
		return uiserver.addPatientFromMed(obj);
	 }
	 public Object getuserinfoByEmail(String emailid) throws RemoteException, SQLException{
		return uiserver.getuserinfoByEmail(emailid);
	 }
	 public Object getuserinfoByAny(String serStr) throws RemoteException, SQLException{
		return uiserver.getuserinfoByAny(serStr);
	 }
	 public int addLoginRequest(dataobj obj) throws RemoteException, SQLException{
		return uiserver.addLoginRequest(obj);
	 }
	 public Object getLoginRequestData() throws RemoteException, SQLException{
		return uiserver.getLoginRequestData();
	 }
	public Object docOfMinPat(String center, String dis) throws RemoteException, SQLException{
		return uiserver.docOfMinPat(center, dis);
	}
	public String fileUploadLimit(int dayLimit, String pat_id) throws RemoteException, SQLException{
		return uiserver.fileUploadLimit(dayLimit,pat_id);
	}
	public boolean resetPassword(String uid, String pass) throws RemoteException,SQLException{
		return uiserver.resetPassword(uid,pass);
	}
	public Object getUserOTP(String val) throws RemoteException,SQLException
	{
		return uiserver.getUserOTP(val);
	}
	public boolean deactivateAccount(String uid) throws RemoteException,SQLException
	{
		return uiserver.deactivateAccount(uid);
	}
	public boolean activateAccount(String uid) throws RemoteException,SQLException
	{
		return uiserver.activateAccount(uid);
	}
	public Object getEmailId() throws RemoteException, SQLException
	{
		return uiserver.getEmailId();
	}
	public Object getEmailId(int low, int high) throws RemoteException, SQLException
	{
		return uiserver.getEmailId(low,high);
	}
	/* Soumya Bhattacharya*/
    public int InsertRegUsers_users(dataobj obj)throws RemoteException,SQLException
    {
    	return uiserver.InsertRegUsers_users(obj);
    }
    /*Soumya Bhattacharya*/
    //Rct flag operations
    public boolean enableRctFlag(String uid) throws RemoteException,SQLException
	{
	    return uiserver.enableRctFlag(uid);
	}

	public boolean disableRctFlag(String uid) throws RemoteException,SQLException
	{
	    return uiserver.disableRctFlag(uid);
	}

	public int getRctFlag(String uid) throws RemoteException,SQLException
	{
	    return uiserver.getRctFlag(uid);
	}

	public boolean updateRctFlagAfterRegistration(String uid, int rctFlag) throws RemoteException, SQLException {
	    return uiserver.updateRctFlagAfterRegistration(uid, rctFlag);
	}

	public Object getRctStatistics(String center, String userType) throws RemoteException, SQLException {
	    return uiserver.getRctStatistics(center, userType);
	}
	
	public String batchUpdateRctFlags(String userIds, int rctFlag) throws RemoteException, SQLException {
	    return uiserver.batchUpdateRctFlags(userIds, rctFlag);
	}

	// // Add these methods to your rcUserInfo.java class

	// /*Soumya Bhattacharya - RCT Automation Methods - Client Side RMI Calls*/

	// /*
	//  * Perform batch RCT flag updates for multiple users
	//  * @param rg_nos Comma-separated list of registration numbers
	//  * @param flagValue 1 to enable, 0 to disable
	//  * @return Success count as string
	//  */
	// public String batchUpdateRctFlags(String rg_nos, int flagValue) throws RemoteException, SQLException {
	//     return uiserver.batchUpdateRctFlags(rg_nos, flagValue);
	// }

	// /*
	//  * Get random users for RCT selection based on criteria
	//  * @param center Center code
	//  * @param userType User type (PAT, doc, usr, adm)
	//  * @param limit Maximum number to return
	//  * @param excludeRct If true, exclude users already in RCT
	//  * @return Result object or error string
	//  */
	// public Object getRandomUsersForRct(String center, String userType, int limit, boolean excludeRct) throws RemoteException, SQLException {
	//     return uiserver.getRandomUsersForRct(center, userType, limit, excludeRct);
	// }

	// /*
	//  * Get RCT statistics for a center and user type
	//  * @param center Center code
	//  * @param userType User type
	//  * @return Formatted statistics string
	//  */
	// public String getRctStatistics(String center, String userType) throws RemoteException, SQLException {
	//     return uiserver.getRctStatistics(center, userType);
	// }

	// /*
	//  * Reset all RCT flags for a specific center and user type
	//  * @param center Center code
	//  * @param userType User type
	//  * @return Number of affected rows as string
	//  */
	// public String resetAllRctFlags(String center, String userType) throws RemoteException, SQLException {
	//     return uiserver.resetAllRctFlags(center, userType);
	// }

	// /*
	//  * Get eligible users count for randomization
	//  * @param center Center code
	//  * @param userType User type
	//  * @param excludeRct Exclude already enrolled users
	//  * @return Count as string
	//  */
	// public String getEligibleUsersCount(String center, String userType, boolean excludeRct) throws RemoteException, SQLException {
	//     return uiserver.getEligibleUsersCount(center, userType, excludeRct);
	// }

	// /*
	//  * Advanced randomization with stratification by a field (e.g., center)
	//  * @param userType User type
	//  * @param percentage Percentage to select from each stratum
	//  * @param maxPerStratum Maximum per stratum
	//  * @param stratifyBy Field to stratify by (e.g., 'center')
	//  * @return Result summary
	//  */
	// public String performStratifiedRandomization(String userType, double percentage, int maxPerStratum, String stratifyBy) throws RemoteException, SQLException {
	//     return uiserver.performStratifiedRandomization(userType, percentage, maxPerStratum, stratifyBy);
	// }
}
