<%-- <%@page language="java"  import="imedix.cook,imedix.rcUserInfo,java.util.*,java.io.*"%>

<%
    cook cookx = new cook();
    String cmd = request.getParameter("cmd");
    String result = "{";
    
    try {
        rcUserInfo rcui = new rcUserInfo(request.getRealPath("/"));
        
        if(cmd != null) {
            if(cmd.equalsIgnoreCase("disable_rct")) {
                String uid = request.getParameter("uid");
                boolean res = rcui.disableRctFlag(uid);
                
                if(res) {
                    result += "\"status\": \"success\", ";
                    result += "\"message\": \"RCT flag disabled for user with uid = " + uid + "\"";
                } else {
                    result += "\"status\": \"error\", ";
                    result += "\"message\": \"Failed to disable RCT flag for user with uid = " + uid + "\"";
                }
                result += "}";
                out.println(result);
            }
            else if(cmd.equalsIgnoreCase("enable_rct")) {
                String uid = request.getParameter("uid");
                boolean res = rcui.enableRctFlag(uid);
                
                if(res) {
                    result += "\"status\": \"success\", ";
                    result += "\"message\": \"RCT flag enabled for user with uid = " + uid + "\"";
                } else {
                    result += "\"status\": \"error\", ";
                    result += "\"message\": \"Failed to enable RCT flag for user with uid = " + uid + "\"";
                }
                result += "}";
                out.println(result);
            }
            else if(cmd.equalsIgnoreCase("get_rct")) {
                String uid = request.getParameter("uid");
                int flag = rcui.getRctFlag(uid);
                
                result += "\"status\": \"success\", ";
                result += "\"rctFlag\": " + flag;
                result += "}";
                out.println(result);
            }
        }
    } catch(Exception e) {
        result += "\"status\": \"error\", ";
        result += "\"message\": \"Exception: " + e.getMessage() + "\"";
        result += "}";
        out.println(result);
        e.printStackTrace();
    }
%> --%>

<%@page language="java"  import="imedix.cook,imedix.rcUserInfo,imedix.dataobj,java.util.*,java.io.*"%>

