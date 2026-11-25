package imedix.saMiX.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
public class WebhookController {

    @Autowired
    private WhatsAppController whatsAppController;

    @GetMapping("/webhook")
    public ResponseEntity<String> verifyWebhook(
            @RequestParam(value = "hub.mode", required = false) String mode,
            @RequestParam(value = "hub.verify_token", required = false) String token,
            @RequestParam(value = "hub.challenge", required = false) String challenge) {
        return whatsAppController.verifyWebhook(mode, token, challenge);
    }

    @PostMapping("/webhook")
    public ResponseEntity<Void> receiveMessage(@RequestBody String jsonPayload) {
        return whatsAppController.receiveMessage(jsonPayload);
    }
}
