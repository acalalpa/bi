view: cat_procesador {
  sql_table_name: dbo.Cat_Procesador ;;
  drill_fields: [id]

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.Id ;;
  }

  dimension: activo {
    type: string
    sql: ${TABLE}.Activo ;;
  }

  dimension: nombre {
    type: string
    sql: ${TABLE}.Nombre ;;
  }

  measure: count {
    type: count
    drill_fields: [id]
  }
}
