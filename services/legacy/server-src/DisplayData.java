package imedix;

import java.rmi.*;
import java.sql.*;
import java.rmi.server.*;
import java.util.Vector;
import java.util.StringTokenizer;
import java.util.*;
import org.json.simple.*;
import java.util.Date;
import java.text.SimpleDateFormat;

/**
 * <center><b>iMediX Business Logic RMI Server </b></center>
 * <p>
 * Developted at Telemedicine Lab, IIT Kharagpur.
 * <p>
 * This Class used for Manage The Display The Data of iMediX System.
 * @author Saikat Ray.<br>Telemedicine Lab, IIT Kharagpur
 * @author <a href="mailto:skt.saikat@gmail.com">skt.saikat@gmail.com</a>
 * @see DisplayData
 */
 
public class DisplayData extends UnicastRemoteObject implements DisplayDataInterface {
		
	projinfo pinfo;
	dball mydb;
	
	/**
     * Constructor used to create this object.
     * @param p server Configuration class object.
     * @see projinfo
     */
     
	public DisplayData(projinfo p) throws RemoteException{
		pinfo=p;
		mydb= new dball(pinfo);
	}
	
	public Object DisplayMed(String id,String dt,String slno) throws RemoteException,SQLException{
		String isql="";
		if(dt.equals("") && slno.equals("")){
			isql="Select * from med where upper(pat_id)='"+id.toUpperCase()+"' order by entrydate desc";
		}else{
			isql="Select * from med where upper(pat_id)='"+id.toUpperCase()+"' and entrydate='"+dt+"' and serno='"+slno+"'";	
		}	
		System.out.println("SQL = "+isql);
 	    return mydb.ExecuteQuary(isql);
	}
	
	public Object DisplayFrm(String tnam,String id,String dt,String slno) throws RemoteException,SQLException{
		System.out.println("Date :-"+dt);
		//Select * from pre where pat_id='VBCR0193008200000' and entrydate=cast('' as DATETIME) and serno='';
		//String isql="Select * from "+ tnam +" where pat_id='"+id+"' and entrydate='"+dt+"' and serno='"+slno+"'";
		String isql="Select * from "+ tnam +" where pat_id='"+id+"' and entrydate=cast('"+dt+"' as DATETIME) and serno='"+slno+"'";
 	    System.out.println("DisplayFrm:"+isql);
 	    return mydb.ExecuteQuary(isql);
	}
	
	public Object getAttachmentAndOtherFrm(String id,String ftype,String slno,String dt) throws RemoteException,SQLException{
		Object res=new Object();
		Vector Vtmp=new Vector();
		String imgname="",movname="";
		dataobj objtemp;
				
		String qSql="select type,serno from patimages where pat_id='"+id+"' and type='"+ftype+"' and formkey='"+slno+"' and entrydate='"+dt+"'";
		
		res = mydb.ExecuteQuary(qSql);
		if(res instanceof String) imgname="";
		else{
			Vtmp= (Vector) res;
			for(int i=0;i<Vtmp.size();i++){
			objtemp=(dataobj) Vtmp.get(i);
			imgname+=objtemp.getValue("type")+"-"+objtemp.getValue("serno")+"#";
			}	
		}
		System.out.println("getAttachmentAndOtherFrm()1>> "+qSql);
						
		qSql="select type,serno from patmovies where pat_id='"+id+"' and type='"+ftype+"' and formkey='"+slno+"' and entrydate='"+dt+"'";
		res=null;
		res = mydb.ExecuteQuary(qSql);
		if(res instanceof String) movname="";
		else{
			Vtmp = (Vector)res;
			for(int i=0;i<Vtmp.size();i++){
			objtemp= (dataobj)Vtmp.get(i);
			movname+=objtemp.getValue("type")+"-"+objtemp.getValue("serno")+"#";
			}	
		}
				
		qSql="select date,serno from listofforms where pat_id ='"+id+"' and Upper(type) ='"+ftype.toUpperCase()+"'";
		res=null;
		res = mydb.ExecuteQuary(qSql);
		System.out.println("getAttachmentAndOtherFrm()2>> "+qSql);
		objtemp=null;
		objtemp = new dataobj();
		objtemp.add("img",imgname);	
		objtemp.add("mov",movname);
		
		Vtmp.add(objtemp); // add the dataobj
		Vtmp.add(res); // add the vector
		return Vtmp;
 	    
	}
	public Object getSelfRelationPatList(String ccode) throws RemoteException, SQLException{
		String isql="Select uid,name,l_name,addline1,login.phone,emailid,opdno from login inner join med on login.uid=med.pat_id where login.type='PAT' and verified='A' and center='"+ccode+"'";
		if(ccode.equalsIgnoreCase("XXXX"))
			isql="Select uid,name,l_name,addline1,login.phone as phone,emailid,opdno from login inner join med on login.uid=med.pat_id where login.type='PAT' and verified='A'";
 	    System.out.println("getSelfRelationPatList(ccode): "+isql);
 	    return mydb.ExecuteQuary(isql);		
	}
	public Object getFamilyMembers(String primarypatid) throws RemoteException, SQLException{
		String isql="Select * from med where primarypatid='"+primarypatid+"'";
 	    System.out.println("getFamilyMembers(): "+isql);
 	    return mydb.ExecuteQuary(isql);			
	}
	
	/*
    public Object DisplayFrmLayers(String tnam,String id,String dt,String slno)throws RemoteException,SQLException{
    	Vector Vtmp=new Vector();
    	String qsql;
    	StringTokenizer frms = new StringTokenizer(tnam,",");
    	while (frms.hasMoreTokens()){
    	String t=frms.nextToken();
		qsql="Select * from "+ t.toLowerCase() +" where pat_id='"+id+"' and entrydate='"+dt+"' and serno='"+slno+"'";
 	    //System.out.println("DisplayFrmLayers:"+qsql);
 	    
 	    Vtmp.add(mydb.ExecuteQuary(qsql));
 	    }	
		return Vtmp;	
    }
	*/
	
    public Object DisplayFrmLayers(String tnam,String id,String dt,String slno)throws RemoteException,SQLException{
    	//ctor Vtmp=new Vector();
    	dataobj newdata=new dataobj();
    	Object res;
    	String qsql;
    	int tag=0;
    	StringTokenizer frms = new StringTokenizer(tnam,",");
    	while (frms.hasMoreTokens()){
		qsql="Select * from "+ frms.nextToken().toLowerCase() +" where pat_id='"+id+"' and entrydate='"+dt+"' and serno='"+slno+"'";
 	    //System.out.println("DisplayFrmLayers:"+qsql);
 	    res=mydb.ExecuteQuary(qsql);
 	    if(res instanceof String) continue;
		else{
		Vector tmp = (Vector)res;
			if(tmp.size()>0){
			  dataobj temp = (dataobj) tmp.get(0);
				  for(int i=0;i<temp.getLength();i++){
				  	if((tag==1) && (temp.getKey(i).equalsIgnoreCase("entrydate") || temp.getKey(i).equalsIgnoreCase("testdate")))  continue; 
				  	if(temp.getKey(i).equalsIgnoreCase("serno") || temp.getKey(i).equalsIgnoreCase("pat_id")) continue;
				  	newdata.add(new data(temp.getKey(i),temp.getValue(i)));
				  }
				  tag=1;
			}
 	    }	
		
    }
    
    return newdata;
}
		
	public Object getChildAndOtherFrm(String id,String ftype,String slno) throws RemoteException,SQLException{
		Object res=new Object();
		Vector Vtmp=new Vector();
		String child="";
		//System.out.println(" Ex getChildAndOtherFrm : ");
		String qSql="select child from parchl where Upper(parent)='"+ftype.toUpperCase()+"'";
		child = mydb.ExecuteSingle(qSql);
		
    	//System.out.println("child : "+child);
    	
    	qSql="select date,serno from listofforms where pat_id ='"+id+"' and Upper(type) ='"+ftype.toUpperCase()+"'";
    	res = mydb.ExecuteQuary(qSql);
    	
    	Vtmp.add(0,child); // add the String
		Vtmp.add(1,res); // add the vector
		return Vtmp;
    }
    
    public Vector getImgdetailsOtherimgMarkimg(String mtype,String id,String type,String dt,String isl,String msl,String rcode) throws RemoteException,SQLException{
    	Vector Vtmp=new Vector();
    	String qSql="";   	
    	
    	qSql="select ref_code,entrydate,serno from refimages where upper(pat_id) = '"+id.toUpperCase()+"' AND upper(type)='"+type.toUpperCase()+"' AND img_serno="+isl+ " Order By serno";
    	Vtmp.add(mydb.ExecuteQuary(qSql));   

    	qSql="select entrydate ,serno from patimages where upper(pat_id) = '"+id.toUpperCase()+"' AND upper(type)='"+type.toUpperCase()+"' Order By serno";
    	Vtmp.add(mydb.ExecuteQuary(qSql));   
		
		if(mtype.equalsIgnoreCase("nomark")){
    		qSql = "Select imgdesc,lab_name,doc_name,testdate,entrydate,con_type,ext from patimages Where "+ 
    		"upper(pat_id) = '"+id.toUpperCase()+"' AND serno="+isl+" AND upper(type)='"+type.toUpperCase()+"' AND entrydate='"+dt+"'"; 
    		Vtmp.add(mydb.ExecuteQuary(qSql));
    		 
    	}else if(mtype.equalsIgnoreCase("mark")){
    		qSql = "Select ref_code,imgdesc,lab_name,doc_name,testdate,entrydate,con_type,ext from refimages Where "+ 
    		"upper(pat_id) = '"+id.toUpperCase()+"' AND serno="+msl+
    		" AND upper(type)='"+type.toUpperCase()+"' AND entrydate='"+dt+"' AND ref_code='"+rcode+"' AND img_serno="+isl; 
    		Vtmp.add(mydb.ExecuteQuary(qSql));    	
    	}
    	    	      	  
    	return Vtmp;
    }  
	
	    
    public Object showLists(String paid)throws RemoteException,SQLException{
	    Vector Vtmp=new Vector();
	    String qSql="";
	    
	    qSql="select count(type) As total,type,date from listofforms,forms Where Upper(pat_id) = '"+paid.toUpperCase()+"' and par_chl <> 'C' and forms.name = listofforms.type group by type,date order by type";
	    Vtmp.add(mydb.ExecuteQuary(qSql));
	    qSql= "select count(type) as total,type,entrydate from patimages Where Upper(pat_id) = '"+paid.toUpperCase()+"' and (formkey = -1 OR formkey is NULL) group  by type, entrydate order by type";
	   	Vtmp.add(mydb.ExecuteQuary(qSql));
	    qSql= "select count(type) as total, type,entrydate from patdoc Where Upper(pat_id) = '"+paid.toUpperCase()+"' group by type, entrydate order by type";
	    Vtmp.add(mydb.ExecuteQuary(qSql));
	    qSql= "select count(type) as total,type,entrydate from patmovies Where Upper(pat_id) = '"+paid.toUpperCase()+"' and  (formkey <> -1 OR formkey is NULL) group  by type, entrydate order by type";
	    Vtmp.add(mydb.ExecuteQuary(qSql));
	    return  Vtmp; 
    }
    
    public Object showAllLists(String paid)throws RemoteException,SQLException{
	    Vector Vtmp=new Vector();
	    String qSql="";
		qSql=  "select count(type) As total,type,Max(date) as date ,description,Max(serno) as serno ,forms.par_chl from listofforms,forms Where Upper(pat_id) = '"+paid.toUpperCase()+"' and par_chl <> 'C' and forms.name = listofforms.type group by type,description,DATE(date) order by date desc,type asc";
		System.out.println("qSql 1:"+qSql);
		Vtmp.add(mydb.ExecuteQuary(qSql));
	    qSql= "select count(type) as total,type,Max(entrydate) as entrydate,Max(serno)as serno from patimages Where Upper(pat_id) = '"+paid.toUpperCase()+"' and (formkey = -1 OR formkey is NULL) group  by type, DATE(entrydate) order by entrydate desc,type asc";
		System.out.println("qSql 2:"+qSql);   
		Vtmp.add(mydb.ExecuteQuary(qSql));
	    qSql= "select count(type) as total, type,Max(entrydate)as entrydate,Max(serno)as serno from patdoc Where Upper(pat_id) = '"+paid.toUpperCase()+"' group by type, DATE(entrydate) order by entrydate desc,type asc";
		System.out.println("qSql 3:"+qSql);
		Vtmp.add(mydb.ExecuteQuary(qSql));
	    qSql= "select count(type) as total,type,Max(entrydate)as entrydate,Max(serno)as serno from patmovies Where Upper(pat_id) = '"+paid.toUpperCase()+"' and (formkey <> -1 OR formkey is NULL) group  by type, DATE(entrydate) order by entrydate desc,type asc";
		System.out.println("qSql 4:"+qSql);
		Vtmp.add(mydb.ExecuteQuary(qSql));
		System.out.println("OUTPUT:"+Vtmp.toString());
	    return  Vtmp; 
    }
      
    public Object viewSummary(String paid)throws RemoteException,SQLException{
	    Vector Vtmp=new Vector();
	    String qSql="";
	    String ccode=paid.substring(0,4).toUpperCase();	    
	    	    
	    qSql= "Select name,phone from center where upper(code) ='"+ccode+"'";
	    //System.out.println("ccode >> "+qSql);
	    
	    Vtmp.add(mydb.ExecuteQuary(qSql));
	    
	    qSql="Select * from med where upper(pat_id) = '"+paid.toUpperCase()+"' ";
	    Vtmp.add(mydb.ExecuteQuary(qSql)); 
		
		qSql="Select * from lpatq where upper(pat_id) = '"+paid.toUpperCase()+"' ";
	    Vtmp.add(mydb.ExecuteQuary(qSql)); 
	    
	    qSql = "Select Count(pat_id) as total from listofforms, forms Where Upper(pat_id) = '"+paid.toUpperCase()+"' And upper(type) <> 'PRE' And upper(type) <> 'PRS' and forms.par_chl <>'C' and listofforms.type = forms.name ";
		Vtmp.add(mydb.ExecuteQuary(qSql)); 
		
		qSql = "Select Count(pat_id) as total from listofforms Where Upper(pat_id) = '"+paid.toUpperCase()+"' And (upper(type)= 'PRE' or upper(type) = 'PRS')";
		Vtmp.add(mydb.ExecuteQuary(qSql)); 
				
		qSql = "Select Count(pat_id) as total from patimages Where Upper(pat_id) = '"+paid.toUpperCase()+"'";
		Vtmp.add(mydb.ExecuteQuary(qSql));
		
		qSql = "Select Count(pat_id) as total from refimages Where Upper(pat_id) = '"+paid.toUpperCase()+"'";
		Vtmp.add(mydb.ExecuteQuary(qSql));
		
		qSql = "Select Count(pat_id) as total from patdoc Where Upper(pat_id) = '"+paid.toUpperCase()+"'";
		Vtmp.add(mydb.ExecuteQuary(qSql)); 
		
		qSql = "Select Count(pat_id) as total from patmovies Where Upper(pat_id) = '"+paid.toUpperCase()+"'";
		Vtmp.add(mydb.ExecuteQuary(qSql));
	    return  Vtmp;
	    
    }
    public Object viewSummary(String paid,String ccode)throws RemoteException,SQLException{
	    Vector Vtmp=new Vector();
	    String qSql="";
	   // String ccode=paid.substring(0,4).toUpperCase();	    
	    	    
	    qSql= "Select name,phone from center where upper(code) ='"+ccode+"'";
	    //System.out.println("ccode >> "+qSql);
	    
	    Vtmp.add(mydb.ExecuteQuary(qSql));
	    
	    qSql="Select * from med where upper(pat_id) = '"+paid.toUpperCase()+"' ";
	    Vtmp.add(mydb.ExecuteQuary(qSql)); 
		
		qSql="Select * from lpatq where upper(pat_id) = '"+paid.toUpperCase()+"' ";
	    Vtmp.add(mydb.ExecuteQuary(qSql)); 
	    
	    qSql = "Select Count(pat_id) as total from listofforms, forms Where Upper(pat_id) = '"+paid.toUpperCase()+"' And upper(type) <> 'PRE' And upper(type) <> 'PRS' and forms.par_chl <>'C' and listofforms.type = forms.name ";
		Vtmp.add(mydb.ExecuteQuary(qSql)); 
		
		qSql = "Select Count(pat_id) as total from listofforms Where Upper(pat_id) = '"+paid.toUpperCase()+"' And (upper(type)= 'PRE' or upper(type) = 'PRS')";
		Vtmp.add(mydb.ExecuteQuary(qSql)); 
				
		qSql = "Select Count(pat_id) as total from patimages Where Upper(pat_id) = '"+paid.toUpperCase()+"'";
		Vtmp.add(mydb.ExecuteQuary(qSql));
		
		qSql = "Select Count(pat_id) as total from refimages Where Upper(pat_id) = '"+paid.toUpperCase()+"'";
		Vtmp.add(mydb.ExecuteQuary(qSql));
		
		qSql = "Select Count(pat_id) as total from patdoc Where Upper(pat_id) = '"+paid.toUpperCase()+"'";
		Vtmp.add(mydb.ExecuteQuary(qSql)); 
		
		qSql = "Select Count(pat_id) as total from patmovies Where Upper(pat_id) = '"+paid.toUpperCase()+"'";
		Vtmp.add(mydb.ExecuteQuary(qSql));
	    return  Vtmp;
	    
    }    
        
    public byte[] getImage(String paid,String edate,String type,String slno)throws RemoteException,SQLException {        
      
      
       String qSql= "select patpic from patimages where pat_id= '"+paid
       +"' and serno= '"+slno+"' and type='"+type+"' AND entrydate='"+edate+"'"; //Order By type, serno " ;
       System.out.println("/nImage :" + qSql); 
                 
        //dball mydb= new dball(pinfo);
       return mydb.ExecuteImage(qSql);
     }
     public byte[] getBackupImage(String paid,String edate,String type,String slno)throws RemoteException,SQLException {        
      
      
       String qSql= "select patpic from patimages_bak where pat_id= '"+paid
       +"' and serno= '"+slno+"' and type='"+type+"' AND entrydate='"+edate+"'"; //Order By type, serno " ;
       System.out.println("/nBackup Image :" + qSql); 
                 
        //dball mydb= new dball(pinfo);
       return mydb.ExecuteImage(qSql);
     }
     
     public String getImageCon_type(String paid,String edate,String type,String slno)throws RemoteException,SQLException {
     	
        
        String qSql= "select con_type from patimages where upper(pat_id)= '"+paid.toUpperCase()
        +"' and serno= '"+slno+"' and upper(type)='"+type.toUpperCase()+"' AND entrydate='"+edate+"'"; //"' Order By type, serno" ;
        //System.out.println("con_type :" + qSql);         
        //dball mydb= new dball(pinfo);
        return mydb.ExecuteSingle(qSql);    
     }
     
     public byte[] getRImage(String paid,String edate,String type,String slno,String islno,String rcode)throws RemoteException,SQLException {
        
         String qSql= "select patpic from refimages Where "+ 
    		"upper(pat_id) = '"+paid.toUpperCase()+"' AND serno="+slno+
    		" AND upper(type)='"+type.toUpperCase()+"' AND entrydate='"+edate+
    		"' AND ref_code='"+rcode+"' AND img_serno="+islno;
         
        // System.out.println("RImage :" + qSql);   
         
         return mydb.ExecuteImage(qSql);
        	
        }
        
     public String getRImageCon_type(String paid,String edate,String type,String slno,String islno,String rcode)throws RemoteException,SQLException {       
        String qSql= "select con_type from refimages Where "+ 
    		"upper(pat_id) = '"+paid.toUpperCase()+"' AND serno="+slno+
    		" AND upper(type)='"+type.toUpperCase()+"' AND entrydate='"+edate+
    		"' AND ref_code='"+rcode+"' AND img_serno="+islno;
    		
       // System.out.println("Rcon_type :" + qSql);    
        //dball mydb= new dball(pinfo);
        return mydb.ExecuteSingle(qSql);   	
     }
     
