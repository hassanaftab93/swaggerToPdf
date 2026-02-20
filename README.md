# Swagger → PDF Generator

Convert a Swagger/OpenAPI JSON spec into a clean PDF document using Docker — no local dependencies beyond `curl` and Docker itself.

Works on **Linux/macOS** (`swaggerToPdf.sh`) and **Windows** (`swaggerToPdf.ps1`).

---

## How it works

The scripts run three steps automatically:

1. **Download** the Swagger JSON from a URL via `curl`
2. **Generate HTML** docs using [`openapitools/openapi-generator-cli`](https://hub.docker.com/r/openapitools/openapi-generator-cli) (Docker)
3. **Convert to PDF** using headless Chromium via [`zenika/alpine-chrome`](https://hub.docker.com/r/zenika/alpine-chrome) (Docker)

Temporary files (`swagger.json`, `index.html`, openapi-generator artifacts) are cleaned up automatically after the PDF is created.

---

## Prerequisites

| Dependency | Notes |
|---|---|
| `curl` | Used to download the Swagger JSON |
| `docker` | Must be installed and the daemon must be running |

---

## Linux / macOS

### Quick start

```bash
chmod +x swaggerToPdf.sh
./swaggerToPdf.sh
```

### Custom URL and output filename

```bash
./swaggerToPdf.sh https://your-api/swagger/v1/swagger.json my-api.pdf
```

Both arguments are optional — defaults are used if omitted.

### Azure DevOps pipeline (Linux agent)

```yaml
- script: |
    chmod +x swaggerToPdf.sh
    ./swaggerToPdf.sh https://your-api/swagger/v1/swagger.json api-docs.pdf
  displayName: 'Generate API Documentation PDF'

- publish: $(System.DefaultWorkingDirectory)/api-docs.pdf
  artifact: SwaggerDocs
```

---

## Windows

### Quick start

```powershell
.\swaggerToPdf.ps1
```

### Custom URL and output filename

```powershell
.\swaggerToPdf.ps1 -SwaggerUrl "https://your-api/swagger/v1/swagger.json" -OutputPdf "my-api.pdf"
```

### Execution policy

If you hit an execution policy error, bypass it for the current process only:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\swaggerToPdf.ps1
```

### Azure DevOps pipeline (Windows agent)

```yaml
- task: PowerShell@2
  displayName: 'Generate API Documentation PDF'
  inputs:
    filePath: 'swaggerToPdf.ps1'
    arguments: '-SwaggerUrl "https://your-api/swagger/v1/swagger.json" -OutputPdf "api-docs.pdf"'

- publish: $(System.DefaultWorkingDirectory)/api-docs.pdf
  artifact: SwaggerDocs
```

---

## Features

- **Pre-flight checks** — verifies `curl` and Docker are available before doing anything
- **Step-by-step logging** — numbered progress with color-coded output (easy to read in CI logs)
- **Output validation** — exits with a clear error message if any step fails
- **Auto cleanup** — removes all temp files after the PDF is generated
- **Sensible defaults** — both URL and output filename are optional arguments
