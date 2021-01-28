CREATE DATABASE streamsetsdays;
GO
​
USE streamsetsdays;
GO
​
CREATE TABLE streamsetsdays.dbo.CUSTOMER (
	ID int NOT NULL,
	FNAME varchar(20),
	LNAME varchar(20),
	ADDRESS varchar(50),
	CITY varchar(20),
	STATE varchar(20),
	CONSTRAINT PK__CUSTOMER__3214EC2712A0926E PRIMARY KEY (ID)
);
GO
​
CREATE TABLE streamsetsdays.dbo.EMPLOYEE (
	ID int NOT NULL,
	FNAME varchar(10),
	LNAME varchar(10),
	REGION varchar(2),
	DEPT varchar(2),
	CONSTRAINT PK__EMPLOYEE__3214EC275FE99F0A PRIMARY KEY (ID)
);
GO

​/* This code turns on CDC capture */
/*
EXEC sys.sp_cdc_enable_db
EXEC sys.sp_cdc_enable_table
@SOURCE_SCHEMA=N'dbo',
@SOURCE_NAME=N'EMPLOYEE',
@CAPTURE_INSTANCE=N'dbo_EMPLOYEE',
@ROLE_NAME=NULL,
@supports_net_changes = 1
GO
*/