     public byte[] getDocument(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException {
        
         String qSql= "select patdoc from patdoc where upper(pat_id)= '"+paid.toUpperCase()
        +"' and serno= '"+slno+"' and upper(type)='"+type.toUpperCase()+"' AND entrydate='"+edate+"'"; //Order By type, serno " ;
       //System.out.println("Image :" + qSql); 
                 
        //dball mydb= new dball(pinfo);
        return mydb.ExecuteImage(qSql);
        }
      
     public Object getDocumentdetailsOthers(String paid,String edate,String type,String slno) throws RemoteException,SQLException{
     	Vector Vtmp=new Vector();
    	
    	String qSql="Select ext,docdesc,lab_name,doc_name,testdate,entrydate,con_type from patdoc where upper(pat_id)= '"+paid.toUpperCase()
        +"' and serno= '"+slno+"' and upper(type)='"+type.toUpperCase()+"' AND entrydate='"+edate+"'";
        Vtmp.add(mydb.ExecuteQuary(qSql));
        
        qSql="select entrydate ,serno from patdoc where upper(pat_id) = '"+paid.toUpperCase()+"' AND upper(type)='"+type.toUpperCase()+"' Order By serno";
    	Vtmp.add(mydb.ExecuteQuary(qSql));   
    	
    	return Vtmp;	
     }

        
     public String getDocumentExt(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException{
        	
        String qSql= "select ext from patdoc where upper(pat_id)= '"+paid.toUpperCase()
        +"' and serno= '"+slno+"' and upper(type)='"+type.toUpperCase()+"' AND entrydate='"+edate+"'"; //"' Order By type, serno" ;
        //System.out.println("con_type :" + qSql);         
        //dball mydb= new dball(pinfo);
        return mydb.ExecuteSingle(qSql);
        
        }
        
     public byte[] getMovie(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException{
        String qSql= "select patmov from patmovies where upper(pat_id)= '"+paid.toUpperCase()
        +"' and serno= '"+slno+"' and upper(type)='"+type.toUpperCase()+"' AND entrydate='"+edate+"'"; //Order By type, serno " ;
       //System.out.println("Image :" + qSql); 
                 
        //dball mydb= new dball(pinfo);
        return mydb.ExecuteImage(qSql);
        
        }
        
     public Object getMoviedetailsOthers(String paid,String edate,String type,String slno) throws RemoteException,SQLException{
     	Vector Vtmp=new Vector();
    	  	
    	String qSql="Select ext,movdesc,lab_name,doc_name,testdate,entrydate,con_type from patmovies where upper(pat_id)= '"+paid.toUpperCase()
        +"' and serno= '"+slno+"' and upper(type)='"+type.toUpperCase()+"' AND entrydate='"+edate+"'";
        Vtmp.add(mydb.ExecuteQuary(qSql));
        
        qSql="select entrydate ,serno from patmovies where upper(pat_id) = '"+paid.toUpperCase()+"' AND upper(type)='"+type.toUpperCase()+"' Order By serno";
    	Vtmp.add(mydb.ExecuteQuary(qSql));
    	
    	return Vtmp;
     }

     public String getMovieExt(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException{
        String qSql= "select ext from patmovies where upper(pat_id)= '"+paid.toUpperCase()
        +"' and serno= '"+slno+"' and upper(type)='"+type.toUpperCase()+"' AND entrydate='"+edate+"'"; //"' Order By type, serno" ;
        //System.out.println("con_type :" + qSql);         
        //dball mydb= new dball(pinfo);
        return mydb.ExecuteSingle(qSql);
        }
     
     public String getMovieCon_type(String paid,String edate,String type,String slno)throws RemoteException,
        SQLException {
        	
        String qSql= "select con_type from patmovies where upper(pat_id)= '"+paid.toUpperCase()
        +"' and serno= '"+slno+"' and upper(type)='"+type.toUpperCase()+"' AND entrydate='"+edate+"'"; //"' Order By type, serno" ;
       // System.out.println("con_type :" + qSql);         
        //dball mydb= new dball(pinfo);
        return mydb.ExecuteSingle(qSql);
        }
     
     public Object getDataTeleRequest(String ccode,String pid)throws RemoteException,SQLException {
     	Vector Vtmp=new Vector();
    	String qSql="Select assigneddoc from lpatq where upper(pat_id) = '"+pid.toUpperCase()+"'";
    	Vtmp.add(mydb.ExecuteSingle(qSql));
    	qSql="select name,code from center order by code";
        Vtmp.add(mydb.ExecuteQuary(qSql));
        qSql="Select name,rg_no from login where upper(type) = 'DOC' and upper(active) ='Y' and referral= 'Y' and upper(center) ='"+ccode.toUpperCase()+"'";
    	Vtmp.add(mydb.ExecuteQuary(qSql));
    	System.out.println("getDataTeleRequest() : "+qSql);
    	return Vtmp;
    	
     }
     
     public Object getComplaintSummary(String id, int no ) throws RemoteException,SQLException{
     	 String qSql = "SELECT comp1, dur1, hdmy1, comp2, dur2, hdmy2, comp3, dur3, hdmy3, entrydate FROM a14 WHERE pat_id = '"+id+"' order by entrydate desc " + (no > 0 ? " LIMIT " + no : "") ;
         return mydb.ExecuteQuary(qSql);
     }
    
       
    
     
     public String getVisitSummaryGEN(String id, String year, int no) throws RemoteException,SQLException{
     
      String outputstr = "", nowcolor = "", tempstr = "", diagnosis = "";
	    int prevyear = 0, sl = 1, count = 1; 
        String qSql=""; 
            

            if (no > 0)
                qSql = "select entrydate, stage, diagnosis1, diagnosis2, diagnosis3 from d03 where pat_id = '"+id+"' order by entrydate desc, serno desc LIMIT " + no ;
            else
	               qSql = "select entrydate, stage, diagnosis1, diagnosis2, diagnosis3 from d03 where pat_id = '"+id+"' AND YEAR(entrydate) = '" + year + "' order by entrydate desc, serno desc";
    
            outputstr += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
            outputstr += "<tr style='background-color:#D7FFD7'><th>Date</th><th>Diagnosis</th><th>Stage</th></tr>"; //<th>SL.</th>
			Object res= mydb.ExecuteQuary(qSql);
			Vector tmpv = (Vector)res;
			if(tmpv.size()>0){
			
				for(int j=0;j<tmpv.size();j++){
					dataobj tmpdata = (dataobj) tmpv.get(j);
					
					String pdt = tmpdata.getValue(0);
					String dt = pdt.substring(8,10)+"/"+pdt.substring(5,7)+"/"+pdt.substring(0,4);
					
					int iyear= Integer.parseInt(pdt.substring(0,4));
					if(iyear!=prevyear){
							if (nowcolor.equalsIgnoreCase("#FEFEF2")) nowcolor = "#FCF6CF";
	                        else nowcolor = "#FEFEF2";
	                        sl = 1;
					}
					count = 1;
	                diagnosis = "";
	                String stage=tmpdata.getValue(1);
	                String d1=tmpdata.getValue(2);
	                String d2=tmpdata.getValue(3);
	                String d3=tmpdata.getValue(4);
	                
	                if (!d1.equalsIgnoreCase(""))
	                {
	                    diagnosis += "<br>" + count + ". " +d1 ;
	                    count++;
	                }
	                if (!d2.equalsIgnoreCase(""))
	                {
	                    diagnosis += "<br>" + count + ". " + d2;
	                    count++;
	                }
	                if (!d3.equalsIgnoreCase(""))
	                {
	                    diagnosis += "<br>" + count + ". " + d3;
	                    count++;
	                }
	                if (diagnosis.startsWith("<br>")) diagnosis = diagnosis.substring(4);
	                
	                outputstr += "<tr style='background-color:" + nowcolor + ";border:1px solid #880088'>";
                    //                outputstr += "<td>" + sl + "</td>";

                    tempstr = (no == 0 ? "<a style='text-decoration:none' href=\"javascript:ExecuteCallContent('visitsummary.jsp', 'get', 'data=obsrv&date=" + dt + "', '', 'contentD')\">" + dt + "</a>" : dt);
                    outputstr += "<td align='center' nowrap>" + tempstr + "</td>";

                    tempstr = (no == 0 ? "<a style='text-decoration:none' href=\"javascript:ExecuteCallContent('visitsummary.jsp', 'get', 'data=prscp&date=" + dt + "', '', 'contentD')\">" + diagnosis + "</a>" : diagnosis);
                    outputstr += "<td align='left'>" + tempstr + "</td>";

                    tempstr = (no == 0 ? "<a style='text-decoration:none' href=\"javascript:ExecuteCallContent('visitsummary.jsp', 'get', 'data=rcord&date=" + dt + "', '', 'contentD')\">" + stage + "</a>" : stage);
                    outputstr += "<td align='left' nowrap>" + tempstr + "</td>";

                    outputstr += "</tr>";

                    prevyear = iyear;
                    sl++;
                    
                
			
				} // end for
			}else{
				outputstr += "<tr style='background-color:#FFFFFF'><td align='center' colspan='3'>No Visit Encountered</td></tr>";
			}
						
 			outputstr += "</table>";
 		    
	     return outputstr;
	     	
     }
     	
     public String getVisitSummaryPHIV(String id, String year, int no) throws RemoteException,SQLException{
	     
	    String outputstr = "", nowcolor = "", tempstr = "", diagnosis = "";
	    int prevyear = 0, sl = 1, count = 1; 
        String qSql=""; 
            

            if (no > 0)
                qSql = "select entrydate, stage, diagnosis1, diagnosis2, diagnosis3 from d03 where pat_id = '"+id+"' order by entrydate desc, serno desc LIMIT " + no ;
            else
	            qSql = "select entrydate, stage, diagnosis1, diagnosis2, diagnosis3 from d03 where pat_id = '"+id+"' AND YEAR(entrydate) = '" + year + "' order by entrydate desc, serno desc";
    
            outputstr += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
            outputstr += "<tr style='background-color:#D7FFD7'><th>Date</th><th>Diagnosis</th><th>Stage</th></tr>"; //<th>SL.</th>
			Object res= mydb.ExecuteQuary(qSql);
			Vector tmpv = (Vector)res;
			if(tmpv.size()>0){
			
				for(int j=0;j<tmpv.size();j++){
					dataobj tmpdata = (dataobj) tmpv.get(j);
					
					String pdt = tmpdata.getValue(0);
					String dt = pdt.substring(8,10)+"/"+pdt.substring(5,7)+"/"+pdt.substring(0,4);
					
					int iyear= Integer.parseInt(pdt.substring(0,4));
					if(iyear!=prevyear){
							if (nowcolor.equalsIgnoreCase("#FEFEF2")) nowcolor = "#FCF6CF";
	                        else nowcolor = "#FEFEF2";
	                        sl = 1;
					}
					count = 1;
	                diagnosis = "";
	                String stage=tmpdata.getValue(1);
	                String d1=tmpdata.getValue(2);
	                String d2=tmpdata.getValue(3);
	                String d3=tmpdata.getValue(4);
	                
	                if (!d1.equalsIgnoreCase(""))
	                {
	                    diagnosis += "<br>" + count + ". " +d1 ;
	                    count++;
	                }
	                if (!d2.equalsIgnoreCase(""))
	                {
	                    diagnosis += "<br>" + count + ". " + d2;
	                    count++;
	                }
	                if (!d3.equalsIgnoreCase(""))
	                {
	                    diagnosis += "<br>" + count + ". " + d3;
	                    count++;
	                }
	                if (diagnosis.startsWith("<br>")) diagnosis = diagnosis.substring(4);
	                
	                outputstr += "<tr style='background-color:" + nowcolor + ";border:1px solid #880088'>";
                    //                outputstr += "<td>" + sl + "</td>";

                    tempstr = (no == 0 ? "<a style='text-decoration:none' href=\"javascript:ExecuteCallContent('visitsummary.jsp', 'get', 'data=obsrv&date=" + dt + "', '', 'contentD')\">" + dt + "</a>" : dt);
                    outputstr += "<td align='center' nowrap>" + tempstr + "</td>";

                    tempstr = (no == 0 ? "<a style='text-decoration:none' href=\"javascript:ExecuteCallContent('visitsummary.jsp', 'get', 'data=prscp&date=" + dt + "', '', 'contentD')\">" + diagnosis + "</a>" : diagnosis);
                    outputstr += "<td align='left'>" + tempstr + "</td>";

                    tempstr = (no == 0 ? "<a style='text-decoration:none' href=\"javascript:ExecuteCallContent('visitsummary.jsp', 'get', 'data=rcord&date=" + dt + "', '', 'contentD')\">" + stage + "</a>" : stage);
                    outputstr += "<td align='left' nowrap>" + tempstr + "</td>";

                    outputstr += "</tr>";

                    prevyear = iyear;
                    sl++;
                    
                
			
				} // end for
			}else{
				outputstr += "<tr style='background-color:#FFFFFF'><td align='center' colspan='3'>No Visit Encountered</td></tr>";
			}
						
 			outputstr += "</table>";
 		    
	     return outputstr;
     }
     
     public Object getYearVisitSummary(String id) throws RemoteException,SQLException {
     	String qSql="SELECT DISTINCT YEAR(visitdate), Count(*) FROM patientvisit WHERE pat_id = '"+id+"' GROUP BY YEAR(visitdate) ORDER BY YEAR(visitdate) desc";
     	return mydb.ExecuteQuary(qSql);
     }
     
     public String getObservation(String id, String date) throws RemoteException,SQLException {
     	String outputstr="";
     	
     	//String dt = date.substring(6)+"-"+date.substring(3,5)+"-"+date.substring(0,2);
		
     	String qSql="SELECT what, finding, category FROM a15 WHERE PAT_ID = '"+id+"' AND date(entrydate) ='"+date+"' ORDER BY entrydate DESC";
     	
     	//System.out.println("getObservation : "+qSql);
     	
     	outputstr += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
        outputstr += "<tr style='background-color:#D7FFD7'><th>Description</th><th>Observation</th><th>Category</th></tr>";
		Object res= mydb.ExecuteQuary(qSql);
		Vector tmpv = (Vector)res;
		for(int j=0;j<tmpv.size();j++){
			dataobj tmpdata = (dataobj) tmpv.get(j);
				outputstr += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                outputstr += "<td align='left'>" + tmpdata.getValue(0) + "</td>";
                outputstr += "<td align='left'>" + tmpdata.getValue(1) + "</td>";
                outputstr += "<td align='left'>" + tmpdata.getValue(2) + "</td>";
                outputstr += "</tr>";
		}
 		outputstr += "</table>";
     	return outputstr;
     }
     
     
     
     
     
    public String getPrescription(String id, String date,String slno) throws RemoteException,SQLException {
    	String outputstr="", qSql="";
    	String cond="";
    	if (!date.equalsIgnoreCase("")){
    		cond=" AND date(t.entrydate) = '"+date+"'";
    	}
    	if (!slno.equalsIgnoreCase("")){
    		cond=" AND t.serno = "+slno;	
    	}
    	//if (date.equalsIgnoreCase(""))                
        //  qSql = "SELECT d.drug, f.prep, a.formuladose, f.unit, t.dose, t.pill_desp, t.pill_consumed, t.entrydate FROM a02 t, arvpackage a, drugindex d, formulation f WHERE t.pat_id = '"+id+"' AND t.drug_id = d.id_drugindex AND t.arvpackage_id = a.id_arvpackage AND f.id_formulation =a.formula";
        //else
        
            qSql = "SELECT d.drug, f.prep, a.formuladose, f.unit, t.dose, t.pill_desp, t.pill_consumed, t.entrydate FROM a02 t, arvpackage a, drugindex d, formulation f WHERE t.pat_id = '"+id+"'"+cond+" AND t.drug_id = d.id_drugindex AND t.arvpackage_id = a.id_arvpackage AND f.id_formulation =a.formula";   
         
         
            //System.out.println("getPrescription :"+qSql);
            
            outputstr += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
            outputstr += "<tr style='background-color:#D7FFD7'><th>Drug</th><th>Formula</th><th>Dose</th><th>Adherence</th><th>Date</th></tr>";
			Object res= mydb.ExecuteQuary(qSql);
			Vector tmpv = (Vector)res;
			for(int j=0;j<tmpv.size();j++){
				dataobj tmpdata = (dataobj) tmpv.get(j);
				String pdt = tmpdata.getValue(7);
				String dt = pdt.substring(8,10)+"/"+pdt.substring(5,7)+"/"+pdt.substring(0,4);
				double pd = Double.parseDouble(tmpdata.getValue(5));
				double pc = Double.parseDouble(tmpdata.getValue(6));
					outputstr += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
	                outputstr += "<td align='left'>" + tmpdata.getValue(0) + "</td>";
	                outputstr += "<td align='left'>" + tmpdata.getValue(1) + " " + tmpdata.getValue(2) + tmpdata.getValue(3) + "</td>";
	                outputstr += "<td align='left'>" + tmpdata.getValue(4) + "</td>";
	                outputstr += "<td align='center'>" + Math.round(100 * pc / pd) + "%</td>";
	                outputstr += "<td align='center'>" + dt + "</td>";
	                outputstr += "</tr>";
			}
	 		outputstr += "</table>";
	     	return outputstr;    
    }
   
    public String getAntiretroviralPrescription(String id,String edate,String slno) throws RemoteException,SQLException{
    	String outputstr = "";
		String qSql="";
		
			if(edate.equalsIgnoreCase("") ||slno.equalsIgnoreCase("") ){
				
				qSql= "select distinct row_id,drug_name,formulation_am,formulation_pm,dose_am,dose_pm,entrydate,pill_disp,balance,pill_consumed," +
                "ROUND(CAST(pill_consumed as DECIMAL)/pill_disp*100, 2) " +
                "from  k02 pc,drug_grp dg " +
                "where pat_id='"+id+"' and balance>0 and pc.drug_id=dg.drug_id " +
                "Union select distinct row_id,drug_name,formulation_am,formulation_pm,dose_am,dose_pm,entrydate,pill_disp,balance,pill_consumed, 0 " +
                "from  k02 pc,drug_grp dg " +
                "where pat_id='"+id+"' and pill_disp=0 and pc.drug_id=dg.drug_id";
                
                
			}else{
				qSql= "select distinct row_id,drug_name,formulation_am,formulation_pm,dose_am,dose_pm,entrydate,pill_disp,balance,pill_consumed," +
                    "ROUND(CAST(pill_consumed as DECIMAL)/pill_disp*100, 2) " +
                    "from  k02 pc,drug_grp dg " +
                    "where pat_id='"+id+"' and entrydate = '"+edate+"' and serno = "+slno+" and pc.drug_id=dg.drug_id ";
			}
			
			System.out.println("\n\n"+ qSql+"\n\n");
        
            
            outputstr += "<table width='100%' border='1' align='center' cellspacing='1' cellpadding='2' style='border:1px solid #00AA00'>"; 
            if(edate.equalsIgnoreCase("") ||slno.equalsIgnoreCase("") )
            	outputstr += "<tr style='background-color:#D7FFD7'><th>Drug</th><th>Formula</th><th>Dose(AM)</th><th>Dose(PM)</th><th>A.R.</th><th>Date</th></tr>";
           	else
           		outputstr += "<tr style='background-color:#D7FFD7'><th>Drug</th><th>Formula</th><th>Dose(AM)</th><th>Dose(PM)</th><th>Dispense</th><th>Date</th></tr>";
           	
            String formula="";
            
            Object res= mydb.ExecuteQuary(qSql);
			Vector tmpv = (Vector)res;
			if(tmpv.size()>0){
				for(int j=0;j<tmpv.size();j++){
				dataobj tmpdata = (dataobj) tmpv.get(j);
				
				outputstr += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
	            outputstr += "<td align='left'>" + tmpdata.getValue(1)+ "</td>";
	        	        
	        	        if (tmpdata.getValue(2) != "" || tmpdata.getValue(2) != null)
	                        formula = tmpdata.getValue(2);
	                    else
	                        formula = tmpdata.getValue(3);
	                        
	                    outputstr += "<td align='left'>&nbsp;" + formula + "</td>";
	                    //outputstr += "<td align='left'>" + newReader.GetValue(1).ToString() + " " + newReader.GetValue(2).ToString() + newReader.GetValue(3).ToString() + "</td>";
	
	                    outputstr += "<td align='center'>&nbsp;" + tmpdata.getValue(4)+ "</td>";
	                    outputstr += "<td align='center'>&nbsp;" + tmpdata.getValue(5) + "</td>";
	                    
	                    if(edate.equalsIgnoreCase("") ||slno.equalsIgnoreCase(""))
	                     	outputstr += "<td align='center'>&nbsp;" + tmpdata.getValue(10) + "</td>";
	                    else 
                        	outputstr += "<td align='center'>&nbsp;" + tmpdata.getValue(7) + "</td>";
	                   
	                    
	                    outputstr += "<td align='center'>" + myDate.mysql2ind(tmpdata.getValue(6)) + "</td>";
	                    outputstr += "</tr>";
	           }
           }else
            {
                outputstr += "<tr style='background-color:#FFFFFF'><td align='center' colspan='5'>No Anti-Retroviral drug is prescribed</td></tr>";
            }
            outputstr += "</table>";
            return outputstr;
    }
    
     public String getCTXSummary(String id, int no,String edate,String slno)throws RemoteException,SQLException{
     	  
     	   String outputstr = "";
     	   String qSql="";
            try
            {
          	 if(edate.equalsIgnoreCase("") ||slno.equalsIgnoreCase("") ){
          	 	 qSql = "SELECT  d.formulation , t.dose , t.entrydate, Round(cast(t.pill_consumed as DECIMAL)/t.pill_disp*100, 2),t.pill_disp FROM k01 t, ctx_dose d WHERE t.pat_id ='"+id+"' AND t.formulation_id  = d.id  ORDER BY entrydate DESC " + (no > 0 ? " LIMIT " + no : "") ;
          	 }else{
          	 	qSql = "SELECT  d.formulation , t.dose , t.entrydate, Round(cast(t.pill_consumed as DECIMAL)/t.pill_disp*100, 2),t.pill_disp FROM k01 t, ctx_dose d WHERE t.pat_id ='"+id+"' AND t.entrydate = '"+edate+"' AND t.serno = "+slno + " AND t.formulation_id  = d.id  ORDER BY entrydate DESC ";
          	 }
             
             System.out.println("\n\n"+ qSql+"\n\n");
             outputstr += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
			if(edate.equalsIgnoreCase("") ||slno.equalsIgnoreCase("") )
            	outputstr += "<tr style='background-color:#D7FFD7'><th>Formula</th><th>Dose</th><th>A.R.</th><th>Date</th></tr>";
           	else
           		outputstr += "<tr style='background-color:#D7FFD7'><th>Formula</th><th>Dose</th><th>Dispense</th><th>Date</th></tr>";
           	
			Object res= mydb.ExecuteQuary(qSql);
			Vector tmpv = (Vector)res;
			if(tmpv.size()>0){
				for(int j=0;j<tmpv.size();j++){
					dataobj tmpdata = (dataobj) tmpv.get(j);
			     	outputstr += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
	             	outputstr += "<td align='left'>" + tmpdata.getValue(0) + "</td>";
	                outputstr += "<td align='left'>" + tmpdata.getValue(1) + "</td>";
	                if(edate.equalsIgnoreCase("") ||slno.equalsIgnoreCase("") )
	                	outputstr += "<td align='center'>" + tmpdata.getValue(3) + "</td>";
	                else  	
	                	outputstr += "<td align='center'>" + tmpdata.getValue(4) + "</td>";
	                outputstr += "<td align='center'>" + myDate.mysql2ind(tmpdata.getValue(2)) + "</td>";
	                outputstr += "</tr>";
				}
			}else
            {
                outputstr += "<tr style='background-color:#FFFFFF'><td align='center' colspan='5'>No Cotrimoxazole Prophylaxis drug is prescribed</td></tr>";
            }
            outputstr += "</table>";
           
            }catch (Exception err)
            {
                outputstr=err.toString();
            }
     	 return outputstr;
     	 
   }

	public String getAntiTuberculosisSummary(String id, int no,String edate,String slno)throws RemoteException,SQLException{
	 String outputstr = "";
	 String qSql="";
	 
            try
            {
            if(edate.equalsIgnoreCase("") ||slno.equalsIgnoreCase("") ){
        	 	qSql = "SELECT   d.drug_name, t.formulation, t.dose, t.entrydate, Round(cast(t.pill_consumed as DECIMAL)/t.pill_disp*100, 2),t.pill_disp FROM k00 t, drugname_tb d WHERE t.pat_id = '"+id+"' AND t.drug_id = d.drug_id ORDER BY entrydate DESC" + (no > 0 ? " LIMIT " + no : "") ;	
            }else{
             	qSql = "SELECT   d.drug_name, t.formulation, t.dose, t.entrydate, Round(cast(t.pill_consumed as DECIMAL)/t.pill_disp*100, 2),t.pill_disp FROM k00 t, drugname_tb d WHERE t.pat_id = '"+id+"' AND t.entrydate = '"+edate+"' AND t.serno = "+slno + " AND t.drug_id = d.drug_id ORDER BY entrydate DESC";
            }
            
          	System.out.println("\n\n"+ qSql+"\n\n");
         	 
            outputstr += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
			if(edate.equalsIgnoreCase("") ||slno.equalsIgnoreCase("") )
            	outputstr += "<tr style='background-color:#D7FFD7'><th>Drug</th><th>Formula</th><th>Dose</th><th>A.R.</th><th>Date</th></tr>";
           	else
           		outputstr += "<tr style='background-color:#D7FFD7'><th>Drug</th><th>Formula</th><th>Dose</th><th>Dispense</th><th>Date</th></tr>";
           	
			Object res= mydb.ExecuteQuary(qSql);
			Vector tmpv = (Vector)res;
			if(tmpv.size()>0){
				for(int j=0;j<tmpv.size();j++){
					dataobj tmpdata = (dataobj) tmpv.get(j);
					outputstr += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                    outputstr += "<td align='left'>" + tmpdata.getValue(0) + "</td>";
                    outputstr += "<td align='left'>" + tmpdata.getValue(1) + "</td>";
                    outputstr += "<td align='center'>" + tmpdata.getValue(2)+ "</td>";
                     if(edate.equalsIgnoreCase("") ||slno.equalsIgnoreCase("") )
                    	outputstr += "<td align='center'>" + tmpdata.getValue(4) + "</td>";
                    else
                    	outputstr += "<td align='center'>" + tmpdata.getValue(5) + "</td>";
                    	
                    outputstr += "<td align='center'>" + myDate.mysql2ind(tmpdata.getValue(3)) + "</td>";
                    outputstr += "</tr>";
				}
			}else
            {
                outputstr += "<tr style='background-color:#FFFFFF'><td align='center' colspan='5'>No Anti-tuberculosis drug is prescribed</td></tr>";
            }
            outputstr += "</table>";
           
            }catch (Exception err)
            {
                outputstr=err.toString();
            }
     	 return outputstr;
 	
	}
   
    
    public String getRecord(String id, String date) throws RemoteException,SQLException{
    	
    	String outputstr = "";
    	try{
    	String qSql="SELECT DISTINCT f.name, RTRIM(f.description), s.field_names FROM forms f, listofforms l, form_summary s WHERE l.PAT_ID = '"+id+"' AND date(l.DATE) = '"+date+"' AND UPPER(RTRIM(l.TYPE)) = UPPER(s.form_name) AND UPPER(f.name) = UPPER(s.form_name)";
    	//System.out.println(qSql);
    	
    	Object res= mydb.ExecuteQuary(qSql);
    	ArrayList meta=new ArrayList();
    	
		Vector tmpv = (Vector)res;
			for(int j=0;j<tmpv.size();j++){
				dataobj tmpdata = (dataobj) tmpv.get(j);
				//System.out.println("ArrayList : "+j);
				
					String form_name = tmpdata.getValue(0);
                    String form_desc = tmpdata.getValue(1); 
                    String field_names = tmpdata.getValue(2);
				    meta.add(new String[] { form_name, form_desc, field_names });
				}
			
			//System.out.println("OK 1 : ");
					
				qSql = "Call sp_getrecord('"+id+"','"+date+"')";
				
				res= mydb.ExecuteProcQuary(qSql);
				
				//System.out.println("OK 2 : ");
				
				if(res instanceof String){
					System.out.println(res);
					//outputstr+=res;
				}else{
                	outputstr += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='font-size:13px;border:1px solid #00AA00'>";
                	outputstr += "<tr style='background-color:#D7FFD7'><th>Forms</th><th>Records</th></tr>";

					Vector mainv = (Vector)res;
					for(int i=0;i<mainv.size();i++){
					    
					   // System.out.println("OK 3 : ");
					    
					    String[] metadata = (String[])meta.get(i);
                        String form_name = metadata[0];
                        String form_desc = metadata[1];
                        String field_names = metadata[2];
                        String[] fields = field_names.split(",");
                        
                        tmpv = (Vector)mainv.get(i);
							
                        if(tmpv.size()>0){
                        	
                        outputstr += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        outputstr += "<td align='left' width='30%'>" + form_desc + " (" + form_name + ")" + "</td>";
                        outputstr += "<td width='70%' style='background-color:#FCFCD8'><table width='100%' border='0' cellspacing='2' cellpadding='0' style='font-size:13px;'>";
                        outputstr += "<tr style='background-color:#D7FFD7'>";
                        
                        for (int ii = 0; ii < fields.length; ii++)
                            outputstr += "<th>" + fields[ii].trim() + "</th>";
                        outputstr += "</tr>";
                        	
                        }
                        
                        for(int j=0;j<tmpv.size();j++){
							dataobj tmpdata = (dataobj) tmpv.get(j);
							outputstr += "<tr>";
							for(int k=0 ; k<tmpdata.getLength();k++)														
						       	outputstr += "<td align='center' >" +  tmpdata.getValue(k) + "</td>";
				       	outputstr += "</tr>";
                        }
                        outputstr += "</table></td>";
                    	outputstr += "</tr>";
                        
						
					} // i 
					
				} // else
				
    		
    	}catch(Exception e){
    		System.out.println("getRecord : "+e.toString());
    	}
    	
    return outputstr ;
    
    }
    
    public dataobj getVisitDates(String id,String year) throws RemoteException,SQLException{
    	
    	String qSql="";
    	dataobj allData = new dataobj();
    	try{
    	
        if (year == null || year == "")
            qSql = "select visitdate from patientvisit where pat_id='"+id+"' order by visitdate desc";
        else
            qSql = "select visitdate from patientpisit where pat_id='"+id+"' and YEAR(visitdate) = '" + year + "' order by visitdate desc";
            
        Object res= mydb.ExecuteQuary(qSql);
		Vector tmpv = (Vector)res;
			for(int j=0;j<tmpv.size();j++){
				dataobj tmpdata = (dataobj) tmpv.get(j);
				String tmpdate = tmpdata.getValue(0);
				String dt[]=tmpdate.split(" ");
				String dat[]=dt[0].split("-");
				Date newdt = new Date(Integer.parseInt(dat[0]),Integer.parseInt(dat[1]),Integer.parseInt(dat[2]));
				
				String dm=myDate.dateFormat("dd MMMM",newdt);
				allData.add(dat[0],dm);
				}
			}catch(Exception e){
				System.out.println(e.toString());
			}
			
           return  allData;
    	
    }
    
    public String getGenPrescriptionforMedication(String id,String date,String slno) throws RemoteException,SQLException{
    	String outputstr="";
        String drugstr="", quantitystr="", dosestr="", durationstr="", dtstr = "",cond="";
        String[] drg , qty, dose, dura ;
        boolean exist=false;
        if (!date.equalsIgnoreCase("")){
    		//String edt = date.substring(6)+"-"+date.substring(3,5)+"-"+date.substring(0,2);
    		cond=" AND date(t.entrydate) = '"+date+"'";
    	}
    	
    	if (!slno.equalsIgnoreCase("")){
    		cond=" AND t.serno = "+slno;	
    	}
    	
        String  qSql = "select drugs,quantity,dose,duration,entrydate from pre where pat_id='"+id+"' "+cond+" and drugs is not null union select drugs,quantity,dose,duration,entrydate from prs where pat_id='"+id+"' and drugs is not null";
        Object res= mydb.ExecuteQuary(qSql);
 		
			Vector tmpv = (Vector)res;
			if(tmpv.size()>0){
               	outputstr += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
            	outputstr += "<tr style='background-color:#D7FFD7'><th>Drug</th><th>Quantity</th><th>Dose</th><th>Duration</th><th>Date</th></tr>";
 					
				for(int j=0;j<tmpv.size();j++){
					dataobj tmpdata = (dataobj) tmpv.get(j);
					drugstr = tmpdata.getValue(0);
                    quantitystr = tmpdata.getValue(1);
                    dosestr = tmpdata.getValue(2);
                    durationstr = tmpdata.getValue(3);
                    String pdt = tmpdata.getValue(4);
					dtstr = pdt.substring(8,10)+"/"+pdt.substring(5,7)+"/"+pdt.substring(0,4);
					
				//	drg = drugstr.Split(new string[] { "!" }, StringSplitOptions.RemoveEmptyEntries);
					drg = drugstr.split("!");
					
                   // qty = quantitystr.Split(new string[] { "!" }, StringSplitOptions.None);
                    qty = quantitystr.split("!");
                   // dose = dosestr.Split(new string[] { "!" }, StringSplitOptions.None);
                    dose = dosestr.split("!");
                    //dura = durationstr.Split(new string[] { "!" }, StringSplitOptions.None);
                    dura = durationstr.split("!");
                    for (int i = 0; i < drg.length; i++)
                    {
                        outputstr += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        outputstr += "<td align='left'>" + drg[i] + "</td>";
                        outputstr += "<td align='left'>" + (i < qty.length ? qty[i] : "") + "</td>";
                        outputstr += "<td align='left'>" + (i < dose.length ? dose[i] : "") + "</td>";
                        outputstr += "<td align='center'>" + (i < dura.length ? dura[i] : "") + "</td>";
                        outputstr += "<td align='center'>" + dtstr + "</td>";
                        outputstr += "</tr>";
                    }				
				}
				outputstr += "</table>";
	    		exist=true;
    		}
                        
            
    		if (exist == false){
          	outputstr = "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00;background-color:#FFFFFF'><tr><td align='center'>No Record Found</td></tr></table>";
           }
    			
	   return outputstr;
    }
    
    
    private boolean hasImpression(String str)
		{
			String [] arr = new String [13];
			boolean ans=true;
			arr[0]="med";
			arr[1]="prs";
			arr[2]="pre";
			arr[3]="smr";
			arr[4]="tsr";
			arr[5]="i07";
			arr[6]="i22"; 
			arr[7]="h12"; 
			arr[8]="h13"; 
			arr[9]="h14"; 
			arr[10]="h15";
			arr[11]="p26";
			arr[12]="i30";
			
			for(int i=0;i<13;i++)
			{
				if(arr[i].equalsIgnoreCase(str)){
					ans=false;
					break;
				}
			}
			return ans;
		}
		
    public String getImpression(String id) throws RemoteException,SQLException{
    	String output="";
    	String  qSql="";
       	String [] myarr= new String [3];
		String [] myarr1 = new String [3];
		myarr[0]="H";
		myarr1[0]="Complaints";
		myarr[1]="P";
		myarr1[1]="Findings";
		myarr[2]="I";
		myarr1[2]="Investigations";
		//get the patient name	
        qSql = "select pat_name from med where pat_id ='"+id+"'";
		String patnam =mydb.ExecuteSingle(qSql);
		output+="<TABLE><TR><TD Width='500'><FONT SIZE='8pt'><B>General Summary</B></FONT></TD><TD Valign='Bottom'>";
		output+="<A HREF='#'  onClick='PrintDoc();' Border=0 ";
		output+="Style='font-weight:Bold; text-decoration:none; '>";
		output+="&nbsp;&nbsp;Print&nbsp;&nbsp;</A></TD></TR></TABLE>";
		output+="<B>" +patnam.toUpperCase()+ "</B>(" +id.toUpperCase()+ ") <HR>";
		for(int i=0;i<3;i++)//modified 06/06/2008
		{
                qSql = "Select type,serno,date from listofforms Where pat_id = '"+id+"' and Upper(type) Like '"+myarr[i] + "%' Order by type, serno";
				Object res=mydb.ExecuteQuary(qSql);
				Vector tmpv = (Vector)res;
				if(tmpv.size()>0 ) output+="<FONT SIZE='5pt' Color='#009900'><B><U>"+myarr1[i].toUpperCase()+"</U></B></FONT><BR><BR>" ;
				
				for(int j=0;j<tmpv.size();j++){
					dataobj tmpdata = (dataobj) tmpv.get(j);
					String typ=tmpdata.getValue("type").toLowerCase();
					
					boolean ans=hasImpression(typ);
					if(ans == true){
						String pdt = tmpdata.getValue("date");
						String dt = pdt.substring(8,10)+"/"+pdt.substring(5,7)+"/"+pdt.substring(0,4);
						String sl=tmpdata.getValue("serno");
						qSql = "Select tbxgeneralimp from " + typ + " where pat_id = '"+id+"' and  entrydate = '"+pdt+"' and serno="+sl;
							Object res1=mydb.ExecuteQuary(qSql);
							Vector tmpv1 = (Vector)res;
							if(tmpv1.size()>0){
								dataobj tmpdata1 = (dataobj) tmpv1.get(0);
								String gimp="";
								gimp=tmpdata1.getValue(0).trim();
								if(gimp.equalsIgnoreCase("")){
								output+="<FONT Color='BLUE'><B>";
								output+=typ.toUpperCase()+"</B><FONT Color='RED'>(Serial No: <B>"+sl+"</B> Dated:<B>"+dt+"</B>)<BR>";
								output+= "</FONT></FONT>" ;
								output+= "<TABLE Width=500><TR><TD><P Align=justify><BLOCKQUOTE>'" +gimp+ "'</BLOCKQUOTE></P></TD></TR></TABLE>";
								}		
							}
					}
				}
			}
					            
		return output;
    }

/* old ver
    public String getImmuzinationData(String id) throws RemoteException,SQLException{
    	String outputstr = "";
        String prevvac_name = "", vac_name = "", nowcolor ="";
        boolean exist=false;
        Calendar c1 = Calendar.getInstance(); 
        String qSql = "SELECT age, dateofbirth, type, entrydate FROM med WHERE pat_id = '"+id+"'";
        Object res=mydb.ExecuteQuary(qSql);
		Vector tmpv = (Vector)res;	
		if(tmpv.size()>0){
			dataobj tmpdata = (dataobj) tmpv.get(0);
			String dob=tmpdata.getValue("dateofbirth");
			String ag=tmpdata.getValue("age");
			String entryDate = tmpdata.getValue("entrydate");
			entryDate=entryDate.substring(0,10);
		//	System.out.println("entryDate:"+entryDate);
			
	    	String xx [] = entryDate.split("-");
	    	
	    	try{
				if(dob.equalsIgnoreCase("")){
        	    	c1.set(Integer.parseInt(xx[0]),Integer.parseInt(xx[1])-1,Integer.parseInt(xx[2]));
					String ages[]=ag.split(",",3);
				//	System.out.println("ages.length :"+ages.length);
				
					if(!ages[0].equals("")) c1.add(Calendar.YEAR, - Integer.parseInt(ages[0].trim()));
					if(!ages[1].equals("")) c1.add(Calendar.MONTH, - Integer.parseInt(ages[1].trim()));
					if(!ages[2].equals("")) c1.add(Calendar.DATE, - Integer.parseInt(ages[2].trim()));
					dob=myDate.dateFormat("yyyy-MM-dd",c1.getTime());
				}
		
				//outputstr += "<center><h3>Immuzination</h4></center><table width='70%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
	           

	            qSql = "SELECT vac,testdate FROM a13 WHERE pat_id = '"+id+"' order by vac asc, testdate desc";		
				Object res1=mydb.ExecuteQuary(qSql);
				Vector tmpv1 = (Vector)res1;
				if(tmpv1.size()>0 )	{
					
	            outputstr += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
            	outputstr += "<tr style='background-color:#D7FFD7'><th>Vaccine Name</th> <th>Date</th><th>Years</th><th>Months</th><th>Days</th> </tr>";

				for(int i=0;i<tmpv1.size();i++){
					dataobj tmpdata1 = (dataobj) tmpv1.get(i);	
					String tdt=tmpdata1.getValue(1);
					tdt=tdt.substring(0,10);
					String dt = tdt.substring(8,10)+"/"+tdt.substring(5,7)+"/"+tdt.substring(0,4);
				//	System.out.println("testdate >:"+tdt);
				//	System.out.println("dob >:"+dob);
					
					String xx1 [] = tdt.split("-");
					java.util.Date tstdt = new Date(Integer.parseInt(xx1[0]),Integer.parseInt(xx1[1])-1,Integer.parseInt(xx1[2]));
					String xx2 [] = dob.split("-");
					java.util.Date dobdt=new Date(Integer.parseInt(xx2[0]),Integer.parseInt(xx2[1])-1,Integer.parseInt(xx2[2]));
					
					
					long ldatetst=tstdt.getTime();
					long ldatedob=dobdt.getTime();
					
					//long ldatetst=0;
					//long ldatedob=0;
					
				    int hrtst   = (int)(ldatetst/3600000); //60*60*1000
		        	int hrdob   = (int)(ldatedob/3600000);
		        	int daystst = (int)hrtst/24;
		    	    int daysdob = (int)hrdob/24;
		    	    int dateDiff  = daystst - daysdob;
		    	    int years =		(int)(dateDiff / 365);
		            int months = (int)((dateDiff % 365) / 30);
		            int days = dateDiff - (years * 365 + months * 30);
		            
		            vac_name = tmpdata1.getValue(0);
		            
		                if (vac_name != prevvac_name)
		                {   if (nowcolor == "#FEFEF2")
		                        nowcolor = "#FCF6CF";
		                    else
		                        nowcolor = "#FEFEF2";
		                }
	                outputstr += "<tr style='background-color:" + nowcolor + ";border:1px solid #880088'>";
	                outputstr += "<td>" + vac_name + "</td>";
	                outputstr += "<td align='center'>" + dt + "</td>";
	                outputstr += "<td align='center'>" + (years > 0 ? years : "") + "</td>";
	                outputstr += "<td align='center'>" + (months > 0 ? months : "") + "</td>";
	                outputstr += "<td align='center'>" + (days > 0 ? days : "") + "</td>";
	                outputstr += "</tr>";
	                prevvac_name = vac_name;  
					}
					exist=true; 
			 		outputstr += "</table>";
				} // endif
			}catch(Exception e){
				System.out.println(e.toString());
			}	
		}
		if (exist == false){
          	outputstr = "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00;background-color:#FFFFFF'><tr><td align='center'>No Record Found</td></tr></table>";
     	}
        return outputstr;   
    }
    
    */
    
    public String getImmuzinationData(String pid) throws RemoteException,SQLException{
    	
            String vaccine_name, prevvac_name="", strTable = "", nowcolor="",dt="";
           
            String prevVacCode = "-1";
            int i = 0;

            String qr = "select a13.vaccine_id,a13.age_given,a13.site,a13.code,a13.entrydate,immun_schedule.age,immun_schedule.vaccine_code as vaccine_code,";
            qr += "(select vac_name from immunization where immunization.vac_code=immun_schedule.vaccine_code) as vName,";
            qr += "(select vac_info from immunization where immunization.vac_code=immun_schedule.vaccine_code) as info,";
            qr += "(select disease from immunization where immunization.vac_code=immun_schedule.vaccine_code) as Dis";
            qr += " from a13, immun_schedule where a13.vaccine_id=immun_schedule.vac_id and pat_id= '"+pid+"' order by vaccine_code";
            
            //strTable += "<center><h3>Immunization</h4></center>";
            
             try{
            	Object res=mydb.ExecuteQuary(qr);
         		if(res instanceof String){
					strTable= "Error : "+res;
				}else{
					Vector tmp = (Vector)res;
					if(tmp.size()>0){
						
						for(int ii=0;ii<tmp.size();ii++){
						dataobj temp = (dataobj) tmp.get(ii);
						
						String VacCode = temp.getValue(6); 
						
						if(!VacCode.equalsIgnoreCase(prevVacCode)){
							if (!prevVacCode.equalsIgnoreCase("-1"))
                            {
                                strTable += "</table></td></tr></table><br>";
                            }
                            
                            strTable += "<table border='0' width='90%' align='center' class='tabh'>";
                            strTable += "<tr><td style='color:blue;font-weight:bold;font-size:9pt'>" + temp.getValue(9) + "</td></tr>";
                            strTable += "<tr><td><table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;' class='tabh'>";
                            strTable += "<tr align='center' style='background-color:#D7FFD7'><th>Vaccine</th><th>Date Given</th><th>Site</th><th>Age Given</th><th>Age Recomended</th><th>Code</th></tr>";
                            prevVacCode = VacCode;
                            i++;
						} // if
						
						   vaccine_name = temp.getValue(7) +" "+ temp.getValue(0).substring(temp.getValue(0).length()-1) ;// myrdr.GetValue(0).ToString().Remove (0,myrdr.GetValue(0).ToString().Length-1);
                           dt=myDate.mysql2ind(temp.getValue(4));
                            
                        if (!vaccine_name.equalsIgnoreCase(prevvac_name)){
                            if (nowcolor.equalsIgnoreCase("#FEFEF2")) nowcolor = "#FCF6CF";
                            else nowcolor = "#FEFEF2";
                        }
                        
                            strTable += "<tr align='center' style='background-color:#FEFEF2;border:1px solid #880088'>";
                            strTable += "<td>"+vaccine_name+"</td>";
                            strTable += "<td>" + dt + "</td>";
                            strTable += "<td>" + temp.getValue(2) + "</td>";
                            strTable += "<td>" + temp.getValue(1) + "</td>";
                            strTable += "<td>" + temp.getValue(5) + "</td>";
                            strTable += "<td>" + temp.getValue(3) + "</td>";
                            strTable += "</tr>";
                        	prevvac_name = vaccine_name;
                        
						} //for
						
						strTable += "</table></td></tr></table><br>";
						
						
					}else{
	                 	strTable +="<table  align='center' width='100%' cellspacing='0' cellpadding='5' style='background-color:#CECEFF;'>";
                    	strTable += "<tr style='background-color:#D7FFD7'><th>Vaccine</th><th>Date Given</th><th>Site</th><th>Age Given</th><th>Age Recomended</th><th>Code</th></tr>";
                    	strTable += "<tr><td td align='center' colspan='5'>No Data<td></tr></table>";
					}
							
			  } // else
			  
            }catch (Exception e){
         		//strTable= "Error :" +e.toString() ;
         	} 
         return strTable;
         
           
        }
            
    public String getPhenotypeRecord(String id) throws RemoteException,SQLException{
   	 	String outputstr = "";
   	 	String nrti_thymidine = "", nrti_nucleoside = "", nnrti = "", protease_minor = "", protease_major = "", fusion = "", integrase = "";
   	 	 
   	 	String qSql = "SELECT * FROM s31 WHERE PAT_ID = '"+id+"' ORDER BY entrydate DESC";
   	 	
   	 	outputstr += "<table width='70%' border='1' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
        outputstr += "<tr style='background-color:#D7FFD7'><th>Date</th><th>NRTI(Thymidine)</th><th>NRTI(Nucleoside)</th><th>NNRTI</th><th>Protease(Minor)</th><th>Protease(Major)</th><th>Fusion</th><th>Integrase</th></tr>";
		
		Object res=mydb.ExecuteQuary(qSql);
		Vector tmpv = (Vector)res;	
		for(int i=0;i<tmpv.size();i++){
			dataobj tmpdata = (dataobj) tmpv.get(i);	
			String tdt=tmpdata.getValue(8);
			String dt = tdt.substring(8,10)+"/"+tdt.substring(5,7)+"/"+tdt.substring(0,4);
				nrti_thymidine = tmpdata.getValue(1);
                nrti_nucleoside = tmpdata.getValue(2);
                nnrti = tmpdata.getValue(3);
                protease_minor = tmpdata.getValue(4);
                protease_major = tmpdata.getValue(5);
                fusion = tmpdata.getValue(6);
                integrase = tmpdata.getValue(7);
                
                if(nrti_thymidine.equalsIgnoreCase("")) nrti_thymidine="-";
                if(nrti_nucleoside.equalsIgnoreCase("")) nrti_nucleoside="-";
                if(nnrti.equalsIgnoreCase("")) nnrti="-";
                if(protease_minor.equalsIgnoreCase("")) protease_minor="-";
                if(protease_major.equalsIgnoreCase("")) protease_major="-";
                if(fusion.equalsIgnoreCase("")) fusion="-";
                if(integrase.equalsIgnoreCase("")) integrase="-";
                
                outputstr += "<tr>";
                outputstr += "<td>" + dt + "</td>";
                outputstr += "<td>" + nrti_thymidine.replaceAll(",", "<br>") + "</td>";
                outputstr += "<td>" + nrti_nucleoside.replaceAll(",", "<br>") + "</td>";
                outputstr += "<td>" + nnrti.replaceAll(",", "<br>") + "</td>";
                outputstr += "<td>" + protease_minor.replaceAll(",", "<br>") + "</td>";
                outputstr += "<td>" + protease_major.replaceAll(",", "<br>") + "</td>";
                outputstr += "<td>" + fusion.replaceAll(",", "<br>") + "</td>";
                outputstr += "<td>" + integrase.replaceAll(",", "<br>") + "</td>";
                outputstr += "</tr>";
                
		}
		outputstr += "</table>";
	    return outputstr;
    }
    
    public String getCBCSummary(String patid, int no) throws RemoteException,SQLException{
    //	System.out.println("\n getCBCSummary : \n");
    	
    	String prevyear ="";
        String outputstr = "", nowcolor = "";
     	String qSql = "SELECT testdate, cd4_count, cd4_percent, ROUND(LOG10(viralload), 2) AS Log_copies FROM s32 WHERE pat_id = '"+patid+"' order by testdate desc, serno desc" + (no > 0 ? " LIMIT " + no : "") ;   //, lymphocytes_t, ROUND(CAST(cd4_count AS float) / CAST(cd8_count AS float), 2) AS cd4cd8, viralload
        	
        outputstr += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
        outputstr += "<tr style='background-color:#D7FFD7'><th>Testdate</th><th>CD4 Count</th> <th>CD4 Percent</th><th>Log Copies</th></tr>";  // <th>Lymphocyte</th> <th>Viral_load</th>
		
		Object res=mydb.ExecuteQuary(qSql);
		Vector tmpv = (Vector)res;	
            if (tmpv.size()>0 ){
            	
                	for(int i=0;i<tmpv.size();i++){
                		dataobj tmpdata = (dataobj) tmpv.get(i);
                		String tdt=tmpdata.getValue(0);	
                		String tdty=tdt.substring(0,4);
                		String dt = tdt.substring(8,10)+"/"+tdt.substring(5,7)+"/"+tdt.substring(0,4);
	                    
	                     
                    if (tdty.equalsIgnoreCase(prevyear)){
                        if (nowcolor == "#FEFEF2") nowcolor = "#FCF6CF";
                       else nowcolor = "#FEFEF2";
                    }

                    outputstr += "<tr style='background-color:" + nowcolor + ";border:1px solid #880088'>";
                    outputstr += "<td align='center' nowrap>" + dt + "</td>";
                    outputstr += "<td align='center'>" + tmpdata.getValue(1) + "</td>";
                    outputstr += "<td align='center'>" +tmpdata.getValue(2) + "</td>";
                    outputstr += "<td align='center'>" + tmpdata.getValue(3) + "</td>";
                    outputstr += "</tr>";
                    prevyear = tdty;
                }
            }
            else
            {
                outputstr += "<tr style='background-color:#FFFFFF'><td align='center' colspan='4'>No Record Found</td></tr>";
            }
            
            outputstr += "</table>";
            
       return outputstr;
       
    }
    public String getOtherCBCSummary(String patid, String[][] fields, int no) throws RemoteException,SQLException{
    	//System.out.println("\n getOtherCBCSummary : \n");
    	
    	boolean exist = false;
        String outputstr = "", caption = "", row1 = "", row2 = "";
		
		outputstr += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
		
        for (int i = 0; i < fields.length; i++){
        	
        	//String qSql = "SELECT CAST(" + fields[i][0] + " AS varchar(300)), testdate FROM " + fields[i][1] + " WHERE pat_id ='"+patid +"' ORDER BY testdate DESC "  + (no > 0 ? " LIMIT " + no : "") ;
        	String qSql = "SELECT " + fields[i][0] + " , testdate FROM " + fields[i][1] + " WHERE pat_id ='"+patid +"' ORDER BY testdate DESC "  + (no > 0 ? " LIMIT " + no : "") ;
        	
            caption = fields[i][2];
        	row1 = "<th width='20%'>Date</th>";
            row2 = "<td align='center' width='20%' style='background-color:#D7FFD7'>" + caption + "</td>";
            Object res=mydb.ExecuteQuary(qSql);
			Vector tmpv = (Vector)res;	
			
			for(int j=0;j<tmpv.size();j++){
				dataobj tmpdata = (dataobj) tmpv.get(j);
	       		String tdt=tmpdata.getValue(1);	
	       		String dt = tdt.substring(8,10)+"/"+tdt.substring(5,7)+"/"+tdt.substring(0,4);

      		 	row1 += "<th align='center'>" + dt + "</th>";
                row2 += "<td align='center'>" + tmpdata.getValue(0) + "</td>";
                exist = true;
			}
			
         	outputstr += "<tr style='background-color:#D7FFD7'>" + row1 + "</tr>";
         	outputstr += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>" + row2 + "</tr>";        
          }
          outputstr += "</table>";
          if (exist == false){
          	outputstr = "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00;background-color:#FFFFFF'><tr><td align='center'>No Record Found</td></tr></table>";
           }

	  return outputstr;
    
    }
    
	public String getProbSummary(String patid, int no) throws RemoteException,SQLException{
		  // System.out.println("\n getProbSummary : \n");
		   
		   String outputstr = "";
          // String qSql = "SELECT prob_id, prob_desc, onset, added_by FROM problem_list WHERE pat_id ='"+patid+"' and status = 'n' order by onset desc " + (no > 0 ? " LIMIT " + no : "");
           String qSql = "SELECT serno, prob_desc, onset, added_by FROM z00 WHERE pat_id ='"+patid+"' and status = 'n' order by onset desc " + (no > 0 ? " LIMIT " + no : "");
           
           outputstr += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
           outputstr += "<tr style='background-color:#D7FFD7'><th>Onset</th><th>Problem</th></tr>";
           
			Object res=mydb.ExecuteQuary(qSql);
			Vector tmpv = (Vector)res;	
			if(tmpv.size()>0){
			
				for(int j=0;j<tmpv.size();j++){
					dataobj tmpdata = (dataobj) tmpv.get(j);
		       		String tdt=tmpdata.getValue(2);	
		       		String dt = tdt.substring(8,10)+"/"+tdt.substring(5,7)+"/"+tdt.substring(0,4);
					
					outputstr += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                    outputstr += "<td align='center' nowrap>" +dt + "</td>";
                    outputstr += "<td align='left'>" + tmpdata.getValue(1) + "</td>";
                    outputstr += "</tr>";
				}
			}else{
			 	outputstr += "<tr style='background-color:#FFFFFF'><td align='center' colspan='2'>No Problem Listed</td></tr>"; 
			}
			
          outputstr += "</table>";
	   return outputstr;
            
	}
	
	public String getAntiRetroViralSummary(String patid, int no) throws RemoteException,SQLException{
	//System.out.println("\n getAntiRetroViralSummary : \n");
	
	String outputstr = "";
	String qSql = "SELECT d.drug, f.prep, a.formuladose, f.unit, t.dose, t.entrydate FROM a02 t, arvpackage a, drugindex d, formulation f WHERE t.pat_id = '"+patid+"' AND t.drug_id = d.id_drugindex AND t.arvpackage_id = a.id_arvpackage AND f.id_formulation =a.formula ORDER BY entrydate DESC " + (no > 0 ? "LIMIT " + no : "");
    outputstr += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
    outputstr += "<tr style='background-color:#D7FFD7'><th>Drug</th><th>Formula</th><th>Dose</th><th>Date</th></tr>";
   
	Object res=mydb.ExecuteQuary(qSql);
	Vector tmpv = (Vector)res;	
	if(tmpv.size()>0){
	
		for(int j=0;j<tmpv.size();j++){
			dataobj tmpdata = (dataobj) tmpv.get(j);
	   		String tdt=tmpdata.getValue(5);	
	   		String dt = tdt.substring(8,10)+"/"+tdt.substring(5,7)+"/"+tdt.substring(0,4);
			
			outputstr += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
            outputstr += "<td align='left'>" + tmpdata.getValue(0) + "</td>";
            outputstr += "<td align='left'>" + tmpdata.getValue(1) + " " + tmpdata.getValue(2) + tmpdata.getValue(3) + "</td>";
            outputstr += "<td align='left'>" + tmpdata.getValue(4) + "</td>";
            outputstr += "<td align='center'>" + dt + "</td>";
            outputstr += "</tr>";
		 }
	
	}else{
		 outputstr += "<tr style='background-color:#FFFFFF'><td align='center' colspan='4'>No Anti-Retroviral Prescribed</td></tr>";
	}
		
	outputstr += "</table>";
	return outputstr;
            
}

	public String getDrugAllergySummary(String patid) throws RemoteException,SQLException{
	
	//System.out.println("\n getDrugAllergySummary : \n");
	String outputstr = "";
	
    String qSql = "SELECT drug_name, nature_allergy FROM h13 WHERE pat_id ='"+patid+"' ORDER BY drug_name";
    boolean exist=false;
	
	Object res=mydb.ExecuteQuary(qSql);
	Vector tmpv = (Vector)res;	
	if(tmpv.size()>0){
		    outputstr += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
    		outputstr += "<tr style='background-color:#D7FFD7'><th>Drug Name</th><th>Allergy Type</th></tr>";

		for(int j=0;j<tmpv.size();j++){
			dataobj tmpdata = (dataobj) tmpv.get(j);
	   		//String tdt=tmpdata.getValue(5);	
	   		//String dt = tdt.substring(8,10)+"/"+tdt.substring(5,7)+"/"+tdt.substring(0,4);
			
			outputstr += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
            outputstr += "<td align='left'>" + tmpdata.getValue(0) + "</td>";
            outputstr += "<td align='left'>" + tmpdata.getValue(1) + "</td>";
            outputstr += "</tr>";
		 }
		  outputstr += "</table>";
		 exist=true;
	
	}
	
	//else{
	//	 outputstr += "<tr style='background-color:#FFFFFF'><td align='center' colspan='2'>No Record Found</td></tr>";
//	} //outputstr += "</table>";
	    
    if (exist == false){
          	outputstr = "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00;background-color:#FFFFFF'><tr><td align='center'>No Record Found</td></tr></table>";
     }
     
    return outputstr;
            
	}
	
	
public String getVaccinationSummary(String patid) throws RemoteException,SQLException{
	String outputstr="not done";
	
	return outputstr;
	
	}
	
public String getDiaognosisSummary(String patid) throws RemoteException,SQLException{
	String outputstr="";
	String eDate = "";
	String prostr = "", finstr = "", edt = "";
	String bgcolor="#EBEBFC"; //#FFFFFF
	int fcnt=1,pcnt=1;
	
	boolean first = true;
	String qSql="SELECT diag,type, entrydate FROM (SELECT pat_id,tbxpro_diagnosis AS diag, entrydate, 'pro' AS type FROM d00  WHERE pat_id='"+patid+"' UNION SELECT  pat_id,tbxfin_diagnosis AS diag,entrydate, 'fin' AS type FROM d01 WHERE pat_id='"+patid+"') AS abcd  ORDER BY entrydate DESC";
	Object res=mydb.ExecuteQuary(qSql);
	Vector tmpv = (Vector)res;	
	
	if(tmpv.size()>0){
 			outputstr += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
            outputstr += "<tr style='background-color:#D7FFD7'><th>Entry Date</th><th>Provisional</th><th>Final</th></tr>";

		for(int j=0;j<tmpv.size();j++){
			dataobj tmpdata = (dataobj) tmpv.get(j);
	   		edt = tmpdata.getValue(2);
	   		edt=edt.substring(8,10)+"/"+edt.substring(5,7)+"/"+edt.substring(0,4);
	   		
	   		//System.out.println("B edt:" +edt +">>eDate: " +eDate);
	   		
		 	if (!edt.equalsIgnoreCase(eDate) && !eDate.equals("")){              
		 	
		 //	System.out.println(" if edt:" +edt +">>eDate: " +eDate);
		 		  	outputstr += "<tr style='background-color:"+bgcolor+"'>";
                    outputstr += "<td align='left' >" + eDate + "</td>";
                    outputstr += "<td align='left' valign='top' >" + prostr + "</td>";
                    outputstr += "<td align='left' valign='top' >" + finstr + "</td>";
                    outputstr += "</tr>";
                    bgcolor=(bgcolor.equalsIgnoreCase("#FFFFFF") ? "#EBEBFC" : "#FFFFFF");
                    prostr = "";
                    finstr = "";
                    fcnt=1;
                    pcnt=1;
                    eDate = edt;
                    
            }else eDate = edt;

            if (tmpdata.getValue(1).equalsIgnoreCase("fin")){
            	finstr += fcnt + ". "+ tmpdata.getValue(0) + "<br>";
            	fcnt++;
            	
            }else{
            	prostr += pcnt + ". "+ tmpdata.getValue(0) + "<br>";
            	pcnt++;
            }
                
		 }
		 
		 outputstr += "<tr style='background-color:"+bgcolor+"'>";
         outputstr += "<td align='left'  >" + edt + "</td>";
         outputstr += "<td align='left' valign='top' >" + prostr + "</td>";
         outputstr += "<td align='left' valign='top'>" + finstr + "</td>";
         outputstr += "</tr>";
         outputstr += "</table>";
	}else{
       	outputstr = "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00;background-color:#FFFFFF'><tr><td align='center'>No Record Found</td></tr></table>";
    }
	return outputstr;
}

public String getOncoStageSummary(String patid) throws RemoteException,SQLException{
	String outputstr="";
	
	String qSql = "Call sp_oncostage('"+patid+"')";
	
	Object res= mydb.ExecuteProcQuary(qSql);
	if(res instanceof String){
		System.out.println(res);
			//outputstr+=res;
	}else{
		outputstr += "<table width='100%' border='0' align='center' cellspacing='1' cellpadding='3' style='border:1px solid #00AA00'>";
        outputstr += "<tr style='background-color:#D7FFD7'><th>Organ</th><th>Primary Tumor (T)</th><th>Lymph Node (N)</th><th>Distant Metastasis (M)</th><th>Date</th></tr>";
		Vector mainv = (Vector)res;
		for(int i=0;i<mainv.size();i++){
			Vector tmpv = (Vector)mainv.get(i);
			if(tmpv.size()>0){
						
				for(int j=0;j<tmpv.size();j++){
					dataobj tmpdata = (dataobj) tmpv.get(j);
					
					outputstr += "<tr>";
                    outputstr += "<td>" + tmpdata.getValue(0) + "</td>";
                    outputstr += "<td>" + tmpdata.getValue(1) + "</td>";
                    outputstr += "<td>" + tmpdata.getValue(2) + "</td>";
                    outputstr += "<td>" + tmpdata.getValue(3) + "</td>";
                    String d=tmpdata.getValue(4);
                    String dt=d.substring(8,10)+"/"+d.substring(5,7)+"/"+d.substring(0,4);
                    outputstr += "<td>" + dt  + "</td>";
                    outputstr += "</tr>";
					}
			 }else{
			 	outputstr += "<tr style='background-color:#FFFFFF'><td align='center' colspan='5'>No Record Found</td></tr>";
			 }
			} // i 
			
			outputstr += "</table>";
			
	} // else
	
	return outputstr;
}

public dataobj getPatientInfo(String patid) throws RemoteException,SQLException{
	
	String qSql="SELECT * FROM med WHERE pat_id = '"+patid+"'";
	dataobj obj= new dataobj();
	String name = "", type = "", birthdate = "", gender = "", discat = "", mstat = "";
	Calendar c1 = Calendar.getInstance(); 
	try{
		Object res=mydb.ExecuteQuary(qSql);
		Vector tmpv = (Vector)res;	
		if(tmpv.size()>0){
			dataobj tmpdata = (dataobj) tmpv.get(0);
		 	name = tmpdata.getValue(2).trim();
            type = tmpdata.getValue(3).trim();
            gender = tmpdata.getValue(5).trim();
            discat = tmpdata.getValue(7).trim();
            mstat = tmpdata.getValue(26).trim();
            
            String dob=tmpdata.getValue("dateofbirth");
			String ag=tmpdata.getValue("age");
			String entryDate = tmpdata.getValue("entrydate");
			entryDate=entryDate.substring(0,10);
			
	    	String xx [] = entryDate.split("-");
				if(dob.equalsIgnoreCase("")){
        	    	c1.set(Integer.parseInt(xx[0]),Integer.parseInt(xx[1])-1,Integer.parseInt(xx[2]));
					String ages[]=ag.split(",",3);
				//	System.out.println("ages.length :"+ages.length);
					if(!ages[0].equals("")) c1.add(Calendar.YEAR, - Integer.parseInt(ages[0].trim()));
					if(!ages[1].equals("")) c1.add(Calendar.MONTH, - Integer.parseInt(ages[1].trim()));
					if(!ages[2].equals("")) c1.add(Calendar.DATE, - Integer.parseInt(ages[2].trim()));
					dob=myDate.dateFormat("yyyy-MM-dd",c1.getTime());
				}else{
					dob=dob.substring(0,10);
				}
				
				obj.add("name", name);
				obj.add("gender", gender);
                obj.add("discat", discat);
                obj.add("mstat", mstat);
                obj.add("dob", dob);
                
                obj.add("type", type);
                String cdat = myDate.getCurrentDate("ymd",true);
                dbGenOperations   dbGen= new dbGenOperations (pinfo);
                obj.add("age_days", dbGen.getAgeInDaysOfPatient(patid,cdat));
		}
		
		String tabnam = "", hcol = "", wcol = "" ;
		if(discat.equalsIgnoreCase("Pediatric HIV")){
			 hcol = "ht";
             wcol = "wt";
             tabnam = "h15";
		}else if(discat.equalsIgnoreCase("ONCOLOGICAL")){
			hcol = "height";
            wcol = "weight";
            tabnam = "p43";
		}else {
			 hcol = "ht";
             wcol = "wt";
             tabnam = "p00";
		}
				
		String sql = "SELECT 'H', " + hcol + ", entrydate FROM " + tabnam + " WHERE pat_id = '"+ patid +"' AND entrydate = (SELECT MAX(entrydate) FROM " + tabnam + " WHERE PAT_ID = '"+ patid +"' AND " + hcol + " IS NOT NULL) UNION ";
        sql += "SELECT 'W', " + wcol + ", entrydate FROM " + tabnam + " WHERE pat_id = '"+ patid +"' AND entrydate = (SELECT MAX(entrydate) FROM " + tabnam + " WHERE PAT_ID = '"+ patid +"' AND " + wcol + " IS NOT NULL)";   // UNION 
		res=mydb.ExecuteQuary(sql);
		tmpv = (Vector)res;	
		if(tmpv.size()>0){
			for(int i=0;i<tmpv.size();i++){			
				dataobj tmpdata = (dataobj) tmpv.get(i);		
				String entdate = tmpdata.getValue(2);
				String val = tmpdata.getValue(1);
				entdate=entdate.substring(0,10);
				if(tmpdata.getValue(0).equalsIgnoreCase("H")){
					obj.add("height", val + " " + entdate);
				} else if(tmpdata.getValue(0).equalsIgnoreCase("W")){
					obj.add("weight", val + " " + entdate);
				}
			}
		}
	}catch(Exception e){
			System.out.println("getPatientInfo >> "+e.toString());
	}
	return obj;
}

	public String getPercentile(String tabname, int month, String val) throws RemoteException,SQLException{
		
		String qSql="SELECT * FROM " + tabname + " WHERE agemonth = "+ month;
		double value = Double.parseDouble(val);
		
		String prcnt = "";
		try{
			Object res=mydb.ExecuteQuary(qSql);
			Vector tmpv = (Vector)res;	
			if(tmpv.size()>0){
				dataobj tmpdata = (dataobj) tmpv.get(0);		
				for(int i=0;i<tmpdata.getLength();i++) {
                    if(!tmpdata.getKey(i).startsWith("p")) continue;
                    String tabval=tmpdata.getValue(i);
                    
                    if(value < Double.parseDouble(tabval) || value >= Double.parseDouble(tabval) &&  value < Double.parseDouble(tmpdata.getValue(i+1))){
						prcnt = tmpdata.getKey(i);
					    break;	
					}else if (value >= Double.parseDouble(tmpdata.getValue(i+1)))
                    {
                        prcnt = tmpdata.getKey(i+1);
                        break;
                    }
				}
			}
		}catch(Exception e){
			System.out.println("getPercentile >> "+e.toString());
			
		}
		return prcnt;
	}
	
	public dataobj getPercentile(String tabname, int month) throws RemoteException,SQLException{
		dataobj obj= new dataobj();
		String qSql="SELECT * FROM " + tabname + " WHERE agemonth = "+ month;
		try{
			Object res=mydb.ExecuteQuary(qSql);
			Vector tmpv = (Vector)res;	
			if(tmpv.size()>0){
				dataobj tmpdata = (dataobj) tmpv.get(0);	
					
				for(int i=0;i<tmpdata.getLength();i++) {
                    if(!tmpdata.getKey(i).startsWith("p")) continue;
                   	obj.add(tmpdata.getKey(i),tmpdata.getValue(i) );
				}
			}
		}catch(Exception e){
			System.out.println("getPercentile >> "+e.toString());
			
		}
		
		return obj;
	}

	public String getPastHistoryRecord(String patid) throws RemoteException,SQLException{
	
	String strOprTable="", strTBTable="", strOtherTable="";
	try{
		String qSql="SELECT * FROM a21 WHERE pat_id ='"+ patid +"'";
		
		strOprTable = "<table border='0' width='90%' align='center'><tr style='color:blue;font-weight:bold;font-size:12pt'><td>Past History of Oppurtunistic Infection</td></tr>";
		strOprTable += "<tr><td><table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
		strOprTable += "<tr style='background-color:#D7FFD7'><th>Diagnosis</th><th>Onset</th><th>Duration</th><th>Hospitalisation</th>";
		
		strTBTable = "<table border='0' width='90%' align='center'><tr style='color:blue;font-weight:bold;font-size:12pt'><td>Past History of TB</td></tr>";
		strTBTable += "<tr><td><table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
		strTBTable += "<tr style='background-color:#D7FFD7'><th>Diagnosis</th><th>Onset</th><th>Duration</th><th>Hospitalisation</th>";
		
		strOtherTable = "<table border='0' width='90%' align='center'><tr style='color:blue;font-weight:bold;font-size:12pt'><td>Other Significant Past Illness</td></tr>";
		strOtherTable += "<tr><td><table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
		strOtherTable += "<tr style='background-color:#D7FFD7'><th>Diagnosis</th><th>Onset</th><th>Duration</th><th>Hospitalisation</th>";
		
		Object res=mydb.ExecuteQuary(qSql);
 		if(res instanceof String){
			strOprTable= "Error : "+res;
		}else{
			Vector tmp = (Vector)res;
			if(tmp.size()>0){
				for(int ii=0;ii<tmp.size();ii++){
				dataobj tmpdata = (dataobj) tmp.get(ii);
				
		        strOprTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                //strOprTable += "<td>" + tmpdata.getValue(1) + "</td><td>" + myDate.mysql2ind(tmpdata.getValue(3)) + "</td><td>" + tmpdata.getValue(4)+tmpdata.getValue(5) + "</td><td>" + tmpdata.getValue(6) + "</td>";
                strOprTable += "<td>" + tmpdata.getValue(1) + "</td><td>" + tmpdata.getValue(3) + "</td><td>" + tmpdata.getValue(4)+tmpdata.getValue(5) + "</td><td>" + tmpdata.getValue(6) + "</td>";
                strOprTable += "</tr>";

                strTBTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                //strTBTable += "<td>" + tmpdata.getValue(8) + "</td><td>" + myDate.mysql2ind(tmpdata.getValue(10)) + "</td><td>" + tmpdata.getValue(11) + tmpdata.getValue(12) + "</td><td>" + tmpdata.getValue(13) + "</td>";
                strTBTable += "<td>" + tmpdata.getValue(8) + "</td><td>" + tmpdata.getValue(10) + "</td><td>" + tmpdata.getValue(11) + tmpdata.getValue(12) + "</td><td>" + tmpdata.getValue(13) + "</td>";
                strTBTable += "</tr>";

                strOtherTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                //strOtherTable += "<td>" + tmpdata.getValue(14) + "</td><td>" + myDate.mysql2ind(tmpdata.getValue(16)) + "</td><td>" + tmpdata.getValue(17) + tmpdata.getValue(18) + "</td><td>" + tmpdata.getValue(19) + "</td>";
                strOtherTable += "<td>" + tmpdata.getValue(14) + "</td><td>" + tmpdata.getValue(16) + "</td><td>" + tmpdata.getValue(17) + tmpdata.getValue(18) + "</td><td>" + tmpdata.getValue(19) + "</td>";
                strOtherTable += "</tr>";
				
				}
			}else{
                strOprTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='9'>No Data</td></tr>";
                strTBTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='9'>No Data</td></tr>";
                strOtherTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='9'>No Data</td></tr>";
			}
		}

        strOprTable += "</table></td></tr></table>";
        strTBTable += "</table></td></tr></table>";
        strOtherTable += "</table></td></tr></table>";
            
	}catch(Exception e){
			strOprTable=e.toString();	
	}
	return (strOprTable + strTBTable + strOtherTable);
	
	}
	
	public String getTuberculosisHistoryRecord(String patid)throws RemoteException,SQLException{
		String qSql="SELECT * FROM h22 WHERE pat_id ='"+ patid +"'";
		
		String strTable = "";
        String strParentTable = "", strSiblingOtherTable = "", strMDRTable="";
        
        strParentTable += "<table border='0' width='100%' align='center'><tr style='color:blue;font-weight:bold;font-size:12pt'><td>Parent History</td></tr>";
        strParentTable += "<tr><td><table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
        strParentTable += "<tr style='background-color:#D7FFD7'><th>Person</th><th>Kind of TB</th><th>Diagnosis Date</th><th>Treatment</th>";

        strSiblingOtherTable += "<table border='0' width='100%' align='center'><tr style='color:blue;font-weight:bold;font-size:12pt'><td>Sibling & Other History</td></tr>";
        strSiblingOtherTable += "<tr><td><table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
        strSiblingOtherTable += "<tr style='background-color:#D7FFD7'><th>Person</th><th>Kind of TB</th><th>Diagnosis Date</th><th>Treatment</th>";

        strMDRTable += "<table border='0' width='100%' align='center'><tr style='color:blue;font-weight:bold;font-size:12pt'><td>MDR TB History</td></tr>";
        strMDRTable += "<tr><td><table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
        strMDRTable += "<tr style='background-color:#D7FFD7'><th>Person</th><th>Kind of TB</th><th>Diagnosis Date</th><th>Treatment</th>";
                
        try{
        	Object res=mydb.ExecuteQuary(qSql);
 			if(res instanceof String){
				strParentTable= "Error : "+res;
			}else{
				Vector tmp = (Vector)res;
				if(tmp.size()>0){
					for(int ii=0;ii<tmp.size();ii++){
						dataobj tmpdata = (dataobj) tmp.get(ii);
						
						if(tmpdata.getValue(1).equalsIgnoreCase("yes")){
					        strParentTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
	                        strParentTable += "<td>Mother</td><td>" + tmpdata.getValue(2) + "</td><td>" + tmpdata.getValue(3) + "</td>";
	                        strParentTable += "<td>" + tmpdata.getValue(4) + "</td>";
	                        strParentTable += "</tr>";
						}
						
						if(tmpdata.getValue(5).equalsIgnoreCase("yes")){
					        strParentTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
	                        strParentTable += "<td>Mother</td><td>" + tmpdata.getValue(6) + "</td><td>" + tmpdata.getValue(7) + "</td>";
	                        strParentTable += "<td>" + tmpdata.getValue(8) + "</td>";
	                        strParentTable += "</tr>";
						}
						
						if(tmpdata.getValue(9).equalsIgnoreCase("yes")){
	                            strSiblingOtherTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
	                            strSiblingOtherTable += "<td>" + tmpdata.getValue(10) + "</td><td>" + tmpdata.getValue(11) + "</td><td>" + tmpdata.getValue(12) + "</td>";
	                            strSiblingOtherTable += "<td>" + tmpdata.getValue(13) + "</td>";
	                            strSiblingOtherTable += "</tr>";
						}
						
						if(tmpdata.getValue(14).equalsIgnoreCase("yes")){
	                            strSiblingOtherTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
	                            strSiblingOtherTable += "<td>" + tmpdata.getValue(15) + "</td><td>" + tmpdata.getValue(16) + "</td><td>" + tmpdata.getValue(17) + "</td>";
	                            strSiblingOtherTable += "<td>" + tmpdata.getValue(18) + "</td>";
	                            strSiblingOtherTable += "</tr>";
						}
						
						if(tmpdata.getValue(19).equalsIgnoreCase("yes")){
	                            strMDRTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
	                            strMDRTable += "<td>" + tmpdata.getValue(20) + "</td><td>" + tmpdata.getValue(21) + "</td><td>" + tmpdata.getValue(22) + "</td>";
	                            strMDRTable += "<td>" + tmpdata.getValue(23) + "</td>";
	                            strMDRTable += "</tr>";
						}
					}//for
				}else
                {
                    strParentTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='9'>No Data</td></tr>";
                    strSiblingOtherTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='9'>No Data</td></tr>";
                    strMDRTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='9'>No Data</td></tr>";
                }
			}
			
        }catch(Exception e){
			strParentTable=e.toString();	
		}
		
		strParentTable += "</table></td></tr></table>";
        strSiblingOtherTable += "</table></td></tr></table>";
        strMDRTable += "</table></td></tr></table>";
		return (strParentTable + strSiblingOtherTable + strMDRTable);	
	}	
	
	public String getBirthHistoryRecord(String patid) throws RemoteException,SQLException{
		String qSql="SELECT * FROM a22 WHERE pat_id = '"+patid+"' order by entrydate desc";
	 	String BirthTable="", MaternalTable="", NeonatTable="",heading="";
	 	
	 	heading = "<Center><H3>Birth History</H3></Center>";
	 	
        BirthTable = "<table border='0' width='90%' align='center'><tr style='color:blue;font-weight:bold;font-size:12pt'><td>Birth History</td></tr>";
        BirthTable += "<tr><td><table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
        BirthTable += "<tr style='background-color:#D7FFD7'><th>Gestation</th><th>Delivery</th><th>Birth weight(gms)</th><th>Entry Date</th>";

        MaternalTable = "<table border='0' width='90%' align='center'><tr style='color:blue;font-weight:bold;font-size:12pt'><td>Maternal PMTCT</td></tr>";
        MaternalTable += "<tr><td><table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
        MaternalTable += "<tr style='background-color:#D7FFD7'><th>Antenatal</th><th>Duration</th><th>IntraPartum</th><th>Entry Date</th>";

        NeonatTable = "<table border='0' width='90%' align='center'><tr style='color:blue;font-weight:bold;font-size:12pt'><td>Neonatal PMTCT</td></tr>";
        NeonatTable += "<tr><td><table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
        NeonatTable += "<tr style='background-color:#D7FFD7'><th>No Prophylaxis</th><th>Single Dose NVP</th><th>Neonatal ARV</th><th>Duration</th><th>Entry Date</th>";
		  try{
        	Object res=mydb.ExecuteQuary(qSql);
 			if(res instanceof String){
				BirthTable= "Error : "+res;
			}else{
				Vector tmp = (Vector)res;
				if(tmp.size()>0){
					for(int ii=0;ii<tmp.size();ii++){
						dataobj tmpdata = (dataobj) tmp.get(ii);
						
						BirthTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        BirthTable += "<td>" + tmpdata.getValue(1) + "</td><td>" + tmpdata.getValue(2) + "</td><td>" + tmpdata.getValue(3) + "</td><td>" + myDate.mysql2ind(tmpdata.getValue(12)) + "</td>";
                        BirthTable += "</tr>";

                        MaternalTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        MaternalTable += "<td>" + tmpdata.getValue(4) + "</td><td>" + tmpdata.getValue(5) + "</td><td>" + tmpdata.getValue(6) + "</td><td>" + myDate.mysql2ind(tmpdata.getValue(12)) + "</td>";
                        MaternalTable += "</tr>";

                        NeonatTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        NeonatTable += "<td>" + tmpdata.getValue(7) + "</td><td>" + tmpdata.getValue(8) + "</td><td>" + tmpdata.getValue(9) + "</td><td>" + tmpdata.getValue(10) + "</td><td>" + myDate.mysql2ind(tmpdata.getValue(12)) + "</td>";
                        NeonatTable += "</tr>";
                        
						
					} //for
				}else{
					BirthTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='9'>No Data</td></tr>";
                    MaternalTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='9'>No Data</td></tr>";
                    NeonatTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='9'>No Data</td></tr>";
				}
			}//else
			
		}catch(Exception e){
			BirthTable=e.toString();	
		}
		
		BirthTable += "</table></td></tr></table>";
        MaternalTable += "</table></td></tr></table>";
        NeonatTable += "</table></td></tr></table>";
                
		
		 return (heading + BirthTable + MaternalTable + NeonatTable);
	 }
	
	public String getSocioEcoStatusRecord(String patid) throws RemoteException,SQLException{
		
		String qSql="SELECT * FROM a24 WHERE pat_id = '"+ patid +"' order by entrydate desc";
		String strTable = "";	
		strTable += "<Center><H3>SocioEconomic Status</H3></Center>";
	    strTable += "<table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
	    strTable += "<tr style='background-color:#D7FFD7'><th>Education</th><th>Occupation</th><th>Family Income(PM)</th><th>Class</th></th><th>Entry Date</th>";

        try{
	        Object res=mydb.ExecuteQuary(qSql);
 			if(res instanceof String){
				strTable= "Error : "+res;
			}else{
				Vector tmp = (Vector)res;
				if(tmp.size()>0){
					for(int ii=0;ii<tmp.size();ii++){
						dataobj tmpdata = (dataobj) tmp.get(ii);
						strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        strTable += "<td>" + tmpdata.getValue(1) + "</td>";
                        strTable += "<td>" + tmpdata.getValue(2) + "</td>";
                        strTable += "<td>" + tmpdata.getValue(3) + "</td>";
                        strTable += "<td>" + tmpdata.getValue(4) + "</td>";
                        strTable += "<td>" + myDate.mysql2ind(tmpdata.getValue(6)) + "</td>";
                        strTable += "</tr>";


					}
				}else{
					strTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='5'>No Data</td></tr>";
				}
			}
			
        }catch(Exception e){
			strTable=e.toString();	
		} 

		strTable += "</table>";
        return strTable;   
		
	}
	public String getSupportSystemRecord(String patid) throws RemoteException,SQLException{
		
		String qSql="SELECT * FROM a25 WHERE pat_id = '"+ patid +"' order by entrydate desc";
		String strTable = "";	
		strTable += "<Center><H3>Available Support System</H3></Center>";
        strTable += "<table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
        strTable += "<tr style='background-color:#D7FFD7'><th>Emotional</th><th>Comments</th><th>Financial</th><th>Comments</th><th>Other</th><th>Comments</th><th>Entry Date</th>";
		
		 try{
	        Object res=mydb.ExecuteQuary(qSql);
 			if(res instanceof String){
				strTable= "Error : "+res;
			}else{
				Vector tmp = (Vector)res;
				if(tmp.size()>0){
					for(int ii=0;ii<tmp.size();ii++){
						dataobj tmpdata = (dataobj) tmp.get(ii);
                        strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        strTable += "<td>" + tmpdata.getValue(1) + "</td>";
                        strTable += "<td>" + tmpdata.getValue(2) + "</td>";
                        strTable += "<td>" + tmpdata.getValue(3) + "</td>";
                        strTable += "<td>" + tmpdata.getValue(4) + "</td>";
                        strTable += "<td>" + tmpdata.getValue(5) + "</td>";
                        strTable += "<td>" + tmpdata.getValue(6) + "</td>";
                        strTable += "<td>" + myDate.mysql2ind(tmpdata.getValue(8)) + "</td>";
                        strTable += "</tr>";

					}
				}else{
					 strTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='7'>No Data</td></tr>";
				}
			}
			
        }catch(Exception e){
			strTable=e.toString();	
		} 
		
		strTable += "</table>";
        return strTable;   
	}
	public String getARTRecord(String patid) throws RemoteException,SQLException{
		
		String qSql="SELECT * FROM a26 WHERE pat_id = '"+ patid +"' order by entrydate desc";
		String strTable = "";	
		
        strTable += "<Center><H3>ART/PRE ART Adherence</H3></Center>";
        strTable += "<table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
        strTable += "<tr style='background-color:#D7FFD7'><th>Support System<br> Available</th><th>Comments</th><th>Financial</th><th>Comments</th><th>Emotional</th><th>Comments</th><th>Physical</th><th>Comments</th><th>Non Disclosure <br>at home</th><th>Comments</th><th>Occupational</th><th>Comments</th><th>Other</th><th>Comments</th><th>Entry Date</th></tr>";
		
		try{
	        Object res=mydb.ExecuteQuary(qSql);
 			if(res instanceof String){
				strTable= "Error : "+res;
			}else{
				Vector tmp = (Vector)res;
				if(tmp.size()>0){
					for(int ii=0;ii<tmp.size();ii++){
						dataobj tmpdata = (dataobj) tmp.get(ii);                       
                        strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        for (int i = 1; i < 15; i++)
                        {
                            strTable += "<td>" + tmpdata.getValue(i) + "</td>";
                        }
                        strTable += "<td>" + myDate.mysql2ind(tmpdata.getValue(16)) + "</td>";
                        strTable += "</tr>";
					}
				}else{
                    strTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='15'>No Data</td></tr>";
				}
			}
			
        }catch(Exception e){
			strTable=e.toString();	
		} 
		
		strTable += "</table>";
        return strTable; 
	}
	public String getHIVExposedRecord(String patid) throws RemoteException,SQLException{
		
		
		
		String qSql="SELECT * FROM a27 WHERE pat_id = '"+ patid +"' order by entrydate desc";
		String strHeading="",tableExposure="", tableTesting="", tableFeeding="";	
		
		strHeading = "<Center><H3>HIV Exposed Child</H3></Center>";
             
        tableExposure = "<label style='color:blue;font-weight:bold;font-size:12pt'>Type of Exposure</label><table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
        tableTesting = "<label style='color:blue;font-weight:bold;font-size:12pt'>Current Testing</label><table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
        tableFeeding = "<table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";

        tableExposure += "<tr style='background-color:#D7FFD7'><th>Maternal HIV</th><th>Comments</th><th>Blood Transfusion</th><th>Comments</th><th>Other</th><th>Comments</th></tr>";
        tableTesting += "<tr style='background-color:#D7FFD7'><th>Age at Test(Months)</th><th>Type of Test</th><th>Result</th></tr>";
        tableFeeding += "<tr style='background-color:#D7FFD7'><th>Breast Feeding</th><th>Comments</th></tr>";
		
		try{
	        Object res=mydb.ExecuteQuary(qSql);
 			if(res instanceof String){
				tableExposure= "Error : "+res;
			}else{
				Vector tmp = (Vector)res;
				if(tmp.size()>0){
					for(int ii=0;ii<tmp.size();ii++){
						dataobj tmpdata = (dataobj) tmp.get(ii);                       
                       
                       
                       tableExposure += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        tableTesting += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        tableFeeding += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";

                        for (int i = 1; i < 7; i++)
                            tableExposure += "<td>" + tmpdata.getValue(i) + "</td>";

                        tableTesting += "<td>" + tmpdata.getValue(7) + "</td>";
                        tableTesting += "<td>" + tmpdata.getValue(8) + "</td>";
                        tableTesting += "<td>" + tmpdata.getValue(9) + "</td>";

                        tableFeeding += "<td>" + tmpdata.getValue(11) + "</td>";
                        tableFeeding += "<td>" + tmpdata.getValue(12) + "</td>";

                        tableExposure += "</tr>";
                        tableTesting += "</tr>";
                        tableFeeding += "</tr>";
					}
				}else{
                    tableExposure += "<tr style='background-color:#FFFFFF'><td align='center' colspan='6'>No Data</td></tr>";
                    tableTesting += "<tr style='background-color:#FFFFFF'><td align='center' colspan='3'>No Data</td></tr>";
                    tableFeeding += "<tr style='background-color:#FFFFFF'><td align='center' colspan='2'>No Data</td></tr>";

				}
			}
			
        }catch(Exception e){
			tableExposure=e.toString();	
		} 
		
		tableExposure += "</table><br>";
        tableTesting += "</table><br>";
        tableFeeding += "</table>";
        return (strHeading+tableExposure + tableTesting + tableFeeding);
	}
	
	public String getAdherenceRecord(String patid) throws RemoteException,SQLException{
	
		String qSql="SELECT * FROM a28 WHERE pat_id = '"+ patid +"' order by entrydate desc";
		String strTable = "";	
		
        strTable += "<Center><H3>Adherence</H3></Center>";
        strTable += "<table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
        strTable += "<tr style='background-color:#D7FFD7'><th>Reason for missing dose?</th><th>Comments</th><th>Entry Date</th>";
		
		try{
	        Object res=mydb.ExecuteQuary(qSql);
 			if(res instanceof String){
				strTable= "Error : "+res;
			}else{
				Vector tmp = (Vector)res;
				if(tmp.size()>0){
					for(int ii=0;ii<tmp.size();ii++){
						dataobj tmpdata = (dataobj) tmp.get(ii);                       

                        strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        strTable += "<td>" + tmpdata.getValue(1) + "</td>";
                        strTable += "<td>" + tmpdata.getValue(2) + "</td>";
                        strTable += "<td>" + myDate.mysql2ind(tmpdata.getValue(4)) + "</td>";
                        strTable += "</tr>";
					}
				}else{
                     strTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='4'>No Data</td></tr>";
				}
			}
			
        }catch(Exception e){
			strTable=e.toString();	
		} 
		
		strTable += "</table>";
        return strTable; 
       
	}
	public String getSocialHistoryRecord(String patid) throws RemoteException,SQLException{
	  
	  	String qSql="SELECT * FROM a29 WHERE pat_id = '"+ patid +"' order by entrydate desc";
		String strTable = "";	
	    strTable += "<Center><H3>Social History</H3></Center>";
        
        //strTable += "<table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
        //strTable += "<tr style='background-color:#D7FFD7'><th>Emotional</th><th>Comments</th><th>Financial</th><th>Comments</th><th>Other</th><th>Comments</th><th>Entry Date</th>";
		try{
	        Object res=mydb.ExecuteQuary(qSql);
 			if(res instanceof String){
				strTable= "Error : "+res;
			}else{
				Vector tmp = (Vector)res;
				if(tmp.size()>0){
					for(int ii=0;ii<tmp.size();ii++){
						dataobj tmpdata = (dataobj) tmp.get(ii);                       
						
						strTable += "<table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
                        strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        strTable += "<td>Who is the child's primary care giver?</td><td>" + tmpdata.getValue(1) + "</td></tr>";
                        strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'><td>Is mother living?</td><td>" + tmpdata.getValue(2) + "</td><tr>";
                        strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'><td>Is mother HIV Positive?</td><td>" + tmpdata.getValue(3) + "</td><tr>";
                        strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'><td>How is mother's Health?</td><td>" + tmpdata.getValue(4) + "</td><tr>";
                        strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'><td>Is father living?</td><td>" + tmpdata.getValue(5) + "</td><tr>";
                        strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'><td>Is father HIV Positive?</td><td>" + tmpdata.getValue(6) + "</td><tr>";
                        strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'><td>How is father's Health?</td><td>" + tmpdata.getValue(7) + "</td><tr>";
                        strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'><td>Who lives in the <br>home with the child?</td><td>" + tmpdata.getValue(8) + "," + tmpdata.getValue(9) + "," + tmpdata.getValue(10) + "</td><tr>";
                        strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'><td>Have the sibling been tested?</td><td>" + tmpdata.getValue(11) + "</td><tr>";
                        strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'><td>Does the child go to school?</td><td>" + tmpdata.getValue(13) + "</td><tr>";
                        strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'><td>What type of water <br>is needed to bath child?</td><td>" + tmpdata.getValue(14) + "</td><tr>";
                        strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'><td>Entry Date</td><td>" + myDate.mysql2ind(tmpdata.getValue(16)) + "</td>";
                        strTable += "</tr>";
                        strTable += "</table><br>";
                        
					}
				}else{
                    strTable += "<table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
                    strTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='2'>No Data</td></tr>";
                    strTable += "</table>";
				}
			}
			
        }catch(Exception e){
			strTable=e.toString();	
		} 
		
        return strTable; 
 }
 
 
 public String getDevelopmentMilestonesRecord(String patid) throws RemoteException,SQLException{
 
  	String qSql= "SELECT * FROM a23 WHERE pat_id = '"+ patid +"' order by entrydate desc";
  	String strTable = "";	
    strTable += "<table border='0' width='90%' align='center'>";
    strTable += "<tr><td><table  align='center' width='100%' cellspacing='1' cellpadding='5' style='background-color:#CECEFF;'>";
    strTable += "<tr style='background-color:#D7FFD7'><th>Age of Assesment</th><th>Gross Motor</th><th>Age</th><th>Visual Motor</th><th>Age</th><th>Language</th><th>Age</th><th>Social/Adaptive</th><th>Age</th></tr>";
	
	try{
	        Object res=mydb.ExecuteQuary(qSql);
 			if(res instanceof String){
				strTable= "Error : "+res;
			}else{
				Vector tmp = (Vector)res;
				if(tmp.size()>0){
					for(int ii=0;ii<tmp.size();ii++){
						dataobj tmpdata = (dataobj) tmp.get(ii);                       
                        strTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        strTable += "<td>" + tmpdata.getValue(1) + "</td><td>" + tmpdata.getValue(2) + "</td><td>" + tmpdata.getValue(3) + "</td><td>" + tmpdata.getValue(4) + "</td><td>" + tmpdata.getValue(5) + "</td>";
                        strTable += "<td>" + tmpdata.getValue(6) + "</td><td>" + tmpdata.getValue(7) + "</td><td>" + tmpdata.getValue(8) + "</td><td>" + tmpdata.getValue(9) + "</td>";
                        strTable += "</tr>";
					}
				}else{
                      strTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='9'>No Data</td></tr>";
				}
			}
			
        }catch(Exception e){
			strTable=e.toString();	
		} 
		
		strTable += "</table>";
        return strTable; 
    
 }
 
 public String getPlanRecord(String patid) throws RemoteException,SQLException{
 	
 	 String qSql = "SELECT * FROM a42 WHERE PAT_ID = '"+patid+"' order by entrydate desc";
 	 String ProbTable="", MedicationTable="", LabTable="",CounselTable="", heading="";
 	 //heading = "<Center><H3>PLAN</H3></Center>";
    ProbTable = "<table border='0' width='90%' align='center'><tr style='color:blue;font-weight:bold;font-size:12pt'><td>Treatment Of Problem</td></tr>";
    ProbTable += "<tr><td><table  align='center' width='100%' cellspacing='1' cellpadding='2' style='background-color:#CECEFF;'>";
    ProbTable += "<tr style='background-color:#D7FFD7'><th>Treatment <br>of Problem</th><th>Notes</th><th>Entry Date</th>";

    MedicationTable = "<table border='0' width='90%' align='center'><tr style='color:blue;font-weight:bold;font-size:12pt'><td>Medication</td></tr>";
    MedicationTable += "<tr><td><table  align='center' width='100%' cellspacing='1' cellpadding='2' style='background-color:#CECEFF;'>";
    MedicationTable += "<tr style='background-color:#D7FFD7'><th>Cotrimoxazole</th><th>Antitubercular</th><th>ART</th><th>Notes</th><th>Entry Date</th>";

    LabTable = "<table border='0' width='90%' align='center'><tr style='color:blue;font-weight:bold;font-size:12pt'><td>Laboratory Testing</td></tr>";
    LabTable += "<tr><td><table  align='center' width='100%' cellspacing='1' cellpadding='2' style='background-color:#CECEFF;'>";
    LabTable += "<tr style='background-color:#D7FFD7'><th>CD4</th><th>Other</th><th>Notes</th><th>Entry Date</th>";

    CounselTable = "<table border='0' width='90%' align='center'><tr style='color:blue;font-weight:bold;font-size:12pt'><td></tr>";
    CounselTable += "<tr><td><table  align='center' width='100%' cellspacing='1' cellpadding='2' style='background-color:#CECEFF;'>";
    CounselTable += "<tr style='background-color:#D7FFD7'><th>Counseling</th><th>Note</th><th>Return to <br>clinic one month</th><th>Entry Date</th>";
 	try{
 		Object res=mydb.ExecuteQuary(qSql);
 			if(res instanceof String){
				heading= "Error : "+res;
			}else{
				Vector tmp = (Vector)res;
				if(tmp.size()>0){
					for(int ii=0;ii<tmp.size();ii++){
						dataobj tmpdata = (dataobj) tmp.get(ii); 
						
						
						ProbTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        ProbTable += "<td>" + tmpdata.getValue(1) + "</td><td>" + tmpdata.getValue(2) + "</td><td>" + myDate.mysql2ind(tmpdata.getValue(14)) + "</td>";
                        ProbTable += "</tr>";

                        MedicationTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        MedicationTable += "<td>" + tmpdata.getValue(3) + "</td><td>" + tmpdata.getValue(4) + "</td><td>" + tmpdata.getValue(5) + "</td><td>" + tmpdata.getValue(6) + "</td><td>" + myDate.mysql2ind(tmpdata.getValue(14)) + "</td>";
                        MedicationTable += "</tr>";

                        LabTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        LabTable += "<td>" + tmpdata.getValue(7) + "</td><td>" + tmpdata.getValue(8) + "</td><td>" + tmpdata.getValue(9) + "</td><td>" + myDate.mysql2ind(tmpdata.getValue(14)) + "</td>";
                        LabTable += "</tr>";

                        CounselTable += "<tr style='background-color:#FEFEF2;border:1px solid #880088'>";
                        CounselTable += "<td>" + tmpdata.getValue(10) + "</td><td>" + tmpdata.getValue(11) + "</td><td>" + tmpdata.getValue(12) + "</td><td>" + myDate.mysql2ind(tmpdata.getValue(14)) + "</td>";
                        CounselTable += "</tr>";
                        
                        
					}
				}else{
                    ProbTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='9'>No Data</td></tr>";
                    MedicationTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='9'>No Data</td></tr>";
                    LabTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='9'>No Data</td></tr>";
                    CounselTable += "<tr style='background-color:#FFFFFF'><td align='center' colspan='9'>No Data</td></tr>";
                }
                ProbTable += "</table></td></tr></table>";
                MedicationTable += "</table></td></tr></table>";
                LabTable += "</table></td></tr></table>";
                CounselTable += "</table></td></tr></table>";
			}
			 		
 		}catch(Exception e){
			heading=e.toString();	
		} 
		return (heading + ProbTable + MedicationTable + LabTable + CounselTable);
	
        }

	public String getDataJSON(String pat_id,String tableName,String date,String nextDate) throws RemoteException,SQLException{

		String sql="select * from "+tableName+" where pat_id='"+pat_id+"' and DATE(entrydate)>=DATE('"+date+"') and DATE(entrydate)<DATE('"+nextDate+"')";
		
		String result="";
		System.out.println(sql);
		try{
			Object obj = mydb.ExecuteQuary(sql);
			if(obj instanceof String){
				result="Error 7332 : "+obj;
			}
			else{
				Vector rs = (Vector)obj;
				int rs_size = rs.size();
				if(rs_size>0){
					dataobj firstobj= (dataobj) rs.get(0);
					result="{\"pat_id\":\""+pat_id+"\",\"opdno\":\""+firstobj.getValue("opdno")+"\",";
					for(int i=0;i<rs_size;i++){
						dataobj data= (dataobj) rs.get(i);
						if(i<rs_size-1)
							result +="\""+i+"\":{\"test_id\":\""+data.getValue("test_id")+"\",\"studyUID\":\""+data.getValue("studyUID")+"\",\"test_name\":\""+data.getValue("test_name")+"\",\"description\":\""+data.getValue("description")+"\",\"type\":\""+data.getValue("type")+"\",\"status\":\""+data.getValue("status")+"\",\"entrydate\":\""+data.getValue("entrydate")+"\",\"reffered_by\":\""+data.getValue("reffered_by")+"\"},";
						else
							result +="\""+i+"\":{\"test_id\":\""+data.getValue("test_id")+"\",\"studyUID\":\""+data.getValue("studyUID")+"\",\"test_name\":\""+data.getValue("test_name")+"\",\"description\":\""+data.getValue("description")+"\",\"type\":\""+data.getValue("type")+"\",\"status\":\""+data.getValue("status")+"\",\"entrydate\":\""+data.getValue("entrydate")+"\",\"reffered_by\":\""+data.getValue("reffered_by")+"\"}";
						
					}
					result +="}";
					System.out.println(result+"\n\n");
				}
				
			}
		}catch(Exception ex){System.out.println("Error09558 : "+ex.toString());}
	return result;
	}
	public String pendingStudyUID(String pat_id,String extra) throws RemoteException,SQLException{
		
		String query="";
		//System.out.println(extra);
		String extraParam[] = extra.split("#");
		String type ="",fromDate = "",toDate="",ccode="XXXX@XXX",extraQuery="",patName="",phone="";
		if(extraParam.length>=6){
			type = extraParam[0];
			fromDate = extraParam[1];
			toDate = extraParam[2];
			ccode = extraParam[5];
			patName = extraParam[3];
			phone = extraParam[4];
			if(ccode == null || ccode.trim().isEmpty() || ccode.equalsIgnoreCase("null") || ccode.equalsIgnoreCase("XXXX"))
				ccode = "";
		}
		else{System.out.println("ERROR : Check all parameter and length");}
		if(pat_id != null && !pat_id.trim().isEmpty()){
			if(type.length()>4)
				extraQuery += " and type = '"+type+"'";
			if(fromDate.length()>9 && toDate.length()>9)
				extraQuery += " and (DATE(entrydate) between '"+fromDate+"' and '"+toDate+"')";
			if(ccode.length()==8)
				extraQuery += " and pat_id like '%"+ccode+"%'";
				
			query = "SELECT *,(select concat(COALESCE(pat_name,''),' ',COALESCE(m_name,''),' ',COALESCE(l_name,'')) from med where med.pat_id=ai0.pat_id) as patName,(select phone from login where uid = '"+pat_id+"') as Phone FROM ai0 where status='P' and pat_id = '"+pat_id+"'"+extraQuery+" limit 0,3000";
		}
		else if(phone.length()>9)
		{
			String daterange ="";
			
			if(fromDate.length()>9 && toDate.length()>9)
				daterange += " and (DATE(entrydate) between '"+fromDate+"' and '"+toDate+"')";
			if(type.length()>4)
				daterange += " and ai0.type = '"+type+"'";
			
			daterange += " and pat_id in (select uid from login where phone ='"+phone+"')"; 		
			
			//query = "SELECT *,(select concat(COALESCE(pat_name,''),' ',COALESCE(m_name,''),' ',COALESCE(l_name,'')) from med where med.pat_id=ai0.pat_id) as patName,(select phone from med where med.pat_id=ai0.pat_id) as phone FROM ai0 where status='P'"+daterange+" and pat_id like '"+ccode+"%' limit 0,3000";
			query = "SELECT *,(select concat(COALESCE(pat_name,''),' ',COALESCE(m_name,''),' ',COALESCE(l_name,'')) from med where med.pat_id=ai0.pat_id) as patName,(select phone from login where login.uid=ai0.pat_id) as Phone FROM ai0,login where status='P'"+daterange+" and login.uid=ai0.reffered_by and login.center like '"+ccode+"%' limit 0,3000";
			query = "SELECT *,(select concat(COALESCE(pat_name,''),' ',COALESCE(m_name,''),' ',COALESCE(l_name,'')) from med where med.pat_id=ai0.pat_id) as patName,(select phone from login where login.uid=ai0.pat_id) as Phone FROM ai0 where status='P' "+daterange+" limit 0,3000";
		}
		else{
			String daterange ="";
			
			if(fromDate.length()>9 && toDate.length()>9)
				daterange += " and (DATE(entrydate) between '"+fromDate+"' and '"+toDate+"')";
			if(type.length()>4)
				daterange += " and ai0.type = '"+type+"'";
			if(patName.length()>=3)
				daterange += " and pat_id in (select pat_id from med where pat_name like '"+patName+"%' or m_name like '"+patName+"%' or l_name like '"+patName+"%')"; 	

			//query = "SELECT *,(select concat(COALESCE(pat_name,''),' ',COALESCE(m_name,''),' ',COALESCE(l_name,'')) from med where med.pat_id=ai0.pat_id) as patName,(select phone from med where med.pat_id=ai0.pat_id) as phone FROM ai0 where status='P'"+daterange+" and pat_id like '"+ccode+"%' limit 0,3000";
			query = "SELECT *,(select concat(COALESCE(pat_name,''),' ',COALESCE(m_name,''),' ',COALESCE(l_name,'')) from med where med.pat_id=ai0.pat_id) as patName,(select phone from login where login.uid=ai0.pat_id) as Phone FROM ai0,login where status='P'"+daterange+" and login.uid=ai0.reffered_by and login.center like '"+ccode+"%' limit 0,3000";
			}
		
		String result="";
		System.out.println(query);
		try{
			Object obj = mydb.ExecuteQuary(query);
			if(obj instanceof String){
				result = "Error 200393 : "+obj;
			}
			else{
				Vector rs = (Vector)obj;
				int rs_size = rs.size();
				if(rs_size>0){
					JSONObject json = new JSONObject();
					json.put("pat_id", pat_id);
					for(int i=0;i<rs_size;i++){
						dataobj data = (dataobj) rs.get(i);
						JSONArray array = new JSONArray();
						JSONObject item = new JSONObject();
						item.put("testId", data.getValue("test_id"));
						item.put("test_name", data.getValue("test_name"));
						item.put("description", data.getValue("description"));
						item.put("type", data.getValue("type"));
						item.put("status", data.getValue("status"));
						item.put("entrydate", data.getValue("entrydate"));
						item.put("reffered_by", data.getValue("reffered_by"));
						item.put("patName", data.getValue("patName"));
						item.put("phone", data.getValue("Phone"));
						//array.put(item);

						item.put("pat_id",data.getValue("pat_id")); //Soumya_B

						json.put(i, item);
					}
					result = json.toString();
				}
			}
		}catch(Exception ex){result = "ERR 022521 : "+ex.toString();}
		return result;
	}
	public String patWisePendingStudyUID(String pat_id,String extra) throws RemoteException,SQLException{
		
		String query="";
		//System.out.println(extra);		
		String extraParam[] = extra.split("#");
		String type ="",fromDate = "",toDate="",ccode="XXXX@XXX",extraQuery="",patName="",phone="";
		if(extraParam.length>=6){
			type = extraParam[0];
			fromDate = extraParam[1];
			toDate = extraParam[2];
			ccode = extraParam[5];
			patName = extraParam[3];
			phone = extraParam[4];
			if(ccode == null || ccode.trim().isEmpty() || ccode.equalsIgnoreCase("null") || ccode.equalsIgnoreCase("XXXX"))
				ccode = "";
		}
		else{System.out.println("ERROR : Check all parameter and length");}
		if(pat_id != null && !pat_id.trim().isEmpty()){
			if(type.length()>4)
				extraQuery += " and type = '"+type+"'";
			if(fromDate.length()>9 && toDate.length()>9)
				extraQuery += " and (DATE(entrydate) between '"+fromDate+"' and '"+toDate+"')";
			if(ccode.length()==8)
				extraQuery += " and pat_id like '%"+ccode+"%'";
				
			query = "SELECT *,(select concat(COALESCE(pat_name,''),' ',COALESCE(m_name,''),' ',COALESCE(l_name,'')) from med where med.pat_id=ai0.pat_id) as patName,(select phone from login where uid = '"+pat_id+"') as Phone FROM ai0 where status='P' and pat_id = '"+pat_id+"'"+extraQuery+" group by pat_id limit 0,3000";
		}
		else if(phone.length()>9)
		{
			String daterange ="";
			
			if(fromDate.length()>9 && toDate.length()>9)
				daterange += " and (DATE(entrydate) between '"+fromDate+"' and '"+toDate+"')";
			if(type.length()>4)
				daterange += " and ai0.type = '"+type+"'";
			
			daterange += " and pat_id in (select uid from login where phone ='"+phone+"')"; 		
			
			//query = "SELECT *,(select concat(COALESCE(pat_name,''),' ',COALESCE(m_name,''),' ',COALESCE(l_name,'')) from med where med.pat_id=ai0.pat_id) as patName,(select phone from med where med.pat_id=ai0.pat_id) as phone FROM ai0 where status='P'"+daterange+" and pat_id like '"+ccode+"%' group by opdno limit 0,3000";
			query = "SELECT ai0.pat_id,MAX(ai0.opdno) as opdno,(select concat(COALESCE(pat_name,''),' ',COALESCE(m_name,''),' ',COALESCE(l_name,'')) from med where med.pat_id=ai0.pat_id) as patName,(select phone from login where login.uid=ai0.pat_id) as Phone FROM ai0,login where status='P'"+daterange+" and login.uid=ai0.reffered_by and login.center like '"+ccode+"%' group by ai0.pat_id limit 0,3000";
		}
		else{
			String daterange ="";
			
			if(fromDate.length()>9 && toDate.length()>9)
				daterange += " and (DATE(entrydate) between '"+fromDate+"' and '"+toDate+"')";
			if(type.length()>4)
				daterange += " and ai0.type = '"+type+"'";
			if(patName.length()>=3)
				daterange += " and pat_id in (select pat_id from med where pat_name like '"+patName+"%' or m_name like '"+patName+"%' or l_name like '"+patName+"%')"; 	
			
			//query = "SELECT *,(select concat(COALESCE(pat_name,''),' ',COALESCE(m_name,''),' ',COALESCE(l_name,'')) from med where med.pat_id=ai0.pat_id) as patName,(select phone from med where med.pat_id=ai0.pat_id) as phone FROM ai0 where status='P'"+daterange+" and pat_id like '"+ccode+"%' group by opdno limit 0,3000";
			query = "SELECT ai0.pat_id,MAX(ai0.opdno) as opdno,(select concat(COALESCE(pat_name,''),' ',COALESCE(m_name,''),' ',COALESCE(l_name,'')) from med where med.pat_id=ai0.pat_id) as patName,(select phone from login where login.uid=ai0.pat_id) as Phone FROM ai0,login where status='P'"+daterange+" and login.uid=ai0.reffered_by and login.center like '"+ccode+"%' group by ai0.pat_id limit 0,3000";
			}
		
		String result="";
		System.out.println(query);
		try{
			Object obj = mydb.ExecuteQuary(query);
			if(obj instanceof String){
				result = "Error 200393 : "+obj;
			}
			else{
				Vector rs = (Vector)obj;
				int rs_size = rs.size();
				int count=0;
				if(rs_size>0){
					JSONObject json = new JSONObject();
					
					//json.put("pat_id", pat_id);
					for(int i=0;i<rs_size;i++){

						dataobj data = (dataobj) rs.get(i);
						JSONArray array = new JSONArray();
						JSONObject item = new JSONObject();

						String pid=data.getValue("pat_id");
						String cnt="select count(*) from ai0 where pat_id = '"+pid +"' and type='"+type+"' and status='P'";
						String nofp = mydb.ExecuteSingle(cnt);
						int no_of_pat = 0;
						try{
							no_of_pat = Integer.parseInt(nofp);
						}catch(Exception ex){no_of_pat=0;}

						if(no_of_pat>0){
						
						item.put("opdno", data.getValue("opdno"));
						item.put("patId", data.getValue("pat_id"));
						item.put("phone", data.getValue("Phone"));

						item.put("patName", data.getValue("patName"));
						//array.put(item);

						json.put(count, item);
						count++;
						}
					}
					result = json.toString();
				}
			}
		}catch(Exception ex){result = "ERR 022521 : "+ex.toString();}
		return result;
	}
	public String getPendingStudyList(String opdno) throws RemoteException,SQLException{
		String result="";
		String sql = "SELECT *,(select concat(COALESCE(pat_name,''),' ',COALESCE(m_name,''),' ',COALESCE(l_name,'')) from med where med.pat_id=ai0.pat_id) as patName FROM ai0 where status='P' and opdno='"+opdno+"'";
		System.out.println("getPendingStudyList(String opdno) : "+sql);
		try{
			Object obj = mydb.ExecuteQuary(sql);
			if(obj instanceof String){
				result = "Error 200393 : "+obj;
			}
			else{
				Vector rs = (Vector)obj;
				int rs_size = rs.size();
				if(rs_size>0){
					JSONObject json = new JSONObject();
					json.put("opdno", opdno);
					for(int i=0;i<rs_size;i++){
						dataobj data = (dataobj) rs.get(i);
						JSONArray array = new JSONArray();
						JSONObject item = new JSONObject();
						item.put("testId", data.getValue("test_id"));
						item.put("test_name", data.getValue("test_name"));
						item.put("description", data.getValue("description"));
						item.put("type", data.getValue("type"));
						item.put("status", data.getValue("status"));
						item.put("entrydate", data.getValue("entrydate"));
						item.put("reffered_by", data.getValue("reffered_by"));
						item.put("isReport", data.getValue("isReport"));
						item.put("isNote", data.getValue("isNote"));
						item.put("studyUID", data.getValue("studyUID"));
						item.put("patName", data.getValue("patName"));
						//array.put(item);

						json.put(i, item);
					}
					result = json.toString();
				}
				else{
					result = "{}";
					}
			}

			}catch(Exception ex){System.out.println("Err456780 : "+ex.toString());result="{}";}
		return result;
	}
	/*Soumyajit Das*/
	public String getPendingStudyListPAT(String opdno,String patid) throws RemoteException,SQLException{
		String result="";
		String sql = "SELECT *,(select concat(COALESCE(pat_name,''),' ',COALESCE(m_name,''),' ',COALESCE(l_name,'')) from med where med.pat_id=ai0.pat_id) as patName,(select phone from login where uid='"+patid+"') as phone FROM ai0 where status='P' and pat_id='"+patid+"'";
		System.out.println("getPendingStudyListPAT(String opdno,String patid) : "+sql);
		try{
			Object obj = mydb.ExecuteQuary(sql);
			if(obj instanceof String){
				result = "Error 200393 : "+obj;
			}
			else{
				Vector rs = (Vector)obj;
				int rs_size = rs.size();
				if(rs_size>0){
					JSONObject json = new JSONObject();
					json.put("opdno", opdno);
					for(int i=0;i<rs_size;i++){
						dataobj data = (dataobj) rs.get(i);
						JSONArray array = new JSONArray();
						JSONObject item = new JSONObject();
						item.put("testId", data.getValue("test_id"));
						item.put("test_name", data.getValue("test_name"));
						item.put("description", data.getValue("description"));
						item.put("type", data.getValue("type"));
						item.put("status", data.getValue("status"));
						item.put("entrydate", data.getValue("entrydate"));
						item.put("reffered_by", data.getValue("reffered_by"));
						item.put("isReport", data.getValue("isReport"));
						item.put("isNote", data.getValue("isNote"));
						item.put("studyUID", data.getValue("studyUID"));
						item.put("patName", data.getValue("patName"));
						item.put("phone", data.getValue("phone"));
						//array.put(item);

						json.put(i, item);
					}
					result = json.toString();
				}
				else{
					result = "{}";
					}
			}
				
		}catch(Exception ex){System.out.println("Err456780 : "+ex.toString());result="{}";}
		return result;
	}	
	public ArrayList getSyncedStudyIDList(String opdno) throws RemoteException,SQLException{
		ArrayList<String> result = new ArrayList<String>();
		String sql = "select * from ai0 where opdno = '"+opdno+"' and (studyUID != '' or studyUID != NULL or status='P')";
		System.out.println("getSyncedStudyList(String opdno) : "+sql);
		try{
			Object obj = mydb.ExecuteQuary(sql);
			if(obj instanceof String){
				System.out.println("Error 200393 : "+obj);
			}
			else{
				Vector rs = (Vector)obj;
				int rs_size = rs.size();
				if(rs_size>0){
					for(int i=0;i<rs_size;i++){
						dataobj data = (dataobj) rs.get(i);
						result.add(i, data.getValue("studyUID"));
					}
				}
			}
						
		}catch(Exception ex){System.out.println("Err456780 : "+ex.toString());}
		return result;
	}

	
 	public String activeStudyUID(String pat_id,String extra){		
		String extraParam[] = extra.split("#");
		String type ="",fromDate = "",toDate="",extraQuery="";
		if(extraParam.length>=3){
			type = extraParam[0];
			fromDate = extraParam[1];
			toDate = extraParam[2];
		}
		
		if(type.length()>4)
			extraQuery += " and type = '"+type+"'";
		if(fromDate.length()>9 && toDate.length()>9)
			extraQuery += "  and (DATE(entrydate) between '"+fromDate+"' and '"+toDate+"')";

		
		String query = "SELECT *,(select concat(COALESCE(pat_name,''),' ',COALESCE(m_name,''),' ',COALESCE(l_name,'')) from med where med.pat_id=ai0.pat_id) as patName FROM ai0 where status='A' and pat_id = '"+pat_id+"'"+extraQuery;
		String result="";
		System.out.println(query);
		try{
			Object obj = mydb.ExecuteQuary(query);
			if(obj instanceof String){
				result = "Error 200393 : "+obj;
			}
			else{
				Vector rs = (Vector)obj;
				int rs_size = rs.size();
				if(rs_size>0){
					JSONObject json = new JSONObject();
					json.put("pat_id", pat_id);
					for(int i=0;i<rs_size;i++){
						dataobj data = (dataobj) rs.get(i);
						JSONArray array = new JSONArray();
						JSONObject item = new JSONObject();
						item.put("testId", data.getValue("test_id"));
						item.put("test_name", data.getValue("test_name"));
						item.put("description", data.getValue("description"));
						item.put("type", data.getValue("type"));
						item.put("status", data.getValue("status"));
						item.put("entrydate", data.getValue("entrydate"));
						item.put("reffered_by", data.getValue("reffered_by"));
						item.put("isReport", data.getValue("isReport"));
						item.put("isNote", data.getValue("isNote"));
						item.put("studyUID", data.getValue("studyUID"));
						item.put("patName", data.getValue("patName"));
						//array.put(item);

						json.put(i, item);
					}
					result = json.toString();
				}
			}
		}catch(Exception ex){result = "ERR 022521 : "+ex.toString();}
		return result;
	}
	public boolean isReport(String studyUID){
		String query = "select count(*) from ai0 where studyUID='"+studyUID+"' and isReport='1'";
		String nofp = mydb.ExecuteSingle(query);
		System.out.println(query);
		int no_of_pat = 0;
		try{
			no_of_pat = Integer.parseInt(nofp);
		}catch(Exception ex){no_of_pat=0;}
		if(no_of_pat > 0)
			return true;
		else
			return false;		
	}
	public boolean isNote(String studyUID){
		String query = "select count(*) from ai0 where studyUID='"+studyUID+"' and isNote='1'";
		System.out.println(query);
		String nofp = mydb.ExecuteSingle(query);
		int no_of_pat = 0;
		try{
			no_of_pat = Integer.parseInt(nofp);
		}catch(Exception ex){no_of_pat=0;}
		if(no_of_pat > 0)
			return true;
		else
			return false;		
	}
	public String getPathoData(String test_id) throws RemoteException,SQLException{
		String sql = "select pat_id,fileId,ext,type,size,description,entrydate from pathoData where test_id='"+test_id+"'";
		String result="";
		System.out.println(sql);
		try{
			Object obj = mydb.ExecuteQuary(sql);
			if(obj instanceof String){
				result = "Error 200393 : "+obj;
			}
			else{
				Vector rs = (Vector)obj;
				int rs_size = rs.size();
				if(rs_size>0){
					JSONObject json = new JSONObject();
					json.put("test_id", test_id);
					for(int i=0;i<rs_size;i++){
						dataobj data = (dataobj) rs.get(i);
						JSONArray array = new JSONArray();
						JSONObject item = new JSONObject();
						item.put("fileId", data.getValue("fileId"));
						item.put("ext", data.getValue("ext"));
						item.put("description", data.getValue("description"));
						item.put("type", data.getValue("type"));
						item.put("size", data.getValue("size"));
						item.put("entrydate", data.getValue("entrydate"));
						//array.put(item);

						json.put(i, item);
					}
					result = json.toString();
				}
			}
		}catch(Exception ex){result = "ERR 022521 : "+ex.toString();}
		return result;		
	}
	public byte[] getPathoData(String test_id, String fileId)throws RemoteException,SQLException {
         String qSql= "select rawData from pathoData where test_id = '"+test_id+"' and fileId = '"+fileId+"'";
       //System.out.println("Image :" + qSql);             
        //dball mydb= new dball(pinfo);
        return mydb.ExecuteImage(qSql);
    }
    
    public Object latestData(String pat_id,String tableName)throws RemoteException,SQLException{
		String sql = "select * from "+tableName+" where pat_id='"+pat_id+"' order by entrydate desc limit 0,1";
		System.out.println("latestData() : "+sql);
		 return mydb.ExecuteQuary(sql);
	} 
	public Object requestConsultantQueue(String centerid) throws RemoteException,SQLException{
		String sql = "select distinct(c.pat_id) as pat_id,c.centerid as centerid,c.dept as dept, name, emailid from consultrequest c inner join login l on l.uid = c.pat_id where centerid='"+centerid+"' and requested='Y'";
		System.out.println("SQL = "+sql);
 	    return mydb.ExecuteQuary(sql);
	}
	/*Soumyajit Das*/	
	public Object getDrugListIMEDIX() throws RemoteException, SQLException{
		//String sql = "select * from druglist";
		String sql = "select * from druglist where drug_name!=''";
		System.out.println("getDrugListIMEDIX()> "+sql);
		return mydb.ExecuteQuary(sql);
	}
	/*Soumyajit Das*/
	public Object getDrugListIMEDIX(String ccode) throws RemoteException, SQLException{
		//String sql = "select * from druglist";
	String sql = "select * from druglist where drug_name!='' and drug_name not in (select drug_name from druglistbycenter where ccode='"+ccode+"')";
		System.out.println("getDrugListIMEDIX(ccode)> "+sql);
		return mydb.ExecuteQuary(sql);
	}
	/*Soumyajit Das*/
	public Object getDrugList(String name) throws RemoteException, SQLException{
		String sql = "select * from druglist where drug_name like '%"+name+"%'";
		System.out.println("getDrugList()> "+sql);
		return mydb.ExecuteQuary(sql);
	}
	/*Soumyajit Das*/
	public Object getDrugListDefault() throws RemoteException, SQLException{
		String sql = "select * from druglist";
		System.out.println("getDrugList()> "+sql);
		return mydb.ExecuteQuary(sql);
	}
	/*Soumyajit Das*/
	public Object getDrugListByCenter(String ccode) throws RemoteException, SQLException{
		//String sql = "select * from druglist where drug_name like '%"+name+"%'";
		String sql = "select * from druglistbycenter where ccode='"+ccode+"' and active=1";
		System.out.println("getDrugListByCenter()> "+sql);
		return mydb.ExecuteQuary(sql);
	}

	public Object getDepartments(String center)throws RemoteException, SQLException{
		String sql = "select * from department where center = '"+center+"' and active = 1";
		System.out.println("getDepartments >> "+sql);
		return mydb.ExecuteQuary(sql);
	}

	public Object getAllDepartments(String center)throws RemoteException, SQLException{
		String sql = "select * from department where center = '"+center+"'";
		System.out.println("getDepartments >> "+sql);
		return mydb.ExecuteQuary(sql);
	}

	public Object getDoctorsOfDepartment(String ccode, String department)throws RemoteException, SQLException{
		String sql =  "Select l.name,l.rg_no from login l right join othdis  o on l.rg_no = o.rg_no where upper(type) = 'DOC' and upper(active) ='Y' and referral= 'Y' and upper(center) ='"+ccode+"' and o.dis = '"+department+"'";
		System.out.println("DisplayData->getDoctorsOfDepartment >> "+sql);
		return mydb.ExecuteQuary(sql);
	}
	/*Soumyajit Das*/
	public Object getAllDoctors(String center)throws RemoteException, SQLException{
		String sql = "select * from login where type='doc' and center = '"+center+"'";
		System.out.println("getAllDoctors >> "+sql);
		return mydb.ExecuteQuary(sql);
	}
	/*Soumyajit Das*/
	public Object getdrugs(String center)throws RemoteException,SQLException
	{
		String sql="select * from druglistbycenter where ccode='"+center+"' and active=1";
		System.out.println("getdrugs >> "+sql);
		return mydb.ExecuteQuary(sql);
	}
	/*Soumyajit Das*/
	public Object getAlldrugs(String center)throws RemoteException,SQLException
	{
		String sql="select * from druglistbycenter where ccode='"+center+"'";
		System.out.println("getAllDrugs >> "+sql);
		return mydb.ExecuteQuary(sql);
	}
	public Object getAdviceOfPrescription(String preid) throws RemoteException,SQLException 
	{
		String sql="select * from ai0 where preid='"+preid+"'";
		System.out.println("DisplayData->getAdviceOfPrescription: "+sql);
		return mydb.ExecuteQuary(sql);
	}	
	/*Surajit */
	public Object getPrescribedPatientList(String inputdate, String centerid) throws RemoteException, SQLException{
		String sql = "select pat_id, (select concat(pat_name,' ',m_name,' ',l_name) from med where pat_id=pre.pat_id) as patname, MAX(entrydate) as entrydate, count(pat_id) as noofpres from pre where DATE_FORMAT(pre.entrydate,'%d/%m/%Y')='"+inputdate+"' and name_hos = '"+centerid+"' group by pat_id order by MAX(entrydate) desc";
		System.out.println("getPrescribedPatientList >> "+sql);
		return mydb.ExecuteQuary(sql);
	}
	/*Surajit*/
	/*Surajit */
	public Object getPrescriptionList(String inputdate, String centerid) throws RemoteException, SQLException{
		String sql = "(select pre.*, 'pre' as tablename, (select concat(IFNULL(pat_name,''),' ',IFNULL(m_name,''),' ',IFNULL(l_name,'')) from med where pat_id=pre.pat_id) as patname from pre where DATE_FORMAT(pre.entrydate,'%d/%m/%Y')='"+inputdate+"' and pat_id like '"+centerid+"%') UNION (select prs.*, 'prs' as tablename, (select concat(IFNULL(pat_name,''),' ',IFNULL(m_name,''),' ',IFNULL(l_name,'')) from med where pat_id=prs.pat_id) as patname from prs where DATE_FORMAT(prs.entrydate,'%d/%m/%Y')='"+inputdate+"' and pat_id like '"+centerid+"%') order by entrydate desc";
		System.out.println("getPrescriptionList >> "+sql);
		return mydb.ExecuteQuary(sql);
	}		
	/*Surajit*/
	public Object getPrescriptionDetails(String inputdate, String centerid, String patid) throws RemoteException, SQLException{
		String sql = "select * from pre where pat_id='"+patid+"' and DATE_FORMAT(pre.entrydate,'%d/%m/%Y')='"+inputdate+"' and name_hos = '"+centerid+"'";
		System.out.println("getPrescriptionDetails >> "+sql);
		return mydb.ExecuteQuary(sql);
	}
	/*Surajit*/
	public Object getPrintedPrescriptionList(String inputdate) throws RemoteException, SQLException{
		String sql = "select * from printedpres where DATE_FORMAT(creationdate,'%d/%m/%Y')='"+inputdate+"'";
		System.out.println("getPrintedPrescriptionList() > "+sql);
		return mydb.ExecuteQuary(sql);
	}

	/*Mithun*/
	public Object searchPatient(String key, String ccode) throws RemoteException, SQLException{
		String isql="select med.pat_person,login.name, login.emailid, login.phone, med.pat_id, med.pat_name, med.l_name from med " +
					"left join login on med.pat_id = login.uid "+
					"where (med.pat_id like '%"+key+"%' or med.pat_name like '%"+key+"%' or med.l_name like '%"+key+"%' or med.pat_person like '%"+key+"%' or login.phone like '%"+key+"%') " +
					"and login.center = '"+ccode+"' limit 10";
		if(ccode.equalsIgnoreCase("XXXX")){
			isql="select med.pat_person,login.name, login.emailid, login.phone, med.pat_id, med.pat_name, med.l_name from med " +
				"left join login on med.pat_id = login.uid "+
				"where med.pat_id like '%"+key+"%' or med.pat_name like '%"+key+"%' or med.l_name like '%"+key+"%' or med.pat_person like '%"+key+"%' or login.phone like '%"+key+"%' limit 10";
		}
 	    System.out.println("searchPatient: "+isql);
 	    return mydb.ExecuteQuary(isql);
	}
	/*Surajit*/
	public Vector rkmsStatistics( String fromDate, String toDate, String centerid) throws RemoteException, SQLException{
		Vector<Object> result = new Vector();
		String centerQ = "", center = "";
		String sql1 = "select DATE(entrydate) entrydateonly, count(DATE(entrydate)) as noofadv from pre where (DATE(entrydate) > DATE_FORMAT(STR_TO_DATE('"+fromDate+"', '%d/%m/%Y'), '%Y-%m-%d') and DATE(entrydate) <= DATE_FORMAT(STR_TO_DATE('"+toDate+"', '%d/%m/%Y'), '%Y-%m-%d')) and pat_id REGEXP '"+centerid+"' group by entrydateonly order by entrydateonly";
		System.out.println("rkmsStatistics() 1 >"+sql1);
			result.add(mydb.ExecuteQuary(sql1));
		String sql2 = "select sex, count(sex) as genderno from med where pat_id in (select pat_id from pre where (DATE(pre.entrydate) > DATE_FORMAT(STR_TO_DATE('"+fromDate+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(pre.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+toDate+"', '%d/%m/%Y'), '%Y-%m-%d')) and pre.pat_id REGEXP '"+centerid+"') group by sex order by sex";
		System.out.println("rkmsStatistics() 2 >"+sql2);
			result.add(mydb.ExecuteQuary(sql2));	
			return result;

	}
	/*Surajit*/
	public Vector rkmsStatisticsAdm( String fromDate, String toDate, int codeLength) throws RemoteException, SQLException{
		Vector<Object> result = new Vector();
		String sql3 = "select substring(pat_id,1,"+codeLength+") as center, count(distinct pat_id) nop from pre where (DATE(pre.entrydate) > DATE_FORMAT(STR_TO_DATE('"+fromDate+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(pre.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+toDate+"', '%d/%m/%Y'), '%Y-%m-%d')) group by center";
		System.out.println("rkmsStatisticsAdm() > "+sql3);	
			result.add(mydb.ExecuteQuary(sql3));
			return result;		
	}
	// Surajit/
	public Object diagnosisStats(String center, String basic_diagnosis, String detailed_diagnosis) throws RemoteException, SQLException{
		
		String sql = "select * from p51 where preid in (select preid from pre where name_hos in ('"+center+"') and preid is not NULL)";
		if (center.equals("XXXX"))
			sql = "select * from p51 where preid in (select preid from pre where preid is not NULL)";
		String substring_value = "", substring_basic_diagnosis = "";
		if (detailed_diagnosis.length()>0)
			substring_value = " and value like '%"+detailed_diagnosis+"%'";
		if (basic_diagnosis.length()>0)
			substring_basic_diagnosis = " and basic_diagnosis='"+basic_diagnosis+"'";
		sql = sql+substring_value+substring_basic_diagnosis;
		System.out.println("Display data> diagnosisStats(): "+sql);
		return mydb.ExecuteQuary(sql);
	}
	// Surajit//
	public Object diagnosisSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		/*
		String queryString = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		String sql = "select basic_diagnosis, count(value) as noofdiag from p51 where preid in (select preid from pre where preid is not NULL"+queryString+" and pre.pat_id REGEXP '"+center+"') group by basic_diagnosis";
		if (center.equals("XXXX"))
			sql = "select basic_diagnosis, count(value) as noofdiag from p51 where preid in (select preid from pre where preid is not NULL"+queryString+") group by basic_diagnosis";
		System.out.println("diagnosisSummary> diagnosisSummary(): "+ sql);
		return mydb.ExecuteQuary(sql); 
		* */
		String queryString = "", queryString1 = "", splcase = "";
		if (fromdate.length()>0 && todate.length()>0){
			queryString = " DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		}
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";
		
		if(attr.contains("entrydate"))
			splcase = " entry";
		else{
			splcase  = attr;
			attr = "";	
		}		
		String sql = "select "+splcase+", count(*) as noofdiag from (select "+splcase+" from med inner join pre on med.pat_id=pre.pat_id inner join p51 on pre.preid=p51.preid where "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
		//String sql = "select basic_diagnosis, count(basic_diagnosis) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and pre.pat_id in (select pat_id from patientvisit where "+queryString+" and pat_id REGEXP '"+center+"') "+queryString1+" group by basic_diagnosis;";
		if (center.equals("XXXX"))
			sql = "select "+splcase+", count(*) as noofdiag from (select "+splcase+" from med inner join pre on med.pat_id=pre.pat_id inner join p51 on pre.preid=p51.preid where "+queryString+" group by pre.preid, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
			//sql = "select basic_diagnosis, count(basic_diagnosis) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and pre.pat_id in (select pat_id from patientvisit where "+queryString+") "+queryString1+" group by basic_diagnosis;";
		System.out.println("diagnosisSummary> diagnosisSummary(): "+ sql);
		return mydb.ExecuteQuary(sql); 		
	}
	
	//Surajit
	public Object diagnosisSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", queryString1 = "", splcase="";
		if (fromdate.length()>0 && todate.length()>0){
			queryString = " DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		}

		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
			
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}
		
		String sql = "select "+splcase+", count(*) as noofdiag from (select "+splcase+" from med inner join pre on med.pat_id=pre.pat_id inner join p51 on pre.preid=p51.preid where "+queryString+" and pre.pat_id REGEXP '"+center+"' group by med.pat_id, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
		//String sql = "select basic_diagnosis, count(basic_diagnosis) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and pre.pat_id in (select pat_id from patientvisit where "+queryString+" and pat_id REGEXP '"+center+"') "+queryString1+" group by basic_diagnosis;";
		if (center.equals("XXXX"))
			sql = "select "+splcase+", count(*) as noofdiag from (select "+splcase+" from med inner join pre on med.pat_id=pre.pat_id inner join p51 on pre.preid=p51.preid where "+queryString+" group by med.pat_id, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
			//sql = "select basic_diagnosis, count(basic_diagnosis) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and pre.pat_id in (select pat_id from patientvisit where "+queryString+") "+queryString1+" group by basic_diagnosis;";
		System.out.println("diagnosisSummary> diagnosisSummaryUnique(): "+ sql);
		return mydb.ExecuteQuary(sql); 
	} 
	
	public Object totalNCDScreeningPatient(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " DATE(entrydate)>=DATE('"+fromdate+"') and DATE(entrydate)<=DATE('"+todate+"')";
		
		String sql = "select '"+attr+"', count(distinct pat_id) as noofdiag from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+" and pat_id REGEXP '"+center+"'";
		if(center.equals("XXXX"))
			sql = "select '"+attr+"', count(distinct pat_id) as noofdiag from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+"";
		System.out.println("DiagnosisSummary> totalNCDScreeningPatient(): "+ sql);
		return mydb.ExecuteQuary(sql);			
		
	}
	
	//Surajit
/*	public Object genderWiseDiagSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";
		String sql = "select "+attr+", sex, count(sex) as noofdiag from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)>16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by sex,"+attr+" order by "+attr.replace("MONTH", "")+"";
		if(center.equals("XXXX"))
			sql = "select "+attr+", sex, count(sex) as noofdiag from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)>16 "+queryString+" group by sex,"+attr+" order by "+attr.replace("MONTH", "")+"";
		System.out.println("DiagnosisSummary> genderWiseDiagSummary(): "+ sql);
		return mydb.ExecuteQuary(sql);
	}*/
	//Surajit
	public Object genderWiseDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " DATE(entrydate)>=DATE('"+fromdate+"') and DATE(entrydate)<=DATE('"+todate+"')";
		
		String sql = "select '"+attr+"', sex, count(sex) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+" and pat_id REGEXP '"+center+"') and (TIMESTAMPDIFF(YEAR,med.entrydate, DATE('"+fromdate+"'))+SUBSTRING_INDEX(age,',',1))>16 group by sex";
		if(center.equals("XXXX"))
			sql = "select '"+attr+"', sex, count(sex) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+") and (TIMESTAMPDIFF(YEAR,med.entrydate, DATE('"+fromdate+"'))+SUBSTRING_INDEX(age,',',1))>16 group by sex";
		System.out.println("DiagnosisSummary> genderWiseDiagSummaryNCD(): "+ sql);
		return mydb.ExecuteQuary(sql);		
	
	}
	
	//Surajit
	public Object genderWiseDiagSummaryVisit(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", splcase = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";
		
		if(attr.contains("entrydate"))
			splcase = " entry";
		else{
			splcase  = attr;
			attr = "";	
		}		
		String sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))>16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))>16 "+queryString+" group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		System.out.println("DiagnosisSummary> genderWiseDiagSummaryVisit(): "+ sql);
		return mydb.ExecuteQuary(sql);
	}
	

	//Surajit
	public Object genderWiseDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", splcase = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";
		
		if(attr.contains("entrydate"))
			splcase = " entry";
		else{
			splcase  = attr;
			attr = "";	
		}		
		String sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))>16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by med.pat_id, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))>16 "+queryString+" group by med.pat_id, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		System.out.println("DiagnosisSummary> genderWiseDiagSummaryUnique(): "+ sql);
		return mydb.ExecuteQuary(sql);
	}
	
	
	//Surajit
	public Object genderWiseDiagSummaryOldPatient(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		/*
		String queryString = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";			
		String sql = "select "+attr+", concat(sex, '_old') as sex, count(sex) as noofdiag from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)>16 "+queryString+" and pre.pat_id REGEXP '"+center+"' and p51.preid in (select preid from pre where pat_id in (select pat_id from patientvisit group by 1 having count(pat_id) > 1)) group by sex,"+attr+" order by "+attr.replace("MONTH", "")+"";
		if(center.equals("XXXX"))
			sql = "select "+attr+", concat(sex, '_old') as sex, count(sex) as noofdiag from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)>16 "+queryString+"  and p51.preid in (select preid from pre where pat_id in (select pat_id from patientvisit group by 1 having count(pat_id) > 1)) group by sex,"+attr+" order by "+attr.replace("MONTH", "")+"";
		System.out.println("DiagnosisSummary> genderWiseDiagSummaryOldPatient(): "+ sql);
		return mydb.ExecuteQuary(sql);
		* */
		
/*		
		String queryString = "", splcase = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)<DATE('"+fromdate+"') ";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
				
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}				
		String sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_old') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)>16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_old') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)>16 "+queryString+" group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		System.out.println("DiagnosisSummary> genderWiseDiagSummaryOldPatient(): "+ sql);
		return mydb.ExecuteQuary(sql);
		* */
		
		String queryString = "", splcase = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate) != DATE(pre.entrydate) ";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
				
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}				
		String sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_old') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))>16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_old') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))>16 "+queryString+" group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		System.out.println("DiagnosisSummary> genderWiseDiagSummaryOldPatient(): "+ sql);
		return mydb.ExecuteQuary(sql);		
		
		
	}
	
	// Surajit
