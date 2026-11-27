package imedix.saMiX.service;

import imedix.saMiX.dao.PobadoScreeningRepository;
import imedix.saMiX.dao.UserRepository;
import imedix.saMiX.model.PobadoScreeningRequest;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

@Service
public class PobadoScreeningService {
    private final PobadoScreeningRepository repository;
    private final UserRepository userRepository;

    public PobadoScreeningService(PobadoScreeningRepository repository, UserRepository userRepository) {
        this.repository = repository;
        this.userRepository = userRepository;
    }

    public long create(PobadoScreeningRequest request) {
        authorizePatient(request.crNumber());
        return repository.save(actor(), request, score(request));
    }

    public List<Map<String, Object>> find(String patientId) {
        authorizePatient(patientId);
        return repository.findByPatient(patientId);
    }

    private void authorizePatient(String patientId) {
        if (!repository.patientExists(patientId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Patient not found");
        }
        String type = String.valueOf(userRepository.getUserInfo(actor()).get("type"));
        if ("PAT".equalsIgnoreCase(type)) {
            if (!actor().equalsIgnoreCase(patientId)) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Patient access is restricted to the authenticated patient");
            }
            return;
        }
        if ("doc".equalsIgnoreCase(type) && !repository.doctorHasPatient(actor(), patientId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Doctor is not assigned to this patient");
        }
        if (!"doc".equalsIgnoreCase(type) && !"adm".equalsIgnoreCase(type)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Role is not allowed to access Pobado screening");
        }
    }

    private int score(PobadoScreeningRequest r) {
        return value(r.fatigue()) + value(r.mood()) + value(r.anxiety()) + value(r.depression()) + value(r.limitations()) + value(r.socialProblems());
    }

    private int value(Integer value) { return value == null ? 0 : value; }

    private String actor() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getName() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
        }
        return authentication.getName();
    }
}