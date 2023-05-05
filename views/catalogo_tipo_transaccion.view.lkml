view: catalogo_tipo_transaccion {
  sql_table_name: broxelco_rdg.CatalogoTipoTransaccion ;;
  drill_fields: [categoria_transaccion,codigo_transaccional,tipo_transaccion]

  dimension: categoria_transaccion {
    type: string
    sql: ${TABLE}.CategoriaTransaccion ;;
  }

  dimension: codigo_transaccional {
    type: number
    sql: ${TABLE}.CodigoTransaccional ;;
  }

  dimension: tipo_transaccion {
    type: string
    sql: ${TABLE}.TipoTransaccion ;;
  }

  measure: count {
    type: count

  }
}
