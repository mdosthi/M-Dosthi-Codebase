package imedix.saMiX.controller;

import imedix.saMiX.model.PobadoScreeningRequest;
import imedix.saMiX.service.PobadoScreeningService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/pobado")
public class PobadoScreeningController {
    private final PobadoScreeningService service;

    public PobadoScreeningController(PobadoScreeningService service) {
        this.service = service;
    }

    @PostMapping("/screenings")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@Valid @RequestBody PobadoScreeningRequest request) {
        return Map.of("id", service.create(request), "crNumber", request.crNumber());
    }

    @GetMapping("/patients/{patientId}/screenings")
    public Map<String, Object> find(@PathVariable String patientId) {
        List<Map<String, Object>> records = service.find(patientId);
        return Map.of("records", records);
    }
}