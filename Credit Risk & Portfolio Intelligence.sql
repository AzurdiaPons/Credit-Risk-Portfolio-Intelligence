/* 
   PROYECTO: Credit Risk & Portfolio Intelligence
   OBJETIVO: Consultas de análisis de mora, segmentación y reporte ejecutivo
   AUTOR: Julio Azurdia
*/

USE BancaSegundoPiso;
GO

-- 1. Reporte Ejecutivo: Visión General (¿Cuánto dinero hemos colocado y qué tan diversificados estamos?)
SELECT 
    i.Sector,
    COUNT(c.ID_Credito) AS Cantidad_Creditos,
    SUM(c.Monto_Otorgado) AS Total_Colocado,
    AVG(c.Tasa_Interes) AS Tasa_Promedio
FROM Instituciones AS i
JOIN Creditos AS c ON i.ID_Institucion = c.ID_Institucion
GROUP BY i.Sector
ORDER BY Total_Colocado DESC;
GO

-- 2. El "Semáforo" de Riesgo: Análisis de Mora
SELECT 
    i.Sector,
    SUM(c.Monto_Otorgado) AS Cartera_Total,
    SUM(CASE WHEN P.Estado_pago = 'Vencido' THEN P.Monto_Cuota ELSE 0 END) AS Total_Vencido,
    (SUM(CASE WHEN P.Estado_pago = 'Vencido' THEN P.Monto_Cuota ELSE 0 END) / NULLIF(SUM(c.Monto_Otorgado), 0)) * 100 AS Indice_Mora_Porcentaje
FROM Instituciones AS i
JOIN Creditos AS c ON i.ID_Institucion = c.ID_Institucion
JOIN Pagos AS P ON c.ID_Credito = P.ID_Credito
GROUP BY i.Sector
ORDER BY Indice_Mora_Porcentaje;
GO

-- 3. Instituciones en Alerta
SELECT TOP 5
    i.Nombre,
    i.Calificacion_Riesgo,
    SUM(p.Monto_Cuota) AS Saldo_Vencido_Acumulado
FROM Instituciones i 
JOIN Creditos c ON i.ID_Institucion = c.ID_Institucion
JOIN Pagos p ON c.ID_Credito = p.ID_Credito
WHERE p.Estado_Pago = 'Vencido'
GROUP BY i.Nombre, i.Calificacion_Riesgo
ORDER BY Saldo_Vencido_Acumulado DESC;
GO

-- 4. Segmentación de Riesgo
SELECT 
    Nombre,
    Calificacion_Riesgo,
    Saldo_Vencido_Acumulado,
    CASE 
        WHEN Saldo_Vencido_Acumulado > 9500 THEN 'CRITICO - Acción Inmediata'
        WHEN Saldo_Vencido_Acumulado BETWEEN 9000 AND 9500 THEN 'ALERTA - Seguimiento'
        ELSE 'CONTROL - Revisión Rutinaria'
    END AS Nivel_Urgencia
FROM (
    SELECT TOP 5
        i.Nombre,
        i.Calificacion_Riesgo,
        SUM(p.Monto_Cuota) AS Saldo_Vencido_Acumulado
    FROM Instituciones i
    JOIN Creditos c ON i.ID_Institucion = c.ID_Institucion
    JOIN Pagos p ON c.ID_Credito = p.ID_Credito
    WHERE p.Estado_Pago = 'Vencido'
    GROUP BY i.Nombre, i.Calificacion_Riesgo
) AS Resumen_Mora
ORDER BY Saldo_Vencido_Acumulado DESC;
GO