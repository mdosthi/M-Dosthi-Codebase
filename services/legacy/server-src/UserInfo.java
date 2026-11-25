package imedix;

import java.rmi.*;
import java.sql.*;
import java.rmi.server.*;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Date;
import java.util.StringTokenizer;
import java.util.Vector;
import java.io.*;
import java.math.BigInteger;

import logger.*;
import java.text.SimpleDateFormat;

public class UserInfo extends UnicastRemoteObject implements UserInfoInterface {

	projinfo pinfo;
	dball mydb;
	public UserInfo(projinfo p) throws RemoteException{
		pinfo=p;
		mydb= new dball(pinfo);
	}
	
// 	public int  InsertRegUsers(dataobj obj,byte[] b)throws RemoteException,SQLException{
  //    		int ans =0,tag=0;
  //   		dataobj tmp= obj;
  //   		String qr="",key="",val="";
// 			String tmpUtype="",tmpDistype="",tmpRg_no="",tmp_Actv="";;
			
  //   		String uid=tmp.getValue("uid");
  //   		String type=tmp.getValue("type");
  //   		String ccode=tmp.getValue("center");
    		
// 			tmp.replace("crtdate",myDate.getCurrentDateMySql());
			
  //   	//	if(type.equalsIgnoreCase("usr")){
// 				tmp.add("rg_no",genusrrg_no(type,ccode));
// 		//	}

// 			System.out.println("ans **:"+ans);
// 			ans=checkuser(uid,tmp.getValue("rg_no"));
			
  //    		System.out.println("ans **>>:"+ans);
     		
  //    		if(ans==0) return ans;
    		
