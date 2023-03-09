view: ind_movimientos {
  sql_table_name: (
  SELECT id,nro_ruc,fclear FROM broxelco_rdg.ind_movimientos

  );;
  drill_fields: [id]

  dimension: id {
    type: number
    sql: ${TABLE}.id ;;
  }
  dimension: nro_ruc {
    type: string
    sql: ${TABLE}.NroRuc ;;
  }
  dimension_group: fclear {
    type: time
    timeframes: [
      raw,
      date,
      week,
      month,
      quarter,
      year
    ]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.FClear ;;
  }
  dimension: importe_pesos {
    type: number
    sql: ${TABLE}.importe_pesos ;;
  }
}
