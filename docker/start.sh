#! /bin/bash

if [ -n "$KEYCLOAK_PROVIDER" ]; then
    cat << EOF > /kafdrop/src/main/resources/application.yml
server:
  port: \${SERVER_PORT:9000}
  servlet:
    context-path: /
  error:
    path: /error
    whitelabel:
      enabled: false
  ssl:
    key-store-type: \${SSL_KEY_STORE_TYPE:PKCS12}
    key-store: \${SSL_KEY_STORE:}
    key-store-password: \${SSL_KEY_STORE_PASSWORD:}
    key-alias: \${SSL_KEY_ALIAS:}
    enabled: \${SSL_ENABLED:false}

spring:
  jmx:
    enabled: true
    default_domain: Kafdrop
  jackson:
    deserialization:
      fail_on_unknown_properties: false
      read_unknown_enum_values_as_null: true
  mvc:
    pathmatch:
      matching-strategy: ant_path_matcher
  security:
    oauth2:
      client:
        registration:
          keycloak:
            client-id: ${CLIENT_ID}
            client-secret: ${CLIENT_SECRET}
            authorization-grant-type: authorization_code
            redirect-uri: "{baseUrl}/login/oauth2/code/{registrationId}"
            scope: openid, profile, email
            authorization-uri: $KEYCLOAK_PROVIDER/protocol/openid-connect/auth
            token-uri: $KEYCLOAK_PROVIDER/protocol/openid-connect/token
            user-info-uri: $KEYCLOAK_PROVIDER/protocol/openid-connect/userinfo
            jwk-set-uri: $KEYCLOAK_PROVIDER/protocol/openid-connect/certs
            logout-uri: $KEYCLOAK_PROVIDER/protocol/openid-connect/logout
        provider:
          keycloak:
            issuer-uri: $KEYCLOAK_PROVIDER
management:
  endpoints:
    web:
      base-path: /actuator
      exposure.include: "*"
  server:
    port: 9000

kafdrop.monitor:
  clientId: Kafdrop

kafka:
  brokerConnect: ${KAFKA_BROKERCONNECT}
  saslMechanism: "PLAIN"
  securityProtocol: "SASL_PLAINTEXT"
  truststoreFile: "\${KAFKA_TRUSTSTORE_FILE:kafka.truststore.jks}"
  propertiesFile : "\${KAFKA_PROPERTIES_FILE:kafka.properties}"
  keystoreFile: "\${KAFKA_KEYSTORE_FILE:kafka.keystore.jks}"
EOF
    cat << EOF > /kafdrop/src/main/java/kafdrop/controller/LogoutController.java
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
    return "redirect:$KEYCLOAK_PROVIDER/protocol/openid-connect/logout";
  }
}
EOF
else
    rm /kafdrop/src/main/java/kafdrop/controller/LogoutController.java
    cp /nosec/SecurityConfiguration.java /kafdrop/src/main/java/kafdrop/config/SecurityConfiguration.java
    cat << EOF > /kafdrop/src/main/resources/application.yml
server:
  port: \${SERVER_PORT:9000}
  servlet:
    context-path: /
  error:
    path: /error
    whitelabel:
      enabled: false
  ssl:
    key-store-type: \${SSL_KEY_STORE_TYPE:PKCS12}
    key-store: \${SSL_KEY_STORE:}
    key-store-password: \${SSL_KEY_STORE_PASSWORD:}
    key-alias: \${SSL_KEY_ALIAS:}
    enabled: \${SSL_ENABLED:false}

spring:
  jmx:
    enabled: true
    default_domain: Kafdrop
  jackson:
    deserialization:
      fail_on_unknown_properties: false
      read_unknown_enum_values_as_null: true
  mvc:
    pathmatch:
      matching-strategy: ant_path_matcher
  security:
    enabled: false
management:
  endpoints:
    web:
      base-path: /actuator
      exposure.include: "*"
  server:
    port: 9000

kafdrop.monitor:
  clientId: Kafdrop

kafka:
  brokerConnect: ${KAFKA_BROKERCONNECT}
  saslMechanism: "PLAIN"
  securityProtocol: "SASL_PLAINTEXT"
  truststoreFile: "\${KAFKA_TRUSTSTORE_FILE:kafka.truststore.jks}"
  propertiesFile : "\${KAFKA_PROPERTIES_FILE:kafka.properties}"
  keystoreFile: "\${KAFKA_KEYSTORE_FILE:kafka.keystore.jks}"
