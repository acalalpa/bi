view: movimientos {
  sql_table_name:
    (
      SELECT id, NroRuc Cuenta, CONVERT(DATE,Fclear) Fecha
      FROM broxelco_rdg.ind_movimientos
      WHERE Fclear > EOMONTH(DATEADD(MONTH, -1, GETDATE()))
      UNION ALL
      SELECT id, NumCuenta Cuenta, CONVERT(DATE,Fecha) Fecha
      FROM broxelpaymentsws.PrePayStudioMovements_v
      WHERE Fecha > EOMONTH(DATEADD(MONTH, -1, GETDATE()))
    ) ;;

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
}
