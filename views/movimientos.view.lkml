view: movimientos {
  sql_table_name:
    (
      SELECT id, NroRuc Cuenta, CONVERT(DATE,Fclear) Fecha,importe_pesos Importe,CodPtoCuota Producto
      FROM broxelco_rdg.ind_movimientos
      WHERE Fclear > EOMONTH(DATEADD(MONTH, -1, GETDATE()))
      UNION ALL
      SELECT id, NumCuenta Cuenta, CONVERT(DATE,Fecha) Fecha,ImpTotalDEC Importe,Producto
      FROM broxelpaymentsws.PrePayStudioMovements_v
      WHERE Fecha > EOMONTH(DATEADD(MONTH, -1, GETDATE()))
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
}
