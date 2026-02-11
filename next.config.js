// const { withContentlayer } = require("next-contentlayer");

/** @type {import('next').NextConfig} */
const domains = [
  "demo.dev.datopian.com",
  "api.dev.cloud.portaljs",
  "blob.datopian.com",
];
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  // Enable standalone output for Docker deployment
  output: "standalone",
  eslint: {
    // Warning: This allows production builds to successfully complete even if
    // your project has ESLint errors.
    ignoreDuringBuilds: true,
  },
  images: {
    domains,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  publicRuntimeConfig: {
    DOMAINS: domains, // Make domains accessible at runtime
  },
};

module.exports = nextConfig;