  //   		try{
  //   			//qr = "select * from regusers";
  //   			qr = "select * from login";
// 				String token = mydb.FieldTypesmeta(qr);
// 				StringTokenizer st = new StringTokenizer(token,"=&");
// 				qr = "insert into login values( ";
// 				while(st.hasMoreTokens()){
// 					key = st.nextToken();
// 					val = st.nextToken();
// 						String qv=tmp.getValue(key);
// 						qv=qv.replaceAll("'","''");
// 						//System.out.println("KEy : "+key);
// 						if(key.equalsIgnoreCase("type")){
// 							 tmpUtype=qv;
// 							 tmpDistype=tmp.getValue("dis");
// 							 tmpRg_no=tmp.getValue("rg_no"); 
// 							 tmp_Actv=tmp.getValue("active"); 
// 						}
						
// 						if(qv==null) qv="";
												
// 						if(qv.length()>0){
// 							if(val.equalsIgnoreCase("CHAR") ||val.equalsIgnoreCase("VARCHAR")){
// 								if(key.equalsIgnoreCase("pwd")){
// 									// qr = qr+"AES_ENCRYPT('"+qv+"', UNHEX(SHA2('"+tmp.getValue("uid")+"',512))),";
// 									qr = qr+"'"+getMD5(qv)+"',";
// 								}else
// 									qr = qr+"'"+qv+"',";
// 							}		
// 							else if(val.equalsIgnoreCase("DATE") || val.equalsIgnoreCase("DATETIME")){
// 								//String dt=myDate.getFomateDate("ymd",true,qv);
// 								qr = qr+"'"+qv+"',";
// 							}							
// 							else if (val.equalsIgnoreCase("INT") || val.equalsIgnoreCase("NUMERIC") ||val.equalsIgnoreCase("FLOAT")||val.equalsIgnoreCase("DECIMAL"))
// 								qr = qr+qv+",";
// 							else {
// 								System.out.println("MatchNot Found :"+val);
// 								qr = qr+"'"+qv+"',";
// 							}
							
// 						}else if (val.equalsIgnoreCase("blob") || val.equalsIgnoreCase("longblob") || val.equalsIgnoreCase("mediumblob")){
// 								if(b==null) qr = qr + "null,";
// 								else	qr=qr+"?,";
// 						}else
// 							qr = qr + "null,";	
					
					
// 				}

// 				qr=qr.substring(0,qr.length()-1);
// 				qr = qr+ " )";
				
// 				/*
// 					try
// 					{
// 						FileOutputStream out = new FileOutputStream("D:/Log.txt");
				
// 						PrintStream p = new PrintStream( out );
						
// 						p.println (qr);
				
// 						p.close();
// 					}
// 					catch (Exception e)
// 					{
// 						System.err.println ("Error writing to file");
// 					}
// 				*/
					
// 				System.out.println(qr);
				
// 				String str=""; 
// 			//	if(==null)	
				
// 				str=mydb.ExecuteSql(qr);
// 				InsertRegUsers_users(tmp); // Calling to make entry in users table
				
// 			//	else str=mydb.ExecuteImage(qr,b); 

// 	   			if(str.equalsIgnoreCase("Error")) ans=0;
// 	   			else{
// 	   				ans =1; 
		   		
// 		  ////////////////////////// log //////////////////////////////////////////////////////////////////
					
// 					imedixlogger imxlog = new imedixlogger(pinfo);
// 					dataobj keydtls = new dataobj();
// 					dataobj desdtls = new dataobj();
// 					keydtls.add("uid",uid);
// 					desdtls.add("table","login");
					
// 					if(tmp_Actv.equalsIgnoreCase("Y")) desdtls.add("details","Insert User with Activated (" + type + ")" );
// 					else  desdtls.add("details","Insert User without Activated (" + type + ")" );
					
// 				//	System.out.println("************bbbb****************");
						
// 					imxlog.putFormInformation(tmp.getValue("userid"),tmp.getValue("usertype"),1,keydtls,desdtls);
					
// 		/////////////////////////////////////////////// log ////////////////////////////////////////////
					
// 				//	System.out.println("****************************");
					
// 						if(tmp_Actv.equalsIgnoreCase("Y") && tmpUtype.equalsIgnoreCase("doc")){
// 		   				String IsQl="insert into  othdis values('"+tmpRg_no.trim() +"','"+tmpDistype.trim()+"')";
// 		   				mydb.ExecuteSql(IsQl);
// 		   				tmp_Actv="";
// 		   				tmpUtype="";
// 		   			}
		   			
// 	   			}
  //   		}catch(Exception e){
  //   			System.out.println("Exception :"+e.toString());
  //   			ans =0;	
  //   		}
  //   	return ans;
  // }
	public int InsertRegUsers(dataobj obj, byte[] b) throws RemoteException, SQLException {
    int ans = 0, tag = 0;
    dataobj tmp = obj;
    String qr = "", key = "", val = "";
    String tmpUtype = "", tmpDistype = "", tmpRg_no = "", tmp_Actv = "";
    
    String uid = tmp.getValue("uid");
    String type = tmp.getValue("type");
    String ccode = tmp.getValue("center");
    
    tmp.replace("crtdate", myDate.getCurrentDateMySql());
    
    tmp.add("rg_no", genusrrg_no(type, ccode));
    
    System.out.println("ans **:" + ans);
    ans = checkuser(uid, tmp.getValue("rg_no"));
    
    System.out.println("ans **>>:" + ans);
    
    if (ans == 0) return ans;
    
    try {
        qr = "select * from login";
        String token = mydb.FieldTypesmeta(qr);
        StringTokenizer st = new StringTokenizer(token, "=&");
        qr = "insert into login values( ";
        
        while (st.hasMoreTokens()) {
            key = st.nextToken();
            val = st.nextToken();
            String qv = tmp.getValue(key);
            
            if (qv == null) qv = "";
            qv = qv.replaceAll("'", "''");
            
            if (key.equalsIgnoreCase("type")) {
                tmpUtype = qv;
                tmpDistype = tmp.getValue("dis");
                tmpRg_no = tmp.getValue("rg_no");
                tmp_Actv = tmp.getValue("active");
            }
            
            if (qv.length() > 0) {
                if (val.equalsIgnoreCase("CHAR") || val.equalsIgnoreCase("VARCHAR")) {
                    if (key.equalsIgnoreCase("pwd")) {
                        qr = qr + "'" + getMD5(qv) + "',";
                    } else {
                        qr = qr + "'" + qv + "',";
                    }
                } else if (val.equalsIgnoreCase("DATE") || val.equalsIgnoreCase("DATETIME")) {
                    qr = qr + "'" + qv + "',";
                } else if (val.equalsIgnoreCase("TIMESTAMP")) {
                    if (key.equalsIgnoreCase("instance_time")) {
                        qr = qr + "CURRENT_TIMESTAMP,";
                    } else {
                        qr = qr + "'" + qv + "',";
                    }
                } else if (val.equalsIgnoreCase("INT") || val.equalsIgnoreCase("TINYINT")) {
                    // Default non-null status flags to zero when absent.
                    if (key.equalsIgnoreCase("rctFlag") || key.equalsIgnoreCase("dpdp_agreed")) {
                        String flagValue = tmp.getValue(key);
                        if (flagValue != null && !flagValue.isEmpty()) {
                            qr = qr + flagValue + ",";
                        } else {
                            qr = qr + "0,";
                        }
                    } else {
                        if (qv.length() > 0) {
                            qr = qr + qv + ",";
                        } else {
                            qr = qr + "NULL,";
                        }
                    }
                } else {
                    if (qv.length() > 0) {
                        qr = qr + qv + ",";
                    } else {
                        qr = qr + "NULL,";
                    }
                }
            } else {
                if (val.equalsIgnoreCase("INT") || val.equalsIgnoreCase("TINYINT")) {
                    if (key.equalsIgnoreCase("rctFlag") || key.equalsIgnoreCase("dpdp_agreed")) {
                        qr = qr + "0,";
                    } else {
                        qr = qr + "NULL,";
                    }
                } else if (val.equalsIgnoreCase("TIMESTAMP")) {
                    if (key.equalsIgnoreCase("instance_time")) {
                        qr = qr + "CURRENT_TIMESTAMP,";
                    } else {
                        qr = qr + "NULL,";
                    }
                } else {
                    qr = qr + "NULL,";
                }
            }
        }
        
        qr = qr.substring(0, qr.length() - 1);
        qr = qr + ")";
        
        System.out.println("Final Insert Query: " + qr);
        
        String str = mydb.ExecuteSql(qr);
        
        if (str.equalsIgnoreCase("Error")) {
            ans = 0;
        } else {
            ans = 1;
            
            // Log RCT assignment
            String rctValue = tmp.getValue("rctFlag");
            System.out.println("=== USER REGISTRATION WITH RCT ===");
            System.out.println("User ID: " + uid);
            System.out.println("User Type: " + type);
            System.out.println("RCT Flag: " + (rctValue != null ? rctValue : "0"));
            System.out.println("Registration Number: " + tmp.getValue("rg_no"));
            System.out.println("Center: " + ccode);
            System.out.println("================================");
            
            // Handle doctor-specific logic
            if (tmp_Actv.equalsIgnoreCase("Y") && tmpUtype.equalsIgnoreCase("doc")) {
                String IsQl = "insert into othdis values('" + tmpRg_no.trim() + "','" + tmpDistype.trim() + "')";
                mydb.ExecuteSql(IsQl);
                tmp_Actv = "";
                tmpUtype = "";
            }
        }
        
	    } catch (Exception e) {
	        System.out.println("Exception in InsertRegUsers: " + e.toString());
	        e.printStackTrace();
	        ans = 0;
	    }
	    return ans;
	}
  public int InsertRegUsers_users(dataobj obj)throws RemoteException,SQLException
	{
		int ans =0;
    		dataobj tmp= obj;
    		// String loginid=tmp.getValue("loginid");    		
    		String loginid=tmp.getValue("uid");    		
    		String name=tmp.getValue("name");
    		//String userid=tmp.getValue("userid");
    		String userid=loginid;
    		String pwd=loginid;
    		// String pwd=tmp.getValue("pwd");
    		//pwd="AES_ENCRYPT('"+pwd+"', UNHEX(SHA2('"+userid+"',512)))";
    		//pwd="SHA1('"+pwd+"')";
    		// String age=tmp.getValue("age");
    		// String sex=tmp.getValue("sex");
    		// String ccode=tmp.getValue("ccode");
    		// String user_type=tmp.getValue("user_type");
    		String user_type="svy";
    		String address=tmp.getValue("address");
    		// String mobile=tmp.getValue("mobile");
    		// String email=tmp.getValue("email");
    		String qualification=tmp.getValue("qualification");
    		String designation=tmp.getValue("designation");
    		String verifemail=tmp.getValue("verifemail");
    		String verifphone=tmp.getValue("verifphone");
    		String active="Y";
    		


			  



    		// String userid=genusrrg_no(user_type,ccode);
		// System.out.println("ans **:"+ans);
		// ans=checkuser(loginid,userid);
			
     		// System.out.println("ans **>>:"+ans);
     		
     		// if(ans==0) return ans;
    		
    		
    		
    		//String query="insert into users (loginid,name,userid,pwd,age,sex,ccode,user_type,address,mobile,email,qualification,designation,verifemail,verifphone,active) values ('"+loginid+"','"+name+"','"+userid+"',SHA1('"+pwd+"'),'"+age+"','"+sex+"','"+ccode+"','"+user_type+"','"+address+"','"+mobile+"','"+email+"','"+qualification+"','"+designation+"','"+verifemail+"','"+verifphone+"','"+active+"')";
    		String query="insert into users (loginid,name,userid,pwd,user_type,address,qualification,designation,verifemail,verifphone,active) values ('"+loginid+"','"+name+"','"+userid+"','"+getMD5(pwd)+"','"+user_type+"','"+address+"','"+qualification+"','"+designation+"','"+verifemail+"','"+verifphone+"','"+active+"')";
		
		String str="";
		
		try
		{
			str=mydb.ExecuteSql(query);
			if(str.equalsIgnoreCase("Error")) 
				ans=0;
			else
			{
				ans =1; 
			}
		}
		catch(Exception e)
		{
    			System.out.println("Exception :"+e.toString());
    			ans =0;	
    		}
            System.out.println("Users:>> "+ query+ " : " +ans);
	    	return ans;
	  }
  
