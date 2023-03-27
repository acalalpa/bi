view: movimientos {
  sql_table_name:
    (
     SELECT --TOP(1000)
      A.id,A.NroRuc Cuenta, CONVERT(DATE,A.Fclear) Fecha,SUM(A.ImpTotal) Importe,A.CodPtoCuota Producto,A.DenMov Categoria,COUNT(1) Operaciones,SUM(case when A.CodMont!='484' then (A.TasaIntercambio*(A.importe_pesos/A.ImpTotal)) else A.TasaIntercambio end) Intercambio
      ,CASE WHEN B.CategoriaTransaccion IS NOT NULL THEN UPPER(B.CategoriaTransaccion) ELSE A.TipReg END TipReg
      FROM broxelco_rdg.ind_movimientos (NoLock) A
    LEFT JOIN [broxelco_rdg].[CatalogoTipoTransaccion] B
    ON A.CodTransac = B.CodigoTransaccional
      WHERE Fclear > EOMONTH(DATEADD(MONTH, -6, GETDATE()))
      GROUP BY id,NroRuc,CONVERT(DATE,Fclear),CodPtoCuota,DenMov,TipReg,B.CategoriaTransaccion
      UNION ALL
      SELECT --TOP(1000)
      id, NumCuenta Cuenta, CONVERT(DATE,Fecha) Fecha,SUM(ImpTotalDEC) Importe,Producto,DenMov Categoria,COUNT(1) Operaciones,SUM(ExchangeRateDEC) Intercambio
      ,TipoReg AS TipReg
      FROM broxelpaymentsws.PrePayStudioMovements_v (NoLock)
      WHERE Fecha > EOMONTH(DATEADD(MONTH, -6, GETDATE()))
      GROUP BY id,NumCuenta,CONVERT(DATE,Fecha),Producto,DenMov,TipoReg
    ) ;;
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


}
