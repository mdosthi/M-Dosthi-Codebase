package imedix.saMiX.helper;

import imedix.saMiX.dao.UserRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.io.Serializable;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

@Component
public class JwtUtil implements Serializable {
    static Cipher cipher;

    @Value("${secretkey}")
    private String SECRET_KEY;

    @Autowired
    private UserRepository userRepository;

    public JwtUtil() {
        try {
            cipher = Cipher.getInstance("AES");
        }catch (Exception e){
            e.printStackTrace();
        }
    }

    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public String extractPatientId(String token) {
        final Claims claims = extractAllClaims(token);
        if(claims.containsKey("patid")){
            return claims.get("patid").toString();
        }else{
            return "";
        }
    }

    public String extractType(String token){
        final Claims claims = extractAllClaims(token);
        if(claims.containsKey("type")){
            return claims.get("type").toString();
        }else if(claims.containsKey("user_type")){
            return claims.get("user_type").toString();
        }else{
            return lookupUserInfo(claims).getOrDefault("type", "").toString();
        }
    }

    public String extractRegNo(String token){
        final Claims claims = extractAllClaims(token);
        if(claims.containsKey("reg_no")){
            return claims.get("reg_no").toString();
        }else{
            return lookupUserInfo(claims).getOrDefault("rg_no", "").toString();
        }
    }

    private Map<String, Object> lookupUserInfo(Claims claims) {
        String username = claims.getSubject();
        if (username == null || username.isBlank()) {
            return Map.of();
        }
        return userRepository.getUserInfo(username);
    }

    public String extractKey(String token){
        final Claims claims = extractAllClaims(token);
        String decKey = "";
        try {
            if (claims.containsKey("key")) {
                String key = claims.get("key").toString();
                byte[] decodedKey = Base64.getDecoder().decode(SECRET_KEY);
                // rebuild key using SecretKeySpec
                SecretKey originalKey = new SecretKeySpec(decodedKey, 0, decodedKey.length, "AES");
                decKey = decrypt(key, originalKey);
            }
        }catch (Exception e){
            e.printStackTrace();
        }
        return decKey;
    }

    public Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }
    private Claims extractAllClaims(String token) {
        return Jwts.parser()
            .verifyWith(signingKey())
            .build()
            .parseSignedClaims(token)
            .getPayload();
    }

    private Boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    public String generateToken(UserDetails userDetails) {
        Map<String, Object> claims = new HashMap<>();
        Map<String, Object> userinfo = userRepository.getUserInfo(userDetails.getUsername());
        String type = (String) userinfo.get("type");
        String regNo = (String) userinfo.get("rg_no");
        claims.put("type", type);
        claims.put("reg_no", regNo);
        // generate secretkey
        try {
            String newkey = Base64.getEncoder().encodeToString(
                    KeyGenerator.getInstance("AES").generateKey().getEncoded());
            //System.out.println("Generated key: "+ newkey);
            // encrypt key
            // decode the base64 encoded string
            byte[] decodedKey = Base64.getDecoder().decode(SECRET_KEY);
            // rebuild key using SecretKeySpec
            SecretKey originalKey = new SecretKeySpec(decodedKey, 0, decodedKey.length, "AES");
            String key = encrypt(newkey,originalKey);
            claims.put("key", key);
        }catch (Exception e){
            e.printStackTrace();
            claims.put("key", "");
        }

        return createToken(claims, userDetails.getUsername());
    }

    private String createToken(Map<String, Object> claims, String subject) {

//        return Jwts.builder().setClaims(claims).setSubject(subject).setIssuedAt(new Date(System.currentTimeMillis()))
//                .setExpiration(new Date(System.currentTimeMillis() + 1000 * 60 * 60 * 10))
         long thirtyDaysInMillis = 1000L * 60 * 60 * 24 * 30;
        return Jwts.builder()
                .setClaims(claims)
                .setSubject(subject)
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(new Date(System.currentTimeMillis() + thirtyDaysInMillis))
                .signWith(signingKey(), Jwts.SIG.HS256)
                .compact();
    }

    private SecretKey signingKey() {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(SECRET_KEY.getBytes(StandardCharsets.UTF_8));
            return new SecretKeySpec(digest, "HmacSHA256");
        } catch (Exception e) {
            throw new IllegalStateException("Unable to create JWT signing key", e);
        }
    }

    public Boolean validateToken(String token, UserDetails userDetails) {
        final String username = extractUsername(token);
        return (username.equals(userDetails.getUsername()) && !isTokenExpired(token));
    }

    public String encrypt(String plainText, SecretKey secretKey)
            throws Exception {
        byte[] plainTextByte = plainText.getBytes();
        cipher.init(Cipher.ENCRYPT_MODE, secretKey);
        byte[] encryptedByte = cipher.doFinal(plainTextByte);
        Base64.Encoder encoder = Base64.getEncoder();
        String encryptedText = encoder.encodeToString(encryptedByte);
        return encryptedText;
    }

    public String decrypt(String encryptedText, SecretKey secretKey)
            throws Exception {
        Base64.Decoder decoder = Base64.getDecoder();
        byte[] encryptedTextByte = decoder.decode(encryptedText);
        cipher.init(Cipher.DECRYPT_MODE, secretKey);
        byte[] decryptedByte = cipher.doFinal(encryptedTextByte);
        String decryptedText = new String(decryptedByte);
        return decryptedText;
    }
}
