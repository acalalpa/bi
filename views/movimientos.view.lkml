view: movimientos {
  sql_table_name:
    (
      SELECT id, NroRuc AS Cuenta, Fclear AS Fecha
      FROM broxelco_rdg.ind_movimientos
      UNION ALL
      SELECT id, NumCuenta AS Cuenta, Fecha AS Fecha
      FROM broxelpaymentsws.PrePayStudioMovements_v
    ) Combinada ;;

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
