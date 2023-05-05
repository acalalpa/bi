view: catalogo_clasificacion_clientes {
  sql_table_name: broxelco_rdg.CatalogoClasificacionClientes ;;
  drill_fields: [clasificacion,codigo]

  dimension: clasificacion {
    type: string
    sql: ${TABLE}.Clasificacion ;;
  }

  dimension: codigo {
    type: number
    sql: ${TABLE}.Codigo ;;
  }

  measure: count {
    type: count

  }
}
