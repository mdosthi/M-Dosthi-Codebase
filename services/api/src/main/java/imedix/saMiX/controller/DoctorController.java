package imedix.saMiX.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import imedix.saMiX.filter.JwtFilter;
import imedix.saMiX.service.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.net.ssl.*;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.cert.X509Certificate;
import java.text.SimpleDateFormat;
import java.util.*;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping(path = "/api/doctor")
public class DoctorController {
    @Autowired
    private JwtFilter jwtFilter;

    @Autowired
    PatientQueueInfoService patientQueueInfoService;

    @Autowired
    UserInfoService userInfoService;

    private SimpleDateFormat mysqlDate = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    private static void trustAllCertificates() throws NoSuchAlgorithmException, KeyManagementException
    {
        TrustManager[] trustManagers = new TrustManager[]{new X509TrustManager()
        {
            public X509Certificate[] getAcceptedIssuers()
            {
                return new X509Certificate[0];
            }

            public void checkClientTrusted(
                    X509Certificate[] certs, String authType)
            {
            }

            public void checkServerTrusted(
                    X509Certificate[] certs, String authType)
            {
            }
        }};

        SSLContext sslContext = SSLContext.getInstance("SSL");
        sslContext.init(null, trustManagers, new SecureRandom());
        HttpsURLConnection.setDefaultSSLSocketFactory(sslContext.getSocketFactory());
    }

    @GetMapping("/get-local-patients")
    public Map<String, Object> getLocalPatients(){
        Map<String,Object> result = new HashMap<>();
        String type = jwtFilter.getType();
        String reg_no = jwtFilter.get_reg_no();

        boolean isClinician = type != null
            && (type.equalsIgnoreCase("doc") || type.equalsIgnoreCase("psy"));

        if(isClinician){
            try{
                List<Map<String,Object>> ret = "psy".equalsIgnoreCase(type)
                    ? patientQueueInfoService.getAllPatientsForPsychologist()
                    : patientQueueInfoService.getLocalPatientQueue(reg_no);
                result.put("status", "success");
                result.put("data", ret);
            }catch (Exception e){
                e.printStackTrace();
                result.put("status", "error");
                result.put("message","could not get local patient queue");
            }
        }else{
            result.put("status", "error");
            result.put("message","You are not authorized to access this resource");
        }
        return result;
    }


}
