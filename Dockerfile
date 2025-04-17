FROM wordpress:php8.4-apache

# change the listening port to a nonpriveleged port
RUN sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf
RUN sed -i 's/:80/:8080/g' /etc/apache2/sites-enabled/000-default.conf

COPY apache2.conf /etc/apache2/apache2.conf

# Uncomment to debug connection to mysql pod
# RUN apt-get update -y; \
#     apt-get install default-mysql-client -y

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]