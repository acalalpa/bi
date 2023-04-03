view: movimientos {
  sql_table_name:
    (
     SELECT --TOP(1000)
      A.id,A.NroRuc Cuenta,
    CONVERT(DATE,A.Fclear) Fecha,
    SUM(A.ImpTotal) Importe,A.CodPtoCuota Producto,A.DenMov Categoria,
    COUNT(1) Operaciones,
    SUM(case when A.CodMont!='484' then (A.TasaIntercambio*(A.importe_pesos/A.ImpTotal)) else A.TasaIntercambio end) Intercambio,
    CASE WHEN B.CategoriaTransaccion IS NOT NULL THEN UPPER(B.CategoriaTransaccion) ELSE A.TipReg END TipReg,
    DATEPART(ISOWK,FClear) AS Semana,
    'Ind_Movimientos' AS Fuente
  FROM broxelco_rdg.ind_movimientos (NoLock) A
  LEFT JOIN [broxelco_rdg].[CatalogoTipoTransaccion] B
  ON A.CodTransac = B.CodigoTransaccional
  WHERE YEAR(FClear) = '2023' AND MONTH(FClear) = '2' AND DATEPART(ISOWK,FClear) = '7'
    --Fclear > EOMONTH(DATEADD(MONTH, -6, GETDATE()))
  GROUP BY id,NroRuc,CONVERT(DATE,Fclear),CodPtoCuota,DenMov,TipReg,B.CategoriaTransaccion,DATEPART(ISOWK,FClear)
  UNION ALL
  SELECT --TOP(1000)
      A.id,
    A.NumCuenta Cuenta,
    CONVERT(DATE,A.Fecha) Fecha,
    SUM(A.ImpTotalDEC) Importe,
    A.Producto,
    A.DenMov Categoria,
    COUNT(1) Operaciones,
    SUM(A.ExchangeRateDEC) Intercambio
      ,UPPER(CASE
      WHEN B.idComercio IS NOT NULL AND  A.TipoReg='C' THEN C.Categoria
               ELSE
                 CASE A.TipoReg
            WHEN 'C'      THEN 'POS'
            WHEN 'D'      THEN 'Devoluciones'
            WHEN 'R'      THEN 'ATM'
            WHEN 'Z'      THEN 'Comisiones'
            WHEN 'S'      THEN 'Comisiones'
            WHEN 'X'      THEN 'Devoluciones'
            WHEN 'Y'      THEN 'Otros'
            WHEN 'I'      THEN 'Comisiones'
            WHEN 'K'      THEN 'Devoluciones'
            WHEN 'L'      THEN 'Comisiones'
            WHEN 'J'      THEN 'Devoluciones'
            WHEN 'M'      THEN 'Comisiones'
            WHEN 'N'      THEN 'Comisiones'
            WHEN 'H'      THEN 'Otros'
            WHEN 'T'      THEN 'Otros'
            WHEN 'O'      THEN 'Otros'
            WHEN 'A'      THEN 'Otros'
            WHEN 'B'      THEN 'Comisiones'
            WHEN 'G'      THEN 'Otros'
            WHEN 'F'      THEN 'Devoluciones'
            WHEN 'Q'      THEN 'Comisiones'
            WHEN 'P'      THEN 'No Aplica'
            WHEN 'U'      THEN 'Devoluciones'
            WHEN 'V'      THEN 'No Aplica'
            WHEN 'W'      THEN 'NO APLICA'
END END)
    ,DATEPART(ISOWK,Fecha) AS SEMANA
    ,'PrePayStudio' AS Fuente
      FROM broxelpaymentsws.PrePayStudioMovements_v (NoLock) A
    LEFT JOIN broxelco_rdg.Comercio (NoLock) B ON A.DenMov = B.Comercio
    LEFT JOIN broxelco_rdg.CatalogoCategoriaComercio (NoLock) C ON B.Categoria = C.id
      WHERE YEAR(Fecha) = '2023' AND  MONTH(Fecha) = '2' AND DATEPART(ISOWK,Fecha) = '7'
    --Fecha > EOMONTH(DATEADD(MONTH, -6, GETDATE()))
      GROUP BY A.id,A.NumCuenta,CONVERT(DATE,A.Fecha),A.Producto,A.DenMov,A.TipoReg,B.idComercio,C.Categoria,DATEPART(ISOWK,Fecha)) ;;
  drill_fields: [Producto]

  dimension: id {
    primary_key: yes
    type: string
    sql: ${TABLE}.id ;;
}

dimension: Cuenta {
  type: string
  sql: ${TABLE}.Cuenta ;;
}

dimension_group: Fecha {
  type: time
  timeframes: [
    raw,
    time,
    date,
    week,
    month,
    quarter,
    year
  ]
  sql: ${TABLE}.Fecha ;;
}
dimension: Importe {
  type: number
  sql: ${TABLE}.Importe ;;
}
dimension: Producto {
  type: string
  sql: ${TABLE}.Producto ;;
}
dimension: Categoria {
  type: string
  sql: COALESCE(${TABLE}.Categoria, 'Otros') ;;
}
dimension: Operaciones {
  type: number
  sql: ${TABLE}.Operaciones ;;
}
dimension: Intercambio {
  type: number
  sql: ${TABLE}.Intercambio ;;
}
  dimension: TipReg {
    type: string
    sql: ${TABLE}.TipReg ;;
  }
  dimension: Cat {
    type: string
    sql: CASE
         WHEN ${TABLE}.TipReg = 'A' THEN 'OTROS'
         WHEN ${TABLE}.TipReg = 'B' THEN 'COMISIONES'
         WHEN ${TABLE}.TipReg = 'C' THEN 'POS'
         WHEN ${TABLE}.TipReg = 'D' THEN 'POS'
         WHEN ${TABLE}.TipReg = 'E' THEN 'DEVOLUCIONES'
         WHEN ${TABLE}.TipReg = 'F' THEN 'DEVOLUCIONES'
         WHEN ${TABLE}.TipReg = 'G' THEN 'OTROS'
         WHEN ${TABLE}.TipReg = 'H' THEN 'OTROS'
         WHEN ${TABLE}.TipReg = 'I' THEN 'COMISIONES'
         WHEN ${TABLE}.TipReg = 'J' THEN 'DEVOLUCIONES'
         WHEN ${TABLE}.TipReg = 'K' THEN 'DEVOLUCIONES'
         WHEN ${TABLE}.TipReg = 'L' THEN 'COMISIONES'
         WHEN ${TABLE}.TipReg = 'M' THEN 'COMISIONES'
         WHEN ${TABLE}.TipReg = 'N' THEN 'COMISIONES'
         WHEN ${TABLE}.TipReg = 'O' THEN 'OTROS'
         WHEN ${TABLE}.TipReg = 'P' THEN 'NO APLICA'
         WHEN ${TABLE}.TipReg = 'Q' THEN 'COMISIONES'
         WHEN ${TABLE}.TipReg = 'R' THEN 'ATM'
         WHEN ${TABLE}.TipReg = 'S' THEN 'COMISIONES'
         WHEN ${TABLE}.TipReg = 'T' THEN 'OTROS'
         WHEN ${TABLE}.TipReg = 'U' THEN 'DEVOLUCIONES'
         WHEN ${TABLE}.TipReg = 'V' THEN 'NO APLICA'
         WHEN ${TABLE}.TipReg = 'W' THEN 'NO APLICA'
         WHEN ${TABLE}.TipReg = 'X' THEN 'DEVOLUCIONES'
         WHEN ${TABLE}.TipReg = 'Y' THEN 'OTROS'
         WHEN ${TABLE}.TipReg = 'Z' THEN 'COMISIONES'
         ELSE ${TABLE}.TipReg -- en caso de que TipReg no sea C, A o B, asigna un valor de 0
       END ;;
  }
  dimension: clase {
    type: string
    sql: CASE
    WHEN ${TipReg} = 'C' AND ${comercio.id_comercio} IS NOT NULL THEN ${catalogo_categoria_comercio.categoria} ELSE ${Cat} END;;
  }
}
