package kafdrop.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfiguration {

  @Bean
  public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
      .csrf(csrf -> csrf.disable())
      .oauth2Login()
      .defaultSuccessUrl("/", true)
      .and()
      .authorizeHttpRequests()
      .anyRequest().authenticated()
      .and()
      .logout()
      .logoutUrl("/ln") // URL for logout
      .logoutSuccessUrl("/");
    return http.build();
  }
}
