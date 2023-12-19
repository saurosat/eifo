## Technology stack:
### Webserver: 
Nginx + openresty (openresty for getting notifications and for searching requests only. All other requests are served with pre-generated static contents)
- https://openresty-reference.readthedocs.io/en/latest/Lua_Nginx_API/
- https://github.com/openresty/openresty
- https://openresty.org/en/
### Serverside template engine: 
https://github.com/bungle/lua-resty-template
### Clientside template engine (to render state and UI changes triggered from BO): 
Using native template engine of knockout.js
- https://knockoutjs.com/documentation/template-binding.html
- https://www.tutorialspoint.com/knockoutjs/knockoutjs_templating.htm
### Client state management: 
jQuery, KnockoutJS 
- https://knockoutjs.com/documentation/introduction.html
- Client UI: TailwindCSS (recommended because there are lots of free UI templates)
- FO storage: Redis Stack (Redis packed with modules for Indexing, Searching and JSON processing)
  - https://redis.io/docs/getting-started/
  - https://redis.io/commands/# eifo


## Quick Start:
+ Install Redis Stack Server
+ Install OpenResty and update $PATH variable to include nginx execution file (nginx is packed inside OpenResty)
+ Open [EIFO ProjectHome]/conf/nginx.conf, check all configs
+ Start Redis Stack Server: redis-stack-server (you can start it as daemon)
+ Start Nginx: nginx -p [EIFO ProjectHome] -c [EIFO ProjectHome]/conf/nginx.conf (Using relative path is ok)

## Server-side rendering
EIFO generates static htmls. 
When the requested html is not exist, the request will be re-direct to 
 the 'router' (eifo.view), then the router will find a appropriated 'view' based 
 on the request parameter. The view in turn will generate the requested html file. If there is not any view matches the request params, a 401 http code will be returned.
 To generate html, the view have to collect data from Redis and fill in the pre-defined resty templates. There are 3 types of objects are involved in this process: models, views and view-models. It's similar to MVVM design pattern, in which the model-view is the bridge between models and views. 
 ### ViewModel is responsible for:
  1. Load needed models for a view
  2. Notify view about entity's changes, so that view can re-generate static html files
When there is any changes made on related entities, related entities will notify the view models, the view models will query all affected views and notify all them.
### ViewModel usages
The ViewModel is similar to a SQL VIEW. After init, you can left join, right join other 'table's with alias and 'ON' condition, and get access to the column and joined table's records. Please refer to init.lua as usage samples