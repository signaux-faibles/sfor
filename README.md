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

# OSF Data Synchronization

The application can synchronize data from the database where `opensignauxfaibles` writes data. This includes `stg_apconso` and `stg_apdemande` tables.

## Environment Configuration

Before running synchronization commands, you need to configure the `opensignauxfaibles` database connection by setting these environment variables:

```bash
OSF_DATABASE_HOST=osf_database_host
OSF_DATABASE_PORT=5432
OSF_DATABASE_NAME=osf_database_name
OSF_DATABASE_USERNAME=osf_database_user
OSF_DATABASE_PASSWORD=osf_database_password
OSF_DATABASE_POOL=5
```

## Synchronization Commands

### Sync Individual Data Types

To synchronize specific data types independently:

```bash
# Sync apdemande data only
docker compose exec web rails osf:sync_apdemande

# Sync apconso data only
docker compose exec web rails osf:sync_apconso
```

### Sync All OSF Data

To synchronize all OSF data types at once:

```bash
docker compose exec web rails osf:sync_all
```

## What Gets Synchronized

- **OSF Apdemande**: Data from `stg_apdemande` table → `osf_apdemandes` table
- **OSF Apconso**: Data from `stg_apconso` table → `osf_apconsos` table

## Features

- **Smart Updates**: Creates new records or updates existing ones based on primary keys
- **Establishment Validation**: Only syncs data for establishments that exist in the Rails application
- **Comprehensive Logging**: Each sync type logs to separate files in the `log/` directory
- **Error Handling**: Continues processing even if individual records fail
- **Statistics**: Reports how many records were created, updated, or failed

## Log Files

Synchronization logs are saved to:
- `log/osf_apdemande_sync.log` - Apdemande sync logs
- `log/osf_apconso_sync.log` - Apconso sync logs

# Asset Pipeline

This Rails application uses a hybrid approach for managing assets, combining **Sprockets** for CSS processing and **Import Maps** for JavaScript modules.

## CSS Processing with Dart Sass

The application uses **Dart Sass** (`dartsass-rails` gem) for SCSS compilation, which is the Rails team's recommended approach for Sass support.

### How Dart Sass and Sprockets Work Together

**Dart Sass** and **Sprockets** work together in a two-step process:

1. **Dart Sass** compiles SCSS to CSS - converts `.scss` files into `.css`
2. **Sprockets** manages the asset pipeline - concatenates, fingerprints, and serves the final CSS

```
SCSS files → Dart Sass → CSS files → Sprockets → Final served assets
```

- **Dart Sass** handles SCSS compilation (variables, mixins, `@use`, etc.)
- **Sprockets** handles asset pipeline management (concatenation, cache busting, serving)

### SCSS Structure
- **Main stylesheet**: `app/assets/stylesheets/application.scss`
- **SCSS files**: All stylesheets are converted to `.scss` and use the modern `@use` syntax
- **Dart Sass compilation**: Handles SCSS compilation to CSS during asset precompilation

### SCSS Usage
```scss
// app/assets/stylesheets/application.scss
@use "dsfr";
@use "custom";
@use "admin";
@use "utility";
@use "tom-select.min";
```

## JavaScript with Import Maps

The application uses **Import Maps** (`importmap-rails` gem) for JavaScript module management without a build step.

### Import Map Configuration
```ruby
# config/importmap.rb
pin "application"
pin "dsfr", to: "dsfr.module.min.js"
pin "tom-select", to: "tom-select.js"
# ... other pins
```

### JavaScript Structure
- **Main entry point**: `app/javascript/application.js`
- **Stimulus controllers**: `app/javascript/controllers/`
- **External libraries**: `vendor/javascript/` (downloaded via `bin/importmap pin`)

### Adding External JavaScript Libraries
```bash
# Pin a library from CDN
bin/importmap pin library-name

# Pin a specific version
bin/importmap pin library-name@1.2.3

# Pin from a local file
bin/importmap pin library-name --download
```

## Development vs Production Asset Handling

### Development Environment
In development, Rails compiles assets **on-demand** (lazy compilation):
- **CSS**: SCSS files are compiled to CSS when first requested
- **JavaScript**: Import Maps serve ES modules directly from the browser
- **No precompilation**: Assets are generated as needed
- **Faster startup**: No need to compile all assets at startup
- **Real-time changes**: SCSS changes are reflected immediately

