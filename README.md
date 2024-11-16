# Blog system built with SQL Server, ASP.NET Core web api, Angular

## Features

- Register, Sign in, Sign out
- Show blogs list with paging
- Create blog: add photo to blog
- View blog detail
- Edit blog
- Comment on blog: edit, reply, edit comment

## Tech stack

- Database: SQL Server
- Back-end: ASP.NET Core web api
- Front-end: Angular
- Nuget packages: Newtonsoft.Json, Microsoft.Extensions.Identity.Core, Dapper, System.Data.SqlClient

## Run local

### Initial database

- Install SQL Server
- Run script in file Deployment.sql

### Run back-end project

- dotnet run

### Run front-end project

- Install node packages with command: npm install
- Run project with command: ng serve

## Hosting

- Point api urls to prod path
- Modify output path point to wwwfolder of Web API project
- Config middleware using UseDefaultFiles() and UseStaticFiles() methods in Startup.cs
- Run command: ng build
- Add fallback controller
