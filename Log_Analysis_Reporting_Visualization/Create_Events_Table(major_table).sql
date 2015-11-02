USE [LogDB]
GO
CREATE TABLE [dbo].[EVENTS](
	[Id] [bigint] IDENTITY(1,1) PRIMARY KEY NOT NULL,
	[EventId] [int] NULL,
	[EventVersion] [nvarchar](max) NULL,
	[EventLevel] [nvarchar](max) NULL,
	[Task] [nvarchar](max) NULL,
	[OpCode] [int] NULL,
	[Keywords] [bigint] NULL,
	[EventRecordId] [int] NULL,
	[ProviderName] [nvarchar](max) NULL,
	[ProviderId] [nvarchar](max) NOT NULL,
	[LogName] [nvarchar](max) NULL,
	[ProcessId] [int] NULL,
	[ThreadId] [bigint] NULL,
	[MachineName] [nvarchar](max) NULL,
	[TimeCreated] [nvarchar](max) NULL,
	[LevelDisplayName] [nvarchar](max) NULL,
	[OpcodeDisplayName] [nvarchar](max) NULL,
	[TaskDisplayName] [nvarchar](max) NULL,
	[KeywordsDisplayNames] [nvarchar](max) NULL,
	[Message] [nvarchar](max) NULL
)