/*	public Object genderWiseDiagSummaryOldPatientVisit(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "", queryString1 = "";
		if (fromdate.length()>0 && todate.length()>0){
			queryString = "DATE(visitdate)>=DATE('"+fromdate+"') and DATE(visitdate)<=DATE('"+todate+"')";
			queryString1 = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		}
		
		String sql = "select "+attr+", concat(sex, '_old') as sex, count(sex) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and SUBSTRING_INDEX(age,',',1)>16 and pre.pat_id in (select pat_id from patientvisit where "+queryString+" and pat_id REGEXP '"+center+"' group by 1 having count(pat_id) > 1) "+queryString1+" group by sex, "+attr+"";		
		
		if (center.equals("XXXX"))
			sql = "select "+attr+", concat(sex, '_old') as sex, count(sex) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and SUBSTRING_INDEX(age,',',1)>16 and pre.pat_id in (select pat_id from patientvisit where "+queryString+" group by 1 having count(pat_id) > 1) "+queryString1+" group by sex, "+attr+"";
		System.out.println("DiagnosisSummary> genderWiseDiagSummaryOldPatientVisit()>> "+ sql);
		return mydb.ExecuteQuary(sql);
	}
*/

	//Surajit
	public Object genderWiseDiagSummaryOldPatientUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", splcase = "", financial_year_start_date = "";
		int financial_year_month = 0;
		financial_year_month = Integer.valueOf(todate.split("-")[1]);
		financial_year_start_date = (financial_year_month<=3)? String.valueOf(Integer.valueOf(todate.split("-")[0])-1)+"-04-01" : todate.split("-")[0]+"-04-01";
		
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)<DATE('"+financial_year_start_date+"') ";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
				
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}				
		String sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_old') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))>16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by med.pat_id, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_old') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))>16 "+queryString+" group by med.pat_id, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		System.out.println("DiagnosisSummary> genderWiseDiagSummaryOldPatientUnique(): "+ sql);
		return mydb.ExecuteQuary(sql);
	}

	
	// Surajit
