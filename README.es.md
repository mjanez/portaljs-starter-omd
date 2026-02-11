<p align="right">
  🌐 <a href="README.md">Read in English</a>
</p>

<h1 align="center">PortalJS OpenMetadata Starter</h1>

<p align="center">
  <em>Una plantilla frontend moderna y lista para producción para catálogos de datos con OpenMetadata</em>
</p>

<p align="center">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="Licencia: MIT"></a>
  <a href="https://nextjs.org/"><img src="https://img.shields.io/badge/Next.js-14+-black?logo=next.js&logoColor=white" alt="Next.js 14+"></a>
  <a href="https://www.typescriptlang.org/"><img src="https://img.shields.io/badge/TypeScript-5.0+-blue?logo=typescript&logoColor=white" alt="TypeScript"></a>
  <a href="https://tailwindcss.com/"><img src="https://img.shields.io/badge/Tailwind_CSS-3.0+-38B2AC?logo=tailwind-css&logoColor=white" alt="Tailwind CSS"></a>
  <a href="https://www.docker.com/"><img src="https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white" alt="Docker"></a>
</p>

<p align="center">
  <a href="#-características">Características</a> •
  <a href="#-inicio-rápido">Inicio rápido</a> •
  <a href="#-despliegue-docker">Docker</a> •
  <a href="#-personalización">Personalización</a> •
  <a href="#-hoja-de-ruta">Hoja de ruta</a> •
  <a href="#-contribuir">Contribuir</a>
</p>

---

## Descripción

