package kafdrop.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class LogoutController {

  @PostMapping("/logout")
  public String logoutPost(HttpServletRequest request) {
    ClusterController.userEmail = "";
    request.getSession().invalidate();
    return "redirect:http://localhost:8321/realms/delta-inspira/protocol/openid-connect/logout";
  }
}