/*	public Object childGenderWiseDiagSummaryOldPatientVisit(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "", queryString1 = "";
		if (fromdate.length()>0 && todate.length()>0){
			queryString = "DATE(visitdate)>=DATE('"+fromdate+"') and DATE(visitdate)<=DATE('"+todate+"')";
			queryString1 = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		}
		String sql = "select "+attr+", concat(sex, '_old') as sex, count(sex) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and SUBSTRING_INDEX(age,',',1)<=16 and pre.pat_id in (select pat_id from patientvisit where "+queryString+" and pat_id REGEXP '"+center+"' group by 1 having count(pat_id) > 1) "+queryString1+" group by sex, "+attr+"";		
		
		if (center.equals("XXXX"))
			sql = "select "+attr+", concat(sex, '_old') as sex, count(sex) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and SUBSTRING_INDEX(age,',',1)<=16 and pre.pat_id in (select pat_id from patientvisit where "+queryString+" group by 1 having count(pat_id) > 1) "+queryString1+" group by sex, "+attr+"";
		System.out.println("DiagnosisSummary> childGenderWiseDiagSummaryOldPatientVisit()>> "+ sql);
		return mydb.ExecuteQuary(sql);
	}
*/
	//Surajit
	public Object childGenderWiseDiagSummaryOldPatientUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", splcase = "", financial_year_start_date = "";
		int financial_year_month = 0;
		financial_year_month = Integer.valueOf(todate.split("-")[1]);
		financial_year_start_date = (financial_year_month<=3)? String.valueOf(Integer.valueOf(todate.split("-")[0])-1)+"-04-01" : todate.split("-")[0]+"-04-01";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)<DATE('"+financial_year_start_date+"') ";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
			
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}						
		String sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_old') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))<=16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by med.pat_id, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_old') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))<=16 "+queryString+" group by med.pat_id, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		System.out.println("DiagnosisSummary> childGenderWiseDiagSummaryOldPatientUnique(): "+ sql);
		return mydb.ExecuteQuary(sql);
	}	
	
	
	
	//Surajit
	public Object genderWiseDiagSummaryNewPatient(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		/*
		String queryString = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(med.entrydate)>=DATE('"+fromdate+"') and DATE(med.entrydate)<=DATE('"+todate+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";
		String sql = "select "+attr+", concat(sex, '_new') as sex, count(sex) as noofdiag from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)>16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by sex, "+attr+" order by "+attr.replace("MONTH", "")+"";			
		//String sql = "select "+attr+", concat(sex, '_new') as sex, count(sex) as noofdiag from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)>16 "+queryString+" and pre.pat_id REGEXP '"+center+"' and p51.preid in (select preid from pre where pat_id in (select pat_id from patientvisit group by 1 having count(pat_id) <= 1)) group by sex,"+attr+" order by "+attr.replace("MONTH", "")+"";
		if(center.equals("XXXX"))
			sql = "select "+attr+", concat(sex, '_new') as sex, count(sex) as noofdiag from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)>16 "+queryString+" group by sex,"+attr+" order by "+attr.replace("MONTH", "")+"";	
			//sql = "select "+attr+", concat(sex, '_new') as sex, count(sex) as noofdiag from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)>16 "+queryString+"  and p51.preid in (select preid from pre where pat_id in (select pat_id from patientvisit group by 1 having count(pat_id) <= 1)) group by sex,"+attr+" order by "+attr.replace("MONTH", "")+"";
		System.out.println("DiagnosisSummary> genderWiseDiagSummaryNewPatient(): "+ sql);
		return mydb.ExecuteQuary(sql);
		* */
/*
		String queryString = "", splcase = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)>=DATE('"+fromdate+"') and DATE(med.entrydate)<=DATE('"+todate+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
			
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}						
		String sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_new') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)>16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_new') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)>16 "+queryString+" group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		System.out.println("DiagnosisSummary> genderWiseDiagSummaryNewPatient(): "+ sql);
		return mydb.ExecuteQuary(sql);		
		* */
		
		String queryString = "", splcase = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)= DATE(pre.entrydate)";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
			
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}						
		String sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_new') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))>16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_new') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))>16 "+queryString+" group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		System.out.println("DiagnosisSummary> genderWiseDiagSummaryNewPatient(): "+ sql);
		return mydb.ExecuteQuary(sql);			
		
	}	
	
	//Surajit
	public Object genderWiseDiagSummaryNewPatientNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " DATE(entrydate)>=DATE('"+fromdate+"') and DATE(entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)=DATE(ncd.entrydate) ";
		
		String sql = "select '"+attr+"', concat(sex, '_new') as sex, count(sex) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+" and pat_id REGEXP '"+center+"') and (TIMESTAMPDIFF(YEAR,med.entrydate, DATE('"+fromdate+"'))+SUBSTRING_INDEX(age,',',1))>16 group by sex";
		if(center.equals("XXXX"))
			sql = "select '"+attr+"', concat(sex, '_new') as sex, count(sex) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+") and (TIMESTAMPDIFF(YEAR,med.entrydate, DATE('"+fromdate+"'))+SUBSTRING_INDEX(age,',',1))>16 group by sex";
		System.out.println("DiagnosisSummary> genderWiseDiagSummaryNewPatientNCD(): "+ sql);
		return mydb.ExecuteQuary(sql);			
	}

	// Surajit
