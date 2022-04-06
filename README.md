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
- Create Azure CDN for our Azure Blob Storage.
- Added custom domain to CDN, [www.davisdre.me](https://www.davisdre.me).
- Enable HTTPS on the Azure CDN.
- Added my custom domain to CORS policy for Azure Function.

## Fourth Steps
- Setup CI/CD.
- Created GitHub workflows for backend and frontend to be trigger on push oin those respective folders. 

## Azure Technologies being used
- Azure CosmosDB
- Azure Functions
- Azure Storage
- Azure CDN
