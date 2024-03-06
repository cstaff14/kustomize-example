FROM wordpress:6.2.1-apache

RUN sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf
RUN sed -i 's/:80/:8080/g' /etc/apache2/sites-enabled/000-default.conf

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]