# Roadmap

> Last updated: 2026-02-11

---

## ✅ Completed

### Docker Compose Full-Stack Deployment
- [x] Unified `docker-compose.yml` with all services (PostgreSQL, Elasticsearch, OpenMetadata Server, Airflow Ingestion, PortalJS Frontend)
- [x] Sample PostgreSQL database (`Dockerfile.postgres.data` + `postgres_data.sql`) with demo tables (actors, films, customers)
- [x] Production-ready multi-stage `Dockerfile` for PortalJS (standalone Next.js output)
- [x] Consolidated `.env` / `.env.example` (removed redundant `.env.docker` split)
- [x] Health checks and dependency ordering between services

### Automated Setup Scripts
- [x] `scripts/01_setup-sample-data.sh` — One-command automation:
  - Registers sample PostgreSQL as a Database Service in OpenMetadata
  - Creates and triggers a metadata ingestion pipeline via Airflow
  - Creates a sample Domain ("Sample Data")
  - Creates Data Products ("Film Database", "Customer Records") linked to domain and tables
  - Creates a Business Glossary with sample terms
- [x] `scripts/00_init-bot-token.sh` — Bot token creation and `.env` update

### OpenMetadata API Compatibility (v1.9.x)
- [x] Fixed search index names: `dataAsset` → `data_product_search_index` (per OMD 1.9 Elasticsearch index naming)
- [x] Fixed Data Product creation: `domain` (singular) → `domains` (plural array)
- [x] Fixed Base64 password encoding for authentication (OMD 1.9+ requirement)
- [x] Removed obsolete `entityType.keyword:dataproduct` filter (redundant when querying dedicated index)

### Frontend Robustness
- [x] Defensive error handling in `searchDataProducts()` — graceful fallback on API errors
- [x] Defensive error handling in `getFacets()` — handles missing aggregation buckets
- [x] Defensive error handling in `dataProductToDataset()` — handles missing domains/assets/tags
- [x] Defensive error handling in `listGlossaries()` — prevents crash on empty/error responses
- [x] Defensive error handling in `getAllDomains()` — handles invalid API responses
- [x] Fixed `getDomainDataProducts()` — correct search index for domain-filtered queries

### Documentation
- [x] Bilingual README (`README.md` + `README.es.md`) with Docker deployment instructions
- [x] OpenAPI spec reference (`docs/openapi-spec.v1.9.8.json`)
- [x] `LICENSE`, `CHANGELOG.md`

---

## Phase 1: Metadata Experience (Next Priority)

### Enhanced Table/Asset View
- [ ] Display column-level metadata (type, description, constraints) in table preview
- [ ] Show data profiling stats (row count, null %, unique %, value distribution) when available
- [ ] Render column tags and glossary term associations inline
- [ ] Add "Schema" tab with sortable/searchable column table

### Rich Data Product Pages
- [ ] Show Data Product owners and experts with profile links
- [ ] Display asset list with direct links to table detail pages
- [ ] Render Data Product tags, tier, and certification badges
- [ ] Show domain breadcrumb navigation

### Glossary Integration
- [ ] Clickable glossary terms that navigate to term detail pages
- [ ] Show related assets for each glossary term
- [ ] Hierarchical glossary term tree with expand/collapse
- [ ] Glossary term search and filtering

### Search Improvements
- [ ] Autocomplete / typeahead search suggestions
- [ ] Search result highlighting (matched terms in bold)
- [ ] Filter by data freshness (last updated)
- [ ] Filter by data quality score (when available)
- [ ] Saved searches / bookmarks

---

## Phase 2: Data Intelligence

### Data Lineage
- [ ] Visual lineage graph (upstream/downstream) for tables
- [ ] Cross-service lineage tracking
- [ ] Impact analysis: "What breaks if this table changes?"

### Data Quality
- [ ] Display test suite results per table
- [ ] Quality score badges on search results and Data Product cards
- [ ] Quality trend charts (pass/fail over time)
- [ ] Alert indicators for failing tests

### Schema Evolution
- [ ] Schema diff view between versions
- [ ] Timeline of schema changes with annotations
- [ ] Breaking change detection and alerts

---

## Phase 3: Enterprise & Operations

### Authentication & Authorization
- [ ] SSO integration examples (OIDC, SAML)
- [ ] Role-based access control (RBAC) in the portal
- [ ] Team-based data product ownership views

### Customization & Branding
- [ ] Dark mode theme toggle
- [ ] Custom logo, colors, fonts via configuration
- [ ] White-label support for multi-tenant deployments
- [ ] Custom CSS injection point

### Performance & Scalability
- [ ] API response caching (Redis or in-memory)
- [ ] API rate limiting
- [ ] Static generation (ISR) for stable pages
- [ ] CDN-ready asset pipeline

### Internationalization
- [ ] Multi-language support (i18n) — Spanish, English, French, German
- [ ] RTL layout support
- [ ] Locale-aware date/number formatting

---

## Phase 4: Ecosystem & Community

### Developer Experience
- [ ] NPM package distribution (`@portaljs/openmetadata-starter`)
- [ ] Storybook component documentation
- [ ] Plugin system for extensibility
- [ ] CLI tool for scaffolding and configuration

### Testing & Quality
- [ ] E2E testing suite (Playwright/Cypress)
- [ ] Integration tests against OMD API
- [ ] Visual regression testing
- [ ] Performance monitoring (Core Web Vitals)

### Deployment
- [ ] Terraform module for cloud deployment (AWS, GCP, Azure)
- [ ] Kubernetes Helm chart
- [ ] GitHub Actions CI/CD pipeline template
- [ ] One-click deploy buttons (Railway, Render, Vercel)

### Analytics
- [ ] Portal usage analytics dashboard
- [ ] Most viewed/searched datasets tracking
- [ ] User engagement metrics
- [ ] Data catalog coverage reports