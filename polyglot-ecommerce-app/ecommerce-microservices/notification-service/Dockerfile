FROM mcr.microsoft.com/dotnet/sdk:6.0
WORKDIR /app
COPY Program.cs .
RUN dotnet new console -n app && mv Program.cs app/Program.cs && cd app && dotnet build
CMD ["dotnet","run","--project","app"]