EOF
fi
cd /kafdrop
mvn clean install -DskipTests



echo ""
# Website used to generate the text: https://patorjk.com/software/taag/#p=display&f=Alligator2&t=KAFDROP%204
echo ":::    :::     :::     :::::::::: :::::::::  :::::::::   ::::::::  :::::::::           :::    "
echo ":+:   :+:    :+: :+:   :+:        :+:    :+: :+:    :+: :+:    :+: :+:    :+:         :+:     "
echo "+:+  +:+    +:+   +:+  +:+        +:+    +:+ +:+    +:+ +:+    +:+ +:+    +:+        +:+ +:+  "
echo "+#++:++    +#++:++#++: :#::+::#   +#+    +:+ +#++:++#:  +#+    +:+ +#++:++#+        +#+  +:+  "
echo "+#+  +#+   +#+     +#+ +#+        +#+    +#+ +#+    +#+ +#+    +#+ +#+             +#+#+#+#+#+"
echo "#+#   #+#  #+#     #+# #+#        #+#    #+# #+#    #+# #+#    #+# #+#                   #+#  "
echo "###    ### ###     ### ###        #########  ###    ###  ########  ###                   ###  "
echo ""

# Set marathon ports to 0:0 to have marathon assign and pass random port
if [ $PORT0 ]; then
    JMX_PORT=$PORT0;
fi

# Marathon passes "HOST" variable
if [ -z $HOST ]; then
    HOST=localhost;
fi

# Marathon passes memory limit
if [ $MARATHON_APP_RESOURCE_MEM ]; then
    HEAP_ARGS="-Xms${MARATHON_APP_RESOURCE_MEM%.*}m -Xmx${MARATHON_APP_RESOURCE_MEM%.*}m"
fi

if [ $JMX_PORT ]; then
    JMX_ARGS="-Dcom.sun.management.jmxremote \
    -Dcom.sun.management.jmxremote.port=${JMX_PORT} \
    -Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT} \
    -Dcom.sun.management.jmxremote.local.only=false \
    -Dcom.sun.management.jmxremote.authenticate=false \
    -Dcom.sun.management.jmxremote.ssl=false \
    -Djava.rmi.server.hostname=$HOST"
fi

KAFKA_PROPERTIES_FILE=${KAFKA_PROPERTIES_FILE:-kafka.properties}
if [ "$KAFKA_PROPERTIES" != "" ]; then
  echo Writing Kafka properties into $KAFKA_PROPERTIES_FILE
  echo "$KAFKA_PROPERTIES" | base64 --decode --ignore-garbage > $KAFKA_PROPERTIES_FILE
fi

KAFKA_TRUSTSTORE_FILE=${KAFKA_TRUSTSTORE_FILE:-kafka.truststore.jks}
if [ "$KAFKA_TRUSTSTORE" != "" ]; then
  echo Writing Kafka truststore into $KAFKA_TRUSTSTORE_FILE
  echo "$KAFKA_TRUSTSTORE" | base64 --decode --ignore-garbage > $KAFKA_TRUSTSTORE_FILE
fi

KAFKA_KEYSTORE_FILE=${KAFKA_KEYSTORE_FILE:-kafka.keystore.jks}
if [ "$KAFKA_KEYSTORE" != "" ]; then
  echo Writing Kafka keystore into $KAFKA_KEYSTORE_FILE
  echo "$KAFKA_KEYSTORE" | base64 --decode --ignore-garbage > $KAFKA_KEYSTORE_FILE
fi

ARGS="--add-opens=java.base/sun.nio.ch=ALL-UNNAMED -Xss256K \
     $JMX_ARGS \
     $HEAP_ARGS \
     $JVM_OPTS"

#CLIENT_ID, CLIENT_SECRET, KEYCLOAK_PROVIDER, KAFKA_BROKER     5891IBBfGZZZuhpwPAjJHU4WxAku2fSS

exec java $ARGS -Dloader.path=/extra-classes -jar /kafdrop/target*/kafdrop*jar ${CMD_ARGS}
