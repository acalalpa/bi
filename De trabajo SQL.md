# bi
/****** Object:  StoredProcedure [qmr].[qmr_cargar_liquidaciones]    Script Date: 15/03/2023 11:11:15 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- qmr_cargar_liquidaciones '2020Q2'
-- qmr_cargar_liquidaciones '2020Q3'
-- qmr_cargar_liquidaciones '2020Q4'
-- truncate table   qmr.liquidaciones


ALTER  PROCEDURE [qmr].[qmr_cargar_liquidaciones] ( @trim CHAR(6))

AS
BEGIN
	IF  (SELECT COUNT(1)  FROM qmr.liquidaciones WHERE TrimestreQ = @trim) >0
    
		SELECT 'Ya Existe';
	ELSE
		INSERT INTO   qmr.liquidaciones 
		SELECT 
		bp.id AS IdLiquidacion,
		'K175' AS Producto,
		TRY_CONVERT(DATE,bp.fecha) AS Fecha,
		CONCAT(YEAR( bp.fecha), tr.Inicio ) AS Trimestre ,
		TRY_CONVERT(CHAR(6),CONCAT(YEAR(bp.fecha), 'Q', DATEPART(QUARTER,(bp.fecha)))) AS TrimestreQ,
		bp.transacciones AS Transacciones,
		ABS(bp.importe_ventas) AS Importe,
		bp.folio AS Folio,
		IIF(bp.liquidacion_comercio > 0, 'LIQUIDACION', 'DEVOLUCION') AS Tipo,
		UPPER(TRIM(bp.comercio)) AS Comercio
		FROM broxelco_rdg.bp_detalle_diario_comercio AS bp WITH(NOLOCK)
		inner JOIN   qmr.trimDetail tr WITH (NOLOCK) on MONTH(bp.fecha)=tr.Mes
		WHERE ABS(bp.liquidacion_comercio) > 0
		AND CAST(CONCAT(YEAR(bp.fecha), 'Q', DATEPART(QUARTER,(bp.fecha))) AS CHAR(6)) =@trim;

        
        SELECT 'Datos insertados';
    END 

	-- select * from qmr.liquidaciones WHERE TrimestreQ='2020Q4'
	--select * from qmr.trimDetail 
	-- SELECT * FROM ##LIQUIDATEMP WITH (NOLOCK)
