# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Unified Docker Compose full-stack deployment** (`docker-compose.yml`) with all services: PostgreSQL, Elasticsearch, OpenMetadata Server, Airflow Ingestion, and PortalJS Frontend
- **Sample data database** (`Dockerfile_postgres_data` + `postgres_data.sql`) with demo tables (actors, films, customers) auto-loaded on startup
- **Automated setup script** (`scripts/01_setup-sample-data.sh`):
  - Registers sample PostgreSQL as a Database Service in OpenMetadata
  - Creates and triggers a metadata ingestion pipeline via Airflow
  - Creates a sample Domain ("Sample Data")
  - Creates Data Products ("Film Database", "Customer Records") linked to domain and ingested tables
  - Creates a Business Glossary with a sample "Customer" term
- **Bot token initialization script** (`scripts/00_init-bot-token.sh`) — creates a bot user and updates `.env` with the JWT token
- OpenAPI spec reference for OpenMetadata v1.9.8 (`docs/openapi-spec.v1.9.8.json`)
- Bilingual README (`README.md` + `README.es.md`) with Docker deployment instructions
- Health checks and dependency ordering between Docker services
- Comprehensive ROADMAP with completed work and phased future plans

### Fixed
- **Search index compatibility with OpenMetadata 1.9**: changed `index=dataAsset` → `index=data_product_search_index` in `searchDataProducts()`, `getFacets()`, and `getDomainDataProducts()` per OMD 1.9 Elasticsearch index naming
- **Data Product creation API**: changed `domain` (singular) → `domains` (plural array) in setup scripts, matching OMD 1.9 schema
- **Base64 password encoding** for authentication API calls (required by OMD 1.9+)
- **Frontend crash on `/glossaries`**: added defensive error handling in `listGlossaries()` to prevent `TypeError: Cannot read properties of undefined (reading 'map')`
- **Frontend crash on `/search`**: added try-catch and null-safe access in `searchDataProducts()`, `getFacets()`, and `dataProductToDataset()`
- **Frontend crash on domain pages**: added defensive handling in `getAllDomains()` for invalid API responses
- **Empty `DMS_TOKEN` in Docker container**: ensured the token is passed as runtime environment variable via `docker-compose.yml`
- Removed redundant `entityType.keyword:dataproduct` filter (implicit when querying `data_product_search_index`)

### Changed
- **Consolidated `.env.docker` → `.env`**: single environment file for both local dev and Docker, read automatically by Docker Compose
- Removed `.env.docker.example` in favor of unified `.env.example`
- Scripts renamed with numeric prefixes for execution order (`00_init-bot-token.sh`, `01_setup-sample-data.sh`)
- Updated all references across `docker-compose.yml`, READMEs, scripts, and `.gitignore`

### Removed
- `.env.docker` / `.env.docker.example` separation (consolidated into `.env` / `.env.example`)

## [1.0.0] - 2025-02-01

### Added
- Initial release as PortalJS OpenMetadata Starter
- OpenMetadata integration for Data Products and Domains
- Full-text search powered by OpenMetadata's Elasticsearch
- Faceted filtering by domains, tags, and asset types
- Table asset preview with column metadata
- Responsive design with Tailwind CSS
- TypeScript support throughout the codebase
- Theme system for customization
- Docker Compose setup for local development with OpenMetadata

### Attribution
- Based on [PortalJS Frontend Starter](https://github.com/datopian/portaljs-frontend-starter) by [Datopian](https://datopian.com/)
- Original template licensed under MIT License

## [0.1.0] - 2024-xx-xx (Pre-release)

### Added
- Initial fork from PortalJS Frontend Starter template
- Basic OpenMetadata API integration
- Data Product to Dataset mapping
- Domain to Organization mapping
- Table to Resource mapping

---

## Legend

- **Added** - New features
- **Changed** - Changes in existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Vulnerability fixes
