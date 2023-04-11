view: pre_pay_studio_movements_v {
  sql_table_name: broxelpaymentsws.PrePayStudioMovements_v ;;
  drill_fields: [id]

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.Id ;;
  }
  dimension: num_cuenta {
    type: string
    sql: ${TABLE}.NumCuenta ;;
  }
  dimension: Importe {
    type: number
    sql: ${TABLE}.ImpTotal ;;
  }
  dimension_group: fecha {
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
  # Agrega una dimensión calculada para filtrar por año
  dimension: fecha_2023 {
    type: string
    sql: |
      CASE
        WHEN date_part('year', ${TABLE}.Fecha) = 2023 THEN '2023'
        ELSE NULL
      END ;;
    hidden: yes
  }
}