**PortalJS OpenMetadata Starter** es una plantilla frontend desacoplada diseñada para crear catálogos de datos públicos atractivos y de alto rendimiento, impulsados por [OpenMetadata](https://open-metadata.org/). Proporciona una interfaz moderna basada en React que se conecta de forma transparente a tu instancia de OpenMetadata, permitiéndote exponer tus productos de datos a usuarios externos.

### ¿Qué hace diferente a este proyecto?

Este proyecto está construido sobre el excelente framework [PortalJS](https://github.com/datopian/portaljs) de [Datopian](https://datopian.com/), extendiéndolo específicamente para la integración con OpenMetadata. Mientras que PortalJS se centra en backends CKAN, esta plantilla:

- **Soporte nativo de OpenMetadata**: integración directa con las APIs de OMD
- **Centrado en Data Products**: diseñado en torno a los Data Products y Dominios de OMD
- **Funcionalidades extendidas**: funcionalidad ampliada más allá de la plantilla base
- **Docker-First**: contenedorización lista para producción
- **Preparado para NPM**: listo para su distribución como paquete independiente

## Características

| Característica | Descripción |
|----------------|-------------|
| **UI Moderna** | Diseño limpio y responsive con Tailwind CSS |
| **Alto Rendimiento** | Construido con Next.js con SSR/SSG para una carga óptima |
| **Integración con OpenMetadata** | Soporte nativo para Data Products, Dominios y Tablas de OMD |
| **TypeScript** | Tipado completo para una mejor experiencia de desarrollo |
| **Sistema de Temas** | Personalización sencilla con temas basados en componentes |
| **Mobile-First** | Diseño responsive que funciona en todos los dispositivos |
| **Docker Ready** | Contenedorización para producción incluida |
| **Búsqueda de Texto Completo** | Impulsada por las capacidades de búsqueda de OpenMetadata |
| **Vista Previa de Datos** | Vista previa de tablas con metadatos de columnas |
| **Filtrado por Facetas** | Filtrado por dominios, etiquetas y tipos de activos |

### Mapeo de Taxonomía

Esta plantilla mapea los conceptos de OpenMetadata a terminología familiar de catálogos de datos:

| OpenMetadata | PortalJS Starter |
|--------------|------------------|
| Data Products | Datasets |
| Domains | Organizaciones |
| Tables | Recursos |
| Tags | Etiquetas |

## Inicio Rápido

### Prerrequisitos

- Node.js 18+ (recomendado: 22)
- npm o yarn
- Docker y Docker Compose (para desarrollo local)

### Configuración para Desarrollo

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/mjanez/portaljs-starter-omd.git
   cd portaljs-starter-omd
   ```

2. **Instalar dependencias**
   ```bash
   npm i
   ```

3. **Iniciar OpenMetadata (desarrollo local)**
   ```bash
   docker compose -f docker-compose-postgres.yml up -d
   ```
   > Esto inicia una instancia local de OpenMetadata con datos de ejemplo en `http://localhost:8585`

4. **Configurar el BOT de OpenMetadata**
   - Navega a `http://localhost:8585`
   - Inicia sesión con `admin@open-metadata.org` / `admin`
   - Crea un nuevo BOT para el frontend y copia su token de acceso

5. **Configurar el entorno**
   ```bash
   cp .env.example .env
   ```
   Edita `.env`:
   ```bash
   NEXT_PUBLIC_DMS=http://localhost:8585
   DMS_TOKEN=<tu-token-de-bot>
   ```

6. **Iniciar el servidor de desarrollo**
   ```bash
   npm run dev
   ```

7. **Abrir el navegador**
   Navega a `http://localhost:3000`

### Configuración de Datos de Ejemplo

1. En OpenMetadata, ve a **Settings > Services > Database > Add New Service**
2. Elige **PostgreSQL** y configura:
   ```
   Host: postgresql
   Port: 5432
   Username: openmetadata_user
   Password: password
   Database: postgres
   ```
3. Ejecuta la ingesta de metadatos
4. Crea Dominios y Data Products a partir de los activos ingestados

## Despliegue Docker

### Stack Completo (Recomendado)

Despliega OpenMetadata + PortalJS con un solo comando:

```bash
# 1. Copiar la plantilla de entorno
cp .env.example .env

# 2. Iniciar todos los servicios
docker compose up -d

# 3. Esperar a que OpenMetadata esté listo (~2-3 min)
docker compose logs -f openmetadata-server

# 4. Inicializar el token del bot (cuando OpenMetadata esté listo)
./scripts/00_init-bot-token.sh

# 5. Configurar la fuente de datos de ejemplo y lanzar la ingesta
./scripts/01_setup-sample-data.sh

# 6. Reiniciar PortalJS con el nuevo token
docker compose up -d --build portaljs
```

**Acceder a los servicios:**
| Servicio | URL | Credenciales |
|----------|-----|--------------|
| PortalJS | http://localhost:3000 | - |
| OpenMetadata | http://localhost:8585 | `admin@open-metadata.org` / `admin` |
| Airflow | http://localhost:8080 | `admin` / `admin` |

### Dockerfile de Producción

Construir y ejecutar el frontend como contenedor independiente:

```bash
# Construir la imagen
docker build -t portaljs-omd:latest -f Dockerfile .

# Ejecutar el contenedor
docker run -p 3000:3000 \
  -e NEXT_PUBLIC_DMS=https://tu-instancia-omd.com \
  -e DMS_TOKEN=tu-token-de-bot \
  portaljs-omd:latest
```

### Solo OpenMetadata (Desarrollo)

Si ya tienes PortalJS ejecutándose localmente con `npm run dev`:

```bash
# Iniciar solo OpenMetadata + base de datos de ejemplo
docker compose -f docker-compose-postgres.yml up -d
```

## Personalización

### Personalización del Logo

```tsx
// components/_shared/PortalDefaultLogo.tsx
export default function PortalDefaultLogo() {
  return (
    <Link href="/">
      <img src="/tu-logo.png" alt="Tu Portal" height={55} />
    </Link>
  );
}
```

### Enlaces del Footer

```tsx
// components/_shared/Footer.tsx
const navigation = {
  about: [
    { name: "Sobre Nosotros", href: "/about" },
    { name: "Contacto", href: "/contact" },
  ],
  useful: [
    { name: "Datasets", href: "/search" },
    { name: "Organizaciones", href: "/organizations" },
  ],
  social: [
    { name: "twitter", href: "https://twitter.com/tuhandle" },
    { name: "email", href: "mailto:contacto@tusitio.com" },
  ],
};
```

### Componentes de Tema

```tsx
// themes/default/index.tsx
const DefaultTheme = {
  header: CustomHeader,
  footer: CustomFooter,
  layout: DefaultThemeLayout,
};
```

### Variables de Entorno

| Variable | Descripción | Requerida |
|----------|-------------|-----------|
| `NEXT_PUBLIC_DMS` | URL de la instancia de OpenMetadata | Sí |
| `DMS_TOKEN` | Token de acceso del bot para autenticación API | Sí |
| `NEXT_PUBLIC_ORG` | Filtro de organización por defecto (opcional) | No |

## Hoja de Ruta

Estamos desarrollando activamente esta plantilla con las mejoras planificadas enumeradas en el [ROADMAP](ROADMAP.md).

¿Quieres contribuir a alguna de estas funcionalidades? ¡Consulta nuestra [Guía de Contribución](#-contribuir)!

## Stack Tecnológico

| Tecnología | Propósito |
|------------|-----------|
| [Next.js 14+](https://nextjs.org/) | Framework React con SSR/SSG |
| [TypeScript](https://www.typescriptlang.org/) | Desarrollo con tipado seguro |
| [Tailwind CSS](https://tailwindcss.com/) | Estilos utility-first |
| [Componentes PortalJS](https://github.com/datopian/portaljs) | Componentes UI para portales de datos |
| [Docker](https://www.docker.com/) | Contenedorización |
| [API de OpenMetadata](https://docs.open-metadata.org/) | Backend del catálogo de datos |

## Paquete NPM (Próximamente)

Estamos trabajando en publicar esto como un paquete npm para una integración más sencilla:

```bash
# Uso futuro
npx create-portaljs-omd mi-portal-de-datos
cd mi-portal-de-datos
npm run dev
```

## Contribuir

¡Las contribuciones son bienvenidas! Así puedes empezar:

1. **Haz fork** de este repositorio
2. **Crea** una rama de funcionalidad (`git checkout -b feature/funcionalidad-increible`)
3. **Haz commit** de tus cambios (`git commit -m 'Añadir funcionalidad increíble'`)
4. **Haz push** a la rama (`git push origin feature/funcionalidad-increible`)
5. **Abre** un Pull Request

### Comandos de Desarrollo

```bash
npm run dev        # Iniciar servidor de desarrollo
npm run build      # Compilar para producción
npm run start      # Iniciar servidor de producción
npm run lint       # Ejecutar ESLint
npm run typecheck  # Ejecutar comprobaciones de TypeScript
```

## Licencia

Este proyecto está licenciado bajo la **Licencia MIT** - consulta el archivo [LICENSE](LICENSE) para más detalles.

### Atribución

Este proyecto está basado en [PortalJS](https://github.com/datopian/portaljs) de [Datopian](https://datopian.com/), que también está licenciado bajo la Licencia MIT. Extendemos nuestro agradecimiento al equipo de Datopian por su excelente trabajo en el ecosistema PortalJS.

```
Trabajo original Copyright (c) 2024 Datopian
Modificaciones Copyright (c) 2025 mjanez
```

## Agradecimientos

- **[Datopian](https://datopian.com/)** - Por crear PortalJS y la plantilla frontend starter
- **[OpenMetadata](https://open-metadata.org/)** - Por el increíble catálogo de datos open-source
- **[Vercel](https://vercel.com/)** - Por Next.js y la plataforma de despliegue
- Todos los contribuidores que ayudan a mejorar este proyecto

---

<p align="center">
  <a href="https://github.com/mjanez/portaljs-starter-omd/issues">Reportar Bug</a> •
  <a href="https://github.com/mjanez/portaljs-starter-omd/issues">Solicitar Funcionalidad</a> •
  <a href="https://github.com/mjanez/portaljs-starter-omd/discussions">Discusiones</a>
</p>
