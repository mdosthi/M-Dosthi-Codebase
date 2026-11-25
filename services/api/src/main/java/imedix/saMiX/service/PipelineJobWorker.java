package imedix.saMiX.service;

import imedix.saMiX.dao.UserRepository;
import imedix.saMiX.model.PipelineJob;
import jakarta.annotation.PostConstruct;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
public class PipelineJobWorker {

    private static final String PIPELINE_SCRIPT =
            "/home/sadmin/M-Dosthi/API/annotate/run_pipeline.sh";

    @Autowired
    private UserRepository userRepository;

    @PostConstruct
    public void recoverStaleJobsOnStartup() {
        userRepository.recoverStalePipelineJobs();
    }

    // Runs once a day at midnight to purge completed/failed jobs older than 2 days.
    @Scheduled(cron = "0 0 0 * * *")
    public void purgeOldJobs() {
        userRepository.deleteOldCompletedPipelineJobs();
    }

    // Checked every minute; drains the pending queue whenever the current time falls
    // within the admin-configured annotation window (see pipeline_settings table).
    @Scheduled(cron = "0 * * * * *")
    public void processQueue() {
        Map<String, Object> window = userRepository.getPipelineWindow();
        LocalTime start = LocalTime.parse((String) window.get("start_time"));
        LocalTime end = LocalTime.parse((String) window.get("end_time"));

        PipelineJob job;
        while (isWithinWindow(LocalTime.now(), start, end) &&
                (job = userRepository.fetchAndLockNextPipelineJob()) != null) {
            runJob(job);
        }
    }

    // Supports windows that wrap past midnight (e.g. start=22:00, end=02:00).
    // An equal start/end is treated as a zero-width window, i.e. annotation disabled.
    private boolean isWithinWindow(LocalTime now, LocalTime start, LocalTime end) {
        if (start.isBefore(end)) {
            return !now.isBefore(start) && now.isBefore(end);
        } else if (start.isAfter(end)) {
            return !now.isBefore(start) || now.isBefore(end);
        }
        return false;
    }

    private void runJob(PipelineJob job) {
        try {
            if (job.isForceReannotate() && job.getSessionId() != null) {
                userRepository.deleteSignalForReannotation(job.getPatId(), job.getSessionId());
            }

            List<String> cmd = new ArrayList<>(Arrays.asList("/bin/bash", PIPELINE_SCRIPT, job.getPatId()));
            if (job.getSessionId() != null) {
                cmd.add("--session");
                cmd.add(job.getSessionId());
            }

            ProcessBuilder pb = new ProcessBuilder(cmd);
            pb.inheritIO();
            Process process = pb.start();
            int exitCode = process.waitFor();

            if (exitCode == 0) {
                userRepository.markPipelineJobCompleted(job.getId());
                System.out.println("Annotate pipeline completed for: " + job.getPatId()
                        + (job.getSessionId() != null ? " session: " + job.getSessionId() : ""));
            } else {
                userRepository.markPipelineJobFailed(job.getId(), "Exit code: " + exitCode);
                System.err.println("Annotate pipeline failed for " + job.getPatId() + " with exit code " + exitCode);
            }
        } catch (Exception e) {
            userRepository.markPipelineJobFailed(job.getId(), e.getMessage());
            System.err.println("WARNING - Could not run annotate pipeline for " + job.getPatId() + ": " + e.getMessage());
        }
    }
}