   private String  genusrrg_no(String uty,String ccode){
   	String ans=uty+ccode;
   	
   	try{
		
		String iSql = "select rg_no from login where upper(type)='"+uty.toUpperCase() +"' and center='"+ccode +"' order by rg_no desc";
    	System.out.println("iSql="+iSql);
    	String rgno=mydb.ExecuteSingle(iSql);
    	System.out.println("iSql= rgno "+rgno);
    		
    	if(rgno.equalsIgnoreCase("")) ans+="0000";
    	else{
    		int sl=Integer.parseInt(rgno.substring(rgno.length()-4,rgno.length()));
    		System.out.println("sl *****> "+sl);
    		sl++;
    		System.out.println("slN *****> "+sl);
    		
    		if(sl<10) ans=ans+"000"+Integer.toString(sl);
    		else if(sl<100) ans=ans+"00"+Integer.toString(sl);	
    		else if(sl<1000) ans=ans+"0"+Integer.toString(sl);
    		else ans=ans+Integer.toString(sl);
    	}
    
    }catch(Exception e){
    		System.out.println(e.toString());
    		ans="usr0001";
    }
    System.out.println("usr id "+ans);
    return ans;
    		
   }
   
   private int checkuser(String uid,String rgno){
       	try{
    		
    		String iSql = "select uid from login where uid='"+uid+"'";
    		System.out.println("iSql="+iSql);
    		String lid=mydb.ExecuteSingle(iSql);
    		
    		System.out.println("lid="+lid);
    		
    		if(!lid.equals("")) return 0;
    			
    		iSql = "select rg_no from login where rg_no='"+rgno+"'";
    		System.out.println("iSql="+iSql);
    		String rid=mydb.ExecuteSingle(iSql);
    		System.out.println(" l rid="+rid);
    		if(!rid.equals("")) return 0;
    		
    		/*iSql = "select rg_no from regusers where rg_no='"+rgno+"'";
    		System.out.println("iSql="+iSql);
    		rid=mydb.ExecuteSingle(iSql);
    		System.out.println("rid="+rid);
    		if(!rid.equals("")) return 0;
    		*/
    		
    	}catch(Exception e){
    		System.out.println(e.toString());
    		return 0;
    	}
    	System.out.println("result=1");
    	return 1;
    	
    }