/*	public Object genderWiseDiagSummaryNewPatientVisit(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "", queryString1 = "";
		if (fromdate.length()>0 && todate.length()>0){
			queryString = "DATE(visitdate)>=DATE('"+fromdate+"') and DATE(visitdate)<=DATE('"+todate+"')";
			queryString1 = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		}
		String sql = "select "+attr+", concat(sex, '_new') as sex, count(sex) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and SUBSTRING_INDEX(age,',',1)>16 and pre.pat_id in (select pat_id from patientvisit where "+queryString+" and pat_id REGEXP '"+center+"' group by 1 having count(pat_id) <= 1) "+queryString1+" group by sex, "+attr+"";		
		
		if (center.equals("XXXX"))
			sql = "select "+attr+", concat(sex, '_new') as sex, count(sex) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and SUBSTRING_INDEX(age,',',1)>16 and pre.pat_id in (select pat_id from patientvisit where "+queryString+" group by 1 having count(pat_id) <= 1) "+queryString1+" group by sex, "+attr+"";
		System.out.println("DiagnosisSummary> genderWiseDiagSummaryNewPatientVisit()>> "+ sql);
		return mydb.ExecuteQuary(sql);
	}*/
	
	//Surajit
	public Object genderWiseDiagSummaryNewPatientUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", splcase = "", financial_year_start_date = "", financial_year_end_date = "";
		int financial_year_month = 0;
		financial_year_month = Integer.valueOf(todate.split("-")[1]);
		financial_year_start_date = (financial_year_month<=3)? String.valueOf(Integer.valueOf(todate.split("-")[0])-1)+"-04-01" : todate.split("-")[0]+"-04-01";
		financial_year_end_date = (financial_year_month<=3)? todate.split("-")[0]+"-03-31" : String.valueOf(Integer.valueOf(todate.split("-")[0])+1)+"-03-31";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)>=DATE('"+financial_year_start_date+"') and DATE(med.entrydate)<=DATE('"+financial_year_end_date+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
			
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}						
		String sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_new') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))>16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by med.pat_id, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_new') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))>16 "+queryString+" group by med.pat_id, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		System.out.println("DiagnosisSummary> genderWiseDiagSummaryNewPatientUnique(): "+ sql);
		return mydb.ExecuteQuary(sql);
	}		
	

	// Surajit
