CREATE DATABASE [BlogDB];

CREATE SCHEMA aggregate;

CREATE TABLE public.AccountType (
	Username VARCHAR(20) NOT NULL,
	NormalizedUsername VARCHAR(20) NOT NULL,
	Email VARCHAR(30) NOT NULL,
	NormalizedEmail VARCHAR(30) NOT NULL,
	Fullname VARCHAR(30) NULL,
	PasswordHash VARCHAR NOT NULL
);

CREATE TYPE public.AccountTypeUdt AS (
  Username VARCHAR(20)
);

CREATE TABLE public.BlogCommentType (
	BlogCommentId INTEGER NOT NULL,
	ParentBlogCommentId INTEGER NULL,
	BlogId INTEGER NOT NULL,
	Content VARCHAR(300) NOT NULL
);

CREATE TYPE public.BlogCommentTypeUdt AS (
  	BlogCommentId INTEGER,
	ParentBlogCommentId INTEGER,
	BlogId INTEGER
);

CREATE TABLE public.BlogType AS (
	BlogId INTEGER NOT NULL,
	Title VARCHAR(50) NOT NULL,
	Content VARCHAR(max) NOT NULL,
	PhotoId INTEGER NULL
);

CREATE TYPE public.BlogTypeUdt AS (
	BlogId INTEGER
);

CREATE TABLE public.PhotoType AS (
	PublicId VARCHAR(50) NOT NULL,
	ImageUrl VARCHAR(250) NOT NULL,
	Description VARCHAR(30) NOT NULL
);

	-- SQLINES LICENSE FOR EVALUATION USE ONLY
	CREATE TABLE ApplicationUser (
		ApplicationUserId INT NOT NULL GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1),
		Username VARCHAR(20) NOT NULL,
		NormalizedUsername VARCHAR(20) NOT NULL,
		Email VARCHAR(30) NOT NULL,
		NormalizedEmail VARCHAR(30) NOT NULL,
		Fullname VARCHAR(30) NULL,
		PasswordHash TEXT NOT NULL,
		PRIMARY KEY(ApplicationUserId)
	);

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE INDEX IX_ApplicationUser_NormalizedUsername ON ApplicationUser (NormalizedUsername);

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE INDEX IX_ApplicationUser_NormalizedEmail ON ApplicationUser (NormalizedEmail);

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE TABLE Blog (
	BlogId INT NOT NULL GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1),
	ApplicationUserId INT NOT NULL,
	PhotoId INT NULL,
	Title VARCHAR(50) NOT NULL,
	Content TEXT NOT NULL,
	PublishDate TIMESTAMP(3) NOT NULL DEFAULT NOW(),
	UpdateDate TIMESTAMP(3) NOT NULL DEFAULT NOW(),
	ActiveInd BOOLEAN NOT NULL DEFAULT CONVERT(BIT, 1) PRIMARY KEY(BlogId);

,
FOREIGN KEY(ApplicationUserId) REFERENCES ApplicationUser(ApplicationUserId),
FOREIGN KEY(PhotoId) REFERENCES Photo(PhotoId)
)
GO
	-- SQLINES LICENSE FOR EVALUATION USE ONLY
	CREATE TABLE Photo (
		PhotoId INT NOT NULL GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1),
		ApplicationUserId INT NOT NULL,
		PublicId VARCHAR(50) NOT NULL,
		ImageUrl VARCHAR(250) NOT NULL,
		Description VARCHAR(30) NOT NULL,
		PublishDate TIMESTAMP(3) NOT NULL DEFAULT NOW(),
		UpdateDate TIMESTAMP(3) NOT NULL DEFAULT NOW(),
		PRIMARY KEY(PhotoId),
		FOREIGN KEY(ApplicationUserId) REFERENCES ApplicationUser(ApplicationUserId)
	);

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE TABLE BlogComment (
	BlogCommentId INT NOT NULL GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1),
	ParentBlogCommentId INT NULL,
	BlogId INT NOT NULL,
	ApplicationUserId INT NOT NULL,
	Content VARCHAR(300) NOT NULL,
	PublishDate TIMESTAMP(3) NOT NULL DEFAULT NOW(),
	UpdateDate TIMESTAMP(3) NOT NULL DEFAULT NOW(),
	ActiveInd BOOLEAN NOT NULL DEFAULT CONVERT(BIT, 1),
	PRIMARY KEY(BlogCommentId),
	FOREIGN KEY(BlogId) REFERENCES Blog(BlogId),
	FOREIGN KEY(ApplicationUserId) REFERENCES ApplicationUser(ApplicationUserId)
);

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE VIEW [aggregate].Blog AS
SELECT
	t1.BlogId,
	t1.ApplicationUserId,
	t2.Username,
	t1.Title,
	t1.Content,
	t1.PhotoId,
	t1.PublishDate,
	t1.UpdateDate,
	t1.ActiveInd
