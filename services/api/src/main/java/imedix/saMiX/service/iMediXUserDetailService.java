package imedix.saMiX.service;

import imedix.saMiX.dao.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Map;

@Service
public class iMediXUserDetailService implements UserDetailsService {

    @Autowired
    private UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        try {
            Map<String, Object> user = userRepository.getUserInfo(username);

            //String uid = (String) user.get("uid");
            //String pwd = (String) user.get("pwd");
            //System.out.println(user.get("userid"));
            String uid = (String) user.get("uid");
            String pwd = (String) user.get("pwd");
            return new User(uid, pwd, new ArrayList<>());
        }catch (Exception e){
            throw new UsernameNotFoundException("User not found");
        }
    }
}