	private String getMD5(String msg)
	{
		try { 
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] messageDigest = md.digest(msg.getBytes());
            BigInteger no = new BigInteger(1, messageDigest);
 
            // Convert message digest into hex value
            String hashtext = no.toString(16);
            while (hashtext.length() < 32) {
                hashtext = "0" + hashtext;
            }
            return hashtext;
        } 
        catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
	}    
	
	public Object getuserinfo(String id,String ps) throws RemoteException,SQLException{
		
		
		String pwd = getMD5(ps);
		String sql = "select l.uid,l.name,l.crtdate,l.type,l.phone,l.address,l.emailid,l.qualification,l.designation,"+
					 "l.dis,l.rg_no,l.center,l.active from login l left join med on med.pat_id=l.uid  where "+
					 "((l.uid='"+id+"' and l.pwd='"+pwd+"') or (l.emailid='"+id+"' and l.verifemail='Y' and l.pwd='"+pwd+
					 "') or(l.phone='"+id+"' and l.verifphone='Y' and l.pwd='"+pwd+"') or (l.type='PAT' and med.opdno='"+id+
					 "' and med.relationship='self' and l.pwd='"+pwd+"')) and l.verified='A'";

        // String sql = "select l.uid,l.name,l.crtdate,l.type,l.phone,l.address,l.emailid,l.qualification,l.designation,"+
        //       "l.dis,l.rg_no,l.center,l.active from login l left join med on med.pat_id=l.uid  where "+
        //       "((l.uid='"+id+"' and l.pwd='"+pwd+"') or (l.emailid='"+id+"' and l.pwd='"+pwd+
        //       "') or(l.phone='"+id+"' and l.pwd='"+pwd+"') or (l.type='PAT' and med.opdno='"+id+
        //       "' and med.relationship='self' and l.pwd='"+pwd+"')) and l.verified='A'";

		// String sql = "select uid,name,crtdate,type,phone,address,emailid,qualification,designation,dis,rg_no,center,active from login where uid='"+id+"' AND pwd='"+pwd+"'";
		System.out.println(sql);
		return mydb.ExecuteQuary(sql);
	}
    
	
	public Object getuserinfo(String id) throws RemoteException,SQLException{
		String isql="Select * from login where uid='" +id+"'";
 	   
        return mydb.ExecuteQuary(isql);
	}
	public Object getuserinfoByrgNo(String rg_no) throws RemoteException,SQLException{
		String isql="Select * from login where rg_no='" +rg_no+"'";
 	   
        return mydb.ExecuteQuary(isql);
	}
		
	public String getreg_no(String id) throws RemoteException,SQLException{
		String isql="Select rg_no from login where uid = '" +id+"'";
 	    
        return mydb.ExecuteSingle(isql);  
	}
	
	public String getName(String regn) throws RemoteException,SQLException{
		String isql="Select name from login where upper(rg_no) = '"+regn.toUpperCase()+"'";
 	    //System.out.println(isql);
 	    
        String aa = mydb.ExecuteSingle(isql);
        //System.out.println("'"+aa+"'");
        if(aa.equals("")) aa=regn;
        return aa;
	}
    
	public String getUid(String regn) throws RemoteException,SQLException{
		String isql="Select uid from login where upper(rg_no) = '"+regn.toUpperCase()+"'";
 	    //System.out.println(isql);
 	    
        String aa = mydb.ExecuteSingle(isql);
        //System.out.println("'"+aa+"'");
        if(aa.equals("")) aa=regn;
        return aa;
	}

    public byte[] getSign(String regn)throws RemoteException,SQLException { 
       String qSql= "select sign from login where upper(rg_no) = '"+regn.toUpperCase()+"'";
       System.out.println("getSign :" + qSql); 
      
       return mydb.ExecuteImage(qSql);
     }
     
     
    public Object getValues(String fld, String cond ) throws RemoteException,SQLException{
     	String query = "select " + fld + " from login where " + cond;
        System.out.println(query);
        return mydb.ExecuteQuary(query);
    }
    
     public boolean sendDoctor(String uid,String rcode) throws RemoteException,SQLException{
     	boolean ans=false;
     	SendDocRecords sdr=new SendDocRecords(uid,rcode,pinfo);
     	ans=sdr.CollectDocData();
     	if(ans==true){
     	//	ans=sdr.ftpSendDoc();
     	}
     	return ans;	
     }
     
     public int updateUserInfo(dataobj obj) throws RemoteException,SQLException{
		
		int ans=0;
		String pwd="";
		String uid=obj.getValue("uid");
		String opwd=obj.getValue("oldpwd");	
		String tpwd =obj.getValue("pwd");
		
		if (tpwd != null && !tpwd.isEmpty()){
			// pwd = "AES_ENCRYPT('"+obj.getValue("pwd").replaceAll("'","''")+"', UNHEX(SHA2('"+uid+"',512)))";
			pwd = "'"+getMD5(obj.getValue("pwd"))+"'";
		}else 
			pwd = "";
		if(!obj.getValue("userid").equals("admin")){
			String oldPassword = getMD5(opwd);
			if(!oldPassword.equals(getPswd(uid))) return 2;
		}
			
		
		try{
    		String qr = "UPDATE login set ";
			if (!pwd.isEmpty()) qr += " pwd="+ pwd +",";
			qr += " name='"+ obj.getValue("name").replaceAll("'","''") +"',";
			qr += " address='"+ obj.getValue("address").replaceAll("'","''") +"',";
			qr += " phone='"+ obj.getValue("phone").replaceAll("'","''") +"',";
			qr += " qualification='"+ obj.getValue("qualification").replaceAll("'","''") +"',";
			qr += " designation='"+ obj.getValue("designation").replaceAll("'","''") +"',";
			qr += " emailid='"+ obj.getValue("emailid").replaceAll("'","''") +"',";
			qr += " verifemail='"+ obj.getValue("verifyemailstatus").replaceAll("'","''") +"',";
			qr += " verifphone='"+ obj.getValue("verifyphonestatus").replaceAll("'","''") +"'";
			qr += " where uid ='"+ uid +"'";
			System.out.println("updateUserInfo: "+qr);
			String str=mydb.ExecuteSql(qr);
   			System.out.println("str **:"+str);
   			
   			if(str.equalsIgnoreCase("Error")) ans=0;
   			else{
   					ans=1; 		
   				
	  ////////////////////////// log //////////////////////////////////////////////////////////////////
					imedixlogger imxlog = new imedixlogger(pinfo);
					dataobj keydtls = new dataobj();
					dataobj desdtls = new dataobj();
					keydtls.add("uid",uid);
					desdtls.add("table","login");
					desdtls.add("details","Update User (" + obj.getValue("type") + ")" );
					
					imxlog.putFormInformation(obj.getValue("userid"),obj.getValue("usertype"),2,keydtls,desdtls);
					
		/////////////////////////////////////////////// log ////////////////////////////////////////////



   			}	   			
    		}catch(Exception e){
    			System.out.println("Exception b:"+e.toString());
    			ans=0;
    		}
       return ans;
     }
     
     private String getPswd(String uid){
     	//String qSql="select pwd from login where uid='"+uid+"'";
     	//String qSql="select AES_DECRYPT(pwd,UNHEX(SHA2(uid,512))) pwd from login where uid='"+uid+"'";
		 String qSql="select pwd from login where uid='"+uid+"'";

     	return mydb.ExecuteSingle(qSql);
     }
     

     public boolean updateUserStatus(String uid, String status,dataobj obj) throws RemoteException,SQLException{	
     	String usql = "UPDATE login set active = '"+ status +"' where lower(uid) = '"+uid.toLowerCase().trim()+"'";
     	String str=mydb.ExecuteSql(usql);
     	if(str.equalsIgnoreCase("Error")) return false;
   		else{
   		
   		////////////////////////// log //////////////////////////////////////////////////////////////////
					imedixlogger imxlog = new imedixlogger(pinfo);
					dataobj keydtls = new dataobj();
					dataobj desdtls = new dataobj();
					keydtls.add("uid",uid);
					desdtls.add("table","login");
					desdtls.add("details","Update User Status (active="+ status +")" );
					
					imxlog.putFormInformation(obj.getValue("userid"),obj.getValue("usertype"),2,keydtls,desdtls);
					
		/////////////////////////////////////////////// log ////////////////////////////////////////////

   		
   				return true;
   		
   		}
     	
     }
     
     public int deleteUser(String uid,dataobj obj) throws RemoteException,SQLException{
     
     String usql = "Delete from login where lower(uid) = '"+uid.toLowerCase().trim()+"'";
     	String str=mydb.ExecuteSql(usql);
     	if(str.equalsIgnoreCase("Error")) return 0;
   		else{
   		
   	////////////////////////// log //////////////////////////////////////////////////////////////////
					imedixlogger imxlog = new imedixlogger(pinfo);
					dataobj keydtls = new dataobj();
					dataobj desdtls = new dataobj();
					keydtls.add("uid",uid);
					desdtls.add("table","login");
					desdtls.add("details","Delete User");
					imxlog.putFormInformation(obj.getValue("userid"),obj.getValue("usertype"),3,keydtls,desdtls);
					
	/////////////////////////////////////////////// log ////////////////////////////////////////////
	
   			return 1;
   		 }
     }
     
      public int deleteRegUser(String uid) throws RemoteException,SQLException{
     
      String usql = "Delete from login where lower(uid) = '"+uid.toLowerCase().trim()+"'";
     	String str=mydb.ExecuteSql(usql);
     	if(str.equalsIgnoreCase("Error")) return 0;
   		else	return 1;
   		  	
     }
     
     public Object getAllUsers(String ccode,String utyp,String ARAll) throws RemoteException,SQLException {
     	
     	String qSql="",cond="", cond1="", cond2="";;
     	
     	if (ccode.equalsIgnoreCase("XXXX") || ccode.equalsIgnoreCase("") ) cond="";
     	else cond = " and Upper(center) ='"+ccode.toUpperCase()+"' ";
     	
     	if(utyp.equalsIgnoreCase("")) cond1="";
     	else cond1 = " and upper(type)= '"+utyp.toUpperCase()+"' ";
     	
     	if(ARAll.equalsIgnoreCase("A")) cond2 = " and available= 'Y' ";
     	else if(ARAll.equalsIgnoreCase("R")) cond2 = " and referral= 'Y' ";
     	else cond2="";
     	
     	//qSql = "Select l.uid,l.name as uname ,l.qualification,l.phone,emailid,rg_no,upper(type) as type,available,referral,center,c.name as cname from login l, center c where active = 'Y' "+cond+cond1+cond2 +" and c.code = l.center Order by center,type,uname";
     	qSql = "Select l.uid,l.name as uname ,l.qualification,l.phone,emailid,rg_no,upper(type) as type,available,referral,center,c.name as cname,c.* from login l, center c where active = 'Y' "+cond+cond1+cond2 +" and c.code = l.center Order by center,type,uname";

     	System.out.println("getAllUsers>> : "+qSql);
     	   
		return mydb.ExecuteQuary(qSql);
     }
     
     public String getSpecialization(String docid) throws RemoteException,SQLException {
     	String output="";
     	String qSql = "select dis from othdis where rg_no='"+docid+"' order by dis";
        Object res=mydb.ExecuteQuary(qSql);
        if(res instanceof String){
			output+=res;
		}else{
			Vector Vtmp = (Vector)res;
			for(int i=0;i<Vtmp.size();i++){
				dataobj tempdata = (dataobj) Vtmp.get(i);	
				output+=","+tempdata.getValue("dis");	
			}
		}
		if(output.startsWith(","))   output=output.substring(1);
     	return output;
     }
     
     public String updateAvailability(String Adocid,String Rdocid,dataobj obj) throws RemoteException,SQLException {
       	String usr=obj.getValue("userid").toString(),uSql="",center="",ans="";
       	center=obj.getValue("center").toString();
       	/*if(obj.getValue("userid")==s||obj.getValue("center")=="XXXX"){
       	uSql="Update login set available='N',referral='N'";
        mydb.ExecuteSql(uSql);
       	
       	uSql="Update login set available='Y' where rg_no in ("+Adocid+")";
       	System.out.println(uSql);
       	mydb.ExecuteSql(uSql);
       	
       	  ////////////////////////// log //////////////////////////////////////////////////////////////////
					imedixlogger imxlog = new imedixlogger(pinfo);
					dataobj keydtls = new dataobj();
					dataobj desdtls = new dataobj();
					keydtls.add("rg_no",Adocid);
					desdtls.add("table","login");
					desdtls.add("details","Update Availability (available)");
					imxlog.putFormInformation(obj.getValue("userid"),obj.getValue("usertype"),2,keydtls,desdtls);
					
	/////////////////////////////////////////////// log ////////////////////////////////////////////

       	uSql="Update login set referral='Y' where rg_no in ("+Rdocid+")";
       	System.out.println(uSql);
       	ans = mydb.ExecuteSql(uSql);
       	
       	 ////////////////////////// log //////////////////////////////////////////////////////////////////
					imedixlogger imxlog1 = new imedixlogger(pinfo);
					dataobj keydtls1 = new dataobj();
					dataobj desdtls1 = new dataobj();
					keydtls1.add("rg_no",Rdocid);
					desdtls1.add("table","login");
					desdtls1.add("Update Availability (referral)");
					imxlog1.putFormInformation(obj.getValue("userid"),obj.getValue("usertype"),2,keydtls,desdtls);
					
	/////////////////////////////////////////////// log ////////////////////////////////////////////
}
       	else{*/
       	String cen=" center='"+center+"'";
       	String wh=" where ";
       	String nd=" and ";
    
       	if(center.equalsIgnoreCase("XXXX") ){ //|| usr.equalsIgnoreCase("admin")
			cen="";
			wh="";
			nd="";
		}
			uSql="Update login set available='N',referral='N' "+wh+cen;
			//System.out.println(uSql);
			mydb.ExecuteSql(uSql);
			uSql="Update login set available='Y' where rg_no in ("+Adocid+") "+nd+cen;
       	//System.out.println(uSql);
       	mydb.ExecuteSql(uSql);
       	
       	  ////////////////////////// log //////////////////////////////////////////////////////////////////
					imedixlogger imxlog = new imedixlogger(pinfo);
					dataobj keydtls = new dataobj();
					dataobj desdtls = new dataobj();
					keydtls.add("rg_no",Adocid);
					desdtls.add("table","login");
					desdtls.add("details","Update Availability (available)");
					imxlog.putFormInformation(obj.getValue("userid"),obj.getValue("usertype"),2,keydtls,desdtls);
					
	/////////////////////////////////////////////// log ////////////////////////////////////////////

       	uSql="Update login set referral='Y' where rg_no in ("+Rdocid+") "+nd+cen;
       	//System.out.println(uSql);
       	ans = mydb.ExecuteSql(uSql);
       	
       	 ////////////////////////// log //////////////////////////////////////////////////////////////////
					imedixlogger imxlog1 = new imedixlogger(pinfo);
					dataobj keydtls1 = new dataobj();
					dataobj desdtls1 = new dataobj();
					keydtls1.add("rg_no",Rdocid);
					desdtls1.add("table","login");
					desdtls1.add("Update Availability (referral)");
					imxlog1.putFormInformation(obj.getValue("userid"),obj.getValue("usertype"),2,keydtls,desdtls);
			//}
       	return ans;

     }
	public boolean verifyPatient(String verifiedCode, String emailid) throws RemoteException, SQLException{
		String sql = "update login set verified='A' where verified='"+verifiedCode+"' and emailid='"+emailid+"'";
		String ans = mydb.ExecuteSql(sql);
		if(ans.equalsIgnoreCase("Done"))
			return true;
		else
			return false;
	}
	public boolean convertTOSelf(String patid) throws RemoteException, SQLException{
		String sql = "update med set relationship='Self', primarypatid=null where pat_id='"+patid+"'";
		String ans = mydb.ExecuteSql(sql);
		if(ans.equalsIgnoreCase("Done"))
			return true;
		else
			return false;
	}
	public String existEmail(String emailid) throws RemoteException, SQLException{
		String sql = "select count(*) as noemail from login where emailid='"+emailid+"'";
		System.out.println("existEmail> "+sql);
		return mydb.ExecuteSingle(sql);
	}
	public String existPhone(String phone) throws RemoteException, SQLException{
		String sql = "select count(*) as nophone from login where phone='"+phone+"'";
		System.out.println("existEmail> "+sql);
		return mydb.ExecuteSingle(sql);
	}
	public String existUid(String uid) throws RemoteException, SQLException{
		String sql = "select count(*) as noemail from login where uid='"+uid+"'";
		System.out.println("existEmail> "+sql);
		return mydb.ExecuteSingle(sql);
	}
	public String existRgno(String rgno) throws RemoteException, SQLException{
		String sql = "select count(*) as nophone from login where rg_no='"+rgno+"'";
		System.out.println("existEmail> "+sql);
		return mydb.ExecuteSingle(sql);
	}
	/// New Addition as on 21-April-2020
	public Object getPatientsWithoutLogin(String key) throws RemoteException{
		String sql="";
     	sql = "select * from med left join login on med.pat_id = login.uid where (med.pat_name like '%"+key+"%' or med.m_name like '%"+key+"%' or med.l_name like '%"+key+"%') and login.name IS NULL";
     	System.out.println("getPatientsWithoutLogin : "+sql);
		 
		return mydb.ExecuteQuary(sql);
	}

	public Object getPatientData(String pat_id)throws RemoteException, SQLException{
		String sql="";
     	sql = "select * from med where med.pat_id ='"+pat_id+"'";
     	System.out.println("getPatientData : "+sql);
		 
		return mydb.ExecuteQuary(sql);
	}

	public int addPatientFromMed(dataobj obj) throws RemoteException, SQLException{
		int result = 0;// 0=OK, 1=Error
		String sql="";
		String type = obj.getValue("type");
		String ccode = obj.getValue("center");
		String regno = genusrrg_no(type,ccode);
		String crtdate = myDate.getCurrentDateMySql();
		String emailid = obj.getValue("emailid");
		String phone = obj.getValue("phone");
		String fld ="" , vals ="";
		if (emailid != null && !emailid.isEmpty()) {
			fld += ", emailid, verifemail";
			vals += ", '"+ emailid +"','Y' ";
		} 
		if (phone != null && !phone.isEmpty()) {
			fld += ", phone, verifphone";
			vals += ", '"+ phone +"','Y' ";
		} 
		// String pwd = "AES_ENCRYPT('"+obj.getValue("pwd")+"', UNHEX(SHA2('"+obj.getValue("uid")+"',512)))";
		String pwd = "'"+getMD5(obj.getValue("pwd"))+"'";

     	sql = "insert into login (uid, pwd, name, crtdate, type, rg_no, center, active, available, referral "+fld+",consent) VALUES ";
		sql += "('"+obj.getValue("uid")+"',"+   pwd +",'"+obj.getValue("name")+"','"+crtdate+"','"+
				type+"','"+regno+"','"+ccode+"','"+obj.getValue("active")+"','"+obj.getValue("available")+"','"+obj.getValue("referral")+"' "+vals+",'N')";

		System.out.println("addPatientFromMed : "+sql);
		try{
			mydb.ExecuteSql(sql);
		}catch(Exception e){
			System.out.println("addPatientFromMed: "+e.toString());
			result = 1;
		}
		return result;
	}	
	public Object getuserinfoByEmail(String emailid) throws RemoteException,SQLException{
		// String isql="Select uid,AES_DECRYPT(pwd,UNHEX(SHA2(uid,512))) as pwd, name, crtdate, type, phone, address, emailid, qualification, designation, dis, rg_no, center, active,verifemail,verifphone from login where (emailid='" +emailid+"' or uid='" +emailid+"') ";
        //String isql="Select uid, pwd, name, crtdate, type, phone, address, emailid, qualification, designation, dis, rg_no, center, active,verifemail,verifphone from login where (emailid='" +emailid+"' or uid='" +emailid+"' ) ";
		String id = emailid;
		String isql = "select l.uid,l.pwd, l.name,l.crtdate,l.type,l.phone,l.address,l.emailid,l.qualification,l.designation,"+
			"l.dis,l.rg_no,l.center,l.active,l.verifemail,l.verifphone from login l left join med on med.pat_id=l.uid  where "+
			"(l.uid='"+id+"' or (l.emailid='"+id+"' and l.verifemail='Y'"+
			") or(l.phone='"+id+"' and l.verifphone='Y') or (l.type='PAT' and med.opdno='"+id+
			"' and med.relationship='self')) and l.verified='A'";


        //System.out.println("SQL = "+isql);
		return mydb.ExecuteQuary(isql);
	}
	
	public Object getuserinfoByAny(String serStr) throws RemoteException,SQLException{
		//String isql="Select uid,AES_DECRYPT(pwd,UNHEX(SHA2(uid,512))) as pwd, name, crtdate, type, phone, address, emailid, qualification, designation, dis, rg_no, center, active,verifemail,verifphone from login where (emailid='" +serStr+"' or uid='" +serStr+"'  or phone='" +serStr+"' ) ";
        String isql="Select uid, pwd, name, crtdate, type, phone, address, emailid, qualification, designation, dis, rg_no, center, active,verifemail,verifphone from login where (emailid='" +serStr+"' or uid='" +serStr+"'  or phone='" +serStr+"' ) ";

        //System.out.println("SQL = "+isql);
		return mydb.ExecuteQuary(isql);
	}
	
	public int addLoginRequest(dataobj obj) throws RemoteException, SQLException{
		int result = 0;// 0=OK, 1=Error
		String iSql="";
		String type = obj.getValue("pat_id");
		String ccode = obj.getValue("pat_name");
		String emailid =  obj.getValue("emailid");
		//String mobileno =  obj.getValue("mobileno");
		//iSql = "insert into login_request (pat_id, pat_name, emailid, mobileno) VALUES ";
		//iSql += "('"+obj.getValue("pat_id")+"','"+ obj.getValue("pat_name") +"','"+obj.getValue("emailid")+"','"+obj.getValue("mobileno")+"')";
		iSql = "insert into login_request (pat_id, pat_name, emailid) VALUES ";
		iSql += "('"+obj.getValue("pat_id")+"','"+ obj.getValue("pat_name") +"','"+obj.getValue("emailid")+"')";
		String str=mydb.ExecuteSql(iSql);
		System.out.println("iSql = "+iSql);
     	if(str.equalsIgnoreCase("Error")) return 0;
		else return 1;
	}
	
	public Object getLoginRequestData() throws RemoteException, SQLException{
		String sql= "select login_request.* from login_request where  login_request.pat_id not in (select distinct uid from login)  order by rdate";
     	System.out.println("getPatientData : "+sql);
		return mydb.ExecuteQuary(sql);
	}
	public Object docOfMinPat(String center, String dis) throws RemoteException, SQLException{
		//String sql = "select assigneddoc from lpatq l,login lg where lg.rg_no = l.assigneddoc and lg.available='Y' and lg.center='"+center+"' and l.assigneddoc in (select rg_no from othdis where dis='"+dis+"') group by assigneddoc order by count(*) limit 1";
		String sql = "select rg_no,emailid,phone,uid,name,verifemail,verifphone from login lg LEFT JOIN lpatq l on lg.rg_no = l.assigneddoc where type='DOC' and lg.available='Y' and lg.center='"+center+"' and lg.rg_no in (select rg_no from othdis where dis='"+dis+"') group by assigneddoc order by count(*) limit 1";
		 System.out.println("docOfMinPat() > "+sql);
		 return mydb.ExecuteQuary(sql);
	}
	public String fileUploadLimit(int dayLimit, String pat_id) throws RemoteException, SQLException{
		String sql = "select count(*) from listofforms l where l.pat_id='"+pat_id+"' and type in ('patdoc','patimages','patmovies') and (select visitdate from patientvisit where pat_id='"+pat_id+"' order by visitdate desc limit 1)+ INTERVAL "+dayLimit+" DAY>=DATE(NOW())";
		System.out.println("fileUploadLimit() > "+sql);
		return mydb.ExecuteSingle(sql);
	}
	public boolean resetPassword(String uid, String pass) throws RemoteException,SQLException{
		// String sql="update login set pwd = AES_ENCRYPT('"+pass+"', UNHEX(SHA2('"+uid+"',512))) where uid='"+uid+"'";
		String sql="update login set pwd = '"+getMD5(pass)+"' where uid='"+uid+"'";
		System.out.println("UserInfo -> resetPassword() > "+sql);
		String ans = mydb.ExecuteSql(sql);
		if(ans.equalsIgnoreCase("Done"))
		return true;
		else
		return false;
	}

	public Object getUserOTP(String val) throws RemoteException,SQLException
	{
		String sql="select * from login where emailid='"+val+"' or phone='"+val+"'";
		System.out.println("getUserOTP() > "+sql);
		return mydb.ExecuteQuary(sql);
	}
	public boolean deactivateAccount(String uid) throws RemoteException,SQLException
	{
		String sql="update login set verified='N',consent='N' where rg_no='"+uid+"'";
		System.out.println("deactivateAccount() > "+sql);
		String ans = mydb.ExecuteSql(sql);
		if(ans.equalsIgnoreCase("Done"))
			return true;
		else
			return false;
		
	}
	public boolean activateAccount(String uid) throws RemoteException,SQLException
	{
		String sql="update login set verified='A' where rg_no='"+uid+"'";
		System.out.println("activateAccount() > "+sql);
		String ans = mydb.ExecuteSql(sql);
		if(ans.equalsIgnoreCase("Done"))
			return true;
		else
			return false;
		
	}
	public Object getEmailId() throws RemoteException, SQLException{
		String sql = "select emailid from login limit 0,10000";
		System.out.println("getEmailId() > "+sql);
		return mydb.ExecuteQuary(sql);		
	}
	public Object getEmailId(int low, int high) throws RemoteException, SQLException{
		String sql = "select emailid from login limit"+low+","+high;
		System.out.println("getEmailId(low, high) > "+sql);
		return mydb.ExecuteQuary(sql);		
	}
	//Rct flag operations
	/*Soumya Bhattacharya*/
	public boolean enableRctFlag(String uid) throws RemoteException,SQLException
	{
	    String sql="update login set rctFlag=1 where rg_no='"+uid+"'";
	    System.out.println("enableRctFlag() > "+sql);
	    String ans = mydb.ExecuteSql(sql);
	    if(ans.equalsIgnoreCase("Done"))
	        return true;
	    else
	        return false;
	}

	public boolean disableRctFlag(String uid) throws RemoteException,SQLException
	{
	    String sql="update login set rctFlag=0 where rg_no='"+uid+"'";
	    System.out.println("disableRctFlag() > "+sql);
	    String ans = mydb.ExecuteSql(sql);
	    if(ans.equalsIgnoreCase("Done"))
	        return true;
	    else
	        return false;
	}

	public int getRctFlag(String uid) throws RemoteException,SQLException
	{
	    String sql="select rctFlag from login where rg_no='"+uid+"'";
	    System.out.println("getRctFlag() > "+sql);
	    String ans = mydb.ExecuteSingle(sql);
	    if(ans != null && !ans.isEmpty())
	        return Integer.parseInt(ans);
	    else
	        return 0;
	}
    // public int getRctFlag(String uid) throws RemoteException,SQLException
    //     {
    //         String sql="select rctFlag from login where uid='"+uid+"'";
    //         System.out.println("getRctFlag() > "+sql);
    //         String ans = mydb.ExecuteSingle(sql);
    //         if(ans != null && !ans.isEmpty())
    //             return Integer.parseInt(ans);
    //         else
    //             return 0;
    //     }
	public boolean updateRctFlagAfterRegistration(String uid, int rctFlag) throws RemoteException, SQLException {
    System.out.println("=== updateRctFlagAfterRegistration START ===");
    System.out.println("UID: " + uid);
    System.out.println("RCT Flag: " + rctFlag);
    
    try {
        // First check if user exists in login table
        String checkSql = "SELECT uid FROM login WHERE uid = '" + uid + "'";
        String existingUid = mydb.ExecuteSingle(checkSql);
        
        if (existingUid != null && !existingUid.isEmpty()) {
            // User exists, update RCT flag
            String updateSql = "UPDATE login SET rctFlag = " + rctFlag + " WHERE uid = '" + uid + "'";
            String result = mydb.ExecuteSql(updateSql);
            
            boolean success = !result.equalsIgnoreCase("Error");
            System.out.println("Update result: " + result + ", Success: " + success);
            return success;
            
        } else {
            System.out.println("User not found in login table: " + uid);
            return false;
        }
        
	    } catch (Exception e) {
	        System.out.println("Error in updateRctFlagAfterRegistration: " + e.getMessage());
	        e.printStackTrace();
	        return false;
	    }
	}
	
	public Object getRctStatistics(String center, String userType) throws RemoteException, SQLException {
	    try {
	        String condition = "active = 'Y'";
	        
	        if (!center.equals("XXXX")) {
	            condition += " AND center = '" + center + "'";
	        }
	        
	        if (userType != null && !userType.isEmpty()) {
	            condition += " AND type = '" + userType + "'";
	        }
	        
	        // Get total users
	        String totalSql = "SELECT COUNT(*) as total FROM login WHERE " + condition;
	        
	        // Get RCT enrolled users
	        String rctSql = "SELECT COUNT(*) as rct_count FROM login WHERE " + condition + " AND rctFlag = 1";
	        
	        // Get RCT not enrolled users
	        String nonRctSql = "SELECT COUNT(*) as non_rct_count FROM login WHERE " + condition + " AND rctFlag = 0";
	        
	        System.out.println("RCT Statistics Queries:");
	        System.out.println("Total: " + totalSql);
	        System.out.println("RCT: " + rctSql);
	        System.out.println("Non-RCT: " + nonRctSql);
	        
	        String totalResult = mydb.ExecuteSingle(totalSql);
	        String rctResult = mydb.ExecuteSingle(rctSql);
	        String nonRctResult = mydb.ExecuteSingle(nonRctSql);
	        
	        return "TOTAL:" + totalResult + "|RCT:" + rctResult + "|NONRCT:" + nonRctResult;
	        
	    } catch (Exception e) {
	        System.out.println("Error getting RCT statistics: " + e.getMessage());
	        return "ERROR:" + e.getMessage();
	    }
	}

	public String batchUpdateRctFlags(String userIds, int rctFlag) throws RemoteException, SQLException {
    int successCount = 0;
    int totalCount = 0;
    
    try {
        String[] ids = userIds.split(",");
        totalCount = ids.length;
        
        for (String uid : ids) {
            uid = uid.trim();
            if (!uid.isEmpty()) {
                String updateSql = "UPDATE login SET rctFlag = " + rctFlag + " WHERE uid = '" + uid + "' AND active = 'Y'";
                String result = mydb.ExecuteSql(updateSql);
                
                if (!result.equalsIgnoreCase("Error")) {
                    successCount++;
                    System.out.println("Updated RCT flag for user: " + uid + " to " + rctFlag);
                }
            }
        }
        
        System.out.println("Batch RCT update completed: " + successCount + "/" + totalCount);
        return successCount + "/" + totalCount;
        
	    } catch (Exception e) {
	        System.out.println("Error in batch RCT update: " + e.getMessage());
	        return "ERROR";
	    }
	}


	// // Add these methods to your UserInfo.java class

	// /*Soumya Bhattacharya - Simple RCT Automation Methods*/

	// /*
	//  * Perform batch RCT flag updates for multiple users
	//  * @param rg_nos Comma-separated list of registration numbers
	//  * @param flagValue 1 to enable, 0 to disable
	//  * @return Success count as string
	//  */
	// public String batchUpdateRctFlags(String rg_nos, int flagValue) throws RemoteException, SQLException {
	//     System.out.println("batchUpdateRctFlags() > rg_nos: " + rg_nos + ", flagValue: " + flagValue);
	    
	//     if(rg_nos == null || rg_nos.trim().isEmpty()) {
	//         return "0";
	//     }
	    
	//     try {
	//         // Split the registration numbers
	//         String[] rgArray = rg_nos.split(",");
	//         int successCount = 0;
	        
	//         for(String rg_no : rgArray) {
	//             rg_no = rg_no.trim();
	//             if(!rg_no.isEmpty()) {
	//                 String sql = "UPDATE login SET rctFlag=" + flagValue + " WHERE rg_no='" + rg_no + "'";
	//                 System.out.println("Batch update SQL: " + sql);
	//                 String result = mydb.ExecuteSql(sql);
	                
	//                 if("Done".equalsIgnoreCase(result)) {
	//                     successCount++;
	//                 }
	//             }
	//         }
	        
	//         return String.valueOf(successCount);
	        
	//     } catch(Exception e) {
	//         System.out.println("batchUpdateRctFlags() Error: " + e.getMessage());
	//         return "ERROR: " + e.getMessage();
	//     }
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
	//     System.out.println("getRandomUsersForRct() > center: " + center + ", type: " + userType + ", limit: " + limit + ", excludeRct: " + excludeRct);
	    
	//     try {
	//         String sql = "SELECT rg_no, name, center, emailid, phone, rctFlag FROM login WHERE active='Y' AND type='" + userType + "'";
	        
	//         if(excludeRct) {
	//             sql += " AND rctFlag=0";
	//         }
	        
	//         if(!center.equals("XXXX") && !center.equals("ALL")) {
	//             sql += " AND center='" + center + "'";
	//         } else {
	//             sql += " AND center <> 'XXXX'";
	//         }
	        
	//         sql += " ORDER BY RAND() LIMIT " + limit;
	        
	//         System.out.println("Random users SQL: " + sql);
	//         return mydb.ExecuteQuary(sql);
	        
	//     } catch(Exception e) {
	//         System.out.println("getRandomUsersForRct() Error: " + e.getMessage());
	//         return "ERROR: " + e.getMessage();
	//     }
	// }

	// /*
	//  * Get RCT statistics for a center and user type
	//  * @param center Center code
	//  * @param userType User type
	//  * @return Formatted statistics string
	//  */
	// public String getRctStatistics(String center, String userType) throws RemoteException, SQLException {
	//     System.out.println("getRctStatistics() > center: " + center + ", userType: " + userType);
	    
	//     try {
	//         String sql = "SELECT COUNT(*) as total, ";
	//         sql += "SUM(CASE WHEN rctFlag=1 THEN 1 ELSE 0 END) as enabled, ";
	//         sql += "SUM(CASE WHEN rctFlag=0 THEN 1 ELSE 0 END) as disabled ";
	//         sql += "FROM login WHERE active='Y' AND type='" + userType + "'";
	        
	//         if(!center.equals("XXXX") && !center.equals("ALL")) {
	//             sql += " AND center='" + center + "'";
	//         } else {
	//             sql += " AND center <> 'XXXX'";
	//         }
	        
	//         System.out.println("Statistics SQL: " + sql);
	        
	//         Object result = mydb.ExecuteQuary(sql);
	//         if(result instanceof String) {
	//             return "ERROR: " + result;
	//         }
	        
	//         Vector resultVector = (Vector)result;
	//         if(resultVector.size() > 0) {
	//             dataobj stats = (dataobj)resultVector.get(0);
	//             int total = Integer.parseInt(stats.getValue("total"));
	//             int enabled = Integer.parseInt(stats.getValue("enabled"));
	//             int disabled = Integer.parseInt(stats.getValue("disabled"));
	//             double percentage = total > 0 ? (double)enabled / total * 100 : 0;
	            
	//             return "TOTAL:" + total + "|ENABLED:" + enabled + "|DISABLED:" + disabled + "|PERCENTAGE:" + String.format("%.1f", percentage);
	//         }
	        
	//         return "TOTAL:0|ENABLED:0|DISABLED:0|PERCENTAGE:0.0";
	        
	//     } catch(Exception e) {
	//         System.out.println("getRctStatistics() Error: " + e.getMessage());
	//         return "ERROR: " + e.getMessage();
	//     }
	// }

	// /*
	//  * Reset all RCT flags for a specific center and user type
	//  * @param center Center code
	//  * @param userType User type
	//  * @return Number of affected rows as string
	//  */
	// public String resetAllRctFlags(String center, String userType) throws RemoteException, SQLException {
	//     System.out.println("resetAllRctFlags() > center: " + center + ", userType: " + userType);
	    
	//     try {
	//         String sql = "UPDATE login SET rctFlag=0 WHERE active='Y' AND type='" + userType + "'";
	        
	//         if(!center.equals("XXXX") && !center.equals("ALL")) {
	//             sql += " AND center='" + center + "'";
	//         } else {
	//             sql += " AND center <> 'XXXX'";
	//         }
	        
	//         System.out.println("Reset SQL: " + sql);
	//         String result = mydb.ExecuteSql(sql);
	        
	//         if("Done".equalsIgnoreCase(result)) {
	//             // Get count of affected rows (approximate)
	//             String countSql = sql.replace("UPDATE login SET rctFlag=0", "SELECT COUNT(*)");
	//             String count = mydb.ExecuteSingle(countSql);
	//             return count != null ? count : "0";
	//         } else {
	//             return "ERROR: " + result;
	//         }
	        
	//     } catch(Exception e) {
	//         System.out.println("resetAllRctFlags() Error: " + e.getMessage());
	//         return "ERROR: " + e.getMessage();
	//     }
	// }

	// /*
	//  * Get eligible users count for randomization
	//  * @param center Center code
	//  * @param userType User type
	//  * @param excludeRct Exclude already enrolled users
	//  * @return Count as string
	//  */
	// public String getEligibleUsersCount(String center, String userType, boolean excludeRct) throws RemoteException, SQLException {
	//     System.out.println("getEligibleUsersCount() > center: " + center + ", userType: " + userType + ", excludeRct: " + excludeRct);
	    
	//     try {
	//         String sql = "SELECT COUNT(*) FROM login WHERE active='Y' AND type='" + userType + "'";
	        
	//         if(excludeRct) {
	//             sql += " AND rctFlag=0";
	//         }
	        
	//         if(!center.equals("XXXX") && !center.equals("ALL")) {
	//             sql += " AND center='" + center + "'";
	//         } else {
	//             sql += " AND center <> 'XXXX'";
	//         }
	        
	//         System.out.println("Count SQL: " + sql);
	//         String count = mydb.ExecuteSingle(sql);
	//         return count != null ? count : "0";
	        
	//     } catch(Exception e) {
	//         System.out.println("getEligibleUsersCount() Error: " + e.getMessage());
	//         return "0";
	//     }
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
	//     System.out.println("performStratifiedRandomization() > userType: " + userType + ", percentage: " + percentage + ", maxPerStratum: " + maxPerStratum + ", stratifyBy: " + stratifyBy);
	    
	//     try {
	//         // First, get all unique values for the stratification field
	//         String strataSql = "SELECT DISTINCT " + stratifyBy + " FROM login WHERE active='Y' AND type='" + userType + "' AND rctFlag=0 AND " + stratifyBy + " <> 'XXXX'";
	        
	//         System.out.println("Strata SQL: " + strataSql);
	//         Object strataResult = mydb.ExecuteQuary(strataSql);
	        
	//         if(strataResult instanceof String) {
	//             return "ERROR: No strata found - " + strataResult;
	//         }
	        
	//         Vector strataVector = (Vector)strataResult;
	//         int totalSelected = 0;
	//         StringBuilder summary = new StringBuilder();
	//         summary.append("STRATIFIED_RANDOMIZATION|");
	        
	//         for(int i = 0; i < strataVector.size(); i++) {
	//             dataobj stratum = (dataobj)strataVector.get(i);
	//             String stratumValue = stratum.getValue(stratifyBy);
	            
	//             // Get users in this stratum
	//             String usersSql = "SELECT rg_no, name FROM login WHERE active='Y' AND type='" + userType + "' AND rctFlag=0 AND " + stratifyBy + "='" + stratumValue + "' ORDER BY RAND()";
	            
	//             Object usersResult = mydb.ExecuteQuary(usersSql);
	//             if(!(usersResult instanceof String)) {
	//                 Vector usersVector = (Vector)usersResult;
	//                 int stratumTotal = usersVector.size();
	//                 int stratumToSelect = Math.min(maxPerStratum, (int)Math.ceil(stratumTotal * percentage / 100.0));
	                
	//                 int stratumSelected = 0;
	//                 for(int j = 0; j < Math.min(stratumToSelect, stratumTotal); j++) {
	//                     dataobj user = (dataobj)usersVector.get(j);
	//                     String rg_no = user.getValue("rg_no");
	                    
	//                     String updateSql = "UPDATE login SET rctFlag=1 WHERE rg_no='" + rg_no + "'";
	//                     String updateResult = mydb.ExecuteSql(updateSql);
	                    
	//                     if("Done".equalsIgnoreCase(updateResult)) {
	//                         stratumSelected++;
	//                         totalSelected++;
	//                     }
	//                 }
	                
	//                 summary.append(stratumValue).append(":").append(stratumSelected).append("/").append(stratumTotal).append("|");
	//             }
	//         }
	        
	//         summary.append("TOTAL_SELECTED:").append(totalSelected);
	//         return summary.toString();
	        
	//     } catch(Exception e) {
	//         System.out.println("performStratifiedRandomization() Error: " + e.getMessage());
	//         return "ERROR: " + e.getMessage();
	//     }
	// }	    	
}
