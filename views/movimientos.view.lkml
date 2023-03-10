view: movimientos {
  sql_table_name:
    (
      SELECT id, NroRuc Cuenta, CONVERT(DATE,Fclear) Fecha,SUM(importe_pesos) Importe,CodPtoCuota Producto,DenMov Categoria,COUNT(1) Operaciones,SUM(case when CodMont!='484' then (TasaIntercambio*(importe_pesos/ImpTotal)) else TasaIntercambio end) Intercambio
      FROM broxelco_rdg.ind_movimientos
      WHERE Fclear > EOMONTH(DATEADD(MONTH, -1, GETDATE()))
      GROUP BY id,NroRuc,CONVERT(DATE,Fclear),CodPtoCuota,DenMov
      UNION ALL
      SELECT id, NumCuenta Cuenta, CONVERT(DATE,Fecha) Fecha,SUM(ImpTotalDEC) Importe,Producto,DenMov Categoria,COUNT(1) Operaciones,SUM(ExchangeRateDEC) Intercambio
      FROM broxelpaymentsws.PrePayStudioMovements_v
      WHERE Fecha > EOMONTH(DATEADD(MONTH, -1, GETDATE()))
      GROUP BY id,NumCuenta,CONVERT(DATE,Fecha),Producto,DenMov
    ) ;;
  drill_fields: [Producto]

  dimension: id {
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
  sql: COALESCE(${TABLE}.Categoria, 'C') ;;
}
dimension: Operaciones {
  type: number
  sql: ${TABLE}.Operaciones ;;
}
dimension: Intercambio {
  type: number
  sql: ${TABLE}.Intercambio ;;
}
}
