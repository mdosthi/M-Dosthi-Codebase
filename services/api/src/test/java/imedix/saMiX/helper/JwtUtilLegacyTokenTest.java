package imedix.saMiX.helper;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.Date;
import java.util.Map;

import javax.crypto.SecretKey;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import imedix.saMiX.dao.UserRepository;
import io.jsonwebtoken.Jwts;

class JwtUtilLegacyTokenTest {

    private static final String USERNAME = "aimkpsy2";
    private static final String SECRET = "test-secret-key";

    private JwtUtil jwtUtil;
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        jwtUtil = new JwtUtil();
        userRepository = mock(UserRepository.class);
        ReflectionTestUtils.setField(jwtUtil, "SECRET_KEY", SECRET);
        ReflectionTestUtils.setField(jwtUtil, "userRepository", userRepository);
    }

    @Test
    void resolvesRoleAndRegistrationForUnexpiredLegacyTokenWithoutClinicianClaims() {
        when(userRepository.getUserInfo(USERNAME)).thenReturn(Map.of(
                "type", "psy",
                "rg_no", "psyAIMK0190000"));
        SecretKey signingKey = ReflectionTestUtils.invokeMethod(jwtUtil, "signingKey");
        Date now = new Date();
        String legacyToken = Jwts.builder()
                .subject(USERNAME)
                .issuedAt(now)
                .expiration(new Date(now.getTime() + 60_000))
                .signWith(signingKey)
                .compact();

        assertThat(jwtUtil.extractType(legacyToken)).isEqualTo("psy");
        assertThat(jwtUtil.extractRegNo(legacyToken)).isEqualTo("psyAIMK0190000");
    }
}