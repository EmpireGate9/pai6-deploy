# PAI-6 Ready

## Autodeploy Suite
- مشغّل: `pai6_full_autodeploy.sh`
- متغيرات:
  - `DRY_RUN=1` تشغيل تجريبي بلا تنفيذ فعلي.
  - `CONFIRM=1` تجاوز التأكيد التفاعلي.
  - `LOG=logs/deploy.log` مسار اللوج.
- بيئات:
  - `docker-compose.yml` الأساسي.
  - `infra/docker-compose.staging.yml` و `infra/docker-compose.prod.yml` كـ overrides:
    - مثال: `docker compose -f infra/docker-compose.yml -f infra/docker-compose.staging.yml up -d --build`
