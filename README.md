# Signaux-Faibles On Rails

# Local Development

## Setup

The project has been dockerized. This means you need to have Docker up and running on your machine to start the project.

> [!NOTE]  
> Please note that the dockerfile used by docker compose is `Dockerfile.dev`
> `Dockerfile` should be used for production

First create start the `db` service by running

```
docker-compose up -d db
```

then

```
docker-compose run web rails db:create db:migrate
```
This will create the database and run the migrations. For your information, the database is a PostgreSQL database and we use the default configuration for the database connection (host: db, username: postgres, password: password).

Finally start the application by running

```
docker-compose up --build
```

If the application still takes a long time to start, or if it fails, check the container logs for any error messages:

```
docker-compose logs web
```

If you want to connect a dbms to the local dockerized databases, then use the following connection details :

```
Host: localhost
Port: 5432
Database: (As specified in Rails database.yml, e.g., signaux_faibles_v2_development)
Username: postgres
Password: password
```

## Rubymine issues

### Sometimes, RubyMine does not immediately synchronize with changes in Docker containers:

- Force a gem update in RubyMine by using the gem reloading function in Settings > Ruby SDK and Gems and then look for the "Synchronize" icon in the right column.
- This may require closing and reopening RubyMine or refreshing the project for the changes to take effect.

### Rails web console cannot be accessed from the browser

In `config/environments/development.rb` add :

```
config.web_console.permissions = '192.168.65.1'
```
This is because rails sees the ip trying to access the rails web console as some Docker internal IP (might vary depending on your OS)
and rails does not authorize ips other than localhost to access the rails web console for security reasons.


# DSFR (js + css)
The design and layout uses the [dsfr](https://www.systeme-de-design.gouv.fr/). 
Since the dsfr is not available through a CDN and we want to use importmaps (which means no usage of node and npm) then we directly use the dsfr static files.

On the javascript side we use importmap to import the dsfr as a javascript module file :

The module file is here :
`app/javascript/dsfr.module.min.js`

```ruby
# config/importmap.rb
pin "dsfr", to: "dsfr.module.min.js"
```
and then

```ruby
# app/javascript/application.js
import "dsfr"
```

But for browsers not supporting ES6 modules we also serve the file using sprockets :

The non-module file is here :
`vendor/javascript/dsfr.nomodule.min.js`

and

```html
<!-- app/views/layouts/application.html.erb -->
<script src="<%= asset_path 'dsfr.nomodule.min.js' %>" nomodule></script>
```

On the CSS side, the minified dsfr css files are in the `app/assets` directory and referenced in `app/assets/config/manifest.js`.
This means rails assets pipeline `Sprockets` will handle concatenation, compression, and cache-busting of the CSS files, which will improve the application's performance and maintainability.