FROM maven:3.9-eclipse-temurin-25 AS build

WORKDIR /workspace/services/api
COPY services/api/ ./
RUN mvn -B -DskipTests package

FROM eclipse-temurin:25-jre

WORKDIR /app
COPY --from=build /workspace/services/api/target/*.jar /app/app.jar
EXPOSE 9090
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
