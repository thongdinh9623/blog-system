CREATE DATABASE BlogDB;

SET search_path TO BlogDB;

/* Types */

CREATE TYPE public.AccountType AS (
    Username VARCHAR(20),
    NormalizedUsername VARCHAR(20),
    Email VARCHAR(30),
    NormalizedEmail VARCHAR(30),
    Fullname VARCHAR(30),
    PasswordHash TEXT
);

CREATE TYPE public.BlogCommentType AS (
    BlogCommentId INTEGER,
    ParentBlogCommentId INTEGER,
    BlogId INTEGER,
    Content VARCHAR(300)
);

CREATE TYPE public.BlogType AS (
    BlogId INTEGER,
    Title VARCHAR(50),
    Content TEXT,
    PhotoId INTEGER
);

CREATE TYPE public.PhotoType AS (
    PublicId VARCHAR(50),
    ImageUrl VARCHAR(250),
    Description VARCHAR(30)
);

/* Tables */

CREATE TABLE public.ApplicationUser (
    ApplicationUserId SERIAL PRIMARY KEY,
    Username VARCHAR(20) NOT NULL,
    NormalizedUsername VARCHAR(20) NOT NULL,
    Email VARCHAR(30) NOT NULL,
    NormalizedEmail VARCHAR(30) NOT NULL,
    Fullname VARCHAR(30) NULL,
    PasswordHash TEXT NOT NULL
);

CREATE INDEX IX_ApplicationUser_NormalizedUsername
ON public.ApplicationUser (NormalizedUsername);

CREATE INDEX IX_ApplicationUser_NormalizedEmail
ON public.ApplicationUser (NormalizedEmail);

CREATE TABLE public.Photo (
    PhotoId SERIAL PRIMARY KEY,
    ApplicationUserId INTEGER NOT NULL,
    PublicId VARCHAR(50) NOT NULL,
    ImageUrl VARCHAR(250) NOT NULL,
    Description VARCHAR(30) NOT NULL,
    PublishDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdateDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ApplicationUserId) REFERENCES public.ApplicationUser (ApplicationUserId)
);

CREATE TABLE public.Blog (
    BlogId SERIAL PRIMARY KEY,
    ApplicationUserId INTEGER NOT NULL,
    PhotoId INTEGER,
    Title VARCHAR(50) NOT NULL,
    Content TEXT NOT NULL,
    PublishDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdateDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActiveInd BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (ApplicationUserId) REFERENCES public.ApplicationUser (ApplicationUserId),
    FOREIGN KEY (PhotoId) REFERENCES public.Photo (PhotoId)
);

CREATE TABLE public.BlogComment (
    BlogCommentId SERIAL PRIMARY KEY,
    ParentBlogCommentId INTEGER,
    BlogId INTEGER NOT NULL,
    ApplicationUserId INTEGER NOT NULL,
    Content VARCHAR(300) NOT NULL,
    PublishDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdateDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActiveInd BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (BlogId) REFERENCES public.Blog (BlogId),
    FOREIGN KEY (ApplicationUserId) REFERENCES public.ApplicationUser (ApplicationUserId)
);

/* Views */

CREATE VIEW aggregate.Blog
AS
SELECT t1.BlogId,
       t1.ApplicationUserId,
       t2.Username,
       t1.Title,
       t1.Content,
       t1.PhotoId,
       t1.PublishDate,
       t1.UpdateDate,
       t1.ActiveInd
FROM dbo.Blog t1
    INNER JOIN dbo.ApplicationUser t2
        ON t1.ApplicationUserId = t2.ApplicationUserId;

CREATE VIEW aggregate.BlogComment
AS
SELECT t1.BlogCommentId,
       t1.ParentBlogCommentId,
       t1.BlogId,
       t1.Content,
       t2.Username,
       t1.ApplicationUserId,
       t1.PublishDate,
       t1.UpdateDate,
       t1.ActiveInd
FROM dbo.BlogComment t1
    INNER JOIN dbo.ApplicationUser t2
        ON t1.ApplicationUserId = t2.ApplicationUserId;

CREATE PROCEDURE Account_GetByUsername @NormalizedUsername VARCHAR(20)
AS
SELECT ApplicationUserId,
       Username,
       NormalizedUsername,
       Email,
       NormalizedEmail,
       Fullname,
       PasswordHash
