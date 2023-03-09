view: ind_movimientos {
  sql_table_name: (
  SELECT id,nro_ruc,fclear FROM broxelco_rdg.ind_movimientos
  UNION ALL
  SELECT id,NumCuenta as nro_ruc,Fecha as fclear,'0' as importe_pesos
  FROM pre_pay_studio_movements_v
  );;
  drill_fields: [id]

  dimension: id {
    type: number
    sql: ${TABLE}.id ;;
  }
  dimension: nro_ruc {
    type: string
    sql: ${TABLE}.NroRuc ;;
    label: "NumCuenta"
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
    label: "Fecha"
  }
  dimension: importe_pesos {
    type: number
    sql: ${TABLE}.importe_pesos ;;
    label: "Importe"
  }
}
