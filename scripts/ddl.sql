-- Crear la base de datos si no existe
    CREATE DATABASE Financial_accounting;
   USE Financial_accounting;

-- Crear tabla para importar el CSV financiero
IF OBJECT_ID('dbo.financial_accounting', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.financial_accounting;
END
GO

CREATE TABLE dbo.financial_accounting (
    [Date] DATE NOT NULL,
    [Account] NVARCHAR(100) NOT NULL,
    [Description] NVARCHAR(200) NOT NULL,
    [Debit] DECIMAL(12,2) NOT NULL,
    [Credit] DECIMAL(12,2) NOT NULL,
    [Category] NVARCHAR(50) NOT NULL,
    [Transaction_Type] NVARCHAR(50) NOT NULL,
    [Customer_Vendor] NVARCHAR(100) NOT NULL,
    [Payment_Method] NVARCHAR(50) NOT NULL,
    [Reference] INT NOT NULL
);
--IMPORTANDO DATOS DEL CSV
BULK INSERT financial_accounting
FROM 'C:\Users\david\Documents\SQL-Server-Financial-Analytics\DATA\financial_accounting.csv'
WITH (
    FORMAT = 'CSV',
	FIRSTROW = 2 ,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'

SELECT * 
FROM Financial_accounting ;


