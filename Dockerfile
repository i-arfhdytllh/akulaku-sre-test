# ===== STAGE 1: Build Stage =====
FROM maven:3.9.5-eclipse-temurin-17 AS builder

WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
RUN mvn clean package -DskipTests -B

# ===== STAGE 2: Runtime Stage =====
FROM eclipse-temurin:17-jre

LABEL maintainer="Arif Hidayatullah"
LABEL version="1.0.0"
LABEL description="Hello World Spring Boot - Akulaku SRE Test"

# Debian syntax (bukan Alpine)
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

WORKDIR /app

COPY --from=builder /app/target/hello-world.jar app.jar

RUN chown appuser:appgroup app.jar

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-XX:+UseG1GC", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar"]
