# azure-resume
My own Azure resume, following [ACG project video](https://learn.acloud.guru/series/acg-projects/view/403). Created on my Windows 11 laptop, using [Visual Studio Code](https://code.visualstudio.com/).

## Software I needed for this project.

- [Visual Studio Code](https://code.visualstudio.com/)
- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=v4%2Cwindows%2Ccsharp%2Cportal%2Cbash)
- [Visual Studio Code Extension: Azure Functions](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurefunctions)
- [NuGet Microsoft.Azure.WebJobs.Extensions.CosmosDB](https://www.nuget.org/packages/Microsoft.Azure.WebJobs.Extensions.CosmosDB#dotnet-cli)
- [Visual Studio Code Extension: Azure Storage](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurestorage)

## First Steps

- Frontend folder contains the website.
- main.js contains visitor counter code.

## Second Steps
- Backend folder contains the api.
- Created Azure Resource Group in Azure portal.
- Created Azure CosmosDB in Azure portal.
- Created Azure Function locally via CLI.
- Deployed local Azure Function to Azure for production via Visual Studio Code Extension: Azure Functions.

## Third Steps
- Deployed Frontend folder to Azure Blob Storage via Visual Studio Code Extension: Azure Storage.
- Updated CORS setting on Azure function to reflect URL of Azure Blog Storage.
- Create Cloudflare distribution for our Azure Blob Storage.
- Added custom domain to Cloudflare, [www.davisdre.me](https://www.davisdre.me).
- Enable HTTPS on Cloudflare.
- Added my custom domain to CORS policy for Azure Function.

## Fourth Steps
- Setup CI/CD.
- Created GitHub workflows for backend and frontend to be trigger on push oin those respective folders. 

## Technologies being used
- Azure CosmosDB
- Azure Functions
- Azure Storage
- Cloudflare

## Recent updates (2026-03-18)
- Fixed a production HTTP 500 on `GetResumeCounter` caused by a missing runtime assembly used by the Cosmos DB input binding.
- Added explicit dependency management for `Microsoft.Bcl.AsyncInterfaces` in the backend function project.
- Upgraded backend function packages to current versions:
	- `Microsoft.Azure.Functions.Worker` `2.51.0`
	- `Microsoft.Azure.Functions.Worker.Sdk` `2.0.7`
	- `Microsoft.Azure.Functions.Worker.Extensions.Http` `3.3.0`
	- `Microsoft.Azure.Functions.Worker.Extensions.CosmosDB` `4.14.0`
	- `Microsoft.Bcl.AsyncInterfaces` `8.0.0`
- Verified deployment and endpoint health in Azure (`/api/getresumecounter` returning `200 OK` with incrementing counter).
- Updated repository ignore rules to keep generated/local files out of source control:
	- `backend/tests/obj/`
	- `.gemini/`
