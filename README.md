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
Says we have two tables A and A2A as below:
**Table A:**
| ID    | Name    | 
|-------|---------|
| A01   | name A01|
| A02   | name A02|
| A03   | name A03|
| A04   | name A04|

**Table A2A:**
| childAId    | parentAId   | description           | Active  |
|-------------|-------------|-----------------------|---------|
| A02         | A01         | A01 is parent of A02  | yes     |
| A03         | A02         | A02 is parent of A03  | no      |
| A04         | A01         | A01 is parent of A04  | yes     |

We can join two tables as below:
**Option 1:**
...
local vmA = eifo.VModelBuilder.new("A")
local vmA2A = vmA:rightJoin("A2A", "parentAId", "children")
vmA2A:leftJoin("childAId", "parent")
...
**Option 2:**
...
local vmA = eifo.VModelBuilder.new("A")
local vmA2A = vmA:rightJoin("A2A", "childAId", "parent")
vmA2A:leftJoin("parentAId", "children")
...
*Notice the dot '.' and colon ':'*
rightJoin requires 3 params: the dest table name, the dest FK column name, and an alias for the join column in source table
leftJoin requires two params: the FK column name, and an alias to name the list in FK dest table.
With both options above, after loading, each record of A will have two addition properties: 
*parent* and *children*, which's names are defined by the *alias*, the last parameter in **rightJoin**; and each record of B will have two addtion properties: *parentA* and *childA* (those names are from column names *parentAId* and *childAId*, removed the trailing *'Id'*). The only differences is the order of loaded records. 

To get loaded record, use notation: 
...
vmA[0] // a record of A
vmA.keys["A01"] // a record of A
vmA[1].parent //a record of A
vmA.keys["A01"].parent //same as above
vmA[1].children // a list of records of A
vmB[0] // a record of A2A
vmB[0].parentA // a record of A
vmB[0].childA // a record of A
...

#### Query:
***loadByKey***
***loadByIds***
***loadByFk***
...
local vmA = eifo.VModelBuilder.new("A")
local vmA2A = vmA:rightJoin("A2A", "parentAId", "children")
vmA2A:leftJoin("childAId", "parent")
local vModel = vmA:newVModel()
local conn = eifo.db.conn.redis()
conn:connect()
local vRecord, err = vModel:loadByKey("A01", conn)
conn:disconnect()
...
Records loaded in vmA's model:
| ID    | Name    | children              |parent       |
|-------|---------|-----------------------|-------------|
| A01   | name A01| A02(list), A04(list)  |             |
| A02   | name A02| A03(list)             | A01(object) |
| A03   | name A03|                       | A02(object) |
| A04   | name A04|                       | A01(object) |
Records loaded in vmB's model:
| childAId | parentAId | description           | Active | childA  | parentA |
| (string) | (string)  | (string)              |(string)| (object)| (object)|
|----------|-----------|-----------------------|--------|---------|---------|
| A02      | A01       | A01 is parent of A02  | yes    | A02     | A01     |
| A03      | A02       | A02 is parent of A03  | no     | A03     | A02     |
| A04      | A01       | A01 is parent of A04  | yes    | A04     | A01     |

The first row in vmA is the record we are looking for. The next ones is loaded because of the join statements: A01 load A02 and A04, A02 load A03
#### Limit the deep for query:
***maxLevel setting***
***idOnly setting***
#### Select columns:
#### Joining on conditions
#### Filtering results
***Add filters***
***vModel:select(condition)***
#### Event model
#### Search affected records from an entity change
