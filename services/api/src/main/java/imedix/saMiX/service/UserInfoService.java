package imedix.saMiX.service;

import imedix.saMiX.dao.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.Period;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

@Service
public class UserInfoService {
    @Autowired
    private UserRepository userRepository;

    public Map<String,Object> getUserInfo(String username){
        return userRepository.getUserInfo(username);
    }
}