FROM
	Blog t1
	INNER JOIN ApplicationUser t2 ON t1.ApplicationUserId = t2.ApplicationUserId;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE VIEW [aggregate].BlogComment AS
SELECT
	t1.BlogCommentId,
	t1.ParentBlogCommentId,
	t1.BlogId,
	t1.Content,
	t2.Username,
	t1.ApplicationUserId,
	t1.PublishDate,
	t1.UpdateDate,
	t1.ActiveInd
FROM
	BlogComment t1
	INNER JOIN ApplicationUser t2 ON t1.ApplicationUserId = t2.ApplicationUserId;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE
OR REPLACE FUNCTION Account_GetByUsername (p_NormalizedUsername VARCHAR(20)) RETURNS VOID AS $ $ BEGIN -- SQLINES LICENSE FOR EVALUATION USE ONLY
SELECT
	ApplicationUserId,
	Username,
	NormalizedUsername,
	Email,
	NormalizedEmail,
	Fullname,
	PasswordHash
FROM
	ApplicationUser t1
WHERE
	t1.NormalizedUsername = p_NormalizedUsername;

END;

$ $ LANGUAGE plpgsql;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE
OR REPLACE FUNCTION Account_Insert (p_Account AccountType) RETURNS VOID AS $ $ BEGIN READONLY AS -- SQLINES LICENSE FOR EVALUATION USE ONLY
INSERT INTO
	ApplicationUser (
		Username,
		NormalizedUsername,
		Email,
		NormalizedEmail,
		Fullname,
		PasswordHash
	)
SELECT
	Username,
	NormalizedUsername,
	Email,
	NormalizedEmail,
	Fullname,
	PasswordHash
FROM
	@Account;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
SELECT
	CAST(SCOPE_IDENTITY() AS INT);

END;

$ $ LANGUAGE plpgsql;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE
OR REPLACE FUNCTION Blog_Delete (p_BlogId INT) RETURNS VOID AS $ $ BEGIN
UPDATE
	BlogComment
SET
	ActiveInd = CONVERT(
		BIT,
		0;

),
UpdateDate = NOW()
WHERE
	BlogId = p_BlogId;

UPDATE
	Blog
SET
	PhotoId = NULL,
	ActiveInd = CONVERT(
		BIT,
		0;

),
UpdateDate = NOW()
WHERE
	BlogId = p_BlogId
END;

$ $ LANGUAGE plpgsql;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE
OR REPLACE FUNCTION Blog_Get (p_BlogId INT) RETURNS VOID AS $ $ BEGIN -- SQLINES LICENSE FOR EVALUATION USE ONLY
SELECT
	BlogId,
	ApplicationUserId,
	Username,
	Title,
	Content,
	PhotoId,
	PublishDate,
	UpdateDate
FROM
	[aggregate].Blog t1
WHERE
	t1.BlogId = p_BlogId
	AND t1.ActiveInd = CONVERT(BIT, 1)
END;

$ $ LANGUAGE plpgsql;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE
OR REPLACE FUNCTION Blog_GetAll (p_Offset INT, p_PageSize INT) RETURNS VOID AS $ $ BEGIN -- SQLINES LICENSE FOR EVALUATION USE ONLY
SELECT
	BlogId,
	ApplicationUserId,
	Username,
	Title,
	Content,
	PhotoId,
	PublishDate,
	UpdateDate
FROM
	[aggregate].Blog t1
WHERE
	t1.ActiveInd = CONVERT(BIT, 1)
ORDER BY
	t1.BlogId OFFSET p_Offset ROWS FETCH NEXT @PageSize ROWS;

ONLY;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
SELECT
	COUNT(*)
FROM
	[aggregate].Blog t1
WHERE
	t1.ActiveInd = CONVERT(BIT, 1);

END;

$ $ LANGUAGE plpgsql;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE
OR REPLACE FUNCTION Blog_GetAllFamous() RETURNS VOID AS $ $ BEGIN -- SQLINES LICENSE FOR EVALUATION USE ONLY
SELECT
	t1.BlogId,
	t1.ApplicationUserId,
	t1.Username,
	t1.PhotoId,
	t1.Title,
	t1.Content,
	t1.PublishDate,
	t1.UpdateDate
