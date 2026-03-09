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

## Email Configuration (SMTP)

The application uses SMTP to send emails (password reset, etc.). Configure the following environment variables:

### Production Environment Variables

```bash
# SMTP Configuration
SMTP_ADDRESS=smtp.gmail.com          # SMTP server address
SMTP_PORT=587                        # SMTP port (587 for TLS, 465 for SSL)
SMTP_DOMAIN=yourdomain.com           # Your domain name
SMTP_USERNAME=your-email@domain.com  # SMTP username (usually your email)
SMTP_PASSWORD=your-app-password       # SMTP password or app-specific password
SMTP_AUTHENTICATION=plain             # Authentication method (plain, login, or cram_md5)
SMTP_ENABLE_STARTTLS_AUTO=true        # Enable STARTTLS (true/false)

# Email sender configuration
DEVISE_MAILER_SENDER=noreply@yourdomain.com  # Email address shown as sender
MAILER_FROM=noreply@yourdomain.com           # Default from address for all emails
HOST_URL=https://yourdomain.com              # Your application URL (for email links)
```

### Development Environment

In development, emails are opened in the browser using `letter_opener` by default. To use real SMTP in development, uncomment the SMTP configuration in `config/environments/development.rb`.

### Common SMTP Providers

**Gmail:**

- `SMTP_ADDRESS=smtp.gmail.com`
- `SMTP_PORT=587`
- `SMTP_AUTHENTICATION=plain`
- Use an [App Password](https://support.google.com/accounts/answer/185833) instead of your regular password

**SendGrid:**

- `SMTP_ADDRESS=smtp.sendgrid.net`
- `SMTP_PORT=587`
- `SMTP_USERNAME=apikey`
- `SMTP_PASSWORD=your-sendgrid-api-key`

**Mailgun:**

- `SMTP_ADDRESS=smtp.mailgun.org`
- `SMTP_PORT=587`
- Use your Mailgun SMTP credentials

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

# Import data from opensignauxfaibles

```
bin/rails osf:sync_all[24]                    # Sync all OSF data from OSF database to local Rails tables
bin/rails osf:sync_ap[24]                     # Sync OSF ap data from clean_ap materialized view to local Rails tables
bin/rails osf:sync_cotisation[24]             # Sync OSF cotisation data using PostgreSQL cursors ~ 1 heure
bin/rails osf:sync_debit[24]                  # Sync OSF debit data using PostgreSQL cursors ~ 30 mins
bin/rails osf:sync_delai[24]                  # Sync OSF delai data using PostgreSQL cursors ~ quelques secondes
bin/rails osf:sync_effectif[24]               # Sync OSF effectif data using PostgreSQL cursors ~ 28 mins
bin/rails osf:sync_effectif_ent[24]           # Sync OSF effectif_ent data using PostgreSQL cursors ~ 13 mins
bin/rails osf:sync_procol                     # Sync OSF procol data using PostgreSQL cursors ~ quelques secondes
bin/rails osf:sync_sirene                     # Sync establishments from SIRENE clean view ~ 2 hours
bin/rails osf:sync_sirene_ul                  # Sync companies from SIRENE_UL clean view ~ 1 hour
```

> For `osf_effectif` don't forget to update the `data_freshness` attribute of the corresponding line of the `import.rb` model. You can do this using the app admin panel. You can get the value by doing `select Max(oe.periode) from osf_effectifs oe` . This will be hopefully automaticaly done at import time one day.

# Data freshness and forward fill (URSSAF + Effectif/AP widgets)

This section documents how time-series data is prepared for the URSSAF and Effectif/AP widgets.

Definitions:

- **Forward fill**: If a period is missing but a previous value exists, the previous value is repeated until the fill boundary.
- **Data freshness**: A cutoff month stored in `imports.data_freshness`. Values after this month are hidden (set to `nil`).

## Data types overview


| Data type (widget)                                   | Forward filled | Data freshness used | Import name                                                  |
| ---------------------------------------------------- | -------------- | ------------------- | ------------------------------------------------------------ |
| Cotisations (URSSAF)                                 | Yes            | Yes                 | `osf_cotisation`                                             |
| Dette restante - part salariale (URSSAF)             | Yes            | Yes                 | `osf_debit`                                                  |
| Dette restante - part patronale (URSSAF)             | Yes            | Yes                 | `osf_debit`                                                  |
| Délai de paiement - montant de l'échéancier (URSSAF) | Yes            | Yes                 | `osf_delai`                                                  |
| Effectifs (Effectif/AP)                              | No             | Yes                 | `osf_effectif` (establishment), `osf_effectif_ent` (company) |
| AP - consommation (Effectif/AP)                      | No             | Yes                 | `osf_ap`                                                     |
| AP - autorisation (Effectif/AP)                      | No             | Yes                 | `osf_ap`                                                     |


## Examples (what is displayed)

Assume the chart shows periods **Jan → Apr 2025** and the `data_freshness` month is **Mar 2025**.

- **Cotisations (forward fill + freshness)**  
Raw values: `[Jan: 1000, Feb: nil, Mar: 1200, Apr: nil]`  
Displayed: `[Jan: 1000, Feb: 1000, Mar: 1200, Apr: nil]`
- **Dettes (forward fill + freshness)**  
Raw values: `[Jan: 500, Feb: 600, Mar: nil, Apr: nil]`  
Displayed: `[Jan: 500, Feb: 600, Mar: 600, Apr: nil]`
- **Délai de paiement (forward fill + freshness)**  
Raw values: `[Jan: 2000, Feb: nil, Mar: nil, Apr: 3000]`  
Displayed: `[Jan: 2000, Feb: 2000, Mar: 2000, Apr: nil]`
- **Effectifs (freshness only, no forward fill)**  
Raw values: `[Jan: 42, Feb: nil, Mar: 40, Apr: 41]`  
Displayed: `[Jan: 42, Feb: nil, Mar: 40, Apr: nil]`
- **AP consommation / autorisation (freshness only, no forward fill)**  
Raw values: `[Jan: 10, Feb: 12, Mar: nil, Apr: 9]`  
Displayed: `[Jan: 10, Feb: 12, Mar: nil, Apr: nil]`

# Import sjcf companies

Just import the data of an sjcf csv file with a `siren` column and a `libelle_list` column. The headers labels don't mater as long as you have one list of sirens and the name of the current list (e.g. "Septembre 2025").

```
siren;libelle_list
123456789;Septembre 2025
```

## Activating the "Liste retraitée" filter

Once the SJCF data has been imported and the list exists in the application, you can enable the "Liste retraitée" filter on the list search form. When enabled, users will see a checkbox that filters companies to only those from the list transmitted to the CDED before the CODEFI meeting.

From a Rails console:

```bash
docker compose exec web rails console
```

Then set `sjcf_filter_active` to `true` for the desired list (by label or id):

```ruby
# By list label (e.g. the libelle_list value from your CSV)
List.find_by(label: "Septembre 2025").update!(sjcf_filter_active: true)

# Or by list id
List.find(123).update!(sjcf_filter_active: true)
```

The filter is hidden by default (`sjcf_filter_active` is `false`) for all lists.

# Import d'une liste (avec Dbeaver)

Dbeaver ne supporte pas l'import de données directement en json :
Créer d'abord une nouvelle connexion de base de données en choisissant le driver JSON.
Sélectionner le dossier contenant la liste au format JSON.
Dbeaver va alors créer une nouvelle base de données où chaque table sera un fichier json du dossier choisi.
Sélectionner ensuite la table `company_score_entries` et importer les données de la table issue du json créée précédement (Attention au mapping, il faut l'ajuster colonne par colonne)

# Tests

L'application est testée grâce à un ensemble de tests d'intégration écrits à l'aide de la librairie `Minitest` fournie avec `Ruby on Rails`. Les tests sont lancés automatiquement lors de l'exécution du workflow GitHub `Publish rails container to ghcr.io`.

Pour lancer les tests en local :

**Une fois** (créer la base de test et exécuter les migrations, y compris celle qui crée la fonction SQL `procol_at_date`) :

```bash
docker compose run test_web rails db:create db:migrate RAILS_ENV=test
```

**Ensuite, à chaque fois :**

```bash
docker compose run test_web rails test
```

### Réinitialiser la base de test (drop impossible : "database is being accessed by other users")

Si `db:drop` échoue parce que la base de test est encore utilisée (connexions ouvertes), utilisez la tâche qui coupe les connexions puis supprime toutes les bases de test (y compris les clones parallèles) :

```bash
docker compose run test_web rails db:test:drop_force RAILS_ENV=test
```

Puis recréez et migrez :

```bash
docker compose run test_web rails db:create db:migrate RAILS_ENV=test
```

En une seule commande :

```bash
docker compose run test_web rails db:test:drop_force db:create db:migrate RAILS_ENV=test
```

La couverture des tests est calculée par la gem `simplecov` et sera affichée à la fin des tests. Un fichier récapitulatif est disponible dans le dossier `coverage`.