/*	public Object childGenderWiseDiagSummaryNewPatientVisit(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "", queryString1 = "";
		if (fromdate.length()>0 && todate.length()>0){
			queryString = "DATE(visitdate)>=DATE('"+fromdate+"') and DATE(visitdate)<=DATE('"+todate+"')";
			queryString1 = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		}
		String sql = "select basic_diagnosis, sex, count(sex) as noofdiag from ( select "+attr+", concat(sex, '_new') as sex from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and SUBSTRING_INDEX(age,',',1)<=16 and pre.pat_id in (select pat_id from patientvisit where "+queryString+" and pat_id REGEXP '"+center+"' group by 1 having count(pat_id) <= 1) "+queryString1+" group by med.pat_id, sex, "+attr+") temp group by sex, basic_diagnosis";		
		
		if (center.equals("XXXX"))
			sql = "select basic_diagnosis, sex, count(sex) as noofdiag from ( select "+attr+", concat(sex, '_new') as sex, count(sex) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and SUBSTRING_INDEX(age,',',1)<=16 and pre.pat_id in (select pat_id from patientvisit where "+queryString+" group by 1 having count(pat_id) <= 1) "+queryString1+" group by med.pat_id, sex, "+attr+") temp group by sex, basic_diagnosis";
		System.out.println("DiagnosisSummary> childGenderWiseDiagSummaryNewPatientVisit()>> "+ sql);
		return mydb.ExecuteQuary(sql);
	} */
	
	//Surajit
	public Object childGenderWiseDiagSummaryNewPatientUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", splcase = "", financial_year_start_date = "", financial_year_end_date = "";
		int financial_year_month = 0;
		financial_year_month = Integer.valueOf(todate.split("-")[1]);
		financial_year_start_date = (financial_year_month<=3)? String.valueOf(Integer.valueOf(todate.split("-")[0])-1)+"-04-01" : todate.split("-")[0]+"-04-01";
		financial_year_end_date = (financial_year_month<=3)? todate.split("-")[0]+"-03-31" : String.valueOf(Integer.valueOf(todate.split("-")[0])+1)+"-03-31";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)>=DATE('"+financial_year_start_date+"') and DATE(med.entrydate)<=DATE('"+financial_year_end_date+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
			
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}			
					
		String sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_new') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))<=16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by med.pat_id, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_new') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))<=16 "+queryString+" group by med.pat_id, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		System.out.println("DiagnosisSummary> childGenderWiseDiagSummaryNewPatientUnique(): "+ sql);
		return mydb.ExecuteQuary(sql);
	}	
		
	//Surajit
	public Object childGenderWiseDiagSummaryNewPatientNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " DATE(entrydate)>=DATE('"+fromdate+"') and DATE(entrydate)<=DATE('"+todate+"')  and DATE(med.entrydate)=DATE(ncd.entrydate) ";
		
		String sql = "select '"+attr+"', concat(sex, '_new') as sex, count(sex) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+" and pat_id REGEXP '"+center+"' ) and (TIMESTAMPDIFF(YEAR,med.entrydate, DATE('"+fromdate+"'))+SUBSTRING_INDEX(age,',',1))<=16 group by sex";
		if(center.equals("XXXX"))
			sql = "select '"+attr+"', concat(sex, '_new') as sex, count(sex) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+") and (TIMESTAMPDIFF(YEAR,med.entrydate, DATE('"+fromdate+"'))+SUBSTRING_INDEX(age,',',1))<=16 group by sex";
		System.out.println("DiagnosisSummary> childGenderWiseDiagSummaryNewPatientNCD(): "+ sql);
		return mydb.ExecuteQuary(sql);			
	}	

	//Surajit
	public Object genderWiseDiagSummaryOldPatientNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " DATE(entrydate)>=DATE('"+fromdate+"') and DATE(entrydate)<=DATE('"+todate+"')  and DATE(med.entrydate)!=DATE(ncd.entrydate) ";
		
		String sql = "select '"+attr+"', concat(sex, '_old') as sex, count(sex) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+" and pat_id REGEXP '"+center+"') and (TIMESTAMPDIFF(YEAR,med.entrydate, DATE('"+fromdate+"'))+SUBSTRING_INDEX(age,',',1))>16 group by sex";
		if(center.equals("XXXX"))
			sql = "select '"+attr+"', concat(sex, '_old') as sex, count(sex) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+") and (TIMESTAMPDIFF(YEAR,med.entrydate, DATE('"+fromdate+"'))+SUBSTRING_INDEX(age,',',1))>16 group by sex";
		System.out.println("DiagnosisSummary> genderWiseDiagSummaryOldPatientNCD(): "+ sql);
		return mydb.ExecuteQuary(sql);			
	}
	//Surajit
	public Object childGenderWiseDiagSummaryOldPatientNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " DATE(entrydate)>=DATE('"+fromdate+"') and DATE(entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)!=DATE(ncd.entrydate) ";
		
		String sql = "select '"+attr+"', concat(sex, '_old') as sex, count(sex) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+" and pat_id REGEXP '"+center+"') and (TIMESTAMPDIFF(YEAR,med.entrydate, DATE('"+fromdate+"'))+SUBSTRING_INDEX(age,',',1))<=16 group by sex";
		if(center.equals("XXXX"))
			sql = "select '"+attr+"', concat(sex, '_old') as sex, count(sex) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+") and (TIMESTAMPDIFF(YEAR,med.entrydate, DATE('"+fromdate+"'))+SUBSTRING_INDEX(age,',',1))<=16 group by sex";
		System.out.println("DiagnosisSummary> childGenderWiseDiagSummaryOldPatientNCD(): "+ sql);
		return mydb.ExecuteQuary(sql);			
	}	
	
	//Surajit
	public Object oldPatientDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " DATE(entrydate)>=DATE('"+fromdate+"') and DATE(entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)!=DATE(ncd.entrydate) ";
		
		String sql = "select '"+attr+"', count(distinct pat_id) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+" and pat_id REGEXP '"+center+"')";
		if(center.equals("XXXX"))
			sql = "select '"+attr+"', count(distinct pat_id) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+")";
		System.out.println("DiagnosisSummary> oldPatientDiagSummaryNCD(): "+ sql);
		return mydb.ExecuteQuary(sql); 
	}
	//Surajit
	public Object newPatientDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " DATE(entrydate)>=DATE('"+fromdate+"') and DATE(entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)=DATE(ncd.entrydate) ";
		
		String sql = "select '"+attr+"', count(distinct pat_id) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+" and pat_id REGEXP '"+center+"')";
		if(center.equals("XXXX"))
			sql = "select '"+attr+"', count(distinct pat_id) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+")";
		System.out.println("DiagnosisSummary> newPatientDiagSummaryNCD(): "+ sql);
		return mydb.ExecuteQuary(sql); 
	}	
	
	//Surajit
	public Object childGenderWiseDiagSummaryOldPatient(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		/*
		String queryString = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";			
		String sql = "select "+attr+", concat(sex, '_old') as sex, count(sex) as noofdiag from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)<=16 "+queryString+" and pre.pat_id REGEXP '"+center+"' and p51.preid in (select preid from pre where pat_id in (select pat_id from patientvisit group by 1 having count(pat_id) > 1)) group by sex,"+attr+" order by "+attr.replace("MONTH", "")+"";
		if(center.equals("XXXX"))
			sql = "select "+attr+", concat(sex, '_old') as sex, count(sex) as noofdiag from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)<=16 "+queryString+"  and p51.preid in (select preid from pre where pat_id in (select pat_id from patientvisit group by 1 having count(pat_id) > 1)) group by sex,"+attr+" order by "+attr.replace("MONTH", "")+"";
		System.out.println("DiagnosisSummary> childGenderWiseDiagSummaryOldPatient(): "+ sql);
		return mydb.ExecuteQuary(sql);
		* */

/*
		String queryString = "", splcase = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)<DATE('"+fromdate+"') ";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
			
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}						
		String sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_old') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)<=16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_old') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)<=16 "+queryString+" group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		System.out.println("DiagnosisSummary> childGenderWiseDiagSummaryOldPatient(): "+ sql);
		return mydb.ExecuteQuary(sql);	
		* */

		String queryString = "", splcase = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)!=DATE(pre.entrydate) ";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
			
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}						
		String sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_old') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))<=16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_old') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))<=16 "+queryString+" group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		System.out.println("DiagnosisSummary> childGenderWiseDiagSummaryOldPatient(): "+ sql);
		return mydb.ExecuteQuary(sql);			
		
			
	}
	
	//Surajit
	public Object childGenderWiseDiagSummaryNewPatient(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		/*
		String queryString = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(med.entrydate)>=DATE('"+fromdate+"') and DATE(med.entrydate)<=DATE('"+todate+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
		String sql = "select "+attr+", concat(sex, '_new') as sex, count(sex) as noofdiag from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)<=16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by sex, "+attr+" order by "+attr.replace("MONTH", "")+"";		
		//String sql = "select "+attr+", concat(sex, '_new') as sex, count(sex) as noofdiag from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)<=16 "+queryString+" and pre.pat_id REGEXP '"+center+"' and p51.preid in (select preid from pre where pat_id in (select pat_id from patientvisit group by 1 having count(pat_id) <= 1)) group by sex,"+attr+" order by "+attr.replace("MONTH", "")+"";
		if(center.equals("XXXX"))
			sql = "select "+attr+", concat(sex, '_new') as sex, count(sex) as noofdiag from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)<=16 "+queryString+" group by sex, "+attr+" order by "+attr.replace("MONTH", "")+"";
			//sql = "select "+attr+", concat(sex, '_new') as sex, count(sex) as noofdiag from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)<=16 "+queryString+"  and p51.preid in (select preid from pre where pat_id in (select pat_id from patientvisit group by 1 having count(pat_id) <= 1)) group by sex,"+attr+" order by "+attr.replace("MONTH", "")+"";
		System.out.println("DiagnosisSummary> childGenderWiseDiagSummaryNewPatient(): "+ sql);
		return mydb.ExecuteQuary(sql);
		* */
/*
		String queryString = "", splcase = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)>=DATE('"+fromdate+"') and DATE(med.entrydate)<=DATE('"+todate+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
			
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}			
					
		String sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_new') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)<=16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_new') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where SUBSTRING_INDEX(age,',',1)<=16 "+queryString+" group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		System.out.println("DiagnosisSummary> childGenderWiseDiagSummaryNewPatient(): "+ sql);		
		return mydb.ExecuteQuary(sql);
*/
		String queryString = "", splcase = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate) = DATE(pre.entrydate)";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
			
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}			
					
		String sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_new') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))<=16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", concat(sex, '_new') as sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))<=16 "+queryString+" group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		System.out.println("DiagnosisSummary> childGenderWiseDiagSummaryNewPatient(): "+ sql);		
		return mydb.ExecuteQuary(sql);	
	}	
	
		
	
	//Surajit
	public Object casteWiseDiagSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", splcase="";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
		
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}
		String sql = "select "+splcase+", caste_category, count(caste_category) as noofdiag from ( select "+attr+splcase+", caste_category from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where religion=3 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, caste_category,"+splcase+" order by "+splcase+") temp group by caste_category, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", caste_category, count(caste_category) as noofdiag from ( select "+attr+splcase+", caste_category from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where religion=3 "+queryString+" group by pre.preid, caste_category,"+splcase+" order by "+splcase+") temp group by caste_category, "+splcase+"";
		System.out.println("DiagnosisSummary> casteWiseDiagSummary(): "+ sql);
		return mydb.ExecuteQuary(sql);
	}	
	
	//Surajit
	public Object casteWiseDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " DATE(entrydate)>=DATE('"+fromdate+"') and DATE(entrydate)<=DATE('"+todate+"')";
		
		String sql = "select '"+attr+"', caste_category, count(caste_category) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+" and pat_id REGEXP '"+center+"') and religion=3 group by caste_category";
		if(center.equals("XXXX"))
			sql = "select '"+attr+"', caste_category, count(caste_category) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+") and religion=3 group by caste_category";
		System.out.println("DiagnosisSummary> casteWiseDiagSummaryNCD(): "+ sql);
		return mydb.ExecuteQuary(sql);	
	}
	
	//Surajit
/*	public Object casteWiseDiagSummaryVisit(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "", queryString1 = "";
		if (fromdate.length()>0 && todate.length()>0){
			queryString = "DATE(visitdate)>=DATE('"+fromdate+"') and DATE(visitdate)<=DATE('"+todate+"')";
			queryString1 = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		}
	
		String sql = "select "+attr+", caste_category, count(caste_category) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and pre.pat_id in (select pat_id from patientvisit where "+queryString+" and pat_id REGEXP '"+center+"') and religion = 3 "+queryString1+" group by caste_category, "+attr+"";
		if(center.equals("XXXX"))
			sql = "select "+attr+", caste_category, count(caste_category) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and pre.pat_id in (select pat_id from patientvisit where "+queryString+") and religion = 3 "+queryString1+" group by caste_category, "+attr+"";
		System.out.println("DiagnosisSummary> casteWiseDiagSummaryVisit():  "+sql);
		return mydb.ExecuteQuary(sql);		
	}*/

	//Surajit
	public Object casteWiseDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", splcase="";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
		
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}
		String sql = "select "+splcase+", caste_category, count(caste_category) as noofdiag from ( select "+attr+splcase+", caste_category from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where religion=3 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by med.pat_id, caste_category,"+splcase+" order by "+splcase+") temp group by caste_category, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", caste_category, count(caste_category) as noofdiag from ( select "+attr+splcase+", caste_category from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where religion=3 "+queryString+" group by med.pat_id, caste_category,"+splcase+" order by "+splcase+") temp group by caste_category, "+splcase+"";
		System.out.println("DiagnosisSummary> casteWiseDiagSummaryUnique(): "+ sql);
		return mydb.ExecuteQuary(sql);
	}

	
	//Surajit
	public Object religionWiseDiagSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", splcase = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
			
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}					
		// Exclude Hindu (3) religion
		String sql = "select "+splcase+", religion, count(religion) as noofdiag from ( select "+attr+splcase+", religion from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where religion!=3 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, religion,"+splcase+" order by "+splcase+") temp group by religion, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", religion, count(religion) as noofdiag from ( select "+attr+splcase+", religion from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where religion!=3 "+queryString+" group by pre.preid, religion,"+splcase+" order by "+splcase+") temp group by religion, "+splcase+"";
		System.out.println("DiagnosisSummary> religionWiseDiagSummary(): "+ sql);
		return mydb.ExecuteQuary(sql);
	}
	
	public Object religionWiseDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " DATE(entrydate)>=DATE('"+fromdate+"') and DATE(entrydate)<=DATE('"+todate+"')";
		
		String sql = "select '"+attr+"', religion, count(religion) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+" and pat_id REGEXP '"+center+"') and religion!=3 group by religion";
		if(center.equals("XXXX"))
			sql = "select '"+attr+"', religion, count(religion) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+") and religion!=3 group by religion";
		System.out.println("DiagnosisSummary> religionWiseDiagSummaryNCD(): "+ sql);
		return mydb.ExecuteQuary(sql);			
	}
	
	//Surajit
/*	public Object religionWiseDiagSummaryVisit(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "", queryString1 = "";
		if (fromdate.length()>0 && todate.length()>0){
			queryString = "DATE(visitdate)>=DATE('"+fromdate+"') and DATE(visitdate)<=DATE('"+todate+"')";
			queryString1 = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		}
	
		String sql = "select "+attr+", religion, count(religion) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and religion!=3 and pre.pat_id in (select pat_id from patientvisit where "+queryString+" and pat_id REGEXP '"+center+"') "+queryString1+" group by religion, "+attr+"";
		if(center.equals("XXXX"))
			sql = "select "+attr+", religion, count(religion) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and religion!=3 and pre.pat_id in (select pat_id from patientvisit where "+queryString+") "+queryString1+" group by religion, "+attr+"";
		System.out.println("DiagnosisSummary> religionWiseDiagSummaryVisit():  "+sql);
		return mydb.ExecuteQuary(sql);			
	}
*/	
	//Surajit
	public Object religionWiseDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", splcase = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
			
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}					
		// Exclude Hindu (3) religion
		String sql = "select "+splcase+", religion, count(religion) as noofdiag from ( select "+attr+splcase+", religion from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where religion!=3 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by med.pat_id, religion,"+splcase+" order by "+splcase+") temp group by religion, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", religion, count(religion) as noofdiag from ( select "+attr+splcase+", religion from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where religion!=3 "+queryString+" group by med.pat_id, religion,"+splcase+" order by "+splcase+") temp group by religion, "+splcase+"";
		System.out.println("DiagnosisSummary> religionWiseDiagSummaryUnique(): "+ sql);
		return mydb.ExecuteQuary(sql);
	}	
	
	//Surajit
	public Object otherreligionDiagTotal(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", queryString1 = "", splcase="";
		if (fromdate.length()>0 && todate.length()>0){
			queryString = " DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		}
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";
		
		if(attr.contains("entrydate"))
			splcase = " entry";
		else{
			splcase  = attr;
			attr = "";	
		}		
		String sql = "select "+splcase+", count(*) as noofdiag from (select "+splcase+" from med inner join pre on med.pat_id=pre.pat_id inner join p51 on pre.preid=p51.preid where "+queryString+" and religion not in (3,4) and pre.pat_id REGEXP '"+center+"' group by pre.preid, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
		if (center.equals("XXXX"))
			sql = "select "+splcase+", count(*) as noofdiag from (select "+splcase+" from med inner join pre on med.pat_id=pre.pat_id inner join p51 on pre.preid=p51.preid where "+queryString+" and religion not in (3,4) group by pre.preid, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
		System.out.println("diagnosisSummary> otherreligionDiagTotal(): "+ sql);
		return mydb.ExecuteQuary(sql); 
	}
	
	//Surajit
	public Object otherreligionDiagTotalNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " DATE(entrydate)>=DATE('"+fromdate+"') and DATE(entrydate)<=DATE('"+todate+"')";
		
		String sql = "select '"+attr+"', religion, count(religion) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+" and pat_id REGEXP '"+center+"') and religion not in (3,4) group by religion";
		if(center.equals("XXXX"))
			sql = "select '"+attr+"', religion, count(religion) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+") and religion not in (3,4) group by religion";
		System.out.println("DiagnosisSummary> otherreligionDiagTotalNCD(): "+ sql);
		return mydb.ExecuteQuary(sql);	
	}
	
	
	//Surajit
	public Object otherreligionDiagTotalUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", queryString1 = "", splcase = "";
		if (fromdate.length()>0 && todate.length()>0){
			queryString = " DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		}
		
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
			
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}
				
		String sql = "select "+splcase+", count(*) as noofdiag from (select "+splcase+" from med inner join pre on med.pat_id=pre.pat_id inner join p51 on pre.preid=p51.preid where "+queryString+" and religion not in (3,4) and pre.pat_id REGEXP '"+center+"' group by med.pat_id, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
		if (center.equals("XXXX"))
			sql = "select "+splcase+", count(*) as noofdiag from (select "+splcase+" from med inner join pre on med.pat_id=pre.pat_id inner join p51 on pre.preid=p51.preid where "+queryString+" and religion not in (3,4) group by med.pat_id, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
		System.out.println("diagnosisSummary> otherreligionDiagTotalUnique(): "+ sql);
		return mydb.ExecuteQuary(sql); 
	} 

	
	//Surajit
	public Object hindureligionDiagTotalUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", queryString1 = "", splcase = "";
		if (fromdate.length()>0 && todate.length()>0){
			queryString = " DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		}
		
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
			
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}		
		
		String sql = "select "+splcase+", count(*) as noofdiag from (select "+splcase+" from med inner join pre on med.pat_id=pre.pat_id inner join p51 on pre.preid=p51.preid where "+queryString+" and religion = 3 and pre.pat_id REGEXP '"+center+"' group by med.pat_id, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
		if (center.equals("XXXX"))
			sql = "select "+splcase+", count(*) as noofdiag from (select "+splcase+" from med inner join pre on med.pat_id=pre.pat_id inner join p51 on pre.preid=p51.preid where "+queryString+" and religion = 3 group by med.pat_id, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
		System.out.println("diagnosisSummary> hindureligionDiagTotalUnique(): "+ sql);
		return mydb.ExecuteQuary(sql); 
	} 	
	
	
	//Surajit
	public Object hindureligionDiagTotal(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", queryString1 = "", splcase = "";
		if (fromdate.length()>0 && todate.length()>0){
			queryString = " DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		}
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";	
			
		if(attr.contains("entrydate"))
			splcase = " entry";	
		else{
			splcase  = attr;
			attr = "";	
		}		
		String sql = "select "+splcase+", count(*) as noofdiag from (select "+splcase+" from med inner join pre on med.pat_id=pre.pat_id inner join p51 on pre.preid=p51.preid where "+queryString+" and religion = 3 and pre.pat_id REGEXP '"+center+"' group by pre.preid, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
		if (center.equals("XXXX"))
			sql = "select "+splcase+", count(*) as noofdiag from (select "+splcase+" from med inner join pre on med.pat_id=pre.pat_id inner join p51 on pre.preid=p51.preid where "+queryString+" and religion = 3 group by pre.preid, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
		System.out.println("diagnosisSummary> hindureligionDiagTotal(): "+ sql);
		return mydb.ExecuteQuary(sql);
	}
	
	//Surajit
	public Object hindureligionDiagTotalNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " DATE(entrydate)>=DATE('"+fromdate+"') and DATE(entrydate)<=DATE('"+todate+"')";
		
		String sql = "select '"+attr+"', religion, count(religion) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+" and pat_id REGEXP '"+center+"') and religion = 3 group by religion";
		if(center.equals("XXXX"))
			sql = "select '"+attr+"', religion, count(religion) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+") and religion = 3 group by religion";
		System.out.println("DiagnosisSummary> hindureligionDiagTotalNCD(): "+ sql);
		return mydb.ExecuteQuary(sql);		
	}
	
	
	//Surajit
	public Object childGenderWiseDiagSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", splcase = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";			
		
		if(attr.contains("entrydate"))
			splcase = " entry";
		else{
			splcase  = attr;
			attr = "";	
		}			
		String sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))<=16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))<=16 "+queryString+" group by pre.preid, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		System.out.println("DiagnosisSummary> childGenderWiseDiagSummary(): "+ sql);
		return mydb.ExecuteQuary(sql);		
	}
	
	//Surajit
	public Object childGenderWiseDiagSummaryNCD(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " DATE(entrydate)>=DATE('"+fromdate+"') and DATE(entrydate)<=DATE('"+todate+"')";
		
		String sql = "select '"+attr+"', sex, count(sex) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+" and pat_id REGEXP '"+center+"') and TIMESTAMPDIFF(YEAR, dateofbirth, DATE('"+fromdate+"'))<=16 group by sex";
		if(center.equals("XXXX"))
			sql = "select '"+attr+"', sex, count(sex) as noofdiag from med where pat_id in (select distinct pat_id from ncd where COALESCE("+attr+"_status, '')!='' and "+queryString+") and TIMESTAMPDIFF(YEAR, dateofbirth, DATE('"+fromdate+"'))<=16 group by sex";
		System.out.println("DiagnosisSummary> childGenderWiseDiagSummaryNCD(): "+ sql);
		return mydb.ExecuteQuary(sql);	
	}
	
	//Surajit
/*	public Object childGenderWiseDiagSummaryVisit(String fromdate, String todate, String center, String attr) throws RemoteException, SQLException{
		String queryString = "", queryString1 = "";
		if (fromdate.length()>0 && todate.length()>0){
			queryString = "DATE(visitdate)>=DATE('"+fromdate+"') and DATE(visitdate)<=DATE('"+todate+"')";
			queryString1 = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		}
	
		String sql = "select "+attr+", sex, count(sex) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and SUBSTRING_INDEX(age,',',1)<=16 and pre.pat_id in (select pat_id from patientvisit where "+queryString+" and pat_id REGEXP '"+center+"') "+queryString1+" group by sex, "+attr+"";
		if(center.equals("XXXX"))
			sql = "select "+attr+", sex, count(sex) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and SUBSTRING_INDEX(age,',',1)<=16 and pre.pat_id in (select pat_id from patientvisit where "+queryString+") "+queryString1+" group by sex, "+attr+"";
		System.out.println("DiagnosisSummary> childGenderWiseDiagSummaryVisit():  "+sql);
		return mydb.ExecuteQuary(sql);		
	}
	*/
	
	//Surajit
	public Object childGenderWiseDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		String queryString = "", splcase = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";			
		
		if(attr.contains("entrydate"))
			splcase = " entry";
		else{
			splcase  = attr;
			attr = "";	
		}			
		String sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))<=16 "+queryString+" and pre.pat_id REGEXP '"+center+"' group by med.pat_id, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", sex, count(sex) as noofdiag from ( select "+attr+splcase+", sex from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where (TIMESTAMPDIFF(YEAR,med.entrydate, pre.entrydate)+SUBSTRING_INDEX(age,',',1))<=16 "+queryString+" group by med.pat_id, sex,"+splcase+" order by "+splcase+") temp group by sex, "+splcase+"";
		System.out.println("DiagnosisSummary> childGenderWiseDiagSummaryUnique(): "+ sql);
		return mydb.ExecuteQuary(sql);		
	}	
	
	
	
	//Surajit
	public Object oldPatientDiagSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		/*
		String queryString = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " and DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		String sql = "select basic_diagnosis, count(value) as noofdiag from p51 where preid in (select preid from pre where pat_id in (select pat_id from patientvisit group by 1 having count(pat_id) > 1) and preid is not NULL "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pat_id) group by basic_diagnosis";
		if(center.equals("XXXX"))
			sql = "select basic_diagnosis, count(value) as noofdiag from p51 where preid in (select preid from pre where pat_id in (select pat_id from patientvisit group by 1 having count(pat_id) > 1) and preid is not NULL "+queryString+" group by pat_id) group by basic_diagnosis";
		System.out.println("DiagnosisSummary> oldPatientDiagSummary(): "+ sql);
		return mydb.ExecuteQuary(sql);
		* */
