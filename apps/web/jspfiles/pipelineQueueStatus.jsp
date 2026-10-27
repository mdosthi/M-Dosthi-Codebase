<%@page contentType="application/json" import="imedix.rcDisplayData,imedix.dataobj,java.util.*,org.json.simple.JSONObject,org.json.simple.JSONArray" %>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject result = new JSONObject();
JSONArray jobs = new JSONArray();
JSONObject counts = new JSONObject();

try {
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));

    // Summary counts
    Object countsResult = rd.getPipelineJobStatusCounts();
    if (countsResult instanceof Vector) {
        Vector countsVec = (Vector) countsResult;
        for (int i = 0; i < countsVec.size(); i++) {
            dataobj c = (dataobj) countsVec.get(i);
            counts.put(c.getValue("status"), Long.parseLong(c.getValue("cnt")));
        }
    }

    // Today completed / failed counts
    String processedToday = rd.getPipelineJobsProcessedToday();
    counts.put("processed_today", processedToday != null ? Long.parseLong(processedToday) : 0L);

    // Recent jobs — last 100, newest first, with patient name
    Object jobsResult = rd.getRecentPipelineJobs();
    if (jobsResult instanceof Vector) {
        Vector jobsVec = (Vector) jobsResult;
        for (int i = 0; i < jobsVec.size(); i++) {
            dataobj j = (dataobj) jobsVec.get(i);
            JSONObject job = new JSONObject();
            job.put("id",               Long.parseLong(j.getValue("id")));
            job.put("pat_id",           j.getValue("pat_id"));
            job.put("pat_name",         j.getValue("pat_name"));
            job.put("session_id",       j.getValue("session_id"));
            job.put("force_reannotate", "1".equals(j.getValue("force_reannotate")));
            job.put("status",           j.getValue("status"));
            job.put("created_at",       j.getValue("created_at"));
            job.put("started_at",       j.getValue("started_at"));
            job.put("finished_at",      j.getValue("finished_at"));
            job.put("error_message",    j.getValue("error_message"));
            jobs.add(job);
        }
    }

    result.put("success", true);
    result.put("counts", counts);
    result.put("jobs", jobs);
} catch (Exception e) {
    result.put("success", false);
    result.put("error", e.getMessage());
}

out.print(result.toJSONString());
%>