FROM
	[aggregate].Blog t1
	INNER JOIN BlogComment t2 ON t1.BlogId = t2.BlogId
WHERE
	t1.ActiveInd = CONVERT(
		BIT
		LIMIT
			6, 1
	)
	AND t2.ActiveInd = CONVERT(BIT, 1)
GROUP BY
	t1.BlogId,
	t1.ApplicationUserId,
	t1.Username,
	t1.PhotoId,
	t1.Title,
	t1.Content,
	t1.PublishDate,
	t1.UpdateDate
ORDER BY
	COUNT(t2.BlogCommentId) DESC
END;

$ $ LANGUAGE plpgsql;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE
OR REPLACE FUNCTION Blog_GetByUserId (p_ApplicationUserId INT) RETURNS VOID AS $ $ BEGIN -- SQLINES LICENSE FOR EVALUATION USE ONLY
SELECT
	BlogId,
	ApplicationUserId,
	Username,
	Title,
	Content,
	PhotoId,
	PublishDate,
	UpdateDate
FROM
	[aggregate].Blog t1
WHERE
	t1.ApplicationUserId = p_ApplicationUserId
	AND t1.ActiveInd = CONVERT(BIT, 1)
END;

$ $ LANGUAGE plpgsql;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE
OR REPLACE FUNCTION Blog_Upsert (p_Blog BlogType) RETURNS VOID AS $ $ BEGIN READONLY,
@ApplicationUserId INT AS MERGE INTO Blog TARGET USING (
	SELECT
		BlogId,
		@ApplicationUserId ApplicationUserId,
		Title,
		Content,
		PhotoId
	FROM
		@Blog
) AS SOURCE ON (
	TARGET.BlogId = SOURCE.BlogId
	AND TARGET.ApplicationUserId = SOURCE.ApplicationUserId
)
WHEN MATCHED THEN
UPDATE
SET
	TARGET.[Title] = SOURCE.Title,
	TARGET.[Content] = SOURCE.Content,
	TARGET.[PhotoId] = SOURCE.PhotoId,
	TARGET.[UpdateDate] = NOW();

WHEN NOT MATCHED BY TARGET THEN -- SQLINES LICENSE FOR EVALUATION USE ONLY
INSERT
	(
		ApplicationUserId,
		Title,
		Content,
		PhotoId
	)
VALUES
	(
		SOURCE.ApplicationUserId,
		SOURCE.Title,
		SOURCE.Content,
		SOURCE.PhotoId
	);

-- SQLINES LICENSE FOR EVALUATION USE ONLY
SELECT
	CAST(SCOPE_IDENTITY() AS INT);

END;

$ $ LANGUAGE plpgsql;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE
OR REPLACE FUNCTION BlogComment_Delete (p_BlogCommentId INT) RETURNS VOID AS $ $ BEGIN DROP TABLE IF EXISTS #BlogCommentsToBeDeleted;
-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE TEMPORARY TABLE tmp_BlogCommentsToBeDeleted AS WITH cte_blogComments AS (
	SELECT
		t1.BlogCommentId,
		t1.ParentBlogCommentId
	FROM
		BlogComment t1
	WHERE
		t1.BlogCommentId = p_BlogCommentId
	UNION
	ALL
	SELECT
		t2.BlogCommentId,
		t2.ParentBlogCommentId
	FROM
		BlogComment t2
		INNER JOIN cte_blogComments t3 ON t3.BlogCommentId = t2.ParentBlogCommentId
)
SELECT
	BlogCommentId,
	ParentBlogCommentId
FROM
	cte_blogComments;

UPDATE
	t1
SET
	t1.[ActiveInd] = CONVERT(
		BIT,
		0;

),
t1.UpdateDate = NOW()
FROM
	dbo.BlogComment t1
	INNER JOIN #BlogCommentsToBeDeleted t2
	ON t1.[BlogCommentId] = t2.BlogCommentId;

END;

$ $ LANGUAGE plpgsql;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE
OR REPLACE FUNCTION BlogComment_Get (p_BlogCommentId INT) RETURNS VOID AS $ $ BEGIN -- SQLINES LICENSE FOR EVALUATION USE ONLY
SELECT
	t1.BlogCommentId,
	t1.ParentBlogCommentId,
	t1.BlogId,
	t1.ApplicationUserId,
	t1.Username,
	t1.Content,
	t1.PublishDate,
	t1.UpdateDate