/*
		String queryString = "", splcase = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)<DATE('"+fromdate+"') ";
							
		String sql = "select basic_diagnosis, count(*) as noofdiag from ( select basic_diagnosis from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, basic_diagnosis order by basic_diagnosis) temp group by basic_diagnosis";
		if(center.equals("XXXX"))
			sql = "select basic_diagnosis, count(*) as noofdiag from ( select basic_diagnosis from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where "+queryString+" group by pre.preid, basic_diagnosis order by basic_diagnosis) temp group by basic_diagnosis";
		System.out.println("DiagnosisSummary> oldPatientDiagSummary(): "+ sql);
		return mydb.ExecuteQuary(sql);		
		* */
		
		String queryString = "", splcase = "";
	
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate) != DATE(pre.entrydate) ";
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";
		
		if(attr.contains("entrydate"))
			splcase = " entry";
		else{
			splcase  = attr;
			attr = "";	
		}	
									
		String sql = "select "+splcase+", count(*) as noofdiag from ( select "+splcase+" from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", count(*) as noofdiag from ( select "+splcase+" from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where "+queryString+" group by pre.preid, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
		System.out.println("DiagnosisSummary> oldPatientDiagSummary(): "+ sql);
		return mydb.ExecuteQuary(sql);			
		
	}
	
	//Surajit
	public Object oldPatientDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		/*
		String queryString = "", queryString1 = "";
		if (fromdate.length()>0 && todate.length()>0){
			queryString = " DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		}
		String sql = "select basic_diagnosis, count(*) as noofdiag from (select basic_diagnosis from med inner join pre on med.pat_id=pre.pat_id inner join p51 on pre.preid=p51.preid where "+queryString+" and pre.pat_id REGEXP '"+center+"' and p51.preid in (select preid from pre where pat_id in (select pat_id from patientvisit group by 1 having count(pat_id)>1)) group by med.pat_id, basic_diagnosis order by basic_diagnosis) temp group by basic_diagnosis";
		//String sql = "select basic_diagnosis, count(basic_diagnosis) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and pre.pat_id in (select pat_id from patientvisit where "+queryString+" and pat_id REGEXP '"+center+"' group by 1 having count(pat_id) > 1) "+queryString1+" group by basic_diagnosis;";
		if (center.equals("XXXX"))
			//sql = "select basic_diagnosis, count(basic_diagnosis) as noofdiag from pre inner join p51 inner join med on pre.pat_id = med.pat_id where pre.preid=p51.preid and pre.pat_id in (select pat_id from patientvisit where "+queryString+" group by 1 having count(pat_id) > 1) "+queryString1+" group by basic_diagnosis;";
			sql = "select basic_diagnosis, count(*) as noofdiag from (select basic_diagnosis from med inner join pre on med.pat_id=pre.pat_id inner join p51 on pre.preid=p51.preid where "+queryString+" and p51.preid in (select preid from pre where pat_id in (select pat_id from patientvisit group by 1 having count(pat_id)>1)) group by med.pat_id, basic_diagnosis order by basic_diagnosis) temp group by basic_diagnosis";
		System.out.println("diagnosisSummary> oldPatientDiagSummaryUnique(): "+ sql);
		return mydb.ExecuteQuary(sql); 
		* */
		
		
		
		String queryString = "", splcase = "", financial_year_start_date = "";
		int financial_year_month = 0;
		financial_year_month = Integer.valueOf(todate.split("-")[1]);
		financial_year_start_date = (financial_year_month<=3)? String.valueOf(Integer.valueOf(todate.split("-")[0])-1)+"-04-01" : todate.split("-")[0]+"-04-01";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)<DATE('"+financial_year_start_date+"') ";
		
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";			
		
		if(attr.contains("entrydate"))
			splcase = " entry";
		else{
			splcase  = attr;
			attr = "";	
		}		
							
		String sql = "select "+splcase+", count(*) as noofdiag from ( select "+splcase+" from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where "+queryString+" and pre.pat_id REGEXP '"+center+"' group by med.pat_id, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", count(*) as noofdiag from ( select "+splcase+" from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where "+queryString+" group by med.pat_id, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
		System.out.println("DiagnosisSummary> oldPatientDiagSummaryUnique(): "+ sql);
		return mydb.ExecuteQuary(sql);		
		
	}
	
	//Surajit
	public Object newPatientDiagSummary(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		/*
		String queryString = "";
		if (fromdate.length()>0 && todate.length()>0)
			queryString = " and DATE(med.entrydate)>=DATE('"+fromdate+"') and DATE(med.entrydate)<=DATE('"+todate+"')";
		String sql = "select basic_diagnosis, count(value) as noofdiag from p51 where preid in (select preid from pre inner join med on pre.pat_id=med.pat_id where preid is not NULL "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.pat_id) group by basic_diagnosis";
		if(center.equals("XXXX"))
			sql = "select basic_diagnosis, count(value) as noofdiag from p51 where preid in (select preid from pre inner join med on pre.pat_id = med.pat_id where preid is not NULL "+queryString+" group by pre.pat_id) group by basic_diagnosis";
		System.out.println("DiagnosisSummary> newPatientDiagSummary(): "+ sql);
		return mydb.ExecuteQuary(sql);
		* */

/*		
		String queryString = "", splcase = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)>=DATE('"+fromdate+"') and DATE(med.entrydate)<=DATE('"+todate+"')";
						
		String sql = "select basic_diagnosis, count(*) as noofdiag from ( select basic_diagnosis from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, basic_diagnosis order by basic_diagnosis) temp group by  basic_diagnosis";
		if(center.equals("XXXX"))
			sql = "select basic_diagnosis, count(*) as noofdiag from ( select basic_diagnosis from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where "+queryString+" group by pre.preid, basic_diagnosis order by basic_diagnosis) temp group by basic_diagnosis";
		System.out.println("DiagnosisSummary> newPatientDiagSummary(): "+ sql);
		return mydb.ExecuteQuary(sql);		
		* */
		String queryString = "", splcase = "";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate) = DATE(pre.entrydate)";
			
		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";
		
		if(attr.contains("entrydate"))
			splcase = " entry";
		else{
			splcase  = attr;
			attr = "";	
		}						
		String sql = "select "+splcase+", count(*) as noofdiag from ( select "+splcase+" from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where "+queryString+" and pre.pat_id REGEXP '"+center+"' group by pre.preid, "+splcase+" order by "+splcase+") temp group by  "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", count(*) as noofdiag from ( select "+splcase+" from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where "+queryString+" group by pre.preid, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
		System.out.println("DiagnosisSummary> newPatientDiagSummary(): "+ sql);
		return mydb.ExecuteQuary(sql);			
	}	


	//Surajit
	public Object newPatientDiagSummaryUnique(String fromdate, String todate, String center, String attr, String diag) throws RemoteException, SQLException{
		
		/*
		String queryString = "", queryString1 = "";
		if (fromdate.length()>0 && todate.length()>0){
			queryString = " DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"')";
		}
		String sql = "select basic_diagnosis, count(*) as noofdiag from (select basic_diagnosis from med inner join pre on med.pat_id=pre.pat_id inner join p51 on pre.preid=p51.preid where "+queryString+" and pre.pat_id REGEXP '"+center+"' and p51.preid in (select preid from pre where pat_id in (select pat_id from patientvisit group by 1 having count(pat_id)=1)) group by med.pat_id, basic_diagnosis order by basic_diagnosis) temp group by basic_diagnosis";
		if (center.equals("XXXX"))
			sql = "select basic_diagnosis, count(*) as noofdiag from (select basic_diagnosis from med inner join pre on med.pat_id=pre.pat_id inner join p51 on pre.preid=p51.preid where "+queryString+" and p51.preid in (select preid from pre where pat_id in (select pat_id from patientvisit group by 1 having count(pat_id)=1)) group by med.pat_id, basic_diagnosis order by basic_diagnosis) temp group by basic_diagnosis";
		System.out.println("diagnosisSummary> newPatientDiagSummaryUnique(): "+ sql);
		return mydb.ExecuteQuary(sql); 
		* */
		String queryString = "", splcase = "", financial_year_start_date = "", financial_year_end_date = "";
		int financial_year_month = 0;
		financial_year_month = Integer.valueOf(todate.split("-")[1]);
		financial_year_start_date = (financial_year_month<=3)? String.valueOf(Integer.valueOf(todate.split("-")[0])-1)+"-04-01" : todate.split("-")[0]+"-04-01";
		financial_year_end_date = (financial_year_month<=3)? todate.split("-")[0]+"-03-31" : String.valueOf(Integer.valueOf(todate.split("-")[0])+1)+"-03-31";
		if (fromdate.length()>0  && todate.length()>0)
			queryString = " DATE(pre.entrydate)>=DATE('"+fromdate+"') and DATE(pre.entrydate)<=DATE('"+todate+"') and DATE(med.entrydate)>=DATE('"+financial_year_start_date+"') and DATE(med.entrydate)<=DATE('"+financial_year_end_date+"')";

		if (diag.length()>0)
			queryString += " and p51.basic_diagnosis='"+diag+"'";			
		
		if(attr.contains("entrydate"))
			splcase = " entry";
		else{
			splcase  = attr;
			attr = "";	
		}

						
		String sql = "select "+splcase+", count(*) as noofdiag from ( select "+splcase+" from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where "+queryString+" and pre.pat_id REGEXP '"+center+"' group by med.pat_id, "+splcase+" order by "+splcase+") temp group by  "+splcase+"";
		if(center.equals("XXXX"))
			sql = "select "+splcase+", count(*) as noofdiag from ( select "+splcase+" from med inner join pre on med.pat_id = pre.pat_id inner join p51 on pre.preid = p51.preid where "+queryString+" group by med.pat_id, "+splcase+" order by "+splcase+") temp group by "+splcase+"";
		System.out.println("DiagnosisSummary> newPatientDiagSummaryUnique(): "+ sql);
		return mydb.ExecuteQuary(sql);		
		
	}
	
	// Mithun
	public Object getDiagnosis(String preid) throws SQLException, RemoteException{
		String sql = "select * from p51 where preid='"+preid+"'";
		System.out.println("DisplayData->getDiagnosis: "+ sql);
		return mydb.ExecuteQuary(sql);
	}

	// Mithun
	public Object getObservationAndAdvice(String preid) throws SQLException, RemoteException{
		String sql = "select * from p52 where preid='"+preid+"'";
		System.out.println("DisplayData->getObservationAndAdvice: "+ sql);
		return mydb.ExecuteQuary(sql);
	}

	// Mithun
	public Object getLastChiefComplaint(String pat_id) throws SQLException, RemoteException{
		String sql = "Select * from a14 where pat_id='"+pat_id+"' order by serno desc limit 1";
		System.out.println("DisplayData->getLastChiefComplaint: "+ sql);
		return mydb.ExecuteQuary(sql);
	}
	//Soumya_B
	public Object getLastNotes(String pat_id) throws SQLException, RemoteException{
		String sql = "Select * from psyNotes where pat_id='"+pat_id+"' order by serno desc limit 1";
		System.out.println("DisplayData->getLastNotes: "+ sql);
		return mydb.ExecuteQuary(sql);
	}

	// Mithun
	public Object getChiefComplaints(String pat_id, String entrydate, String serno) throws SQLException, RemoteException{
		String sql = "select * from a14_extra where pat_id='"+pat_id+"' and entrydate='"+entrydate+"' and serno="+ serno;
		System.out.println("DisplayData->getChiefComplaints: "+ sql);
		return mydb.ExecuteQuary(sql);
	}
	//Soumya_B
	public Object getNotes(String pat_id, String entrydate, String serno) throws SQLException, RemoteException{
		String sql = "select * from psyNotes where pat_id='"+pat_id+"' and entrydate='"+entrydate+"' and serno="+ serno;
		System.out.println("DisplayData->getNotes: "+ sql);
		return mydb.ExecuteQuary(sql);
	}
	/*Soumyajit*/
	public Object stats_age_sex_caste(String centre, String fromdt, String todt) throws SQLException, RemoteException{
		String sql="";
		if(centre.equalsIgnoreCase("XXXX"))
		{
			sql="select distinct(p.pat_id),concat_ws(' ',m.pat_name,m.m_name,m.l_name) as patname,DATE_FORMAT(p.entrydate, '%Y-%m-%d') as entrydate,sex,age,caste_category,m_status,p.docrg_no,l.name,substring(p.pat_id,1,7) as center from pre as p,med as m,login as l where p.pat_id=m.pat_id and l.rg_no=p.docrg_no and (DATE(p.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(p.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) order by substring(p.pat_id,1,7)";
		}
		else
		{
			sql="select distinct(p.pat_id),concat_ws(' ',m.pat_name,m.m_name,m.l_name) as patname,DATE_FORMAT(p.entrydate, '%Y-%m-%d') as entrydate,sex,age,caste_category,m_status,p.docrg_no,l.name,substring(p.pat_id,1,7) as center from pre as p,med as m,login as l where p.pat_id=m.pat_id and l.rg_no=p.docrg_no and p.pat_id like '"+centre+"%' and (DATE(p.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(p.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) order by substring(p.pat_id,1,7)";
		}
		System.out.println(sql);
		return mydb.ExecuteQuary(sql);
	}
	/*Soumyajit*/
	public Object CNT_stats_sex_caste(String centre, String fromdt, String todt,String tag) throws SQLException, RemoteException{
		String sql="";
		if(centre.equalsIgnoreCase("XXXX"))
		{
			sql="select count(distinct(p.pat_id)) as count,substring(p.pat_id,1,7) as center,m."+tag+" from pre as p,med as m,login as l where p.pat_id=m.pat_id and l.rg_no=p.docrg_no and (DATE(p.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(p.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) group by m."+tag+",substring(p.pat_id,1,7) order by substring(p.pat_id,1,7)";
		}
		else
		{
			sql="select count(distinct(p.pat_id)) as count,substring(p.pat_id,1,7) as center,m."+tag+" from pre as p,med as m,login as l where p.pat_id=m.pat_id and l.rg_no=p.docrg_no and p.pat_id like '"+centre+"%' and (DATE(p.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(p.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) group by m."+tag+",substring(p.pat_id,1,7) order by substring(p.pat_id,1,7)";			
		}
		System.out.println(sql);
		return mydb.ExecuteQuary(sql);
	}
	/*Soumyajit*/
	public Object stats_disease(String centre,String diagnosis,String fromdt, String todt) throws SQLException,RemoteException
	{
		String sql="";
		if(centre.equalsIgnoreCase("XXXX"))
		{
			if(diagnosis.length()!=0)
			{
				sql="select pre.pat_id,concat_ws(' ',m.pat_name,m.m_name,m.l_name) as patname,DATE_FORMAT(pre.entrydate, '%Y-%m-%d') as entrydate,l.name as docname,m.sex,m.age,m.caste_category,concat_ws(' ',pre.diagnosis,p51.value) as diag from pre left join p51 on pre.preid=p51.preid join med as m on pre.pat_id =m.pat_id join login as l on l.rg_no=pre.docrg_no and (DATE(pre.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(pre.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) where pre.diagnosis like '%"+diagnosis+"%' or p51.value like '%"+diagnosis+"%' group by pre.entrydate";
			}
			else
			{
				sql="select pre.pat_id,concat_ws(' ',m.pat_name,m.m_name,m.l_name) as patname,DATE_FORMAT(pre.entrydate, '%Y-%m-%d') as entrydate,l.name as docname,m.sex,m.age,m.caste_category,concat_ws(' ',pre.diagnosis,p51.value) as diag from pre left join p51 on pre.preid=p51.preid join med as m on pre.pat_id =m.pat_id join login as l on l.rg_no=pre.docrg_no and (DATE(pre.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(pre.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) group by pre.entrydate";
			}
		}
		else{
			if(diagnosis.length()!=0)
			{
				sql="select pre.pat_id,concat_ws(' ',m.pat_name,m.m_name,m.l_name) as patname,DATE_FORMAT(pre.entrydate, '%Y-%m-%d') as entrydate,l.name as docname,m.sex,m.age,m.caste_category,concat_ws(' ',pre.diagnosis,p51.value) as diag from pre left join p51 on pre.preid=p51.preid join med as m on pre.pat_id =m.pat_id join login as l on l.rg_no=pre.docrg_no and pre.pat_id like '"+centre+"%' and (DATE(pre.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(pre.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) where pre.diagnosis like '%"+diagnosis+"%' or p51.value like '%"+diagnosis+"%' group by pre.entrydate";
			}
			else
			{
				sql="select pre.pat_id,concat_ws(' ',m.pat_name,m.m_name,m.l_name) as patname,DATE_FORMAT(pre.entrydate, '%Y-%m-%d') as entrydate,l.name as docname,m.sex,m.age,m.caste_category,concat_ws(' ',pre.diagnosis,p51.value) as diag from pre left join p51 on pre.preid=p51.preid join med as m on pre.pat_id =m.pat_id join login as l on l.rg_no=pre.docrg_no and pre.pat_id like '"+centre+"%' and (DATE(pre.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(pre.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) group by pre.entrydate";
			}

		}
		System.out.println(sql);
		return mydb.ExecuteQuary(sql);

	}
	/*Soumyajit*/
	public Object stats_disease_count(String centre,String diagnosis,String fromdt, String todt) throws SQLException,RemoteException
	{
		String sql="";
		if(centre.equalsIgnoreCase("XXXX"))
		{
			sql="select count(pre.pat_id) as cnt from pre left join p51 on pre.preid=p51.preid join med as m on pre.pat_id =m.pat_id join login as l on l.rg_no=pre.docrg_no and (DATE(pre.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(pre.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) where pre.diagnosis like '%"+diagnosis+"%' or p51.value like '%"+diagnosis+"%' ";
			/*if(diagnosis.length()!=0)
			{
				sql="select count(pre.pat_id) as cnt from pre left join p51 on pre.preid=p51.preid join med as m on pre.pat_id =m.pat_id join login as l on l.rg_no=pre.docrg_no and (DATE(pre.entrydate) > DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(pre.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) where pre.diagnosis like '%"+diagnosis+"%' or p51.value like '%"+diagnosis+"%' ";
			}
			else
			{
				sql="select count(pre.pat_id) as cnt from pre left join p51 on pre.preid=p51.preid join med as m on pre.pat_id =m.pat_id join login as l on l.rg_no=pre.docrg_no and pre.pat_id like '"+centre+"%' and (DATE(pre.entrydate) > DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(pre.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) group by concat_ws(' ',pre.diagnosis,p51.value)";
			}*/
		}
		else
		{
			sql="select count(pre.pat_id) as cnt from pre left join p51 on pre.preid=p51.preid join med as m on pre.pat_id =m.pat_id join login as l on l.rg_no=pre.docrg_no and pre.pat_id like '"+centre+"%' and (DATE(pre.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(pre.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) where pre.diagnosis like '%"+diagnosis+"%' or p51.value like '%"+diagnosis+"%' ";
		}


		System.out.println(sql);
		return mydb.ExecuteQuary(sql);

	}

	/*Soumyajit*/
	public Object stats_disease_count2(String centre,String diagnosis,String fromdt, String todt) throws SQLException,RemoteException
	{
		String sql="";
		if(centre.equalsIgnoreCase("XXXX"))
		{
			sql="select count(distinct pre.pat_id) as cnt from pre left join p51 on pre.preid=p51.preid join med as m on pre.pat_id =m.pat_id join login as l on l.rg_no=pre.docrg_no and (DATE(pre.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(pre.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) where pre.diagnosis like '%"+diagnosis+"%' or p51.value like '%"+diagnosis+"%' ";	
		}
		else
		{
			sql="select count(distinct pre.pat_id) as cnt from pre left join p51 on pre.preid=p51.preid join med as m on pre.pat_id =m.pat_id join login as l on l.rg_no=pre.docrg_no and pre.pat_id like '"+centre+"%' and (DATE(pre.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(pre.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) where pre.diagnosis like '%"+diagnosis+"%' or p51.value like '%"+diagnosis+"%' ";
		}


		System.out.println(sql);
		return mydb.ExecuteQuary(sql);

	}




	/*Soumyajit*/
	public Object stats_allvisit(String centre,String fromdt, String todt) throws SQLException,RemoteException
	{
		String sql="";
		//select pre.pat_id,concat_ws(' ',m.pat_name,m.m_name,m.l_name) as patname,pre.entrydate,pre.serno from pre join med as m on pre.pat_id=m.pat_id order by pat_id;
		//select pre.pat_id,concat_ws(' ',m.pat_name,m.m_name,m.l_name) as patname,pre.entrydate,pre.serno from pre join med as m on pre.pat_id=m.pat_id where pre.pat_id like 'VBCR019%'  order by pat_id;

		if(!centre.equalsIgnoreCase("XXXX"))
		{
			//sql="select pre.pat_id,concat_ws(' ',m.pat_name,m.m_name,m.l_name) as patname,count(pre.serno) as cnt from pre join med as m on pre.pat_id=m.pat_id where pre.pat_id like '"+centre+"%' group by pat_id order by pat_id";
			sql="select pre.pat_id,concat_ws(' ',m.pat_name,m.m_name,m.l_name) as patname,count(pre.serno) as cnt from pre join med as m on pre.pat_id=m.pat_id where pre.pat_id like '"+centre+"%' and (DATE(pre.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(pre.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) group by pat_id order by pat_id";
		}
		else
		{
			//sql="select pre.pat_id,concat_ws(' ',m.pat_name,m.m_name,m.l_name) as patname,count(pre.serno) as cnt from pre join med as m on pre.pat_id=m.pat_id group by pat_id order by pat_id";
			sql="select pre.pat_id,concat_ws(' ',m.pat_name,m.m_name,m.l_name) as patname,count(pre.serno) as cnt from pre join med as m on pre.pat_id=m.pat_id where (DATE(pre.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(pre.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) group by pat_id order by pat_id";
		}
		System.out.println(sql);
		return mydb.ExecuteQuary(sql);
	}

	/*Soumyajit*/
	public Object stats_visitpat(String patid,String fromdt, String todt) throws SQLException,RemoteException
	{
		String sql="";
		//select pre.pat_id,concat_ws(' ',m.pat_name,m.m_name,m.l_name) as patname,pre.entrydate,pre.serno from pre join med as m on pre.pat_id=m.pat_id order by pat_id;
		//select pre.pat_id,concat_ws(' ',m.pat_name,m.m_name,m.l_name) as patname,pre.entrydate,pre.serno from pre join med as m on pre.pat_id=m.pat_id where pre.pat_id like 'VBCR019%'  order by pat_id;

		//sql="select pre.pat_id,concat_ws(' ',m.pat_name,m.m_name,m.l_name) as patname,pre.entrydate,pre.serno from pre join med as m on pre.pat_id=m.pat_id where pre.pat_id like '"+patid+"'";

		sql="select pre.pat_id,concat_ws(' ',m.pat_name,m.m_name,m.l_name) as patname,pre.entrydate,pre.serno from pre join med as m on pre.pat_id=m.pat_id where pre.pat_id like '"+patid+"' and (DATE(pre.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(pre.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d'))";
		
		System.out.println(sql);
		return mydb.ExecuteQuary(sql);
	}
	/*Soumyajit*/
	public Object CNT_stats_religion_caste(String centre, String fromdt, String todt) throws SQLException, RemoteException{
		String sql="";
		if(centre.equalsIgnoreCase("XXXX"))
		{
			//sql="select count(distinct(p.pat_id)) as count,substring(p.pat_id,1,7) as center,m."+tag+" from pre as p,med as m,login as l where p.pat_id=m.pat_id and l.rg_no=p.docrg_no and (DATE(p.entrydate) > DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(p.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) group by m."+tag+",substring(p.pat_id,1,7) order by substring(p.pat_id,1,7)";
			sql="select count(p.pat_id) as count,substring(p.pat_id,1,7) as center, m.caste_category,m.religion from pre as p,med as m,login as l where p.pat_id=m.pat_id and l.rg_no=p.docrg_no and (DATE(p.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(p.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) group by m.caste_category,religion";
		}
		else
		{
			sql="select count(p.pat_id) as count,substring(p.pat_id,1,7) as center, m.caste_category,m.religion from pre as p,med as m,login as l where p.pat_id=m.pat_id and l.rg_no=p.docrg_no and p.pat_id like 'VBCR%' and (DATE(p.entrydate) >= DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(p.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) group by m.caste_category,religion";

			//sql="select count(distinct(p.pat_id)) as count,substring(p.pat_id,1,7) as center,m."+tag+" from pre as p,med as m,login as l where p.pat_id=m.pat_id and l.rg_no=p.docrg_no and p.pat_id like '"+centre+"%' and (DATE(p.entrydate) > DATE_FORMAT(STR_TO_DATE('"+fromdt+"','%d/%m/%Y'), '%Y-%m-%d') and DATE(p.entrydate) <= DATE_FORMAT(STR_TO_DATE('"+todt+"', '%d/%m/%Y'), '%Y-%m-%d')) group by m."+tag+",substring(p.pat_id,1,7) order by substring(p.pat_id,1,7)";			
		}
		System.out.println(sql);
		return mydb.ExecuteQuary(sql);
	}
	
	
	//Surajit
	public Object ncdScreeningView(String pat_id) throws SQLException, RemoteException{
		String sql = "";
		sql = "select ht_status, ht_symptoms, dm_status, dm_symptoms, bc_status, bc_symptoms, oc_status, oc_symptoms, entrydate from ncd where pat_id = '"+pat_id+"'";
		System.out.println(sql);
		return mydb.ExecuteQuary(sql); 
	}


	/*Soumya_B*/
	public Object getPrescribedTests(String patid) throws RemoteException, SQLException {
    String sql = "SELECT * FROM PrescribedTests WHERE pat_id = '"+patid+"'";
    System.out.println("DisplayData->getPrescribedTests: "+ sql);
    return mydb.ExecuteQuary(sql);
	}


	/*Soumya_B*/
	// public Object getTobaccoAssessmentData(String patid) throws RemoteException, SQLException {
   //  String outputstr = "";
   //  String qSql = "SELECT rid, subject_id, survey_datetime, sid, record_type, survey_data FROM record_log " +
   //               "WHERE subject_id = '" + patid + "' ORDER BY survey_datetime DESC";
    
   //  System.out.println("getTobaccoAssessmentData: " + qSql);
   //  return mydb.ExecuteQuary(qSql);
	// }
	// Add this method implementation
	public Object getTobaccoAssessmentData(String patid) throws RemoteException, SQLException {
    try {
        String qSql = "SELECT rid, subject_id, survey_datetime, sid, record_type, survey_data " +
                      "FROM record_log " +
                      "WHERE subject_id = '" + patid + "' " +
                      "ORDER BY survey_datetime DESC";
        
        System.out.println("getTobaccoAssessmentData: " + qSql);
        return mydb.ExecuteQuary(qSql);
    		} catch (Exception e) {
        System.out.println("Error in getTobaccoAssessmentData: " + e.toString());
        throw e;
    	}
	}

	/*Soumya_B*/

	public Object getSurveyFormDetails(String surveyName) throws RemoteException, SQLException {
    String qSql = "SELECT * FROM survey_project WHERE name = '"+surveyName+"'";
    System.out.println("getSurveyFormDetails(): "+qSql);
    return mydb.ExecuteQuary(qSql);
	}

	public Object getSurveyFormBySid(String sid) throws RemoteException, SQLException {
	    String qSql = "SELECT * FROM survey_project WHERE sid = '"+sid+"'";
	    System.out.println("getSurveyFormBySid(): "+qSql);
	    return mydb.ExecuteQuary(qSql);
	}

	public Object getPatientPrescribedSurveys(String patId) throws RemoteException, SQLException {
	    String qSql = "SELECT p.slno, p.pat_id, p.prescribed_tests, s.sid, s.name, s.description " +
	                  "FROM PrescribedTests p " +
	                  "JOIN survey_project s ON p.prescribed_tests = s.name " +
	                  "WHERE p.pat_id = '"+patId+"'";
	    System.out.println("getPatientPrescribedSurveys(): "+qSql);
	    return mydb.ExecuteQuary(qSql);
	}

	public Object getPatientSurveyResponses(String patId /*String sid*/) throws RemoteException, SQLException {
	    String qSql = "SELECT rid, subject_id, survey_datetime, sid, record_type, survey_data, score " +
                      "FROM record_log " +
                      "WHERE subject_id = '" + patId + "' " +
                      "ORDER BY survey_datetime DESC";
	    System.out.println("getPatientSurveyResponses(): "+qSql);
	    return mydb.ExecuteQuary(qSql);
	}

	public boolean saveSurveyResponse(String patId, String sid, String surveyData, String userId, String submittedBy) throws RemoteException, SQLException {
    try {
        // Generate a unique record ID
        String rid = sid + "_" + System.currentTimeMillis() % 1000;
        
        // Format current date/time for the database
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        String timestamp = dateFormat.format(new Date());
        
        // Escape single quotes in surveyData to prevent SQL injection
        surveyData = surveyData.replace("'", "''");
        
        // Use default values if parameters are empty
        if (userId == null || userId.isEmpty()) userId = patId;
        String username = userId;
        
        // Default submittedBy to "patient" if not provided
        if (submittedBy == null || submittedBy.isEmpty()) submittedBy = "patient";
        
        // Insert survey response with submittedBy in record_type field
        String qSql = "INSERT INTO record_log (rid, subject_id, survey_datetime, sid, record_type, survey_data, userid, username) " +
                     "VALUES ('"+rid+"', '"+patId+"', '"+timestamp+"', '"+sid+"', '"+submittedBy+"', '"+surveyData+"', '"+userId+"', '"+username+"')";
        System.out.println("saveSurveyResponse(): "+qSql);
        
        mydb.ExecuteSql(qSql);
        return true;
    } catch (Exception e) {
        System.out.println("Error saving survey response: "+e.toString());
        e.printStackTrace();
        return false;
    }
}
	/*Soumya*/
	public Object getChatControlSettings(String patId) throws RemoteException, SQLException {
	    String sql = "SELECT pat_id, daily_chat_limit, max_session_duration, min_session_interval, " +
	                "blackout_start_time, blackout_end_time, blackout_days " +
	                "FROM chat_control WHERE pat_id = '" + patId + "'";
	    return mydb.ExecuteQuary(sql);
}

	/*Srijit*/
	public String getChatType(String patId) throws RemoteException, SQLException {
	    String sql = "SELECT chat_type FROM chat_control WHERE pat_id = '" + patId + "'";
	    String chatType = mydb.ExecuteSingle(sql);
	    return (chatType != null && !chatType.trim().isEmpty()) ? chatType : "original";
}

	/*Srijit*/
	public Object getSessionSummaryBySessionId(String sessionId) throws RemoteException, SQLException {
	    String sql = "SELECT sh.session_id, sh.session_date, sh.start_time, sh.session_summary, " +
	                "si.readiness, si.concerns, si.triggers, si.advice, si.quit_history, si.suicidal_ideation " +
	                "FROM session_history sh LEFT JOIN signal_history si ON sh.signal_id = si.signal_id " +
	                "WHERE sh.session_id = '" + sessionId + "'";
	    return mydb.ExecuteQuary(sql);
	}

	/*Srijit*/
	public Object getSessionSummaryByPatId(String patId) throws RemoteException, SQLException {
	    String sql = "SELECT sh.session_id, sh.session_date, sh.start_time, sh.session_summary, " +
	                "si.readiness, si.concerns, si.triggers, si.advice, si.quit_history, si.suicidal_ideation " +
	                "FROM session_history sh LEFT JOIN signal_history si ON sh.signal_id = si.signal_id " +
	                "WHERE sh.pat_id = '" + patId + "' ORDER BY sh.session_date ASC, sh.start_time ASC";
	    return mydb.ExecuteQuary(sql);
	}

	/*Srijit*/
	public boolean updateSessionDeltaFields(long deltaId, String persistentTriggers, String persistentConcerns, String cumulativeQuitHistory, String continuedAdvice, String readinessAfter) throws RemoteException, SQLException {
	    String sql = "UPDATE session_deltas SET persistent_triggers = '" + esc(persistentTriggers) +
	                "', persistent_concerns = '" + esc(persistentConcerns) +
	                "', cumulative_quit_history = '" + esc(cumulativeQuitHistory) +
	                "', continued_advice = '" + esc(continuedAdvice) +
	                "', readiness_after = '" + esc(readinessAfter) +
	                "' WHERE delta_id = " + deltaId;
	    return "Done".equals(mydb.ExecuteSql(sql));
	}

	/*Srijit*/
	public boolean queueAnnotation(String patId, String sessionId, boolean forceReannotate) throws RemoteException, SQLException {
	    String sql = "INSERT INTO pipeline_jobs (pat_id, session_id, force_reannotate, status, created_at) VALUES ('" +
	                patId + "', '" + sessionId + "', " + (forceReannotate ? 1 : 0) + ", 'pending', NOW())";
	    return "Done".equals(mydb.ExecuteSql(sql));
	}

	/*Srijit*/
	public Object getLatestPipelineRun(String conversationId) throws RemoteException, SQLException {
	    String sql = "SELECT run_id, conversation_id, patient_id, " +
	                "DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s') AS created_at, " +
	                "total_rounds, rounds, consensus, dataset_row, " +
	                "session_delta, longitudinal_sanity, longitudinal_output " +
	                "FROM pipeline_runs WHERE conversation_id = '" + conversationId + "' " +
	                "ORDER BY created_at DESC LIMIT 1";
	    return mydb.ExecuteQuary(sql);
	}

	/*Srijit*/
	public Object getSessionDeltaByToSessionId(String sessionId) throws RemoteException, SQLException {
	    String sql = "SELECT * FROM session_deltas WHERE to_session_id = '" + sessionId + "' LIMIT 1";
	    return mydb.ExecuteQuary(sql);
	}

	/*Srijit*/
	public boolean updateDeltaClinicalSummary(String sessionId, String summary) throws RemoteException, SQLException {
	    String sql = "UPDATE session_deltas SET clinical_summary = '" + esc(summary) +
	                "' WHERE to_session_id = '" + sessionId + "'";
	    return "Done".equals(mydb.ExecuteSql(sql));
	}

	/*Srijit*/
	public Object getLatestPatientMemory(String patId) throws RemoteException, SQLException {
	    String sql = "SELECT delta_id, persistent_triggers, persistent_concerns, cumulative_quit_history, continued_advice, readiness_after " +
	                "FROM session_deltas WHERE pat_id = '" + patId + "' ORDER BY to_session_date DESC, delta_id DESC LIMIT 1";
	    return mydb.ExecuteQuary(sql);
	}

	/*Srijit*/
	public boolean isSessionAnnotated(String signalId) throws RemoteException, SQLException {
	    String sql = "SELECT 1 FROM signal_history WHERE signal_id = '" + signalId + "' LIMIT 1";
	    String found = mydb.ExecuteSingle(sql);
	    return found != null && !found.trim().isEmpty();
	}

	/*Srijit*/
	public Object getPipelineJobStatusCounts() throws RemoteException, SQLException {
	    String sql = "SELECT status, COUNT(*) AS cnt FROM pipeline_jobs GROUP BY status";
	    return mydb.ExecuteQuary(sql);
	}

	/*Srijit*/
	public String getPipelineJobsProcessedToday() throws RemoteException, SQLException {
	    String sql = "SELECT COUNT(*) AS cnt FROM pipeline_jobs WHERE status IN ('completed','failed') AND DATE(finished_at) = CURDATE()";
	    return mydb.ExecuteSingle(sql);
	}

	/*Srijit*/
	public Object getRecentPipelineJobs() throws RemoteException, SQLException {
	    String sql = "SELECT p.id, p.pat_id, concat_ws(' ', m.pat_name, m.m_name, m.l_name) AS pat_name, p.session_id, p.force_reannotate, p.status, " +
	                "p.created_at, p.started_at, p.finished_at, p.error_message " +
	                "FROM pipeline_jobs p LEFT JOIN med m ON m.pat_id = p.pat_id " +
	                "ORDER BY p.id DESC LIMIT 100";
	    return mydb.ExecuteQuary(sql);
	}

	/*Srijit*/
	public int clearPipelineQueue() throws RemoteException, SQLException {
	    String sql = "DELETE FROM pipeline_jobs";
	    mydb.ExecuteSql(sql);
	    String countSql = "SELECT ROW_COUNT() AS cnt";
	    String cnt = mydb.ExecuteSingle(countSql);
	    try { return Integer.parseInt(cnt); } catch (Exception e) { return 0; }
	}

	/*Srijit*/
	public Object getPipelineQueueSettings() throws RemoteException, SQLException {
	    String sql = "SELECT TIME_FORMAT(start_time, '%H:%i') AS start_time, TIME_FORMAT(end_time, '%H:%i') AS end_time " +
	                "FROM pipeline_settings WHERE id = 1";
	    return mydb.ExecuteQuary(sql);
	}

	/*Srijit*/
	public boolean savePipelineQueueSettings(String startTime, String endTime) throws RemoteException, SQLException {
	    String updateSql = "UPDATE pipeline_settings SET start_time = '" + startTime + "', end_time = '" + endTime + "' WHERE id = 1";
	    if ("Done".equals(mydb.ExecuteSql(updateSql))) {
	        return true;
	    }
	    String insertSql = "INSERT INTO pipeline_settings (id, start_time, end_time) VALUES (1, '" + startTime + "', '" + endTime + "')";
	    return "Done".equals(mydb.ExecuteSql(insertSql));
	}

	/*Srijit*/
	public boolean saveSessionSummary(String sessionId, String summary) throws RemoteException, SQLException {
	    String countSql = "SELECT COUNT(*) FROM session_history WHERE session_id = '" + sessionId + "'";
	    String count = mydb.ExecuteSingle(countSql);
	    int recordCount = 0;
	    try {
	        if (count != null && !count.trim().isEmpty()) recordCount = Integer.parseInt(count);
	    } catch (Exception e) { recordCount = 0; }

	    String summaryValue = esc(summary != null ? summary.trim() : "");
	    String sql;
	    if (recordCount > 0) {
	        sql = "UPDATE session_history SET session_summary = '" + summaryValue + "' WHERE session_id = '" + sessionId + "'";
	    } else {
	        sql = "INSERT INTO session_history (session_id, pat_id, start_time, session_summary) " +
	              "VALUES ('" + sessionId + "', '', NOW(), '" + summaryValue + "')";
	    }
	    return "Done".equals(mydb.ExecuteSql(sql));
	}

	/*Srijit*/
	public boolean saveChatType(String patId, String chatType) throws RemoteException, SQLException {
	    try {
	        mydb.ExecuteSql("ALTER TABLE chat_control ADD COLUMN chat_type VARCHAR(20) DEFAULT 'original'");
	    } catch (Exception colEx) { /* column already exists */ }

	    String sql = "UPDATE chat_control SET chat_type = '" + esc(chatType) + "' WHERE pat_id = '" + patId + "'";
	    return "Done".equals(mydb.ExecuteSql(sql));
	}

	/*Srijit*/
	private String esc(String s) {
	    return s == null ? "" : s.replace("'", "''");
	}
//    /*Soumya_B*/
//    public boolean saveChatControlSettings(String patId, int dailyLimit, int maxDuration, int minInterval, String startTime, String endTime, String blackoutDays) throws RemoteException, SQLException {
//     System.out.println("\n=== DEBUG: saveChatControlSettings START ===");
//     System.out.println("Input Parameters:");
//     System.out.println("  patId: '" + patId + "'");
//     System.out.println("  dailyLimit: " + dailyLimit);
//     System.out.println("  maxDuration: " + maxDuration);
//     System.out.println("  minInterval: " + minInterval);
//     System.out.println("  startTime: '" + startTime + "'");
//     System.out.println("  endTime: '" + endTime + "'");
//     System.out.println("  blackoutDays: '" + blackoutDays + "'");
    
//     try {
//         // Test database connection first
//         System.out.println("\n=== Testing Database Connection ===");
//         String testSql = "SELECT 1 as test_connection";
//         String testResult = mydb.ExecuteSingle(testSql);
//         System.out.println("Database connection test result: " + testResult);
        
//         // Check if table exists
//         System.out.println("\n=== Checking if chat_control table exists ===");
//         String tableCheckSql = "SHOW TABLES LIKE 'chat_control'";
//         String tableExists = mydb.ExecuteSingle(tableCheckSql);
//         System.out.println("Table exists check result: '" + tableExists + "'");
        
//         if (tableExists == null || tableExists.isEmpty()) {
//             System.out.println("ERROR: chat_control table does not exist!");
//             return false;
//         }
        
//         // Check table structure
//         System.out.println("\n=== Checking table structure ===");
//         String structureSql = "DESCRIBE chat_control";
//         Object structureResult = mydb.ExecuteQuary(structureSql);
//         System.out.println("Table structure: " + structureResult);
        
//         // Check current record count
//         System.out.println("\n=== Checking current record count ===");
//         String countAllSql = "SELECT COUNT(*) as total_records FROM chat_control";
//         String totalRecords = mydb.ExecuteSingle(countAllSql);
//         System.out.println("Total records in chat_control: " + totalRecords);
        
