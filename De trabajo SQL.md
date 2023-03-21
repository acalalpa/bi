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
	
	;
	
	SELECT 
YEAR(C.Fecha) as Year,
MONTH(C.Fecha) as Month,
C.comercio,
CC.Razon_Social,
C.folioFactura,
SUM(liquidacion_comercio) as Liquidacion,
--SUM(liquidacion_comercio) OVER (Partition By C.comercio,YEAR(C.Fecha),MONTH(C.Fecha)) AS Mensual,
P.IdProducto,
CASE WHEN C.envioPago is not null THEN 'Facturado' Else 'Pendiente' END AS Estatus
FROM broxelco_rdg.bp_detalle_diario_comercio (NoLock) C
LEFT JOIN [broxelco_rdg].[Comercio] (NoLock) CC
ON C.comercio = CC.comercio
LEFT JOIN Broxelco_rdg.Programas P
ON C.idPrograma = P.IdProgramas
where YEAR(C.Fecha) in ('2020') 
AND  C.folioFactura is not null
--and C.envioPago = 1 
--AND  C.comercio = '22CBX00567'
--AND CC.Razon_Social like '%desarrollo%'
GROUP BY C.comercio,C.folioFactura,CC.Razon_Social,YEAR(C.Fecha),C.Producto,liquidacion_comercio,MONTH(C.Fecha),P.IdProducto,CASE WHEN C.envioPago is not null THEN 'Facturado' Else 'Pendiente' END
Order By YEAR(C.Fecha) asc

;
SELECT TOP(100) * 
FROM broxelco_rdg.bp_detalle_diario_comercio
WHERE YEAR(Fecha) = '2023'
;
SELECT TOP(100) * FROM broxelco_rdg.maquila 
where clave_cliente = '22CBX00567'

;

SELECT TOP (100) *
FROM [qmr].[qmr_cargar_liquidaciones]


SELECT Top(100)* FROM broxelco_rdg.DetalleClientesBroxel

;