FROM ApplicationUser t1
WHERE t1.NormalizedUsername = @NormalizedUsername;

/* Procedures */

CREATE PROCEDURE Account_Insert @Account AccountType READONLY
AS
INSERT INTO ApplicationUser
(
    Username,
    NormalizedUsername,
    Email,
    NormalizedEmail,
    Fullname,
    PasswordHash
)
SELECT Username,
       NormalizedUsername,
       Email,
       NormalizedEmail,
       Fullname,
       PasswordHash
FROM @Account;

SELECT CAST(SCOPE_IDENTITY() AS INT);

CREATE PROCEDURE Blog_Delete @BlogId INT
AS
UPDATE BlogComment
SET ActiveInd = CONVERT(BIT, 0),
    UpdateDate = GETDATE()
WHERE BlogId = @BlogId;

UPDATE Blog
SET PhotoId = NULL,
    ActiveInd = CONVERT(BIT, 0),
    UpdateDate = GETDATE()
WHERE BlogId = @BlogId;

CREATE PROCEDURE Blog_Get @BlogId INT
AS
SELECT BlogId,
       ApplicationUserId,
       Username,
       Title,
       Content,
       PhotoId,
       PublishDate,
       UpdateDate
FROM aggregate.Blog t1
WHERE t1.BlogId = @BlogId
      AND t1.ActiveInd = CONVERT(BIT, 1);

CREATE PROCEDURE Blog_GetAll
    @Offset INT,
    @PageSize INT
AS
SELECT BlogId,
       ApplicationUserId,
       Username,
       Title,
       Content,
       PhotoId,
       PublishDate,
       UpdateDate
FROM aggregate.Blog t1
WHERE t1.ActiveInd = CONVERT(BIT, 1)
ORDER BY t1.BlogId OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

SELECT COUNT(*)
FROM aggregate.Blog t1
WHERE t1.ActiveInd = CONVERT(BIT, 1);

CREATE PROCEDURE Blog_GetAllFamous
AS
SELECT TOP 6
    t1.BlogId,
    t1.ApplicationUserId,
    t1.Username,
    t1.PhotoId,
    t1.Title,
    t1.Content,
    t1.PublishDate,
    t1.UpdateDate
FROM aggregate.Blog t1
    INNER JOIN BlogComment t2
        ON t1.BlogId = t2.BlogId
WHERE t1.ActiveInd = CONVERT(BIT, 1)
      AND t2.ActiveInd = CONVERT(BIT, 1)
GROUP BY t1.BlogId,
         t1.ApplicationUserId,
         t1.Username,
         t1.PhotoId,
         t1.Title,
         t1.Content,
         t1.PublishDate,
         t1.UpdateDate
ORDER BY COUNT(t2.BlogCommentId) DESC;

CREATE PROCEDURE Blog_GetByUserId @ApplicationUserId INT
AS
SELECT BlogId,
       ApplicationUserId,
       Username,
       Title,
       Content,
       PhotoId,
       PublishDate,
       UpdateDate
FROM aggregate.Blog t1
WHERE t1.ApplicationUserId = @ApplicationUserId
      AND t1.ActiveInd = CONVERT(BIT, 1);

CREATE PROCEDURE Blog_Upsert
    @Blog BlogType READONLY,
    @ApplicationUserId INT
AS
MERGE INTO Blog TARGET
USING
(
    SELECT BlogId,
           @ApplicationUserId ApplicationUserId,
           Title,
           Content,
           PhotoId
    FROM @Blog
) AS SOURCE
ON (
       TARGET.BlogId = SOURCE.BlogId
       AND TARGET.ApplicationUserId = SOURCE.ApplicationUserId
   )
WHEN MATCHED THEN
    UPDATE SET TARGET.Title = SOURCE.Title,
               TARGET.Content = SOURCE.Content,
               TARGET.PhotoId = SOURCE.PhotoId,
               TARGET.UpdateDate = GETDATE()
WHEN NOT MATCHED BY TARGET THEN
    INSERT
    (
        ApplicationUserId,
        Title,
        Content,
        PhotoId
    )
    VALUES
    (SOURCE.ApplicationUserId, SOURCE.Title, SOURCE.Content, SOURCE.PhotoId);

SELECT CAST(SCOPE_IDENTITY() AS INT);

