FROM nginxproxy/docker-gen

# Change the uid of nginx to the same as mampf-container
#RUN sed -i 's/^nginx.\+/nginx\:x\:501\:501\:nginx\:\/var\/cache\/nginx\:\/sbin\/nologin/' /etc/passwd
COPY docker/nginx.tmpl /etc/docker-gen/templates/nginx.tmpl