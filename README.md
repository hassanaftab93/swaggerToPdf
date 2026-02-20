# Linux Script:

## Usage

```bash
  chmod +x swaggerToPdf.sh
```

## Custom URL and output filename

```bash
  ./swaggerToPdf.sh https://your-api/swagger/v1/swagger.json my-api.pdf
```

## What it does:

- Takes the Swagger URL and output filename as arguments (both optional with sensible defaults)

- Pre-flight checks Docker and curl are available before running anything

- Runs all 3 steps with clear numbered progress logging

- Validates output at each step — exits with a clear error message if something fails

- Cleans up temp files (swagger.json, index.html, openapi-generator artifacts) after PDF is created

- Color-coded output so it's easy to read in pipeline logs

## For Azure DevOps, just call it as a script step:

  ```yaml
    - script: |
        chmod +x swaggerToPdf.sh
        ./swaggerToPdf.sh https://azdev-bffweb.reeft.com/swagger/v1/swagger.json api-docs.pdf
      displayName: 'Generate API Documentation PDF'

    - publish: $(System.DefaultWorkingDirectory)/api-docs.pdf
      artifact: SwaggerDocs
  ```

---
# Windows Script

## Usage

```powershell
  .\swaggerToPdf.ps1
```

## Custom URL and output name

```powershell
  .\swaggerToPdf.ps1 -SwaggerUrl "https://your-api/swagger/v1/swagger.json" -OutputPdf "my-api.pdf"
```

## If you hit execution policy issues:

```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass .\swaggerToPdf.ps1
```

## For Azure DevOps (Windows agent):

  ```yaml
    - task: PowerShell@2
      displayName: 'Generate API Documentation PDF'
      inputs:
        filePath: 'swaggerToPdf.ps1'
        arguments: '-SwaggerUrl "https://azdev-bffweb.reeft.com/swagger/v1/swagger.json" -OutputPdf "api-docs.pdf"'

    - publish: $(System.DefaultWorkingDirectory)/api-docs.pdf
      artifact: SwaggerDocs
  ```