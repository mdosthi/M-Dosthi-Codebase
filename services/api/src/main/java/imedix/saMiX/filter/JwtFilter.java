package imedix.saMiX.filter;

import com.fasterxml.jackson.databind.ObjectMapper;
import imedix.saMiX.helper.JwtUtil;
import imedix.saMiX.service.iMediXUserDetailService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

@Component
public class JwtFilter extends OncePerRequestFilter {

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private iMediXUserDetailService imediXUserDetailService;

    private String username;
    private String patid;
    private String type;
    private String reg_no;
    private String key;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        String authorization = request.getHeader("Authorization");
        String token = null;
        String userName = null;
        patid = null;
        reg_no = null;

        try {
            if (authorization != null && authorization.startsWith("Bearer")) {
                token = authorization.substring(7);
                userName = jwtUtil.extractUsername(token);
                //patid = jwtUtil.extractPatientId(token);
                type = jwtUtil.extractType(token);
                reg_no = jwtUtil.extractRegNo(token);
                //reg_no = jwtUtil.extractRegNo(token);
                key = jwtUtil.extractKey(token);
            }

            if (userName != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                this.username = userName;
                UserDetails userDetails = imediXUserDetailService.loadUserByUsername(userName);
                if (jwtUtil.validateToken(token, userDetails)) {
                    UsernamePasswordAuthenticationToken usernamePasswordAuthenticationToken =
                            new UsernamePasswordAuthenticationToken(userDetails,
                                    null, userDetails.getAuthorities());
                    usernamePasswordAuthenticationToken.setDetails(
                            new WebAuthenticationDetailsSource().buildDetails(request)
                    );
                    SecurityContextHolder.getContext().setAuthentication(usernamePasswordAuthenticationToken);
                }
            }
        }catch (Exception e){
            //response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.setStatus(HttpServletResponse.SC_OK    );
            response.setContentType("application/json");

            //pass down the actual obj that exception handler normally send

            PrintWriter out = response.getWriter();
            Map<String,String> res = new HashMap<>();
            res.put("status","error");
            res.put("message", "token has expired");
            System.out.println("token has expired");
            String json = new ObjectMapper().writeValueAsString(res);
            out.print(json);
            out.flush();
            return;
        }
        filterChain.doFilter(request,response);
    }

    public String getUsername() {
        return username;
    }

    public String getPatientID(){
        return patid;
    }

    public String getType(){
        return type;
    }

    public String get_reg_no() {
        return reg_no;
    }

    public String getKey() {
        return key;
    }

    public String encrypt(String plainText){
        try {
            byte[] decodedKey = Base64.getDecoder().decode(key);
            SecretKey originalKey = new SecretKeySpec(decodedKey, 0, decodedKey.length, "AES");
            return jwtUtil.encrypt(plainText, originalKey);
        }catch (Exception e){
            return "";
        }
    }

    public String decrypt(String encryptedText){
        try {
            byte[] decodedKey = Base64.getDecoder().decode(key);
            SecretKey originalKey = new SecretKeySpec(decodedKey, 0, decodedKey.length, "AES");
            return jwtUtil.decrypt(encryptedText, originalKey);
        }catch (Exception e){
            return "";
        }
    }


}
