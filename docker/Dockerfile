FROM eclipse-temurin:17.0.13_11-jdk

RUN apt-get update -y && apt-get upgrade -y

RUN apt-get install maven -y

ADD start.sh /

ADD kafdrop /kafdrop

ADD nosec /nosec

RUN chmod +x /start.sh

EXPOSE 9000

ENTRYPOINT ["/start.sh"]
