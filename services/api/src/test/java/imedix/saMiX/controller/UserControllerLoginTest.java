package imedix.saMiX.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static java.util.Map.entry;
import static org.mockito.ArgumentMatchers.anyString;

import imedix.saMiX.dao.UserRepository;
import imedix.saMiX.helper.JwtUtil;
import imedix.saMiX.model.JwtReqest;
import imedix.saMiX.service.iMediXUserDetailService;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.User;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class UserControllerLoginTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private JwtUtil jwtUtil;

    @Mock
    private AuthenticationManager authenticationManager;

    @Mock
    private iMediXUserDetailService userDetailsService;

    private UserController controller;

    @BeforeEach
    void setUp() {
        controller = new UserController();
        ReflectionTestUtils.setField(controller, "userRepository", userRepository);
        ReflectionTestUtils.setField(controller, "jwtUtil", jwtUtil);
        ReflectionTestUtils.setField(controller, "authenticationManager", authenticationManager);
        ReflectionTestUtils.setField(controller, "imedixUserDetailService", userDetailsService);
    }

    @Test
    void migratesExistingPlaintextPasswordAfterSuccessfulVerification() throws Exception {
        String encodedPassword = "md5-hash";
        Map<String, Object> userInfo = Map.of(
                "uid", "patient-1",
                "pwd", "correct-password",
                "name", "Patient",
                "type", "PAT",
                "dpdp_agreed", 1);
        when(userRepository.encodePassword("correct-password")).thenReturn(encodedPassword);
        when(authenticationManager.authenticate(any(Authentication.class)))
                .thenThrow(new BadCredentialsException("legacy plaintext password"))
                .thenReturn(UsernamePasswordAuthenticationToken.authenticated(
                        "patient-1", null, java.util.List.of()));
        when(userRepository.getUserInfo("patient-1")).thenReturn(userInfo, userInfo, userInfo);
        when(userRepository.updatePassword("patient-1", encodedPassword)).thenReturn(true);
        when(userDetailsService.loadUserByUsername("patient-1"))
                .thenReturn(User.withUsername("patient-1").password(encodedPassword).authorities("user").build());
        when(jwtUtil.generateToken(any())).thenReturn("jwt-token");

        var response = controller.login(new JwtReqest("patient-1", "correct-password"));

        assertThat(response.getStatus()).isEqualTo("success");
        assertThat(response.getJwtToken()).isEqualTo("jwt-token");
        verify(userRepository).updatePassword("patient-1", encodedPassword);
    }

    @Test
    void doesNotMigrateWhenSubmittedPasswordDoesNotMatchLegacyValue() throws Exception {
        when(userRepository.encodePassword("wrong-password")).thenReturn("wrong-hash");
        when(authenticationManager.authenticate(any(Authentication.class)))
                .thenThrow(new BadCredentialsException("invalid credentials"));
        Map<String, Object> userInfo = Map.of(
                "uid", "patient-1",
                "pwd", "different-legacy-password");
        when(userRepository.getUserInfo("patient-1")).thenReturn(userInfo, userInfo);

        var response = controller.login(new JwtReqest("patient-1", "wrong-password"));

        assertThat(response.getStatus()).isEqualTo("error");
        assertThat(response.getMessage()).isEqualTo("Invalid Credential");
        verify(userRepository, never()).updatePassword(anyString(), anyString());
    }

    @Test
    void trimsWhitespaceFromCredentialsLikeTheLegacyLogin() throws Exception {
        String encodedPassword = "md5-hash";
        Map<String, Object> userInfo = Map.of(
                "uid", "patient-1",
                "pwd", encodedPassword,
                "name", "Patient",
                "type", "PAT",
                "dpdp_agreed", 1);
        when(userRepository.encodePassword(" correct-password ")).thenReturn("untrimmed-hash");
        when(userRepository.encodePassword("correct-password")).thenReturn(encodedPassword);
        when(authenticationManager.authenticate(any(Authentication.class)))
                .thenThrow(new BadCredentialsException("untrimmed credentials"))
                .thenReturn(UsernamePasswordAuthenticationToken.authenticated(
                        "patient-1", null, java.util.List.of()));
        when(userRepository.getUserInfo("patient-1"))
                .thenReturn(userInfo, userInfo, userInfo);
        when(userDetailsService.loadUserByUsername("patient-1"))
                .thenReturn(User.withUsername("patient-1").password(encodedPassword).authorities("user").build());
        when(jwtUtil.generateToken(any())).thenReturn("jwt-token");

        var response = controller.login(new JwtReqest(" patient-1 ", " correct-password "));

        assertThat(response.getStatus()).isEqualTo("success");
        assertThat(response.getJwtToken()).isEqualTo("jwt-token");
        verify(userRepository).encodePassword("correct-password");
        verify(userRepository, org.mockito.Mockito.times(3)).getUserInfo("patient-1");
        verify(userDetailsService).loadUserByUsername("patient-1");
    }

    @Test
    void authenticatesPsychologistWithCaseInsensitiveUserId() throws Exception {
        String encodedPassword = "md5-hash";
        Map<String, Object> userInfo = Map.of(
                "uid", "psy-user",
                "pwd", encodedPassword,
                "name", "Psychologist",
                "type", "psy",
                "dpdp_agreed", 1);
        when(userRepository.encodePassword("correct-password")).thenReturn(encodedPassword);
        when(userRepository.getUserInfo("PSY-USER")).thenReturn(userInfo);
        when(userRepository.getUserInfo("psy-user")).thenReturn(userInfo);
        when(authenticationManager.authenticate(any(Authentication.class)))
                .thenReturn(UsernamePasswordAuthenticationToken.authenticated(
                        "psy-user", null, java.util.List.of()));
        when(userDetailsService.loadUserByUsername("psy-user"))
                .thenReturn(User.withUsername("psy-user").password(encodedPassword).authorities("user").build());
        when(jwtUtil.generateToken(any())).thenReturn("jwt-token");

        var response = controller.login(new JwtReqest("PSY-USER", "correct-password"));

        assertThat(response.getStatus()).isEqualTo("success");
        assertThat(response.getType()).isEqualTo("psy");
        assertThat(response.getJwtToken()).isEqualTo("jwt-token");
        verify(authenticationManager).authenticate(any(Authentication.class));
        verify(userDetailsService).loadUserByUsername("psy-user");
    }

    @Test
    void rejectsWhitespaceOnlyPasswordsBeforeAuthentication() throws Exception {
        var response = controller.login(new JwtReqest("patient-1", "   "));

        assertThat(response.getStatus()).isEqualTo("error");
        assertThat(response.getMessage()).isEqualTo("Invalid Credential");
        verify(userRepository, never()).encodePassword(anyString());
    }

    @Test
    void hashesPasswordsBeforeCreatingAccounts() {
        when(userRepository.encodePassword("new-password")).thenReturn("md5-hash");
        when(userRepository.createNewEdosthiLogin(any())).thenReturn(true);
        Map<String, String> request = Map.ofEntries(
                entry("uid", "patient-2"),
                entry("pwd", "new-password"),
                entry("name", "Patient"),
                entry("crtdate", "2026-10-30"),
                entry("rg_no", "TEST-PATIENT-2"),
                entry("center", "XXXX"),
                entry("type", "PAT"),
                entry("active", "Y"),
                entry("available", "Y"),
                entry("referral", "Y"),
                entry("verified", "A"),
                entry("verifemail", "N"),
                entry("verifphone", "N"),
                entry("consent", "N"));

        Map<String, Object> response = controller.createNewEdosthiLogin(request);

        verify(userRepository).createNewEdosthiLogin(
                org.mockito.ArgumentMatchers.<Map<String, String>>argThat(
                        data -> "md5-hash".equals(data.get("pwd"))
                                && "TEST-PATIENT-2".equals(data.get("rg_no"))));
        assertThat(response.get("status")).isEqualTo("success");
    }

    @Test
    void requiresRegistrationNumberWhenCreatingAccounts() {
        Map<String, String> request = Map.of(
                "uid", "patient-2",
                "pwd", "new-password");

        Map<String, Object> response = controller.createNewEdosthiLogin(request);

        assertThat(response.get("status")).isEqualTo("error");
        assertThat(response.get("message")).isEqualTo("Registration number is required");
        verify(userRepository, never()).createNewEdosthiLogin(any());
    }
}
