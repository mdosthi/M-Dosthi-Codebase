FROM tomcat:9.0-jdk11-temurin AS build

WORKDIR /workspace
COPY apps/web/ /workspace/apps/web/
COPY services/legacy/ /workspace/services/legacy/
RUN mkdir -p /workspace/tools/tomcat9/lib \
    && ln -s /usr/local/tomcat/lib/servlet-api.jar /workspace/tools/tomcat9/lib/servlet-api.jar

WORKDIR /workspace/services/legacy/server-src
RUN ./makeJar.sh

WORKDIR /workspace/services/legacy/servlet-src/WEB-INF/classes/src
RUN SERVLET_API_JAR=/usr/local/tomcat/lib/servlet-api.jar ./makeJar.sh

FROM tomcat:9.0-jdk11-temurin

WORKDIR /opt/mdosthi
COPY --from=build --chown=www-data:www-data /workspace/apps/web/ /usr/local/tomcat/webapps/M-Dosthi/
COPY --from=build --chown=www-data:www-data /workspace/services/legacy/runtime/lib/ /opt/mdosthi/services/legacy/runtime/lib/
COPY --from=build --chown=www-data:www-data /workspace/services/legacy/runtime/iMediXBusinessLogic.jar /opt/mdosthi/services/legacy/runtime/iMediXBusinessLogic.jar
COPY --chown=www-data:www-data apps/web/config.info.template /opt/mdosthi/apps/web/config.info.template
COPY --chown=www-data:www-data docker/legacy-entrypoint.sh /usr/local/bin/legacy-entrypoint.sh
RUN chmod +x /usr/local/bin/legacy-entrypoint.sh \
    && mkdir -p /usr/local/tomcat/services/legacy/runtime /var/lib/mdosthi/temp /var/lib/mdosthi/SystemLog /var/lib/mdosthi/GenSqlLog /usr/local/tomcat/webapps/M-Dosthi/temp /usr/local/tomcat/logs /usr/local/tomcat/temp /usr/local/tomcat/work \
    && chown -R www-data:www-data /usr/local/tomcat/services /var/lib/mdosthi /opt/mdosthi/services/legacy /usr/local/tomcat/webapps/M-Dosthi /usr/local/tomcat/logs /usr/local/tomcat/temp /usr/local/tomcat/work

USER www-data
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/legacy-entrypoint.sh"]
