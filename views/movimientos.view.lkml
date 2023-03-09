view: movimientos {
  sql_table_name: |-
    (
      SELECT id, nro_ruc AS Cuenta, Fclear AS Fecha
      FROM ind_movimientos
      UNION ALL
      SELECT id, NumCuenta AS Cuenta, Fecha AS Fecha
      FROM pre_pay_studio_movements_v
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