FROM
	[aggregate].BlogComment t1
WHERE
	t1.BlogCommentId = p_BlogCommentId
	AND t1.ActiveInd = CONVERT(BIT, 1)
END;

$ $ LANGUAGE plpgsql;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE
OR REPLACE FUNCTION BlogComment_GetAll (p_BlogId INT) RETURNS VOID AS $ $ BEGIN -- SQLINES LICENSE FOR EVALUATION USE ONLY
SELECT
	t1.BlogCommentId,
	t1.ParentBlogCommentId,
	t1.BlogId,
	t1.ApplicationUserId,
	t1.Username,
	t1.Content,
	t1.PublishDate,
	t1.UpdateDate
FROM
	[aggregate].BlogComment t1
WHERE
	t1.BlogId = p_BlogId
	AND t1.ActiveInd = CONVERT(BIT, 1)
ORDER BY
	t1.UpdateDate DESC
END;

$ $ LANGUAGE plpgsql;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE
OR REPLACE FUNCTION BlogComment_Upsert (p_BlogComment BlogCommentType) RETURNS VOID AS $ $ BEGIN READONLY,
@ApplicationUserId INT AS MERGE INTO BlogComment TARGET USING (
	SELECT
		BlogCommentId,
		ParentBlogCommentId,
		BlogId,
		Content,
		@ApplicationUserId ApplicationUserId
	FROM
		@BlogComment
) AS SOURCE ON (
	TARGET.BlogCommentId = SOURCE.BlogCommentId
	AND TARGET.ApplicationUserId = SOURCE.ApplicationUserId
)
WHEN MATCHED THEN
UPDATE
SET
	TARGET.[Content] = SOURCE.Content,
	TARGET.[UpdateDate] = NOW();

WHEN NOT MATCHED BY TARGET THEN -- SQLINES LICENSE FOR EVALUATION USE ONLY
INSERT
	(
		ParentBlogCommentId,
		BlogId,
		ApplicationUserId,
		Content
	)
VALUES
	(
		SOURCE.ParentBlogCommentId,
		SOURCE.BlogId,
		SOURCE.ApplicationUserId,
		SOURCE.Content
	);

-- SQLINES LICENSE FOR EVALUATION USE ONLY
SELECT
	CAST(SCOPE_IDENTITY() AS INT);

END;

$ $ LANGUAGE plpgsql;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE
OR REPLACE FUNCTION Photo_Delete (p_PhotoId INT) RETURNS VOID AS $ $ BEGIN
DELETE FROM
	dbo.Photo
WHERE
	PhotoId = p_PhotoId;

END;

$ $ LANGUAGE plpgsql;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE
OR REPLACE FUNCTION Photo_Get (p_PhotoId INT) RETURNS VOID AS $ $ BEGIN -- SQLINES LICENSE FOR EVALUATION USE ONLY
SELECT
	t1.PhotoId,
	t1.ApplicationUserId,
	t1.PublicId,
	t1.ImageUrl,
	t1.Description,
	t1.PublishDate,
	t1.UpdateDate
FROM
	Photo t1
WHERE
	t1.PhotoId = p_PhotoId;

END;

$ $ LANGUAGE plpgsql;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE
OR REPLACE FUNCTION Photo_GetByUserId (p_ApplicationUserId INT) RETURNS VOID AS $ $ BEGIN -- SQLINES LICENSE FOR EVALUATION USE ONLY
SELECT
	t1.PhotoId,
	t1.ApplicationUserId,
	t1.PublicId,
	t1.ImageUrl,
	t1.Description,
	t1.PublishDate,
	t1.UpdateDate
FROM
	Photo t1
WHERE
	t1.ApplicationUserId = p_ApplicationUserId;

END;

$ $ LANGUAGE plpgsql;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE
OR REPLACE FUNCTION Photo_Insert (p_Photo PhotoType) RETURNS VOID AS $ $ BEGIN READONLY,
@ApplicationUserId INT AS -- SQLINES LICENSE FOR EVALUATION USE ONLY
INSERT INTO
	Photo (
		ApplicationUserId,
		PublicId,
		ImageUrl,
		Description
	)
SELECT
	@ApplicationUserId,
	PublicId,
	ImageUrl,
	Description
FROM
	@Photo;

-- SQLINES LICENSE FOR EVALUATION USE ONLY
SELECT
	CAST(SCOPE_IDENTITY() AS INT);

END;

$ $ LANGUAGE plpgsql;