<%
    cook cookx = new cook();
    String cmd = request.getParameter("cmd");
    String result = "{";
    
    try {
        rcUserInfo rcui = new rcUserInfo(request.getRealPath("/"));
        
        if(cmd != null) {
            
            // MODIFIED: Disable individual RCT - NOT ALLOWED once enrolled
            if(cmd.equalsIgnoreCase("disable_rct")) {
                String uid = request.getParameter("uid");
                
                // Check if user is already in RCT
                int currentFlag = rcui.getRctFlag(uid);
                if(currentFlag == 1) {
                    result += "\"status\": \"error\", ";
                    result += "\"message\": \"Cannot remove patient from RCT once enrolled. RCT enrollment is permanent to maintain trial integrity.\"";
                } else {
                    result += "\"status\": \"error\", ";
                    result += "\"message\": \"User is not enrolled in RCT.\"";
                }
                result += "}";
                out.println(result);
            }
            
            // Enable RCT - Still allowed (one-time only)
            else if(cmd.equalsIgnoreCase("enable_rct")) {
                String uid = request.getParameter("uid");
                
                // Check if user is already in RCT
                int currentFlag = rcui.getRctFlag(uid);
                if(currentFlag == 1) {
                    result += "\"status\": \"info\", ";
                    result += "\"message\": \"User is already enrolled in RCT.\"";
                } else {
                    boolean res = rcui.enableRctFlag(uid);
                    
                    if(res) {
                        result += "\"status\": \"success\", ";
                        result += "\"message\": \"Patient successfully enrolled in RCT. This enrollment is permanent and cannot be undone.\"";
                    } else {
                        result += "\"status\": \"error\", ";
                        result += "\"message\": \"Failed to enroll patient in RCT.\"";
                    }
                }
                result += "}";
                out.println(result);
            }
            
            // Get RCT status
            else if(cmd.equalsIgnoreCase("get_rct")) {
                String uid = request.getParameter("uid");
                int flag = rcui.getRctFlag(uid);
                
                result += "\"status\": \"success\", ";
                result += "\"rctFlag\": " + flag;
                result += "}";
                out.println(result);
            }
            
            // AUTOMATED RANDOMIZATION - Modified for permanent enrollment
            else if(cmd.equalsIgnoreCase("auto_randomize_simple")) {
                String centerCode = request.getParameter("center");
                String userType = request.getParameter("userType");
                String percentageStr = request.getParameter("percentage");
                String maxCountStr = request.getParameter("maxCount");
                String resetExisting = request.getParameter("resetExisting");
                
                // Validate parameters
                if(centerCode == null || percentageStr == null) {
                    result += "\"status\": \"error\", ";
                    result += "\"message\": \"Missing required parameters: center and percentage\"";
                    result += "}";
                    out.println(result);
                    return;
                }
                
                double percentage = Double.parseDouble(percentageStr);
                int maxCount = (maxCountStr != null) ? Integer.parseInt(maxCountStr) : 999;
                if(userType == null) userType = "PAT";
                
                // IMPORTANT: Reset existing is NOT allowed for RCT integrity
                if("true".equalsIgnoreCase(resetExisting)) {
                    result += "\"status\": \"error\", ";
                    result += "\"message\": \"Cannot reset existing RCT enrollments. Once patients are enrolled in RCT, it cannot be undone to maintain trial integrity.\"";
                    result += "}";
                    out.println(result);
                    return;
                }
                
                // Build condition - ONLY non-RCT users (rctFlag=0)
                String condition = "active='Y' AND type='" + userType + "' AND rctFlag=0";
                
                if(!centerCode.equals("XXXX") && !centerCode.equals("ALL")) {
                    condition += " AND center='" + centerCode + "'";
                } else {
                    condition += " AND center <> 'XXXX'";
                }
                
                try {
                    // Get eligible users (only those NOT in RCT)
                    Object eligibleUsers = rcui.getValues("rg_no,name,center,emailid,phone", condition + " ORDER BY RAND()");
                    
                    if(eligibleUsers instanceof String) {
                        result += "\"status\": \"error\", ";
                        result += "\"message\": \"No eligible users found for RCT enrollment: " + eligibleUsers + "\"";
                    } else {
                        Vector userVector = (Vector)eligibleUsers;
                        int totalUsers = userVector.size();
                        int usersToSelect = Math.min(maxCount, (int)Math.ceil(totalUsers * percentage / 100.0));
                        
                        int successCount = 0;
                        int errorCount = 0;
                        int alreadyEnrolledCount = 0;
                        StringBuilder selectedUsers = new StringBuilder();
                        
                        // Randomize selection - PERMANENT enrollment
                        for(int i = 0; i < Math.min(usersToSelect, totalUsers); i++) {
                            dataobj user = (dataobj)userVector.get(i);
                            String rg_no = user.getValue("rg_no");
                            
                            // Double-check current status before enrolling
                            int currentFlag = rcui.getRctFlag(rg_no);
                            if(currentFlag == 1) {
                                alreadyEnrolledCount++;
                                continue;
                            }
                            
                            boolean enableResult = rcui.enableRctFlag(rg_no);
                            
                            if(enableResult) {
                                successCount++;
                                if(selectedUsers.length() > 0) selectedUsers.append(", ");
                                selectedUsers.append(user.getValue("name")).append(" (").append(rg_no).append(")");
                            } else {
                                errorCount++;
                            }
                        }
                        
                        result += "\"status\": \"success\", ";
                        result += "\"message\": \"Automated randomization completed! Enrolled patients cannot be removed from RCT.\", ";
                        result += "\"totalEligible\": " + totalUsers + ", ";
                        result += "\"targetSelection\": " + usersToSelect + ", ";
                        result += "\"successCount\": " + successCount + ", ";
                        result += "\"errorCount\": " + errorCount + ", ";
                        result += "\"alreadyEnrolledCount\": " + alreadyEnrolledCount + ", ";
                        result += "\"selectedUsers\": \"" + selectedUsers.toString() + "\"";
                    }
                    result += "}";
                    out.println(result);
                    
                } catch(Exception ex) {
                    result += "\"status\": \"error\", ";
                    result += "\"message\": \"Randomization failed: " + ex.getMessage() + "\"";
                    result += "}";
                    out.println(result);
                }
            }
            
            // Get current RCT statistics
            else if(cmd.equalsIgnoreCase("get_rct_stats")) {
                String centerCode = request.getParameter("center");
                String userType = request.getParameter("userType");
                if(userType == null) userType = "PAT";
                
                String condition = "active='Y' AND type='" + userType + "'";
                if(!centerCode.equals("XXXX") && !centerCode.equals("ALL")) {
                    condition += " AND center='" + centerCode + "'";
                } else {
                    condition += " AND center <> 'XXXX'";
                }
                
                try {
                    Object allUsers = rcui.getValues("rg_no,rctFlag", condition);
                    
                    if(allUsers instanceof String) {
                        result += "\"status\": \"error\", ";
                        result += "\"message\": \"No users found\"";
                    } else {
                        Vector userVector = (Vector)allUsers;
                        int totalUsers = userVector.size();
                        int rctEnabledCount = 0;
                        
                        for(int i = 0; i < userVector.size(); i++) {
                            dataobj user = (dataobj)userVector.get(i);
                            if("1".equals(user.getValue("rctFlag"))) {
                                rctEnabledCount++;
                            }
                        }
                        
                        int rctDisabledCount = totalUsers - rctEnabledCount;
                        double rctPercentage = totalUsers > 0 ? (double)rctEnabledCount / totalUsers * 100 : 0;
                        
                        result += "\"status\": \"success\", ";
                        result += "\"totalUsers\": " + totalUsers + ", ";
                        result += "\"rctEnabled\": " + rctEnabledCount + ", ";
                        result += "\"rctDisabled\": " + rctDisabledCount + ", ";
                        result += "\"rctPercentage\": " + String.format("%.1f", rctPercentage);
                    }
                    result += "}";
                    out.println(result);
                    
                } catch(Exception ex) {
                    result += "\"status\": \"error\", ";
                    result += "\"message\": \"Statistics failed: " + ex.getMessage() + "\"";
                    result += "}";
                    out.println(result);
                }
            }
            
            // REMOVED: reset_all_rct command - NOT ALLOWED for RCT integrity
            else if(cmd.equalsIgnoreCase("reset_all_rct")) {
                result += "\"status\": \"error\", ";
                result += "\"message\": \"Cannot reset RCT enrollments. Once patients are enrolled in RCT, it is permanent to maintain clinical trial integrity.\"";
                result += "}";
                out.println(result);
            }
            
            // Quick randomize - Modified to be permanent
            else if(cmd.equalsIgnoreCase("quick_randomize")) {
                String centerCode = request.getParameter("center");
                String userType = request.getParameter("userType");
                String countStr = request.getParameter("count");
                
                if(centerCode == null || countStr == null) {
                    result += "\"status\": \"error\", ";
                    result += "\"message\": \"Missing required parameters\"";
                    result += "}";
                    out.println(result);
                    return;
                }
                
                int count = Integer.parseInt(countStr);
                if(userType == null) userType = "PAT";
                
                // Only select users NOT already in RCT
                String condition = "active='Y' AND type='" + userType + "' AND rctFlag=0";
                if(!centerCode.equals("XXXX") && !centerCode.equals("ALL")) {
                    condition += " AND center='" + centerCode + "'";
                } else {
                    condition += " AND center <> 'XXXX'";
                }
                
                try {
                    Object eligibleUsers = rcui.getValues("rg_no,name", condition + " ORDER BY RAND() LIMIT " + count);
                    
                    if(eligibleUsers instanceof String) {
                        result += "\"status\": \"error\", ";
                        result += "\"message\": \"No eligible users found (all may already be enrolled in RCT)\"";
                    } else {
                        Vector userVector = (Vector)eligibleUsers;
                        int successCount = 0;
                        StringBuilder selectedUsers = new StringBuilder();
                        
                        for(int i = 0; i < userVector.size(); i++) {
                            dataobj user = (dataobj)userVector.get(i);
                            String rg_no = user.getValue("rg_no");
                            
                            // Double-check they're not already enrolled
                            int currentFlag = rcui.getRctFlag(rg_no);
                            if(currentFlag == 0) {
                                boolean enableResult = rcui.enableRctFlag(rg_no);
                                
                                if(enableResult) {
                                    successCount++;
                                    if(selectedUsers.length() > 0) selectedUsers.append(", ");
                                    selectedUsers.append(user.getValue("name")).append(" (").append(rg_no).append(")");
                                }
                            }
                        }
                        
                        result += "\"status\": \"success\", ";
                        result += "\"message\": \"Quick randomization completed! Enrollment is permanent.\", ";
                        result += "\"requested\": " + count + ", ";
                        result += "\"available\": " + userVector.size() + ", ";
                        result += "\"successCount\": " + successCount + ", ";
                        result += "\"selectedUsers\": \"" + selectedUsers.toString() + "\"";
                    }
                    result += "}";
                    out.println(result);
                    
                } catch(Exception ex) {
                    result += "\"status\": \"error\", ";
                    result += "\"message\": \"Quick randomization failed: " + ex.getMessage() + "\"";
                    result += "}";
                    out.println(result);
                }
            }
            
            // NEW: Get enrollment history (for audit purposes)
            else if(cmd.equalsIgnoreCase("get_enrollment_audit")) {
                String centerCode = request.getParameter("center");
                String userType = request.getParameter("userType");
                if(userType == null) userType = "PAT";
                
                String condition = "active='Y' AND type='" + userType + "' AND rctFlag=1";
                if(!centerCode.equals("XXXX") && !centerCode.equals("ALL")) {
                    condition += " AND center='" + centerCode + "'";
                } else {
                    condition += " AND center <> 'XXXX'";
                }
                condition += " ORDER BY instance_time DESC";
                
                try {
                    Object enrolledUsers = rcui.getValues("rg_no,name,center,instance_time", condition);
                    
                    if(enrolledUsers instanceof String) {
                        result += "\"status\": \"error\", ";
                        result += "\"message\": \"No enrolled users found\"";
                    } else {
                        Vector userVector = (Vector)enrolledUsers;
                        StringBuilder auditList = new StringBuilder();
                        
                        for(int i = 0; i < userVector.size(); i++) {
                            dataobj user = (dataobj)userVector.get(i);
                            if(auditList.length() > 0) auditList.append("|");
                            auditList.append(user.getValue("name"))
                                    .append(" (").append(user.getValue("rg_no")).append(") - ")
                                    .append(user.getValue("center"))
                                    .append(" - ").append(user.getValue("instance_time"));
                        }
                        
                        result += "\"status\": \"success\", ";
                        result += "\"totalEnrolled\": " + userVector.size() + ", ";
                        result += "\"enrolledUsers\": \"" + auditList.toString() + "\"";
                    }
                    result += "}";
                    out.println(result);
                    
                } catch(Exception ex) {
                    result += "\"status\": \"error\", ";
                    result += "\"message\": \"Audit retrieval failed: " + ex.getMessage() + "\"";
                    result += "}";
                    out.println(result);
                }
            }
        }
    } catch(Exception e) {
        result += "\"status\": \"error\", ";
        result += "\"message\": \"System Exception: " + e.getMessage() + "\"";
        result += "}";
        out.println(result);
        e.printStackTrace();
    }
%>