//         // Check if record exists for this patient
//         System.out.println("\n=== Checking if record exists for patient ===");
//         String checkSql = "SELECT COUNT(*) FROM chat_control WHERE pat_id = '" + patId + "'";
//         System.out.println("Check SQL: " + checkSql);
//         String count = mydb.ExecuteSingle(checkSql);
//         System.out.println("Record count for patient '" + patId + "': " + count);
        
//         int recordCount = 0;
//         try {
//             recordCount = Integer.parseInt(count);
//         } catch (Exception e) {
//             System.out.println("ERROR parsing record count: " + e.toString());
//             recordCount = 0;
//         }
        
//         // Show existing data if any
//         if (recordCount > 0) {
//             System.out.println("\n=== Existing record for patient ===");
//             String existingSql = "SELECT * FROM chat_control WHERE pat_id = '" + patId + "'";
//             Object existingData = mydb.ExecuteQuary(existingSql);
//             System.out.println("Existing data: " + existingData);
//         }
        
//         String sql = "";
        
//         // Escape single quotes in text fields to prevent SQL injection
//         if (blackoutDays != null) {
//             blackoutDays = blackoutDays.replace("'", "''");
//         }
        
//         // Handle NULL values for time fields
//         String startTimeValue = (startTime == null || startTime.isEmpty()) ? "NULL" : "'" + startTime + "'";
//         String endTimeValue = (endTime == null || endTime.isEmpty()) ? "NULL" : "'" + endTime + "'";
//         String blackoutDaysValue = (blackoutDays == null || blackoutDays.isEmpty()) ? "NULL" : "'" + blackoutDays + "'";
        
//         System.out.println("\n=== Processed Values ===");
//         System.out.println("  startTimeValue: " + startTimeValue);
//         System.out.println("  endTimeValue: " + endTimeValue);
//         System.out.println("  blackoutDaysValue: " + blackoutDaysValue);
        
//         if (recordCount > 0) {
//             // Update existing record
//             sql = "UPDATE chat_control SET " +
//                   "daily_chat_limit = " + dailyLimit + ", " +
//                   "max_session_duration = " + maxDuration + ", " +
//                   "min_session_interval = " + minInterval + ", " +
//                   "blackout_start_time = " + startTimeValue + ", " +
//                   "blackout_end_time = " + endTimeValue + ", " +
//                   "blackout_days = " + blackoutDaysValue + " " +
//                   "WHERE pat_id = '" + patId + "'";
//             System.out.println("\n=== UPDATE Operation ===");
//         } else {
//             // Insert new record
//             sql = "INSERT INTO chat_control (pat_id, daily_chat_limit, max_session_duration, min_session_interval, blackout_start_time, blackout_end_time, blackout_days) " +
//                   "VALUES ('" + patId + "', " + dailyLimit + ", " + maxDuration + ", " + minInterval + ", " + 
//                   startTimeValue + ", " + endTimeValue + ", " + blackoutDaysValue + ")";
//             System.out.println("\n=== INSERT Operation ===");
//         }
        
//         System.out.println("Final SQL: " + sql);
        
//         // Execute the SQL statement
//         System.out.println("\n=== Executing SQL ===");
//         mydb.ExecuteSql(sql);
//         System.out.println("SQL executed successfully (no exception thrown)");
        
//         // Check if the operation was successful
//         System.out.println("\n=== Verifying Operation Success ===");
//         String newCountSql = "SELECT COUNT(*) FROM chat_control WHERE pat_id = '" + patId + "'";
//         String newCount = mydb.ExecuteSingle(newCountSql);
//         System.out.println("Record count after operation: " + newCount);
        
//         // Show the final data
//         String finalDataSql = "SELECT * FROM chat_control WHERE pat_id = '" + patId + "'";
//         Object finalData = mydb.ExecuteQuary(finalDataSql);
//         System.out.println("Final data: " + finalData);
        
//         System.out.println("\n=== DEBUG: saveChatControlSettings END (SUCCESS) ===");
//         return true;
        
//     } catch (Exception e) {
//         System.out.println("\n=== ERROR in saveChatControlSettings ===");
//         System.out.println("Exception type: " + e.getClass().getName());
//         System.out.println("Error message: " + e.getMessage());
//         System.out.println("Stack trace:");
//         e.printStackTrace();
//         System.out.println("=== DEBUG: saveChatControlSettings END (FAILED) ===");
//         return false;
//     }
// }

 /*Soumya_B*/
public boolean saveChatControlSettings(String patId, int dailyLimit, int maxDuration, int minInterval, String startTime, String endTime, String blackoutDays) throws RemoteException, SQLException {
    System.out.println("\n=== DEBUG: saveChatControlSettings START ===");
    System.out.println("Input Parameters:");
    System.out.println("  patId: '" + patId + "'");
    System.out.println("  dailyLimit: " + dailyLimit);
    System.out.println("  maxDuration: " + maxDuration);
    System.out.println("  minInterval: " + minInterval);
    System.out.println("  startTime: '" + startTime + "'");
    System.out.println("  endTime: '" + endTime + "'");
    System.out.println("  blackoutDays: '" + blackoutDays + "'");
    
    try {
        // Check if record exists for this patient
        String checkSql = "SELECT COUNT(*) FROM chat_control WHERE pat_id = '" + patId + "'";
        System.out.println("\n=== Check SQL: " + checkSql);
        String count = mydb.ExecuteSingle(checkSql);
        System.out.println("Record count BEFORE operation: " + count);
        
        int recordCount = 0;
        try {
            if (count != null && !count.trim().isEmpty()) {
                recordCount = Integer.parseInt(count);
            }
        } catch (Exception e) {
            System.out.println("ERROR parsing record count: " + e.toString());
            recordCount = 0;
        }
        
        // Show existing data if any
        if (recordCount > 0) {
            System.out.println("\n=== Existing record found, will UPDATE ===");
            String showSql = "SELECT * FROM chat_control WHERE pat_id = '" + patId + "'";
            Object existingData = mydb.ExecuteQuary(showSql);
            System.out.println("Existing data: " + existingData);
        } else {
            System.out.println("\n=== No existing record found, will INSERT ===");
        }
        
        String sql = "";
        
        // Handle NULL values properly
        // String startTimeValue = (startTime == null || startTime.trim().isEmpty() || startTime.equals("null")) 
        //                         ? "NULL" 
        //                         : "'" + startTime.replace("'", "''") + "'";
        String startTimeValue = (startTime == null || startTime.isEmpty() || startTime.equalsIgnoreCase("null")) ? "NULL" : "'" + startTime + "'";
        String endTimeValue = (endTime == null || endTime.trim().isEmpty() || endTime.equals("null")) 
                              ? "NULL" 
                              : "'" + endTime.replace("'", "''") + "'";
        String blackoutDaysValue = (blackoutDays == null || blackoutDays.trim().isEmpty() || blackoutDays.equals("null")) 
                                   ? "NULL" 
                                   : "'" + blackoutDays.replace("'", "''") + "'";
        
        System.out.println("\n=== Processed Values ===");
        System.out.println("  startTimeValue: " + startTimeValue);
        System.out.println("  endTimeValue: " + endTimeValue);
        System.out.println("  blackoutDaysValue: " + blackoutDaysValue);
        
        if (recordCount > 0) {
            // Update existing record
            sql = "UPDATE chat_control SET " +
                  "daily_chat_limit = " + dailyLimit + ", " +
                  "max_session_duration = " + maxDuration + ", " +
                  "min_session_interval = " + minInterval + ", " +
                  "blackout_start_time = " + startTimeValue + ", " +
                  "blackout_end_time = " + endTimeValue + ", " +
                  "blackout_days = " + blackoutDaysValue + " " +
                  "WHERE pat_id = '" + patId + "'";
            System.out.println("\n=== UPDATE Operation ===");
        } else {
            // Insert new record
            sql = "INSERT INTO chat_control (pat_id, daily_chat_limit, max_session_duration, min_session_interval, blackout_start_time, blackout_end_time, blackout_days) " +
                  "VALUES ('" + patId + "', " + dailyLimit + ", " + maxDuration + ", " + minInterval + ", " + 
                  startTimeValue + ", " + endTimeValue + ", " + blackoutDaysValue + ")";
            System.out.println("\n=== INSERT Operation ===");
        }
        
        System.out.println("Final SQL: " + sql);
        
        // Execute the SQL statement
        System.out.println("\n=== Executing SQL ===");
        System.out.println("=== EXACT SQL TO EXECUTE: [" + sql + "]");
        mydb.ExecuteSql(sql);
        System.out.println("ExecuteSql completed (no exception thrown)");
        
        // IMMEDIATE verification - check if the data is there RIGHT AFTER insert
        System.out.println("\n=== IMMEDIATE Verification (right after ExecuteSql) ===");
        String immediateCountSql = "SELECT COUNT(*) FROM chat_control WHERE pat_id = '" + patId + "'";
        String immediateCount = mydb.ExecuteSingle(immediateCountSql);
        System.out.println("Record count IMMEDIATELY after SQL: " + immediateCount);
        
        if (immediateCount != null && !immediateCount.equals("0")) {
            System.out.println("Record exists immediately after SQL!");
            
            // Get the actual data
            String immediateDataSql = "SELECT * FROM chat_control WHERE pat_id = '" + patId + "'";
            Object immediateData = mydb.ExecuteQuary(immediateDataSql);
            System.out.println("Immediate data: " + immediateData);
            
            if (immediateData instanceof Vector) {
                Vector v = (Vector) immediateData;
                if (v.size() > 0) {
                    dataobj d = (dataobj) v.get(0);
                    
                    String savedDailyLimit = d.getValue("daily_chat_limit");
                    String savedMaxDuration = d.getValue("max_session_duration");
                    String savedMinInterval = d.getValue("min_session_interval");
                    
                    System.out.println("Values in database:");
                    System.out.println("  daily_chat_limit: " + savedDailyLimit + " (expected: " + dailyLimit + ")");
                    System.out.println("  max_session_duration: " + savedMaxDuration + " (expected: " + maxDuration + ")");
                    System.out.println("  min_session_interval: " + savedMinInterval + " (expected: " + minInterval + ")");
                    
                    // Verify values match
                    try {
                        int dbDailyLimit = Integer.parseInt(savedDailyLimit);
                        int dbMaxDuration = Integer.parseInt(savedMaxDuration);
                        int dbMinInterval = Integer.parseInt(savedMinInterval);
                        
                        if (dbDailyLimit == dailyLimit && dbMaxDuration == maxDuration && dbMinInterval == minInterval) {
                            System.out.println("SUCCESS: All values match!");
                            System.out.println("\n=== DEBUG: saveChatControlSettings END (SUCCESS) ===");
                            return true;
                        } else {
                            System.out.println("ERROR: Values don't match!");
                            System.out.println("\n=== DEBUG: saveChatControlSettings END (VALUES MISMATCH) ===");
                            return false;
                        }
                    } catch (NumberFormatException nfe) {
                        System.out.println("ERROR parsing values: " + nfe.getMessage());
                    }
                }
            }
        } else {
            System.out.println("ERROR: Record NOT found immediately after SQL execution!");
            System.out.println("This suggests the SQL didn't execute or was rolled back.");
            System.out.println("\n=== DEBUG: saveChatControlSettings END (NO RECORD AFTER INSERT) ===");
            return false;
        }
        
        System.out.println("\n=== DEBUG: saveChatControlSettings END (UNKNOWN STATE) ===");
        return false;
        
    } catch (Exception e) {
        System.out.println("\n=== ERROR in saveChatControlSettings ===");
        System.out.println("Exception type: " + e.getClass().getName());
        System.out.println("Error message: " + e.getMessage());
        System.out.println("Stack trace:");
        e.printStackTrace();
        System.out.println("=== DEBUG: saveChatControlSettings END (FAILED) ===");
        return false;
    }
}

/*Soumya_B - Chat History Implementation Methods*/
	public Object getChatSessions(String patId) throws RemoteException, SQLException {
	    try {
	        System.out.println("DEBUG - getChatSessions for patId: " + patId);
	        
	        String sql = "SELECT session_id, session_date, start_time, end_time, duration, session_notes, session_status " +
	                     "FROM chat_sessions WHERE pat_id = '" + patId + "' " +
	                     "ORDER BY session_date DESC, start_time DESC";
	        
	        System.out.println("DEBUG - SQL: " + sql);
	        return mydb.ExecuteQuary(sql);
	        
	    } catch (Exception e) {
	        System.out.println("ERROR - getChatSessions: " + e.getMessage());
	        e.printStackTrace();
	        return "Error retrieving chat sessions: " + e.getMessage();
	    }
	}

	public Object getChatMessages(String sessionId) throws RemoteException, SQLException {
	    try {
	        System.out.println("DEBUG - getChatMessages for sessionId: " + sessionId);
	        
	        String sql = "SELECT message_id, message_sequence, sender_type, message_content, timestamp, is_read, response_time " +
	                     "FROM chat_messages WHERE session_id = ? ORDER BY message_sequence ASC";
	        return mydb.ExecutePQuary(sql, new String[]{sessionId}, 1);
	    } catch (Exception e) {
	        System.out.println("ERROR - getChatMessages: " + e.getMessage());
	        e.printStackTrace();
	        return "Error retrieving chat messages: " + e.getMessage();
	    }
	}

	public Object getChatMessagesForPatient(String patId) throws RemoteException, SQLException {
	    try {
	        String sql = "SELECT cm.session_id, cm.message_id, cm.message_sequence, cm.sender_type, " +
	                     "cm.message_content, cm.timestamp, cm.is_read, cm.response_time " +
	                     "FROM chat_messages cm " +
	                     "JOIN chat_sessions cs ON cm.session_id = cs.session_id " +
	                     "WHERE cs.pat_id = ? " +
	                     "ORDER BY cs.session_date ASC, cs.start_time ASC, cm.message_sequence ASC";
	        return mydb.ExecutePQuary(sql, new String[]{patId}, 1);
	    } catch (Exception e) {
	        System.out.println("ERROR - getChatMessagesForPatient: " + e.getMessage());
	        e.printStackTrace();
	        return "Error retrieving chat messages for patient: " + e.getMessage();
	    }
	}

	public Object getChatSessionsDateRange(String patId, String fromDate, String toDate) throws RemoteException, SQLException {
	    try {
	        System.out.println("DEBUG - getChatSessionsDateRange for patId: " + patId + ", from: " + fromDate + ", to: " + toDate);
	        
	        String sql = "SELECT session_id, session_date, start_time, end_time, duration, session_notes, session_status " +
	                     "FROM chat_sessions WHERE pat_id = ? " +
	                     "AND session_date BETWEEN ? AND ? " +
	                     "ORDER BY session_date DESC, start_time DESC";
	        return mydb.ExecutePQuary(sql, new String[]{patId, fromDate, toDate}, 3);
	    } catch (Exception e) {
	        System.out.println("ERROR - getChatSessionsDateRange: " + e.getMessage());
	        e.printStackTrace();
	        return "Error retrieving chat sessions with date range: " + e.getMessage();
	    }
	}

	public Object getChatSessionsSummary(String patId) throws RemoteException, SQLException {
	    try {
	        System.out.println("DEBUG - getChatSessionsSummary for patId: " + patId);
	        
	        String sql = "SELECT " +
	                     "COUNT(*) as total_sessions, " +
	                     "SUM(duration) as total_duration, " +
	                     "AVG(duration) as avg_duration, " +
	                     "MAX(session_date) as last_session_date, " +
	                     "MIN(session_date) as first_session_date, " +
	                     "COUNT(CASE WHEN session_status = 'completed' THEN 1 END) as completed_sessions, " +
	                     "COUNT(CASE WHEN session_status = 'active' THEN 1 END) as active_sessions, " +
	                     "COUNT(CASE WHEN session_status = 'terminated' THEN 1 END) as terminated_sessions " +
	                     "FROM chat_sessions WHERE pat_id = '" + patId + "'";
	        
	        System.out.println("DEBUG - SQL: " + sql);
	        return mydb.ExecuteQuary(sql);
	        
	    } catch (Exception e) {
	        System.out.println("ERROR - getChatSessionsSummary: " + e.getMessage());
	        e.printStackTrace();
	        return "Error retrieving chat sessions summary: " + e.getMessage();
	    }
	}

	public Object getChatMessageCount(String sessionId) throws RemoteException, SQLException {
	    try {
	        System.out.println("DEBUG - getChatMessageCount for sessionId: " + sessionId);
	        
	        String sql = "SELECT COUNT(*) as message_count, " +
	                     "SUM(CASE WHEN sender_type = 'patient' THEN 1 ELSE 0 END) as patient_messages, " +
	                     "SUM(CASE WHEN sender_type = 'bot' THEN 1 ELSE 0 END) as bot_messages, " +
	                     "SUM(CASE WHEN sender_type = 'system' THEN 1 ELSE 0 END) as system_messages, " +
	                     "AVG(LENGTH(message_content)) as avg_message_length " +
	                     "FROM chat_messages WHERE session_id = '" + sessionId + "'";
	        
	        System.out.println("DEBUG - SQL: " + sql);
	        return mydb.ExecuteQuary(sql);
	        
	    } catch (Exception e) {
	        System.out.println("ERROR - getChatMessageCount: " + e.getMessage());
	        e.printStackTrace();
	        return "Error retrieving chat message count: " + e.getMessage();
	    }
	}

	public Object getChatSessionsWithPagination(String patId, int offset, int limit) throws RemoteException, SQLException {
	    try {
	        System.out.println("DEBUG - getChatSessionsWithPagination for patId: " + patId + ", offset: " + offset + ", limit: " + limit);
	        
	        String sql = "SELECT session_id, session_date, start_time, end_time, duration, session_notes, session_status " +
	                     "FROM chat_sessions WHERE pat_id = '" + patId + "' " +
	                     "ORDER BY session_date DESC, start_time DESC " +
	                     "LIMIT " + limit + " OFFSET " + offset;
	        
	        System.out.println("DEBUG - SQL: " + sql);
	        return mydb.ExecuteQuary(sql);
	        
	    } catch (Exception e) {
	        System.out.println("ERROR - getChatSessionsWithPagination: " + e.getMessage());
	        e.printStackTrace();
	        return "Error retrieving chat sessions with pagination: " + e.getMessage();
	    }
	}

	public Object getChatSessionsWithFilter(String patId, String fromDate, String toDate, String statusFilter, int offset, int limit) throws RemoteException, SQLException {
	    try {
	        System.out.println("DEBUG - getChatSessionsWithFilter for patId: " + patId);
	        System.out.println("DEBUG - Filters - fromDate: " + fromDate + ", toDate: " + toDate + ", status: " + statusFilter);
	        System.out.println("DEBUG - Pagination - offset: " + offset + ", limit: " + limit);
	        
	        StringBuilder sql = new StringBuilder();
	        sql.append("SELECT session_id, session_date, start_time, end_time, duration, session_notes, session_status ");
	        sql.append("FROM chat_sessions WHERE pat_id = '").append(patId).append("' ");
	        
	        // Add date range filter
	        if (fromDate != null && !fromDate.trim().isEmpty() && toDate != null && !toDate.trim().isEmpty()) {
	            sql.append("AND session_date BETWEEN '").append(fromDate).append("' AND '").append(toDate).append("' ");
	        }
	        
	        // Add status filter
	        if (statusFilter != null && !statusFilter.trim().isEmpty()) {
	            sql.append("AND session_status = '").append(statusFilter).append("' ");
	        }
	        
	        sql.append("ORDER BY session_date DESC, start_time DESC ");
	        sql.append("LIMIT ").append(limit).append(" OFFSET ").append(offset);
	        
	        String finalSql = sql.toString();
	        System.out.println("DEBUG - SQL: " + finalSql);
	        return mydb.ExecuteQuary(finalSql);
	        
	    } catch (Exception e) {
	        System.out.println("ERROR - getChatSessionsWithFilter: " + e.getMessage());
	        e.printStackTrace();
	        return "Error retrieving filtered chat sessions: " + e.getMessage();
	    }
	}

	public Object getChatEngagementMetrics(String patId, String fromDate, String toDate) throws RemoteException, SQLException {
	    try {
	        System.out.println("DEBUG - getChatEngagementMetrics for patId: " + patId);
	        
	        StringBuilder sql = new StringBuilder();
	        sql.append("SELECT ");
	        sql.append("DATE(session_date) as session_day, ");
	        sql.append("COUNT(*) as sessions_count, ");
	        sql.append("AVG(duration) as avg_duration, ");
	        sql.append("SUM(duration) as total_duration, ");
	        sql.append("COUNT(CASE WHEN session_status = 'completed' THEN 1 END) as completed_sessions ");
	        sql.append("FROM chat_sessions WHERE pat_id = '").append(patId).append("' ");
	        
	        if (fromDate != null && !fromDate.trim().isEmpty() && toDate != null && !toDate.trim().isEmpty()) {
	            sql.append("AND session_date BETWEEN '").append(fromDate).append("' AND '").append(toDate).append("' ");
	        }
	        
	        sql.append("GROUP BY DATE(session_date) ORDER BY session_day DESC LIMIT 30");
	        
	        String finalSql = sql.toString();
	        System.out.println("DEBUG - SQL: " + finalSql);
	        return mydb.ExecuteQuary(finalSql);
	        
	    } catch (Exception e) {
	        System.out.println("ERROR - getChatEngagementMetrics: " + e.getMessage());
	        e.printStackTrace();
	        return "Error retrieving engagement metrics: " + e.getMessage();
	    }
	}

	public Object getChatMessageAnalytics(String patId, String fromDate, String toDate) throws RemoteException, SQLException {
	    try {
	        System.out.println("DEBUG - getChatMessageAnalytics for patId: " + patId);
	        
	        StringBuilder sql = new StringBuilder();
	        sql.append("SELECT ");
	        sql.append("cs.session_date, ");
	        sql.append("cs.session_id, ");
	        sql.append("COUNT(cm.message_id) as total_messages, ");
	        sql.append("SUM(CASE WHEN cm.sender_type = 'patient' THEN 1 ELSE 0 END) as patient_messages, ");
	        sql.append("SUM(CASE WHEN cm.sender_type = 'bot' THEN 1 ELSE 0 END) as bot_messages, ");
	        sql.append("AVG(LENGTH(cm.message_content)) as avg_message_length ");
	        sql.append("FROM chat_sessions cs ");
	        sql.append("LEFT JOIN chat_messages cm ON cs.session_id = cm.session_id ");
	        sql.append("WHERE cs.pat_id = '").append(patId).append("' ");
	        
	        if (fromDate != null && !fromDate.trim().isEmpty() && toDate != null && !toDate.trim().isEmpty()) {
	            sql.append("AND cs.session_date BETWEEN '").append(fromDate).append("' AND '").append(toDate).append("' ");
	        }
	        
	        sql.append("GROUP BY cs.session_id, cs.session_date ORDER BY cs.session_date DESC");
	        
	        String finalSql = sql.toString();
	        System.out.println("DEBUG - SQL: " + finalSql);
	        return mydb.ExecuteQuary(finalSql);
	        
	    } catch (Exception e) {
	        System.out.println("ERROR - getChatMessageAnalytics: " + e.getMessage());
	        e.printStackTrace();
	        return "Error retrieving message analytics: " + e.getMessage();
	    }
	}

	public Object getChatResponseTimeAnalytics(String patId, String fromDate, String toDate) throws RemoteException, SQLException {
	    try {
	        System.out.println("DEBUG - getChatResponseTimeAnalytics for patId: " + patId);
	        
	        StringBuilder sql = new StringBuilder();
	        sql.append("SELECT ");
	        sql.append("AVG(response_time) as avg_response_time, ");
	        sql.append("MIN(response_time) as min_response_time, ");
	        sql.append("MAX(response_time) as max_response_time, ");
	        sql.append("COUNT(CASE WHEN response_time IS NOT NULL THEN 1 END) as responses_with_time ");
	        sql.append("FROM chat_messages cm ");
	        sql.append("JOIN chat_sessions cs ON cm.session_id = cs.session_id ");
	        sql.append("WHERE cs.pat_id = '").append(patId).append("' AND cm.response_time IS NOT NULL ");
	        
	        if (fromDate != null && !fromDate.trim().isEmpty() && toDate != null && !toDate.trim().isEmpty()) {
	            sql.append("AND cs.session_date BETWEEN '").append(fromDate).append("' AND '").append(toDate).append("' ");
	        }
	        
	        String finalSql = sql.toString();
	        System.out.println("DEBUG - SQL: " + finalSql);
	        return mydb.ExecuteQuary(finalSql);
	        
	    } catch (Exception e) {
	        System.out.println("ERROR - getChatResponseTimeAnalytics: " + e.getMessage());
	        e.printStackTrace();
	        return "Error retrieving response time analytics: " + e.getMessage();
	    }
	}

	public Object getChatUsagePatterns(String patId, String fromDate, String toDate) throws RemoteException, SQLException {
	    try {
	        System.out.println("DEBUG - getChatUsagePatterns for patId: " + patId);
	        
	        StringBuilder sql = new StringBuilder();
	        sql.append("SELECT ");
	        sql.append("HOUR(start_time) as hour_of_day, ");
	        sql.append("DAYNAME(session_date) as day_of_week, ");
	        sql.append("COUNT(*) as session_count ");
	        sql.append("FROM chat_sessions ");
	        sql.append("WHERE pat_id = '").append(patId).append("' ");
	        
	        if (fromDate != null && !fromDate.trim().isEmpty() && toDate != null && !toDate.trim().isEmpty()) {
	            sql.append("AND session_date BETWEEN '").append(fromDate).append("' AND '").append(toDate).append("' ");
	        }
	        
	        sql.append("GROUP BY HOUR(start_time), DAYNAME(session_date) ");
	        sql.append("ORDER BY FIELD(day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'), hour_of_day");
	        
	        String finalSql = sql.toString();
	        System.out.println("DEBUG - SQL: " + finalSql);
	        return mydb.ExecuteQuary(finalSql);
	        
	    } catch (Exception e) {
	        System.out.println("ERROR - getChatUsagePatterns: " + e.getMessage());
	        e.printStackTrace();
	        return "Error retrieving usage patterns: " + e.getMessage();
	    }
	}

	public Object getChatSessionDetails(String sessionId) throws RemoteException, SQLException {
	    try {
	        System.out.println("DEBUG - getChatSessionDetails for sessionId: " + sessionId);
	        
	        String sql = "SELECT cs.session_id, cs.pat_id, cs.session_date, cs.start_time, cs.end_time, " +
	                     "cs.duration, cs.session_notes, cs.session_status, " +
	                     "COUNT(cm.message_id) as message_count, " +
	                     "SUM(CASE WHEN cm.sender_type = 'patient' THEN 1 ELSE 0 END) as patient_messages, " +
	                     "SUM(CASE WHEN cm.sender_type = 'bot' THEN 1 ELSE 0 END) as bot_messages " +
	                     "FROM chat_sessions cs " +
	                     "LEFT JOIN chat_messages cm ON cs.session_id = cm.session_id " +
	                     "WHERE cs.session_id = '" + sessionId + "' " +
	                     "GROUP BY cs.session_id";
	        
	        System.out.println("DEBUG - SQL: " + sql);
	        return mydb.ExecuteQuary(sql);
	        
	    } catch (Exception e) {
	        System.out.println("ERROR - getChatSessionDetails: " + e.getMessage());
	        e.printStackTrace();
	        return "Error retrieving session details: " + e.getMessage();
	    }
	}

	public boolean markChatMessagesAsRead(String sessionId) throws RemoteException, SQLException {
	    try {
	        System.out.println("DEBUG - markChatMessagesAsRead for sessionId: " + sessionId);
	        
	        String sql = "UPDATE chat_messages SET is_read = 1 WHERE session_id = '" + sessionId + "'";
	        
	        System.out.println("DEBUG - SQL: " + sql);
	        mydb.ExecuteSql(sql);
	        
	        System.out.println("DEBUG - Successfully marked messages as read for session: " + sessionId);
	        return true;
	        
	    } catch (Exception e) {
	        System.out.println("ERROR - markChatMessagesAsRead: " + e.getMessage());
	        e.printStackTrace();
	        return false;
	    }
	}

	// Additional helper method for getting total count (useful for pagination)
	public Object getChatSessionsCount(String patId, String fromDate, String toDate, String statusFilter) throws RemoteException, SQLException {
	    try {
	        System.out.println("DEBUG - getChatSessionsCount for patId: " + patId);
	        
	        StringBuilder sql = new StringBuilder();
	        sql.append("SELECT COUNT(*) as total_count FROM chat_sessions WHERE pat_id = '").append(patId).append("' ");
	        
	        // Add date range filter
	        if (fromDate != null && !fromDate.trim().isEmpty() && toDate != null && !toDate.trim().isEmpty()) {
	            sql.append("AND session_date BETWEEN '").append(fromDate).append("' AND '").append(toDate).append("' ");
	        }
	        
	        // Add status filter
	        if (statusFilter != null && !statusFilter.trim().isEmpty()) {
	            sql.append("AND session_status = '").append(statusFilter).append("' ");
	        }
	        
	        String finalSql = sql.toString();
	        System.out.println("DEBUG - SQL: " + finalSql);
	        return mydb.ExecuteQuary(finalSql);
	        
	    } catch (Exception e) {
	        System.out.println("ERROR - getChatSessionsCount: " + e.getMessage());
	        e.printStackTrace();
	        return "Error retrieving chat sessions count: " + e.getMessage();
	    }
	}

	// Utility method for chat session statistics
	public Object getChatSessionsStats(String patId) throws RemoteException, SQLException {
	    try {
	        System.out.println("DEBUG - getChatSessionsStats for patId: " + patId);
	        
	        String sql = "SELECT " +
	                     "COUNT(*) as total_sessions, " +
	                     "COUNT(CASE WHEN session_status = 'completed' THEN 1 END) as completed_sessions, " +
	                     "COUNT(CASE WHEN session_status = 'active' THEN 1 END) as active_sessions, " +
	                     "COUNT(CASE WHEN session_status = 'terminated' THEN 1 END) as terminated_sessions, " +
	                     "AVG(duration) as avg_session_duration, " +
	                     "MAX(duration) as max_session_duration, " +
	                     "MIN(duration) as min_session_duration, " +
	                     "SUM(duration) as total_duration " +
	                     "FROM chat_sessions WHERE pat_id = '" + patId + "'";
	        
	        System.out.println("DEBUG - SQL: " + sql);
	        return mydb.ExecuteQuary(sql);
	        
	    } catch (Exception e) {
	        System.out.println("ERROR - getChatSessionsStats: " + e.getMessage());
	        e.printStackTrace();
	        return "Error retrieving chat sessions statistics: " + e.getMessage();
	    }
	}

	/*Soumya_B - Assign Tests Implementation*/
	public Object getAllSurveys() throws RemoteException, SQLException {
	    try {
	        System.out.println("DEBUG - getAllSurveys called");
	        
	        String sql = "SELECT sid, name, description FROM survey_project WHERE sid NOT IN ('s2','s7','s3','s1','s9','s6','s23','s24','s8')  AND name NOT IN ('Secret Santa', 'User1', 'Nutrition', 'Food Supplement', 'Lavarthi - Food supplement', 'Food Supplement RKM', 'Food Supplement Master', 'Food Supplement (Lavarthi Sheet)') ORDER BY name";
	        
	        System.out.println("DEBUG - SQL: " + sql);
	        return mydb.ExecuteQuary(sql);
	        
	    } catch (Exception e) {
	        System.out.println("ERROR - getAllSurveys: " + e.getMessage());
	        e.printStackTrace();
	        return "Error retrieving surveys: " + e.getMessage();
	    }
	}

	public boolean assignTestToPatient(String patId, String surveyId) throws RemoteException, SQLException {
	    try {
	        // First, get the survey name from the survey_project table using sid
	        String getSurveyNameSql = "SELECT name FROM survey_project WHERE sid = '" + surveyId + "'";
	        System.out.println("Getting survey name: " + getSurveyNameSql);
	        
	        Object result = mydb.ExecuteQuary(getSurveyNameSql);
	        String surveyName = "";
	        
	        if (result instanceof Vector) {
	            Vector v = (Vector) result;
	            if (v.size() > 0) {
	                dataobj d = (dataobj) v.get(0);
	                surveyName = d.getValue("name");
	            }
	        }
	        
	        if (surveyName.isEmpty()) {
	            System.out.println("Error: Survey not found for sid: " + surveyId);
	            return false;
	        }
	        
	        // Check if this test is already prescribed to this patient
	        String checkSql = "SELECT COUNT(*) as count FROM PrescribedTests " +
	                         "WHERE pat_id = '" + patId + "' AND prescribed_tests = '" + surveyName + "'";
	        System.out.println("Checking for existing assignment: " + checkSql);
	        
	        Object checkResult = mydb.ExecuteQuary(checkSql);
	        boolean alreadyExists = false;
	        
	        if (checkResult instanceof Vector) {
	            Vector v = (Vector) checkResult;
	            if (v.size() > 0) {
	                dataobj d = (dataobj) v.get(0);
	                int count = Integer.parseInt(d.getValue("count"));
	                alreadyExists = (count > 0);
	            }
	        }
	        
	        if (alreadyExists) {
	            System.out.println("Test already assigned to patient: " + surveyName);
	            return true; // Return true as the assignment already exists
	        }
	        
	        // Insert the prescription record using survey NAME (not SID)
	        // Note: PrescribedTests table only has slno (auto-increment), pat_id, prescribed_tests
	        String insertSql = "INSERT INTO PrescribedTests (pat_id, prescribed_tests) " +
	                          "VALUES ('" + patId + "', '" + surveyName + "')";
	        System.out.println("assignTestToPatient(): " + insertSql);
	        
	        mydb.ExecuteSql(insertSql);
	        System.out.println("Successfully assigned test '" + surveyName + "' to patient: " + patId);
	        
	        return true;
	        
	    } catch (Exception e) {
	        System.out.println("Error in assignTestToPatient: " + e.toString());
	        e.printStackTrace();
	        return false;
	    }
	}
}








