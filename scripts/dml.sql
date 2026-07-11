---Verificar valores faltantes en columnas clave
SELECT 
    SUM(CASE WHEN [Date] IS NULL THEN 1 ELSE 0 END) AS Nulos_Date,
    SUM(CASE WHEN [Account] IS NULL THEN 1 ELSE 0 END) AS Nulos_Account,
    SUM(CASE WHEN [Debit] IS NULL THEN 1 ELSE 0 END) AS Nulos_Debit,
    SUM(CASE WHEN [Credit] IS NULL THEN 1 ELSE 0 END) AS Nulos_Credit,
    SUM(CASE WHEN [Category] IS NULL THEN 1 ELSE 0 END) AS Nulos_Category,
    SUM(CASE WHEN [Customer_Vendor] IS NULL THEN 1 ELSE 0 END) AS Nulos_Cliente,
    SUM(CASE WHEN [Reference] IS NULL THEN 1 ELSE 0 END) AS Nulos_Reference
FROM dbo.financial_accounting;

----- Verificar valores duplicados en la tabla financial_accounting 
SELECT [Reference], COUNT(*) AS Cantidad
FROM dbo.financial_accounting
GROUP BY [Reference]
HAVING COUNT(*) > 1;

--Pregunta 1: ¿Cuánto se ha transaccionado (débito y crédito) en cada categoría de cuenta?

-- Distribución de montos por categoría de cuenta --

SELECT 
    Category,
    COUNT(*) AS Total_Transacciones,
    SUM(Debit) AS Total_Debito,
    SUM(Credit) AS Total_Credito
FROM dbo.financial_accounting
GROUP BY Category
ORDER BY Total_Debito DESC;

--Pregunta 2: ¿Cuál es el método de pago más usado, y cuál mueve más dinero?

-- Método de pago más usado y monto total movido --

SELECT 
    Payment_Method,
    COUNT(*) AS Total_Transacciones,
    SUM(Debit) AS Monto_Total
FROM dbo.financial_accounting
GROUP BY Payment_Method
ORDER BY Monto_Total DESC;

---Pregunta 3: ¿Quiénes son los 10 clientes/proveedores con mayor monto acumulado?

-- Top 10 clientes/proveedores por monto acumulado --

SELECT TOP 10
    Customer_Vendor,
    COUNT(*) AS Total_Transacciones,
    SUM(Debit) AS Monto_Total
FROM dbo.financial_accounting
GROUP BY Customer_Vendor
ORDER BY Monto_Total DESC;

--Pregunta 4: ¿Cuánto se mueve en Ventas, Compras y Transferencias?

-- Monto total y transacciones por tipo 

SELECT 
    Transaction_Type,
    COUNT(*) AS Total_Transacciones,
    SUM(Debit) AS Monto_Total
FROM dbo.financial_accounting
GROUP BY Transaction_Type
ORDER BY Monto_Total DESC;

--Pregunta 5: ¿Cuántas transacciones son "altas", "medias" o "bajas" según su monto?

-- Clasificación de transacciones por tamaño de monto 

SELECT 
    CASE 
        WHEN Debit >= 700 THEN 'Alta'
        WHEN Debit >= 300 THEN 'Media'
        ELSE 'Baja'
    END AS Rango_Monto,
    COUNT(*) AS Total_Transacciones,
    SUM(Debit) AS Monto_Total
FROM dbo.financial_accounting
GROUP BY 
    CASE 
        WHEN Debit >= 700 THEN 'Alta'
        WHEN Debit >= 300 THEN 'Media'
        ELSE 'Baja'
    END
ORDER BY Monto_Total DESC;

--Pregunta 6: ¿Cómo varía el monto transaccionado mes a mes? ¿Cuál fue el mes más fuerte?

-- Tendencia mensual de monto transaccionado 

SELECT 
    FORMAT([Date], 'yyyy-MM') AS Mes,
    COUNT(*) AS Total_Transacciones,
    SUM(Debit) AS Monto_Total
FROM dbo.financial_accounting
GROUP BY FORMAT([Date], 'yyyy-MM')
ORDER BY Mes ASC;

--Pregunta 7: ¿Qué porcentaje del total representa cada categoría de cuenta?

-- Participación porcentual de cada categoría sobre el total --

