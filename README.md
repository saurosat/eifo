Technology stack:
+ Webserver: Nginx + openresty (openresty for getting notifications and for searching requests only. All other requests are served with pre-generated static contents)
            - https://github.com/openresty/openresty
            - https://openresty.org/en/
            - API: https://openresty-reference.readthedocs.io/en/latest/Lua_Nginx_API/
+ Serverside template engine: https://github.com/bungle/lua-resty-template
+ Clientside template engine (to render state and UI changes triggered from BO): using native template engine of knockout.js
            - https://knockoutjs.com/documentation/template-binding.html
            - https://www.tutorialspoint.com/knockoutjs/knockoutjs_templating.htm
+ Client state management: jQuery, KnockoutJS 
            - https://knockoutjs.com/documentation/introduction.html
+ Client UI: TailwindCSS (recommended because there are lots of free UI templates)
+ FO storage: Redis Stack (Redis packed with modules for Indexing, Searching and JSON processing)
            - https://redis.io/docs/getting-started/
            - https://redis.io/commands/# eifo


Quick Start:
+ Install Redis Stack Server
+ Install OpenResty and update $PATH variable to include nginx execution file (nginx is packed inside OpenResty)
+ Open [EIFO ProjectHome]/conf/nginx.conf, check all configs
+ Start Redis Stack Server: redis-stack-server (you can start it as daemon)
+ Start Nginx: nginx -p [EIFO ProjectHome] -c [EIFO ProjectHome]/conf/nginx.conf (Using relative path is ok)