/****** Object:  StoredProcedure [qmr].[qmr_resumen_trimestral]    Script Date: 15/03/2023 11:14:47 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--qmr.qmr_resumen_trimestral '2021Q1'



ALTER PROCEDURE [qmr].[qmr_resumen_trimestral] (@TRIM char(6))
AS
BEGIN
SET NOCOUNT ON
--DECLARE @TRIM CHAR(6) = '2020Q4'
  DECLARE @INICIO datetime,
          @FINAL datetime
  IF  (SELECT COUNT(1)  FROM QMR.QMR WITH (NOLOCK)where Trimestre=@TRIM)> 0
			select    'Ya Existe'
  IF  (SELECT COUNT(1)  FROM QMR.QMR WITH (NOLOCK)where Trimestre=@TRIM)= 0 
BEGIN
SELECT 'INICIAMOS LLENADO PLANILLA'
INSERT INTO qmr.qmr
 SELECT  
      @TRIM AS TRIMESTRE,
      PRODUCTOS.PRODUCTO,
      PRODUCTOS.GRUPO,
      CONCEPTOS.ID AS IDCONCEPTO,
      CONCEPTOS.CATEGORIA,
      CONCEPTOS.CONCEPTO,
        SUM( IIF( transacciones.ID is not null, 1, 0 ) ) AS Transacciones,
        SUM( IIF( transacciones.Id is not null , ABS( transacciones.Importe ), 0.0 ) ) AS VolumenMoneda,
		SUM( IIF( transacciones.Id is not null, ABS( transacciones.ImportePesos ), 0.0 ) ) AS Volumen,
      0 AS ABIERTAS,
      0 AS BLOQUEADAS,
      0 AS TOTAL
    FROM QMR.PRODUCTOS  WITH (NOLOCK)
    INNER JOIN QMR.CONCEPTOS  WITH (NOLOCK)
      ON 1 = 1
    LEFT JOIN qmr.REGLAS   WITH (NOLOCK)
      ON CONCEPTOS.ID = REGLAS.ID AND  REGLAS.tipo=1
    LEFT JOIN (SELECT
      MOVIMIENTOS.IDMOVIMIENTO AS ID,
      MOVIMIENTOS.PRODUCTO AS PRODUCTO,
      MOVIMIENTOS.CUENTA AS CUENTA,
      MOVIMIENTOS.TIPO AS TIPO,
      MOVIMIENTOS.MONEDA AS MONEDA,
      MOVIMIENTOS.COMERCIO AS COMERCIO,
      MOVIMIENTOS.IMPORTE AS IMPORTE,
      MOVIMIENTOS.IMPORTEPESOS AS IMPORTEPESOS
    FROM RECURSOS.MOVIMIENTOS WITH (NOLOCK)
    LEFT JOIN RECURSOS.COMERCIOS_ADMIN  WITH (NOLOCK)
      ON MOVIMIENTOS.COMERCIO = COMERCIOS_ADMIN.COMERCIO
    WHERE MOVIMIENTOS.ESTATUS = 'APROBADA'
    AND MOVIMIENTOS.TRIMESTREQ = @TRIM
    AND MOVIMIENTOS.TIPO != ''
    AND COMERCIOS_ADMIN.COMERCIO IS NULL) AS TRANSACCIONES
      ON PRODUCTOS.PRODUCTO = TRANSACCIONES.PRODUCTO
      AND REGLAS.TIPOTRANS = TRANSACCIONES.TIPO
      AND REGLAS.MONEDATRANS = TRANSACCIONES.MONEDA
    WHERE PRODUCTOS.PRODUCTO <> 'K175'
    GROUP BY PRODUCTOS.PRODUCTO,
             PRODUCTOS.GRUPO,
             CONCEPTOS.CATEGORIA,
			 CONCEPTOS.ID,
             CONCEPTOS.CONCEPTO   	



SELECT 'INICIAMOS LLENADO SEGUNDA PLANILLA'
INSERT INTO qmr.qmr
   SELECT
      @TRIM AS TRIMESTRE,
      PRODUCTOS.PRODUCTO,
      PRODUCTOS.GRUPO,
      CONCEPTOS.ID AS IDCONCEPTO,
      CONCEPTOS.CATEGORIA,
      CONCEPTOS.CONCEPTO,
  		SUM( IIF( transacciones.Id is not null, transacciones.Transacciones, 0 ) ) AS Transacciones,
		SUM( IIF( transacciones.Id is not null , transacciones.Importe, 0.0 ) ) AS VolumenMoneda,
        SUM( IIF( transacciones.Id is not null, transacciones.Importe, 0.0 ) ) AS Volumen,
      0 AS ABIERTAS,
      0 AS BLOQUEADAS,
      0 AS TOTAL
    FROM QMR.PRODUCTOS  WITH (NOLOCK)
    INNER JOIN QMR.CONCEPTOS  WITH (NOLOCK)
      ON 1 = 1
    LEFT JOIN qmr.REGLAS  WITH (NOLOCK)
      ON CONCEPTOS.ID = REGLAS.ID AND tipo =2
    LEFT JOIN (SELECT
      LIQUIDACIONES.IDLIQUIDACION AS ID,
      LIQUIDACIONES.PRODUCTO,
      LIQUIDACIONES.TRANSACCIONES,
      LIQUIDACIONES.IMPORTE,
      LIQUIDACIONES.TIPO,
      LIQUIDACIONES.COMERCIO
    FROM QMR.LIQUIDACIONES  WITH (NOLOCK)
    LEFT JOIN RECURSOS.COMERCIOS_ADMIN  WITH (NOLOCK)
      ON LIQUIDACIONES.COMERCIO = COMERCIOS_ADMIN.COMERCIO
    WHERE LIQUIDACIONES.TRIMESTREQ = @TRIM
    AND COMERCIOS_ADMIN.COMERCIO IS NULL) AS TRANSACCIONES
      ON PRODUCTOS.PRODUCTO = TRANSACCIONES.PRODUCTO
      AND REGLAS.TIPOTRANS = TRANSACCIONES.TIPO
    WHERE PRODUCTOS.PRODUCTO = 'K175'
    GROUP BY 
             PRODUCTOS.PRODUCTO,
             PRODUCTOS.GRUPO,
			  CONCEPTOS.ID,
             CONCEPTOS.CATEGORIA,
             CONCEPTOS.CONCEPTO


			




select 'Actualizando en qmr total de cuentas y tarjetas que transaccionaron en el @trimestre'


UPDATE QMR.QMR
  SET QMR.ABIERTAS =
                    CASE
                      WHEN QMR.IDCONCEPTO = 24 THEN CUENTAS_TRANSACCIONARON.CUENTAS
                      WHEN QMR.IDCONCEPTO = 28 THEN CUENTAS_TRANSACCIONARON.TARJETAS
                      ELSE QMR.ABIERTAS END
  FROM (SELECT
    MOVIMIENTOS.TRIMESTREQ AS TRIMESTRE,
    MOVIMIENTOS.PRODUCTO,
    COUNT(DISTINCT MOVIMIENTOS.CUENTA) AS CUENTAS,
    COUNT(DISTINCT CONCAT(MOVIMIENTOS.CUENTA, MOVIMIENTOS.TARJETA)) AS TARJETAS
  FROM RECURSOS.MOVIMIENTOS
  INNER JOIN QMR.PRODUCTOS
    ON MOVIMIENTOS.PRODUCTO = PRODUCTOS.PRODUCTO
  LEFT JOIN RECURSOS.COMERCIOS_ADMIN
    ON MOVIMIENTOS.COMERCIO = COMERCIOS_ADMIN.COMERCIO
  WHERE MOVIMIENTOS.TRIMESTREQ = @TRIM
  AND MOVIMIENTOS.TIPO NOT IN
  (
  '',
  'DEVOLUCION ATM'
  )
  AND COMERCIOS_ADMIN.COMERCIO IS NULL
  GROUP BY MOVIMIENTOS.TRIMESTREQ,
           MOVIMIENTOS.PRODUCTO) AS CUENTAS_TRANSACCIONARON
  WHERE QMR.PRODUCTO = CUENTAS_TRANSACCIONARON.PRODUCTO
  AND QMR.IDCONCEPTO IN
  (
  24,
  28
  )
  AND QMR.TRIMESTRE = @TRIM


  	DECLARE @ANIOTRIM CHAR(4) = (SELECT SUBSTRING(@TRIM,1,4))
	DECLARE @TRIMNUM CHAR(1)=(SELECT SUBSTRING (@TRIM,6,6) AS TRIMD) 
	
	SET @INICIO=( SELECT  top 1 (CONCAT (@ANIOTRIM,Inicio)) from qmr.trimDetail WHERE   Id_trim= @TRIMNUM)
	SET @FINAL=( SELECT  top 1 (CONCAT (@ANIOTRIM,fin)) from qmr.trimDetail WHERE   Id_trim= @TRIMNUM)
	--SELECT  @ANIOTRIM ,@TRIMNUM,@INICIO,@FINAL


	
	
	Declare @Id int =(select Id -1 FROM qmr.trimOrder WHERE TrimDtae=@TRIM)
	Declare @LastTrim varchar (10)= (select isnull(TrimDtae,@TRIM)  from  qmr.trimOrder where Id= @Id )
	select @LastTrim
	drop table if exists ##AccountsendQuarter
	Select Trimestre,Producto,Grupo,IdConcepto,Categoria,Concepto,Total into ##AccountsendQuarter from  qmr.qmr where IdConcepto= '23' and Trimestre= @LastTrim

	update qmr.qmr
	set  Abiertas = AQ.Total  from   ##AccountsendQuarter AQ inner join   qmr.qmr QR 
					on  AQ.Producto=QR.Producto AND AQ.Grupo=QR.Grupo AND AQ.Categoria=QR.Categoria 
					where QR.Trimestre= @TRIM AND qr.IdConcepto=20


		update qmr.qmr
	set  Total = AQ.Total  from   ##AccountsendQuarter AQ inner join   qmr.qmr QR 
					on  AQ.Producto=QR.Producto AND AQ.Grupo=QR.Grupo AND AQ.Categoria=QR.Categoria 
					where QR.Trimestre= @TRIM AND qr.IdConcepto=20

   

   SELECT 'Actualizando en qmr total de cuentas que se dieron de alta y baja'


    UPDATE QMR.QMR
  SET QMR.ABIERTAS =
                    CASE
                      WHEN
                        QMR.IDCONCEPTO = 20 THEN CUENTAS.ALTASANTES - CUENTAS.BAJASANTES
                      WHEN
                        QMR.IDCONCEPTO = 21 THEN CUENTAS.ALTASDURANTE
                      WHEN
                        QMR.IDCONCEPTO = 22 THEN CUENTAS.BAJASDURANTE
                      WHEN
                        QMR.IDCONCEPTO = 23 THEN CUENTAS.ALTASANTES - CUENTAS.BAJASANTES + CUENTAS.ALTASDURANTE - CUENTAS.BAJASDURANTE
                      ELSE QMR.ABIERTAS
                    END
  FROM (SELECT
    CUENTAS.PRODUCTO,
    SUM(IIF(CUENTAS.FECHAALTA < @INICIO, 1, 0)) AS ALTASANTES,
    SUM(IIF(CUENTAS.FECHABAJA < @INICIO, 1, 0)) AS BAJASANTES,
    SUM(IIF(CUENTAS.FECHAALTA BETWEEN @INICIO AND @FINAL, 1, 0)) AS ALTASDURANTE,
    SUM(IIF(CUENTAS.FECHABAJA BETWEEN @INICIO AND @FINAL, 1, 0)) AS BAJASDURANTE
  FROM recursos.CatalogoCuentas CUENTAS
  WHERE CUENTAS.PRODUCTO != 'K175'
  GROUP BY CUENTAS.PRODUCTO) AS CUENTAS
  WHERE QMR.PRODUCTO = CUENTAS.PRODUCTO
  AND QMR.TRIMESTRE = @TRIM
  AND QMR.IDCONCEPTO IN
  (
  20,
  21,
  22,
  23
  )

  ------------------------------------------------------------------------------------------------------------




 SELECT 'ULTIMO UPDATE'

    UPDATE QMR.QMR
  SET QMR.TOTAL = QMR.ABIERTAS + QMR.BLOQUEADAS
  

  


  END

  END
;

  SELECT TOP(100) * FROM recursos.HistoricoMovimientos
  WHERE YEAR(Fecha) = '2021'
  AND MONTH(Fecha) = '1'
  AND Autorizacion = '184898'

  ;

  SELECT TOP(100) * FROM broxelco_rdg.ind_movimientos
  WHERE YEAR(FClear) = '2021'
  AND MONTH(FClear) = '1'
  AND  NroAut = '184898'


  SELECT CC.* 
   FROM [broxelco_rdg].[CC_MOVIMIENTO_ENC] (NoLock) CC
   LEFT JOIN recursos.HistoricoMovimientos (NoLock) His
   ON CC.Id_Secuencia = His.Autorizacion
   LEFT JOIN broxelco_rdg.ind_movimientos (NoLock) Ind
   ON CC.Id_Secuencia = Ind.NroAut
   WHERE CC.Id_Secuencia = '184898'

   ;

SELECT CONVERT(varchar,CC.Id_Secuencia) AS Id
FROM [broxelco_rdg].[CC_MOVIMIENTO_ENC] (NoLock) CC
LEFT JOIN recursos.HistoricoMovimientos (NoLock) His
ON CONVERT(varchar, CC.Id_Secuencia) = CONVERT(varchar, His.Autorizacion)
LEFT JOIN broxelco_rdg.ind_movimientos (NoLock) Ind
ON CONVERT(varchar, CC.Id_Secuencia) = CONVERT(varchar, Ind.NroAut)
WHERE CONVERT(varchar, CC.Id_Secuencia) = '184898'


;

SELECT * FROM sys.procedures WHERE name LIKE '%cierreTransaccionesCredencial%'

(SELECT GETDATE()-38)

;

SELECT
*
FROM  
broxelco_rdg.ind_movimientos with(nolock)   
WHERE FClear> EOMONTH(DATEADD(MONTH, -24, GETDATE())) and FClear<= GETDATE() AND NroRuc IN (SELECT Cuenta FROM recursos.CatalogoCuentas where Cliente = '13BRC00009')


SELECT TOP(100)
*
FROM  
broxelco_rdg.ind_movimientos with(nolock)   
WHERE DenMov = '13BRC00009'

SELECT Cuenta FROM recursos.CatalogoCuentas where Cliente = '13BRC00009'

SELECT TOP(100) * FROM  [broxelpaymentsws].[PrePayStudioMovements_v] WHERE ClaveCliente = '13BRC00009'
AND YEAR(Fecha) = '2023'
AND MONTH(Fecha) = '3'
;


select year(a.Fecha) año ,month(a.Fecha) mes,case when c.Estado is null then 'No Identificado' else c.Estado end Estado ,a.Producto,sum(a.ImportePesos) Monto , count(1) NumeroTransacciones
from recursos.LogHistoricoMovimientos a with(nolock)
left join [broxelco_rdg].[Comercio] b with(nolock) on a.Comercio=b.Comercio
left join [recursos].[CodigosPostales] c with(nolock) on b.codigo_postal=c.Codigo
where a.Estatus = 'APROBADA'
and a.CategoriaPayments is null
group by year(a.Fecha),month(a.Fecha),a.Producto,case when c.Estado is null then 'No Identificado' else c.Estado end
union
select year(a.Fecha) año,month(a.Fecha) mese,case when c.Estado is null then 'No Identificado' else c.Estado end Estado ,a.Producto,sum(a.ImportePesos) Monto , count(1) NumeroTransacciones
from recursos.HistoricoMovimientos a with(nolock)
left join [broxelco_rdg].[Comercio] b with(nolock) on a.Comercio=b.Comercio
left join [recursos].[CodigosPostales] c with(nolock) on b.codigo_postal=c.Codigo
where a.Estatus = 'APROBADA'
and a.CategoriaPayments is null and YEAR(a.Fecha) in ('2021','2022','2023')
group by year(a.Fecha),month(a.Fecha),a.Producto,case when c.Estado is null then 'No Identificado' else c.Estado end



SELECT TOP(1000) * FROM 
recursos.LogHistoricoMovimientos
WHERE 
CategoriaPayments is null
and YEAR(Fecha) = '2022'

 SELECT c.name AS 'Column Name',
    t.name AS 'Table Name',
    SCHEMA_NAME(schema_id) AS 'Schema Name',
    db_name() AS 'Database Name'
FROM sys.columns c
INNER JOIN sys.tables t ON t.object_id = c.object_id
WHERE c.name LIKE '%codi%com%'
ORDER BY 'Schema Name', 'Table Name';

SELECT * FROM broxelco_rdg.maquila where nombre_tarjethabiente like '%BANX%'

SELECT * FROM broxelco_rdg.AgrupacionClientes where NombreCorto like '%BANX%'

SELECT TOP(100) * FROM [broxelco_rdg].[Comercio] where razon_social like '%banco%mex%'
;
select top (100) * from broxelco_rdg.ind_movimientos where NroRuc = '529130023'
and YEAR(Fclear) = '2023' and MONTH(FClear) = '1'

;

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [Id]
      ,[Trimestre]
      ,[Producto]
      ,[Grupo]
      ,[IdConcepto]
      ,[Categoria]
      ,[Concepto]
      ,[Transacciones]
      ,[VolumenMoneda]
      ,[Volumen]
      ,[Abiertas]
      ,[Bloqueadas]
      ,[Total]
  FROM [qmr].[qmr]

  SELECT TOP (1000) * FROM RECURSOS.MOVIMIENTOS

  SELECT TOP (100) * FROM RECURSOS.COMERCIOS_ADMIN
  
  ;
  
   select IdMovimiento AS IdMovimiento,Cuenta AS Cuenta,Tarjeta AS Tarjeta
 ,Producto AS Producto,FechaPago AS Fecha,Hora AS Hora
 ,cast(concat(year(Fecha),'-',(((datepart(quarter,Fecha) - 1) * 3) + 1),'-01') as date) AS Trimestre
 ,concat(year(Fecha),'Q',datepart(quarter,Fecha)) AS TrimestreQ,Moneda AS Moneda,Importe AS Importe
 ,ImportePesos AS ImportePesos,CodigoTransaccion AS CodigoTipo
 ,(case when (((Procesador = 'PAYSTUDIO') or ((Procesador = 'CREDENCIAL') and (Importe > 0))) 
 and (Comercio = '16ADM00017')) then 'KIOSKO' when (((Procesador = 'PAYSTUDIO') or ((Procesador = 'CREDENCIAL') 
 and (Importe > 0))) and (CodigoTransaccion in ('1','10','0501')) and (Giro <> 'PAYMENTS')) then 'CONSUMO POS' 
 when ((Procesador = 'CREDENCIAL') and (Estatus = 'RECHAZADA') and (Giro not in ('ATM','PAYMENTS'))) then 'CONSUMO POS' 
 when (((Procesador = 'PAYSTUDIO') or ((Procesador = 'CREDENCIAL') and (Importe > 0))) 
 and (CodigoTransaccion in ('1','10','0501')) and (Giro = 'PAYMENTS')) then 'CONSUMO PAYMENTS' when ((Procesador = 'CREDENCIAL') 
 and (Estatus = 'RECHAZADA') and (Giro = 'PAYMENTS')) then 'CONSUMO PAYMENTS' when (((Procesador = 'PAYSTUDIO')
 or ((Procesador = 'CREDENCIAL') and (Importe > 0))) and (CodigoTransaccion in ('2','0701','2701'))) 
 then 'CONSUMO ATM' when ((Procesador = 'CREDENCIAL') and (Estatus = 'RECHAZADA') and (Giro = 'ATM')) 
 then 'CONSUMO ATM' when (((Procesador = 'PAYSTUDIO') or ((Procesador = 'CREDENCIAL') and (Importe < 0))) 
 and (CodigoTransaccion in ('3','5','7','0501','2501')) and (Giro <> 'PAYMENTS')) then 'DEVOLUCION POS'
 when (((Procesador = 'PAYSTUDIO') or ((Procesador = 'CREDENCIAL') and (Importe < 0))) 
 and (CodigoTransaccion in ('3','5','7','0501','2501')) and (Giro = 'PAYMENTS')) then 'DEVOLUCION PAYMENTS' 
 when (((Procesador = 'PAYSTUDIO') or ((Procesador = 'CREDENCIAL') and (Importe < 0))) 
 and (CodigoTransaccion in ('3','5','7','0701','2701'))) then 'DEVOLUCION ATM' else '' end) AS Tipo,Comercio AS Comercio,
 RazonSocial AS RazonSocial,Giro AS Giro,CategoriaPayments AS Categoria,Autorizacion AS Autorizacion
 ,Procesador AS Emisor,Estatus AS Estatus,CodigoEstatus AS CodigoEstatus,
 DescripcionEstatus AS DescripcionEstatus 
 from recursos.HistoricoMovimientos  with (nolock)
 
 ;
 
 DECLARE @Inicio INT, @Fin INT;
SET @Inicio = 1;
SET @Fin = 999999 + 1;

SELECT * FROM (
SELECT ROW_NUMBER() OVER (ORDER BY Fecha, Id) AS NumeroConsecutivo, *
FROM cierres_diarios.CierreDiarioDisponibles WITH (NOLOCK)
WHERE Fecha >= '2022-10-01' AND Fecha <= '2022-10-31'
) A
WHERE A.NumeroCOnsecutivo BETWEEN @Inicio AND @Fin;


SELECT COUNT(1)
FROM cierres_diarios.CierreDiarioDisponibles WITH (NOLOCK)
WHERE Fecha >= '2022-10-01' AND Fecha <= '2022-10-31'

;

Declare @Inicio INT
		,@Fin INT;
		SET @Inicio = 310643368
		SET @Fin = 12000000 + 310643368;
select COUNT(1)
from cierres_diarios.CierreDiarioDisponibles (nolock)
where Fecha >= '2022-10-01' and Fecha <= '2022-12-31'
AND Id BETWEEN @Inicio and @Fin
ORDER BY Id asc
;

 SELECT MOV.Num_Cuenta AS Cuenta
		,CONVERT(DATE,MOV.Fec_Movimiento) AS FechaMovimiento
		,MOV.Mon_Movimiento AS Monto
		,CASE WHEN CAT.IND_MOVIMIENTO IN ('C') THEN 'Deposito' ELSE 'Retiro' END AS Tipo
		,CASE WHEN CAT.IND_MOVIMIENTO IN ('C') THEN MOV.Mon_Movimiento * 1 ELSE MOV.Mon_Movimiento * - 1 END AS Importe
		,UPPER(CAT.DES_TRANSACCION) AS Cat
		,UPPER(SubTip.DES_SUBTRANSAC) AS SubCat
		,UPPER(Cuenta.NOM_CHEQUERA) AS Nombre
		,UPPER(Cuenta.COD_CLIENTE) AS CodCliente
		,UPPER(Cuenta.DES_CORREO) AS Correo
		,UPPER(Pro.NOM_PRODUCTO) AS Producto
		,UPPER(Emp.RAZON_SOCIAL) AS Empresa
		,UPPER(Sis.DES_SISTEMA) AS Sistema
		,UPPER(MOV.Fec_Operacion) AS Fecha
		,MOV.Id_Secuencia AS Secuencia
		,MOV.Fec_Operacion AS FecOperacion
		,Pro.REQUISITOS
FROM [Broxel_nSAF].[CC].[CC_MOVIMIENTO_ENC] (NOLOCK) MOV
LEFT JOIN [Broxel_nSAF].[CF].[CF_CATAL_TRANSACCIONES] (NOLOCK) CAT
ON MOV.Tip_Transaccion = CAT.TIP_TRANSACCION AND MOV.Cod_Sistema_Origen = CAT.COD_SISTEMA
LEFT JOIN  [Broxel_nSAF].[CF].[CF_SUBTIP_TRANSAC] (NoLock) SubTip
ON MOV.Subtip_Transac = SubTip.SUBTIP_TRANSAC AND MOV.Cod_Empresa = SubTip.COD_EMPRESA AND MOV.Cod_Sistema_Origen = SubTip.COD_SISTEMA AND MOV.Tip_Transaccion = SubTip.TIP_TRANSACCION
LEFT JOIN [Broxel_nSAF].[CF].[CF_SISTEMAS] (NoLock) Sis
ON MOV.Cod_Sistema_Origen = Sis.COD_SISTEMA AND MOV.Est_Movimiento = Sis.IND_ESTADO
LEFT JOIN [Broxel_nSAF].[CF].[CF_EMPRESAS] (NoLock) Emp
ON MOV.Cod_Empresa = Emp.COD_EMPRESA
LEFT JOIN [Broxel_nSAF].[CC].[CC_CUENTA] (NoLock) Cuenta
ON MOV.Num_Cuenta = Cuenta.NUM_CUENTA AND MOV.Cod_Sistema_Origen = Cuenta.COD_SISTEMA AND MOV.Cod_Empresa = Cuenta.COD_EMPRESA
LEFT JOIN [Broxel_nSAF].[CF].[CF_PRODUCTOS] (NoLock) Pro
ON Cuenta.COD_PRODUCTO = Pro.COD_PRODUCTO AND MOV.Cod_Sistema_Origen = Pro.COD_SISTEMA AND MOV.Cod_Empresa = Pro.COD_EMPRESA
WHERE  SUBSTRING(MOV.Num_Cuenta,1,4) LIKE 'S15%'
  AND  YEAR(fec_Movimiento) = '2023'
  AND MOV.Tip_Transaccion NOT IN ('45','39') 
  AND MONTH(Fec_Movimiento) IN ('3')
  AND Est_Movimiento <> 'N'
--AND Des_Movimiento <> 'Ajuste de Rendimiento'
--ORDER BY Id_Secuencia ASC;

/****** Object:  StoredProcedure [recursos].[SpCargarHistoricoMovimientos]    Script Date: 16/03/2023 04:42:11 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [recursos].[SpCargarHistoricoMovimientos]
as
BEGIN

EXEC recursos.SpCargarCategoriasComercios

Declare @MaxIdMovPyst int =( SELECT ISNULL(MAX(IdMovimiento), 0) FROM recursos.HistoricoMovimientos
								WHERE Procesador = 'PAYSTUDIO'
									AND Origen = 'paystudio.Movimientos')
Declare @MaxIdMovCred int=(SELECT COALESCE(MAX(IdMovimiento), 0) FROM recursos.HistoricoMovimientos
								WHERE Procesador = 'CREDENCIAL' AND Estatus = 'APROBADA' 
									AND Origen = 'broxelco_rdg.ind_movimientos')
Declare @MaxIdMovCredRech int =(SELECT COALESCE(MAX(IdMovimiento), 0) FROM recursos.HistoricoMovimientos
									WHERE Procesador = 'CREDENCIAL'
										AND Estatus = 'RECHAZADA' AND Origen = 'broxelco_rdg.ind_rechazos')
print 'VARIABLES LISTAS'

	INSERT INTO recursos.HistoricoMovimientos
	SELECT 
	--NULL AS Id,
    'paystudio.Movimientos' AS Origen,
	Movimientos.ID_TRANSACTION AS IdMovimiento,
	Movimientos.TRANSACTION_CATEGORY AS CodigoTransaccion,
	CatalogoTransacciones.Descripcion AS TipoTransaccion,
	CAST(Movimientos.TRANSACTION_BEGIN_TIME AS DATE) AS Fecha,
	CAST(Movimientos.TRANSACTION_BEGIN_TIME AS TIME) AS Hora,
	isnull(Productos.Producto,'') AS Producto,
	isnull(Movimientos.INTERNAL_ACCOUNT_NUMBER,'') AS Cuenta,
	Movimientos.TRANSACTION_MASKED_PAN AS Tarjeta,
	IIF(Movimientos.MESSAGE_CURRENCY_CODE = '484', 'MXN', 'USD') AS Moneda,
	IIF(Movimientos.TRANSACTION_CATEGORY in (3,5,7),ABS(Movimientos.MESSAGE_AMNT) *(-1),Movimientos.MESSAGE_AMNT) AS Importe,
	IIF(Movimientos.TRANSACTION_CATEGORY in (3,5,7),ABS(Movimientos.CARD_BILLING_AMNT) *(-1),Movimientos.CARD_BILLING_AMNT) AS ImportePesos,
    isnull(Movimientos.MontoIntercambio,0.00) AS MontoIntercambio,
	isnull(recursos.acentos(Movimientos.CARD_ACCEPTOR_NAME),'') AS Comercio,
	recursos.acentos(CategoriasComercios.RazonSocial) AS RazonSocial,
	isnull(Movimientos.MCC_CODE,'') AS MCC,
    IIF(CategoriasComercios.Comercio IS NULL, COALESCE(ControlesBroxel.Control, 'OTROS'), 'PAYMENTS') AS BroxelControl,
	IIF(CategoriasComercios.Comercio IS NULL, COALESCE(CatalogoMCC.Comercial, 'OTROS'), 'PAYMENTS') AS Giro,
    CategoriasComercios.Categoria AS CategoriaPayments,
	Movimientos.AUTHORIZATION_CODE AS Autorizacion,
    Movimientos.ID_RESPONSE_CODE AS CodigoEstatus,
	IIF(Movimientos.ID_RESPONSE_CODE IN ('0', '00'), 'APROBADA', 'RECHAZADA') AS Estatus,
	Movimientos.RESPONSE_CODE_DESCRIPTION AS DescripcionEstatus,
	'PAYSTUDIO' AS Procesador,
    CAST(Movimientos.TRANSACTION_BEGIN_TIME AS DATE) AS FechaPago
	FROM paystudio.Movimientos
	LEFT JOIN paystudio.CatalogoTransacciones
	ON Movimientos.TRANSACTION_CATEGORY = CatalogoTransacciones.Id
	LEFT JOIN paystudio.Productos
	ON Movimientos.ID_PRODUCT = Productos.Id
	LEFT JOIN recursos.CategoriasComercios
    ON Movimientos.CARD_ACCEPTOR_NAME = CategoriasComercios.Comercio
	LEFT JOIN recursos.CatalogoMCC
	ON Movimientos.MCC_CODE = CatalogoMCC.MCC
    LEFT JOIN recursos.ControlesBroxel
    ON Movimientos.MCC_CODE = ControlesBroxel.MCC
    WHERE Movimientos.ID_TRANSACTION > @MaxIdMovPyst
	
	SELECT 'CARGA1'

	INSERT INTO recursos.HistoricoMovimientos
	SELECT
	--NULL AS Id,
	'broxelco_rdg.ind_movimientos' AS Origen,
	Movimientos.id AS IdMovimiento,
	Movimientos.CodTransac AS CodigoTransaccion,
	CatalogoTransacciones.DenominacionTransaccion AS TipoTransaccion,
	Movimientos.FClear  AS Fecha,
	case when Hora like '%:%' then  try_convert(time,Hora) else SUBSTRING(Hora,0,3 )+':'+SUBSTRING(Hora,3,2 )+':'+SUBSTRING(Hora,5,2 ) end  AS Hora,
	Movimientos.CodPtoCuota AS Producto,
	Movimientos.NroRuc AS Cuenta,
	Movimientos.NroTar AS Tarjeta,
	IIF(Movimientos.CodMont = '484', 'MXN', 'USD') AS Moneda,
	Movimientos.ImpTotal AS Importe,
	IIF(COALESCE(Movimientos.importe_pesos, 0) > 0, Movimientos.importe_pesos, Movimientos.ImpTotal) AS ImportePesos,
	isnull(Movimientos.TasaIntercambio,0.00) as MontoIntercambio,
	isnull(recursos.acentos(Movimientos.DenMov),'SIN_COMERCIO') AS Comercio,
	recursos.acentos(CategoriasComercios.RazonSocial) AS RazonSocial,
	isnull(Movimientos.CodRubro,'') AS MCC,
	IIF(CategoriasComercios.Comercio IS NULL, COALESCE(ControlesBroxel.Control, 'OTROS'), 'PAYMENTS') AS BroxelControl,
	iIf(CategoriasComercios.Comercio is null, COALESCE(CatalogoMCC.Comercial, 'OTROS'), 'PAYMENTS') AS Giro,
	CategoriasComercios.Categoria AS CategoriaPayments,
	Movimientos.NroAut AS Autorizacion,
	'00' AS CodigoEstatus,
	'APROBADA' AS Estatus,
	'AUTHORIZED' AS DescripcionEstatus,
	'CREDENCIAL' AS Procesador,
    FePago AS FechaPago
	FROM broxelco_rdg.ind_movimientos AS Movimientos
	LEFT JOIN broxelco_rdg.CatalogoTransacciones
	ON Movimientos.CodTransac = CatalogoTransacciones.Codigo
	LEFT JOIN recursos.CategoriasComercios
	ON Movimientos.DenMov = CategoriasComercios.Comercio
	LEFT JOIN recursos.CatalogoMCC
	ON Movimientos.CodRubro = CatalogoMCC.MCC
	LEFT JOIN recursos.ControlesBroxel
	ON Movimientos.CodRubro = ControlesBroxel.MCC
	WHERE Movimientos.id > @MaxIdMovCred
	SELECT 'CARGA2'

	INSERT INTO recursos.HistoricoMovimientos
	SELECT
	--NULL AS Id,
    'broxelco_rdg.ind_rechazos' AS Origen,
	Movimientos.id AS IdMovimiento,
	Movimientos.CodigoRechazo AS CodigoTransaccion,
	NULL AS TipoTransaccion,
	CAST(Movimientos.Fecha AS DATE) AS Fecha,
	CAST(Movimientos.Hora AS TIME) AS Hora,
	Movimientos.Producto AS Producto,
	Movimientos.Cuenta AS Cuenta,
	Movimientos.Tarjeta AS Tarjeta,
	'MXN' AS Moneda,
	0.0 AS Importe,
	0.0 AS ImportePesos,
    0.0 AS MontoIntercambio,
	recursos.acentos(Movimientos.NombreComercio) AS Comercio,
	CategoriasComercios.RazonSocial AS RazonSocial,
	Movimientos.MCCGiroComercio AS MCC,
    IIF(CategoriasComercios.Comercio IS NULL, COALESCE(ControlesBroxel.Control, 'OTROS'), 'PAYMENTS') AS BroxelControl,
	IIF(CategoriasComercios.Comercio IS NULL, COALESCE(CatalogoMCC.Comercial, 'OTROS'), 'PAYMENTS') AS Giro,
    CategoriasComercios.Categoria AS CategoriaPayments,
	NULL AS Autorizacion,
    Movimientos.CodigoRechazo AS CodigoEstatus,
	'RECHAZADA' AS Estatus,
	UPPER(Movimientos.DescCodigoRechazo) AS DescripcionEstatus,
	'CREDENCIAL' AS Procesador,
    '' AS FechaPago
	FROM broxelco_rdg.ind_rechazos AS Movimientos
    LEFT JOIN recursos.CategoriasComercios
    ON Movimientos.NombreComercio = CategoriasComercios.Comercio
	LEFT JOIN recursos.CatalogoMCC
	ON Movimientos.MCCGiroComercio = CatalogoMCC.MCC
    LEFT JOIN recursos.ControlesBroxel
    ON Movimientos.MCCGiroComercio = ControlesBroxel.MCC
	WHERE Movimientos.id > @MaxIdMovCredRech
	SELECT 'CARGA3'
END
GO

;,

SELECT 
YEAR(C.Fecha) as Year,
SUM(liquidacion_comercio) as Liquidacion,
--SUM(liquidacion_comercio) OVER (Partition By C.comercio,YEAR(C.Fecha),MONTH(C.Fecha)) AS Mensual,
P.IdProducto,
CASE WHEN C.envioPago is not null THEN 'Facturado' Else 'Pendiente' END AS Estatus
FROM broxelco_rdg.bp_detalle_diario_comercio (NoLock) C
LEFT JOIN [broxelco_rdg].[Comercio] (NoLock) CC
ON C.comercio = CC.comercio
LEFT JOIN Broxelco_rdg.Programas P
ON C.idPrograma = P.IdProgramas
where YEAR(C.Fecha) in ('2023') and MONTH(C.Fecha) in ('1','2') 
--AND  C.folioFactura is not null
--and C.envioPago = 1 
AND  C.comercio in ('16ADM00025','16ADM00024','16ADM00023')
--AND CC.Razon_Social like '%desarrollo%'
GROUP BY YEAR(C.Fecha),P.IdProducto,CASE WHEN C.envioPago is not null THEN 'Facturado' Else 'Pendiente' END
Order By YEAR(C.Fecha) asc


;


SELECT TOP (100) * FROM broxelco_rdg.bp_detalle_diario_comercio


  SELECT * FROM RECURSOS.MOVIMIENTOS
  WHERE comercio IN ('16ADM00025','16ADM00024','16ADM00023')

   SELECT TOP (100) * FROM RECURSOS.COMERCIOS_ADMIN
;
   SELECT TOP(100)  * FROM RECURSOS.Historico_Movimiento;
   
   ---Para Buscar en las Bases de Datos
 SELECT c.name AS 'Column Name',
    t.name AS 'Table Name',
    SCHEMA_NAME(schema_id) AS 'Schema Name',
    db_name() AS 'Database Name'
FROM sys.columns c
INNER JOIN sys.tables t ON t.object_id = c.object_id
WHERE c.name LIKE '%idPrograma%'
ORDER BY 'Schema Name', 'Table Name';


SELECT TOP(110) * FROM Broxelco_rdg.Programas



SELECT 
YEAR(C.Fecha) as Year,
SUM(liquidacion_comercio) as Liquidacion,
--SUM(liquidacion_comercio) OVER (Partition By C.comercio,YEAR(C.Fecha),MONTH(C.Fecha)) AS Mensual,
P.IdProducto,
CASE WHEN C.envioPago is not null THEN 'Facturado' Else 'Pendiente' END AS Estatus
FROM broxelco_rdg.bp_detalle_diario_comercio (NoLock) C
LEFT JOIN [broxelco_rdg].[Comercio] (NoLock) CC
ON C.comercio = CC.comercio
LEFT JOIN Broxelco_rdg.Programas P
ON C.idPrograma = P.IdProgramas
where YEAR(C.Fecha) in ('2020','2021','2022') 
--AND  C.folioFactura is not null
--and C.envioPago = 1 
--AND  C.comercio = '22CBX00567'
--AND CC.Razon_Social like '%desarrollo%'
GROUP BY YEAR(C.Fecha),P.IdProducto,CASE WHEN C.envioPago is not null THEN 'Facturado' Else 'Pendiente' END
Order By YEAR(C.Fecha) asc
;
SELECT id, NroRuc Cuenta, CONVERT(DATE,Fclear) Fecha,SUM(importe_pesos) Importe,CodPtoCuota Producto,DenMov Categoria,COUNT(1) Operaciones,SUM(case when CodMont!='484' then (TasaIntercambio*(importe_pesos/ImpTotal)) else TasaIntercambio end) Intercambio
      FROM broxelco_rdg.ind_movimientos
      WHERE Fclear > EOMONTH(DATEADD(MONTH, -1, GETDATE()))
      GROUP BY id,NroRuc,CONVERT(DATE,Fclear),CodPtoCuota,DenMov
      UNION ALL
      SELECT id, NumCuenta Cuenta, CONVERT(DATE,Fecha) Fecha,SUM(ImpTotalDEC) Importe,Producto,DenMov Categoria,COUNT(1) Operaciones,SUM(ExchangeRateDEC) Intercambio
      FROM broxelpaymentsws.PrePayStudioMovements_v
      WHERE Fecha > EOMONTH(DATEADD(MONTH, -1, GETDATE()))
      GROUP BY id,NumCuenta,CONVERT(DATE,Fecha),Producto,DenMov;
      
       SELECT c.name AS 'Column Name',
    t.name AS 'Table Name',
    SCHEMA_NAME(schema_id) AS 'Schema Name',
    db_name() AS 'Database Name'
FROM sys.columns c
INNER JOIN sys.tables t ON t.object_id = c.object_id
WHERE c.name LIKE '%comercio%'
ORDER BY 'Schema Name', 'Table Name';

SELECT TOP(100) * FROM broxelco_rdg.bp_detalle_diario_comercio
where YEAR(Fecha) = '2023' and comercio = '18CBX01138'

SELECT TOP(100) * FROM recursos.HistoricoMovimientos where Comercio = '18CBX01138' and YEAR(Fecha) = '2023'

SELECT * from broxelco_rdg.AgrupacionClientes where Referencia = '18CBX01138'

SELECT 
*
FROM broxelco_rdg.bp_detalle_diario_comercio
where YEAR(Fecha) = '2023' 
--and envioPago = 1 
and  comercio = '18CBX01138'
;
SELECT 
YEAR(C.Fecha) as Year,
MONTH(C.Fecha) as Month,
C.comercio,
CC.Razon_Social,
C.folioFactura,
SUM(liquidacion_comercio) as Liquidacion,
SUM(liquidacion_comercio) OVER (Partition By C.comercio,YEAR(C.Fecha),MONTH(C.Fecha)) AS Mensual,
M.Num_Cuenta,
M.Producto
FROM broxelco_rdg.bp_detalle_diario_comercio (NoLock) C
LEFT JOIN [broxelco_rdg].[Comercio] (NoLock) CC
ON C.comercio = CC.comercio
LEFT JOIN broxelco_rdg.maquila (noLock) M
ON CC.numCuentaBroxel = M.num_cuenta
where YEAR(C.Fecha) in ('2020','2021','2022') 
AND  C.folioFactura is not null
and C.envioPago = 1 
--AND  C.comercio = '22CBX00567'
--AND CC.Razon_Social like '%desarrollo%'
GROUP BY C.comercio,C.folioFactura,CC.Razon_Social,YEAR(C.Fecha),C.Producto,liquidacion_comercio,MONTH(C.Fecha),M.Num_Cuenta,M.producto
Order By YEAR(C.Fecha) asc

;


    SELECT SUBSTRING(Num_Cuenta,1,4) AS Tipo
  ,COUNT(*)
  FROM [Broxel_nSAF].[CC].[CC_MOVIMIENTO_ENC] (NoLock)
  WHERE Fec_Movimiento between '2022-12-01' and '2022-12-31'
  AND Num_Cuenta like 'S15%' and Id_Secuencia is not null
  GROUP BY SUBSTRING(Num_Cuenta,1,4)


  SELECT TOP(1000) * 
  FROM  [Broxel_nSAF].[CC].[CC_MOVIMIENTO_ENC]
  WHERE Id_Secuencia = '1558955'
  ;
  /****** Object:  StoredProcedure [recursos].[cierreTransaccionesCredencial]    Script Date: 13/03/2023 10:22:13 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  PROCEDURE [recursos].[cierreTransaccionesCredencial]
AS

BEGIN
DECLARE @TODAY DATE, @PAST DATE
SET @TODAY=(SELECT GETDATE());
SET @PAST =(SELECT GETDATE()-38)

 DELETE FROM dbo.CierreTransacciones WHERE FECHA>=@PAST AND Procesador <>'Paystudio'
 DELETE FROM dbo.CierreTransacciones WHERE FECHA>=@PAST AND Procesador is null or  Procesador=''

 
INSERT INTO dbo.CierreTransacciones

;
SELECT TOP(1000) 
ind_movimientos.FClear   AS Fecha,
ind_movimientos.CodPtoCuota 		 AS Producto,
cc.Cliente	  AS Clave_Cliente,
COUNT(1) 	  AS Operaciones,
COUNT(DISTINCT(ind_movimientos.NroRuc))	  AS Cuentas,
SUM(case when isnull(importe_pesos,0)<>0 then importe_pesos else ImpTotal end) AS ImportePesos,
sum (case when CodMont!='484' then (TasaIntercambio*(importe_pesos/ImpTotal)) else TasaIntercambio end) AS MontoIntercambio,
CatalogoClasificacionClientes.Clasificacion   AS ClasificacionCliente,
case when Comercio.idComercio is not null then CatalogoCategoriaComercio.Categoria else CatalogoTipoTransaccion.CategoriaTransaccion end AS TipoMovimiento,
Cat_Procesador.Nombre	 AS Procesador
FROM  
broxelco_rdg.ind_movimientos with(nolock)       
LEFT JOIN recursos.CatalogoCuentas cc with(nolock)    ON cc.Cuenta = ind_movimientos.NroRuc
LEFT JOIN broxelco_rdg.clientesBroxel with(nolock) ON clientesBroxel.ClaveCliente = cc.Cliente
LEFT JOIN broxelco_rdg.CatalogoClasificacionClientes with(nolock) ON CatalogoClasificacionClientes.Codigo = clientesBroxel.ClasificacionCtesBroxel
LEFT JOIN broxelco_rdg.CatalogoTipoTransaccion with(nolock)       ON CatalogoTipoTransaccion.CodigoTransaccional = ind_movimientos.CodTransac
LEFT JOIN broxelco_rdg.Comercio with(nolock) ON Comercio.Comercio = ind_movimientos.DenMov
LEFT JOIN broxelco_rdg.CatalogoCategoriaComercio with(nolock)      ON CatalogoCategoriaComercio.id=Comercio.Categoria
LEFT JOIN dbo.Cat_Procesador with(nolock) ON Procesador = Cat_Procesador.Nombre
WHERE FClear>='2023-01-01' and FClear<= GETDATE()
GROUP BY cc.Cliente, CodPtoCuota, FClear,case when Comercio.idComercio is not null then CatalogoCategoriaComercio.Categoria else CatalogoTipoTransaccion.CategoriaTransaccion end ,Clasificacion,
case when Comercio.idComercio is not null then CatalogoCategoriaComercio.Categoria else CatalogoTipoTransaccion.CategoriaTransaccion end,Cat_Procesador.Nombre

;

SELECT c.name AS 'Column Name',
    t.name AS 'Table Name',
    SCHEMA_NAME(schema_id) AS 'Schema Name',
    db_name() AS 'Database Name'
FROM sys.columns c
INNER JOIN sys.tables t ON t.object_id = c.object_id
WHERE c.name LIKE '%Procesador%'
ORDER BY 'Schema Name', 'Table Name';
;

SELECT TOP(1000) *  FROM broxelpaymentsws.PrePayStudioMovements_v (NoLock)
;
SELECT TOP(1000) * FROM  
broxelco_rdg.ind_movimientos (NoLock)

;
SELECT * from Cat_Procesador

;
SELECT B.Procesador,SUM(A.Importe) Importe FROM 
(SELECT id, NroRuc Cuenta, CONVERT(DATE,Fclear) Fecha,SUM(importe_pesos) Importe,CodPtoCuota Producto,DenMov Categoria,COUNT(1) Operaciones,SUM(case when CodMont!='484' then (TasaIntercambio*(importe_pesos/ImpTotal)) else TasaIntercambio end) Intercambio
      FROM broxelco_rdg.ind_movimientos
      WHERE Fclear > EOMONTH(DATEADD(MONTH, -1, GETDATE()))
      GROUP BY id,NroRuc,CONVERT(DATE,Fclear),CodPtoCuota,DenMov
      UNION ALL
      SELECT id, NumCuenta Cuenta, CONVERT(DATE,Fecha) Fecha,SUM(ImpTotalDEC) Importe,Producto,DenMov Categoria,COUNT(1) Operaciones,SUM(ExchangeRateDEC) Intercambio
      FROM broxelpaymentsws.PrePayStudioMovements_v
      WHERE Fecha > EOMONTH(DATEADD(MONTH, -1, GETDATE()))
      GROUP BY id,NumCuenta,CONVERT(DATE,Fecha),Producto,DenMov) A
LEFT JOIN recursos.CatalogoCuentas B with(nolock)    ON B.Cuenta = A.Cuenta
WHERE B.Procesador = 'CREDENCIAL'
GROUP BY B.Procesador
;


SELECT * FROM  recursos.CatalogoCuentas


SELECT c.name AS 'Column Name',
    t.name AS 'Table Name',
    SCHEMA_NAME(schema_id) AS 'Schema Name',
    db_name() AS 'Database Name'
FROM sys.columns c
INNER JOIN sys.tables t ON t.object_id = c.object_id
WHERE c.name LIKE '%%'
ORDER BY 'Schema Name', 'Table Name';

  SELECT MOV.fecha
		,MOV.Importe
		,*  
FROM  [recursos].[HistoricoMovimientos] AS MOV
  WHERE MOV.Producto IN ('S150','S152') 
  AND YEAR(MOV.Fecha) = '2023' 
  ORDER BY MOV.Autorizacion ASC


    SELECT TOP(100) *
FROM  [recursos].[HistoricoMovimientos]
WHERE Producto Like ('S152%');


SELECT c.name AS 'Column Name',
    t.name AS 'Table Name',
    SCHEMA_NAME(schema_id) AS 'Schema Name',
    db_name() AS 'Database Name'
FROM sys.columns c
INNER JOIN sys.tables t ON t.object_id = c.object_id
WHERE c.name LIKE '%Cat%'
ORDER BY 'Schema Name', 'Table Name';
      
