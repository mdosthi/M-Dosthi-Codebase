/**
 * @author Saikat Ray
 **/
 
package imedix;

import java.sql.*;
import java.io.*;
import java.util.Vector;

public class projinfo {
	
	 public String gblcentercode="";
	 public String gbldbjdbccriver="";
	 public String gbldburl="";
	 public String gbldbusername="";
	 public String gbldbpasswd="";
	 public String blport=""; 
	 public String tempdatadir = "";
	 public String ftphost = "";
	 public String ftpuser = "";
	 public String ftppasswd = "";
	 public String ftpdocsendpath;
	 public String ps_home="";
	 public String CenterTypeMSPS="";
	 public String SystemLogger="";
	 public String SystemLoggerPath="";
	 public String GeneralSqlLog="";
	 public String GeneralSqlLogPath="";

	public projinfo(){
		setvalue();
	}	
	
	private void setvalue()
    {   	
		String gblarray[] = new String [25];	
		int gblindex=0;
		int gblcount=0;
		String gblstr="";
		try {
	    	FileInputStream gblfin = new FileInputStream("gblinfo.inf");
			do{
				gblindex = gblfin.read();
				if((char) gblindex != '\n') gblstr = gblstr + (char) gblindex;
				else {
					gblarray[gblcount++]=gblstr;
					gblstr="";
					}
			}while(gblindex != -1);
	   	    	
	    for (gblindex=0; gblindex<gblcount; gblindex++) {
			gblstr =gblarray[gblindex].substring(gblarray[gblindex].indexOf('=')+1);
			gblarray[gblindex] = gblstr.trim();						
//			System.out.println(gblarray[gblindex]);
		}
		
		int c=0;
		
	 
		/* Don't Change the Order of these variables */
		
	 	
	 	
	 	
	 	gblcentercode=gblarray[c++];
		gbldbjdbccriver=gblarray[c++];
	 	gbldburl=gblarray[c++];
	 	gbldbusername=gblarray[c++];
	 	gbldbpasswd=gblarray[c++];
	 	blport=gblarray[c++];
	 	tempdatadir =gblarray[c++];
	 	ftphost = gblarray[c++];
	 	ftpuser = gblarray[c++];
	 	ftppasswd = gblarray[c++];
	 	ftpdocsendpath=gblarray[c++];
	 	ps_home=gblarray[c++];
	 	CenterTypeMSPS=gblarray[c++];
		SystemLogger=gblarray[c++];
	 	SystemLoggerPath=gblarray[c++];
	 	GeneralSqlLog=gblarray[c++];
		GeneralSqlLogPath=gblarray[c++];

		gblcentercode = environmentValue("IMEDIX_CENTER_CODE", gblcentercode);
		gbldburl = environmentValue("LEGACY_DB_URL", gbldburl);
		gbldbusername = environmentValue("LEGACY_DB_USERNAME", gbldbusername);
		gbldbpasswd = environmentValue("LEGACY_DB_PASSWORD", gbldbpasswd);
		tempdatadir = environmentValue("LEGACY_TEMP_DIR", tempdatadir);
		ftpuser = environmentValue("LEGACY_FTP_USERNAME", ftpuser);
		ftppasswd = environmentValue("LEGACY_FTP_PASSWORD", ftppasswd);
		SystemLoggerPath = environmentValue("LEGACY_SYSTEM_LOG_DIR", SystemLoggerPath);
		GeneralSqlLogPath = environmentValue("LEGACY_SQL_LOG_DIR", GeneralSqlLogPath);


	 
		}
	    catch ( Exception e) {
	    		System.out.println(e.toString());
	    		
	    }
	}

	private String environmentValue(String name, String fallback)
	{
		String value = System.getenv(name);
		return value == null || value.trim().isEmpty() ? fallback : value.trim();
	}
	
}
	