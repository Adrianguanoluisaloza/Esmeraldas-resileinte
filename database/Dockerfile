# PostgreSQL 16 + PostGIS 3 para x86 y ARM.
# La imagen postgis/postgis no publica arm64 y la VM de Oracle (A1.Flex) es ARM.
FROM postgres:16-bookworm
RUN apt-get update \
  && apt-get install -y --no-install-recommends postgresql-16-postgis-3 postgresql-16-postgis-3-scripts \
  && rm -rf /var/lib/apt/lists/*
