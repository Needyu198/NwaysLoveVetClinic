# Deploying to AWS

This directory contains configuration to run the clinic stack on AWS. The whole
system is containerized (see the `Dockerfile`s and `docker-compose.yml` at the
repo root), so you can deploy it several ways. Two recommended paths:

- **Simple / cheapest:** one EC2 instance running `docker compose`.
- **Managed / scalable:** Amazon ECS (Fargate) for the containers + Amazon RDS
  for PostgreSQL.

> These steps require **your AWS account and credentials** and will incur cost.
> Nothing here provisions resources on its own; you run the commands.

## Architecture on AWS

```
            +-------------------- AWS --------------------+
  Internet  |                                             |
   ─────────┼──> ALB ──> backend (ECS/Fargate :5050) ──┐  |
            |        └─> web-staff (ECS/Fargate :80)   │  |
            |            reporting (ECS/Fargate :5060) │  |
            |                                          v  |
            |                              RDS PostgreSQL |
            +---------------------------------------------+
```

## Option A — Single EC2 with docker compose (quick start)

1. Launch an Amazon Linux 2023 EC2 instance (t3.small is enough for a demo).
   Open security-group inbound ports 22, 5050, 5060, 8080 (or 80 behind a proxy).
2. Install Docker + compose plugin:
   ```bash
   sudo yum install -y docker && sudo systemctl enable --now docker
   sudo usermod -aG docker ec2-user
   sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
     -o /usr/libexec/docker/cli-plugins/docker-compose && sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose
   ```
3. Copy the repo to the instance, then:
   ```bash
   cp .env.docker.example .env   # set a strong DB_PASSWORD and STAFF_API_BASE_URL=http://<EC2_PUBLIC>:5050
   docker compose up -d --build
   ```
4. Visit `http://<EC2_PUBLIC>:8080` for the staff app; the API is on `:5050`.

## Option B — ECS Fargate + RDS (managed)

1. **RDS**: create a PostgreSQL 16 instance. Note host, port, db, user, password.
2. **ECR**: create repositories and push images:
   ```bash
   aws ecr create-repository --repository-name nways-backend
   aws ecr create-repository --repository-name nways-reporting
   aws ecr create-repository --repository-name nways-web-staff
   # authenticate, then for each image:
   docker build -t <acct>.dkr.ecr.<region>.amazonaws.com/nways-backend ./backend
   docker push <acct>.dkr.ecr.<region>.amazonaws.com/nways-backend
   # repeat for reporting and web-staff (pass --build-arg VITE_API_BASE_URL=<backend URL> for web-staff)
   ```
3. **Secrets**: store `DB_PASSWORD` (and optionally `FIREBASE_SERVICE_ACCOUNT`)
   in AWS Secrets Manager.
4. **ECS**: create a Fargate cluster and services using
   `deploy/ecs-task-definition.json` as a template (fill in the account id,
   region, image URIs, RDS endpoint, and secret ARNs).
5. **ALB**: put an Application Load Balancer in front, routing `/` to web-staff,
   and expose the backend on its own listener/hostname. Point
   `VITE_API_BASE_URL` at that backend hostname when building the web image.

## Notes

- The backend runs `ensureDatabaseSchema()` on startup, so it creates its tables
  automatically against RDS on first boot.
- Set `HOST=0.0.0.0` (already the container default) so it accepts external
  connections.
- Restrict the RDS security group to the backend/reporting security groups only.
- For HTTPS, terminate TLS at the ALB with an ACM certificate.
