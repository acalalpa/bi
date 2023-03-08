connection: "azuresqlbi"

# include all the views
include: "/views/**/*.view"

datagroup: maquila_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: maquila_default_datagroup

explore:cc_movimiento_enc  {
  join: historico_movimientos {
    type: left_outer
    sql_on: ${cc_movimiento_enc.id_secuencia} = ${historico_movimientos.autorizacion} ;;
    relationship: one_to_one
  }
  join: maquila {
    type: left_outer
    sql_on: ${cc_movimiento_enc.num_cuenta} = ${maquila.num_cuenta} ;;
    relationship: many_to_one
  }
  join: ind_movimientos {
    type: left_outer
    sql_on: ${cc_movimiento_enc.id_secuencia} = ${ind_movimientos.nro_aut} ;;
    relationship: many_to_one
  }
}