CREATE PROCEDURE BlogComment_Delete @BlogCommentId INT
AS
DROP TABLE IF EXISTS #BlogCommentsToBeDeleted;
WITH cte_blogComments
AS (SELECT t1.BlogCommentId,
           t1.ParentBlogCommentId
    FROM BlogComment t1
    WHERE t1.BlogCommentId = @BlogCommentId
    UNION ALL
    SELECT t2.BlogCommentId,
           t2.ParentBlogCommentId
    FROM BlogComment t2
        INNER JOIN cte_blogComments t3
            ON t3.BlogCommentId = t2.ParentBlogCommentId
   )
SELECT BlogCommentId,
       ParentBlogCommentId
INTO #BlogCommentsToBeDeleted
FROM cte_blogComments;

UPDATE t1
SET t1.ActiveInd = CONVERT(BIT, 0),
    t1.UpdateDate = GETDATE()
FROM BlogComment t1
    INNER JOIN #BlogCommentsToBeDeleted t2
        ON t1.BlogCommentId = t2.BlogCommentId;

CREATE PROCEDURE BlogComment_Get @BlogCommentId INT
AS
SELECT t1.BlogCommentId,
       t1.ParentBlogCommentId,
       t1.BlogId,
       t1.ApplicationUserId,
       t1.Username,
       t1.Content,
       t1.PublishDate,
       t1.UpdateDate
FROM aggregate.BlogComment t1
WHERE t1.BlogCommentId = @BlogCommentId
      AND t1.ActiveInd = CONVERT(BIT, 1)

CREATE PROCEDURE BlogComment_GetAll @BlogId INT
AS
SELECT t1.BlogCommentId,
       t1.ParentBlogCommentId,
       t1.BlogId,
       t1.ApplicationUserId,
       t1.Username,
       t1.Content,
       t1.PublishDate,
       t1.UpdateDate
FROM aggregate.BlogComment t1
WHERE t1.BlogId = @BlogId
      AND t1.ActiveInd = CONVERT(BIT, 1)
ORDER BY t1.UpdateDate DESC;

CREATE PROCEDURE BlogComment_Upsert
    @BlogComment BlogCommentType READONLY,
    @ApplicationUserId INT
AS
MERGE INTO BlogComment TARGET
USING
(
    SELECT BlogCommentId,
           ParentBlogCommentId,
           BlogId,
           Content,
           @ApplicationUserId ApplicationUserId
    FROM @BlogComment
) AS SOURCE
ON (
       TARGET.BlogCommentId = SOURCE.BlogCommentId
       AND TARGET.ApplicationUserId = SOURCE.ApplicationUserId
   )
WHEN MATCHED THEN
    UPDATE SET TARGET.Content = SOURCE.Content,
               TARGET.UpdateDate = GETDATE()
WHEN NOT MATCHED BY TARGET THEN
    INSERT
    (
        ParentBlogCommentId,
        BlogId,
        ApplicationUserId,
        Content
    )
    VALUES
    (SOURCE.ParentBlogCommentId, SOURCE.BlogId, SOURCE.ApplicationUserId, SOURCE.Content);

SELECT CAST(SCOPE_IDENTITY() AS INT);

CREATE PROCEDURE Photo_Delete @PhotoId INT
AS
DELETE FROM Photo
WHERE PhotoId = @PhotoId;

CREATE PROCEDURE Photo_Get @PhotoId INT
AS
SELECT t1.PhotoId,
       t1.ApplicationUserId,
       t1.PublicId,
       t1.ImageUrl,
       t1.Description,
       t1.PublishDate,
       t1.UpdateDate
FROM Photo t1
WHERE t1.PhotoId = @PhotoId;

CREATE PROCEDURE Photo_GetByUserId @ApplicationUserId INT
AS
SELECT t1.PhotoId,
       t1.ApplicationUserId,
       t1.PublicId,
       t1.ImageUrl,
       t1.Description,
       t1.PublishDate,
       t1.UpdateDate
FROM Photo t1
WHERE t1.ApplicationUserId = @ApplicationUserId;

CREATE PROCEDURE Photo_Insert
    @Photo PhotoType READONLY,
    @ApplicationUserId INT
AS
INSERT INTO Photo
(
    ApplicationUserId,
    PublicId,
    ImageUrl,
    Description
)
SELECT @ApplicationUserId,
       PublicId,
       ImageUrl,
       Description
FROM @Photo;

SELECT CAST(SCOPE_IDENTITY() AS INT);