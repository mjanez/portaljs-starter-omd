<p align="right">
  🌐 <a href="README.es.md">Leer en Español</a>
</p>

<h1 align="center">PortalJS OpenMetadata Starter</h1>

<p align="center">
  <em>A modern, production-ready frontend template for OpenMetadata data catalogs</em>
</p>

<p align="center">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
  <a href="https://nextjs.org/"><img src="https://img.shields.io/badge/Next.js-14+-black?logo=next.js&logoColor=white" alt="Next.js 14+"></a>
  <a href="https://www.typescriptlang.org/"><img src="https://img.shields.io/badge/TypeScript-5.0+-blue?logo=typescript&logoColor=white" alt="TypeScript"></a>
  <a href="https://tailwindcss.com/"><img src="https://img.shields.io/badge/Tailwind_CSS-3.0+-38B2AC?logo=tailwind-css&logoColor=white" alt="Tailwind CSS"></a>
  <a href="https://www.docker.com/"><img src="https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white" alt="Docker"></a>
</p>

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-docker-deployment">Docker</a> •
  <a href="#-customization">Customization</a> •
  <a href="#-roadmap">Roadmap</a> •
  <a href="#-contributing">Contributing</a>
</p>

---

## Overview

**PortalJS OpenMetadata Starter** is a decoupled frontend template designed to create beautiful, high-performance public data catalogs powered by [OpenMetadata](https://open-metadata.org/). It provides a modern React-based interface that connects seamlessly to your OpenMetadata instance, allowing you to showcase your data products to external users.

### What makes this project different?

This project is built upon the excellent [PortalJS](https://github.com/datopian/portaljs) framework by [Datopian](https://datopian.com/), extending it specifically for OpenMetadata integration. While PortalJS focuses on CKAN backends, this template:

- **Native OpenMetadata Support**: Direct integration with OMD APIs
- **Data Product-Centric**: Built around OMD Data Products and Domains
- **Enhanced Features**: Extended functionality beyond the base template
- **Docker-First**: Production-ready containerization
- **NPM Package Ready**: Prepared for distribution as a standalone package

## Features

| Feature | Description |
|---------|-------------|
| **Modern UI** | Clean, responsive design with Tailwind CSS |
| **High Performance** | Built on Next.js with SSR/SSG for optimal loading |
| **OpenMetadata Integration** | Native support for OMD Data Products, Domains, and Tables |
| **TypeScript** | Full type safety for better developer experience |
| **Theming System** | Easy customization with component-based themes |
| **Mobile-First** | Responsive design that works on all devices |
| **Docker Ready** | Production containerization out of the box |
| **Full-Text Search** | Powered by OpenMetadata's search capabilities |
| **Data Preview** | Table asset preview with column metadata |
| **Faceted Filtering** | Filter by domains, tags, and asset types |

### Taxonomy Mapping

This template maps OpenMetadata concepts to familiar data catalog terminology:

| OpenMetadata | PortalJS Starter |
|--------------|------------------|
| Data Products | Datasets |
| Domains | Organizations |
| Tables | Resources |
| Tags | Tags |

## Quick Start

### Prerequisites

- Node.js 18+ (recommended: 22)
- npm or yarn
- Docker and Docker Compose (for local development)

### Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/mjanez/portaljs-starter-omd.git
   cd portaljs-starter-omd
   ```

2. **Install dependencies**
   ```bash
   npm i
   ```

3. **Start OpenMetadata (local development)**
   ```bash
   docker compose -f docker-compose-postgres.yml up -d
   ```
   > This starts a local OpenMetadata instance with sample data at `http://localhost:8585`

4. **Configure OpenMetadata BOT**
   - Navigate to `http://localhost:8585`
   - Login with `admin@open-metadata.org` / `admin`
   - Create a new BOT for the frontend and copy its access token

5. **Configure environment**
   ```bash
   cp .env.example .env
   ```
   Edit `.env`:
   ```bash
   NEXT_PUBLIC_DMS=http://localhost:8585
   DMS_TOKEN=<your-bot-token>
   ```

6. **Start the development server**
   ```bash
   npm run dev
   ```

7. **Open your browser**
   Navigate to `http://localhost:3000`

### Setting Up Sample Data

1. In OpenMetadata, go to **Settings > Services > Database > Add New Service**
2. Choose **PostgreSQL** and configure:
   ```
   Host: postgresql
   Port: 5432
   Username: openmetadata_user
   Password: password
   Database: postgres
   ```
3. Run metadata ingestion
4. Create Domains and Data Products from the ingested assets

## Docker Deployment

### Full Stack (Recommended)

Deploy OpenMetadata + PortalJS with a single command:

```bash
# 1. Copy environment template
cp .env.example .env

# 2. Start all services
docker compose up -d

# 3. Wait for OpenMetadata to be healthy (~2-3 min)
docker compose logs -f openmetadata-server

# 4. Initialize bot token (after OpenMetadata is ready)
./scripts/00_init-bot-token.sh

# 5. Setup sample data source and trigger ingestion
.\scripts\01_setup-sample-data.sh

# 6. Restart PortalJS with the new token
docker compose up -d --build portaljs
```

**Access the services:**
| Service | URL | Credentials |
|---------|-----|-------------|
| PortalJS | http://localhost:3000 | - |
| OpenMetadata | http://localhost:8585 | `admin@open-metadata.org` / `admin` |
| Airflow | http://localhost:8080 | `admin` / `admin` |

### Production Dockerfile

Build and run the frontend as a standalone container:

```bash
# Build the image
docker build -t portaljs-omd:latest -f Dockerfile .

# Run the container
docker run -p 3000:3000 \
  -e NEXT_PUBLIC_DMS=https://your-omd-instance.com \
  -e DMS_TOKEN=your-bot-token \
  portaljs-omd:latest
```

### OpenMetadata Only (Development)

If you already have PortalJS running locally with `npm run dev`:

```bash
# Start only OpenMetadata + sample database
docker compose -f docker-compose-postgres.yml up -d
```

## Customization

### Logo Customization

```tsx
// components/_shared/PortalDefaultLogo.tsx
export default function PortalDefaultLogo() {
  return (
    <Link href="/">
      <img src="/your-logo.png" alt="Your Portal" height={55} />
    </Link>
  );
}
```

### Footer Links

```tsx
// components/_shared/Footer.tsx
const navigation = {
  about: [
    { name: "About Us", href: "/about" },
    { name: "Contact", href: "/contact" },
  ],
  useful: [
    { name: "Datasets", href: "/search" },
    { name: "Organizations", href: "/organizations" },
  ],
  social: [
    { name: "twitter", href: "https://twitter.com/yourhandle" },
    { name: "email", href: "mailto:contact@yoursite.com" },
  ],
};
```

### Theme Components

```tsx
// themes/default/index.tsx
const DefaultTheme = {
  header: CustomHeader,
  footer: CustomFooter,
  layout: DefaultThemeLayout,
};
```

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `NEXT_PUBLIC_DMS` | OpenMetadata instance URL | Yes |
| `DMS_TOKEN` | Bot access token for API authentication | Yes |
| `NEXT_PUBLIC_ORG` | Default organization filter (optional) | No |

## Roadmap

We're actively developing this template with the following planned improvements enumerated in the [ROADMAP](ROADMAP.md):

Want to contribute to any of these features? See our [Contributing Guide](#-contributing)!

## Tech Stack

| Technology | Purpose |
|------------|---------|
| [Next.js 14+](https://nextjs.org/) | React framework with SSR/SSG |
| [TypeScript](https://www.typescriptlang.org/) | Type-safe development |
| [Tailwind CSS](https://tailwindcss.com/) | Utility-first styling |
| [PortalJS Components](https://github.com/datopian/portaljs) | Data portal UI components |
| [Docker](https://www.docker.com/) | Containerization |
| [OpenMetadata API](https://docs.open-metadata.org/) | Data catalog backend |

## NPM Package (Coming Soon)

We're working on publishing this as an npm package for easier integration:

```bash
# Future usage
npx create-portaljs-omd my-data-portal
cd my-data-portal
npm run dev
```

## Contributing

We welcome contributions! Here's how to get started:

1. **Fork** this repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Commands

```bash
npm run dev        # Start development server
npm run build      # Build for production
npm run start      # Start production server
npm run lint       # Run ESLint
npm run typecheck  # Run TypeScript checks
```

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### Attribution

This project is based on [PortalJS](https://github.com/datopian/portaljs) by [Datopian](https://datopian.com/), which is also licensed under the MIT License. We extend our gratitude to the Datopian team for their excellent work on the PortalJS ecosystem.

```
Original work Copyright (c) 2024 Datopian
Modifications Copyright (c) 2025 mjanez
```

## Acknowledgments

- **[Datopian](https://datopian.com/)** - For creating PortalJS and the frontend starter template
- **[OpenMetadata](https://open-metadata.org/)** - For the amazing open-source data catalog
- **[Vercel](https://vercel.com/)** - For Next.js and deployment platform
- All contributors who help improve this project

---

<p align="center">
  <a href="https://github.com/mjanez/portaljs-starter-omd/issues">Report Bug</a> •
  <a href="https://github.com/mjanez/portaljs-starter-omd/issues">Request Feature</a> •
  <a href="https://github.com/mjanez/portaljs-starter-omd/discussions">Discussions</a>
</p>
