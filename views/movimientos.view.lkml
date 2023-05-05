view: movimientos {
  sql_table_name:
    (
     SELECT
        A.id,A.NroRuc Cuenta,
    CONVERT(DATE,A.Fclear) Fecha,
    SUM(A.ImpTotal) Importe,
    A.CodPtoCuota Producto,
    A.DenMov Categoria,
    '1' Operaciones,
    SUM(case when A.CodMont!='484' then (A.TasaIntercambio*(A.importe_pesos/A.ImpTotal)) else A.TasaIntercambio end) Intercambio,
    CASE WHEN B.CategoriaTransaccion IS NOT NULL THEN UPPER(B.CategoriaTransaccion) ELSE CASE A.TipReg
            WHEN 'C'      THEN 'POS'
            WHEN 'D'      THEN 'Devoluciones'
            WHEN 'R'      THEN 'ATM'
            WHEN 'F'      THEN 'Devoluciones'
    END END TipReg,
    DATEPART(ISOWK,FClear) AS Semana,
    'Ind_Movimientos' AS Fuente
FROM broxelco_rdg.ind_movimientos (NoLock) A
    LEFT JOIN [broxelco_rdg].[CatalogoTipoTransaccion] B
    ON A.CodTransac = B.CodigoTransaccional
--WHERE YEAR(FClear) = '2023'
   -- AND MONTH(FClear) = '3'
  --AND DATEPART(ISOWK,FClear) = '7'
    --Fclear > EOMONTH(DATEADD(MONTH, -6, GETDATE()))
GROUP BY id,NroRuc,CONVERT(DATE,Fclear),CodPtoCuota,DenMov,TipReg,B.CategoriaTransaccion,DATEPART(ISOWK,FClear)
UNION ALL
SELECT
        A.id,
    A.NumCuenta Cuenta,
    CONVERT(DATE,A.Fecha) Fecha,
    SUM(A.ImpTotalDEC) Importe,
    A.Producto,
    A.DenMov Categoria,
    '1' Operaciones,
    SUM(A.ExchangeRateDEC) Intercambio
    ,UPPER(CASE
    WHEN B.idComercio IS NOT NULL AND  A.TipoReg='C' THEN C.Categoria
               ELSE
                 CASE A.TipoReg
            WHEN 'C'      THEN 'POS'
            WHEN 'D'      THEN 'Devoluciones'
            WHEN 'R'      THEN 'ATM'
            WHEN 'F'      THEN 'Devoluciones'
    END END) TipReg
    ,DATEPART(ISOWK,Fecha) AS SEMANA
    ,'PrePayStudio' AS Fuente
 FROM broxelpaymentsws.PrePayStudioMovements_v (NoLock) A
    LEFT JOIN broxelco_rdg.Comercio (NoLock) B ON A.DenMov = B.Comercio
    LEFT JOIN broxelco_rdg.CatalogoCategoriaComercio (NoLock) C ON B.Categoria = C.id
    --WHERE YEAR(Fecha) = '2023'
    --AND  MONTH(Fecha) = '3'
    --AND DATEPART(ISOWK,Fecha) = '7'
      --Fecha > EOMONTH(DATEADD(MONTH, -6, GETDATE()))
 GROUP BY A.id,A.NumCuenta,CONVERT(DATE,A.Fecha),A.Producto,A.DenMov,A.TipoReg,B.idComercio,C.Categoria,DATEPART(ISOWK,Fecha)
    ) ;;
  drill_fields: [id,Producto,Cuenta,Mes,Categoria,clase]


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

  dimension: Mes {
    type: string
    sql: UPPER(TRANSLATE(FORMAT(${TABLE}.Fecha, 'MMMM', 'es-ES'), 'JANUARYFEBRUARYMARCHAPRILMAYJUNEJULYAUGUSTSEPTEMBEROCTOBERNOVEMBERDECEMBER', 'ENEROFEBREROMARZOABRILMAYOJUNIOJULIOAGOSTOSEPTIEMBREOCTUBRENOVIEMBREDICIEMBRE')) ;;
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
         WHEN ${TABLE}.TipReg = 'C' THEN 'POS'
         WHEN ${TABLE}.TipReg = 'D' THEN 'POS'
         WHEN ${TABLE}.TipReg = 'E' THEN 'DEVOLUCIONES'
         WHEN ${TABLE}.TipReg = 'F' THEN 'DEVOLUCIONES'
         WHEN ${TABLE}.TipReg = 'L' THEN 'COMISIONES'
         WHEN ${TABLE}.TipReg = 'P' THEN 'NO APLICA'
         WHEN ${TABLE}.TipReg = 'R' THEN 'ATM'
         WHEN ${TABLE}.TipReg = 'T' THEN 'OTROS'
         ELSE ${TABLE}.TipReg -- en caso de que TipReg no sea C, A o B, asigna un valor de 0
       END ;;
  }
  dimension: clase {
    type: string
    sql: CASE
    WHEN ${TipReg} = 'C' AND ${comercio.id_comercio} IS NOT NULL THEN ${catalogo_categoria_comercio.categoria} ELSE ${Cat} END;;
  }
  dimension: Semana {
  type: number
    sql: :{TABLE}.Semana ;;
  }
}