SELECT 
    Category,
    SUM(Debit) AS Monto_Categoria,
    SUM(SUM(Debit)) OVER () AS Monto_Total_General,
    ROUND(
        SUM(Debit) * 100.0 / SUM(SUM(Debit)) OVER (), 2
    ) AS Porcentaje
FROM dbo.financial_accounting
GROUP BY Category
ORDER BY Porcentaje DESC;

--Pregunta 8: Dentro de cada categoría, ¿quiénes son los 3 clientes/proveedores más grandes?

-- Top 3 clientes/proveedores por categoría de cuenta --

WITH RankedClientes AS (
    SELECT 
        Category,
        Customer_Vendor,
        SUM(Debit) AS Monto_Total,
        RANK() OVER (PARTITION BY Category ORDER BY SUM(Debit) DESC) AS Ranking
    FROM dbo.financial_accounting
    GROUP BY Category, Customer_Vendor
)
SELECT *
FROM RankedClientes
WHERE Ranking <= 3
ORDER BY Category, Ranking;

--Pregunta 9 : ¿El 10% de los clientes/proveedores más grandes concentra la mayoría del dinero transaccionado?

-- Concentración de riesgo: % del monto en manos del 10% de clientes más grandes --

WITH MontoPorCliente AS (
    SELECT 
        Customer_Vendor,
        SUM(Debit) AS Monto_Total
    FROM dbo.financial_accounting
    GROUP BY Customer_Vendor
),
Deciles AS (
    SELECT 
        Customer_Vendor,
        Monto_Total,
        NTILE(10) OVER (ORDER BY Monto_Total DESC) AS Decil
    FROM MontoPorCliente
)
SELECT 
    CASE WHEN Decil = 1 THEN 'Top 10%' ELSE 'Resto (90%)' END AS Grupo,
    COUNT(*) AS Cantidad_Clientes,
    SUM(Monto_Total) AS Monto_Grupo,
    ROUND(SUM(Monto_Total) * 100.0 / SUM(SUM(Monto_Total)) OVER (), 2) AS Porcentaje_Del_Total
FROM Deciles
GROUP BY CASE WHEN Decil = 1 THEN 'Top 10%' ELSE 'Resto (90%)' END;

--Pregunta 10: ¿Hay clientes/proveedores cuyo comportamiento se aleja mucho del promedio de su categoría?

-- Top 15 clientes/proveedores más atípicos respecto al promedio de su categoría 

WITH PromedioPorTransaccion AS (
    SELECT 
        Category,
        Customer_Vendor,
        AVG(Debit) AS Promedio_Cliente,
        AVG(AVG(Debit)) OVER (PARTITION BY Category) AS Promedio_Categoria
    FROM dbo.financial_accounting
    GROUP BY Category, Customer_Vendor
)
SELECT TOP 15
    Category,
    Customer_Vendor,
    ROUND(Promedio_Cliente, 2) AS Promedio_Cliente,
    ROUND(Promedio_Categoria, 2) AS Promedio_Categoria,
    ROUND(Promedio_Cliente - Promedio_Categoria, 2) AS Diferencia,
    ROUND((Promedio_Cliente - Promedio_Categoria) * 100.0 / Promedio_Categoria, 2) AS Porcentaje_Desviacion
FROM PromedioPorTransaccion
ORDER BY ABS(Promedio_Cliente - Promedio_Categoria) DESC;

--Pregunta 11: Mes a mes, ¿el ingreso (Revenue) superó al gasto (Expense), o fue al revés?
-- Comparativa Revenue vs Expense por mes --

WITH ResumenMensual AS (
    SELECT 
        FORMAT([Date], 'yyyy-MM') AS Mes,
        SUM(CASE WHEN Category = 'Revenue' THEN Debit ELSE 0 END) AS Total_Revenue,
        SUM(CASE WHEN Category = 'Expense' THEN Debit ELSE 0 END) AS Total_Expense
    FROM dbo.financial_accounting
    GROUP BY FORMAT([Date], 'yyyy-MM')
)
SELECT 
    Mes,
    Total_Revenue,
    Total_Expense,
    Total_Revenue - Total_Expense AS Resultado_Neto,
    CASE 
        WHEN Total_Revenue > Total_Expense THEN 'Ganancia'
        WHEN Total_Revenue < Total_Expense THEN 'Pérdida'
        ELSE 'Equilibrio'
    END AS Estado
FROM ResumenMensual
ORDER BY Mes ASC;
