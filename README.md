# Features
- Register, Signin, Signout
- Show blogs list with paging
- Create blog: add photo to blog
- View blog detail
- Edit blog
- Comment on blog: edit, reply, edit comment

# How to run this project locally?
1. Initial database
- Install SQL Server
- Run script in file Deployment.sql
2. Run back-end project
- Run command
  + Point to Blog.Web project
  + Run command: dotnet watch run
3. Run front-end project
  + Install node packages with command: npm install
  + Run project with command: ng serve

How to deploy this project to a host?
- Point api urls to prod path
- Modify output path point to wwwfolder of Web API project
- Config middleware using UseDefaultFiles() and UseStaticFiles() methods in Startup.cs
- Run command: ng build
- Add fallback controller
- 
