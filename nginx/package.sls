{% set use_upstart = pillar.get('nginx', {}).get('use_upstart', true) %}
{% if use_upstart %}
nginx-old-init:
  cmd.run:
    - name: mv /etc/init.d/nginx /usr/share/nginx/init.d && dpkg-divert --divert /usr/share/nginx/init.d --add /etc/init.d/nginx
    - watch:
      - pkg: nginx
    # Only run this once; don't keep trying to rename the file.
    - unless: test -e /usr/share/nginx/init.d

nginx-old-init-disable:
  cmd:
    - wait
    - name: update-rc.d -f nginx remove
    - watch:
      - cmd: nginx-old-init
{% endif %}

nginx:
  pkg.installed:
    - name: nginx
{% if use_upstart %}
  file:
    - managed
    - name: /etc/init/nginx.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://nginx/templates/upstart.jinja
    - require:
      - pkg: nginx
    - watch:
      - cmd: nginx-old-init
{% endif %}
  service:
    - running
    - enable: True
    - restart: True
    - watch:
{% if use_upstart %}
      - file: nginx
{% endif %}
      - file: /etc/nginx/nginx.conf
      - file: /etc/nginx/conf.d/*
      - file: /etc/nginx/sites-enabled/*
      - pkg: nginx

# Create 'service' symlink for tab completion.
{% if use_upstart %}
/etc/init.d/nginx:
  file.symlink:
    - target: /lib/init/upstart-job
    - require:
      - file: nginx
{% endif %}