```ruby
# config/environments/development.rb
config.public_file_server.enabled = true
config.assets.compile = true
config.assets.check_precompiled_asset = false
```

### Production Environment
In production, assets are **precompiled** for performance:
- **Precompilation**: All assets are compiled and optimized before deployment
- **Concatenation**: Multiple CSS/JS files are combined into single files
- **Minification**: CSS/JS is compressed to reduce file size
- **Fingerprinting**: Assets get unique names for cache busting (e.g., `application-abc123.css`)
- **CDN ready**: Precompiled assets can be served from a CDN

```ruby
# config/environments/production.rb
config.assets.compile = false
config.assets.source_maps = true
config.assets.debug = false
```

### Docker Development Considerations
This project runs in Docker, which can sometimes behave like production regarding asset precompilation. The development configuration includes additional settings to ensure proper asset serving in the containerized environment.

## Asset Pipeline Configuration

### Asset Manifest
```javascript
// app/assets/config/manifest.js
//= link_tree ../images
//= link_tree ../../javascript .js
//= link_tree ../../../vendor/javascript .js
//= link_tree ../builds
//= link application.css
```

## External Libraries Integration

### Chart.js Library
The Chart.js library is integrated as a web component:
```javascript
// app/javascript/application.js
import "chart.js"
```

#### Why did we choose Chart.js instead of DSFR-chart ?
Signaux Faibles product displays a large amount of data in the form of charts.
Charts are complex: multiple datasets, multiple formats (lines, bars, areas, etc.) on the same chart.

After discussions with the DSFR team, we found that the DSFR-chart library does not meet the needs of Signaux Faibles.

> *Dans le cas d’un besoin non couvert, vous pouvez vous appuyer directement sur la bibliothèque Chart.js qui est la base de développement de nos DSFR Charts.*
> — DSFR team

That's why we decided to use Chart.js.

## Troubleshooting

### Asset Not Precompiled Errors
If you encounter "Asset not declared to be precompiled" errors in Docker:
1. Ensure `config.assets.compile = true` in development
2. Check that all required assets are in `manifest.js`
3. Verify importmap pins are correctly configured

### SCSS Compilation Issues
- Use `@use` instead of `@import` for modern Sass
- Ensure all SCSS files are properly referenced in `application.scss`
- Check that `dartsass-rails` gem is properly installed

### Legacy Browser Support Issue
**⚠️ Identified Issue**: The current setup only provides fallback support for DSFR (`dsfr.nomodule.min.js`) but not for other JavaScript modules loaded via Import Maps. This means:

- **Modern browsers**: All JavaScript works (Import Maps + DSFR fallback)
- **Legacy browsers**: Only DSFR works, all other JS (application.js, Stimulus controllers, etc.) fails to load

**Impact**: Users with older browsers will have a broken JavaScript experience.

**Recommended Solutions**:
1. **Accept modern-only**: Remove DSFR fallback and require modern browser support
2. **Full fallback strategy**: Create non-module versions of all JS files and add them to the manifest
3. **Hybrid approach**: Keep DSFR fallback for critical UI, accept limited JS functionality in old browsers

**Action Required**: This issue should be addressed based on the target browser support requirements.

# Import Wekan data

You can import data from signaux faibles wekan into the rails app.
To do so, you must open a terminal in the rails web container and run the following rake tasks all located in the `import_from_wekan` rake namespace for clarity :

## Users
```shell
# Import the users from wekan
rake import_from_wekan:users
```

## Companies


# Tests
L'application est testée grâce à un ensemble de tests d'intégration écrits à l'aide de la librairie `Minitest` fournie avec `Ruby on Rails`.
Les tests sont lancés automatiquement lors de l'exécution du workflow GitHub `Publish rails container to ghcr.io`
Pour lancer les tests en local, utiliser la commande :

```bash
docker compose run test_web rails test
```

La couverture des tests est calculée par la gem `simplecov` et sera affichée à la fin des tests. Un fichier récapitulatif est disponible dans le dossier `coverage`



